#!/bin/sh
# Install concept-scanner for the current user, on macOS or Linux. Nothing is
# written outside your home folder apart from a temporary download folder that
# is removed when the script ends, and nothing needs administrator rights.
#
#   curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.sh | sh
#
# Options (after `sh -s --` when piped, as in `... | sh -s -- --uninstall`):
#   --no-modify-path   leave shell startup files alone, and print the line to add
#   --uninstall        remove what this script installs
#
# Running it again installs the latest release over the copy you have, which is
# also how a copy from before `concept-scanner update` existed is brought up to
# date. After that, `concept-scanner update` checks and installs new releases.
#
# The whole script is functions, and the last line calls one of them, so a
# download cut off part way runs nothing.

# Where releases are downloaded from. Tests replace this one line with a local
# server; nothing at run time changes it.
CS_RELEASES='https://github.com/Obviously-Not/concept-scanner-public/releases/latest/download'

# The comment that marks each line this script adds to a shell startup file, so
# a rerun adds nothing and --uninstall removes exactly those lines.
CS_MARKER='# added by the concept-scanner installer'

cs_say() { printf '%s\n' "$*"; }
cs_err() { printf 'concept-scanner install: %s\n' "$*" >&2; }

cs_usage() {
	cs_say "Install concept-scanner for the current user, into ~/.local/bin."
	cs_say ""
	cs_say "  --no-modify-path   leave shell startup files alone, and print the line to add"
	cs_say "  --uninstall        remove what this script installs"
}

cs_paths() {
	cs_bin_dir="$HOME/.local/bin"
	cs_dest="$cs_bin_dir/concept-scanner"
	cs_dir="$HOME/.concept-scanner"
	cs_env="$cs_dir/env"
	cs_fish_file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/concept-scanner.fish"
}

# cs_detect_asset prints the release file for this machine, named the way the
# release names it.
cs_detect_asset() {
	cs_os=$(uname -s)
	cs_arch=$(uname -m)
	case "$cs_os" in
	Darwin) cs_os=darwin ;;
	Linux) cs_os=linux ;;
	*)
		cs_err "no release binary is published for $cs_os. On Windows use install.ps1; elsewhere the container image runs it (see the README)."
		return 1
		;;
	esac
	case "$cs_arch" in
	x86_64 | amd64) cs_arch=amd64 ;;
	arm64 | aarch64) cs_arch=arm64 ;;
	*)
		cs_err "no release binary is published for $cs_arch."
		return 1
		;;
	esac
	# A shell running under Rosetta reports x86_64 on Apple silicon; install the
	# native build. -i because the name is absent on Intel Macs, where -n alone
	# fails.
	if [ "$cs_os" = darwin ] && [ "$cs_arch" = amd64 ] && [ "$(sysctl -in sysctl.proc_translated 2>/dev/null)" = 1 ]; then
		cs_arch=arm64
	fi
	printf 'concept-scanner-%s-%s\n' "$cs_os" "$cs_arch"
}

cs_fetch() {
	if command -v curl >/dev/null 2>&1; then
		curl --proto '=https' --tlsv1.2 -fsSL --retry 2 -o "$2" "$1"
	elif command -v wget >/dev/null 2>&1; then
		wget --https-only -q -O "$2" "$1"
	else
		cs_err "this needs curl or wget to download the release."
		return 1
	fi
}

cs_sha256() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | cut -d ' ' -f 1
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | cut -d ' ' -f 1
	else
		cs_err "this needs sha256sum or shasum to check the download."
		return 1
	fi
}

cs_on_path() {
	case ":${PATH:-}:" in
	*":$cs_bin_dir:"*) return 0 ;;
	esac
	return 1
}

cs_write_env() {
	mkdir -p "$cs_dir"
	chmod 700 "$cs_dir"
	cat >"$cs_env" <<EOF
$CS_MARKER: puts $cs_bin_dir on PATH, once.
case ":\${PATH}:" in
*":$cs_bin_dir:"*) ;;
*) export PATH="$cs_bin_dir:\$PATH" ;;
esac
EOF
}

# cs_hook adds one marked line sourcing the env file to a startup file, unless
# it is there already.
cs_hook() {
	cs_rc=$1
	if [ -f "$cs_rc" ] && grep -qF "$CS_MARKER" "$cs_rc"; then
		return 0
	fi
	if [ -e "$cs_rc" ] && [ ! -w "$cs_rc" ]; then
		cs_unwritable="$cs_unwritable $cs_rc"
		return 0
	fi
	# Keep the file's last line intact if it has no final newline.
	if [ -s "$cs_rc" ] && [ -n "$(tail -c 1 "$cs_rc")" ]; then
		printf '\n' >>"$cs_rc"
	fi
	if printf 'if [ -f "%s" ]; then . "%s"; fi %s\n' "$cs_env" "$cs_env" "$CS_MARKER" >>"$cs_rc" 2>/dev/null; then
		cs_changed="$cs_changed $cs_rc"
	else
		cs_unwritable="$cs_unwritable $cs_rc"
	fi
}

cs_hook_fish() {
	mkdir -p "$(dirname "$cs_fish_file")"
	cat >"$cs_fish_file" <<EOF
$CS_MARKER: puts $cs_bin_dir on PATH, once.
if not contains -- '$cs_bin_dir' \$PATH
    set -gx PATH '$cs_bin_dir' \$PATH
end
EOF
	cs_changed="$cs_changed $cs_fish_file"
}

cs_hook_shells() {
	case "${SHELL:-}" in
	*/zsh) cs_hook "${ZDOTDIR:-$HOME}/.zshrc" ;;
	*/bash)
		# A new terminal tab starts bash as a non-login shell on Linux, which
		# reads .bashrc; macOS Terminal starts a login shell, which reads
		# .bash_profile, or .profile when there is none.
		cs_hook "$HOME/.bashrc"
		if [ -f "$HOME/.bash_profile" ]; then
			cs_hook "$HOME/.bash_profile"
		else
			cs_hook "$HOME/.profile"
		fi
		;;
	*/fish) cs_hook_fish ;;
	*) cs_hook "$HOME/.profile" ;;
	esac
}

cs_install() {
	cs_modify_path=$1
	cs_asset=$(cs_detect_asset) || return 1

	cs_tmp=$(mktemp -d 2>/dev/null || mktemp -d -t concept-scanner)
	trap 'rm -rf "$cs_tmp"' EXIT
	trap 'exit 1' INT TERM

	cs_say "Downloading $cs_asset ..."
	if ! cs_fetch "$CS_RELEASES/$cs_asset" "$cs_tmp/$cs_asset"; then
		cs_err "could not download $cs_asset, so nothing was installed."
		return 1
	fi
	if ! cs_fetch "$CS_RELEASES/checksums.txt" "$cs_tmp/checksums.txt"; then
		cs_err "could not download the release's checksums.txt, so nothing was installed."
		return 1
	fi
	cs_want=$(awk -v f="$cs_asset" '$2 == f { print $1; exit }' "$cs_tmp/checksums.txt")
	if [ -z "$cs_want" ]; then
		cs_err "the release's checksums.txt lists no $cs_asset, so nothing was installed."
		return 1
	fi
	cs_got=$(cs_sha256 "$cs_tmp/$cs_asset") || return 1
	if [ "$cs_got" != "$cs_want" ]; then
		cs_err "$cs_asset does not match its checksum, so nothing was installed."
		cs_err "A proxy or a captive portal that answered with its own page is the usual cause; try another network."
		cs_err "If it happens on a network you trust, please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security"
		return 1
	fi

	mkdir -p "$cs_bin_dir"
	cs_staged="$cs_bin_dir/.concept-scanner-install.$$"
	cp "$cs_tmp/$cs_asset" "$cs_staged"
	chmod 755 "$cs_staged"
	# Run the new copy before it replaces anything.
	if ! "$cs_staged" version >"$cs_tmp/version.txt" 2>&1; then
		rm -f "$cs_staged"
		cs_err "the downloaded program would not run here, so nothing was installed."
		return 1
	fi
	# A rename, never a write over the old file: a copy that is running is left
	# undisturbed.
	mv -f "$cs_staged" "$cs_dest"
	cs_say "Installed $(head -n 1 "$cs_tmp/version.txt") at $cs_dest"

	cs_changed=""
	cs_unwritable=""
	cs_was_on_path=0
	if cs_on_path; then
		cs_was_on_path=1
	elif [ "$cs_modify_path" = 1 ]; then
		cs_write_env
		cs_hook_shells
	fi

	if [ -n "$cs_changed" ]; then
		cs_say "Added $cs_bin_dir to your PATH in:$cs_changed"
		cs_say "Open a new terminal, or run this in the current one:"
		cs_say "  . \"$cs_env\""
	fi
	if [ "$cs_was_on_path" = 0 ] && { [ "$cs_modify_path" = 0 ] || [ -n "$cs_unwritable" ]; }; then
		[ -z "$cs_unwritable" ] || cs_say "Could not write:$cs_unwritable"
		cs_say "Add this line to your shell's startup file:"
		cs_say "  export PATH=\"$cs_bin_dir:\$PATH\""
	fi
	if [ "$cs_was_on_path" = 1 ]; then
		cs_found=$(command -v concept-scanner 2>/dev/null || true)
		if [ -n "$cs_found" ] && [ "$cs_found" != "$cs_dest" ]; then
			cs_say "Note: another concept-scanner comes first on your PATH, at $cs_found."
			cs_say "Remove it, or run this one as $cs_dest."
		fi
	fi
	if ! command -v ollama >/dev/null 2>&1; then
		cs_say "concept-scanner reads code with a model on this machine, through Ollama, which was not found on your PATH."
		cs_say "If it is not installed: https://ollama.com/download"
	fi
	cs_say "Next: concept-scanner scan ."
}

cs_uninstall() {
	for cs_rc in "${ZDOTDIR:-$HOME}/.zshrc" "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
		if [ -f "$cs_rc" ] && grep -qF "$CS_MARKER" "$cs_rc"; then
			cs_kept="$cs_rc.concept-scanner-uninstall.$$"
			grep -vF "$CS_MARKER" "$cs_rc" >"$cs_kept" || true
			# Written back in place, so the file keeps its owner and permissions.
			cat "$cs_kept" >"$cs_rc"
			rm -f "$cs_kept"
			cs_say "Removed the line it added to $cs_rc"
		fi
	done
	rm -f "$cs_fish_file" "$cs_dest"
	rm -rf "$cs_dir"
	cs_say "Removed $cs_dest and $cs_dir."
	cs_say "Scan results in each project's data/ folder are left alone."
}

cs_main() {
	set -eu
	if [ -z "${HOME:-}" ]; then
		cs_err "HOME is not set, so there is nowhere to install."
		return 1
	fi
	cs_paths
	cs_modify=1
	for cs_arg in "$@"; do
		case "$cs_arg" in
		--uninstall)
			cs_uninstall
			return 0
			;;
		--no-modify-path) cs_modify=0 ;;
		-h | --help)
			cs_usage
			return 0
			;;
		*)
			cs_err "unknown option: $cs_arg (try --help)"
			return 1
			;;
		esac
	done
	cs_install "$cs_modify"
}

cs_main "$@" || exit 1
