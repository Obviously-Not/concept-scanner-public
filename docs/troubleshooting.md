# Troubleshooting

Common failure modes and how to recover, symptom first. If none of these fit,
open a bug with the command you ran, the provider and model, and the last ~20
lines of output.

For provider and key setup, see [PROVIDERS.md](providers.md). For output-budget
tuning (the `CS_BUDGET_*` environment variables referenced below), see the
budgets section of [PROVIDERS.md](providers.md).

---

## "Ollama not running" or a connection error

**Symptom:** the scan stops early with a message about Ollama being unreachable.

**Two different causes, one message historically:**

1. **Ollama really is not running.** Start it: `ollama serve`. Confirm with
   `curl http://localhost:11434/api/tags` (should return JSON).
2. **The model is large and the request timed out**, which can look like a
   connection failure. A big model on a cold start can take minutes to load.
   Try the **Fast** profile (`qwen2.5-coder:7b`) first to confirm the pipeline
   works, then move up.

**If you run Ollama on another host,** pass `--ollama-host http://<host>:11434`.
Note that pointing at a non-local host means your code leaves this machine; the
scanner warns at startup, but the request is still sent.

## The model is too large for this machine

**Symptom:** the scan is extremely slow, the machine swaps, or batches fail.

**Fix:** the first-run picker flags profiles that exceed your detected RAM;
choose one it does not flag, or re-pick with `concept-scanner init`. As a floor,
the **Fast** profile runs on most laptops. On Apple Silicon, an `-mlx` build of
the same model runs faster (choose Custom and add the `-mlx` tag).

## Output looks truncated / "hit max_tokens" / "done_reason=length"

**Symptom:** a concept or a whole batch is cut off, or a log line mentions a
length/`max_tokens` limit.

**Cause:** the per-pass output budget was too small for that model's verbosity.

**Fix:** the scanner retries on truncation with a larger budget automatically,
and if a batch still does not fit it splits the batch and retries the halves. If
it still truncates, raise the budget for the affected pass with the `CS_BUDGET_*`
environment variables (see [PROVIDERS.md](providers.md)). Reasoning-heavy models
spend more tokens before the answer, so they need a larger budget.

## "returned an empty completion" / the endpoint declined to answer

**Symptom:** a scan stops with an error saying a backend returned an empty
completion, usually naming a finish reason such as `content_filter`.

**Cause:** the endpoint accepted the request, charged for reading the prompt, and
generated nothing. On a remote provider this is most often a content filter
declining that particular input; a local model can also return an empty body.

**What it is NOT:** a malformed answer. Before this was reported properly the
same event surfaced as a JSON parse failure after a repair attempt, which sent
people looking at rate limits, keys and token budgets. The finish reason in the
message is the useful part: `content_filter` means the model declined.

**Fix:** there is no retry that helps, because the same prompt gets the same
answer, so the scanner fails immediately rather than paying for another call.
Options are to exclude the file or directory whose content triggered it with
`--exclude`, or to run the scan against a local model, where no content filter
applies. Source code that discusses a filtered subject can trigger a filter even
though the code itself is unremarkable.

## The scan finished but shipped 0 concepts

Several distinct causes, in order of likelihood:

1. **Everything found was classified `textbook` and held back by default.** The
   summary says so. Re-run with `--include-textbook` to include them. A capable
   frontier model classifies more mechanisms as textbook; a lighter model
   surfaces more as `borderline` / `distinctive`.
2. **A verbose frontier model was the multi-model primary on a thin repo.** Very
   capable models can synthesize an empty set on small inputs. Use a lighter
   primary model (see "Choosing a model" in the [README](../README.md)), or scan a
   larger, more substantive repository.
3. **The repository's core was excluded.** See "Results look thin or wrong"
   below.
4. **`--docs-only` was passed and the repository has no MARKDOWN.** That mode
   reads documentation and nothing else, and only `.md` counts: `.txt`, `.rst`,
   `.adoc` and `.org` are excluded by design so that prose fixtures holding
   third-party text cannot enter as source. So a repository documented in
   reStructuredText or plain text selects nothing. The scan says which case you
   hit rather than leaving you to infer it: it warns that `--docs-only` selected
   no files, and names the documentation-shaped extensions it skipped if there
   were any. It does not fall back to the code on purpose, because a silent
   fall back would hand you a code scan when you asked for prose.

## Remote scan: "a pass degraded, consider re-running"

**Symptom:** a remote (cloud) scan completes but a next-step note says a pass
degraded.

**What it means:** the classification pass (Pass 2) did not complete on some
batches. The scanner keeps the discovered concepts rather than dropping them,
but they are **not classified** on that run, so the ranking and the `textbook`
hold-back are less reliable.

**Fix:** the default cloud grader model was validated to complete Pass 2
reliably. If you are seeing this error:
1. **If you passed `--secondary-model` explicitly**, try omitting it to use the
   validated default.
2. **If using the default**, re-run (transient network issues can cause this),
   or try a different `--secondary-model`.

## Results look thin, or describe the wrong part of the repo

**Symptom:** the concepts describe peripheral code (an SDK, docs, examples) and
miss the core, or there are far fewer than expected.

**Cause:** the repository's core is in a language or file type the scanner does
not scan, so only the peripheral files were read; or the repo is small.

**Fix:** the scanner prints an **exclusion summary** at the end of a scan listing
what it skipped and why. Read it. If the core was excluded, that is expected for
unsupported languages. Use `--exclude` to drop noisy directories (vendored code,
generated files, fixtures) so the signal is not diluted. Very small repositories
produce non-representative results; try a larger one to gauge the tool.

## The scan is slow

**Symptom:** a scan takes a long time, mostly after discovery.

**Cause:** characterization (scoring each candidate) is most of the wall-clock
time, and it is bounded by your GPU, not by parallelism. A repository can yield
hundreds of candidates.

**Fix:** this is expected; a large repo is a long scan. Use a smaller/faster
model or `--exclude` to cut the candidate count. Concurrency flags will not help
if the GPU is already saturated.

## Two scans of the same code give different results

**Symptom:** scanning the same commit twice with the same model produces a
different set of concepts.

**Cause:** usually the model server, not the scanner. A server with more than
one slot per model (Ollama's `OLLAMA_NUM_PARALLEL` above 1) runs concurrent
requests together, and that changes each one's output; the scanner sends up to
`--parallel-batches` requests at once (default 4). A server that was restarted
or upgraded between the scans can also have loaded the model with different
settings, and a model tag can point at different weights after a pull.

**Fix:** run with `--parallel-batches 1` when you need the same output twice.
To see what each scan ran on, compare the `models.json` files beside the two
scans: each records the model's weights (`digest`, and `blob` under `server`),
the server's version, and the runner each model loaded with (`slots`,
`flash_attention`, `batch`). Two scans that differ in any of those are not
expected to match.

## Why was this concept held back?

**Symptom:** a concept you expected is missing, or `refusals <scan-id>` lists it.

**Fix:** `review <scan-id> --why <concept-id-or-name>` says which gate held it,
what the gate measured, and, when a number decided it, where that number came
from and what would replace it. `scan --verbose` prints the same for every
refused concept at the end of the run.

## The status line, the status file, and stale runs

**Symptom: timestamped lines instead of a status line at the bottom.** The live
status line runs only when both stdin and stderr are a terminal, `TERM` is not
`dumb`, and neither a coding agent nor CI is detected; everywhere else a scan
prints a line per stage and a heartbeat every 30 seconds instead. `--progress
live` forces the status line on a terminal; `--progress static` keeps it
without motion.

**Symptom: the terminal behaves oddly after a scan was killed.** A scan killed
with `kill -9`, or one that crashed, cannot restore the terminal it was drawing
on. Type `reset` and press Enter. A normal finish, a failure and Ctrl+C all
restore it.

**Symptom: `status` says a run is stale.** Its process is no longer running, or
its status file has not been updated for three heartbeats (30 seconds), so its
`running` state is not true. The run's log (`status` prints its path) holds the
last thing it wrote.

**Symptom: no progress in the tab or taskbar.** It is sent only to terminals
known to show it (Windows Terminal, ConEmu, Ghostty, iTerm2), and never inside
tmux, which does not pass it on.

**Symptom: `status --wait` returned at once, with an earlier scan's result.**
Without a run id it waits on the most recent run when it starts, and a scan
started a moment before may not have recorded its run yet (an interactive scan
records it after its last question). Pass the run id, which the scan prints on
its first line, to wait on that scan and no other.

**Symptom: `::stop-commands::` lines in a GitHub Actions log.** A line the
runner could have read as a workflow command (one starting with `::`, typically
text a model or the scanned repository wrote) is printed between a
`::stop-commands::` line and a matching end line, so the runner shows it and
does not act on it. `##[` in the output appears as `#\u0023[` for the same
reason; inside JSON that is the same text.

**Colour:** any non-empty `NO_COLOR` turns colour off.

## Cloud costs more than expected

**Symptom:** a remote scan on a premium model runs up a bill.

**Cause:** premium remote models are priced per token, and input-cost caching is
not yet enabled, so large repositories re-send a lot of context.

**Fix:** start with a lower-cost model from the shortlist
(`concept-scanner models --cloud`), scan a smaller target first to gauge cost,
and prefer local Ollama (free) for proprietary or exploratory work.

## Semantic batching skipped / "Avenue B skipped"

**Symptom:** the scan log says "Avenue B skipped" or semantic batching did not
run, and you expected it to.

**Cause:** Avenue B (PBD-guided semantic batching) requires go-pbd to encode the
workspace. go-pbd supports Go, TypeScript, Python, and Markdown. If the
repository contains only unsupported languages (Rust, Zig, C, Java, etc.) or if
encoding fails (parse errors, empty workspace), Avenue B skips gracefully.

**Why it is not an error:** Avenue A (size-based batching) still runs and
produces concepts. Avenue B is additive; skipping it means you get the same
results as before semantic batching existed. No action is needed unless you
expected Avenue B to find cross-file mechanisms in a supported-language repo.

**Fix (if unexpected):** check that the repository contains `.go`, `.ts`,
`.tsx`, `.py`, or `.md` files. If it does and Avenue B still skips, the files
may have parse errors. Run `go-pbd encode .` directly in the workspace to see
the underlying failure.

## "Tests: 0 of N" / `tests.json` pairs nothing

**Symptom:** the scan's Tests line says few or none of its concepts are
exercised by tests, in a repository that has tests.

**Cause:** pairing is deliberately narrow, and `tests.json` says which limit
applied to each concept:

- **The language is not one pairing reads.** Pairing reads Go, TypeScript,
  JavaScript and Python; the Tests line says how many concepts are in other
  languages (`unsupported_language` in `tests.json`; `not_go` before 2.0.0).
- **The tests are not beside the code.** Go reads the `_test.go` files in the
  concept's own directory; TypeScript and JavaScript the `.test.` and `.spec.`
  files in its directory and its `__tests__`; Python the test files in its
  directory and the `tests/` or `test/` files named for its module or mirroring
  its path. An integration suite elsewhere is not seen (`no_tests` counts
  concepts with none found).
- **A TypeScript, JavaScript or Python test is written in a form the patterns
  do not read**, such as `test.each(...)(...)` or a test class without `test_`
  methods. Each concept's `language` says how it was read.
- **The concept's line range covers no declaration**, for example only a
  comment or the package clause (`no_declarations`). A concept with no range at
  all is paired against its whole file and marked `file_level`.
- **The only names in range are used by most of the directory's tests.** Such a
  name cannot tell one test from another, so it is not used unless it is the
  range's only name; it is listed under the concept's `common_names`.
- **A file is over the read cap** (100 KB). It is skipped and counted, never
  read cut short: `too_large` for a concept's own file, `test_files_too_large`
  for a test file. `test_files_unreadable` counts test files that did not parse.
- **The concept has no file at all** (`no_file`), which happens when the model
  named none and triage was skipped.

**Fix:** none is needed for a correct "0": it means no test in the concept's
directory uses the code in its range. If you expected a pairing, read the
concept's entry in `tests.json`: `range_names` are the declarations its range
covers, and each paired test lists the names it was paired on.

## `--tests evidence`: properties rejected, or "none of the answers could be read"

**Symptom:** `tests.json` lists properties under `rejected`, or the Tests line
says none of the answers about what the tests assert could be read.

**Cause:** a property is kept only when its quote is found, character for
character up to whitespace, in the test's name, a failure message reported on
the test's own `t`, the condition guarding one, or a case label the test prints
and does not pass to the code under test. Each rejection carries its cause:
`outside_asserting_region` (the quote is in the test, but in its setup data,
which is never evidence), `not_in_test` (the quote is not in that test),
`statement_repeats_setup` (the quote is genuine, but the statement repeats a
phrase found only in the test's setup data), `test_not_paired` (the model named
a test that was not sent), `quote_too_short`, or `no_statement`. "None could be read" means every call
failed or returned an answer that did not parse; the run log has a line for
each.

**Fix:** rejections are the check working, not a fault: a model that
paraphrases instead of quoting gets those properties rejected by design. If
every answer was unreadable,
check the model server as for any failed call; the scan's concepts are
unaffected either way.

## "License check incomplete" / "manifest(s) could not be analyzed"

**Symptom:** the scan summary's `License:` line says `License check incomplete`
or `N manifest(s) could not be analyzed, see dependency_map.errors`.

**Cause:** for a Go repository, license analysis asks the `go` command to list
the packages the repository depends on, then reads each dependency's license
file. It cannot when `go` is not on your PATH (the container image and the
GitHub Action do not include it), when the repository's modules cannot be
downloaded (offline, or a private module without credentials), or when the
repository's packages do not load. For a Node repository, the cause is an
unreadable `package.json` or lockfile.

**What it affects:** only the license findings. Concepts are found and reported
as usual.

**Fix:** run the scan where `go` is installed and can fetch the repository's
modules (running `go mod download` in the repository first confirms that), and
read `dependency_map.errors` in the `--json` output for the exact failure.

## The API key is not being picked up (remote provider)

**Symptom:** a remote scan fails to authenticate.

**Cause:** the key is read from an environment variable matched to the endpoint's
host, never from a flag.

**Fix:** export the correct variable for your endpoint (see the key-resolution
table in [PROVIDERS.md](providers.md)) in the same shell that runs the scan.
Confirm it is set with `printenv <VAR_NAME>` (which prints only that one
variable). Keys are never accepted as command-line flags, by design.

## "symlink escapes repository"

**Symptom:** the scan fails with `symlink escapes repository: <path> -> <target>`.

**Cause:** the repository contains a symlink that points outside the repository
root. By default, the scanner rejects these as a security measure (a cloned
repository should not be able to read files outside itself).

**Fix:** if the symlink is legitimate (for example, pointing to a shared corpus
or federated artifacts), pass `--allow-external-symlinks` to skip the check:

```bash
concept-scanner scan ./my-project --allow-external-symlinks
```

This flag is honored for local repositories only; remote clones always enforce
the symlink boundary for security.

## `update` did not install the new release

**Symptom:** `concept-scanner update` reports a newer release and then installs
nothing, or stops with a reason. Whatever the reason, the copy you ran is left
exactly as it was.

**Causes and fixes, by the message:**

- **"Nothing was installed, because ..."**: it only installs after you answer
  yes at a prompt, and it does not prompt in a pipe, a script, CI, or a coding
  agent's terminal (the message names which). Run it yourself in a terminal.
  `update --json` always checks without installing.
- **"this copy runs from the container image"**: pull the new image instead,
  `docker pull ghcr.io/obviously-not/concept-scanner:v1`. A GitHub Action on
  `@v1` already runs the latest stable release.
- **"cannot write beside ..."**: the folder holding the binary is not writable
  by you, which `update` now finds before downloading anything. It never asks
  for elevated rights; reinstall with the install script (the command it
  prints), which puts the program in a folder you own so later updates work.
- **"carries no release-signing key"**: a development build, or a release from
  before the updater existed, has nothing to verify with. Download the release
  by hand once; later releases can then update themselves.
- **"does not verify", "does not match its checksum", or "reports version"**:
  the release failed a check a genuine release always passes, so nothing from it
  was installed. Please report it privately (see [SECURITY.md](../SECURITY.md))
  rather than downloading that release by hand.
- **"returned N bytes where the release lists M"**: what arrived was not the
  file. A corporate proxy or a captive portal answering with its own page, or a
  dropped connection, is the usual cause; this is a network problem, not a
  problem with the release. Try again, or from another network.
- **"GitHub's limit on requests from this network without signing in is used
  up"**: GitHub allows 60 such requests an hour per network address, and
  everyone behind one office address shares them. It says when the limit
  resets; check again after that.
- **"could not reach the releases page"**: the check needs `api.github.com`,
  `github.com` and `release-assets.githubusercontent.com` (where GitHub serves
  release downloads); a firewall that allows only `github.com` blocks the
  download.

## A scan says a newer version is available

You said yes, after a scan, to letting scans check for a newer release. It
checks at most once a day, sends one request to GitHub's public releases page,
and only ever tells you: installing is still `concept-scanner update` and your
yes. To stop it, `concept-scanner update --auto-check off`; to start it again,
`--auto-check on`. The setting lives in `~/.concept-scanner/settings.json`, in
your home folder and nowhere else, so a repository you scan cannot change it.

## Installing

**`concept-scanner: command not found` after the install script finished.** The
script added `~/.local/bin` to your PATH for new terminals. Open a new one, or
run `. ~/.concept-scanner/env` in the current one. If you ran it with
`--no-modify-path`, or it could not write your shell's startup file, add the
line it printed. On Windows, open a new terminal.

**"does not match its checksum, so nothing was installed."** Usually a proxy or
captive portal that answered with its own page; try another network. If it
happens on a network you trust, report it privately (see
[SECURITY.md](../SECURITY.md)).

**"Windows did not run the downloaded program."** Nothing was installed. The
Windows build is signed, so the usual cause is antivirus software, or a policy
your organization sets (App Control, or Smart App Control on a managed PC). A
brand-new signature can also start without SmartScreen reputation and draw a
warning until it builds. Please report it, with the message, on the issue
tracker; meanwhile the container image (or WSL) runs the scanner. Turning Smart
App Control off is not something this project asks you to do.

**macOS blocked a binary you downloaded in a browser** ("cannot be opened" or
"Apple could not verify"). The binaries are signed and notarized, but a bare
command-line binary cannot carry its notarization, so macOS asks Apple the first
time it runs: run it from Terminal, while online, rather than double-clicking it
in Finder (which no command-line tool supports). If it is still blocked, System
Settings, Privacy & Security, then Open Anyway, and please report it. The
install script avoids all of this, because a file `curl` downloads is not
marked as from the internet.

**PowerShell says "Method invocation is supported only on core types in this
language mode".** Your organization restricts PowerShell scripts. Install by hand
from the latest release instead (see the README).

**A 429 from `raw.githubusercontent.com`** when fetching the script: GitHub's
limit on anonymous downloads, shared by everyone on your network address. Wait
and retry, or download the script from the public repository in a browser.
