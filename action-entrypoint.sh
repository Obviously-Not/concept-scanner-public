#!/bin/sh
# Entrypoint for the GitHub Marketplace Action (action.yml). GitHub passes each
# action input as an INPUT_<NAME> env var; this script maps them to
# `concept-scanner scan` flags and execs. Kept separate from the plain
# docker-entrypoint.sh so `docker run` users are unaffected.
#
# BYO-provider invariant: no endpoint or key is baked in. The api-key input is
# the user's secret, passed through to the env var the scanner reads; it is
# never echoed (GitHub masks it in logs when passed as ${{ secrets.* }}).
set -e

# The container runs as root, so everything the scanner writes to the mounted
# workspace (data/scans/..., cache/, costs/, pbd/) lands root-owned. The
# subsequent workflow steps run as the unprivileged runner user and can't read
# it (EACCES on scandir) — and the same bites a `docker run` host user. Capture
# the workspace owner now (before we write anything) and hand our output back on
# exit. Only touches root-owned files (what we created) and only when we run as
# root against a workspace owned by someone else — a no-op otherwise.
WS_UID="$(stat -c %u . 2>/dev/null || echo 0)"
WS_GID="$(stat -c %g . 2>/dev/null || echo 0)"
_restore_ownership() {
	[ "$(id -u)" = "0" ] || return 0
	[ "$WS_UID" = "0" ] && return 0
	find . -user root -exec chown "$WS_UID:$WS_GID" {} + 2>/dev/null \
		|| find . -user root -exec chown "$WS_UID:$WS_GID" {} \; 2>/dev/null \
		|| true
}
trap _restore_ownership EXIT

# GitHub sets one INPUT_<NAME> env var per action input, uppercasing the name and
# replacing SPACES (not dashes) with underscores — so a dashed input like
# `api-key` becomes INPUT_API-KEY, which POSIX sh cannot expand as $INPUT_API_KEY
# (the dash is not a valid identifier char). Read the dashed ones via printenv.
# `provider` and `model` have no dash, so GitHub's plain INPUT_PROVIDER /
# INPUT_MODEL already resolve.
INPUT_API_KEY="$(printenv 'INPUT_API-KEY' || true)"
INPUT_BASE_URL="$(printenv 'INPUT_BASE-URL' || true)"
INPUT_REPO_PATH="$(printenv 'INPUT_REPO-PATH' || true)"
INPUT_OLLAMA_HOST="$(printenv 'INPUT_OLLAMA-HOST' || true)"
INPUT_EXTRA_ARGS="$(printenv 'INPUT_EXTRA-ARGS' || true)"

# The workspace is bind-mounted with the runner's ownership; mark it safe so the
# scanner's git blame/history works. `git config --global` writes to
# $HOME/.gitconfig; guard against an unset HOME (container run as a bare uid).
export HOME="${HOME:-/tmp}"
git config --global --add safe.directory '*'

# Map the action's api-key to the generic env var the scanner reads (never printed).
if [ -n "$INPUT_API_KEY" ]; then
	export CONCEPT_SCANNER_API_KEY="$INPUT_API_KEY"
fi

# BYO-provider invariant: the Action ships no default provider, so require it to
# be set explicitly. Fail fast with a clear message instead of silently defaulting
# to a local Ollama at localhost that a GitHub-hosted container runner cannot reach.
if [ -z "$INPUT_PROVIDER" ]; then
	echo "concept-scanner action: the 'provider' input is required (set it to 'ollama' or 'openai-compatible')." >&2
	echo "  On GitHub-hosted runners use provider: openai-compatible with base-url + model + a secret api-key. See PROVIDERS.md." >&2
	exit 2
fi

# Build the scan command, adding each flag only when its input is set.
set -- scan "${INPUT_REPO_PATH:-.}"
[ -n "$INPUT_PROVIDER" ] && set -- "$@" --provider "$INPUT_PROVIDER"
[ -n "$INPUT_BASE_URL" ] && set -- "$@" --base-url "$INPUT_BASE_URL"
[ -n "$INPUT_MODEL" ] && set -- "$@" --primary-model "$INPUT_MODEL"
[ -n "$INPUT_OLLAMA_HOST" ] && set -- "$@" --ollama-host "$INPUT_OLLAMA_HOST"
# A hosted/container runner has no TTY; never drop into the interactive picker.
set -- "$@" --no-interactive
# extra-args: word-split intentionally (these are additional flags). Simple
# space-separated flags only — quoted values with embedded spaces are not
# supported (documented in action.yml).
if [ -n "$INPUT_EXTRA_ARGS" ]; then
	# shellcheck disable=SC2086
	set -- "$@" $INPUT_EXTRA_ARGS
fi

# Not exec'd: the shell must survive to run the EXIT trap (_restore_ownership).
# set -e propagates the scanner's non-zero status; the trap does not alter it.
/usr/local/bin/concept-scanner "$@"
