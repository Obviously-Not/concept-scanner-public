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

**The message ends by saying which of five things is true**, and its first
next step is the fix for that one:

1. **Ollama is not installed on this machine** ("Ollama is not installed on
   this machine: download it from https://ollama.com/download, open it, and run
   this again"). Install it, or point `--ollama-host` at an Ollama server that
   is running. The first-run setup says so beside its Local choice.
2. **Ollama is installed and not running** ("Open the Ollama app, or run:
   ollama serve"). Open the Ollama app (it stays in the menu bar on macOS and the
   system tray on Windows), or run `ollama serve` in a terminal. Confirm with
   `curl http://localhost:11434/api/tags` (should return JSON). In the window,
   Settings says whether Ollama is running, installed and stopped, or not
   installed.
3. **The address is another machine's server**: start it on that machine;
   `ollama serve` here would start a different one.
4. **The address is this machine, at a port other than Ollama's own**
   (`--ollama-host http://127.0.0.1:11500`): start the Ollama server at that
   address, or point `--ollama-host` at one that is running. No `ollama`
   command is suggested, because `ollama serve` and `ollama pull` reach the
   default address, not this one.
5. **The run was on an OpenAI-compatible server** (`--provider
   openai-compatible`): start that server the way it is started (LM Studio,
   llama.cpp's server, vLLM), or point `--base-url` at one that is running.

**"something is answering at ... and it is not the model server":** another
program holds the port, or a proxy in front of Ollama refused the request.
Check what is answering on that port, or point `--ollama-host` at the model
server. The next steps never suggest saving an API key here: Ollama's own API
reads none, so a key would not help.

**A large model that timed out can look like a connection failure.** A big
model on a cold start can take minutes to load. A request that reaches
`--timeout` is sent at most twice, and the error then says so (see "after N
attempts, M of them reaching the per-request timeout" below). Try a smaller
model first to confirm the pipeline works, then move up.

**If you run Ollama on another host,** pass `--ollama-host http://<host>:11434`.
Note that pointing at a non-local host means your code leaves this machine; the
scanner warns at startup, but the request is still sent.

## "Downloading N models this run calls", or "does not have a model this run calls"

**What happens:** before its first model call, every command that calls a
model asks the server about every model it will call. On a local Ollama, one
line names each model about to be downloaded, the flag that chose it and,
where the model registry records it, about how much; the download runs (its
progress is on the status line and in `status`), and only then is anything
sent. A scan that shows no setup screen or start-up card prints a `Models:`
line first, naming every model and the server.

**"the Ollama server at ... does not have N models this run calls: ...
--no-auto-pull is set, so nothing was downloaded and nothing was sent":** the
run was told not to download. Download each one with `ollama pull <model>` (the
next steps give each command), run without `--no-auto-pull`, or choose models
the server has (`concept-scanner models` lists them).

**"the Ollama server at ... answered that it does not have the model ...":** a
model went missing during the run, after the check before its first call
(someone removed it, or the server changed). Download it and run again.

**"downloading <model> (<flag>) to the Ollama server at ... failed, so nothing
was sent":** the server did not finish the download. Check the model's name
(`concept-scanner models` lists the ones this program recommends), then run
`ollama pull <model>` by hand, which prints the server's own words and says
whether the name, the network or the disk is the cause. On the setup screens
either failure shows the models screen again with the reason, so you can
choose another model.

**"remote model check failed before any inference":** an OpenAI-compatible
endpoint's model list does not hold a model the run named. Nothing can be
downloaded there: give a model id from that endpoint's own list, with the flag
the message names.

## The model is too large for this machine

**Symptom:** the scan is extremely slow, the machine swaps, or batches fail; or,
on a local Ollama, a line before the scan says a model "needs about N GB ... so
this run sizes it for N tokens", or the run stops saying it "still does not fit,
so nothing was sent".

**Cause:** before anything is sent, a run on Ollama's own API prices each model
on this machine: its weights, its context at the run's window across every slot
the server runs, and its prompt cache, against the machine's memory less a
reserve. A model that does not fit at the run's window is given the largest
window that does, with that line; below the smallest window a run can use, the
run stops instead.

**Fix:** the models screen and the first-run picker flag profiles that exceed
your detected RAM; choose one they do not flag, or re-pick with
`concept-scanner init`. The smallest profile, **Fast**, needs about 17 GB, and
that figure is set by its grader (`gpt-oss:20b`): with `--skip-review` a Fast
scan calls only its discovery model, `qwen2.5-coder:7b`. A server running fewer slots
(`OLLAMA_NUM_PARALLEL`) needs less memory per model and keeps the full window. On
Apple Silicon, an `-mlx` build of the same model runs faster (choose Custom and
add the `-mlx` tag).

## "--<key> N is outside its range"

**Cause:** every adjustable value has a fixed range, and a value outside it is
refused before anything runs or is saved, naming the range.

**Fix:** give a value inside the range. The refusal's next steps name
`concept-scanner help <command> --json`, which lists every flag's range, and,
for a value `init` lists, `concept-scanner init --json`. A `0` on `--timeout`,
`--parallel-batches`, `--bridge-max-components`, `--bridge-max-candidates`,
`--triage-max-candidates` or `--triage-min-keywords` used to mean the built-in
value and is now outside the range: leave the flag out instead, and the run
takes the value saved with `init`, else the built-in one.

## "N values differ from their built-in ones on this run"

**Cause:** a flag, a value saved with `concept-scanner init --<key>`, or a
`CS_BUDGET_*` variable changed a value this run reads. The line names each one
and where it came from, and a scan records them in its `models.json` as
`settings_changed`. Every run also writes the list as `settings_changed` in its
`status.json` and in its first `--progress jsonl` event (`run_start`), `[]`
when nothing changed.

**Fix:** nothing, if you meant it. Otherwise drop the flag, run
`concept-scanner init --reset <key>`, or unset the variable.

## "the saved defaults name ..., which this version does not have"

**Cause:** the `"defaults"` section of `~/.concept-scanner/settings.json` holds
a key this version has no value for: one an earlier version had and this one
removed (`default-concurrency` and `default-remote-concurrency`, whose work
`--parallel-batches` does, and `native-request-timeout`, whose work
`default-ollama-timeout` does), or one a newer version saved into the same
file. It is ignored; the rest of the section applies.

**Fix:** `concept-scanner init --reset <key>` removes it. `init --reset all`
leaves it, because a key this version does not know may be a newer version's.

## "repository too large" or "too many files"

**Cause:** a scan refuses a repository over its size or file-count limit
(1 GiB and 10,000 files built in), before reading it.

**Fix:** if the repository is yours to scan, raise the limit for one run with
`--max-repo-size N` (bytes) or `--max-file-count N`, or save it with
`concept-scanner init --max-repo-size N`. Neither can be set by a scanned
repository's `.env.local` or data directory.

## "the saved defaults ... cannot be read"

**Cause:** a value in the `"defaults"` section of
`~/.concept-scanner/settings.json` is the wrong kind or outside its range, so
none of the section is used and the built-in values apply to that run.
`concept-scanner init --json` names the problem in `defaults_problem`.

**Fix:** `concept-scanner init --reset <key>` removes a value that cannot be
read, and `concept-scanner init --<key> N` replaces it with one that can; either
repairs the section, and the next steps beside the refusal give the reset for
each key. A section that is not an object at all is removed with
`concept-scanner init --reset all`, which also removes every saved output
budget. `init` will not save any OTHER value into the section while it cannot
read it, and says so with those same steps; correcting the file by hand also
works.

## Output looks truncated / "hit max_tokens" / "done_reason=length"

**Symptom:** a concept or a whole batch is cut off, or a log line mentions a
length/`max_tokens` limit.

**Cause:** the per-pass output budget was too small for that model's verbosity.

**Fix:** the scanner retries on truncation with a larger budget automatically,
and if a batch still does not fit it splits the batch and retries the halves. If
it still truncates, raise the budget for the affected pass:
`--budget-<name> N` on the run, `concept-scanner init --budget-<name> N` (or the
window's Settings) to keep it, or the `CS_BUDGET_*` variable (see
[PROVIDERS.md](providers.md)). The scan's discarded-generations note names the
stage and model each discard came from. Reasoning-heavy models spend more tokens
before the answer, so they need a larger budget.

If the log says the discarded text repeats itself (`looks_repetitive=true`),
the model was looping rather than writing a long answer: no budget fixes that,
and the scanner does not send that same request again. Changing the model is
what helps.

## "returned an empty completion" / the endpoint declined to answer

**Symptom:** a scan stops with an error saying a backend returned an empty
completion, usually naming a finish reason such as `content_filter`.

**Cause:** the endpoint accepted the request and generated no answer. The
message says which of three things the counts show:

- **"the model never ran"**: the server read no prompt and wrote nothing, which
  is what a model that failed to load returns. On a server on this machine this
  is most often a context window or slot count its memory cannot hold (a large
  window times eight slots, for instance); the message names the window the
  request asked for and, for Ollama, the server log that says why the model did
  not load. It is not a refusal, and the scan does not score it as the model's
  answer.
- **"a model on this machine does not decline"**: a local model read the prompt
  and wrote no answer, often because it spent its output budget reasoning (the
  message counts the reasoning when the server reports it).
- **"declined to answer"**: an endpoint on another machine read the prompt and
  generated nothing, most often a content filter declining that input.

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

## "after N attempts, M of them reaching the per-request timeout"

**Symptom:** a command fails with an error saying a request failed after two or
three attempts, some of them reaching the per-request timeout, and naming
`--timeout`.

**Cause:** a model call did not finish within `--timeout` (10 minutes built in).
A call that reaches it is sent at most twice in all (`timeout-attempts`), since
a call that took its whole timeout twice is not expected to finish a third time,
and no stage above the client sends it again (characterization's retries and
the multi-model synthesizer did, up to eight and six sends, until this
version); a call that failed in passing for another reason is sent up to three
times (`request-attempts`). The error counts the sends that timed out. A remote
request the endpoint rejects with a 4xx status other than 429 is not sent again
at all: the run fails with that status.

**Fix:** raise `--timeout` for a large model or a large batch, or choose a
smaller or faster model. On a local server, a model loading from a cold start
or another program's model holding the GPU makes calls slow; see "The scan is
slow". A strict Pass 2 stop for this reason can be resumed with a larger
`--timeout` (see "pass 2 validation degraded on batch N of M").

## The scan says "input truncation: NOT CHECKED"

**Cause:** the scan reached its model through `--provider openai-compatible`,
whose requests cannot carry a context window, so the server used its own, and
nothing could say what it is: the endpoint's listing gives no window for the
model, and on a server on this machine the measurement before the run could not
size it (the server reports no prompt counts, or counts that do not follow the
prompt). A prompt cut to a fixed size is still found, from the server's own
counts, and stops the run; a prompt cut once, just past the window, may not be.

**Fix:** for a local Ollama, give `--provider ollama`, or its `/v1` URL, which
is run on Ollama's own API. For LM Studio, llama.cpp or vLLM, load the model with
a context of at least 32k tokens. On a remote provider whose listing gives no
window, this line is expected.

## The run waits for minutes before it starts, after "Measured the window ..." or before it

**Symptom:** with `--provider openai-compatible` and a server on this machine,
nothing happens for a while before the first stage.

**Cause:** the server does not say its context window in an API this tool
reads, so the run measures it: three prompts for each model, the last one the
size of the window. A large model takes minutes to read that (about seven on a
31B model on an M2 Max). The run waits once for each prompt, up to ten minutes
(`describe-measure-timeout`), and does not send it again.

**Fix:** nothing is wrong. To skip the wait, say the window once, and later runs
on that endpoint use it: `concept-scanner models describe <model> --provider
openai-compatible --base-url <url> --window <tokens>`. llama.cpp's server, LM
Studio (for a model already loaded) and vLLM say their window themselves and
are not measured. On a slower machine, raise `describe-measure-timeout`.

## "nothing says what <model> is": the run stopped before sending anything

**Symptom:** a command run with `--provider openai-compatible` stops with exit
code 1, saying nothing says what a model is at an endpoint.

**Cause:** the run needs the model's context window before it sizes anything,
and, on an endpoint off this machine, the most it writes in one answer. Nothing
gave them: the endpoint's model list does not (OpenAI's own list, for example,
gives no windows), the model is not one this tool recommends, a server on this
machine could not be measured, and you have not described it. At a terminal the
run asks instead, once, and saves the answers.

**Fix:** run the step the error gives, once for that endpoint: `concept-scanner
models describe <model> --provider openai-compatible --base-url <url> --window
<tokens>`, with `--max-output` too for an endpoint off this machine. On a server
on this machine the window is the context length you loaded the model with; the
line printed before the error says why the measurement could not size it. If it
says the server did not answer a long prompt, the server is usually short of
memory or running on the CPU: load the model with a smaller context, or fewer
parallel slots, and the measurement then works (`--measure` in place of
`--window` runs it again).

## "refuses a prompt of the 32768 tokens this tool sizes for", or "cuts" one: the run stopped

**Symptom:** a command run with `--provider openai-compatible` against a server
on this machine stops with exit code 1 before sending anything, saying the
server refuses, or cuts, a prompt of the size this tool sizes for.

**Cause:** the server loaded the model with a context window smaller than
32,768 tokens. Unlike Ollama, it refuses a prompt longer than its window, or
shortens it to a length that does not show the window. Either way the window is
smaller, by an amount this shows nothing about, and this server does not say
its window in an API this tool reads (llama.cpp's server, LM Studio and vLLM
do, and are read) or in the refusal itself (llama.cpp's and vLLM's do, and a
run is then sized for the window named).

**Fix:** say the window once, and the run is sized for it:
`concept-scanner models describe <model> --provider openai-compatible --base-url
<url> --window <tokens>`. Or load the model with a context of at least 32,768
tokens.

## "the server cut the prompt of a call": the run stopped

**Symptom:** a scan, `bridges`, `triage`, `synthesize` or `figure draw` stops
with exit code 1 and an error saying the server cut the prompt of a call.

**Cause:** the model server applied a smaller context window than the one this
tool sized its prompts for, and dropped part of a prompt before the model read
it. The server's own prompt count shows it: the half-window count Ollama and
llama.cpp keep when a prompt is too long, or exactly the same count for two
prompts of clearly different sizes. Usually the server loaded the model with a
small context (a default of 4k is common), or another program reloaded it
smaller while the run was going.

**What is kept:** a scan writes no scan. The error names `unfinished.json` in
the run's own folder (`runs/<run-id>/` under the data directory), with `stage`
`input-check` and every concept the scan had in `pending`; any of them may come
from the prompt that was cut. The other commands save nothing.

**Fix:** for a local Ollama, use `--provider ollama`, which sets the window on
every call. For LM Studio, llama.cpp or vLLM, load the model with a context of
at least 32k tokens. Then run the command again.

## The scan finished but shipped 0 concepts

Several distinct causes, in order of likelihood:

1. **Everything found was scored below the distinctiveness floor and held back.**
   The summary says how many were also classified `textbook`. Re-run with
   `--include-textbook` to include them, or change `characterized-score-floor`.
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
   validated default (on OpenRouter; any other endpoint needs one named).
2. **If using the default**, re-run (transient network issues can cause this),
   or try a different `--secondary-model`.

## "pass 2 validation degraded on batch N of M": the scan stopped

**Symptom:** a scan stops with exit code 3 and an error saying Pass 2
validation degraded on a batch and strict validation is on.

**Cause:** the classifying model could not classify one batch: its answer
could not be used, the call failed, or the answer was cut off. Strict validation
stops the scan rather than ship concepts graded only by the model that found
them. Before stopping, Pass 2 sends a failed call again only when a second send
can succeed: an error in passing is sent again, an answer that could not be used
is asked for once more (`pass2-max-attempts`, 2), and a call that reached
`--timeout` is sent at most twice in all (`timeout-attempts`, 2). A cut answer,
a refusal and any other failure that would repeat are not sent again.

**What is kept:** the error names `unfinished.json` in the run's own folder
(`runs/<run-id>/` under the data directory). It holds every concept classified
before the failure (`done`), and the rest, unclassified (`pending`), with the
batch that failed (`step` of `steps`), and what a resume needs: discovery as it
ran, every batch Pass 2 finished, a hash of every collected file, the models
with the weights each name pointed at, and the scan's settings. It is not a
scan: `review` and `submit` do not see it.

**Fix:** resume it. The error's first next step is the exact command,
`concept-scanner scan <path> --resume <run-id>` with the flags that make the
run's choices (for a scan started on the setup screens, the flags that make
the screens' choices, with the plan they chose saved under the scan's id in
your home folder), and `concept-scanner status <run-id>` offers it too, as does
the window's Running screen for the newest run: it re-uses discovery and every
batch Pass 2 finished, sends the rest, and saves a new scan. It is refused,
with the reason, when a file, a model or its weights, a setting the run used
or this program's version changed since; a choice given another way that
decides the same thing compares equal, and the timeout, the retries, how the
run is shown and the spend ceilings may change, so a batch that timed out can
be resumed with a larger `--timeout`. A record written by an earlier version of
the record (`unfinished.json` before 3.3.0) is refused; run that scan again.
When `status` offers no resume it says why (`resume_refused`), for example: the
record is another version's, its parts disagree, it names another repository or run, or
it sits in a data directory inside a git work tree and this machine did not
write it. A local classifying
model can answer the same request differently after its server restarts, so the
batch that failed may pass. If the log says the answer was cut off repeating
itself, a different `--secondary-model` avoids it, and that is a new scan
rather than a resume.

## Results look thin, or describe the wrong part of the repo

**Symptom:** the concepts describe peripheral code (an SDK, docs, examples) and
miss the core, or there are far fewer than expected.

**Cause:** the repository's core is in a language or file type the scanner does
not scan, so only the peripheral files were read; or the repo is small.

**Fix:** the scanner prints an **exclusion summary** at the end of a scan listing
what it skipped and why. Read it. If the core was excluded, that is expected for
unsupported languages. Use `--exclude` to drop noisy directories (vendored code,
generated files, fixtures) so the signal is not diluted. Folders named `build`,
`dist` or `coverage` are skipped as generated output when git ignores them or
tracks nothing in them (by name alone where git cannot answer, outside a git
checkout or without git), and caches such as `.next` or `__pycache__` by name;
the scan prints which folders it skipped, which rule skipped each and how many
files each held, and names any of those folders it read because git tracks
them. Pass `--keep-dir <name or path>` (repeatable) to read one. A `data` folder
is read; this tool's own data folder never is. Folders that are
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

**"Note: --parent ...: its coverage record is inside the repository being
scanned ... not trusted to say which files were read; so this scan reads every
file, as a first scan, and continues no lineage."** The data directory is inside
the repository you are scanning, or inside another git checkout (`DATA_DIR`
names a folder there, or you are in the container image or the Action, which
keep scans in the repository's `data`), so a repository could have put a scan
record there. A widening trusts such a record only if this machine wrote it:
each scan keeps the digests of its records in your home folder
(`~/.concept-scanner/repos/`), and the record must still match them. If the
note says it "has changed since", the record was edited after it was written.
Nothing in an untrusted record is believed (not its files, drops, renames or
ancestors), so the scan reads every file and starts a lineage of its own; it
says so in that note, in its `--json` notice, in its `coverage`, and in its
status line, which names no parent. Until this version such a widening was
refused. To widen instead, set `DATA_DIR` outside the repository, where nothing
in it can write. In the container image the working directory is the mounted
repository and the home folder belongs to the container, so mount a data
directory from outside the repository and keep it between runs if you want to
widen there.

**"... its arc.json is in a data directory inside a git work tree ... not
trusted to say which lineage the scan belongs to"** (in `review` or the scan
list). The same rule, applied where no repository is named: a coverage record
in a data directory inside any git checkout places its scan in a lineage only
if this machine wrote it. The scan is still listed and can be reviewed on its
own.

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

**If the scan ends with a "model reloads" or "spill" line**, on a local Ollama,
the slowness had a cause outside the scan, and `models.json` beside the scan
records it:

- **"model reloads: <model> was loaded N times during this scan"**, or **"was
  loaded for N of this scan's calls"**: something unloaded the model between
  calls, usually another program's model needing the memory, or the server's
  idle timeout; when the line names other windows, another program loaded the
  same model at a window of its own. The first form reads the server's own log;
  the second counts the scan's own calls that had to wait for a load, and is
  what you see on a server whose log this tool cannot read (one you started
  yourself, or one on another machine), where it cannot say at which windows.
  Every load costs the load time and the server's cached prompt. Stop the other
  program's model during a scan, or give the server more time before it unloads
  an idle model (`OLLAMA_KEEP_ALIVE`).
- **"spill: <model> ran partly on the CPU when this scan ended"**: part of the
  model was held off the GPU, which makes every call much slower. The run sized
  each model to fit before it started, so something else took memory meanwhile.
  Run fewer slots on the server (`OLLAMA_NUM_PARALLEL`) or close other programs
  that use the GPU.
- **"prompt reuse: <stage>'s N calls reused X% of the M prompt tokens they
  read"**: that stage's calls open with the same text (documentation matching's
  calls each open with one part of the documentation list), so a server that
  keeps its prompt cache reads that text once, and this one read it again on
  nearly every call. The line names three usual causes: another program's
  requests between the scan's, a server started with its prompt cache off, or
  several slots each reading the text once. Run the scan alone on the server,
  with one slot, if the stage was slow.

## Two scans of the same code give different results

**Symptom:** scanning the same commit twice with the same model produces a
different set of concepts.

**Cause:** usually the model server, not the scanner. A server with more than
one slot per model (Ollama's `OLLAMA_NUM_PARALLEL` above 1) runs concurrent
requests together, and that changes each one's output; the scanner sends up to
`--parallel-batches` requests at once (by default one at a time to a server on
this machine and 4 to a remote endpoint, unless you gave or saved another
number). A server that was restarted
or upgraded between the scans can also have loaded the model with different
settings, and a model tag can point at different weights after a pull.

**Fix:** run one request at a time when you need the same output twice:
the default on a server on this machine, unless a number is saved
(`concept-scanner init --json` shows `default-parallel-batches`, and
`concept-scanner init --reset default-parallel-batches` removes it; `init`'s
picker opens on this rule and saves a number only when you change it), or
`--parallel-batches 1`.
Such a scan also reuses the discovery answers of earlier identical requests
(the `Discovery cache:` line says how many); `--verify-cache` asks every one
again and reports any that no longer reproduce, which is how to tell a stale
answer from a server that changed. If `--verify-cache` exits 1 saying it
checked nothing, the cache was off for that scan (the `Discovery cache:` line
says why: batches at once, two-phase, `--multi-model`, `--record-examples`, or
`CS_DISCOVERY_CACHE_OFF`); run it with `--parallel-batches 1` and none of
those.
Two scans that found the same concepts list them in the same order (since
2026-10-08; before that the order changed from run to run, so compare by id).
A concept's classification label can still differ between two scans run one
batch at a time: the default classifying model, `gpt-oss:20b`, was measured
answering identical requests differently on 2 of 17 concepts. The cause is the
model server's own prompt cache, which keeps what earlier requests left and
restores it for later ones, so an answer can depend on what the server answered
before. On Ollama 0.35.1 it is off when the server is started with
`LLAMA_ARG_CACHE_RAM=0` in its environment; with that set, 82 identical
classification requests got the same answer to the byte across four runs with
different histories, and no slower (measured 2026-10-10, that one model). It is
the server's setting, not this tool's.
To see what each scan ran on, compare the `models.json` files beside the two
scans: each records the model's weights (`digest`, and `blob` under `server`),
the server's version, and the runner each model loaded with (`slots`,
`flash_attention`, `batch`). Two scans that differ in any of those are not
expected to match.

With `--multi-model`, a file whose content, model, extraction prompt and
request settings match an earlier scan's is read from the extraction cache
instead of being sent again, so a second scan reuses the first one's
extractions. The model is the model as served (the weights its name points
at, the server's version and host), the request settings include the think
setting, pinned penalties, an endpoint's extra fields and the schema sent, and
the name the prompt gives the file is part of the match; a backend that cannot
say what serves it is not cached, and the run says so. A cached answer is read again with the current version's rules
each time, and folders an older prompt wrote are removed the next time a
multi-model scan opens the cache, so the first multi-model scan after an upgrade
that changed the extraction prompt extracts every file again. The cache is in
your user
cache folder: `~/Library/Caches/concept-scanner/extractions` on macOS,
`~/.cache/concept-scanner/extractions` on Linux (or under `$XDG_CACHE_HOME`),
and `%LocalAppData%\concept-scanner\extractions` on Windows. Move it aside for
a scan that extracts every file afresh. Versions before this one kept it in a
`cache` folder where the scan ran; that folder is no longer read and can be
deleted.

## Why was this concept held back?

**Symptom:** a concept you expected is missing, or `refusals <scan-id>` lists it.

**Fix:** `review <scan-id> --why <concept-id-or-name>` says which gate held it,
what the gate measured, who the verdict points at, and, when a number decided
it, the setting by the key you would give `init`, with its built-in value, any
value you saved, and how to change it. `scan --verbose` prints the same for every
refused concept at the end of the run. Two of the verdicts are about what a
concept says rather than how it scores:

- **`required_field_missing`**: characterization answered, and after the
  scanner asked the model once more for the missing fields, the concept still
  lacked one its record requires (its category, technical approach, key
  insight, inputs and outputs, or components and how they interact). It is held
  back rather than shipped incomplete.
- **`required_field_repair_failed`**: a required field was empty and the call
  that asks the model for it again failed, so it could not be filled. The
  detail names the error, and scanning again may fill it.
- **`copied_test_data`**: with `--tests source`, the concept's name or summary
  copies data a test file constructs, or the placeholder that masked it, so it
  may describe a fixture rather than your code.
- **`copied_test_data_field`**: the concept shipped, but one field of its
  description repeated a test's data word for word and was left out; the row's
  detail names the field.
- **`axes_unanswered`**: the concept shipped without its engineering axes after
  being asked for them twice.

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
and prefer local Ollama (free) for proprietary or exploratory work. A remote
scan prints its estimated cost before it spends (`scan --dry-run` shows it
without spending anything), and `BUDGET_PER_OP`, `BUDGET_DAILY` or
`BUDGET_MONTHLY` stop a run at a ceiling you set; see PROVIDERS.md, "Cost
before a scan, and spend ceilings".

**"the spend ceiling for this run was reached":** a ceiling you set was
reached, and no further model call was sent. Raise the variable the message
names, or unset it (or set it to 0) for no ceiling.

**"Estimated cost: not known (... has no listed price)":** the model is not on
the shortlist, so there is no price to estimate with. Its calls still count
toward a ceiling you set when the endpoint reports what each one cost; a call
with neither a listed price nor a reported cost is not counted, the run says so
once, and the running cost on the status line then ends in `+` (`~$0.04+`). The
scan's own cost is then `null`, and its cost line says unknown. A call that
read and wrote nothing, such as one the endpoint rejected, costs 0 whatever its
model, so it alone never makes the cost unknown.

**"served by: the endpoint reported that N upstreams served <model>'s
calls"**: an aggregating endpoint sent one model's calls to more than one
provider, which may run it at different precisions, so this scan's answers may
not all come from one configuration. `models.json` beside the scan lists them,
and each call's row in the run's `calls.jsonl` names its own. Pin one with
`CS_REMOTE_EXTRA_BODY` (see PROVIDERS.md, "Cost before a scan, and spend
ceilings").

**The cost line says "not billed per token"** for a run on Ollama, wherever it
runs ("Ollama, not billed per token"), or on an OpenAI-compatible server at a
loopback address ("an OpenAI-compatible server on this machine, not billed per
token"): such a run is never priced. Earlier versions said "on this machine,
free", also of an Ollama server on another machine.
A priced run's line says "reported or listed prices": a cost the endpoint
reported for a call where it gave one, else the shortlist's price.

**"BUDGET_DAILY is "...", which is not an amount"** (or `BUDGET_PER_OP`,
`BUDGET_MONTHLY`): the variable must be a non-negative number of US dollars.
Fix it or unset it.

## Semantic batching skipped / "Avenue B skipped"

**Symptom:** the scan log says "Avenue B skipped" or semantic batching did not
run, and you expected it to.

**Cause:** Avenue B (PBD-guided semantic batching) requires go-pbd to encode the
workspace. go-pbd supports Go, TypeScript, Python, and Markdown. If the
repository contains only unsupported languages (Rust, Zig, C, Java, etc.) or if
encoding fails (parse errors, empty workspace), Avenue B skips gracefully.
Since 2026-10-08 the scan's Avenue B line says which of these it was: mixed
project files, no project file or readable document, several languages below
the root, a language this build cannot encode (named with its file count; a
release binary built without cgo cannot encode TypeScript or Python), or a
failed or empty encode.

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

- **The language is not one pairing reads.** Pairing reads Go and Python; the
  Tests line says how many concepts are in other languages
  (`unsupported_language` in `tests.json`). TypeScript and JavaScript are not
  paired: measured, their pairing missed too many of the tests that exercise
  the code. Go reads only the `_test.go` files in the concept's own folder;
  Python also reads any test in the repository that imports the module.
- **The tests are not beside the code.** Pairing reads the `_test.go` files in
  the concept's own directory. An integration suite elsewhere is not seen
  (`no_tests` counts concepts with none found).
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
  named none and triage was skipped, or found no file holding its terms (such a
  concept ships `pending`, unverified).

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

## "no --primary-model given, and the model registry has no default"

**Symptom:** a remote scan (or `bridges`, `triage`, `synthesize`, `figure draw`)
stops before any model call with this message, or the same one naming
`--secondary-model`, and exits 1.

**Cause:** the default primary model and the default Pass 2 grader are taken
from the model registry for your endpoint's own catalog, and the registry
lists them for OpenRouter only. On any other endpoint the run will not guess
a model name that catalog may not have.

**Fix:** pass `--primary-model <id>` and `--secondary-model <id>` with model
ids from your provider's catalog, choosing a secondary other than the primary
so the scan does not grade its own output. The primary can be saved once with
`concept-scanner init --provider openai-compatible --base-url <url> --model <id>`;
the secondary is passed on each run.

## "CS_REMOTE_EXTRA_BODY: has no entry for model ... and no "*" entry"

**Symptom:** a remote scan (or another command that calls a model) stops
before any model call with this message and exits 1, naming each model and the
option that chose it.

**Cause:** `CS_REMOTE_EXTRA_BODY` is set and names some of the models this run
calls but not this one, so its requests would go out without the routing the
setting exists to fix. With no `--draft-model`, a run against an endpoint off
this machine drafts with that catalog's default drafting model, so the setting
must name that model too.

**Fix:** add an entry for the model (or a `"*"` entry for every model without
its own), or choose another model with the option the message names.

## The API key is not being picked up (remote provider)

**Symptom:** a remote scan fails to authenticate.

**Cause:** the key is read from an environment variable matched to the endpoint's
host, or else from the key saved for exactly that endpoint's host, never from a
flag. A key in `.env.local` is not read: a file in a cloned repository must not
be able to put its own key in front of yours.

**Fix:** save it once for the endpoint you use: `concept-scanner init --with-key`
saves it for the endpoint already saved with `init`, and `concept-scanner init
--provider openai-compatible --base-url <url> --with-key` saves the endpoint and
its key together, making that endpoint the saved provider (add `--model <id>` to
keep a model with it). Either reads the key from stdin, hidden at a terminal,
and `init --json` shows which hosts have one, by their last four characters.
After a 401, the run's next step saves the key for the endpoint the run sent
to: `init --with-key` when that is the saved endpoint, and otherwise the second
form for the run's own address, with `--model` when the run named its model
with `--primary-model`. An address holding a user, a password or a key is not
repeated in that step; you type it. Or
export the correct variable
for your endpoint (see the key-resolution table in [PROVIDERS.md](providers.md))
in the same shell that runs the scan; confirm it with `printenv <VAR_NAME>`. A
saved key is for one host: an endpoint with another host or port needs its own.
Keys are never accepted as command-line flags, by design. If the run says
`credentials.json cannot be read`, the file is damaged; it was left as it is so
no key in it is lost: fix or delete it, then save the key again. A request the
endpoint rejects for its key (HTTP 401 or 403) is not sent again.

## "--base-url carries the query parameter ..."

**Cause:** the address has a parameter whose name reads as a key (`key=`,
`api_key=`, `access_token=`, `sig=` and similar), and a key in an address
reaches shell history, logs and printed steps. The run refused before anything
was sent or saved, and printed the parameter's name but never its value.

**Fix:** remove the parameter from the address, and give the key in the
environment or save it with `concept-scanner init --provider openai-compatible
--base-url '<address without it>' --with-key`, which reads it from stdin. If
the refused address was the saved one, that same `init` replaces it. A
parameter whose name only looks like a key (`sort_key=`) is refused too; an
endpoint that needs one cannot be used as typed.

## "--local-only: the model server at ... runs a model of this run on another machine"

**Cause:** the local Ollama said it forwards that model to another machine
(its `remote_host`, as for a cloud model after `ollama signin`), so the code
would leave this machine. Nothing was sent to it.

**Fix:** choose a model that `ollama show <model>` reports without a remote
host, or run without `--local-only` if the code may go to the host the message
names. If the message says the server revealed it only in an answer, that one
request's prompt did leave the machine, and no further request was sent.

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

When git can see it, a file renamed with its content unchanged keeps its
concepts' answers and nothing is sent for it, in that pass and every later one;
the scan prints a line naming the files it kept that way, and `review` shows
each such concept as MOVED, at the path the file has now. Give
`--rerun-pure-renames 1` (or save it with `concept-scanner init
--rerun-pure-renames 1`) to re-run the discovery calls that held them instead.
A renamed file that was also edited is re-read like any changed file.

**"--changed: the only change since the last pass is N file(s) renamed with
their content unchanged ... so there is nothing to re-read".** That is the
default above, refusing a pass that would send nothing. The next pass that runs
carries the move; `--rerun-pure-renames 1` re-runs them now.

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
found the concept and nothing has re-asked what the file now does, or a later
pass re-read it and did not find the concept again while its symbols still
resolve; the notice shows the two content hashes so you can see what changed. A
concept a later pass re-read and found again is current. RETIRED means the
symbols its description names are no longer in the file it cites, and it lists
them; a concept naming no code symbol is retired when a re-read of its file did
not find it again, since nothing else can check it.

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
of 3 passes, 41 concepts`. From a later pass's id it reviews that pass alone if
no pass continued it, and otherwise what the passes after it hold, which
includes the passes before it.

Two widenings of one scan are two branches, and the root's review reads both.
A concept found more than once, on two branches or by a later pass that re-read
its file, is shown once and its other records are listed as shared: the same
file, and the same name or the same two or more code symbols named in its
description, so a concept a model renamed between passes is still one. A pass the review leaves out is named under NOT
SHOWN with why: no union record includes it, its concepts cannot be loaded, or
they are concepts that pass does not ship (a pass's documentation concepts in a
repository with code are not shipped, so they are not reviewed).

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
quit under a command that can change something: a scan, a save, a review
decision or an export. Stop the scan from the Running screen, or wait for it to
finish, then quit. Commands that only read, including the ones the window runs
to fill its own screens, never keep it open; they are stopped with it.

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
