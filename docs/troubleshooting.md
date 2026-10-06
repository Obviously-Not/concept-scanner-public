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

1. **Ollama really is not running.** Open the Ollama app (it stays in the menu
   bar on macOS and the system tray on Windows), or run `ollama serve` in a
   terminal. Confirm with `curl http://localhost:11434/api/tags` (should return
   JSON). In the window, Settings says whether Ollama is running, installed and
   stopped, or not installed.
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
generated files, fixtures) so the signal is not diluted. Folders that are
checkouts of their own (a git worktree, a submodule, a repository cloned inside
yours) are skipped and counted as "in other checkouts", because their files
belong to another commit or another repository; scan such a folder directly to
read it. Very small repositories produce non-representative results; try a
larger one to gauge the tool.

If the summary says files were left "outside this scan's coverage", the scan
read part of the repository on purpose (see the next section), and `arc.json`
beside the scan lists which files.

## Reading part of a repository: setup screens, `--coverage` and `--parent`

**"Note: no setup screens (...), so this scan reads every file."** The screens
run only with a person at a terminal and a live display. A coding agent, CI,
`--json`, `--no-interactive`, `--progress plain`, a redirected stream or a
background job turns them off, and the note names which. The scan then reads
every file, as before; to read part of the repository first without the
screens, pass `--intent "..."` or `--intent-from-docs` with `--coverage 30`.

**"--coverage 30 reads part of the repository, outward from its purpose, and
needs one."** A coverage below 100 needs a purpose to rank by: pass `--intent`,
`--intent-file` or `--intent-from-docs`, or `--parent` to widen an earlier scan.

**"... this run has none: no document describing the project was found"** (or
"locate kept no path for any behaviour", or "the folder tree does not fit the
model's window"). With nobody at the terminal, a partial coverage with no
centre is refused rather than widened to every file, so a run asked to read
30% never reads, and pays for, the whole repository. Type the purpose with
`--intent`, or run with `--coverage 100`.

**"N dropped: their quotes were not found in the documents."** A behaviour the
model stated is kept only when its quote, ten characters or more, is in the
document it cites. A dropped one is listed with its cause in `intent.json`. If
most are dropped, the documents may not describe the code, or the model may be
paraphrasing; type the behaviours you care about on the intent screen.

**Picks dropped as `path_not_in_tree` or `path_outside_workspace`.** The model
named a path that is not in the repository's collected files, or one that
leaves it. Nothing is ever opened because a model named it; the pick is
counted in `intent.json` and ignored.

**"folders only, N deep" in `intent.json`.** The repository's file list was too
long for the model's window, so the locate call was sent its folders down to
that depth instead, and the model picked folders. Each folder pick's weight is
spread over its files.

**"not estimated yet: N earlier scan(s) with this model, 3 needed".** The
whole-scan range is drawn from earlier scans with the same model on this
machine that finished; until three exist, only the discovery time is
estimated. Scans made by an earlier version kept no stage times and do not
count. On a first run the discovery time is priced from the two setup calls,
one call after another on a local server, and says "rough".

**"--parent ... scanned another repository" or "no arc.json beside that
scan".** A widening continues the same repository's lineage, and reads the
earlier scan's `arc.json` from the same data directory. Run it against the
repository the earlier scan read, with the same `DATA_DIR`.

**"--parent ... collected its files with --exclude ... and this run with the
defaults".** A widening reads the same set of files as the scans before it,
so it needs the same `--exclude`, documents and tests modes,
`--include-clients` and `--include-fixtures`. Give it the flags the message
names; the widening command a scan prints at its end already carries them.

**"--parent ...: its arc.json is version ..., written before a covered file had
to have reached the model".** That record came from an earlier build, whose
list of covered files could include files the model never read. Start a new
first scan.

**"--parent ...: its coverage record is inside the repository being scanned
... not trusted to say which files were read."** The data directory is inside
the repository you are scanning (`DATA_DIR` names a folder there, or you are
in the container image or the Action, which keep scans in the repository's
`data`), so the repository itself could have put a scan record there. A
widening trusts such a record only if this machine wrote it: each coverage
scan keeps the digests of its `arc.json` and `intent.json` in your home folder
(`~/.concept-scanner/repos/`), and the record must still match them. If the
message says it "has changed since", the record was edited after it was
written. Either way, start a new first scan, or set `DATA_DIR` outside the
repository, where nothing in it can write. In the container image the working
directory is the mounted repository and the home folder belongs to the
container, so mount a data directory from outside the repository and keep it
between runs if you want to widen there.

**"N covered file(s) changed since an earlier scan read them".** A widening
never rereads a file its lineage covered, even when the file has changed since;
it lists them in `arc.json` (`changed_since_covered`). To read them again, start
a new first scan rather than widening.

**"--parent ...: its lineage has already read N% of the scannable bytes, so a
ring to M% reads nothing more"** (or "has already read every scannable file").
A ring takes the file that crosses its share, so a 30% scan can read 50%, and a
widening to 30% then has nothing to read. Pass a higher `--coverage`, or 100 to
read the rest; leaving `--coverage` out widens by 20 points from what the
lineage has read.

**`not_reached` in `arc.json`.** These files were in the scan's ring and never
reached the model (too large, or past a batch's budget; with `--multi-model`,
their extraction failed or did not fit the synthesis prompt). They do not count
as covered, so the next widening reads them.

**"N document(s) not sent: over the budget or the model's window."** The intent
call is sent about 24 KB of documents at most, and no more than the model's
window holds. A document past either was not read for the purpose, and
`intent.json` lists it under `documents_not_sent`; untick a larger one to make
room.

**"Semantic batches, which no estimate prices, made N more call(s)".** The
estimate counts the size-based discovery batches. Semantic batching decides its
batches with a model call during the scan, so it cannot be priced in advance;
its calls are reported apart and recorded in `arc.json`.

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

With `--multi-model`, a file whose content, model and prompt version match an
earlier scan's is read from the extraction cache instead of being sent again,
so a second scan reuses the first one's extractions. The cache is in your user
cache folder: `~/Library/Caches/concept-scanner/extractions` on macOS,
`~/.cache/concept-scanner/extractions` on Linux (or under `$XDG_CACHE_HOME`),
and `%LocalAppData%\concept-scanner\extractions` on Windows. Move it aside for
a scan that extracts every file afresh. Versions before this one kept it in a
`cache` folder where the scan ran; that folder is no longer read and can be
deleted.

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
host, or else from the key saved for exactly that endpoint's host, never from a
flag. A key in `.env.local` is not read: a file in a cloned repository must not
be able to put its own key in front of yours.

**Fix:** save it once for the endpoint you use, `concept-scanner init --with-key`
(it reads the key from stdin, hidden at a terminal; `init --json` shows which
hosts have one, by their last four characters), or export the correct variable
for your endpoint (see the key-resolution table in [PROVIDERS.md](providers.md))
in the same shell that runs the scan; confirm it with `printenv <VAR_NAME>`. A
saved key is for one host: an endpoint with another host or port needs its own.
Keys are never accepted as command-line flags, by design. If the run says
`credentials.json cannot be read`, the file is damaged; it was left as it is so
no key in it is lost: fix or delete it, then save the key again.

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

## A renamed file's concepts were retired instead of following it

A rescan (`--changed`) follows a file that MOVED and keeps its concepts, but
only where git can see that it moved. It needs the commit the earlier scan
recorded to be in the history of the checkout you are scanning now.

A fresh shallow clone does not have it, which is the normal case on a remote
scan: the clone has its own history and nothing in common with the earlier
scan's. When that happens `arc.json`'s `renamed_note` says NOT COVERED and
names the commit it could not find, and the move reads as one file deleted and
one added, so the old path's concepts retire and the new path is simply unread.

This is not approximated: guessing a rename from how similar two files are
would put a concept on a file nobody showed the scanner. If you want renames
followed, scan a checkout that holds both commits (a local clone, or a clone
with enough depth to reach the earlier scan's commit).

## A concept shows STALE or RETIRED and I cannot export it

You can. `submit` names the state in its notice and proceeds.

Both states are disclosures about a concept's EVIDENCE, not verdicts on
whether the mechanism exists. STALE means the file changed since the pass that
found the concept and no later pass re-read it, so its symbols still resolve
and nothing has re-asked what the file now does; the notice shows the two
content hashes so you can see what changed. RETIRED means the symbols its
description names are no longer in the file it cites, and it lists them.

A retired concept is kept, never deleted, and returns to current by itself if
a later change puts those symbols back, because every run recomputes the state
from the content rather than storing a verdict.

## Scans I ran before are missing

Scans are kept in `~/.concept-scanner/data`, whatever folder you run the
command from. Versions before this one kept them in a `data` folder in the
directory you ran from, and that folder is not read any more. Copy it across
with `cp -R data/. ~/.concept-scanner/data/` (then delete the old folder if you
like), or keep using it by running with `DATA_DIR=./data`. A scan from the
container image or the GitHub Action is still in the scanned repository's
`data` folder: point `DATA_DIR` at it to read it.

## `review` showed fewer concepts than my scans found

Give `review` the id of your FIRST scan in a lineage, not the latest. From the
root it reviews every pass that continued it and says so in its header: `union
of 3 passes, 41 concepts`. From a later pass's id it reviews that pass only.

If the header says INCOMPLETE, a concept in the union could not be loaded from
the store and is named rather than left out silently. That usually means a
scan directory was moved or partly deleted; the other members still review.

## The window

**It opened on another port.** The window uses port 7226, and when another
program holds it the window takes the next free one and says so. Nothing is
wrong; the address in the browser is the one to use. To choose the port
yourself, `concept-scanner ui --port <number>`.

**"This page needs to be opened again."** The page in your browser no longer
holds the window's secret: a bookmark, a tab left over from a window you quit,
a private window, or cleared site data. Open Concept Scanner again, or run
`concept-scanner ui`; it opens a fresh page. The address it opens carries a
code that works once, within a minute, so a copied address does not open a
second page.

**"The window has stopped."** It was quit, from its own Quit, by
`concept-scanner ui --stop`, or by restarting the computer. Open it again the
same way you opened it.

**Quit, or `ui --stop`, says commands are still running.** The window will not
stop a scan by quitting under it. Stop the scan from the Running screen, or
wait for it to finish, then quit.

**"a window is serving on port N and this account has no record of it."** A
window from another account, or one whose record in `~/.concept-scanner/ui.json`
was deleted, holds the port. Quit it from its own page, or open this one on
another port with `--port`.

**Nothing opens, or "the window did not start."** The window's own output is in
`~/.concept-scanner/ui.log`; the last lines name the cause. If
`~/.concept-scanner/ui.json` cannot be read and no window is open, delete it.

**Install says "running from its disk image, which cannot be updated."** On a
Mac, drag Concept Scanner from the disk image to your Applications folder,
eject the image, and open it from Applications; updates replace it there.

**Uninstalling kept my scans.** On purpose. Removing the app (dragging it to
the Trash on a Mac, or Windows' Installed apps) removes the program and leaves
`~/.concept-scanner`, which holds your settings, saved keys and scans. Delete
that folder too if you want them gone.

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
