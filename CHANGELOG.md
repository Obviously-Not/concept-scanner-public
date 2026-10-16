# Changelog

All notable changes to concept-scanner are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are the
`v*` tags in this repository.

## [Unreleased]

## [2.1.0] - 2026-10-16

**This release changes no part of the output contract** (the concept, the bridge and the scan result keep
schema 2.0.0), so a program reading 2.0.0 output needs no change. Its changes are in what a run says about
itself, what it refuses and when, and in five records that are not the contract, each with its own schema
version: the refusals ledger (2.0.0, its `rule` field removed), `redundancy.json` (1.3.0), `tests.json` (2.5.0),
a dry run's saved plan (1.5.0) and `arc.json` (1.13.0).

### Added

- **A scan says what it found, what shipped and where the rest went**, in one
  account its summary, its run caveat (the `--json` notice, the `Coverage:`
  line, the closing caveat and the GitHub Actions summary) and its next steps
  all read: how many concepts it found, how many shipped, and how many were
  held back by the gates, cited a file that could not be found, repeated a
  concept of the same name in the same file and were folded into it, were
  documentation claims merged into the code concept of the same name, or were
  documentation concepts kept as context for Pass 4 and not shipped
  (`--characterize-docs` ships them). The parts add up to what was found.
- **`review --json` and the `review` list say how many concepts each
  lineage's passes held back** (`held`), counted from every pass's refusal
  ledger, and `review --json` gives the step that shows them (`held_back`),
  from the pass whose ledger holds them. The terminal says the count in its
  header, after `--set` and in the stored-scans list; the window says it on
  the lineage's line and in a Held back column on the Scans screen.
- **A scan that failed or was cancelled says where it stopped**: the stage
  and how many of its steps were done, as `stopped_in` in its `status.json`
  and on the `run_end` event of `--progress jsonl`, in its closing line
  ("Cancelled after 3m in Pass 2 classification, 4 of 9 steps done"), in
  `status`, and in the window's job view and last-run card. `status` also
  says, beside the path of a stopped run's `unfinished.json`, what that record
  kept (`unfinished_kept` in `status --json`).
- **`tests.json` counts the test files it read** (`test_files_read`, schema 2.5.0), and is written only when a
  test file was found beside a shipped concept.
- `concept-scanner cache clean` empties both caches this program keeps in your user cache folder (a multi-model scan's per-file extractions, and the discovery answers) and says how many entries and how much space each one freed. With `--json` it answers with the same counts, and the window reaches it from All commands. Nothing is lost: the next scan asks the model again.
- A run's record of its model calls (`calls.jsonl` in the run's folder) says the output budget each call was actually sent with: `num_predict_sent`, and `num_predict_first_sent` when the budget was raised after an answer was cut off. `num_predict` is still the budget the stage asked for. A call that failed now carries the input check's verdict (`input_check`), and a call whose prompt the server cut says `cut` with how much of the prompt the server read.
- `redundancy.json` (schema 1.3.0) lists every concept a scan folded into another before it shipped: the folded concept's name and file, the concept it was folded into and whether that one shipped, and where the fold happened. Folds across files, where one title can be two mechanisms, are counted apart, and the scan's redundancy line counts them. What a scan ships does not change.
- A scan says how many of the concepts it ships carry contributors from git blame, and what contributors cannot say (who last wrote the lines, never who designed the mechanism). The GitHub Actions summary has an Authorship row.
- A scan that reused a cached discovery answer prints the discovery cache's limits under its cache line.
- A dry run of a `--changed` re-read names the files it judged changed (the first three, and how many more). The saved plan, and `scan --dry-run --json`, carry the whole re-read plan under `rescan`: the changed, deleted, renamed and dependent files and the batches it would re-run (saved plan schema 1.4.0).

### Changed

- **A concept's license findings state facts and give no advice.** Each
  `license_risks` entry's `impact` now says what the dependency's license is
  and what its terms reach (a strong copyleft license reaches a distributed
  program that includes the library; a weak one, the library's own code), or
  that its license was not recognized, could not be read, or was not found.
  It no longer tells the reader what to do: "ACTION REQUIRED", "Consider:
  replace, isolate or document a compliance plan", "Before filing, manually
  verify" and "Treat as proprietary" are gone. The output contract's shape is
  unchanged; only these strings are.
- **The scan's `License:` line, and `license_stats.summary_message` in
  `--json`, say what was found rather than "License review needed".** It
  reads, for example, "License check: 12 dependencies analyzed; the concepts'
  license_risks hold 3 entries for a copyleft license", counting entries
  (one library imported by three concepts is three), and says "License check
  incomplete" whenever a manifest could not be analyzed, also when risks were
  found beside it, where it said "review needed" before.
- **The summary after a scan prints "Concepts shipped"** for what shipped, and
  "Concepts found" for what the run found, where it printed the shipped count
  as "Concepts found", so a run that held back every concept it found said it
  found none. A "Not shipped" line says where the rest went. The window's Scans
  column "Found" is now "Shipped".
- **The step to see what the gates held back counts only what they held back
  or dropped**: a shipped concept the refusal ledger records as incomplete is
  no longer counted as held back, and a scan whose ledger holds only such
  concepts offers a step to see why they are marked incomplete.
- **`review` on a lineage that holds nothing to decide but held concepts back
  leads with what was held back and the re-run that keeps them**, instead of
  "Scan another repository". The window's "What was held back" follows that
  step, so it lists the holds of the pass that has them (a widening's, when
  the widening held them), where it listed only the first scan's.
- **A `--changed` scan's caveat says its files changed or shared a recorded
  batch with a file that did, and how many changed**, where it said every file
  it read had changed.
- **A scan beside whose concepts no test file was found says "Tests: no test
  file was found beside the shipped concepts" and writes no `tests.json`**,
  where it said "0 of N shipped concepts are paired" and named a `tests.json`,
  a documentation-only scan included.
- **`status.json` is schema 1.4.0** (`stopped_in` added; nothing removed).
- **`scan --multi-model` with no second model saved runs the default second
  model**, as `--secondary-model`'s help always said: the saved profile's
  second model, else `gpt-oss:20b` on Ollama, else the default grader for the
  endpoint's catalog. On the Balanced profile it runs Validated's two models.
  It was refused ("requires a secondary model") after the models were readied,
  so a first run could download the discovery model and then stop. The Models
  line says `(the default)`, and the models screen and the window's models card
  show the default on the second model's row.
- **A link in the repository that leads nowhere no longer stops a scan.** A
  link whose target does not exist, or links that loop, are left out and
  counted on the excluded-files lines ("left out 2 links: 1 into a .git folder,
  1 resolving to nothing"), with the links into a `.git` folder, which were
  left out without a word. Until now one such link anywhere in the repository,
  inside `node_modules` included, refused the whole scan. A link that leads
  outside the repository is still refused.
- **A saved output budget, or a `CS_BUDGET_*` variable, that cannot be used is
  set aside alone and said once when the command starts**, with the command
  that removes it, as a saved default is. One that is not a whole number, or is
  outside 1 to 262144, is set aside and the next value applies; until now one
  value that was not a whole number set every saved budget aside, a saved 0 or
  a bad variable was ignored without a word, and a value above the range was
  used. `init --json` names each one in its row's `saved_problem`, and `init`
  accepts a save that repairs every damaged budget (`init --reset <name>`, or a
  new value), where it refused every budget save.
- **A settings file that cannot be read (its permissions, or a folder in its
  place) is said once when a command starts**: the run then uses no saved
  profile, provider, default or budget. It was read as empty without a word.
- **A `--multi-model` scan sends each call's output schema to any local
  model.** It sent a schema or JSON mode only to the models in the tool's own
  list, and left every other local model to the prompt, where the default scan
  sends its schema to every model. Because the request changes, an unlisted
  local model's cached multi-model extractions are not found once after
  upgrading, and each file is extracted again on the first scan that reads it.
- **The refusals ledger (`refusals.json`) is schema 2.0.0: each row's `rule`
  field is removed.** It named the internal function that recorded the row,
  which no setting matched. A row is named by its `verdict`, whose gate,
  explanation and settings `refusals` and `review --why` give. A ledger
  written by an earlier version still reads; its `rule` is ignored. A verdict
  this version does not know is named by the verdict itself. `refusals --json`
  and `review --why --json` explain a verdict in the same words.
- **Every `--json` answer prints `<` and `>` as written**, so a next step's
  `<concept-id>` reads as it does in the terminal, where it was escaped. The
  same holds for the files a scan writes beside itself, the stored concepts,
  the refusals ledger, `submit` drafts and the `--progress jsonl` events. A
  JSON reader decodes both forms to the same value. Every command's `--json`
  answer now also replaces a model's terminal control characters, as the
  scan's did.
- **Next steps say what fits what happened.** `synthesize` with no pattern
  offers to review the scan's concepts, where it offered "the concepts these
  patterns combine". `triage` with nothing to do leads with reviewing the
  scan, where it said "Triage grounded 0 concepts". The scan's review step
  counts what review lists, documentation concepts shipped with
  `--characterize-docs` included, as "shipped concepts". No step states a
  count of zero.
- **The setup screens:** each screen starts with an empty row, so "Step 1 of
  4" no longer sits against the line above it. No blank row is kept where the
  spinner was once it stops. A long total on step 3 (the Selected line) wraps
  at spaces instead of being cut mid-word. The setup says "first-run setup"
  only when nothing is saved yet, and "setup" when `init` runs again.
- **The ready screen no longer shows the command in its card**, where it
  wrapped and could not be copied in one piece. After `s` starts the scan,
  "Run it with: <command>" is printed once, on one line, above the scan's
  output, as `d` already printed it beside the saved plan.
- **A profile is named with every model it reads files with**, for example
  "Validated (two-pass) (qwen3-coder:30b + gpt-oss:20b)", in `models`, the
  "Using saved profile" line and the profile menu. `models` names the
  recommended profile by its name and models, where it printed its key.
- **A multi-model scan's agreement line says "2 steps of the multi-model path
  degraded, each named in agreement.json"**, where it said "2 degraded steps
  listed under warnings" beside a closing line that counts the warnings the
  run logged.
- **`figure draw` and `figure apply` name what a size or layout rule cut**
  ("3 arrows refused, 2 arrow labels cut"), where they said "1 value cut,
  refused or merged".
- **`arc.json` is 1.13.0 and a saved plan 1.5.0**: each estimate adds
  `tokens_fitted`, whether its source tokens were fitted from the model's
  recorded calls.
- **A setting is renamed, and its meaning changed:** `pbd-cache-max-age` is now `cache-max-unused-age`. It is how long an entry of either cache may go unused before a scan removes it, 30 days built in, and 0 keeps every entry for ever. It was how long a multi-model extraction was served (built in 0, and an expired entry stayed on disk). A value saved under the old name is ignored and a scan says so; save one under the new name with `init --cache-max-unused-age <duration>`, and remove the old one with `init --reset pbd-cache-max-age`.
- Both caches now remove an entry unused for that long when a scan opens them, and an entry a scan reuses counts as used. Until now nothing ever removed an entry of either cache, so both grew with every repository scanned.
- The audit and cost logs are written readable by you only, and an existing one is tightened the next time it is written.
- The audit log no longer records the committer's email address in plain text. Its author hash is now the same hash a concept's contributors carry, so one author has one hash in both.

### Fixed

- **When the `go` command is not on your PATH, the license line says so.**
  It read "1 manifest could not be analyzed, see dependency_map.errors"; it
  now reads "License check incomplete: the go command was not found on PATH,
  so the Go module's dependencies were not analyzed". This is the usual cause
  in the container image and the GitHub Action, which do not include `go`.
- **A bridge never ships with fewer distinct concepts than
  `--bridge-min-components`.** An answer that named one concept twice shipped
  as a two-concept bridge of one concept, an answer naming one real concept
  beside an unknown id shipped as a bridge of one, and with
  `--bridge-min-components 3` an answer that narrowed three concepts to two
  shipped as a pair. Each concept is now counted once, and such an answer is
  declined and counted in the bridge pass's log line
  (`too_few_members_declined`), beside the unnamed and unscored ones.
- **`scan --parallel=false` is refused on a single-model scan**, where it was
  read and ignored, with the same remedies as `--merge-model` (add
  `--multi-model`, or drop the flag). `--parallel` given on its own is the
  default and is never refused.
- **A multi-model scan whose second model is its discovery model is refused
  before anything is downloaded or sent**, with a form to give
  `--secondary-model` another model, and the two are compared as the server
  names them (`qwen3-coder` and `qwen3-coder:latest` are one model). It was
  refused after the models were readied, by raw name.
- **A remote catalog with no default model is refused with a form to give the
  model** (`--primary-model`, `--secondary-model`, or on `bridges`, `triage`,
  `synthesize` and `figure draw` `--extract-model`), and a scan refuses it
  before it reads or clones the repository. Its first step was a re-run with
  `--verbose` that would be refused the same way. A remote single-model scan
  under `--skip-review` no longer needs a default grader it never calls.
- **A `--json` answer that cannot be written is the command's failure**: it
  exits 1 with an error envelope. Until now a value JSON cannot hold printed
  nothing and the command exited 0, and `scan --json` printed its human
  results on standard output instead.
- **A model answer that broke its format is no longer read as a verdict.**
  Triage read an empty answer (`{}`, or an object without the field it asks
  for) as "the concept is not in this file", so a concept could be dropped as
  not found because of a malformed answer; such an answer now counts as no
  answer, and a concept no candidate answered stays pending. The batch
  suggestion, test evidence (`--tests evidence`), TLDR and enriched-summary
  calls and a `--multi-model` scan's synthesis read the same answers as a
  successful answer naming nothing; each now counts it as unreadable, which the
  run already reports for that stage, and the synthesis asks the model to
  repair it and fails the scan when the repair cannot be read either, where it
  reported zero concepts.
- **A valid answer that quotes a code fence is read as it came** in the bridge
  call and a `--multi-model` scan's synthesis, which stripped fences before
  reading and so lost a bridge, or spent a second repair call on a repair
  answer that was never broken. Triage, batch suggestion and test evidence also
  read an answer wrapped in a fence or after a line of text, which they refused.
- An answer from an OpenAI-compatible endpoint that was cut off at its output budget now names the budget it was sent with, as a local one does, instead of "the backend default".
- **`scan --depth N` takes effect on a scan with no coverage flag.** It was
  accepted and ignored there: the files were batched at the depth derived from
  their sizes, and the `Depth:` line said so. It now sets the depth on every
  single-model scan, and the line says it was set.
- **A model server on this machine that does not answer is said to be down on
  an OpenAI-compatible scan too.** The scan ends with "Start the model server
  at ..., or point --base-url at one that is running", exit 3. Until now it
  told you to describe the model, or, with the model described, failed every
  discovery batch with general steps.
- **A multi-model scan whose second model's synthesis named no concept says
  so.** The agreement line read "4 by the primary only", which looks like the
  two models disagreeing; it now says the second model's synthesis named no
  concept, so the shipped concepts are the other model's alone, and
  `agreement.json` lists it among the steps that degraded.
- **A `--resume` that is refused names the repository the stopped run read** in
  its step to run the scan again, where it showed `<repo-url-or-path>`.
- **The progress heartbeat no longer waits on the disk.** A running scan's
  status file was synced to disk under the same lock as every line the console
  prints, so while another program wrote heavily the plain heartbeat, promised
  every 30 seconds, came up to 47 seconds apart. The status file is still
  replaced whole, never half-written, and is no longer synced; every other file
  this program writes still is.

### Window

- A command's rules are listed in the normal colour, and one the form breaks
  is marked as you fill it in, where all of them showed in the warning colour
  on an empty form. The saved keys in Settings are no longer shown as a
  warning either.
- The models card on the scan form and in Settings no longer repeats the
  `models` command's next steps while the local model server answers; what to
  do when it does not still shows. The Running screen no longer repeats its
  help steps beside the last run's card when nothing is running.
- A page opened without its sign-in code shows only the banner that says to
  open it again, where the refusal text also showed under it.
- All commands shows a command's answer the way every other screen does: its
  notice, its result, then its next steps.
- Each row of the Scans table names its scan's id, when it started, and the
  flags its files were collected with when it recorded any, so several scans
  of one project can be told apart.

## [2.0.0] - 2026-10-14

**This release changes the output contract to 2.0.0** (the concept, the bridge
and the scan result's `--json` envelope): a program that reads 1.x output must
update. What changed is listed under Changed, "The output contract is 2.0.0".

### Added

- **`help --json` says which runs of a command change nothing**
  (`query.writes`: the flags that make a run change something, on `models`,
  `status`, `review` and `init`).
- **A scan's `--json` envelope says whether its model calls were billed per
  token** (`billed_per_token`, always present: true when the inference left
  this machine, false for Ollama wherever it runs and for an OpenAI-compatible
  server on this machine). The scan's `notice` carries the sentence the
  terminal's summary prints about the cost, such as "Cost: $0.0000 (Ollama, not
  billed per token).", and the window shows it beside a finished scan's cost.
- **`help --json` lists, for each argument a command can need, the text it
  refuses a command line without it with** (`args[].message`), and for `scan`'s
  repository the flag that stands for it (`args[].required_unless`: `--resume`).
- **More options on the window's review, export, figure and Settings
  screens**, opening the command with what the screen already has.
- **`help --json` lists each required option as a rule** with the text the
  command refuses it with.
- **`review --json` gives each concept the lines review prints before you
  decide** (stale with why and both content hashes, retired with the symbols no
  longer in its file, moved with its file, found again by another pass) as
  `concept_disclosures`, and the lineage's header, members that could not be
  loaded and passes not shown included, as `lineage_header`, word for word as
  the terminal prints them.
- **A running command's status line is in its `status.json` and on every
  `--progress jsonl` event as `status_line`**: the stage, the call timer, the
  time left for the stage and the whole scan or "rest unknown", a retry, tokens
  and cost, exactly as the terminal's live line shows them. `status` prints the
  same line.
- **`models` takes `--provider`, `--base-url` and `--ollama-host` as a scan
  does**, and says whether a scan given them runs on a remote provider
  (`choice.remote`, `choice.provider_saved`, and a line in the table).
- **With a repository's saved setup, `scan --dry-run --json` gives the
  arguments that run it again with no setup call** (`saved_setup.args`), saved
  picks and coverage included, and says why when there are none
  (`saved_setup.args_note`).
- **`help --json` lists each rule between flags with the words a command refuses
  it with** (`message`), marks required flags (`required`), and lists
  `distill gate`'s "one of `--incumbent` or `--calibrate`" and `status
  --running` with a run id.
- **`agreement.json` says, for each concept both models named, whether their
  concepts cite a common file**, and counts those that cite none. The grouping
  and the labels are unchanged.
- **A characterization answer that leaves out the technical distinctiveness
  score is asked once more** with the same request; the score is taken from the
  second answer only when it carries one, and nothing else of that answer is
  used.
- **A scan says how many of the concepts it ships carry no technical
  distinctiveness score**, which the score floor cannot judge: in its closing
  caveat (the `--json` notice and the Coverage line) and as `unscored_shipped`
  in the scan result.
- **A concept with no line range carries `contributors` and
  `authorship_caveat`** when it is in a Go file and its own text names
  declarations of that file: git blame runs over those declarations' lines,
  each line counted once. Discovery writes no line ranges, so until now no
  concept carried contributors. Other languages still get none without a range.
- **A scan started on the setup screens can be resumed.** When strict Pass 2
  validation stops it, its record holds the flags that make the choices made
  on the screens, with the plan they chose saved in your home folder
  (`~/.concept-scanner/repos/<key>/plans/<scan-id>.json`), so the resume
  command it prints runs the same scan without the screens and makes no setup
  call. Only a plan that could not be saved leaves a run that cannot be
  resumed, and the record says why.
- **`models` answers for a choice of models**: it takes the scan's model
  flags (`--primary-model`, `--draft-model`, `--secondary-model`,
  `--multi-model`, `--skip-review`, `--thorough`), and its `--json` gives the
  choice a scan given them would run: each role's model, the form values that
  run it, what would be downloaded, whether it is what a scan with no model
  flag runs, and the `init` arguments that save it. Its human output names the
  choice too. The window's models card shows that answer and applies no rule
  of its own.
- **`init --secondary-model` and `init --multi-model`** save a grader or a
  second model of your own (a multi-model profile needs its second model),
  so the window keeps such a choice as the terminal's models screen does. A
  lone `--secondary-model` replaces the saved profile's grader, as a scan
  reads one.
- **`synthesis_cost.cost`**: what Pass 5's calls cost, in US dollars (0 when
  the run is not billed per token, `null` when a call could not be priced).
- **`status` says why it offers no resume** (`resume_refused` in `--json`,
  and in its human output and the window's Running screen).

- **A next step that needs a value opens its command's form.** A step such as
  "try a different model" now carries `prefill`, the arguments it has, and
  `fill`, each value still to give, so the window opens the form with them in
  place; `args` still means a step that runs as it is, and a step has one or
  the other.
- **`scan --resume` is offered where a stopped scan is reported**: a scan that
  strict Pass 2 validation stopped leads its failure with the resume step,
  `status` of the stopped run offers it, and the window's Running screen shows
  a Resume card (`unfinished.json` 3.1.0 keeps the resume arguments).
- **The values a run changed are in its progress stream and its status file**:
  `run_start` and `status.json` (1.2.0) carry `settings_changed`, and the
  window shows them.
- **`arc.json` 1.9.0 says what kind of pass a scan was** (`pass_kind`: a first
  ring, a widening, or a re-read), and a re-read's caveat says its files
  changed.
- **The window:** a stored scan's Widen and Re-read buttons appear only when
  `review --json` offers the step (`widen`, `reread`), widening from the newest
  pass as the terminal does; Export appears for a submitted concept only when
  an export would change what was sent (`export_changed`); every table scrolls
  on its own and, below 720 pixels, the tabs take their own row; Settings shows
  each saved value; a number field alone carries a minimum and maximum; a form
  refuses a combination of flags its command refuses, in the command's words,
  before running; and `ui`, finding a window already running, names each value
  it keeps from when it started that differs from the one given or saved now.
- **A models screen before the other setup screens**, in the terminal and in
  the window's scan form: each role a scan calls (discovery, drafting,
  grading, and the second model of a multi-model scan), opening on the
  profile this machine's memory recommends unless a flag or the saved profile
  chose, and changeable among the supported models. Every model a run calls
  is readied before its first call, a download is announced before it starts,
  and `--no-auto-pull` refuses the run naming every missing model at once, on
  every command that calls a model. `models --json` gains `calls`,
  `model_roles`, `opens_on`, `default_grader`, `choice` and `download_bytes`.
- **`scan --resume <run-id>`** resumes a scan that strict Pass 2 validation
  stopped, from its `unfinished.json` (now 3.0.0), re-using every batch the
  stopped run finished. It is refused, with the reason, when the repository's
  files, the models or the scan's settings changed since; the stopped run's
  error prints the exact command.
- **`--rerun-pure-renames`**: by default a covered file renamed with its
  content unchanged keeps its answers and is followed, in every later pass;
  `1` re-runs the compositions that held it.
- **What served a call and what it cost, where the endpoint says**:
  `calls.jsonl` rows gain `served_by` and `cost_reported`, `models.json`
  (1.7.0) gains `served_by`, a reported cost is counted by the spend ceilings
  and charged in the envelope, and a closing `prompt reuse:` note says how
  much of each stage's prompts a server reused.
- **`--characterize-docs`**: on a repository that is not docs-only, its
  documentation concepts are characterized and gated as code concepts are, and
  ship as concepts. Without it they stay context for documentation matching, at
  no extra model call. The setup screens offer the same choice, saved for the
  repository, and the window's scan form offers the flag.
- **`tests.json` 2.2.0 says how each paired test was found** (`found_by`:
  beside the code, or by importing it).
- **A concept no axis scored says "not scored"** in the scan's output and in
  `SUMMARY.md`, which lists such concepts in a section of their own, never as
  0%.
- **Each concept of a `--multi-model` scan says how the two models met in it**
  (`model_agreement`, Concept 1.14.0): whether both named it, described it
  differently, or only one did, or why no merge judged it; which models named
  it; and the merge model's own note. A single-model scan carries no
  `model_agreement`. Until now the same record reached only `agreement.json`
  beside the scan. A platform that has not declared the key yet reports it and
  does not store it.
- **93 more defaults can be changed** (the defaults plan's second wave): the
  model transport (each client's request timeout when a command gives none, one
  retry policy for both clients, requests in flight, the remote warm-up's wait
  and cap, the truncation escalation, the introspection and pre-flight
  timeouts), the context windows (the caps, the template margin, characters per
  token, the window floor, and the cut and ceiling tolerances), the memory
  sizing behind the model picker, the spend alert share, batching and depth,
  the largest file a scan reads (one setting for both scan paths),
  characterization's retries and the gates on what ships, the intent and locate
  calls' limits, the time estimate's priors and floors, distill gate's
  calibration bars and judge cap, the `--record-examples` capture budget, and
  how much of a child process's error output is kept. The ten flags these
  values already had (`--timeout`, `--parallel-batches`,
  `--bridge-max-components`, `--bridge-max-candidates`, `--min-doc-relevance`,
  `--enrich-threshold`, `--min-synthesis-score`, `--max-patterns`,
  `--triage-max-candidates`, `--triage-min-keywords`) keep their names and can
  now be saved with `init` and changed in Settings.
- **`anchoring-check` says how many words the open arm named alone**
  (`open_only_count`), as it does for its other two lists.
- **The window groups the values each command takes by area, with a search,**
  and says each value's range and built-in value. A form's values sit in a
  Defaults block, one closed group per area, opened by a search or by a value
  given in it; a field left empty takes the saved value, else the built-in
  one. `help --json` gives each flag that sets such a value a `setting` (its
  key, area, what it bounds, built-in value and range), and each `init --json`
  defaults row gains `range_text`.
- **A local server's window is read from the server, where it says.** On
  `--provider openai-compatible` with a server on this machine, the window is
  read from llama.cpp's server (its slots, or its properties when slots are
  off) and from LM Studio 0.4 and later for a model already loaded, and from
  vLLM's model list on any endpoint; a run measures only a server that says
  nothing. The reader is chosen by which server answers in its own shape, never
  by the address. A declared window meets the same 8,192-token floor as a
  measured one, and the run says which server gave it.
- **A server's refusal that names its window sizes the run.** llama.cpp's server
  and vLLM refuse a prompt longer than their window and say how many tokens
  they hold. Where the measurement meets that refusal (the server's own API is
  out of reach, so nothing declared the window), the run is sized for the
  window named, down to 8,192 tokens, where it was refused as holding a window
  nothing could size.
- **A run asks about a model nothing describes.** On `--provider
  openai-compatible`, a model whose window nothing gives (the endpoint's list, the
  models this tool recommends, a measurement on this machine, or your own
  description), or off this machine whose largest answer nothing gives, is asked
  about once at a terminal and the answers are saved for that endpoint; with
  nobody to answer, the run stops before sending anything, exit 1, with the
  `models describe` step. Before, such a run went ahead and said only `input
  truncation: NOT CHECKED`. The note that called an unlisted local model "not
  in the curated list" is gone.
- **`models describe <model>`** says what a model is for the endpoint the
  provider flags name, and every later run on that endpoint uses it: the context
  window its server applies (`--window`, for an OpenAI-compatible endpoint), the
  most tokens it writes in one answer (`--max-output`), and its think value on
  Ollama's own API (`--reasoning`, or `default` to send none). On an
  OpenAI-compatible server on this machine, `--measure` measures the window with
  three prompts and saves it. A model this tool recommends carries these
  already. `models` now runs and has this subcommand.
- **236 more defaults can be changed** (the first wave of the defaults plan's
  conversion): the gates on what ships (the classification ceilings, the
  near-duplicate threshold, test pairing), Pass 3's bridge scoring and Pass
  5's weights, floors and context sizes, every timeout, retry and lock wait,
  the security limits (repository size and file count, archive ratio,
  manifest, update and window sizes), the sampling values, the model-answer
  and figure size limits, the coverage-ranking weights, the console's
  heartbeat and staleness, the window's port and run limits, and the bench,
  anchoring-check and quality-gate numbers. `--<key>` for one run on the
  commands that read it, `concept-scanner init --<key> N` to save,
  `init --reset <key>` to remove; `init --json` lists each with its range and
  the commands that read it. A scanned repository's `.env.local` or data
  directory cannot set any of them. Flags these values already had (`bench
  --n`, `--max-tokens` and `--timeout`, `distill prepare --train` and
  `--valid`, `distill gate --bar` and `--min-examples`, `anchoring-check
  --timeout`, `ui --port`) keep their names and their place in `--help`, and
  `bench` and `anchoring-check --timeout` now default to a deadline derived
  when the run starts.
- **Single-call bridge synthesis sends an output cap**, `--budget-bridge`
  (`CS_BUDGET_BRIDGE`, 4096), and the bridge extract model's warm-up sends the
  warm-up cap; both sent none.
- **A run says when it uses a value other than the built-in one.** Before a
  command starts, one line names each default or output budget its run reads
  that differs from the built-in value, with the value and where it came from
  (a flag, a value saved with `init`, or a `CS_BUDGET_*` variable). The
  `--json` notice ends with the same sentence. A scan records the values in
  `models.json` (1.3.0) as `settings_changed` (`key`, `value`, `built_in`,
  `source`, and `env` for a variable): `[]` when none differed, beside
  `settings_residual`, which says what the list cannot see.
- **Every default can be changed, starting with how a coverage plan ranks
  files.** `concept-scanner init --<key> N` saves a default for every command
  that reads it; `init --reset <key>` removes one, and `init --reset all`
  removes every saved default and output budget. A command whose run reads a
  default takes the same flag for one run, for example
  `scan --page-rank-damping 0.7`. The first six are `page-rank-damping`,
  `folder-edge-weight`, `omnipresent-factor`, `page-rank-iterations`,
  `page-rank-tolerance` and `lift-precision`; the rest follow. Each has a range,
  held when the flag is read. Saved values go in a `"defaults"` section of
  `~/.concept-scanner/settings.json`, and no environment variable sets them.
- **`init --json` lists every adjustable value in one `defaults` list**, the
  output budgets as their own area: each row gives the value in force, where it
  came from (`built-in`, `saved`, `flag`, or a budget's `environment`), the
  built-in value, the saved value, the range, the commands that read it and the
  step that resets it. It replaces `output_budgets`, and `budgets_problem` is now
  `defaults_problem`. The window's Settings screen has a Defaults card in place
  of the budgets card, grouped by area, with a search field, Save and Use
  built-in, and `init` prints the values you set.
- **Every output budget can be changed, in the terminal and in the window.** An
  output budget is the most tokens a model may write in one answer, per kind of
  call. `concept-scanner init --budget-<name> N` saves a default for every
  command that reads it (`0` removes it); `init --json` lists each budget's
  value, where it came from (built in, saved, or a `CS_BUDGET_*` variable) and
  the commands that read it, and `init` prints the ones not at their built-in
  value. The window's Settings screen shows the same list and saves through
  `init`. For one run, `--budget-<name> N` is on each command whose run reads
  that budget (`help --json` lists them); `synthesize --budget-pass5` and
  `anchoring-check --budget-discovery` are new. A value outside 0 to 262,144 is
  refused.
- **`--local-only`** on every command that calls a model (`scan`, `bridges`,
  `triage`, `synthesize`, `figure draw`, `anchoring-check`, `bench`, `distill
  gate`, and `tiers run`, which passes it to every arm): it refuses before any request, exit 1, unless the model server is
  `localhost` or a loopback address, judged from the `--ollama-host` or
  `--base-url` host and never from the provider, so a server on another
  machine, a LAN address included, is sent nothing. It is never saved and no
  environment variable or `.env.local` sets it, so give it on every run.
  It also asks a local Ollama, before the first request, whether it runs each
  model on this machine (Ollama's `remote_host`, as for a cloud model after
  `ollama signin`), and refuses one it forwards elsewhere, naming the model,
  its flag and the host; if a server says so only in an answer, the run stops
  after that one request, exits 1, and says the prompt left the machine. An
  OpenAI-compatible server on this machine that is not Ollama cannot be asked,
  and the run says so. Refused, it offers this machine's server as a runnable
  next step.
- **A `--base-url` whose query string carries a key-like parameter is
  refused** (`key`, `api_key`, `access_token`, `sig`, `code` and similar),
  before anything is sent or saved, exit 1, naming the parameter and never its
  value, whether it was given on the command line, to `init`, or saved by an
  older version. Give the key in the environment or with `init --with-key`.
  Parameters such as Azure's `api-version` are kept. Printed next steps and
  `init --json` never repeat such a parameter.
- **Every scan records the settings that chose its files** (`--only`,
  `--exclude`, its drops and the rest of what decides the universe) in
  `file-set.json` beside it, which `synthesize` applies.
- **A suggested next step that calls a model carries how you ran**: the
  `--provider`, `--base-url`, `--ollama-host`, `--local-only`, `--thorough`
  and model flags you gave on the command line, only those its command has,
  never one it already sets, and never a user or password written into a
  server address. A saved provider needs none and gets none. "Or use the
  local default provider" now types `--provider ollama`, since leaving it out
  ran a saved remote provider.
- **A scan run with `--parallel-batches 1` reuses discovery answers.** Each
  discovery request's answer is kept in your user cache folder, and a later
  scan sending an identical request (same files and contents, same model and
  server version, same settings) reuses it instead of asking again, so a
  re-scan after a small edit asks only for what changed. Every scan prints a
  `Discovery cache:` line with what it reused and saved, and checks one reused
  answer by asking again (a local server only); `--verify-cache` checks every
  one and exits 1 if any differs, or if the cache was off and it checked
  nothing, and says which on stderr. A check that finds a difference stops reuse for the rest of the
  scan. Scans running batches at once (the default, 4) reuse nothing, and say
  so in their notice; two-phase, `--multi-model`, `--record-examples` and
  `tiers run` arms never reuse, and `CS_DISCOVERY_CACHE_OFF` turns it off.
  The key holds only what decides a discovery answer (the request text, the
  model's identity, the server's version, the options and the output schema),
  so editing Pass 2's criteria or an unused criteria string does not invalidate
  it; a cache from an earlier development build misses once
  (`discovery-cache/3`).
- **A `--multi-model` scan says which concepts both models found.** Until now
  only the primary model wrote concepts, from the files both models had read.
  Now each model writes its own, and one more call groups the two lists by
  mechanism; no concept from either model is dropped. `agreement.json`, beside
  the scan, says which shipped concepts both models named, which they described
  differently, and which only one of them named, and the scan prints a
  `Model agreement:` line. If one model's step fails the scan keeps the other's
  concepts and says so. This costs one more synthesis call and one merge call
  per scan. The same file also says, for each file, how the two models'
  readings of it compared and whether it reached the concepts (`per_file`),
  which model server each step sent your code to and whether that server is
  this machine (`data_flow`), and every step that degraded and why
  (`warnings`), and how many tokens each model's synthesis call and the merge
  call used (`at_merge`, `agreement.json` 1.2.0).
- **A remote scan shows its estimated cost in US dollars before it spends**: on
  the setup screens, in `scan --dry-run` (and its `--json`, per ring:
  `discovery_usd`, `whole_low_usd`, `whole_high_usd`, `prices_as_of`,
  `prices_stale`, `money_basis`, `whole_money_basis`, `ceiling_warnings`), and
  in a line before the first model call. It is priced from the same forecast as
  the time estimate at the model shortlist's dated prices, says when it cannot
  be estimated and why, and the run records what it actually cost in
  `arc.json` (now 1.5.0; saved plans 1.2.0).
- **Opt-in spend ceilings for remote runs**: `BUDGET_PER_OP` (one run),
  `BUDGET_DAILY` and `BUDGET_MONTHLY`, in US dollars, set in the real
  environment. With one set, a run warns at 80% and, at the ceiling, sends no
  further model call and exits 1 saying which ceiling and what to change; an
  estimate that already reaches it is warned about before the scan starts.
  Unset or 0 means no ceiling. The old defaults of 10, 50 and 500 dollars,
  which nothing ever enforced, are removed; an unreadable value now stops the
  command, and `.env.local` may no longer set them.
- **`--keep-dir <name or path>`** (scan, triage) reads a folder the scan would
  skip by name as generated output or a cache, and every run now says which
  such folders it skipped and how many files each held. This tool's own data
  folder is never read, matched by its path.
- **A scan says why semantic batching (Avenue B) was skipped**, on its Avenue B
  line rather than only in a debug log: mixed project files, no project file or
  readable document, several languages below the root, a language this build
  cannot encode (named, with its file count), or a failed or empty encode.
- **`anchoring-check` compares three requests**: one carrying no discovery
  criteria, the one a scan sends, and one naming fixed categories. It reports
  NOT COVERED when naming categories does not change the model's answer (so the
  check cannot say anything about the prompt), and lists the words the criteria
  put into the answer. It asks with the discovery budget a scan uses.
- **Cloud prices older than 90 days are marked stale** wherever a price is
  shown, and `models --json` carries `cloud_pricing_stale`.
- **The intent search reads more project descriptions**: `composer.json`,
  `setup.cfg`'s metadata, `pom.xml`, R's `DESCRIPTION`, Poetry's table and a
  Cargo workspace's table.
- **A model answer cut off at its output limit that repeats itself (a loop, or a
  template with only a counter changing) is no longer sent again with a larger
  output budget**, which only bought more of the same: the call ends with the
  cut-off answer, and the warning, the cost log and the run's closing note say
  why. Answers that do not repeat are escalated as before. The new setting
  `repeating-cut-escalations` (default 0) sets how many times a repeating cut is
  still escalated: `--repeating-cut-escalations N`, or
  `concept-scanner init --repeating-cut-escalations N`; 64 restores the previous
  behaviour.
- **`scan --dry-run` keeps a repository's newest 20 plans and removes older
  ones, saying which when it does.** A plan a stopped run's record names is
  kept. Each dry run's plan is now named `dry-run-<id>.json`. The number is
  adjustable with `--dry-run-plans-kept`, `init --dry-run-plans-kept N`, or the
  window's Settings.

### Changed

- **A concept that characterization did not answer for says nothing of its
  technical approach or comparable techniques**: `technical_approach` and
  `comparable_techniques` are `null` on it, where they were `""` and `[]`. This
  applies to a documentation concept a scan did not characterize, and to a
  concept whose characterization failed or whose source could not be read. A
  characterized concept is unchanged: it always carries a `technical_approach`,
  and `[]` still says it named no comparable technique.
- **A concept classified as a standard technique (`textbook`) is held back only
  when characterization also scores it below the distinctiveness floor**; one
  scored at or above the floor now ships, with its classification. Every concept
  is characterized first, so a scan makes one more characterization call for
  each concept classified textbook. `textbook_held` counts concepts held back as
  textbook and `low_score_held` the other concepts below the floor, with no
  concept counted in both; each refusal row of either kind names the concept's
  classification and score.
- **Python concepts are paired with their tests** (`tests.json` 2.4.0): beside
  the module, and anywhere in the repository a test imports it. TypeScript and
  JavaScript are still not paired.
- **A scan of a subfolder pairs tests that live outside it, and `--tests
  evidence` reads them too.**
- **Under `--two-phase`, a batch made only of documentation is distilled
  through a frame written for documents.**
- **A missing or extra argument is refused by name, with a command to run.**
  `submit` given only a scan id says `<concept-or-bridge-id> is required: submit
  takes <scan-id> <concept-or-bridge-id>` and offers the command with the
  missing argument to fill in; an argument too many is named, with the command
  without it. It said `accepts 2 arg(s), received 1`, with no command to run.
  `scan` without a repository also offers `--resume`.
- **The window's form refuses a missing argument in the command's own words**,
  where it said "Fill in", and needs `scan`'s repository unless `--resume` is
  given.
- **`bridges` and `triage` on a stored scan with no concepts offer a scan to
  produce some and the list of stored scans**, as `synthesize` does.
- **`help`'s usage line reads `help [command]...`.**
- **The window shows every next step a command gives, as a terminal prints
  it**: its priority, what to do, the command and why. A step the window can
  follow is a button, and a step that points at a command's help opens that
  command's form.
- **Every screen of the window shows its command's notice and next steps**, so
  a failed or stale last run, a refused correction and a model server that is
  not running are said there, with what to do.
- **The window checks a command's flag rules before running it in the
  command's own words**, required options included, and marks a required
  option.
- **Reviewing a lineage in the window shows what review tells a reviewer in a
  terminal**: stale, retired, moved and also-found concepts, and the lineage's
  summary.
- **A running command in the window shows the status line a terminal shows**:
  stage, timer, time left, tokens, cost and warnings.
- **The window's models card follows the provider the scan form names**, and
  shows no local models for a scan that runs on a remote provider.
- **"Use it" on a project's saved setup fills the scan form with the command
  that runs that setup**, its picks and coverage included.
- **`triage --workspace`, `synthesize --workspace`, and `distill gate
  --candidate` and `--judge` are required flags**, refused before anything runs.
- **Every rule between flags is checked for every command before it runs**,
  and is refused in the words `help --json` lists for it. A switch given false
  counts as not given, in the command and in the window's form alike, so `scan
  --depth 2 --multi-model=false`, `scan --docs-only=false --exclude-docs`,
  `status --running --wait=false` and `ui --serve=false --stop` are accepted.
- **`--multi-model=false` and `--thorough=false` win over a saved profile for
  one run**, as every other flag does: `scan` and `models` given
  `--multi-model=false` beside a saved multi-model profile run single-model on
  that profile's primary model, and `--thorough=false` beside the saved
  Thorough profile runs the default primary model, in `scan`, `models`,
  `bridges`, `triage`, `synthesize` and `figure draw`. The saved profile is
  unchanged, and the line naming it says what the switch turned off. A scan
  refused for `--depth` under a saved multi-model profile now offers
  `--multi-model=false` for that run, beside saving another profile. The same
  holds for a profile picked at the first-run picker, which is saved as picked,
  and with no profile saved the setup screens' models screen and `models
  --json` open on the recommended profile with `--multi-model=false` applied;
  choosing two models on the screen still runs them.
- **The "Using saved profile" line says when `--thorough` or a lone
  `--secondary-model` replaced one of the profile's models for the run**,
  after the first-run picker too.
- **`status` prints the running command's status line** in place of its separate
  stage, model call and time-left lines.
- **A next step that points at a file** (a run's log, an exported draft, a saved
  plan, a scan's disclosures) **names the file and runs no command**, so it works
  on Windows, where `tail`, `cat` and `ls` do not exist.
- **Every response's next steps number two to five, in priority order**, under
  `--json` and at a terminal; `models describe` offers a scan with the model it
  described, and `ui` prints its next steps at a terminal.
- **Help for `--draft-model`, `--thorough` and `--primary-model` says what each
  does on its command**, including that `--thorough` changes nothing on a remote
  provider; every `--json` has the same help.
- **A `--synthesize` scan's `duration_ms` includes Pass 5**, as its cost does:
  the run's wall time, measured after Pass 5. A standalone `synthesize` is its
  own run, and `synthesis_cost.duration_ms` gives its time.
- **`scan --resume` compares the choices a run used, never how its flags were
  spelled**: the files the scan collected, each by its content; whether Pass 3
  runs; each role's model and the weights its tag pointed at; every value or
  output budget that differs from its built-in one; and a remote endpoint's
  address without its user and password. The same choices given another way
  compare equal. `unfinished.json` is 3.3.0: its shape is unchanged and its
  settings and arguments mean something else, so a 3.2.0 record is refused as
  another version's; run that scan again. A stopped run's record in a data
  directory inside a git work tree is read only when your home folder holds its
  digest, and the record keeps no user or password from a repository's URL.
- **No stage sends a call again that cannot succeed.** A call that timed out
  is sent at most twice in all, by the client, and no stage sends it again
  (characterization's retries could send one up to eight times, the
  multi-model synthesizer up to six); a cut answer and a permanent failure
  are never sent again. Characterization still asks once more for an answer
  it could not decode.
- **A remote request the endpoint rejects is not sent again**: a 4xx answer
  other than 429 (a rejected key, a bad request, payment required, a model the
  endpoint does not serve) fails at once, where every stage sent it again. A
  rate limit (429) and a server error (5xx) are still retried.
- **Ollama's client sends no request without a per-request timeout**, and
  every command gives it the same one (`--timeout`, saved as
  `default-ollama-timeout`). `anchoring-check`, `bench` and `distill gate`
  sent each request with their whole run's deadline; they now send it with the
  per-request timeout as saved or built in, and their `--timeout` is still the
  whole run's deadline. `distill gate`'s run deadline can be saved with
  `init`; 0, built in, sets none.
- **`bench --n N` sends all N requests at once**; it ran at most 4 at once on
  Ollama and 16 remotely, which read as a server that queues.
- **Whether a run costs money is one rule everywhere**: Ollama, wherever it
  runs, and an OpenAI-compatible server on this machine are not billed per
  token, and a hosted endpoint is. The cost line says "Ollama, not billed per
  token" or "an OpenAI-compatible server on this machine, not billed per
  token", the start of a scan on an Ollama server on another machine says so
  (without any user or password in its address), and `--bridges`' help states
  the rule.
- **A scan's cost includes Pass 5 whichever command ran it**: `synthesize`
  adds its run's Pass 5 spend to the stored scan's cost, as `scan
  --synthesize` does. `pbd_cost` and `review_cost` do not include it.
- **The first-run picker opens the parallel-batches question on the rule a
  scan follows** (one at a time against a server on this machine, 4
  remotely), with the memory figure as advice beside it, and saves a number
  only when you change it; the number you pick applies to the scan you are
  starting, unless `--parallel-batches` was given, not only to later ones.
- **`scan`'s usage line marks its repository optional** (`scan
  [repo-url-or-path]`), since `--resume` can take it from the stopped run.

- **Next steps belong to the command that ran.** A response is padded with
  general steps only when it has fewer than two of its own, and those are the
  running command's: its own options, and the provider options only where it
  calls a model. Only `scan` is offered `--verbose`, and a network failure in
  a command that calls no model is no longer told to start Ollama.
- **`review --why` and `refusals` say which gate held a concept back and why,
  in plain words**, with each setting it read by its key, its built-in and
  saved values and the flags that change it; `refusals --json` adds
  `verdicts`.
- **`init` repairs a saved default it cannot read**: `init --reset <key>` or a
  new value replaces it, `init --reset all` removes a defaults section that is
  not an object, and a refusal beside a damaged section offers those, never a
  scan's steps.
- **`--depth`'s range is 0 to the depth ceiling in force**, listed in the
  command's help and held when the scan starts. Any value refused for its
  range now names the flag it was given with.
- **`--include-textbook`'s help, and the setup screen's choice, say it also
  lifts the score floor.**
- **`price-snapshot-max-age-days` is offered on the commands that read it**,
  12 rather than 24.
- **`--parallel-batches` sends one request at a time against a server on this
  machine** by default, and 4 against a remote endpoint; a value given or
  saved still wins. Since the discovery cache serves serial scans, a local
  scan now reuses discovery answers by default.
- **Pass 2 sends a failed call again only when a second send can succeed**: a
  transient error is re-sent, an unusable answer is asked for once more, a
  timeout is sent at most twice end to end (`timeout-attempts`), and a cut
  answer or a permanent error is not re-sent.
- **Pass 5 judges every concept it is given and scores every candidate
  pattern**: a partial answer is kept and the concepts it left out are asked
  again, and the run says `judged N of M mechanisms for product centrality`.
  A failure every attempt would repeat, such as a stopped run, is not split
  and asked again.
- **Triage runs before characterization**, so a concept only triage can
  locate is characterized. A location field listing several files resolves to
  the first that exists, a concept found in documentation is located at the
  document its call read, and a concept's source type follows its corrected
  location. A concept that names no file and matches nothing stays pending
  rather than being dropped.
- **A file larger than one discovery call and under the read cap is read in
  parts**, one call each, instead of being skipped.
- **A concept the lineage followed through a rename is exported and listed at
  the path the file has now**, and a scan whose `--parent` coverage record
  cannot be trusted reads every file and says so, in its caveat, its coverage
  and its status line, instead of being refused.
- **Pass 4's matching is fitted to the model's window** in chunks, each
  answer checked against its own chunk.
- **The OpenAI-compatible path sends characterization's schema**, a server on
  this machine included (`CS_REMOTE_JSON_SCHEMA=0` turns it off); Ollama's own
  API is still sent none. An undecodable characterization answer is re-sent
  only when inference leaves this machine.
- **Every profile's memory figure is rounded up to the next whole GB**:
  Balanced needs ~23 GB, Validated ~39 GB and Thorough ~52 GB (its model alone
  is 51.7 GB), as do the estimates the picker prints for a server's slots. A
  32 GB machine is therefore recommended Fast, where it was Balanced;
  Balanced stays choosable.
- **`models` checks every model a profile's scans call**, the profile this
  machine's memory recommends is marked, and the Fast profile's memory figure
  counts its grader (17 GB).
- **`components.json` 1.2.0** names a concept characterization was never asked
  about, because its location did not resolve to a readable file
  (`not_asked`), apart from one that was asked and never answered.
- **`CS_BUDGET_DEFAULT` and a saved `budgets.default` are no longer read**:
  no model call ever read that budget, and a call with no options is refused
  before anything is sent.
- **The output contract is 2.0.0** (the concept, the bridge and the scan
  result). A consumer that reads 1.x must update:
  - every scoring axis on a concept, a bridge and a pattern is null when it was
    not scored, and a 0 is a score; `axes_unanswered` and `scores_defaulted`
    are gone;
  - discovery's estimate moved to `provenance.discovery_score`, and
    `technical_distinctiveness` is characterization's score alone;
  - a characterized concept carries every field it requires (a category from
    its list, the technical approach, the key insight, the inputs and outputs,
    the components and how they interact), or it is held back as
    `required_field_missing`;
  - each shipped concept carries `name_attenuation`, and each one that has
    `contributors` carries `authorship_caveat`;
  - patterns gain `asserts_feedback_cycle`, and no pattern has one member;
  - the scan result's `duration` is `duration_ms`, Pass 5's too; costs are null
    when a remote call had neither a listed price nor a cost its endpoint
    reported; `repository` names the repository
    by its origin URL or its folder name, never a local path; and the result
    gains `coverage`, `directories_skipped` and `doc_concepts_characterized`.

  Scans stored by an earlier version are read but not written to; scan again.
- **A `--multi-model` context that does not fit keeps every file**, written in
  a shorter form, instead of dropping files; a file is left out only when every
  file's shortest summary still does not fit, and a lossy form is named in
  `agreement.json`'s warnings. Compression is reported as a stage of its own,
  and a compression call's output budget is no longer raised past the size its
  answer is judged against.
- **Multi-model files are extracted again once after upgrading.** The
  extraction cache keys on the extraction prompt and its request settings
  rather than a hand-kept version, keeps the model's own answer and reads it
  again on every hit, and removes the folders an older prompt wrote.
- **`--tests source` masks test data in discovery too**, not only in
  characterization, and a concept whose name or summary copies a test's data,
  or the placeholder that masked it, is held back (`copied_test_data`).
- **`review` and `figure` no longer take `--source-weight-*`**: they read the
  source weight each stored concept carries.
- **A 0 on `--timeout`, `--parallel-batches`, the bridge maxima or the triage
  limits is refused**, naming the range; leave the flag out for the saved
  value, else the built-in one. `--depth` takes 0 to 64 and is refused above
  the depth ceiling in force (4 built in). `init` offers no flag that changes
  only its own run, and `init --default-parallel-batches` saves where the model
  picker and `bench --write-config` do. Discovery's pre-warms send the warm-up
  budget (`--budget-warmup`, 512) rather than 8192. Multi-model extraction
  cache entries made before this change are not reused. `CS_REMOTE_CONTEXT_CAP`
  is read when a model is sized: a flag outranks it, and it outranks a saved
  value.
- **An Ollama server on this machine given as `--provider openai-compatible
  --base-url .../v1` runs on Ollama's own API**, which sets the context window
  on every call; its OpenAI-compatible API cannot, so the server's own window
  applied (4k tokens on a machine with under 24 GiB of GPU memory) and prompts
  were cut. It is the same server and the same loaded model, and the run says so
  in one line. A server is moved only when it reports a version and answers
  Ollama's model list in Ollama's shape; anything else keeps the API it was
  given.
- **No answer is asked of a model beyond the most it writes.** A remote
  catalog's listing says how many tokens a model writes in one answer (OpenRouter
  reports it), and the first budget sent to the model and every retry after a cut
  answer are now held to it; a larger request was refused by an endpoint that
  checks it, or cut there. Every recommended cloud model carries its limit, so a
  command that reads no listing holds to it too.
- **What you say about a model is saved per endpoint, and `think` moved into
  it.** The settings file's `"models"` section holds, for each endpoint and
  model, the context window its server applies, the most tokens it writes in one
  answer, and its think value; every command applies the records for the
  endpoint it runs on once its provider is resolved. The old `"think"` section is
  read as the records of the Ollama server at `localhost:11434` and moved there
  on the first save; for a server elsewhere, give the value for that server.
  `init --json` shows the records under `models` in place of `think`.
- **A local model is sized to the memory that holds it.** Before the first call,
  a run on Ollama's own API prices each model at its window across the server's
  slots (weights, context and the runner's prompt cache) and, when that is more
  than this machine's memory less a 20% reserve, sizes the model for the
  largest window that fits, down to 8,192 tokens, and says so; below that it
  refuses, naming the server's slot setting. A model that ran partly on the CPU
  anyway is said when the scan ends, and so is one loaded more than once under
  it (`models.json` 1.5.0 records both).
- **The model picker prices a profile's memory from its own models.** A request
  slot at the 32k window a scan sends costs 3.0 GiB for `qwen3-coder:30b`, 1.75
  GiB for `qwen2.5-coder:7b` and 0.8 GiB for `gpt-oss:20b`, where it was 2 GB for
  every model, and each model's 8 GiB prompt cache is now counted. So the
  recommended number of requests at once changes: on 48 GiB, Balanced recommends
  3 (it was 8), and Thorough recommends 1, since the server runs its model one
  request at a time. `figure draw`'s load plan prices a model the same way, from
  the server's own log when the model has run there, and says NOT COVERED where
  nothing can price it, rather than its size on disk times 1.25.
- **The context window an OpenAI-compatible server on this machine applies is
  measured before a run sends anything** (three prompts per model, also for
  a model first used mid-run), and every stage is sized for it. Below 8,192
  tokens the run is refused, naming the server's setting and, for Ollama, its
  own API. `models.json` records each measurement.
- **`--log-requests` is removed**, with the `CONCEPT_SCANNER_LOG_REQUESTS`
  variable that also turned it on. It logged one line per model call to stderr;
  every call is now in the run's own `calls.jsonl` (under `runs/<run-id>/` in
  the data directory), failed calls included, with what each one asked for
  (`num_ctx`, `num_predict`) beside what the server answered, the input check's
  mark, and a failure's kind. A command given `--log-requests` now refuses it
  as an unknown flag.
- **A discovery call holds about a fifth more source**: 67,578 characters of
  files at the default 32K window, where it held 55,296. The batch is sized by
  the same rule as every other prompt (the window less the output budget, the
  system prompt, the prompt's fixed text and a margin), and so it now follows
  `--budget-discovery`. A file between the two sizes, which was left out of a
  scan's own discovery before, is read; a large repository is read in a few
  fewer calls.
- **`models.json` (1.2.0) records each model's context window for every
  provider**: the window the run asked for, the window that applied and where
  that came from, and every window it learned; each Ollama runner also records
  its window per slot and the prompt cache it keeps.

- **The multi-model per-file extraction budget (`pbd-extract`) starts at 8,192
  output tokens**, up from 4,096. On one corpus `gpt-oss:20b` overran 4,096 on
  10 of 12 files in both 2026-10-08 scans, and each overrun was thrown away and
  asked again, about 22 minutes of each scan. Re-run at 8,192 on the same
  corpus, none of its twelve extraction calls was thrown away, and the stage
  generated 41% fewer tokens.
- **`--budget-<name>` flags are offered only on the commands whose runs read
  that budget**, and default to `0` (not given) rather than the built-in value.
  A flag a command offered and never read (for example
  `triage --budget-figure`) is now refused as unknown, and `--budget-default`
  is gone, since no command's call ever read it.
- **A saved budget of 0 or less is ignored**, as a variable or flag of 0
  already was, and a saved `budgets` section holding a value that is not a
  whole number changes nothing (before, the keys ahead of the bad one applied).
- **The judge prompt (`bench`, the promotion gate) no longer asks for exactly
  one token while also letting the model think first**; it says the answer is
  one of A, B or TIE. Measured: every reply stayed readable, and calibration's
  verdicts on the two judges tried did not change.
- **The bridge and Pass 5 rubrics keep only their two ends for centrality and
  defensibility**, with no interior anchors (0.7, 0.4, 0.5). The 0.7 anchor was
  deciding Pass 5's gate: measured, 15 of 16 load-bearing concepts scored
  exactly 0.7, the single-mechanism floor. Pass 5's load-bearing centralities
  are therefore not comparable with earlier scans.
- **A split Avenue B batch's prompt says it holds part of a larger group**:
  the grouping hypothesis was written for every file of the group, so a part
  now says which files it holds instead of presenting the hypothesis as
  describing only its own. An unsplit batch's prompt is unchanged.
- **`--merge-model` on a single-model scan is refused** (exit 1, saying
  that only a multi-model scan has a merge model), read from the resolved
  mode, so a saved multi-model profile still accepts it; `--depth` under a
  saved multi-model profile is refused the same way instead of being ignored.
- **Re-run steps repeat the flags of the run they repeat**: "try a different
  model" names the repository and its flags instead of `<path>`; the
  re-query step is now offered (it never was, because it was built before
  the union that sets it) with `--depth 1`; the dry run's widening step, the
  `bridges` and `synthesize` re-runs carry their flags; a widening's re-run
  repeats the widening (the same `--parent` and `--coverage`, and every other
  flag given) instead of a command the scan refuses, with the whole-repository
  re-run offered as a second, lower step; "Re-run with --verbose" is the scan
  just run, from its own path and flags; and the `bridges` "loosen" step
  raises the candidate cap instead of lowering it to 30.
- **Under `--local-only`, a model server that did not answer is followed by
  steps on this machine**, naming the host, instead of a remote provider.
- **`bridges` names the model its calls went to** (the drafting model) on its
  `Model:` line and in the audit's `bridge_model`.
- **`synthesize` reads the workspace with the stored scan's file set**
  (`--only`, `--exclude` and its drops), from the `file-set.json` every scan
  now writes, or from an older coverage scan's `arc.json`, and says which; a
  scan written before 2026-10-09 that planned no coverage recorded none, and
  `synthesize` says that every document is read. A record in a data directory
  inside the repository is used only when this machine's home folder holds its
  digest: otherwise `synthesize` refuses before any model call and says how to
  scan again.
- **The envelope writes `pbd_tokens` and `review_tokens`** (`ScanResult`
  1.5.0): what discovery and Pass 2 used, as `{"input", "output",
  "cache_hit"}`, read from the cost log; absent when the run made no such
  call. Both fields were declared and never written. `pbd_cost` and
  `review_cost` are now computed and stay 0 until a cost-log row carries a
  price; the completion audit carries the same values.
- **`agreement.json` 1.3.0 counts the generations the output-cap escalation
  discarded**: each of `at_merge`'s merge call and two syntheses gains
  `discarded_generations` and its discarded tokens, so the parts sum to the
  cost log, abandoned rows included.
- **A scan says which stage and model its discarded generations came from**,
  in a line after the discarded-generations note, and the cost log's
  discarded and failed escalation rows carry a `stage`.
- **`models.json` records the server's runner settings when `HOME` is moved**
  (as a measured run does): the server's log is found under the home the
  account database gives this user.
- **A build from source uses Go 1.27.2** (`toolchain go1.27.2`, as CI and
  releases already did), and `golang.org/x/tools` moves to v0.51.0, which reads
  the export data that Go 1.27.2 writes. License analysis is unchanged: it
  never read export data, and its output is byte-identical across the bump.
- **On a remote endpoint, the default primary model and the default Pass 2
  grader are chosen for that endpoint's catalog**, from the model registry, as
  the drafting model's is. Both defaults exist on OpenRouter's catalog today.
  On a catalog the registry lists no default for, `scan`, `bridges`, `triage`,
  `synthesize`, `figure draw`, `bench` and `anchoring-check` stop before any
  model call and ask for `--primary-model` (or a model saved with `init
  --model`) and `--secondary-model`, and exit 1, where they used to send every
  call for a model that catalog does not have. The pre-flight check covers both
  defaults.
- **A folder named `data` is read**, and a folder named `build`, `dist` or
  `coverage` is skipped as generated output only when git ignores it or tracks
  nothing in it, so a `dist/` you commit is read. Where git cannot answer (the
  folder is not in a git checkout, or git is not installed) those names are
  skipped as before. The run says which rule skipped each folder, and names
  the folders it read because git tracks them.
- **On a remote endpoint, the drafting model's default is chosen for that
  endpoint's catalog**, from the model registry, and falls back to your primary
  on a catalog the registry does not list; the scan prints which model drafts
  and why, and the pre-flight check now covers the drafting model.
- **`--min-doc-relevance 0` and `--enrich-threshold 0` are honoured.** A value
  of 0 was read as "not set" and replaced with the default.
- **Pass 5 reads the project's own description**, found by the same rules as
  the intent search, and no longer takes `CLAUDE.md`, `AGENTS.md` or
  `CONTRIBUTING.md` for one; every document it reads is bounded.
- **Several answer fields have limits** that hold after the model answers: the
  TLDR, the enriched summary, two characterization reasoning fields, the three
  fields of each distinctiveness mechanism, and the test-evidence statement with
  a rejected property's quote and name. They hold on a remote provider too,
  where the output schema is not enforced. A cut is counted, never silent.
- **`--depth` above 4 is refused** (`--depth 9 is outside its range: give a
  value from 0 to 4`, exit 1) instead of being cut down to 4, and the catalog
  lists 0 to 4, where 0 means work it out from the file sizes.
- **Any loopback address counts as this machine**: a `--base-url` on
  `127.0.0.2` or another address in `127.0.0.0/8`, or an IPv4-mapped loopback
  address, now gets the local defaults and no egress notice, as `127.0.0.1` and
  `::1` did. `agreement.json`'s `data_flow` now calls `0.0.0.0` another
  machine, since a request to it can go through a configured proxy.
- **`--min-doc-relevance` and `--enrich-threshold` refuse a value outside 0 to
  1** (for example `--min-doc-relevance 2 is outside its range: give a value
  from 0 to 1`, exit 1). `help --json` lists the range, and the window's form
  takes it from there.
- **A repository holding a `.zip` that would expand more than 100 times its
  size is no longer refused**, on a local path or a remote clone. This program
  opens no archive, so the scan goes on and names the archive in a note line
  and in its `--json` notice; `bridges --workspace` and `triage --workspace`
  say the same.
- **A local Ollama tag on a loopback `--base-url` is no longer refused** before
  the endpoint is asked; its own model listing decides.
- **`scan --synthesize` honours `--only`**: a README, project description, or
  architecture or decision document outside `--only` is no longer read or sent
  to Pass 5's model, local or remote, and the run prints one note naming what
  it left out.
- **The intent search (`--intent-from-docs` and the setup screens) honours
  `--only`**: a README, root page, package description or documentation page
  outside `--only` is not read or sent to the intent call, and the run prints
  one note naming what it left out. With no document inside `--only`,
  `--intent-from-docs` makes no intent call (a partial `--coverage` is then
  refused) and the first screen says `--only` left the documents out. The Go
  package comment is
  chosen among the root files `--exclude` and `--only` keep, so an excluded
  root Go file no longer stops another one's comment from being read.
- **A remote scan is no longer refused for an `--extract-model` or
  `CS_EXTRACT_MODEL` it will not call**: the extraction model is checked only
  under `--two-phase`, where a grader doing the extracting is checked in that
  role too.
- **An unlisted `--merge-model` on a remote multi-model scan is refused by the
  pre-flight** (exit 3, naming the flag) instead of failing at merge time.
- **`bridges`, `triage` and `synthesize` with `--draft-model` no longer pull
  the primary model** (or, under `--no-auto-pull`, require it): they never
  call it.
- **`distill gate` checks `--judge` against a remote endpoint's catalog**
  before any request; an unlisted judge stops with exit 3.
- **`intent.json` 1.2.0 records the documents `--only` left out**
  (`documents_left_out_by_only`), from `--intent-from-docs`, even when no
  intent call was made, and from the setup screens.
- **`--multi-model`: a file one model refused and the other's call failed
  says what happened to each** in `agreement.json`'s `not_extracted` cause
  (1.2.1, no field changed), where it said "both models' extraction failed",
  and the run's extraction error reads "neither model extracted the file:
  primary: ...; secondary: ...".
- **A saved extract model (`extract_model` in `settings.json`) is used on a
  local provider only.** A remote scan or `bridges --two-phase` run no longer
  uses it, and is no longer refused for it; `--extract-model` and
  `CS_EXTRACT_MODEL` still apply everywhere.
- **`bench` and `anchoring-check` check their model against a remote
  endpoint's catalog** before the first request; a model the catalog lacks
  fails once, naming `--primary-model` (exit 3).
- **`bridges`, `triage`, `synthesize` and `figure draw` check a remote catalog
  before their first call**, for the models each one calls, and refuse once
  naming the flag to change (exit 3). On a catalog the model registry has no
  defaults for, they no longer ask for `--secondary-model`, a flag none of them
  has; `bridges --two-phase` there asks for `--extract-model` (exit 1). The
  model check names only the flags of the models that failed, `scan` included.
- **A `--multi-model` scan in which every file was refused before any model
  call exits 1**, saying so, instead of 3: no model server was asked anything.
- **`--timeout` and `--parallel-batches` help states what the code applies**:
  `--timeout` says that under `--two-phase` a smaller value is raised to 30
  minutes except for `--multi-model`'s own calls, and `--parallel-batches`
  says 0 means the saved setting, else 4.
- **The "Estimated runtime" line is the console's own estimate**, the same
  figure as the live stage ETA, priced from this machine's recorded calls, and
  says when it does not know yet.
- **Model flags' help states the defaults the code uses**, and `--base-url` and
  `init --profile` help no longer show a wrong value name.
- **Triage no longer drops a concept as a missing file when only its keywords
  failed to match**: a file with the name the concept cited is always a
  candidate, a concept with nothing to search with stays pending, and keywords
  are read in any script.
- **Two concepts in one file whose names differ only after their fortieth
  character, or whose names are not in Latin script, are no longer merged** by
  the final de-duplication.
- **Java, Kotlin, Swift and C# test files are recognised by their `Test`
  suffix or prefix**, so `Latest.java` and `Contest.kt` are product code again.
- **A path missing its leading folder is repaired for any layout**, not one
  application layout: the one readable file whose path ends with it.
- **The documents line says why documentation was left out** (code was most of
  the files, or `--exclude-docs`).
- **`--multi-model`: a failed per-file merge call keeps the primary model's
  extraction** (reported as `merge_failed` with its cause in `agreement.json`,
  now 1.1.1) instead of dropping the file, and a cancelled scan stops at once
  instead of continuing file by file and exiting as a model failure.
- **`--multi-model` honours `--timeout`.** Its own model calls had a fixed
  limit of ten minutes whatever `--timeout` said.
- **A `--multi-model` answer that is not a readable merge no longer empties a
  file.** When the step that merges two models' readings of one file got back
  an answer it could not use, it could replace both readings with an empty
  one; it now keeps the primary model's reading and records the file as
  `merge_failed`.

- **`--multi-model` extraction reads each input as a file, code or
  documentation**, not as "the document", and no longer labels every input
  with a constant source type. Its cache moves to v5, so every cached
  multi-model extraction is redone on the next scan; a cache from before the
  2026-10-07 prompt change had been served under the changed prompt until now.
- **A `component_interaction` written by the completion step can be two
  sentences**: that step asked for one sentence where characterization asked
  for one or two.
- **Pass 2 (classification) is no longer shown discovery's score.** Shown it,
  the classifier wrote discovery's number back on every candidate measured;
  the score a concept carries before characterization is now Pass 2's own,
  so it is not comparable with earlier scans' scores at that stage. Labels
  moved no more than edits that change nothing.
- **Discovery's first criterion carries a colon where it had an em dash.**
  Measured against two edits that change nothing, it moved discovery no
  further than they did. A discovery cache written by an earlier development
  build misses once.
- **The test frame (`--tests source`) states what makes test machinery a
  mechanism** (how the test itself is built, not what the code under test
  does) instead of listing four verbs.
- **The prompts state what they look for instead of showing examples.** The
  discovery criteria and the classification, characterization, bridge and
  summary prompts carried examples and sample values taken from particular
  kinds of software, and a model tends to describe what it reads in the
  examples' terms: on a library with no client code, characterization judged
  how detectable 16 of 23 mechanisms were in terms of client-side code, the case
  its example used. Each prompt now states the property it asks about, and shows
  the shape of its answer as placeholders. A concept's parts are no longer cut
  at six when an incomplete characterization is completed. **Scores are not
  directly comparable with earlier versions:** on one fixed set of 23 concepts,
  `implementation_depth` rose one step on 5 of them, `problem_specificity` on
  3, and `technical_distinctiveness` on 1.
- **The same scan gives its results in the same order.** Identical scans
  shipped the same concepts in a different order every run, and when bridge
  candidates tied on score, which combinations were explored changed between
  runs; both now come out the same every time, as do a pattern's subsystem
  list and the order of the patterns step's prompt.
- **Tests are paired with concepts in Go only again.** 1.3.0 also paired
  TypeScript, JavaScript and Python concepts with the tests their conventions
  put beside the code, read by pattern. Measured against hand labels on one
  real repository each, that found about one in five of the tests that
  exercise the code (recall 0.18 and 0.19, where 0.7 was required), so those
  concepts are counted as `unsupported_language` in `tests.json` (schema
  2.1.0), as they were before 1.3.0, and the Tests line says how many.
- **A scan stopped by strict validation keeps the work it had done.** When the
  classifying model cannot classify a batch, the scan still stops with exit
  code 3, and now writes `unfinished.json` to the run's folder first: every
  concept classified so far, and the rest marked unclassified. The error names
  the file. It is a record, not a scan, so nothing graded only by the model
  that found it can be reviewed or exported. One such failure, at batch 846 of
  868, had discarded four and a half hours of work.
- **Bridges (Pass 3) run by default when inference stays on this machine.**
  Pass 3 is where a scan finds how its concepts combine; without it a scan
  reports the parts and never the arrangement. A scan whose model runs on this
  machine, an OpenAI-compatible server on a loopback address included, now runs
  it without `--bridges`, at a bounded cost: about 50 extra model calls in the
  runs measured, capped by a fixed number of candidates rather than by the size
  of the repository. A scan that sends its requests to another machine still
  skips it unless you pass `--bridges`, so a default never spends money, and
  `--no-bridges` turns it off anywhere. Each bridge now carries
  `asserts_feedback_cycle` (bridge schema 1.3.0), true when the bridge's own
  text claims a loop. It describes the text, not the code: the scanner cannot
  check that anything closes the loop, and on a test corpus with the loop's
  write side removed, bridges still claimed one.

### Removed

- **`triage --exclude`, `--keep-dir`, `--include-clients` and
  `--include-fixtures`**: `triage` reads with the scan's own file set, as
  `synthesize` and `bridges` do.
- **`default-concurrency` and `default-remote-concurrency`**, with their
  flags: `--parallel-batches` (`default-parallel-batches`) is the one control
  for how many requests a run keeps in flight. A client no command sized sends
  one request at a time.
- **`native-request-timeout`**: `default-ollama-timeout` is the one
  per-request timeout for Ollama's client.
- A value saved under one of these three keys is ignored, and a run that
  reads defaults says so once; `init --reset <key>` removes it. `init --reset
  all` keeps a key this version does not know, since a newer version may have
  saved it.

### Fixed

- **Quitting the window, `concept-scanner ui --stop`, or uninstalling right after
  the window opened no longer fails with "commands this window started are still
  running".** Commands that only read (the window's own models, settings, scan
  list and Running screen refresh) are stopped with the window. A scan, a save, a
  review decision or an export still keeps it open until it finishes or you stop
  it, and the same holds for **Install and restart**.
- **A cut-off model answer that repeats one template with only a counter
  changing** (for example one file location with its line number climbing past
  the file's end) is now reported as repeating, and the warning names a loop
  rather than a larger budget as the cause. How much of the answer's end such a
  run must cover is the new setting `repetition-counting-share` (default 0.7).
- **A widening (`--parent`) carries a purpose that was cut when the lineage was
  given it**, and its note says that a raised limit cannot restore stored text:
  give the purpose again with `--intent` (a behaviour with `--behaviour`) and the
  raised limit, on a widening or a new first scan. It used to name only a cut
  behaviour and advise a limit flag that could not restore it. A `--changed` pass
  records the same.
- **The multi-model synthesis logs "running the multi-model synthesis".**
- **A remote scan whose `CS_REMOTE_EXTRA_BODY` has no entry for a model it
  calls is refused before its first model call**, naming each such model and
  the option that chose it, with exit 1 and steps to add an entry or choose
  another model. Until now each call to that model was refused one at a time:
  with no `--draft-model` and a setting naming only the first and second models,
  a scan shipped every concept uncharacterized and exited 0. A setting that
  cannot be read is refused the same way; if such a refusal happens during a
  run, the run stops, sends no further model call and exits 1; and a setting's
  refusal now exits 1 wherever it happens (it exited 3 when it came from a model
  call).
- **The spend ceiling's message prints the ceiling as you set it and the spend
  to four decimal places** ("$0.0021 counted ... against BUDGET_PER_OP=$0.002"),
  where a ceiling under a cent read "$0.00", and says how many calls were
  counted at the cost the endpoint reported and how many at the listed prices,
  naming the prices' date only when a listed price was used. The warning before
  a scan prints a ceiling the same way.
- **A remote single-model scan's `models.json` names its provider
  (`openai-compatible`)**; it said `ollama`.
- **When a spend ceiling refused the batch suggestion for semantic batching, the
  Avenue B line says the call was not sent**; it said the model named no usable
  group of files.
- **A scan whose discovery saw less than it collected now says why, instead of
  always saying that discovery batches failed.** `discovery_degraded` and the
  JSON envelope are unchanged. The notice and the terminal warning name each
  cause in plain words with what to change: discovery batches that failed
  (worded as before); files that never reached a discovery prompt (over the read
  cap, past a batch's share of the model's window, or unreadable); on
  `--multi-model`, files neither model could extract; or a synthesis context
  that could hold the files' extractions only shortened, or not all of them,
  where a primary model with a larger window (`--primary-model`) or fewer files
  (`--only`, `--exclude`) keeps more. The next steps follow the cause.
- **Every count reads singular at 1 and plural otherwise**, in the terminal,
  `--json` notices, next steps and errors, the setup screens and the window: "1
  call at a time", "skipped 1 .mod file", "1 file was not extracted, so it never
  reached synthesis", where these read "1 call(s)" or "1 files".
- **A step in an answer on the window's All commands screen opens the form it
  names, with its arguments**: one that opens the scan form no longer fills the
  open command's form instead, and one that opens another command's form no
  longer loses its arguments.
- **Moving between scans in the window no longer fills the browser console with
  errors** from the "Correct the parts" panel.
- **The window's Running screen shows the newest run whenever it is shown**,
  including one started and stopped from a terminal or an agent, with its Resume
  step.
- **The window's Scan screen asks again which models and server a scan would use
  each time it is shown**, so a provider or server saved in a terminal while the
  window is open appears there.
- **A long command in a next step wraps on a narrow screen** instead of making
  the page wider than the window.
- **With two models and `--skip-review`, the second model's row says it extracts
  every file**, no longer that it also grades.
- **With `--progress jsonl`, the line naming the values a run changed from
  their built-in ones is an output line and is no longer counted as a
  warning**; any other start-up note is a warning event whose message is the
  note as the terminal prints it. The window shows both as text.
- **After re-reading what changed (`scan --parent <id> --changed`), a lineage
  that has read part of a repository still offers to read more of it**: in the
  scan's next steps, in `review --json` and in the window. Widening from the
  re-read reads the ring the lineage planned.
- **The estimate line a coverage scan ends with says "time not estimated"** when
  only the calls and tokens were estimated, as the first estimate line does.
- **The setup screens' ready card lists Esc**, and quitting there says nothing
  was scanned and what was kept.
- **A saved default that is out of range or the wrong kind is set aside on its
  own**, and the other saved defaults still apply. The warning names
  `init --reset <key>`, and `init --json` marks the value (`saved_problem`) and
  leads its next steps with removing it.
- **`refusals` names each gate's setting with its built-in and saved values**,
  as `review --why` does, and its re-run step names only the gates that held
  concepts back.
- **`models` names your saved profile** and, with one saved, leads with
  scanning rather than with saving a profile; its notice says in words that
  install status is unknown.
- **The plan's Intent line no longer prints a period before its semicolon.**
- **`bridges --workspace` marks a concept it re-characterizes completely as
  characterized**, as a scan does, and no longer marks a concept it could not
  read as incomplete.
- **A model answer cut at its output limit while the model was still reasoning
  says so.** The error names how much reasoning the model wrote and that it
  wrote no answer, on a local Ollama server and on an OpenAI-compatible
  endpoint; the check for a model repeating itself reads that reasoning when
  there is no answer; the run's closing note says how many discarded
  generations held only reasoning; and the call's row in the run's call log
  records its reasoning.
- **`--record-examples` records the tokens of every send a call made.** A call
  whose last attempt was cut at its output limit was recorded with no tokens,
  and a call re-sent at a larger budget with only its kept answer's.
- **A failed multi-model scan says "scan failed" once**, where it said it twice.
- **A single-model scan that fails because a prompt was cut keeps its work in
  the run's unfinished record**, when every discovery batch fails after the cut
  and when strict Pass 2 classification stops because its calls were refused.
  The record says the run cannot be resumed and holds the concepts the scan
  had, and no scan is saved; before, the first case kept no record and the
  second offered a resume.
- **A multi-model scan no longer sends a compression request larger than the
  model's window.** A batch that would not fit is split by size until each part
  fits, and a context whose batches already fit is compressed as before. A file
  whose extraction is too large to compress on its own is not sent: it is kept as
  extracted, and the run's warnings in `agreement.json` say how many.
- **A fractional `coverage_pct` in a multi-model extraction answer is parsed.**
  The extraction schema allows any number, and a fraction failed the whole
  answer, which dropped that model's extraction of the file.
- **After a prompt is cut, the calls a run refuses are recorded as refused**
  (`error_kind` `refused` in the run's `calls.jsonl` and in a `--record-examples`
  capture), each under its own model and with no tokens, no longer as cuts
  carrying the first call's count. `distill prepare` writes them to no split and
  counts them (`refused_examples`). The error that stops the run names the call
  that was cut, its estimated size and the window, and says whether the prompt
  was larger than the window the run was sized for or the server applied a
  smaller one.
- **A multi-model scan that a cut stops keeps its work in the run's
  `unfinished.json`**: which stages finished, how many files were extracted, and
  where each model's extraction answers are cached. Nothing is saved as a scan.
  `scan --resume` on it is refused with the reason, and the error offers the
  command that runs the scan again, re-using the cached extraction answers.
  `unfinished.json` is now version 3.6.0, and `scan --resume` refuses a record of
  an earlier version.
- **An OpenAI-compatible server that refuses `json_object`, as LM Studio does,
  is sent plain text**: LM Studio accepts only `json_schema` or `text`, so with
  `CS_REMOTE_JSON_SCHEMA=0`, after it refused a schema, and on every call that
  asks for JSON without a schema (the summaries and documentation matching that
  enrich code concepts, and `figure draw`), each request failed with HTTP 400.
  The request is now sent again with no response format, and the rest of the
  run sends that server none, so one request is spent finding out; the answer is
  read as text.
- **`update` in the container image offers the image pull whatever the image's
  version**: an image whose binary carries no release version was offered the
  install script, which in a container installs into a home the container
  discards.
- **A purpose given with `--intent` or `--intent-file`, or a `--behaviour`,
  longer than its limit is cut at a word and says so**: it was cut inside a word
  with nothing said. The plan's lines and `intent.json` (`purpose_cut_from`,
  each behaviour's `cut_from`, `cut`) name the limit and how to keep the text
  whole (`--intent-max-purpose`, `--intent-max-behaviour`, or `init` to save
  either).
- **A scan's time and cost estimates read no call history from a data directory
  the scanned repository could have written**: in the container image and the
  GitHub Action the data directory is the mounted repository's `data` folder,
  where the repository could place rows that move an estimate. The estimate then
  reads no earlier run's calls and says so on the plan's lines, in `arc.json`
  (`history_not_read`) and on the "Estimated runtime" line; the run's own calls
  are priced as they finish.
- **A `--multi-model` scan's concepts carry their unusualness notes**: the
  synthesis step asked for the details that support each concept, and its
  category, without requiring them, and models that write required fields first
  often left both out, so those concepts shipped `unusualness_notes: []`. The
  synthesis request now requires a category and at least one supporting detail
  on every concept, and no longer asks for a field nothing read.
- **Every semantic batch's discovery prompt carries its grouping hypothesis as
  written**: a batch holding every file the hypothesis was written for no longer
  gets a note saying it holds part of a group. This changes the discovery
  prompts of first and widening scans.
- **On a re-read after a Python file changed, a method a concept names on one of
  the file's classes counts as resolved only if the file still defines it.** A
  call that outlived its definition no longer makes the concept read as current;
  such a concept is stale, naming the method, or retired when that was all it
  named.
- **A scan given `--only` counts the files outside it apart from `--exclude`**,
  and its summary says both.
- **A discovery whose model named nothing in the files it was sent says so as
  the model's answer**, which the discovery instructions allow, rather than
  telling you to treat it as a tool fault.
- **A first scan's estimate line says how many discovery calls and tokens it
  counted** when only the time is unknown, where it said "discovery not
  estimated".
- **A widening's or re-read's possible duplicates by name follow renamed
  files**, so two concepts in one file after a rename are marked as in the same
  file.
- **A model answer cut at its output budget is not asked again at a budget the
  model cannot write before `--timeout`**: the raised budget is held to what the
  model writes in that time at the rate it just wrote, and a raised attempt that
  still reaches the timeout is sent once, not twice. The note at the end of a
  scan says when the timeout ended an escalation.
- **`synthesize`, `bridges`, `triage` and `figure draw` count their warnings**;
  they printed them as `INFO WARN ...` and their `status.json` said 0 warnings.
- **With an OpenAI-compatible server, characterization's schema requires each
  distinctiveness mechanism's category**, which servers that write required
  fields first were mostly leaving out.
- **With `--tests evidence`, a test file that `--only` leaves out is not paired
  or sent to the model**, a remote provider included; `--exclude` and dropped
  folders already kept a test out.
- **`triage` chooses its candidate files with the scan's own file set**
  (`--only`, `--exclude`, dropped folders, the documents and tests settings),
  says which on its output and in its `--json` notice, and refuses a file-set
  record this machine did not write, as `synthesize` and `bridges --workspace`
  do.
- **On a scan of a repository's subfolder, license analysis reads the files
  concepts cite**, where every import extraction failed and no license risk was
  reported.
- **A concept held back because a required field stayed empty after the call
  that asks for it again failed is recorded as a runtime failure**
  (`required_field_repair_failed`), not as the model's
  (`required_field_missing`); `review --why` and `refusals` say which.
- **A concept that names a file the scan was told to leave out is no longer
  described from it**: with `--exclude`, `--only`, a dropped folder, or the
  documents or tests settings, the file's text is not read or sent to the
  model, a remote provider included. The concept ships uncharacterized, and the
  refusal record says why.
- **`bridges --workspace` applies the scan's own file set before it describes
  concepts again**, says which on its output and in its `--json` notice, and
  refuses a file-set record this machine did not write, as `synthesize` does.
- **Test pairing does not read a file the scan left out**; such a concept is
  counted in `tests.json`'s new `not_collected`.
- **On a scan of a repository's subfolder, `grounding.json` and
  `redundancy.json` check the files concepts cite**, where they checked none.
- **A concept that shipped without its engineering axes after being asked for
  them twice is named in the refusal record** (`axes_unanswered`), which
  `review --why` and `refusals` show.
- **A concept whose description left out a field because it repeated a test's
  data word for word is named in the refusal record** (`copied_test_data_field`),
  which `review --why` and `refusals` show; the concept still ships.
- **Semantic batching reads the language of the files a scan reads** (after
  `--only`, `--exclude`, the documents and tests modes and dropped folders), not
  whatever a project file at the root names: a Go repository scanned with
  `--exclude '*.go'` batches its Python semantically in a build with cgo, and a
  scan that reads only documents batches them semantically.
- **On a scan of a repository's subfolder, a concept located by asking the model,
  and a concept whose file could not be found, name their file relative to the
  repository's root**, like every other concept and the refusal record, and a
  concept located that way is described even when the root holds a file of the
  same name.
- **Security: no suggested next step, notice, refusal, error or record repeats a
  user name, password, token or key written into a server address or a
  repository URL, and no step runs on an address other than the one you gave.**
  Where printing an address would change it, the step asks you for it
  (`--base-url <base-url>`, `--ollama-host <ollama-host>`,
  `<repo-url-or-path>`): in every next step in the terminal, in `--json` and in
  the window, the dry run's steps and saved setup, the setup screens' command,
  and a stored scan's re-run, widening and re-query. That covers both model
  clients' own errors, the saved provider in `models --json`, a run's target in
  `status`, a tier sweep's arm records, `arc.json`, and a remote repository's
  clone, whose git configuration keeps no credential. Addresses whose password
  holds `?`, `#` or `/`, and addresses with no scheme (`user:password@host`,
  with or without a port), are shown without their credentials. A tier sweep's
  arm still sends its requests to the address as given; only what it records
  leaves the credentials out.
- **Resuming a scan of a repository whose URL held a credential asks for the
  repository again** (`unfinished.json` 3.5.0, `give_target`); a 3.4.0 record
  is refused as another version's.
- **`models describe` saves a description under the endpoint without its
  credentials**, and `init --json` lists saved endpoints the same way.
- **`--ollama-host` given as a host and port (`127.0.0.1:11434`), on the
  command line or saved, reaches the server**, and `models` says when something
  other than Ollama answers there, as a scan does. Every request to an Ollama
  server keeps the query string of `--ollama-host`.
- **An option given empty text counts as not given in every rule between
  options**, as in the window's form: `scan --changed --parent ""`, `init
  --multi-model --secondary-model ""` and `scan --behaviour x --intent ""` are
  refused. `scan --depth 0` (derive the depth) is accepted beside
  `--multi-model`, and `help --json` lists such a value as `asks_nothing`.
- **A remedy that keeps `--depth` beside a saved multi-model profile turns the
  profile's two models off** (`--multi-model=false`) instead of being refused
  again.
- **"Re-run in thorough mode" after a scan that ran one model stays one
  model**, and **the steps a finished resumed scan prints no longer resume the
  stopped run again.**
- **`scan --exclude-docs` and a typed `--include-tests` at a terminal no longer
  meet a setup screens' choice they contradict**, so the commands the screens
  print, their resume record and `saved_setup.args` run as printed.
- **With the setup screens, the "Using saved profile" line is printed after the
  models screen** and names what was chosen there.
- **`refusals`' re-run of a scan that read part of the repository reads the
  same part** (`file-set.json` 1.2.0).
- **`init --multi-model=false --secondary-model <tag>` saves a single-model
  profile graded by that model**, also beside a saved multi-model profile, and
  `init --remove-key` is refused beside `--secondary-model` and `--multi-model`.
- **`figure draw` takes `--thorough`.**
- **A scan given `--intent-file` copies the file only for a stopped run it can
  resume**, and leaves no copy when it finishes.
- **A scan no longer takes a default another process saves while it runs**
  (in the window's Settings, or with `init` in a second terminal).
- **With `scan --depth` given and no model profile saved, the setup screens'
  models screen opens on one model**, the recommended profile's primary alone,
  since a scan given `--depth` refuses two. `models --depth` answers the same,
  so the window's models card follows the scan form's `--depth`, and `models`
  says when a scan given the same flags would refuse the models it shows.
- **The window:**
  - a value chosen from a list for an option given more than once
    (`init --reset`, `tiers run --arm`) now reaches the command it runs;
  - a typed folder or file name starting with `-` is passed as `./<name>`;
  - a form no longer adds event listeners each time it is drawn again;
  - `--two-phase` and `--no-semantic-batching`, which `CS_TWO_PHASE` and
    `CS_SEMANTIC_BATCHING` can turn on, are offered as not set, true or false,
    so a window started with one of those variables can turn the switch off for
    a run; `help --json` lists such a switch's variable as `env`.
- **`models` on a remote provider suggests what a run there needs**: a scan on
  the endpoint, saving it, describing an unlisted model, and the providers
  guide. It no longer suggests local profiles or Ollama remedies.
- **A download step for an Ollama server at a non-default address no longer
  types an `OLLAMA_HOST=` prefix that Windows shells do not read**; it names the
  server and says how to reach it.
- **`review` with nobody at the terminal, a scan id that is not stored
  (`synthesize`, `triage`, `bridges`, `submit`), and `tiers report` on a missing
  or unreadable folder refuse with the steps that fix the problem.**
- **`status --timeout` without `--wait` is refused**, since the timeout only
  bounds the wait.
- **The window's figure panel shows the same live status line as the
  terminal, and the models card's Profile list shows the saved profile** rather
  than "Your own models".
- **The window's forms follow a value saved in Settings without restarting the
  window.**
- **The window's review filters include exported (submitted) items.**
- **A form the window fills from a next step no longer puts an option's value
  into the repository field.**
- **`distill gate --calibrate` exits 1 for a judge that does not pass
  calibration, with `--json` as without it**; under `--json` it exited 0.
- **A failed command's suggested next steps run that command.** A model server
  that did not answer, a remote provider with no `--base-url`, an unknown flag
  or a wrong number of arguments no longer suggest `scan`.
- **A refusal of what a command was given suggests the change to make, never
  the refused line again**: review, submit, figure draw, distill, models
  describe, init, tiers, synthesize and the provider flags.
- **Every next step that needs a value from you carries what it already has and
  what is left to give**, so the window can open it as a form: the benchmark,
  the tier sweep, the training-corpus commands, the figure correction, "Run a
  scan", and "Scan the repository again" after a write into a scan from an
  older version, which now runs from the path and flags that scan recorded.
- **A next step no longer repeats `--json` or `--progress`** from the run that
  offered it.
- **After a 401, the step to save the key saves it for the endpoint the run
  sent to**, not the one saved with `init`; for an endpoint given on the
  command line it carries the run's `--primary-model` as `--model` and says it
  makes that endpoint the saved provider. When the address held a user, a
  password or a key, you type the address.
- **A port on which something other than an Ollama server answers is never
  offered an API key**: the steps say to check what is on the port, or to
  point `--ollama-host` at the model server.
- **An `ollama` command is suggested only where it reaches the run's server**:
  a server on this machine at a port other than Ollama's own is named, with no
  `ollama serve` or `ollama pull`, and `models` treats a server given as host
  and port (`127.0.0.1:11434`) as on this machine.
- **A refusal for a small described window offers to describe it again and to
  measure it here**, and asks for the address when the address held a user or a
  password; on a server that answers as Ollama it offers neither, since
  Ollama's own API refuses both. `models describe --measure` on Ollama's own
  API offers the description without `--measure`, not `--window`.
- **Saving an endpoint whose address held credentials is a step you fill in**,
  and `models` on a remote provider says nothing of Ollama.
- **`tiers report` names every disqualified arm in one step**, so the other
  steps are not cut off.
- **`CONCEPT_SCANNER_PROGRESS=jsonl` stops only a command that streams its
  progress from asking**: `init` and `update` ask again under it.
- **`distill gate --incumbent ""` is refused as giving neither flag**, the way
  an empty required flag is.
- **A remedy for a rule between flags mends that rule and breaks no other**,
  never gives back a flag it drops, and leaves out a flag the rule reads as
  given empty (`--incumbent=`, `--resume=`), so following one no longer loops.
- **The step to resume a stopped scan is `scan --resume <run-id>`**, without an
  empty `--resume` in front of it.
- **A resume says nothing about the setup screens**, which a resume never
  opens.
- **A scan given `--intent-file` is resumed from a copy of the file as it read
  it**, so a later change to the file, or a later dry run that rewrites the
  saved setup, does not change what the resume ranks.
- **A repository's saved setup is one plan file** (`saved-setup.json`, in that
  repository's `plans` folder under `~/.concept-scanner/repos`), not one per
  dry run, and
  `saved_setup.args_note` says the arguments read it as the latest dry run
  wrote it.
- **`review` of a scan id that is not stored is refused** with the stored
  scans to choose from.
- **Notices and steps about concepts held back as textbook say both checks
  held them**: classified `textbook` and scored below the floor. A scan that
  shipped nothing for that reason no longer suggests a lighter model.
- **`status` prints each running command's tokens and warnings once**, and the
  heartbeat's status line once.
- **The window gives a flag you set even at its default**, and keeps a switch
  a followed step gives at its default, such as `--two-phase=false` or
  `--parallel`, so the command it runs is the one the step shows; a checkbox
  turned on and off again still gives nothing.
- **In the window, "Use it" fills the scan form as yours**, so leaving the tab
  and coming back keeps it, and a step that runs `update` opens Settings, where
  the window checks and installs updates.
- **After a scan started from the setup screens, every next step it prints,
  and the steps `review` prints for it later, repeat the choices made on the
  screens**: the models chosen, the tests mode and passes, and for a re-run the
  plan and coverage. They repeated the flags typed on the command line, so with
  `--multi-model=false` given and two models chosen on the models screen the
  widening ran one model, a re-run read every file, and a widening of a scan
  whose tests mode was changed on the screens was refused.
- **"Re-run in thorough mode" runs the thorough model even when the scan was
  given `--primary-model`**, which it used to repeat, overriding `--thorough`.
- **When the models screen refuses the models chosen** (`--merge-model` with one
  model, `--depth` with two), **it names the screen's choice as the cause and
  says what can be done there**: choose other models, or press esc to quit and
  run the scan again without the flag. A long message there wraps instead of
  being cut at the terminal's width. At a command line, the `--merge-model`
  refusal's first step is now "Add --multi-model", the words of its message,
  and the `--depth` refusal beside a saved two-model profile names all three of
  its remedies.
- **The frontload measurement's larger-budget step uses scan's own
  `--budget-discovery` flag** instead of an environment variable, and
  `distill prepare`'s "keep the fractions fixed" step names the fractions the
  run used.
- **`triage` and `bridges` check the stored scan and `--workspace` before
  contacting the model server**; `triage` refuses a scan written by an older
  version before spending anything and fails when it cannot write a result;
  `synthesize` validates `--workspace`.
- **`--progress jsonl` means a command asks no question**, for every command.
- **`tiers run` uses the Ollama server saved with `init`**, and refuses a
  `--timeout` outside 10 s to 24 h.
- **A window given with `models describe` must meet the same minimum as a
  measured one**, and no longer hides a window the server declares;
  `models describe --measure` reads a declared window before probing.
- **A first run that picks a cloud endpoint at the first-run question sends as
  many requests at once as a scan sent there from the start**, and its record of
  changed settings compares with that endpoint's default.
- **The record of changed settings says what each of a run's calls used**
  (`models.json`'s `settings_changed`, the start-up note, the `--json` notice,
  `status.json`). Under `--two-phase`, a `--timeout` below the two-phase floor
  is no longer listed as a change and one above it is compared with the floor; a
  multi-model scan's extraction, synthesis and merge calls, which take the
  timeout as given, are listed apart, named in a new `for` field. A context cap
  set by `CS_REMOTE_CONTEXT_CAP` is listed as from the environment, and a
  requests-in-flight choice made at the first-run model picker is listed for the
  run it applies to.
- **On a scan of a repository's subfolder, every row of `refusals.json` names its
  file relative to the repository root**, as review shows a concept's file.
- **`bench` records its warm-up request as a warm-up**, not as one of its timed
  probes.
- **When an OpenAI-compatible endpoint reports a model unavailable and the
  scanner asks it to load the model, that request is counted** in the run's
  `calls.jsonl`, `status.json` and cost.
- **A scan's record of the values it changed compares `--parallel-batches`
  with what that scan does with nothing given**: one request at a time against
  a server on this machine, 4 against a remote endpoint. A local scan given 4
  is now listed and one given 1 is not, where it was the reverse, in the
  start-up note, the end of the `--json` notice, `status.json` and
  `models.json`.
- **A warm-up request is recorded under the `warmup` stage in a run's
  `calls.jsonl`**, whatever system prompt it sends; the characterization
  warm-ups and the two-phase Pass 3 warm-up were recorded as calls of their
  stage.
- **A `--multi-model` scan names every file in the requests it sends by its
  path relative to the scanned folder.** The per-file merge, compression,
  synthesis and concept-merge requests used the file's full path on your
  machine, which on a remote endpoint sent your home folder's name and the
  repository's location. A cached extraction of a file at the top of the
  scanned folder, or more than one folder deep, is made again once.
- **When the concept merge's answer placed a concept in two groups, the group
  that lost it no longer carries the note the answer wrote for the whole
  group**; it says what was taken instead.
- **On a `--multi-model` scan, `refusals.json` names a concept held back as
  textbook the way a single-model scan does**, not by an id that matched nothing
  the scan stored.
- **On a scan of a repository's subfolder, a concept whose name copies a
  test's data is held back** even when a file with the same relative path
  exists at the repository's root.
- **A scan that stops before it is saved no longer names disclosure files it
  never wrote**: each disclosure line is printed when its file is written, at
  the end of the scan.
- **A `--changed` scan sends each batch again as it first ran.** It re-ran a
  semantic batch through the size-based prompt, without the grouping reason it
  was first sent with, recorded it as size-based, and then planned new
  semantic batches over the same files, so one pass could read the same files
  two or three times. A `--changed` scan now plans no new semantic batch.
- **The estimate before a `--changed` scan counts the batches it re-runs**,
  where it packed the files afresh and could say one call where the scan made
  two; the scan's summary line says how many discovery calls it makes.
- **A scan refused before any model call offers the change its message
  names** as a next step built from your own command line (a `--changed` scan
  whose only change is a renamed file, a partial `--coverage` with no purpose,
  a `--parent` it cannot read, and others), instead of a rerun with `--verbose`
  and a provider check.
- **Batch sizing counts the path the prompt shows**, not each file's full path
  on disk, so a repository batches alike wherever it is checked out.
- **In `union.json`, a stale concept names the symbols its description
  mentions that its changed file no longer contains**, as a retired concept
  does.
- **The audit log's scan-complete entry records the scan's own duration.** It
  read the clock again after reading file history from git, so it recorded tens
  of milliseconds more than the result's `duration_ms`.
- **A scan names `screen.json` only where it writes it.** The screen's line at
  the start of a scan named the file in the scan's folder, so a scan stopped
  before it was saved named a file in a folder that was never created; the save
  now names it beside the final count of marked spans.
- **`doc_concepts_characterized` is true whenever `--characterize-docs` ran on
  a repository that is not docs-only**, including a scan that found no
  documentation concept, where it said false.
- **Pass 5 reads a load-bearing answer written as one object keyed by concept
  ID** (each value a centrality) as the answer for the concepts it asked about.
  It read one score from it and asked about each other concept again, one call
  at a time. A key it did not ask about, or a value that is not a number, is
  not read this way.
- **A scan of a folder that is not a git repository no longer warns** "failed
  to build file attribution ... exit status 128"; it says so at debug level.
- **A scan of a repository's subdirectory records its first concept's file
  history in the audit log**, read from the repository's root, where it
  recorded none.
- **A generation the output-cap escalation gave up on is counted once.** It
  was counted twice in a run's tokens and cost, as discarded and again when
  its call ended, so `status.json`, the console's running cost, the spend
  ceilings and the envelope's `cost`, `pbd_cost` and `review_cost` read high
  wherever a truncated answer was not retried.
- **The note about discarded generations says what followed them**: how many
  were re-issued at a larger budget, and how many were not sent again and why
  (the calling stage's own bound, the most the call may be given, no room left
  in the window, or the escalation steps spent). It said every truncated
  attempt was re-issued.
- **A `--multi-model` scan whose extractions fit written compact no longer asks
  a model to compress them first.** Every form that drops nothing is tried
  before a compression call; compressing first spent minutes on summaries that
  hit their cap and were discarded.
- **A run's `calls.jsonl` records every call the run counts**: each model's
  synthesis on a `--multi-model` scan, the model warm-ups, `bench`'s probes and
  the `anchoring-check` arms were counted and written to no row.

- **A concept is placed only in a file the scan collected.** The location
  repair, the base-name rescue and triage's candidates follow `--only`, the
  documents and tests modes, `--exclude` and the run's drops, so a concept is
  no longer grounded at a test the scan left out or at code a `--docs-only`
  scan never read, and triage places a rescued concept at the file it asked
  about rather than at a path the model wrote.
- **The `triage` command re-types each concept it rescues**, as a scan does:
  a concept moved into a document is a claim.
- **Unresolved documentation claims are triaged when the only code concepts
  are ones whose cited file did not resolve** (a document that cites a source
  file reads as code until triage moves it), where one such concept kept every
  claim from triage and they shipped unchecked.
- **A concept triage could not locate is dropped before characterization and
  documentation matching**, so no call is spent on it and `doc_matches` never
  names a dropped documentation concept.
- **Under `--characterize-docs`, the documentation concepts a scan ships are
  handled as shipped concepts**: stored as concept files, so `review`,
  `submit`, `figure` and the window reach them; grounded, attributed (with
  `contributors` and the authorship caveat under git enrichment), audited, and
  counted in `characterization_incomplete`, `components.json` and
  `low_score_held`, which until now left out the documents it held back.
- **A line range outside the part of a large file a call read is removed**,
  keeping the file, so lines the model never saw are not attributed.
- **"Running synthesis over N concepts" counts each concept once**, where it
  counted three views of one list.
- **The audit log names the repository as the envelope does** (an origin URL
  without credentials, or a folder's name), never a path on this machine, and
  its scan-complete entry follows Pass 5, so its cost includes Pass 5's.
- **A required characterization field emptied because it copied a test's
  data is held back as `copied_test_data`**, not as `required_field_missing`
  "still empty after repair".
- **The missing-fields warning says whether the characterization schema was
  sent**, or why not (`CS_REMOTE_JSON_SCHEMA=0`, or the endpoint refused it).
- **An endpoint's refusal of the output schema is followed by the plain JSON
  request it asks for** with `request-attempts` at 1, where the run failed
  with an unreadable error.
- **Pass 5 judges a batch too long for the model's window in halves**, where
  it judged none of it; a batch that timed out is still split, and a refused
  response format stops.
- **`source_weight` is always written**, so a weight of 0 you chose reaches
  the importer.
- **Every bridge axis reaches the output on 0 to 1**: a score written on a 1
  to 10 scale is read as tenths and the rest are held to the range, where one
  out-of-range axis made the importer refuse the whole bridge.
- **`dependency_map` names files, never folders on this machine**: a manifest
  relative to the repository, a licence in the module cache as
  `module@version` and its path inside the module, and messages with the
  repository, the module cache and the home folder taken out.
- **No git this program runs follows an inherited `GIT_DIR`, `GIT_WORK_TREE`
  or `GIT_INDEX_FILE`** (or any variable `git rev-parse --local-env-vars`
  lists), which a git hook or another tool's shell can export, so a scan run
  from one reads the repository it was given.
- **A lineage whose folder is part of a larger git repository keeps its
  concepts**: every earlier pass's concepts were retired as gone and every
  rename read as a deletion. Such a scan now records its commit and branch.
- **A lineage's re-query step lists each silent file once, at the path it has
  now**; `review` and `submit` say why a concept is stale (no later pass
  re-read its file, or one did and did not find it again); `review --sort file`
  orders a moved concept by its path now; a rename is listed as kept only by
  the pass that saw it; and a pass whose record this machine did not write is
  named as not shown, where it was left out without a word.
- **A widening, re-read or re-run started from `review` or `refusals` runs as
  the scan did**, with its models and passes (`file-set.json` 1.1.0 records
  the flags it was given as `rerun_args`), where it ran with the default
  models and every pass on; a scan whose `--parent` was not trusted is re-run
  as a scan of its own, never as that widening again.
- **`--multi-model --tests source` masks a test's data** before either model
  reads the file, as a single-model scan does.
- **The multi-model extraction cache serves an answer only to the request
  that made it**: its key holds the model as served (its weights, the server's
  version and host), the think setting, pinned penalties, an endpoint's extra
  fields and the schema sent, and the name the prompt gives the file. A
  backend that cannot say what serves it is not cached, and the run says so.
- **An item of a list a model wrote as an object reads the same on both
  scanner paths** (`{"name": "x"}` is `x`).
- **A lone `--secondary-model` is kept** beside a saved profile, the picker
  and the setup screens' choice, where it was dropped in silence; the models
  screen's printed command states the whole choice, so it runs what the
  screen showed over any saved profile.
- **A single-model scan given `--draft-model` records it** in `models.json` and
  in each concept's `provenance.models`, where both named the primary.
- **A remote scan under `--skip-review` checks no grader** against the
  endpoint's catalog.
- **A dry run's saved plan says a model the run downloaded is on the server.**
- **Memory sizes are printed in decimal GB**, as the profile figures are.
- **A next step with a value still to give opens in the window**: "run it
  again with another model", the steps after `--local-only` refuses a run,
  `scan <path>`, `status`'s "Start a scan", `models describe --window
  <tokens>`, `bridges`' re-characterize step and `submit`'s steps carry
  `prefill` and `fill`, where the window dropped them.
- **The window's models card opens on a pre-filled form's model flags** and
  keeps a choice of its own through `init`; it shows each profile's memory
  mark and no grader under `--skip-review`.
- **`anchoring-check` gives at least two next steps for every verdict.**
- **A call that read and wrote nothing costs 0 for every model**, so one
  failed call to a model with no listed price no longer makes the scan's cost
  `null` and its cost line "unknown".
- **An empty answer's cost counts what the model generated** (its output and
  reasoning tokens) and what the endpoint reported, with the upstream that
  served it.
- **The setup screens' calls count** in the running cost, toward the next
  call's spend-ceiling check, and in `served_by`.
- **Multi-model compression's calls are in `pbd_cost`**, and the whole-scan
  time estimate expects them.
- **A ring's discovery cost and the whole-scan range count what each call's
  endpoint reported**, where they used the listed price alone; the ring's cost
  line says how its calls were counted.
- **Estimates count the calls a batch takes**: a file read in parts and files
  that do not fit one call count each call in the live time estimate,
  `--dry-run` and the setup screens, and counting them marks no file as read;
  characterization's estimate leaves out documentation concepts the
  classification gate holds back.
- **A card's command row wraps only at its spaces**, so a long command stays
  whole on a narrow terminal.
- **An answer or a value a command refuses gets that command's own next
  steps** (a repeated `--behaviour`, `figure apply`'s checks, the picker's
  answer, `--profile`).
- **The missing-fields warning names the transport the run used**, and
  suggests `--draft-model`.
- **Small words in the setup card, `status`, the review list and a scan's
  counts**: plurals agree, and `models` and `init` print one blank line before
  their next steps.
- **`printf A | concept-scanner review <scan>` keeps the decision typed
  before input ends.**
- **A stopped scan no longer spends about 20 seconds retrying calls the stop
  refuses**, in characterization, the multi-model synthesizer and Pass 5.
- **Under `--skip-review`, JSON repair no longer calls the grader**, a model
  nothing had readied, and `models.json` names no Pass 2 model.
- **The local audit log records the scan's models, whether Pass 2 ran, its
  token totals and its cost** (null when unpriced, never 0).
- **A command that is not a scan keeps the serial default** against a server
  on this machine, where it went back to four requests.
- **The scan's cost line says an OpenAI-compatible server on a loopback
  address is not billed per token**, which is never priced, where it said
  "listed prices".
- **A scan at the smallest window a run accepts reads its files.** With a
  server holding a model at 8,192 tokens, a scan passed the check before the
  run, sent one call, read no file and exited 0 with no concepts: the sizing
  left discovery's whole 8,192-token answer budget out of an 8,192-token window.
  A prompt's sizing now leaves the answer at most half the window
  (`max-answer-share`), which changes nothing at the default 32,768. The same
  scan now reads all its files.
- **The window measurement no longer calls a full window cut.** Its long prompt
  was compared with a count scaled from one short prompt, which was up to 3.6%
  off depending on the model's chat template; `gpt-oss` models on a server
  holding the full 32,768 tokens were measured as cut. It now sends two short
  prompts of different lengths first, so the comparison is exact, and three
  prompts in all.
- **A window measurement waits once, for up to ten minutes a prompt**
  (`describe-measure-timeout`, for the check before a run and for `models
  describe --measure` alike). The two used to differ (4 and 2 minutes), a large
  model can take six minutes to read a prompt the size of the window, and a
  prompt that timed out was sent three times.
- **LM Studio's refusal of an over-long prompt is recognised** (its MLX engine
  words it differently from its llama.cpp engine), and a server that cuts a
  prompt to a length that does not show its window is told so, not told it
  "refuses" the prompt.

- **A model reloaded under a scan is said on any Ollama server.** The closing
  "model reloads" line read the server's log, which exists only for the server
  the app starts, so on a server started by hand, or on another machine, a
  model another program kept reloading was never mentioned: in a test, 32 of a
  scan's 94 calls waited for a load and the scan said nothing. The scan now
  also counts its own calls that had the server load the model, from the load
  time the server reports for each call, and says so when there were two or
  more (`models.json` 1.6.0 records the count and the seconds).

- **A server too slow to answer the window measurement is no longer called
  too small.** On `--provider openai-compatible` with a server on this machine,
  a long measurement prompt that timed out, or failed for any reason but its
  length, was read as the server refusing it, and the run stopped saying the
  window was "smaller than the 8192 tokens a run needs" with advice to load a
  larger one. Found on a model loaded with a 192 GiB context on a 96 GB machine,
  where the right advice is the opposite. An unanswered prompt now says nothing
  about the window: the line says what happened, and the run asks for the
  window, or stops with the `models describe --window` step. A server that does
  refuse an over-long prompt (llama.cpp's own error is now recognised) is told
  apart, and its message no longer claims the window is below 8,192, only that
  it is below the 32,768 tried.
- **`status.json`'s `heartbeat_s` is rounded up and never shorter than the
  reporter's tick.** A heartbeat set under a second read as stale.
- **`ui` says when a window already running keeps its values**
  (`kept_values`), and names `ui --stop` then `ui`: values reach only a window
  `ui` starts.
- **`tiers run` passes the values it was given to each arm**, and the arm
  record's batch size uses the discovery budget the arm resolves.
- **`update`, `models`, `version` and `ui` apply the values a person gave or
  saved.** The root's setup returned for them before it applied any, so a
  value they read was offered and never used.
- **`bridges` lists bridges of every size in its sizes line**, not only sizes
  2 to 6, which `--bridge-max-components` already allowed past.
- **A scan whose prompt the model server cut stops, and saves no scan.** The
  server's own prompt counts show a cut: the half-window count Ollama and
  llama.cpp keep, and, with no window known, the same count reported for two
  prompts of clearly different sizes, which is how a server that cuts every
  prompt to a fixed size looks. The call that shows it fails, every later model
  call is refused unsent, the run exits 1, and its concepts are kept in
  `unfinished.json` in the run's folder rather than saved as a scan. Before,
  the scan was saved and its envelope written with concepts from a prompt the
  model never read in full; only the exit code said otherwise. `bridges`,
  `triage`, `synthesize` and `figure draw` check their prompts the same way and
  save nothing after a cut.
- **A value refused for its range gets its own next steps.** It was told to
  re-run with `--verbose` and to check the provider; now it is told the range,
  `help <command> --json` for every flag's range, and `init --json` for a value
  `init` lists, and a saved value outside its range points at the settings
  file. `--coverage` and `ui --port` word their refusals the same way:
  `... is outside its range: give ... from 1 to 100`.
- **`review <root-id>` reviews every branch of a lineage.** Two widenings of
  one scan are two branches, and the review showed only the newest pass's,
  leaving the other branch's concepts out with nothing said. It now reads the
  union of every branch, shows a concept both branches found in the same file
  under the same name once (listed under `shared_concepts`), and writes a
  decision to each copy except one already exported. Any pass a review leaves
  out is named, with why, under NOT SHOWN, on every surface that lists
  concepts for review (`review`, `review --json`, `submit`, `figure draw`, the
  store listing). A widening's possible duplicates and yield now count a
  sibling's concepts too (`arc.json` 1.6.0, `union.json` 1.4.0).
- **`scan --changed` compares a file with the newest scan that read it.** It
  compared with the oldest, so a file edited once was read again by every later
  `--changed`, and a file put back to its first content was not read again
  though the scan before had read another version. Each recorded batch is also
  re-run once, where a batch that several scans had re-run was sent once per
  scan. A rename is now followed by every later scan, not only the one right
  after it, which used to list the old path as deleted and retire the concepts
  found before the rename.
- **A test name the answer schema cut short no longer rejects its evidence
  property**: the cut name is matched to the one paired test it begins.
- **Pass 5 could crash on a document whose lower-cased text changed length**
  (some non-ASCII characters) while looking for direction statements.
- **`--tests source` no longer copies a test's data into a concept.** A concept
  found in a test file is characterized from that file, and a test that builds
  a record of the same shape the scanner writes had its values copied into the
  concept, its scores included. The data a test constructs is now replaced by
  `<test data>` before the model reads the file, and any characterization text
  that still contains a sentence-length string from the test's data is removed
  and the concept marked `characterization_incomplete`. The test's code, names,
  comments and failure messages are still read, so a mechanism that lives in a
  test (a harness, a guard) is still described.
- **An answer that repeats itself until it is cut off is not requested again.**
  Classification (Pass 2) and the `--multi-model` merge sent the same request
  up to three times after a model looped to its output limit, and got the same
  loop each time, about eight minutes apiece on a local model. They now stop
  after the first. An answer cut off without repeating itself is still retried.

- **A `--multi-model` scan's context compression could make the context bigger,
  and then a file was dropped.** The step that summarises extracted files to fit
  them in one prompt was given a fixed output budget unrelated to what it was
  summarising, and a retry doubled that budget when a summary was cut off, so
  four batches could write more than they were given: measured twice in one day
  on the same eight-file corpus, growing it 23% and 25%, after which one file of
  eight was left out of the prompt. Each summary is now asked for at most half
  of what it summarises, and any summary that did not come back smaller than its
  own batch is discarded in favour of the original files, so a compression round
  can no longer grow the context whatever the model returns. A summary that
  cannot be produced at that size keeps its files uncompressed rather than
  failing the scan. Verified on a 24-file corpus whose context was three times
  the room: the growth happened, was discarded, the context shrank 42%, and no
  file was dropped.
- **`--tests evidence` now reads an assertion made through a helper library.**
  It read only assertions written as calls on the test's own testing value
  (`t.Errorf` and its siblings), so a message passed to an assertion library was
  not treated as something a test asserts. It now also reads an assertion handed
  the testing value as its first argument (`require.NoError(t, err, "opening
  the config")`), recognised by position rather than by library name so an
  in-house wrapper counts too, and only when the call stands alone as a
  statement, which is what keeps a fixture such as `f := newFixture(t)` out.
  **This may change nothing for your project**: a quoted property can only come
  from text a test contains, so a suite that asserts values without messages has
  little for this mode to read whatever assertion style it uses. Re-measuring
  the corpus that prompted the change moved the accepted count from 0 to 0, because
  152 of its assertions carry 3 quoted strings between them.

- **A scan of a symlinked directory read nothing and exited 0.** Pointing
  `scan` at a symlink to a directory collected zero files and finished
  successfully, where the directory itself collected all of them: the path
  check follows a link, and the path the walk then used did not. A symlinked
  target is now resolved to the directory behind it, as `git` and the `go`
  command do, so it reads the same files. Scan output names the resolved
  directory rather than the link that was typed. Measured on a 24-file corpus:
  0 files through the link before, 24 after, against 24 for the directory both
  times.
- **`--draft-model`'s help said the default was your primary model, and on a
  remote provider it never was.** With no `--draft-model`, a remote scan sends
  its drafting calls to a stronger paid model, and those calls are not only the
  synthesis passes: characterization is one call per concept, and triage, test
  evidence, bridges and synthesis are on the same model. So a scan naming a
  cheap `--primary-model` still spent most of its calls at the higher price,
  while four help strings said otherwise. All four now say what the default
  actually is and what the model is used for, and `PROVIDERS.md` documents the
  remote default, what it is spent on, and how to keep everything on one model.
  No behaviour changed: the default is the same, and it is now stated.
- **Every structured answer's text is now cut at a stated size after it is
  parsed.** A model that writes past a field's limit had its answer kept whole,
  so an unusually long summary, `technical_approach`, `key_insight`,
  `inputs_outputs`, component name or comparable-technique entry could be far
  longer than anything a reader or a consumer expects. Each of those now has a
  registered limit and is cut at a word boundary after parsing, and the scan
  reports when a cut happened. Measured on the default model, nothing came
  close to a limit, so this binds only on an answer that overruns.
- **Pass 5 counted a partial answer as a complete one.** Its load-bearing phase
  accepted an answer covering part of its batch as a success, so the retry and
  the batch split that exist for that case never ran. It now compares what came
  back against what it asked for and keeps a partial answer as a floor rather
  than discarding it.
- **A Pass 5 pattern scored by the model now outranks one left on defaults.**
  When scoring returned fewer results than there were candidates, the
  unanswered patterns kept their default scores and could sort above patterns
  the model had actually judged. Scoring retries once for the candidates it
  missed, and the sort puts judged patterns first.
- **A correction now reaches the stored scan, not only the concept file.**
  Applying a figure correction, recording a review decision, rescuing a
  location with `triage`, re-characterizing with `bridges` and exporting with
  `submit` all wrote the concept's own file and left the scan's own record
  describing it as first found. Re-importing such a scan sent the original back
  and undid the correction, and `synthesize` on a corrected scan read the
  pre-correction concepts. Every one of those writes now updates the stored
  scan as well, across all of the arrays it carries, and never changes which
  concepts are in them.

- **A corrected concept that was already exported can be exported again.**
  `submit` required `approved` and set `submitted` itself, and `review --set
  approved` refuses to change a decision behind an export that exists, so a
  correction could only reach the consumer if it was made before the first
  export. `submit` now accepts a concept it has already exported and writes the
  draft again, which the consumer imports as an update to the draft it holds, by
  id. It is refused only when nothing a consumer reads has changed since that
  export, and it says so rather than rewriting the file for nothing.
- **`figure apply` says what a second export does.** It described the consumer's
  older behaviour, that submitting again would create a second concept. It now
  says the consumer updates the draft it holds by id, and a corrected concept
  that was already exported is offered that export as its next step.
- **`figure apply` says when the figure it corrected was drawn over other
  parts.** Its part numbers are then read in the current numbering, which only
  the window used to disclose.
- **A redraw no longer discards the record of your corrections.** It still
  discards the arrows you drew, which is why it asks first, but the history of
  what was renamed, removed, added and re-worded now survives it. A rename also
  records the label it took off the figure, so what the model had drawn is still
  visible after you replace it.
- **A correction is judged against the component list the concept already has.**
  `figure apply` refused every correction to a concept outside the 2 to 12 parts
  a figure draws, including one that changed no part at all: new prose, a rename
  or an arrow on a concept with more parts than a figure draws was refused, and
  so was renaming the single part of a one-part concept. A correction is now
  refused only where it takes the count further out of that range, and the
  message says when the concept was already outside it.
- **A figure says how many of its concept's parts it does not draw.** A figure
  draws at most 12 boxes, and a concept can carry more parts than that, so a
  figure could quietly show twelve of fourteen. Its note now says how many parts
  are not drawn and how many boxes a limit refused, and it says the same when
  the model simply left a part out.
- **Every text a correction carries is cleaned before it is stored.** The arrows
  you draw and the record of each correction were written to `figures.json` and
  returned by `figure apply --json` without passing the output vocabulary check
  that every other field passes. An export was never affected.
- **An arrow can be removed from a figure whose model wrote `C1` for `c1`.**
  `figure apply --remove-edge` could not find an arrow the figure was drawing,
  and the terminal did not mark your own arrows as yours, when the model wrote a
  component's number in another spelling. Figures drawn before this still work.
- **A component with no text is reported rather than breaking the file.** One
  such part made `figure draw --all` fail for the whole scan on every attempt.
  It is now reported as not drawable, naming the part and the correction that
  repairs it.
- **A damaged `components.json` no longer stops a draw or invents a reason.**
  The read failure is reported, and a concept with no components whose cause is
  unknown says so instead of saying the scan predates that file.
- **The window asks before a redraw discards the arrows you drew.** Its Redraw
  button always replaced the figure, which the command refuses to do without
  `--redraw` for that reason. It now says how many arrows would be lost and
  replaces the figure only if you press it again.
- **Starting a command no longer erases what was on the terminal above it.** A
  command with a live status display, a scan among them, printed its first line
  before the display had drawn, and the display's first frame then cleared the
  screen below that line, so most of what was already on screen disappeared.
  Output now waits for the display's first frame. Menus and the live display no
  longer leave a stale copy of themselves behind when they get shorter (a menu
  kept its whole list on screen, with the cursor on the default rather than on
  your choice), and a long line printed above the display no longer loses one
  character each time it wraps.
- **The first setup screen waits for the model to read your documents.** It
  opened empty and accepted Enter before the answer arrived, so the purpose it
  found never reached the plan. It now shows that it is reading and holds Enter
  until the answer is in. The ready screen says whether bridges will run; it
  said "bridges off" for scans that ran them.
- **A scan that holds back or drops everything it found says so.** It said it
  "found no mechanism" right after holding mechanisms back below the score
  floor, or after dropping every one because each cited a file the repository
  does not have. The next steps now give the count and offer a re-run with
  `--include-textbook`, or the refusals with the file each concept cited.
  Re-run steps carry the scan's own path and flags instead of `scan <path>`, so
  the window can offer them as buttons.
- **A bridge no longer ships after the concepts it combines were dropped.**
  Bridges were drawn before the last check that drops a concept citing a
  missing file, so a bridge could ship whose every concept had been dropped.
  A bridge is now kept only when every concept it combines ships, and the run
  says how many were left out.
- **Rescans and plans count correctly.** `scan --parent <id> --changed` crashed
  whenever a file had changed. It now runs, says that it re-ran the recorded
  batch holding the changed file (it said there was no file to batch and then
  found concepts), and counts a re-read file once (it reported 135% coverage,
  and said the changed files were not read again on the pass that re-read
  them). A `--dry-run` plan no longer skips a ring number when a widening step
  adds no file.
- **What a scan prints reads as text.** Drop counts, contributing concepts and
  word lists printed in Go syntax (`map[file_missing:2]`, `[a b]`) and now read
  as lists. Sizes under 1 KB print in bytes rather than as "0 KB". Git's own
  files are no longer counted as excluded "generated" files (27 on a two-file
  repository), and `go.mod` and other settings, data and media files are
  reported as not a program rather than as an unsupported language. The warning
  that most characterizations were missing fields no longer counts concepts
  that were never characterized. Closing lines read "Bridging complete" and,
  for a dry run, "Planning complete", where they read "Bridg complete" and
  "Scan complete"; `figure draw` closes after the figure it drew; and
  `synthesize` counts the concepts it reads (it said 4 for a scan of 2).
- **Next steps and help.** No next step runs `open` any more, which exists only
  on macOS; seven of the thirteen that did opened files an installed copy does
  not have, and addresses now go in the step's reason. `bridges` suggests
  `submit` with the scan id it needs. `triage` says when nothing needs
  grounding instead of announcing that it is asking the model. Help no longer
  names internal identifiers, and the main help prints one Usage block.
  `status --wait` says which run it waits for, and that Ctrl+C stops the
  waiting, not the run. The `--multi-model` error names `init --profile
  validated` as the way to save a profile. The `.env.local` note no longer
  calls an API key set there a variable this tool does not read: keys are read
  from the environment, never from that file.
- **The window's Settings no longer contacts GitHub when you open it.** It
  asked for the newest release on every visit, every refocus and after every
  save; it now asks only when you press Check now, which is what the README
  promises. The Validated profile's row shows both models it runs, not only the
  first.

### Added

- `review --json` carries `concept_refs`, the name each concept is addressed by,
  one per concept in the order they are listed, which is the name `figure draw`,
  `figure apply` and `submit` take.
- `figure draw --json` carries `unreadable` when a disclosure beside the scan
  could not be read, so a missing reason is visible rather than silent.
- `help --json` lists rules between a flag and a positional argument, as kind
  `excludes_arg`: `figure draw` names a concept or passes `--all`, never both.
- An exported draft distinguishes "no arrows" from "nothing to say" about them:
  `component_edges` is absent when there is no figure to read, or its parts have
  changed since it was drawn, and an empty list when the figure draws no arrow
  between two components.

## [1.3.0] - 2026-10-06

### Added

- **A figure for each concept, drawn by your model and corrected by hand.**
  `concept-scanner figure draw <scan-id> [concept-id]` (or `--all`) asks your
  primary model for a small graph of how a concept's own components connect,
  one call per concept, and stores it beside the scan in `figures.json`, with
  its Mermaid source. Each part cites a component by number, and a part that
  cites none is drawn dashed and counted, so it cannot pass as one of the
  concept's own. `figure apply` corrects a figure: renaming, removing or adding
  a part writes it back to the concept's components, so an export carries it,
  and `--edge` draws an arrow between two parts. Nothing in a scan reads a
  figure. The window draws each concept's figure in its review screen, with the
  same corrections, Copy Mermaid and Save as SVG. Before drawing, the command
  says whether the model is already loaded, fits beside what is loaded, or
  needs another model unloaded first.
- **`concept-scanner ui` opens this program in your browser.** It starts a
  window on this machine's loopback address (127.0.0.1) and opens it, or opens
  the one already running. In it you choose a folder and scan it with live
  progress (with a purpose, the coverage to read first, files to pin or leave
  out), watch every scan running on the computer, review what a scan found and
  approve, reject or export it, choose the model, a cloud provider and its key,
  turn the update check on or off, and run any command with every option it
  takes. The window runs this program's own commands, so it sees the same
  scans, settings and keys an agent does, and a key saved in it is what a
  terminal scan uses. It refuses requests addressed to any other host or sent
  from any other site, and needs a secret the browser is given once. `ui --stop`
  quits it (refused while a command it started is running); `ui --serve` runs
  its server in a terminal and opens no browser. On a Mac, opening the app acts
  as `ui`.
- **A Mac app and a Windows installer.** Each release carries
  `concept-scanner-macos.dmg`, a universal app (Apple silicon and Intel)
  signed, notarized and stapled, which opens the window when double-clicked,
  and `concept-scanner-setup.exe`, a signed per-user installer with a
  Start-menu shortcut that needs no administrator rights; its uninstaller keeps
  your scans, settings and keys. Both update themselves: the app replaces
  itself whole from the new disk image after checking Apple's signature for
  this publisher, and the window's **Install and restart** button installs a
  newer release and reopens onto it. The bundle's own executable run from a
  terminal stays a terminal program; only macOS opening the app opens the window.
- **`models --json` gives the cloud endpoint's address** (`cloud_base_url`),
  and `review --json`'s list gives each lineage's file-set flags as an argument
  list too (`file_set_args`), so a program can widen a lineage without
  splitting a line.
- **`scan --dry-run --json` returns the repository's saved setup**: the
  purpose, behaviours, pins, drops and last scan the returning setup screen
  shows, under `saved_setup`, and a step to widen the last scan when it read
  less than everything. No command returned them before.
- **`scan --drop <path>` and `scan --behaviour <text>`**, the setup screens'
  last two choices as flags, so a scan set up without the screens can say
  everything they can: `--drop` leaves an exact path out (a folder ends in `/`)
  and every widening keeps it out; `--behaviour`, up to eight times beside
  `--intent`, names the behaviours whose files are read first.
- **`help --json` lists every command.** Each command's arguments and what they
  name (a folder, a scan id), every flag with its type, default, allowed values
  and range (hidden ones marked), and the rules between flags the commands
  enforce, read from the command tree itself, so it cannot describe a flag
  differently from how the command parses it.
- **Every command that calls a model shows its progress the way a scan does.**
  `bridges`, `triage`, `synthesize`, `bench`, `anchoring-check` and
  `distill gate` take `--progress` and write the run's status file and log;
  `tiers run` shows a stage per arm. `status --running` lists every run in
  progress with its command and target, a run's status says whether it widens
  a scan or re-reads what changed since (`changed_rescan`), and a model
  download reports its bytes as well as its percentage.
- **A next step that runs this program carries its arguments** as `args`, beside
  the `command` line a shell reads back into them, so a program can run it
  without a shell; a step with a `<placeholder>` has none. **And an error raised
  before a command runs** (a flag it does not have, a missing argument) is the
  `--json` envelope when `--json` was given, where it used to be plain text.
- **An API key saved once is used by every command.** `init --with-key` reads
  the key from stdin (hidden at a terminal; piped otherwise, never a flag) and
  saves it, readable only by you, for the exact host of your saved endpoint; a
  key in the environment still comes first. It is sent to that host and no
  other, refused for plain http to another machine, never copied into the
  process environment, and shown only by its last four characters (`init
  --json`, which also gives each key the command that removes it).
  `init --remove-key` removes the saved endpoint's key, and with `--base-url
  <url>` the key saved for that endpoint, saving nothing else. A damaged key
  file stops the run and is left as it is, rather than being read as no keys
  and overwritten.
- **A provider saved once is what every command uses.** `init --provider
  openai-compatible --base-url <url> --model <id>` saves a cloud provider, and
  `scan`, `bridges`, `triage`, `synthesize`, `bench` and `anchoring-check` use it
  whenever their own flags name no provider; the run says so. A flag still wins
  for that run (`--provider ollama` runs locally). Picking a cloud model in the
  first-run setup saves it the same way, and picking a local profile switches
  back. `init --profile <key>` saves a local profile with no questions, and
  `init --json` shows what is saved and which environment variables are in
  force (a key is shown only as set).
- **`models --json` says what a first-run screen needs**: this machine's memory,
  the profile that fits it, the saved profile and provider, and whether Ollama is
  installed apart from whether it answers, so its advice is "open the Ollama app"
  or "download Ollama" rather than `ollama serve`.
- **`review` with no scan id lists what is stored**: every lineage by the id to
  review it with (its first scan), with its passes, when it last ran, how many
  concepts and bridges it holds and how many are approved and pending (the same
  counts `review <id>` reports), and the file-set flags a widening must repeat,
  which no output showed before. A scan whose record cannot be read is listed as
  unreadable, never left out. `--json` gives the same list.
- **`review <scan-id> --set <id>=approved|rejected|skipped` records a decision
  without a prompt**, repeatable, for concepts and bridges, so a script or an
  agent can do what the interactive review does. It can change an earlier
  decision, every value is checked before any is written (an unknown id is an
  error naming it), and with `--json` it reports the new tallies and what it
  recorded. Reviewing the first scan of a lineage covers every pass, and there a
  concept is named with the pass that found it, `<pass-id>/<id>`, because each
  pass numbers its concepts from 001.
- **`review` and `submit` now work over a whole lineage.** Give `review` the id
  of your FIRST scan and it reviews every pass that continued it, saying so:
  "union of 3 passes, 41 concepts". Each decision is saved against the pass
  that found the concept, so re-running an earlier pass cannot undo it. A
  concept whose file changed since it was found shows STALE with the two
  content hashes, one whose symbols are gone shows RETIRED with the names that
  no longer resolve, and both can still be approved and exported: those are
  disclosures about the evidence, not verdicts on the mechanism. `submit` names
  the state and proceeds. A concept the store cannot load is reported rather
  than quietly left out of the review.
- **Every concept now says which call found it.** A `provenance` object on each
  concept names the scan, the avenue, how many files shared the discovery call,
  and which files those were. Yield is per call, so two concepts are only
  comparable as evidence of density when the calls behind them were comparable,
  and until now nothing in the output said what call a concept came from. It is
  a disclosure, not a score: nothing ranks or filters on it. The concept schema
  moves 1.9.0 to 1.10.0; a concept with no provenance means this scan did not
  say, which is never the same as "found on its own".
- **A renamed file keeps its concepts.** When a rescan can see that a covered
  file moved, the concepts citing it follow it, with the path they used to cite
  recorded beside them, and the file is not read again. Seeing it needs git and
  the earlier scan's commit, which a shallow clone does not have; when that is
  the case the scan says so rather than reporting that nothing moved, and a
  renamed file reads as one deleted and one added, as before. The batch that
  held it is re-run and reported as a NEW batch even when not one byte changed,
  because a batch names its files, so its prompt is not the same prompt.
- **A concept whose file is gone is retired, naming the absence.** It is kept,
  never deleted, and it comes back by itself if the file does. A file that is
  still there and cannot be read is NOT retired and says why: an unreadable
  file is not evidence that anything went away. A covered file that left the
  scan because a flag changed is not a deletion either.
- **`--depth <n>`:** how many files may share one discovery call, 1 to 4. The
  default works it out from the file sizes; this sets it. The scan's `Depth:`
  line says which of the two it was, and a number above the ceiling is cut down
  with the number you asked for named. Refused, rather than quietly ignored,
  with `--multi-model`, which has no discovery batches to bound.
- **`components.json` says WHY a concept's component list is the length it is.**
  A concept can carry 2 to 6 short names for its sub-mechanisms, and until now an
  absent list had four different causes and one spelling: the model named none,
  it named exactly one and the emitted field cannot carry a single name so the
  field was left out, it named more than six and the rest were cut, or
  characterization never answered for that concept at all. Each is correct per
  concept and none was recorded, so "this mechanism has no parts" and "we could
  not fill the field" arrived as the same bytes. This file records the cause for
  every shipped concept, keeps the names the bounds removed, which are the only
  place they survive, and prints one line on every scan. **It never judges the
  mechanism**: a concept recorded as named-none may have no sub-parts, or may
  have been described too vaguely to break into parts, and the file says plainly
  that it cannot tell those apart. Nothing is dropped, renamed or reordered by
  it, and nothing in the scan reads it. Measured while building it, over 7,376
  stored concepts: 97.5% of what the current output format ships carries at
  least two components and a description of how they interact, and the causes
  are recorded from this release onward, so scans made before it keep their
  silence.
- **`redundancy.json` now reports the near-duplicate NAME rate** (schema 1.2.0):
  how many pairs of concept names read as the same name at a published
  similarity threshold, how many of those cross a file boundary, how many names
  are in at least one pair, and the pairs themselves. Every scan prints it on
  its redundancy line. It is a different kind of number from the four relations
  beside it, so it is kept apart from them and labelled: those are exact and
  untunable, this is a similarity score. It exists because one model repeated a
  single mechanism under three near-identical names in one scan and nothing
  reported it: on that 25-file corpus a 7B model measured 0.200 pairs per name
  against a 30B model's 0.083. **Nothing is dropped or reordered by it**, and it
  is not a quality score for a model: on a second 24-file corpus the same two
  models measured 0.045 and 0.074, the smaller model LOWER, so the ordering
  inverted. Real repositories that implement one mechanism in several files
  measure 0.009 to 0.100, and a template that names every exported symbol after
  its own declaration reaches 1.05. Read it as what one scan contains, and
  compare models only on one corpus at a time.
- **`union.json` now says what to do about each file that produced nothing:**
  the calls it sat in, whether it ever had a call to itself, and whether
  re-reading it one file to a call is worth doing. A file that already had its
  own call is named as excluded, because reading it alone would send the same
  prompt again. A covered file whose call was never recorded says that too,
  rather than being reported as though it had been alone.
- **A scan can now re-read only what changed, and say what a second pass
  added.** With `--parent`, `--changed` re-reads the files an earlier scan
  covered whose contents have changed since, by re-running the same discovery
  batches that held them, with the same files in the same order, so the new
  concepts are comparable with the ones they replace. A batch that lost a file
  is re-run without it and reported as a new batch, because its prompt differs.
  `--changed` needs `--parent` and says so.
- **`union.json`, beside a widened scan:** every concept every pass of that
  lineage shipped, each attributed to the pass that found it, and how much this
  pass added, as a RANGE rather than a single number. The range is honest about
  what cannot be known: a widening reads files no earlier pass read, so two
  passes never cite the same file, and only a concept's name can be compared
  across them. Its low end reads every shared name as the same mechanism found
  again, its high end reads none as such. A concept whose file no longer
  contains the symbols its description names is marked retired and KEPT, never
  deleted, and lists what no longer resolves; a file that cannot be read is
  reported as such and retires nothing.
- **`--only <glob>`, repeatable:** read only the paths you name. It narrows
  what the scan considers at all, so a coverage percentage stays a percentage
  of what you asked for, and it composes with `--exclude`, which still removes.
  Name a directory (`--only internal`) to take its whole subtree.
- **A next step that offers to re-read the files a scan got nothing from**, one
  file to a call, since a file that shared a call competed for that call's
  output. It leaves out the files that already had a call to themselves, prices
  the re-read from your own run's calls, and quotes a range of 1.75 to 2.60
  concepts per file rather than one number. It says plainly that this buys
  coverage and not depth: the concepts recovered this way were descriptions of
  subsystems, not of the unusual mechanisms a scan is for.
- **Each scan records which files shared each discovery batch** (in
  `arc.json`), which is what lets a later scan restore a batch exactly. A scan
  that forms no batches, such as `--multi-model`, says so rather than leaving
  the record empty.

- **A scan can read part of a repository first, outward from what the project
  is for, and widen later.** At a terminal, three screens now come before a
  scan: the project's purpose and behaviours, read by your model from the
  project's own documents (each behaviour kept only with a quote found in the
  document it cites), which you can edit; which folders would be read first,
  ranked outward from the files the model names for each behaviour along the
  code's dependencies and folders, with their tokens and the expected time;
  and a ready screen. Without a person at the terminal a scan reads every file
  as before, unless it passes `--intent`, `--intent-file` or
  `--intent-from-docs` with `--coverage <pct>`. `--parent <scan-id>` widens an
  earlier scan, reading only files no scan in its lineage has read, and
  `--pin` always reads a glob first. `--dry-run` shows every ring with its
  files, tokens and time and saves the plan without reading anything with the
  model. A folder you drop on the screens is read by no part of the scan, and
  stays out of every later scan that widens it and out of a saved plan. A
  widening collects files the way its first scan did (the same `--exclude`,
  documents and tests modes), and is refused, naming the flags to give, when it
  would not; every command a scan prints repeats the flags you gave. The
  purpose is never sent to the scan's own prompts. Each such scan
  writes `intent.json` and `arc.json` beside it, and says in its summary and
  `--json` notice that it read part of the repository. Your choices are kept
  per repository in `~/.concept-scanner/repos/` in your home folder.

### Changed

- **An exported draft carries the arrows you drew.** Concept schema 1.13.0
  adds `component_edges` to the `submit` draft: each arrow you drew with
  `figure apply --edge` between two of the concept's components, as
  `{"from": "c1", "to": "c4", "label": "..."}`, where `c<n>` is the nth entry of
  `components`. An arrow touching a part the model added stays on the figure,
  and a figure drawn over parts that have changed since exports none; `submit`
  says when either happens. The arrows the model drew are not exported. An
  arrow from a part to itself is now refused.
- **`review --sort score|file` chooses the order concepts are listed in.**
  Concepts awaiting a decision come first, then the rest, and `score` (the
  default) puts the strongest first while `file` groups them by file. The
  terminal, `review --json` and the window now list concepts in the same order;
  before, the window showed them in the order they were stored, and reviewing a
  lineage of scans was never sorted by score. The window has a "by score / by
  file" control.
- **`submit` keeps each scan's drafts in their own folder.** Left to its
  default, a draft is written to `output/<scan>/concepts/` (or
  `output/<scan>/bridges/`) in the data folder, where `<scan>` is the pass the
  item belongs to. Concept ids are numbered from 001 within each scan, so the
  same id is ordinary across scans, and the old shared `output/concepts/` let a
  second scan's draft silently replace the first. An `--output` you give is
  still used as given.
- **Every concept says which models its scan ran.** Concept schema 1.11.0 adds
  `provenance.models`: each model by role (discovery, classification,
  characterization) with the digest its tag pointed at. Until now that lived
  only in the scan's `models.json`, which an importer never receives. On the
  `--multi-model` path, `models.json` now also names the characterization
  model, which it used to leave out.
- **A bridge whose three engineering scores were not answered says so.**
  Bridge schema 1.2.0 adds `axes_unanswered`, true when technical
  distinctiveness, generality and commonness all came back exactly 0, which
  means the model's answer left them out rather than scored them; `review`
  shows them as not scored instead of 0.00. Before this an importer stored the
  zeros, and a commonness of 0 reads as maximally unusual. Locally the three
  are now REQUIRED in the bridge request's schema, so a local model cannot
  leave them out (a re-run: 3 of 40 unscored before, 0 of 43 after); the flag
  remains for remote providers, which do not enforce the schema.
- **An exported draft records the commit it was scanned at.** `submit` writes
  `source_audit.commit_hash` (concept schema 1.12.0, bridge schema 1.2.0), so a
  concept imported from a draft can say which version of the code it
  describes, as one imported from a whole scan already could.
- **A scan's held-back counts are always written.** Scan result 1.4.0 writes
  `textbook_held`, `low_score_held` and `ungrounded_dropped` even when they are
  0. A score gate that held nothing back is worth seeing, and an omitted zero
  read the same as an older scan that did not report the count.
- **`submit` names its scan: `submit <scan-id> <concept-or-bridge-id>`.** An id
  found by id alone could be the wrong copy: inside one lineage every pass
  numbers its concepts from 001, so a `--changed` rescan finds the same ids
  again, and the oldest copy was the one exported. The scan id is the one
  `review` takes; over a lineage, name a concept with its pass as
  `<pass-id>/<id>` (its `provenance.scan`), as `review --set` does.
- **Flags that cannot go together are refused before the command runs**, with
  one message shape: `--docs-only` with `--exclude-docs`, `--depth` with
  `--multi-model`, `review --set` with `--why`, `init --with-key` with
  `--remove-key` and `--profile` with `--model`, `status --running` with
  `--wait`. `--with-dependents` without `--changed`, and `--changed` without
  `--parent`, are refused the same way as before.
- **`synthesize --json` speaks the same envelope as every other command**, with
  real next steps, and **`synthesize --format` is gone**: its JSON could never
  have been parsed, because progress lines went to stdout before it. Use
  `--json`.
- **`bench --write-config` saves without asking**, under `--json` too, where it
  used to save nothing.
- **`tiers run` names `--provider ollama` for every arm**, so a saved cloud
  provider cannot reach a measurement of local tiers. A sweep begun on an
  earlier version reports its old and new arms as not comparable (they ran with
  different flags); re-run it with `--force`.
- **`synthesize` keeps what it can when a later Pass 5 step fails**, as
  `scan --synthesize` already did: a failed combination or scoring step is
  reported and the patterns that do not depend on it are kept, where it used to
  stop with nothing. Both now run the same Pass 5.
- **Your saved choices now live in one file in your home folder,
  `~/.concept-scanner/settings.json`.** The model profile `init` and the
  first-run picker save, `bench --write-config`'s parallel batches, and the
  hand-edited `"think"` and `"budgets"` sections all moved there from
  `data/config.json`, which is no longer read: copy any `"think"` or
  `"budgets"` section you had into the new file, and re-run `init` to save a
  profile. A file that cannot be read is now moved aside and named in a
  warning, never overwritten, and two copies of the program saving at once no
  longer erase each other's changes.
- **Scans now live in one place, `~/.concept-scanner/data`, whatever folder you
  run from.** They used to go to a `data` folder in the directory you ran the
  command from, so a scan started elsewhere, or by an agent, was invisible to
  `review` run here. `submit` now writes its drafts to `output/` in that folder
  (it wrote `output/concepts` and `output/bridges` where it ran), and `tiers`
  writes to `tiers/` there. **Scans you already have in a project's `data`
  folder are not read from there**: copy them across
  (`cp -R data/. ~/.concept-scanner/data/`), or set `DATA_DIR=./data` to keep
  using that folder. Set `DATA_DIR` to keep scans anywhere else; with no home
  folder and no `DATA_DIR` a command now stops and says so. The container image
  and the GitHub Action still keep scans in the scanned repository's `data`
  folder.
- **Uninstalling keeps your scans, settings and saved keys.** `install.sh --uninstall` and
  `install.ps1 -Uninstall` used to delete `~/.concept-scanner`; they now remove
  the program and the extraction cache, leave that folder, say what it holds,
  and print how to delete it.
- **The extraction cache needs a user cache folder.** With none (no home
  folder), a multi-model scan now stops and says so instead of using a
  temporary folder for one run.
- **Each command offers only the flags it reads.** `--exclude`,
  `--include-clients` and `--include-fixtures` belong to `scan` and `triage`;
  `--only` to `scan`; `--tests` and `--include-tests` to `scan` and
  `tiers run`; `--log-requests` to the commands that call a model. They used to
  appear on every command, so `review --exclude vendor` was accepted and did
  nothing; it is now an unknown flag. `tiers run` passes the request log to its
  arms through `CONCEPT_SCANNER_LOG_REQUESTS=1`. `version`, `init` and `models`
  now refuse arguments they used to ignore, and the usage line of every command
  that needs an id says so (`review <scan-id>`).
- **A model server that is not running is reported as "Open the Ollama app, or
  run: ollama serve"**, everywhere it was "Start it with: ollama serve": a
  person who uses the window, or a Mac or Windows desktop, starts Ollama as an
  app.
- **`OLLAMA_HOST` is not read.** It never took effect (the `--ollama-host`
  flag always has a value, which won), and `.env.local` could set it, so
  making it work would have let a scanned repository move "local" inference to
  a server of its choosing. Point at another local server with `--ollama-host`.

### Removed

- **`scan --type` (`-t`).** Its help offered five scanner strategies, and no
  part of a scan ever read the choice: every value scanned the same way. A
  script that passes it now stops with "unknown flag"; drop the flag and the
  scan is the one it always ran.

### Fixed

- **A concept whose characterization failed no longer ships looking
  characterized.** When the characterization call failed, its source could not
  be read, or no model provider could be built, the concept used to be marked
  `characterized` with zeros on its engineering axes, which an importer reads as
  scores. It now keeps the status `extracted`, carries
  `characterization_incomplete`, is not held back by the score floor on its
  discovery-time estimate, and appears in `refusals.json` (and `refusals`) as
  shipped without axes, with the cause. `characterization_incomplete` also now
  marks a concept whose depth, specificity and generality all came back
  unanswered.
- **An answer that quotes a regular expression is no longer thrown away.** A
  model describing code that contains `\p{L}` or `\d` often writes it into its
  JSON answer without escaping the backslash, and the whole answer was rejected.
  Such escapes are now repaired, only when the answer fails to parse as given.
  Locally, an answer that cannot be read is no longer retried three more times,
  since the same prompt returns the same answer.
- **A `--multi-model` scan's concepts name the file they come from.** When the
  scan shortened its findings to fit the final merge, the file names were lost,
  so every concept shipped with no location and without the engineering details
  that need one. A shortened summary now names its files, and the merge must give
  every concept a location.
- **A `--multi-model` scan sends every file to its final merge when they fit.**
  It held back about half the model's window, so on a small repository it often
  shortened its findings, and when the model made them longer instead, a file
  was left out. It now checks the real request (its prompts, the findings and
  the answer's budget) against the window, stops shortening after a round that
  does not make the findings smaller, and no longer sends each extracted
  statement and principle two or three times over.
- **The second model in a `--multi-model` scan is asked for at most 25
  statements per file**, and a longer answer is cut to its first 25 with a
  warning. A small model listed statements until it ran out of room, and the
  file fell back to the primary model alone. A local server that does not
  enforce the limit while the answer is written can still let it run out.
- **`submit` names a STALE or RETIRED concept's state**, from the lineage's
  newest union. It read the union beside the concept's own pass, where none is
  ever written, so the notice never appeared.
- **`review` offers a concept or bridge that has no review status**, which
  its tallies already counted as pending; it used to skip it, so a review could
  end with items pending that it had never shown.
- **`bridges`, `triage` and `synthesize` on a remote provider without
  `--primary-model` sent a local Ollama model name to the endpoint.** They now
  use the same cloud default `scan` does, and every command picks its model by
  one rule. They also now limit how many requests run at once on a remote
  provider, as `scan` does; before, only the local limit was set.
- **`bench`, `anchoring-check` and `distill gate` now say when your code leaves
  this machine.** On a remote provider they sent source to the endpoint without
  the notice every other command prints; every command that runs a model now
  decides and checks its provider in one place.
- **Reading tests as a source no longer decides whether documents are read.**
  The automatic rule reads a repository's documents unless code is more than
  half of what it collects, and with `--tests source` the test files counted
  as code, so a repository with many tests stopped reading its documents.

- **A multi-model scan that cut summaries from its synthesis prompt reported
  dropping no files.** When a repository's extractions did not fit the model's
  window even after compression, the scan left whole compressed summaries out
  of the prompt, and `files_dropped_at_batch` counted only files left out one
  by one, which at that point never happens, so it said 0. It now counts every
  file a cut summary stood for, and lists them, so a coverage scan does not
  count them as read and the next widening reads them.

- **A description that named its own file was marked partly ungrounded.**
  The check that a concept's description names symbols its cited file
  contains counted the file's own name ("the retry in retry.go") as a symbol
  the file must contain, which most files do not. It no longer does; about one
  verdict in five hundred in real scans' `grounding.json` changes.

- **`concept-scanner models` showed the Thorough profile as not pulled when it
  was.** That profile names its model without a tag, and Ollama lists every
  model with one (`:latest`), so the check never matched. A model named without
  a tag is now compared as its `:latest`, in the table, in `--json` and in the
  setup screen to come.
- **A scan's `commit_hash` and `branch` were always empty.** Both fields have
  been in the scan output from the start and nothing filled them in, although
  the commit was read for the audit records. They now carry the commit and
  branch of the scanned repository. They stay empty when the folder scanned is
  not the top of a git repository (a subfolder of one included, as before for
  the audit records), and `branch` stays empty on a detached checkout (as in
  many CI jobs), where git reports `HEAD` rather than a branch name. Scans saved
  before this change keep their empty values.
- **A concept could be placed in a file the scan had skipped.** A scan leaves out
  client and example folders, fixture folders and anything `--exclude` names,
  but the steps that decide which file a concept lives in (the path the model
  gave, the repair of a malformed path, the search for a file with the same
  name, and triage's search) skipped only vendored and generated folders. So a
  concept could be credited to example, fixture or excluded code the model was
  never shown. Those steps now follow the same rules as the scan itself. A
  concept whose only match is in a skipped folder now goes to triage, which
  searches the files the scan read, and is dropped as ungrounded if nothing
  there matches (with `--no-triage` it is kept, marked pending, as any
  unconfirmed location is). `--include-clients`, `--include-fixtures` and
  leaving out `--exclude` still let those files be found.
- **The calls that group files for semantic batching were missing from the
  cost log.** Apart from the model warm-ups, they were the one discovery-stage
  call that recorded nothing, so
  a remote scan's token totals left them out, their time could appear in the
  "not accounted for" note at the end of a scan, and the progress estimate had
  no history for them. They are now recorded as `batch-suggestion`, including
  when their answer cannot be read. Cost logs written before this change have no
  such rows.
- **A repository with git worktrees inside it was scanned once per copy.** A
  scan read every folder below the one you named, including folders that are
  checkouts of their own: an agent's worktree (for example under
  `.claude/worktrees`) is a full copy of the repository at another commit, so
  its code was scanned again. Such folders are now skipped, and the exclusion
  summary counts them as "in other checkouts" and says to scan one directly to
  read it. This also skips **git submodules** and repositories cloned inside
  yours, whose files belong to another repository; to scan a submodule, point
  `scan` at its folder. The folder you scan is still read when it is a checkout
  itself.

### Security

- **`.env.local` can no longer set an API key, `DATA_DIR`, or anything that
  steers what a key is spent on** (`CS_EXTRACT_MODEL`, `CS_TWO_PHASE`,
  `CS_SEMANTIC_BATCHING`, `CS_REMOTE_CONTEXT_CAP`, `CS_RECORD_EXAMPLES`,
  `CONCEPT_SCANNER_TESTS`, every `CS_BUDGET_*`). Once keys can be saved, a file
  in a cloned repository that set them would spend your key on its own terms: a
  key from it would come before yours and send your code to your endpoint on
  someone else's account, where its request logs are visible to them. Set these
  in your real environment instead.
- **A repository being scanned could choose which models ran and how much
  output each pass may use.** The saved model profile and budgets were read
  from `data/config.json` in the data directory, which is inside the
  repository for `scan .` run from its root, in the container image and in the
  GitHub Action, so a repository could ship one; on a cloud provider that is
  what your key pays for. Saved choices are now read only from your home folder.
- **A `--multi-model` scan kept its per-file extractions in a `cache` folder
  where it ran, and trusted whatever it found there.** In the container image
  and the GitHub Action, and for `scan .` run from a repository's root, that
  folder is inside the repository being scanned, so the scan wrote its cache
  into the repository (root-owned in the image), and a repository could ship
  an entry that replaced one of its files' extraction with text of its own
  choosing, so that file's code was never sent. The cache now lives in your
  user cache folder (`~/Library/Caches/concept-scanner/extractions` on macOS,
  `~/.cache/concept-scanner/extractions` or under `$XDG_CACHE_HOME` on Linux,
  `%LocalAppData%\concept-scanner\extractions` on Windows), readable only by
  you, and a run with no home folder uses a folder of its own that it removes
  when it ends. The first multi-model scan after updating extracts every file
  again. An old `cache` folder is no longer read and can be deleted. A cached
  extraction is now attributed to the file that asked for it: it carried the
  path of whichever file first had the same content, which in a shared cache
  could be another repository's, and that path went into the prompt.

- **A file that is a link into the repository's `.git` folder is no longer
  read.** A README, or any collected file, that was a link to `.git/config`
  was read like the file it pretended to be and sent to the model, and in the
  GitHub Action that file holds the checkout's token. Collection now skips such
  a link, and no other step reads one.

## [1.2.0] - 2026-10-03

### Added

- **Tests are paired with the concepts they exercise.** After a scan decides
  which concepts it ships, each concept in Go, TypeScript, JavaScript or Python
  is paired with the tests beside it that use the declarations in its line
  range (or, when the model gave no range, which is the usual case, the tests
  of what its description names first): Go's `_test.go` files in its directory,
  read from the syntax tree; TypeScript's and JavaScript's `.test.` and `.spec.`
  files and `__tests__`; Python's test files and the `tests/` files named for
  its module or mirroring its path, the last three read by pattern. The result
  is written beside the scan as `tests.json`, with one line in the output
  ("Tests: 12 of 30 shipped concepts are paired with tests that exercise
  them"). No model is involved and no concept changes. `--tests evidence`
  also asks the model what those tests assert that a concept's description does
  not say, one call per paired concept, and keeps a property only when its quote
  is found in the test's name, a failure message reported on the test's own
  `t`, the condition guarding one, or a case label the test prints and does not
  pass to the code, and when its statement repeats no phrase found only in the
  test's setup data; every rejection is listed with its cause, and the model's
  own words pass through the vocabulary sanitizer. `--tests source` also reads tests as a
  source, in batches of their own. `CONCEPT_SCANNER_TESTS` sets the default, and
  `CS_BUDGET_TEST_EVIDENCE` the output budget of the `evidence` call. See "Tests
  as evidence" in the README.
- **A scan now says what it is doing while it runs.** On a terminal, a status
  line at the bottom of the screen shows the stage and how far through it is,
  how long the current model call has taken, an estimate of the time left
  (marked `~`, and shown only once there is recorded history to base it on),
  tokens, cost or `local`, and a count of warnings and errors, with the last
  few log lines under it. Results and warnings print above it and stay in your
  scrollback; when the scan ends it is replaced by one summary line. Off a
  terminal (CI, the Action, a pipe, a coding agent) there is no redrawing at
  all: each stage's start and end is its own timestamped line, and a heartbeat
  line follows whenever 30 seconds pass without one, so a log never goes quiet
  for minutes. `--progress auto|live|static|plain|jsonl` (or
  `CONCEPT_SCANNER_PROGRESS`, which every command's menus follow too) chooses;
  `static` is the status line without motion. A remote run's closing line names
  its estimated cost and the date of the prices it used. A model download is a
  stage of its own, with progress and an estimate, and outside a scan it prints
  a line at every tenth instead of rewriting one line.
- **`concept-scanner status [run-id]`** reads a scan's status file: its state,
  stage, time since it last made real progress, time left, tokens, warnings, and
  where its log and results are. A run whose process has gone, or whose file
  has not been updated for three heartbeats, is reported as **stale**.
  `--wait` waits until the run ends and exits with its exit code (or 1, with a
  notice, if it was cancelled, went stale, or `--timeout` passed), which is the
  way for a script or an agent to wait on a scan without watching the process
  list. Without a run id it takes the most recent run, so pass the id (printed
  on the scan's first line) to wait on one scan and no other. `--json` gives the
  usual envelope.
- **Every scan writes a status file and a log** under `DATA_DIR/runs/<run-id>/`
  (the newest 50 runs are kept; a running one is never removed), and copies its
  final status beside the scan as `run.json`. The run id and the status file's
  path are printed when the run starts. None of this is part of the emitted
  scan result.
- **`--progress jsonl`**: one JSON event per line on stderr (run start and end,
  stage start and end, progress, each finished model call, retries, warnings,
  errors, and a heartbeat every 10 seconds), with nothing else on stderr; stdout
  is unchanged.
- **Menus you can drive with the arrow keys.** The first-run questions (local or
  cloud, the cloud model, the scan profile, how many batches run at once) take
  ↑/↓ and Enter as well as the letter or number each option always had, and
  each leaves one line saying what you chose. Esc or Ctrl+C stops, saving
  nothing. A pipe, `TERM=dumb` or `--progress plain` keeps the typed prompts. A
  later scan says which saved profile it is using, and an interactive scan shows
  what it is about to do before it starts.
- **In GitHub Actions**, each stage is a collapsible group, warnings become
  annotations (the first 10, with a count of the rest), and a summary table is
  added to the job summary.
- **Tab and taskbar progress** in Windows Terminal, ConEmu, Ghostty and iTerm2
  (never inside tmux), and a bell when a scan finishes while its terminal is not
  in focus, in terminals that report focus.

- **Documentation is now read as documentation.** A batch whose files are all
  documentation is analysed with a prompt written for prose, instead of one that
  opens by telling the model it is reading source code. Only the framing
  changed: the criteria for what counts as a distinctive mechanism are
  byte-identical between the two. This affects documentation-only repositories
  and `--docs-only` scans; a batch containing any code file is unchanged, and
  the run says which framing it used. **Whether this finds better mechanisms in
  prose has not been measured**, so treat it as a corrected mismatch rather than
  a quality improvement until it has.
- **`--docs-only`**: scan a repository's documentation and nothing else, even
  when it contains code. The scanner still defaults to reading code and still
  falls back to documentation on a repository that has none; this is the third
  case, forcing prose-only analysis of a codebase. The files it skipped are
  reported as `code_excluded` rather than dropped quietly, and passing it
  together with `--exclude-docs` is refused, because the two together ask for an
  empty scan. A `--docs-only` run sets `is_docs_only_repo`, so its findings
  arrive in `doc_concepts` like any documentation-only scan.
- **One-line install for macOS, Linux and Windows.** `install.sh` (run with
  `curl ... | sh`) and `install.ps1` (run with `irm ... | iex`) install the
  latest release for the current user, with no administrator rights: into
  `~/.local/bin`, or `%LOCALAPPDATA%\Programs\concept-scanner` on Windows. Each
  checks the download against the release's checksums, runs it once before it
  replaces anything, puts the folder on your PATH (a marked line in your shell's
  startup file, or your user PATH on Windows, written so `%VARIABLE%` entries
  keep working), and installs where `update` can later replace it. Rerunning
  either is the reinstall; `--uninstall` / `-Uninstall` removes exactly what it
  added and leaves each project's `data/` folder alone. The commands are in the
  README's Quick start.
- **The Windows binary is signed** with Microsoft Artifact Signing, so Windows
  shows the publisher and Smart App Control runs it. Every release signs it the
  moment it is built, so `checksums.txt` and its signature describe the signed
  file, and a release that cannot sign fails rather than ship it unsigned.
- **The macOS binaries are signed and notarized** (Developer ID), so a binary
  downloaded in a browser runs from Terminal without being blocked, after macOS
  checks its notarization with Apple online the first time. Signed at build
  time like the Windows binary, with the same rule: no unsigned release.
- **Scans can tell you a newer version exists, if you say yes.** After your
  first scan at a terminal you are asked once; it is off unless you agree. When
  on, a scan checks at most once a day, beside the scan and never delaying it,
  and prints one line at the end when a newer release exists. It never installs.
  When a check finds a newer release and its own scan never shows the line
  (the scan failed, or ended before GitHub answered), the next scan shows it
  without asking GitHub again, so a notice is not lost and the check still
  happens at most once a day. It is asked about, and runs, only when both the
  keyboard and the screen are a terminal: with the output sent to a file, the
  question would wait for an answer to a prompt nobody can see.
  `concept-scanner update --auto-check on|off` changes the setting without
  contacting anything. The setting lives in `~/.concept-scanner/settings.json`,
  never in a project folder, so a repository you scan cannot turn it on.
- **`concept-scanner update`**: checks GitHub for the latest release and, at a
  terminal, asks before installing it over the copy you ran. The check is one
  request to GitHub's public releases page, made when you run the command (and,
  only if you turn it on, at most once a day when a scan starts), and it sends
  nothing about you or your code. Nothing is replaced until the
  release's signature, the file's checksum and the new program's own version all
  check out; any failure leaves your copy exactly as it was. Without a terminal,
  or with `--json`, it checks and never installs. Inside the container image it
  points at `docker pull` instead.
- **Signed releases.** Each release now carries `checksums.txt.sig`, an Ed25519
  signature over `checksums.txt`, which is what `update` verifies.
- **`version --json`**, in the same `{data, next_steps, notice}` envelope as the
  other commands.

- **Redundancy now reports two more relations, both exact and model-free.**
  `restated` (two concepts in one file whose names resolve to an identical set of
  that file's own identifiers) and `anchor_subsumed` (one name's set strictly
  inside the other's). These see the case the previous two relations could not:
  the same mechanism described in genuinely different words. Neither drops
  anything, and the report publishes what it declined to judge as a count rather
  than implying there was nothing. Sidecar schema 1.0.0 to 1.1.0.
- **A new `name-attenuation` disclosure** names concepts whose summary states a
  constraint their name discards, since the name is what deduplication keys on
  and what a reader scans. It renames nothing. Sidecar schema 1.0.0.

Each names the population it describes: both are computed before triage and the
ungrounded gate, so a concept they count can still be dropped before the scan
ends (measured at 6 of 17 stored scans, 42 concepts). A reader who needs the
shipped count reads `code_concepts`.

Both are written beside a scan like the existing grounding disclosure and are
**not part of the emitted contract**: `Concept` stays at 1.9.0, `Bridge` at
1.1.0, and these two do not change the `ScanResult` envelope. It does move in
this release, to 1.3.0, for two other fields: `unreadable_match_responses` and
`salvage_dropped`, both below.

- **Every scan's `notice` now ends with a run caveat**: how many files the model
  actually saw and how many it never did, how many concepts the run reports and
  holds back, how many cited a file that could not be found, and how many
  generations were thrown away on an output cap. The human-readable summary
  prints the same sentence as its `Coverage:` line. A clean scan's notice used to
  be empty; it now always says what the run covered.
- **`salvage_dropped`** in the `--json` scan output (envelope 1.3.0). When a
  model's discovery answer is a malformed list, the scanner keeps the items it
  can read and drops the rest; this field now counts what it dropped, by reason,
  so a model that produced many findings in an awkward shape no longer looks like
  a model that found few. It was counted before, but only in a log line. It
  counts discovery only, where a dropped item is a finding the output is missing;
  with `--multi-model` it counts the empty entries dropped from the answer.

### Note on the first release with `update`

It can only update to releases published after it, because those are the first
ones signed. So the release that introduces `update` is the last one you
download by hand.

- **`models.json` records what the model server ran the scan with** (1.1.0,
  `server`): the server's version, each model's weights file, engine (gguf on
  llama.cpp or MLX), its own generation defaults with the ones this tool never
  sends listed apart, its capabilities and thinking values, and every runner
  that could have served the scan with its slots, flash attention and batch
  size, read from the local server's log, plus the models the server held
  loaded when the scan began (`resident_at_start`), which decides whether a
  runner started earlier served it. A log that belongs to another server
  (another port), or that was not written to since the scan began, is refused
  rather than read, and a restart during the scan is stated. The run's `calls.jsonl` now records each call's output tokens, the
  server's load, prompt and generation time, how many prompt tokens came from
  its cache, and the length of any thinking.
- **`review <scan-id> --why <concept>`** says why one concept was held back:
  the gate, what it measured, who the verdict points at and, when a number
  decided it, where that number came from and what would replace it.
  `scan --verbose` prints the same for every refused concept at the end.
- **A per-model `think` setting**: a `"think"` section in `data/config.json`,
  `{"<model>": false | true | "<level>"}`. Nothing is sent by default, so every
  model keeps its own behaviour; a value the server says a model does not
  accept stops a scan before its first call.
- `CS_PENALTIES_OFF=1` sends every sampler penalty switched off, for
  measurement only.

### Changed

- Both parallel-batches pickers said "higher is faster; lower uses less
  memory", and the code said Ollama serves four requests at once by default.
  It serves one (`OLLAMA_NUM_PARALLEL` defaults to 1): on a default server the
  extra requests wait their turn, and a server with more slots holds their
  memory from the moment it loads the model. The pickers and the README now say
  so, including that on a server with several slots a scan is not
  byte-reproducible unless run with `--parallel-batches 1`.
- `bench` now loads the model with the context window a scan uses, so it
  measures a runner a scan would use.
- **How many files share one discovery call is now worked out from your
  repository's file sizes, and printed.** It was a fixed cap of 4. The scan now
  aims at an average of 2 files per call, at most 4, choosing the depth that
  gets nearest that average without going over it, and prints one line saying
  what it chose and from what, for example (`Depth: at most 2 files per call (target 2.0 on
  average, ceiling 4), from 103 files (median 8.4 KB, p90 35.4 KB, largest 69.1
  KB): 55 batches, 19 more than the ceiling alone would make`). A repository of
  small files therefore makes more, smaller calls than before; each added call
  costs about the model's fixed per-call overhead. Discovery's own time
  estimate reflects the new depth once its first calls finish; nothing prices
  it before discovery starts yet. It is a coverage setting: a file that produced nothing
  when it shared a call measured to produce concepts on its own, and nothing
  about what counts as a concept changed. Tier sweeps
  record the target beside the ceiling, and `tiers report` says arms batched
  before and after this change are not comparable.
- **`--include-tests` now also reads test-named files** such as `foo_test.go`
  or `bar.test.ts`. It used to admit test DIRECTORIES only, which was half of
  what its help said. It is now the older spelling of `--tests source`, and is
  refused beside a different `--tests` value rather than one silently winning.
  **It also costs more than it did:** like `--tests source`, it asks the model
  what each concept's paired tests assert, one extra call per concept that has
  paired tests. No mode reads tests as a source without that step; leaving the
  flag out keeps tests out of discovery and still pairs them, with no model
  call.
- **`update` says what actually went wrong.** It finds a folder it cannot write
  before downloading anything, and its remedy is now the install script, which
  installs where you own the folder. A rate limit from GitHub is named as one,
  with the time it resets, rather than read as an outage. A download of the
  wrong size (a proxy's or captive portal's own page, or a dropped connection)
  is reported as a network problem, not as a release that may have been tampered
  with. On Windows, replacing the program retries for a moment while antivirus
  holds the new file open.
- **A failure caused by the model or the model server now exits with code 3**,
  not 1: the model server is not running or is stuck, a model is missing or will
  not download, a remote endpoint does not have the model you named, a model call
  failed, or a pass failed because every call it made did. Mistakes in flags,
  paths and configuration still exit 1. This is the exit code the shared CLI
  convention reserves for provider and model errors, so a script can tell "fix
  the command" from "the model server needs attention" without reading the
  message. If you test for exit code 1 specifically, test for non-zero instead,
  or for 3. `status --wait` passes a scan's 3 through.
- **Nothing asks a question when nobody can answer it.** A scan, `init`,
  `update`, `bench --write-config` and `review` no longer wait for an answer when
  a coding agent or CI runs them, or when `TERM` is `dumb`, even if they appear
  to have a terminal (some agents run commands in one). A scan uses your saved
  profile or the defaults and says so; the others say what to run instead.
  `review` still takes answers piped to it. A scan with `--json` or
  `--progress jsonl` asks nothing either: its first-run questions used to print
  into the JSON output.
- **Ctrl+C during a scan** now records the run as cancelled in its status file
  before the scan stops; it still ends the scan at once, exactly as before, and
  partial results are still not kept.
- **The model picker runs before a remote repository is cloned**, so every
  question comes before the long part of the scan.
- **Discovery's progress lines** (`[01:18] 2/2 (100.0%) | 7 concepts`) are
  replaced by the status line on a terminal and by stage lines elsewhere.

### Fixed

- The triage warm-up, the `--tests evidence` warm-up and both arms of
  `anchoring-check` sent no context window, so the server loaded the model at
  its own default: each warm-up then cost a reload when the first real call
  arrived, and `anchoring-check` could read a long file cut short without a
  word. Each now sends the window its calls use.
- A JSON repair written by the Pass 2 model was logged in the cost log as Pass 2
  validation.
- **`bridges` named the wrong directory when `DATA_DIR` was set.** Its "Saved to"
  line printed a fixed `data/scans/local-dev/...` path; it now prints the
  directory the bridges were written to.
- **Four disclosures went silent exactly when they had something to say.** The
  grounding, redundancy, name-attenuation and screen lines printed only when
  they found something, so a clean result looked like a check that never ran,
  and redundancy hid the names it could not compare and the overlapping pairs
  it did not judge. Each now prints whenever its check ran, with all its counts
  and the file and directory it wrote, and one next step lists every disclosure
  written beside the scan. The lines also appear in the GitHub Actions step
  summary. `tiers run`, `tiers report` and `distill gate` gained long help.

- **Go license analysis failed unless the `go` command on your PATH was the one
  that built this binary.** It recognised the standard library by comparing file
  paths with the build machine's Go installation, so on another machine every
  standard package looked like a dependency without module information and the
  analysis stopped with "some errors occurred when loading direct and transitive
  dependency packages". The standard library is now recognised by import path.
  License analysis still needs the `go` command, which the container image does
  not include.
- **Synthesis scored a lone pattern with default values.** When synthesis found
  exactly one candidate pattern, the model's scores arrived as a single object
  rather than a list and were discarded, so 40% of that pattern's score came
  from defaults (the run logged an error saying so). The answer is now read.
- **The license summary said "passed" when the analysis failed.** If a
  manifest could not be analyzed, for example because the project's
  dependencies could not be loaded, the scan reported "License check passed: 0
  dependencies analyzed". It now says the check is incomplete and points at
  `dependency_map.errors`.
- **A location without line numbers showed as `file:0-0`.** Scan output,
  `review` and the summary now show just the file when the model cited no
  lines.
- **License risks no longer flag a Go repository's own packages.** License
  analysis listed every package it loaded as a dependency, the scanned
  repository's own included, so a finding in a file that imported one of the
  repository's own packages could carry a "no license data" warning about the
  repository's own code. Its own packages are now left out. Three smaller
  corrections in the same place: a JavaScript dependency named in
  `package.json` but missing from the lockfile now reads as having no license
  data, instead of carrying an empty risk with an empty explanation; a license
  expression joining a known license AND one the scanner does not recognise now
  reads as unknown, where `MIT AND <unrecognised>` used to read as no risk; and
  with `--allow-external-symlinks`, reading a finding's file for its imports no
  longer follows a symlink out of the repository.
- **`--docs-only` scans shipped findings the scan said it had held back.** The
  quality gates filtered one list while `doc_concepts`, the list a docs-only scan
  is read from, kept everything, including a finding citing a file that does not
  exist. Separately, a document that mentioned a source file could have a finding
  typed as code, which hid the documents from `review`, `submit` and synthesis.
  Every finding on a `--docs-only` scan is now treated as coming from the
  documentation, whatever any later step labels it, and `doc_concepts` carries
  only what passed the quality checks. On a `--docs-only` scan that now includes
  the textbook classification, so a documented routine pattern is held back like
  a routine one in code; on a repository that has no code at all, which is
  detected rather than declared, documentation is all the context there is and
  the textbook classification is still not applied. A `--docs-only` run reports
  `is_docs_only_repo` even when every finding was held back.
- **`refusals` counted findings held back as insubstantial without showing
  them.** It now shows them, and shows a row whose verdict it does not recognise
  instead of dropping it. A `reviewed_verdict` other than `right` or `wrong`
  (letter case and spaces aside) is counted in `--json`, named in the notice, and
  given a next step, since a review this tool cannot read is counted nowhere.
- **`tiers run --ollama-host` checked the server you named and then scanned with
  the default one.** Every arm now uses the host you give. Arms recorded before
  this compare as having used the default, which is what they did.
- **`tiers report` flagged every fresh sweep as not comparable** because of its
  own baseline row.
- **`distill gate` could promote a model none of whose answers could be read.**
  It counted any non-empty answer as usable; it now reads each answer with the
  same parser and the same acceptance rules its pipeline stage applies.
  Duplicate captures of one request are chosen the same way on both sides, the
  first usable one.
- **`distill gate` could score a timeout as the other model's win.** A capture
  that failed for a reason outside the model, such as a timeout or a
  cancellation, counted as a broken answer, so an interrupted earlier run in one
  capture file could decide the verdict. Such a pair is now excluded and
  counted. A pair where only one side's prompt was cut to fit its context window
  is excluded the same way, since the two answers read different inputs. When
  either reason removes more than a tenth of one side's requests, the gate
  returns no verdict, because the requests left to judge were chosen by those
  failures. The `--json` report carries both counts, and the split, pair,
  unpaired and duplicate counts it prints.
- **`distill gate` could be pointed at a prepared corpus and an unprepared one**,
  which filtered the unprepared side to nothing and blamed the capture. It now
  refuses the mix and says why. Warm-up calls recorded in older capture files
  are dropped when the file is read; they are not captured any more.
- **`distill prepare` could put a two-phase extract and the analysis it embeds in
  different splits**, so held-out results could include text the model had
  trained on. Related examples now share a split, and the command prints the
  achieved proportions beside the requested ones. A request's split never depends
  on what a model answered; captures appended across several scans are accepted;
  an example related to requests in different splits is written to none; and a
  short answer found in a prompt in another split is reported. **Re-prepare
  captures prepared before this release before comparing results across it.**
- **`distill prepare` names its output after its input**, and this changes the
  file names: `capture.jsonl` now prepares into `capture.train.jsonl`,
  `capture.valid.jsonl` and `capture.test.jsonl`, beside a `capture.prepare.json`
  that records the source file and the fractions. Preparing two captures into one
  directory used to leave only the second one's splits, silently. A capture
  whose prompt was cut to fit the context window is written to no split, and the
  run counts the examples that carry no such check at all. **Scripts that read
  `train.jsonl` or `test.jsonl` need the new names.**
- **`distill frontload` could report a batch as front-loaded when every file in it
  was cited**, and measured from the start of the prompt rather than from the
  first file. It also now leaves out a batch whose prompt did not fit the model's
  context window, using a check each capture records, says how many batches were
  captured without that check, and no longer mixes two-phase analysis calls,
  which have a different output budget, into the figure.
- **Semantic batching sent its instructions as the user message and the list of
  files as the system message.** They are now the right way round, which also
  keeps file names from the scanned repository out of the system role. Batches
  may group files differently than before.
- **The cost log recorded the last attempt of every truncation give-up twice**,
  overstating the tokens and time a run discarded. Logs written before this
  release keep the duplicate.
- **A repository you scan can no longer change how the scanner runs.** The
  scanner reads a `.env.local` file from the directory it is started in, which is
  a convenience for local development and was a problem everywhere else: in the
  container image and in the GitHub Action that directory is the repository being
  scanned, so a file committed to someone else's repository could set any
  variable in the scanning process, including where results are written and which
  model your API key pays for. Two changes. Only the scanner's own settings and
  the documented key names are applied now, and anything else in the file is
  ignored with a count of what was skipped. And the file is not read at all in the
  container or the Action, where the run says it was ignored and why. Local
  development is unchanged, and a real environment variable still wins over the
  file. See PROVIDERS.md.
- **Product-level synthesis ran with no limit on how much it could read.** Every
  other stage tells the model how large a context it may use; this one did not, so
  a local model fell back to its own default window and could silently drop part
  of the input, which for this stage includes your architecture and decision
  documents. It now sets the same limit as every other stage. The output size is
  also configurable for the first time, with `--budget-pass5` or
  `CS_BUDGET_PASS5`; the default matches the previous fixed value, so nothing
  changes unless you set it.
- **Held-back findings could not be told apart in the review list.** Every
  finding the scanner held back as textbook was recorded against the same
  identifier, so the list showed three rows that looked like the same item. Rows
  now carry the finding's name where a permanent identifier does not exist yet.
- **An interrupted scan no longer reads back as a complete one.** If a scan was
  killed partway through writing its results, later commands loaded whatever
  files existed and reported nothing unusual. They now compare what loaded
  against what the scan recorded and tell you how many results are missing, so an
  incomplete scan is visible rather than quietly smaller.
- **Documentation was never actually being linked to code.** The step that finds
  which of your design documents explain a given piece of code was discarding
  every answer it got. The model was replying correctly; the reply was in a
  slightly different shape than the code insisted on, so it was thrown away and
  the run reported "no documentation matched" as though that were a finding about
  your repository. Measured on two real runs: 16 answers received, 16 discarded,
  several of them strong matches. Because enriched summaries are only written for
  code that HAS matching documentation, this also meant no enriched summaries
  were being produced at all. Scans of repositories that contain both code and
  documentation will now produce the doc links and enriched summaries they were
  supposed to. A scan output that genuinely has no relevant documentation looks
  the same as before; the difference is that a scan which could not READ the
  answers now says so, as `unreadable_match_responses`, instead of reporting zero
  matches and leaving you to assume your docs are unrelated to your code.
- **A repository whose findings were all filtered could describe itself as
  documentation-only.** If every mechanism the scanner found in your code was
  judged textbook and held back, the run concluded there was no code at all, and
  the output then presented your documentation's claims as the scan's product.
  Documentation describes what something is meant to do, which is not the same
  kind of result, so this was the wrong thing to hand a reader. The run now
  refuses that conclusion when it is holding code findings back, and says so,
  pointing at `--include-textbook` if you want to see them. Such a run now ships
  no findings, rather than letting the documentation's claims reach a reader
  through the older `concepts` array.
- **A response that quoted a code block could lose a whole batch.** If the model
  put a fenced code snippet inside one of its answers, which is an ordinary thing
  to do when the thing being described is code, the output was misread as a
  markdown document, truncated, and then reported as unreadable. The batch was
  retried through a repair step that had nothing to repair. This became much more
  likely with documentation scanning, since design documents routinely contain
  fenced code. Responses are now read as-is first and only cleaned up if that
  fails.
- **Ctrl-C was treated as a temporary network problem.** Interrupting a scan
  against a local model left it retrying, with waits between attempts, before it
  gave up. It now stops. A genuinely slow server is still retried, which is what
  those retries are for.
- **Seven discovery and classification prompts told the model to return a JSON
  array while the wire format enforced a JSON object.** Every schema this tool
  sends has an object at its root, and on a remote provider that shape is
  enforced, so the prompt was asking for something the model was not allowed to
  produce. The prompts now ask for `{"concepts": [...]}` and
  `{"candidates": [...]}`, matching the bridge and extract prompts, which were
  already correct. Nothing about the output shape changed: the parser accepted
  both forms before and still does, so this removes a contradiction rather than
  altering what a scan emits. **Whether it changes what discovery finds has not
  been measured**, so treat it as a corrected mismatch and not as a quality
  improvement. The guard that exists to catch exactly this could not see any of
  the seven, for two reasons: it read only the user half of each call, and the
  rules live in the system half; and its object test matched the phrase anywhere,
  so a per-item "return one JSON object" cancelled the prompt's own top-level
  "Return ONLY a JSON array". It now checks both halves, distinguishes a
  top-level instruction from a per-item one, and derives the list of prompts to
  check from the source rather than from a list someone has to remember to
  extend. Two prompts that never stated their shape at all now do.
- **A documentation-only scan could offer an importer one concept out of
  fourteen.** Scanning with `--docs-only` produces findings about your
  documentation, and the scan tells a downstream importer which of its output
  lists to read. That signal was being decided by something else: because design
  documents mention source files, some findings were labelled as coming from
  code, which flipped the signal and pointed an importer at a list built from
  those few instead of at the documentation findings. One measured run produced
  14 findings and offered one. Every list was well-formed and the scan reported
  success, so there was nothing to notice. `--docs-only` now settles the signal
  itself rather than inferring it.
- **The README described a per-concept avenue tag that is not emitted.** It
  said each concept is tagged with the discovery avenue that found it (`size`,
  `semantic`, or `both`). No such field exists or has ever existed, so anything
  built on it would have found nothing. The text now says so explicitly: a
  merged concept does not record which avenue found it and the output cannot be
  filtered or grouped by avenue, while the run's progress output still reports
  how many concepts each avenue contributed. The wrong sentence was published in
  v1.0.6 and v1.1.0.
- **A scan could report dropping a concept and still ship it.** A concept whose
  cited file could not be found is dropped from the results, and the count of
  those was reported correctly, but one of the arrays a scan emits still
  contained them. That array is the one used when enrichment is turned off, so
  an importer could store a concept pointing at a file that does not exist. A
  related case was fixed on 2026-09-29 for concepts held back by the score gate;
  this is the same problem for the last check to run, which happens after the
  others and was missed. A test now reads the finished output rather than each
  check in isolation.
- **A batch that truncated twice was lost instead of being split.** When a
  discovery call exceeds its output budget the scanner raises the budget and
  retries, and if it still does not fit, it splits the batch and retries the
  halves. The second step stopped working when the backends began returning a
  typed truncation error: the check that decides "was this a size failure" was
  still looking for older wording, so it matched nothing and the batch was
  dropped with no error. Affected both the local and remote backends. The check
  now uses the error's type, and a test drives the real backends so a future
  wording change cannot disable it silently.
- **A refusal from a remote endpoint was reported as a malformed answer.** An
  endpoint that accepts a request and generates nothing, which is what a content
  filter does, returned success with an empty result. The scanner then tried to
  repair the empty answer as if it were broken JSON, spending a second call, and
  failed with a message about unparseable output. It now fails immediately with
  the endpoint's own finish reason in the message, and does not retry, because
  the same prompt gets the same answer. The local backend gets the same check.
  See TROUBLESHOOTING.md.
- Both new disclosures were first computed before the quality gates, so they
  described a larger population than the scan actually ships. They now run
  against the shipped array.
- A pair the redundancy relations had judged could also be counted in the
  "declined to judge" total, overstating that number.
- The name-attenuation summary line could not distinguish "every constraint
  reached its name" from "nothing stated a constraint at all". It now says which.
- The disclosure named matched word STEMS rather than the words a summary
  actually uses, so it printed fragments that could not be searched for.

- **The scan reported prompts as cut that the model had read in full, and missed
  most that were cut.** Measured against Ollama: a prompt longer than the context
  window is cut to exactly half the window, and a prompt within it is read whole,
  whatever the output budget. The check now looks for that, and applies a model's
  own smaller window when Ollama uses it in place of the one requested. Text in
  other scripts, or with long runs of spaces or separator lines, is no longer
  reported as cut because this tool's size estimate runs high on it. On a remote
  provider, whose endpoint applies a window this tool cannot see, the scan now
  says the check did not run instead of saying nothing.
- **A classification answer could fail a whole scan.** Under the default strict
  validation, an answer that split the finding it was asked about into two,
  renamed it, or left its title empty was treated as missing, and a missing
  classification fails the scan. The classification now lands on the finding it
  was asked about, and an answer that classifies nothing is asked again.
- **On a remote provider, a raised output budget could exceed the model's
  context window**, and the endpoint's rejection lost the batch. The budget is now
  capped by the window this tool knows for a listed model, a rejection for
  length splits the batch instead, and the size of a truncated prompt is taken
  from the server's own count when it gives one.
- **`--synthesize` could ship no patterns at all** when the model's answer about
  combinations could not be read. The patterns built from a single central
  mechanism never depended on that answer and are now kept, and an empty answer
  is read as naming no combinations.
- **`--multi-model` could crash on an empty entry** in the model's answer. The
  entry is dropped and counted in `salvage_dropped`.
- **`enrichment_stats` described the findings before the quality checks.** It now
  describes what the scan ships, so `orphaned_docs` counts documentation that no
  shipped finding matches. `characterization_incomplete` is always present and is
  counted after the last check.
- **`distill frontload` missed citations written as `./a.go` or as an absolute
  path**, which read a batch citing its own last file as one that ignored the
  back of its input, and it counted two models' answers to one batch as one. Its
  report is now ordered and carries a schema version.

- **Semantic batching described a Go repository differently on every run.**
  Avenue B groups files using go-pbd's analysis of the repository, and that
  analysis broke ties between same-named code by which of its parallel workers
  finished first, and linked any two functions of the same name to each other,
  every `init` included. Three analyses of one repository gave three different
  descriptions to the model that suggests the batches. go-pbd 0.7.0 fixes both,
  and this release uses it: the same tree is now described the same way every
  time, with fewer false links. Avenue B will group Go repositories differently
  than earlier releases did.
- **Semantic batching links only code that can depend on each other.** go-pbd
  0.8.0 builds a Go repository's links from type information, so links to
  another package's private names, which Go does not allow, and links made from
  words in comments and strings are gone. On this project's own source that is
  60% fewer links between files, and the request to the model that suggests
  batches is about half its former size; Python projects lose a smaller share.
  Builds from source that include TypeScript and Python analysis (the released
  binaries do not) now see a TypeScript project's links for the first time.
  When that request is too large for the model's context window it is now
  split rather than sent whole, because the server cuts a request that does not
  fit and the model then suggests batches from part of the project. Measured on
  a 773-file TypeScript project, the suggested batches cover 202 files instead
  of 54. Building from source now needs Go 1.25.7 or later.
- **Semantic batching reads Python and TypeScript projects more accurately in
  source builds.** go-pbd 0.9.0 resolves Python names by Python's own scoping
  and imports, and links a TypeScript import only to what the code actually
  uses, so links made from local variables, method calls on lists and
  strings, and unused imports are gone. On one Python project that removed a
  third of the links between files. Go projects are unaffected, and the
  released binaries skip semantic batching for Python and TypeScript.

### Security

- **Updated `golang.org/x/mod` from v0.37.0 to v0.41.0**, past two advisories in
  its checksum-database code (GO-2026-6180 and GO-2026-6179, fixed in v0.40.0).
  concept-scanner never called the affected code, so no scan was exposed; the
  update clears them from the dependency graph. It also moves
  `golang.org/x/tools`, which license analysis uses to load a repository's
  packages, from v0.47.0 to v0.49.0; license analysis gives byte-identical
  results on a real dependency graph before and after.

- **Repository and model text can no longer issue GitHub Actions workflow
  commands.** In a GitHub Actions job every line the program prints, from any
  command, passes one filter before the runner reads it. A line the runner could
  read as a command (one that starts with `::` after any whitespace, including
  after a carriage return inside the line) is wrapped so the runner does not act
  on it, and `##[`, which the runner's older parser acts on anywhere in a line,
  is written as `#\u0023[`: the same value inside JSON, so `--json` and
  `--progress jsonl` output stay valid and decode to the same text. Annotation
  text and group titles are escaped. A run's coverage caveat is added as a
  warning annotation.

- **Removed an unmaintained git library with known vulnerabilities.** License
  analysis used a third-party module that linked an unmaintained git library and
  an unsafe OpenPGP package, reported by govulncheck with no fixed version. It is
  replaced by a small loader built on modules this tool already used, with the
  same results on the dependencies it was checked against. The binary is about a
  third smaller.
- **Text from a scanned repository or a model could control your terminal.**
  Concept names and summaries, file paths, error messages and the names of
  variables a repository's `.env.local` tried to set were printed exactly as
  they arrived, so a repository could carry characters that a terminal acts on
  instead of displaying: changing the window title, clearing the screen,
  writing the clipboard, or making a link whose text and target differ. A file
  name or a `.env.local` line was enough, with no model involved. Everything
  printed for a person now shows such characters as visible symbols (an escape
  character prints as `␛`), so you can see that something was there. JSON
  output and saved results are unchanged: they keep the text as it arrived,
  with control characters escaped by JSON.
- **Built with a supported Go and a supported base image again.** Release
  binaries and the container image were built with Go 1.25, which stopped
  receiving security fixes on 2026-08-19, and the image (which the GitHub Action
  runs in) was based on Alpine 3.20, unsupported since 2026-04-01. They are now
  built with the newest Go 1.27 patch on Alpine 3.24. The release binaries had
  no known vulnerability from the old Go at the time of the change, because each
  release took the newest 1.25 patch; builds from source were different, since
  an older installed Go downloaded exactly the 1.25.7 named in `go.mod`, and
  that version has known standard-library vulnerabilities this program can
  reach. **Two consequences:** building from source now needs Go 1.27 or later
  (an older Go fetches 1.27.1 by itself under the default `GOTOOLCHAIN=auto`),
  and the macOS binaries now need macOS 13 Ventura or later.
- **A model-supplied file path could escape the scanned workspace at two read
  sinks.** Concept locations come from the model, and a location that cannot be
  resolved is deliberately left as emitted so triage can look at it. Two checks
  that read a concept's cited file (the description-grounding check, and a
  redundancy check added in this release) joined that path onto the workspace
  without the containment guard the rest of the codebase applies, so a path
  containing `../` could cause a file outside the scanned tree to be read. Both
  now use the existing symlink-resolving containment check, and a refused path is
  reported as unexamined rather than as a pass.

  Scope, stated plainly: reading a file outside the tree you pointed the tool at.
  When a remote provider is configured, file contents are sent to that provider,
  so the practical exposure is a local file being read and transmitted. There is
  no remote-triggered path here: the model has to emit the location, and the model
  is only reading code you gave it.

  A build-time guard now **discovers** every use of the bounded file reader and
  fails the build unless the containment check is present in the same function or
  an explicit exemption records why the path cannot come from the model. It fails
  in both directions, so an exemption cannot outlive the code it excused.

## [1.1.0] - 2026-09-29

**The first release since the source repository's distribution split, and a
measurement release rather than a feature one.** Every headline number this tool
had published about its own recall was re-derived, and several were wrong. The
output contract is unchanged: `Concept` stays at 1.9.0, `Bridge` at 1.1.0, and the
`ScanResult` envelope at 1.1.0.

**Why a minor rather than a patch.** No schema changed, but a gate defect meant the
array the producer contract makes authoritative was never filtered: a full-repository
scan shipped 251 concepts where it now ships 174. Consumers see materially different
output from the same envelope version, which is more than a patch should do.

### Measured

- **A scan is EXACTLY reproducible within one machine state: six runs, sd 0,
  agreement 1.00.** Five consecutive runs of the 18-file corpus on
  `qwen3-coder:30b` at `--parallel-batches 1`, plus a sixth an hour earlier on the
  same binary, produced **identical output on every measure**: Pass 1 = 44 every
  run, score gate held 26 every run, **18 shipped every run**, name / cited-file /
  file-plus-name agreement **1.00 across all 10 pairs**, 0 of 18 names
  run-dependent, all 10 cited files yielding identically, and **no distinctiveness
  score moving**. The only quantity that varied was wall clock (25.4 to 32.6
  minutes; run 1 paid the model load).

  **This falsified its own pre-registered prediction**, which said the runs would
  not agree and put name agreement at 0.70 to 0.95, on the theory that
  mixture-of-experts routing plus server-side batching breaks greedy determinism.
  The server runs `-np 1`, one slot and one request at a time, so there is no
  cross-request batching to perturb the reduction order.

  **What this changes is which caveat a recall figure needs.** Not "n=1, needs an
  error bar", which is what this project has been writing, but **"measured on binary
  X at time T"**. Repeating a scan to average out noise inside one session is wasted
  GPU time; comparing figures across a binary change is the unsafe operation.

  **And the divergence that motivated the experiment was mostly a binary change,
  not noise.** Two runs 17 hours apart had been read as run-to-run variance while
  differing in binary (the gate fix landed between them), a caveat that was named at
  the time and then not applied. Read by PAIRS rather than by name-set, the real
  cross-state drift is about **3 mechanisms in 18**, not the 6 a name-based score
  reports: several differences are one mechanism relabeled (`Adaptive Budget
  Escalation on Truncation` against `Adaptive Truncation Budget Escalation`).
  **A count understates divergence and normalized names overstate it**, so neither
  is a trustworthy identity on its own.

  **Named candidate for the residual, evidenced but not proven:** KV-cache reuse.
  The server log records prompt length against tokens actually evaluated, and 398 of
  400 requests reuse cache, median 2,034 tokens, max 11,990, across **51 distinct
  reuse amounts**. Within a run each discovery call meets the same cached prefix,
  which is why a sequence reproduces; across a gap the residue differs. Server
  restart, worker respawn, batching, prompt, sampling options, model blob and input
  bytes (matching `input_hash` per file) are all excluded. **The pin removes the
  sampler; it does not remove the cache.** Falsifier recorded, not run.

  **Unmeasured:** everything here holds at `--parallel-batches 1`. The pin's
  sufficiency under fan-out is untested, and the code comment predicts it fails.

- **The "7 of 8" is retired; the defensible figure is the full-repository 5 of 8.**
  Re-running the 18-file corpus on a binary with the gate fix scores **2 of 8**.
  Discovery found the same 44 concepts both times, so nothing about the model
  changed: the gate removed 26 of 44, and recall fell from 7 to 2.

  That figure was wrong three independent ways at once. It was measured on a corpus
  **built from the answer key's own citations**, so every target was guaranteed
  present. It was measured **through a gate that was not filtering the array it was
  read from**, so 3 of its 7 key carriers scored **0.3** against a 0.5 floor. And it
  was **a lucky draw**: 2 more carriers scoring 0.7, well clear of the floor, were
  simply not produced on a re-run of the identical corpus.

  **The score floor filters real mechanisms.** Three of eight key mechanisms were
  carried only by 0.3-scoring concepts. It cost nothing on the 186-file repository,
  where the same mechanisms were found at 0.6 and 0.7 by different concepts, but the
  lower cluster is demonstrably not uniformly noise: it contains concepts naming
  mechanisms an independent method ranked 13, 11 and 10 of 13.

  **The model reversal is unaffected.** The 7b scored 1 of 8 on this corpus against
  the 30b's 7 (corrected 2); the ordering holds and only the margin was overstated,
  and the 30b's advantage was independently visible in the counterfactual mechanisms
  (3 of 4 against 0 of 4) and the empty-array rate (0.0% against 40%).

- **Full-repository recall: 5 of 8 against the manual concept corpus, and the
  earlier 7 of 8 was partly an artifact of how its corpus was built.** The 18-file
  corpus that scored 7 of 8 was constructed FROM the key's own citations, so every
  target mechanism was guaranteed present: it measured extraction given perfect
  selection. Over the whole 186-file repository with the same model and prompt,
  `qwen3-coder:30b` produced **251 concepts over 130 files (70% of the repository)
  in 2h04m**, scoring **5 outright, 1 partial, 2 missed**.

  **One mechanism was found on the small corpus and LOST on the full one**: the
  no-drop-authority classification gate, named precisely in the 18-file run and
  absent from all 251 concepts on the full repository. More context produced fewer
  of the specific things being looked for.

- **Recall against an external key: 1 outright, 5 partial, 2 missed.** A separate
  method had found 8 mechanisms in this repository; the scanner was pointed at
  the 18 files those entries cite. The partials share a shape worth stating
  plainly: **the scanner finds a mechanism's machinery and not its governing
  property.** It found the grounding steps and not the refusal rule, the
  validation pass and not that it has no authority to drop, the retry and not the
  taxonomy that selects it.

  **This is a selection limit, not a coverage limit.** Every cited file reached a
  prompt (0 dropped at batch) and 8 of 18 still produced nothing, including three
  files that ARE the mechanisms named. Reading more of a repository would not
  change it. **Why those eight produced nothing is now ANSWERED:** seven are the
  surplus files in multi-file batches. Yield is constant per CALL (2.60 concepts
  per single-file batch, 2.25 per multi-file) and collapses 3.8x per FILE (2.60 to
  0.69). A batch has an effective quota of about three concepts and every file
  beyond the first competes for it. **Not a budget cap:** the Discovery budget is
  8,192 tokens, the largest output was 964, and more input correlates with LESS
  output (Spearman -0.63). The model chooses to stop. This also unifies the
  2026-07-20 context-cap dilution, the batch-ordering sensitivity, and the
  front-loading negative result, which were being treated as three findings.

  **The falsifier then ran**, re-scanning each silent file alone: 8 concepts
  recovered, confirming the quota. But the recovery lands entirely on one side of
  a split, which is the more useful result.

- **The binding constraint is the MODEL, not the task, the batching, or the
  prompt.** Same 18-file corpus, same shipped prompt, same batching, changing only
  the primary model: `qwen2.5-coder:7b` scores **1 of 8** outright against the
  manual concept corpus and **0 of 4** on its counterfactual mechanisms;
  `qwen3-coder:30b` scores **7 of 8** and **3 of 4**, at 44 concepts against 22.

  It found "separates concept classification from filtering decisions, allowing
  textbook mechanisms to be recorded" (no drop authority), "a four-stage cascade
  for resolving concept locations with grounding states" (the resolution ladder),
  and both halves of the inference-error taxonomy. Under the SHIPPED prompt, with
  nothing else changed.

  **Changing the question achieved nothing**: counterfactual prompt criteria over
  the same corpus produced 22 concepts against 22, 7 of 8 against 7 of 8. The cost
  is 2.7x wall clock, ~104s per discovery call against ~38s, and
  `qwen3-coder:30b` runs LOCALLY: this is not an argument for a remote provider.

  **The fast tier's output should not be read as what the tool can find.**

- ~~**Half the mechanisms worth finding are things the code deliberately does NOT
  do, and the discovery prompt has no room for them.**~~ **SUPERSEDED the same day
  by the entry above.** The measurements stand; the conclusion drawn from them was
  wrong. Sorting the 8 manually
  found mechanisms by kind and scoring recall: **positive mechanisms 1.00,
  counterfactual mechanisms 0.25**. Counterfactual means a choice not taken, an
  absence, or an invariant: "NO drop authority", "keyed to recovery ACTIONS rather
  than error types", "an explicit REFUSAL to mint a verdict from an infrastructure
  failure".

  Corroborated per file: re-scanning each silent file ALONE yields **1.75 concepts
  for positive-mechanism files and 0.00 for all three counterfactual ones**,
  including a **2 KB** file that produces nothing as the only thing in the prompt.
  At 2 KB there is no context problem to blame.

  **This explains the whole investigation at once.** Skeleton compression yielded
  zero because a signature cannot express an absence. More context did not help
  because 2 KB alone still yields nothing. "Custom Retry Logic" is the honest
  answer to the question actually asked. Every remedy tried, partitioning,
  compression, co-location, agentic assembly, was a context-assembly fix for a
  question-shape problem.

  **Practical consequence:** a files-per-batch cap is worth shipping as COVERAGE
  (the default packs a median of 5 and a maximum of 16 files per batch on this
  repository, against the 2.0 the quota was measured at), and it recovers zero
  counterfactual mechanisms, which carry the key's four highest scores.

- **Context assembly is not the constraint, measured three ways.** The claim above
  that this is a selection limit was then tested rather than assumed. Three arms
  over the same 18 files: complete source, signature skeletons with doc comments,
  and signatures alone. Compressing the representation **raised** the number of
  mechanisms whose evidence fits inside one batch from 3 of 8 to 5 of 8 and
  **dropped yield from 22 concepts to zero** (both discovery calls returned an
  empty array, 9 output tokens, against 10,242 and 7,418 input tokens).

  A prediction registered before the run, that recall would track co-location,
  **failed in both directions**: a single-file mechanism that fits one batch was
  missed entirely, and two mechanisms split across batches scored partial.

  **The gap is abstraction level.** All 22 concepts name subsystems ("Custom Retry
  Logic", "Coverage Tracking", "Dynamic Schema Handling") where the key names
  mechanisms ("an inference-error taxonomy keyed to recovery ACTIONS"). No batching
  strategy closes that. The signature-only arm also showed the other edge of it:
  with no prose to read, the model reported nothing at all, and in the
  comments-kept arm three of five concepts came from the single most
  comment-dominated file in the corpus.

### Fixed

- **The quality gates did not gate the array the consumer reads.** `scan_finalize`
  aliased `result.Concepts` to `result.CodeConcepts`, then every gate rebound
  `Concepts` to a new slice while `CodeConcepts` kept pointing at the ungated
  original. One full-repository scan reported `low_score_held: 80` and shipped all
  80 in `code_concepts`, which the producer contract makes **authoritative on a
  `--no-enrich` scan** and from which `enriched_concepts` is built 1:1.

  Verified by re-running the same repository with the fix: `code_concepts` 251 to
  **174**, below-floor concepts **80 to 0**, and `concepts`/`code_concepts` now
  agree in length where they were 251 against 171. **Recall against the manual
  corpus held at 5 of 8** while shipping 77 fewer concepts, so the gate removed
  volume rather than signal.

  The first attempt at the fix broke the contract's load-bearing 1:1 invariant,
  because Pass 4 sizes `enriched_concepts` from `CodeConcepts` and runs BEFORE the
  gates. Caught by a test written to prove it before fixing it. The scan that
  exposed the original defect could not have shown that break: it logged "skipping
  Pass 4 doc enrichment", so the enriched array was empty and the invariant was
  vacuously satisfied.

  **Consequence for earlier figures here:** the 18-file "7 of 8" rested partly on
  concepts that should not have shipped. Three of its seven key-carrying concepts
  scored below the floor, and 23 of that run's 44 concepts did. That number was
  inflated twice over, by a corpus built from the answer key and by a gate that was
  not gating.

- **The output budget was inert against a local Ollama `/v1` endpoint, and the
  reply looked clean.** Measured: asking for a ceiling of 16 tokens returned
  **534**, with `finish_reason: "stop"` rather than `"length"`. That endpoint
  honors only the legacy `max_tokens` field and silently ignores the modern
  `max_completion_tokens`, which was the only one this tool sent for a model
  whose name did not begin `mlx:`.

  `PROVIDERS.md` lists exactly that endpoint, so a user following our own
  documentation got a pipeline where every per-pass budget did nothing, no
  truncation error could fire, and the escalation ladder never engaged. The
  adapter now sends both fields and drops the legacy one only after an endpoint
  has actually rejected it. A reply materially longer than its requested ceiling
  is reported as a transport fault rather than as a long answer.

- **A model-stated line range is now bounded by the file it names.** Nothing had
  ever checked one. Measured over this repository's 2,396 stored concepts: 84
  carry a range, and 3 of the 38 resolvable against the current tree fall outside
  their file, including an end line of 186,115 in a 571-line file.

  This matters because `git blame` does not fail on an impossible range: it exits
  0 and returns the whole file, so such a concept was attributed to everyone who
  ever touched it. A range outside its file is now removed and counted, and the
  file-granular location survives.

- **A concept must now say something.** The only check on the single-model path
  was a non-empty title, inside the salvage branch, so a concept named `"The"`
  shipped. The floors that catch it already existed in this repository and were
  applied only to the multi-model path. Blast radius measured before installing:
  0 of 2,396 stored concepts would be refused.

- **A salvage pass now counts what it could not recover**, decomposed by reason.
  It previously dropped unusable items in silence, so a model that emitted
  sixteen concepts in an awkward shape and a model that found two printed
  identically, which is a confound in every concept count this tool publishes.

### Added

- **A null baseline in every tier sweep, which shows three benchmark columns can
  be maxed out by a template that describes nothing.** "Every exported symbol is
  a concept" contacts no model, runs in 0.002 seconds, and emits summaries like
  *"The func `mergeDiscoveryResults` declared in discovery_merge.go."*

  It scores 9.83 concepts per file and 94% description-grounded, against a real
  scan's 0.67 and 100%. Those are not wins: description grounding asks whether
  the symbols a description names appear in the cited file, and the baseline's
  description names one symbol read out of that file's own syntax tree, so it
  passes by construction. Yield is a count of exported symbols. Line ranges are
  computed rather than stated.

  **The baseline scores NOTHING on `technical_approach` or distinctiveness**, and
  declines rather than zeroing. Those are the columns where a model is doing work
  a template cannot do, and they are the only ones a quality claim can rest on.
  Yield, grounding, line-range correctness and wall clock are hygiene: they catch
  a broken run and cannot separate a good one from a template.

- **The judge calibration now has a control for more than one verdict.** It
  compared each answer against a copy of itself, whose only correct answer is a
  tie, and gated on the tie rate, so a judge returning `TIE` to everything scored
  a perfect 1.00 over sixteen prompts it never read. A second control now judges
  each answer against a copy whose identifiers are absent from the source, where
  the intact copy must win. Neither control alone refuses every degenerate judge.

- **An input-side truncation check at the inference seam.** The server reports
  how many prompt tokens it actually evaluated, and that figure had only ever
  reached cost accounting. It is now compared against the context bound the call
  applied, so a prompt cut before the model read it stops being silent.

- **`concept-scanner distill frontload`**: does the output budget decide WHICH
  files in a batch get concepts? Reads captures already on disk and reports where
  cited files sit within each batch. No model is contacted.

### Changed

- **Two guards now discover their own scope instead of reading a list.** The
  provider decorator-parity guard was tested by removing a decorator from one
  construction site, and it passed: it matched three wrapper names in a
  hand-written switch. The threshold registry's file list had the same shape, and
  discovery surfaced **27 unseen files holding 30 policy numbers**, including
  four engineering-axis weights and two context reserves. Both now fail in either
  direction.

- **`concept-scanner bench`: does your model server actually run requests in
  parallel?** Sends one request, then N at once, and compares throughput.
  Reports `parallel`, `partial` or `serialized` with the per-request latencies,
  and refuses a verdict when its two independent signals disagree.

  This matters because `--parallel-batches` multiplies every pass. **On a server
  that queues requests, raising it makes scans slower, not faster**: each
  request waits longer and moves closer to its deadline, so the failure mode
  looks like a slow model. On the machine this was developed against the verdict
  is `serialized` at 0.98x, which explains a previously-unexplained nine-hour
  run. Run it before trusting a concurrency setting on any machine.

- **`concept-scanner refusals <scan-id>`: what the quality gates held back, and
  who each verdict points at.** Concepts that do not ship are now recoverable
  and reviewable instead of being reported as a bare count. The verdicts are
  never totalled: a model citing a file that does not exist, a runtime call that
  failed, and a threshold somebody chose need different responses.

- **Preflight over the model server.** A scan now refuses to start when a model
  is held past its own expiry, which is what an orphaned client leaves behind.
  Without it, every following request queues behind the hold and times out, and
  environment failures render exactly like model results.

- **A disclosure for repository text aimed at a model.** Scanned repositories
  are read for spans that read as instructions to a machine, and for characters
  invisible in an editor. **This is a disclosure and never a filter**: the scan
  reads every byte it would have read anyway, because a screen that quietly
  dropped text would make the output lie about the repository it describes.

- **`models.json` beside each scan: which weights actually ran.** A model name
  is a moving tag, so two scans months apart naming the same model can run
  different weights. The digest is what the name pointed at during that scan.

- **`concept-scanner tiers`: what do you actually get at 8 GB, 24 GB and
  64 GB?** Runs one scan per model profile over one corpus and reports, per
  tier, how many concepts came out, how often a concept's description names
  symbols that are really in the file it cites, how often it cites a file that
  does not exist at all, and the wall-clock cost. `tiers run` measures one arm
  at a time and writes its record immediately, so a sweep that dies at arm three
  keeps arms one and two; `tiers report` renders whatever exists and names the
  arms that are missing.

  **It is a screen, not a ranking.** It says which tiers are disqualified, not
  which is best: nothing in it judges whether one model's concepts are better
  engineering descriptions than another's, and the report says so in its own
  output rather than leaving a reader to infer it from a table of numbers.

  Two refusals are built in, because a benchmark that quietly compares
  incomparable things is worse than none. Arms that did not see the same bytes
  are refused, by content hash over the corpus. Arms that ran with different
  flags are refused, by comparing the recorded argv, with model selection as the
  one permitted difference. The sweep also re-hashes the corpus after every arm
  and stops if it changed mid-run.

- **`scan --record-examples <path>`: keep what was actually asked and
  answered.** Appends every request and its answer to a JSONL file, at the
  inference seam, so it covers the local and the remote backend identically.
  Off by default and it says what it is doing when switched on, because the
  prompts contain the source of the repository being scanned and this writes
  that source to a second place on disk. Bounded: at the budget it stops and
  says so rather than writing truncated records.

- **`concept-scanner distill prepare` and `distill gate`.** `prepare` splits a
  captured corpus into train/valid/test **by hashing the original request**
  rather than by shuffling lines, so every example derived from one request
  lands in one split and the test set stays held out as the corpus grows.
  `gate` decides whether a candidate model has earned an incumbent's place, and
  returns one of three answers: promote, reject, or inconclusive.

  Inconclusive is a real verdict, not a soft reject, and it fires when the
  sample is under 20 comparisons, when the judge disagrees with itself across
  the two presentation orders too often, or when a second signal computed
  without any judge disagrees about which side of the bar the result falls on.
  The judge may not be either contestant, and that is refused rather than
  warned about.

### Fixed

- **Characterization no longer sends a structured-output schema, and the scan is
  both faster and more complete for it.** The schema stated what the answer must
  look like and never stated how long it could be, so a grammar-constrained
  decoder had nothing to stop it: one model wrote inside a string field until it
  hit whatever output cap it was given, taking over an hour on a 3 KB file and
  producing a concept whose descriptive fields were all empty.

  Measured on the same corpora, with the schema and without:

  | | schema on | schema off |
  |---|---|---|
  | `qwen3-coder:30b` | 6,156s, descriptive fields empty | **150s, all populated** |
  | `qwen2.5-coder:7b` | 263s, complete | **226s, 9 of 9 complete** |

  The obvious middle path, bounding each string field with a maximum length, was
  tried and was worse than either: 41 seconds producing concepts whose
  descriptive fields were all EMPTY, including on the model that never overran.

  **This is safe because the prompt has been the real contract since
  2026-07-17.** The remote path already downgrades the schema to a bare
  `json_object` and discards its `"required"` list before sending, so every field
  has had to be named in the prompt regardless, and sending a schema on the local
  path only was a divergence between the two backends. A test now asserts that
  every descriptive field is named in the prompt, and another fails if the call
  silently regains a schema.

- **Budget escalation now tries the ceiling it names.** The escalation step count
  was a fixed 2 and was therefore the real limit, so a call starting at the 4096
  characterization budget stopped at 16384 while every log line reported a
  ceiling of 32768. The error named a budget the code never attempted. The step
  count is now a safety bound and the ceiling is the limit, itself bounded by the
  model's real context window rather than by a constant.

- **Run-level timeouts derive from the per-call timeout, or default to none.**
  `anchoring-check` budgeted ten minutes for a run of two full generations whose
  own per-call timeout is ten minutes each, and a tier-benchmark arm deadline
  killed a scan that was still working and recorded it as incomplete. Where a
  run's call count is not knowable in advance the default is now no limit: the
  per-call timeout prevents a hang, and a run-level deadline over a whole scan
  only converts slow into failed. Two source guards keep it that way.

### Added

- **`concept-scanner distill gate --calibrate`: check a judge against a question
  with a known answer.** It judges a corpus against a COPY OF ITSELF, where the
  only correct answer is a tie, every time, and refuses a judge that expresses a
  preference. Measuring self-agreement across presentation orders cannot catch
  this: the order swap turns a purely positional answer into a tie, so a judge
  that is not reading its inputs reads as merely indecisive.

- **`scripts/e2e-smoke`: one live pass over every command surface.** The test
  gate needs no model, so it cannot catch a capability wired into one scanner
  path and not the other, which has happened four times. This runs every
  command against a real model and asserts each one RUNS and produces its
  artifact. It is not a correctness test and does not pretend to be. Its default
  model is the FAST tier deliberately: a smoke check that cannot finish is not a
  smoke check.

### Changed

- **The promotion gate's judge can be a model that reasons.** Its output budget
  was 8 tokens, on the reasoning that the answer is one token and a judge given
  room to explain will explain. That excluded every model that thinks before
  answering: on the first live run a reasoning judge truncated at 8, then at 16
  and 32 as the budget escalation tried to rescue it, and every comparison came
  back unjudgeable. The budget is now 512 and the answer is read from the END of
  the reply, because a model weighing two options mentions both, and the first
  match is whichever it discussed first rather than its conclusion.

- **Truncated generations are no longer invisible.** A generation that hits the
  output cap returns an error, and the recorder sits on the success path, so
  every discarded attempt used to vanish: its tokens, its minutes, and the fact
  that it happened at all. Measured before the fix: **96% of one scan's elapsed
  time appeared in none of its own records.**

  Both clients now return a typed error carrying the usage they already had and
  were formatting into a message and dropping. The retry decorator reports every
  abandoned generation, including the final one when all escalations are spent,
  and each carries a request key so it joins to the captured prompt that caused
  it without the cost log ever holding source. A scan says what it threw away,
  and says plainly that on a remote provider those tokens were **billed and are
  not in the usage it reports**.

  Abandoned tokens are recorded but excluded from the reported totals, so
  `ScanResult.InputTokens` / `OutputTokens` mean exactly what they meant before.
  Whether they SHOULD include billed-but-discarded tokens is a contract question
  written up rather than decided quietly.

  **This is why it mattered enough to do first.** Output budgets cannot be
  derived from recorded data while the recorded population is censored at exactly
  the threshold being set: every call that exceeded the budget was missing from
  the data you would use to choose the budget, and the censoring is
  self-reinforcing.

- **All nineteen output budgets are now classified in the threshold registry**,
  honestly, as unmeasured. They had escaped it entirely: `genbudget` was not in
  the audited file list, and adding it would have checked nothing, because the
  budgets are struct fields rather than `const` declarations and the audit only
  walks constants. A reflection-based guard now requires every budget field to
  be classified, and was proven to fire before being relied on.

- **`IsTruncation` matches on a type rather than on either client's prose.**
  String matching survives only as a fallback. The old behaviour was the
  fragile-matching shape ADR 0001 is about, and it was not theoretical: changing
  the clients' wording silently disabled every budget escalation in the product
  while the whole suite stayed green, because its fixtures were hand-written
  strings rather than what the clients emit. Both clients are now tested against
  their own real output.

- **The model picker's speed estimates were measured and were wrong.** All three
  non-baseline profiles: Fast was described as "~3x faster than Balanced"
  (measured 1.7x on a small corpus), Validated as "~1.3x slower" (measured
  **18x**), and Thorough as "~3-4x slower" (measured **0.86x, i.e. faster**).

  The field's shape was the deeper problem. **The ratio between tiers is not a
  constant**: Fast is 1.7x Balanced on four files and more than twenty on twelve,
  because the larger model's characterization hits the output cap and each
  overflow costs a full re-generation. A bare multiplier is wrong at some corpus
  size whatever number it carries, so each estimate now names the corpus it came
  from, and a test fails any that does not.

- **The Validated profile no longer claims to add Pass 2 validation.** Pass 2
  runs at every profile; what that profile adds is a second extraction model,
  merged. The published README said the same wrong thing, and contradicted itself
  twenty lines later where the same flags were described correctly.

- **A scan now says how much of its own elapsed time it cannot account for**,
  when that share passes half. The number can be startling: a benchmark arm ran
  90 minutes and its recorded calls summed to 141 seconds. The missing time is
  real work, generations that hit the output cap and were re-issued at a raised
  budget, and a truncated attempt returns an error rather than a result, so
  nothing records it. **On a remote provider those attempts are billed and are
  not in the reported usage.** This is a disclosure, not a fix; the fix needs the
  usage to survive the error.

- **Sampling is now hard pinned** (temperature 0, top_p 1, no top_k, seed 42).
  It was temperature 0.1 with a fixed seed, which is a sampled distribution with
  a stable starting point rather than determinism. Output will differ slightly
  from previous versions and should differ less between runs.

- **Output-budget escalation on truncation is bounded by the model's own
  context**, not only by a global ceiling, so a model with a smaller window
  stops after one refusal instead of spending two more full generations
  reproducing the same truncation.

- **The characterization warm-up has its own 90-second deadline** and reports
  what it is doing. It previously inherited the full request timeout, so its
  failure mode was a silent multi-minute stall.

- **The scan result reports how much of the repo a model actually read**
  (`ScanResultSchemaVersion` 1.0.0 -> **1.1.0**). `files_analyzed` counts files
  the scanner COLLECTED, and batch assembly can drop a collected file before
  any prompt is built: one that exceeds the per-file size cap, or one that
  arrives when a batch's character budget is already full. Nothing in the
  output said so, so a scan could report thousands of files analyzed while the
  model never saw a large share of them.

  Four new fields close that gap. Coverage of what a model actually read is
  `files_analyzed - files_dropped_at_batch`.

  | Field | Meaning |
  |---|---|
  | `files_dropped_at_batch` | Collected files that never reached a discovery prompt. Always emitted, so `0` is distinguishable from an older scanner that cannot answer. |
  | `files_dropped_too_large` | The subset over the per-file size cap. Not tunable: no setting admits these. |
  | `files_dropped_budget` | The subset dropped when a batch filled. Tunable: a longer-context model or a lower `--parallel` admits them. |
  | `characterization_incomplete` | Concepts that shipped with empty descriptive fields. Separates a thin run from a broken one, which look identical on concept count alone. |

  Additive and backwards-compatible: a consumer written against 1.0.0 stays
  correct in everything it already read.

### Changed

- **`discovery_degraded` now also fires when files were dropped**, on both the
  single-model and multi-model paths. It previously meant "a discovery batch
  failed" on one path and included drops on the other; the two paths disagreed
  about what a degraded discovery is. If you branch on this flag, read
  `files_dropped_at_batch` to tell the two causes apart.

### Fixed

- **`scan --json` could still print human text to stdout, so the envelope did
  not parse.** Progress and status lines are supposed to go through
  `progressf`/`progressln`, which divert to stderr under `--json`. Two sites
  bypassed them and wrote to stdout unconditionally: the
  `Characterized N/M concepts...` counter (fires on any scan with more than 20
  concepts) and the `--skip-review has no effect with --multi-model` note. A
  consumer piping `scan --json` into a parser got a preamble ahead of the
  opening brace and failed on the whole document.

  Both now route correctly. A source guard
  (`TestNoDirectStdoutOutsideCommandLayer`) fails the build on any new direct
  stdout write outside the command layer, so this class cannot return quietly:
  the previous test proved the routing helpers worked, which is not the same as
  proving every caller uses them.

- **`files_analyzed` overstated coverage.** Its own documentation claimed it
  counted the files put in front of the model; it counted the files collected,
  and collection applies no size filter at all. The number was wrong in the
  direction that hides the problem.

## [1.0.6] - 2026-08-05

**First release published to
[`concept-scanner-public`](https://github.com/Obviously-Not/concept-scanner-public),
and the first of any kind since `v1.0.5` on 2026-07-15.**

The source repository went private on 2026-07-18, which took the binaries, the
image and the GitHub Action private with it. Distribution is now split from
source: the binaries, the image, the Action and these docs are published to a
public repository, while the source stays private. For users the practical
change is the coordinates. `uses: Obviously-Not/concept-scanner-public@v1`,
and downloads from that repository's releases; the image path is unchanged.

Everything between `v1.0.5` and here is reliability and quality work: a
provider-agnostic model registry with fail-fast id resolution, a consolidated
remediation pass over the open issues, and the two-phase (distill then extract)
generation mode behind an off-by-default flag.

### Added

- **`schema_version` on the scan result.** The envelope (which concept arrays
  exist, which is authoritative, the enriched-to-code 1:1 invariant) is now
  versioned by `ScanResultSchemaVersion`, alongside the existing per-record
  concept and bridge versions. A consumer can assert the shape it was handed
  instead of assuming one.

- **Shell and GraphQL files are scanned** (`.sh`, `.bash`, `.zsh`, `.graphql`).
  Build, deploy and entrypoint logic is real mechanism, and excluding it meant a
  repository whose distinctive work lives in its toolchain scanned as if that
  work were absent.

- **Bridges now carry the commercial axes** (`BridgeSchemaVersion` 1.0.0 →
  **1.1.0**). A `Bridge` gains `product_centrality` and `defensibility`,
  matching the axes a `Concept` and a synthesized pattern already carried.
  Bridges were previously the one output layer that no
  `(product_centrality + defensibility) / 2` ranking could order. Both fields
  are **nullable**: a model that declines to score emits `null`, never `0`,
  because a defaulted `0` would rank an unscored bridge below a genuinely
  peripheral one. Additive optional fields, so a minor bump. The axis
  definitions handed to the model are lifted verbatim from Pass 5, so a bridge
  and a pattern scored on `product_centrality` answer one question rather than
  sharing a field name.

- **`code_files_analyzed` / `doc_files_analyzed` on the scan result.** The
  existing `files_analyzed` counted code plus any included documentation, so a
  docs-heavy repository reported a large total that read as *code* coverage.
  `files_analyzed` keeps its meaning (the total); the two new fields make
  coverage computable instead of inferred. Console and summary output now show
  the breakdown, but only when documentation was actually included.

- **Cloud default models**: Both `--primary-model` and `--secondary-model` are
  now optional for cloud scans. The primary defaults to the measured best-value
  model (ranked #1 on cost per distinctive concept; see `concept-scanner models
  --cloud`). The secondary (Pass 2 grader) defaults to a model validated to
  complete classification reliably on OpenRouter. The scanner prints a note
  when defaulting either.

- **`--allow-external-symlinks` flag**: Skips symlink-escape validation for
  repositories that legitimately contain symlinks pointing outside the repo
  boundary (e.g., to a shared corpus or federated artifacts).

- Improved progress display during long scans: shows elapsed time, ETA (a
  self-calibrating EMA divided by the batch parallelism, so it reflects wall
  clock), percentage, and running concept total. Elapsed rolls into `H:MM:SS`
  past an hour. TTY-aware output uses in-place updates on terminals and clean
  newlines in CI/logs, with failed batches always reported on their own line.
  Upfront runtime estimate printed for scans with >10 batches.

- **`models --json`**: the `models` command now accepts `--json`, emitting the
  same `{ data, next_steps, notice }` envelope as `scan --json`, so a machine
  consumer can read the local profiles (with install status) and the cloud
  shortlist. Install status is `null` (not `false`) when Ollama is unreachable,
  so "not pulled" and "could not check" stay distinguishable.

### Fixed

- **Vocabulary neutralization now matches the importer's exactly.** Six phrases
  were neutralized by the hosted scanner and not by this one, so the same text
  was cleaned or not depending on which scanner ran; two more were neutralized
  to different wording on each side, so one concept could read differently
  depending on which side processed it. Both lists now hold identical phrases
  with identical replacements, and a parity check covers them so the two cannot
  drift apart again unnoticed.

- **Two source guards could not fire on the shapes they were written for.**
  The vocabulary guard used a trailing word boundary, which by definition
  cannot match before an underscore, so the snake_case form it was explicitly
  added to catch never matched. The identifier guard compared decomposed
  camelCase pieces for equality, which made every multi-word entry in its list
  unreachable by construction. Both are fixed, and a new test fails on any
  entry no identifier could ever produce, so a rule that reads as protection
  but cannot fire is now caught at test time.

- **Pass-5 synthesized patterns are sanitized.** Concepts and bridges have
  passed through the output-layer vocabulary sanitizer for months; patterns
  never did, so Pass-5 text reached storage, stdout and any consumer without
  it. `sanitizePattern` now runs on both Pass-5 entry points.

- **An unnamed bridge is declined rather than emitted.** Synthesis that
  returned no name produced a bridge with an empty name and a truncated
  identifier (the identifier is derived from the name), putting an
  uninformative entry in front of a reviewer with nothing recording that the
  name was missing. Whitespace-only names count as unnamed.

- **Removed two Pass-5 guidance fields** that offered patent-practice
  suggestions rather than engineering description, which is outside this
  tool's scope. Both were deterministic keyword templates, and the only
  consumer already discarded them, so no downstream output changes.

- **`--secondary-model` now works on cloud without requiring `--primary-model`.**
  Previously the flag was silently ignored when the primary model was not also
  explicitly specified, causing cloud scans to always use the default grader
  even when `--secondary-model` was passed.

- **Cloud Pass 2 grader changed to a model that actually works.** The previous
  default (`openai/gpt-oss-20b`) failed on OpenRouter with timeouts and
  truncation; `openai/gpt-oss-120b` also failed. The new default was validated
  to complete Pass 2 classification without degradation.

- **Multi-model discovery no longer silently collapses to one model.** The tool's
  own recommended `--multi-model` secondary (`gpt-oss:20b`) and `--thorough`
  primary (`qwen3-coder-next`) were absent from the JSON-capability registry, so
  the local multi-model backend dropped their structured-output grammar; the
  extractor then emitted prose, failed to parse, and the two-model profile
  degraded to single-model. Both are now marked JSON-capable, with a guard test
  asserting every shipped local profile model is.

- **Remote characterization survives a mistyped field.** On an OpenAI-compatible
  provider (`json_object` mode), a single field returned as a stringified number
  (`"0.8"`), a stringified integer, or an object where a string was expected used
  to fail the whole characterization unmarshal, shipping the concept with zero
  engineering axes. The numeric axes and array fields now decode tolerantly
  (coerce rather than fail); the local, grammar-constrained path is unchanged.

- **Public distribution restored.** The "Running in Docker" and "GitHub Action"
  sections briefly carried notes saying the image and `uses:` reference were not
  publicly consumable. Both are consumable again, from the public distribution
  repository, so the notes are gone and every reference points at the coordinates
  that actually resolve.

- **The build was broken for anyone but a maintainer, and is fixed.** Since
  2026-07-21 a clean clone could not compile: `go.mod` carried a `replace`
  pointing at a sibling checkout outside the repository. The dependency is now
  consumed as a published module version. Nothing between `v1.0.5` and this
  release could have been built by anyone who did not already have that sibling
  on disk, which is also why no release was cut in that window.

- **Cross-compilation restored for all five platforms.** The same change pulled
  in tree-sitter, which requires cgo, and that broke static cross-compilation
  outright. The TypeScript and Python encoders now sit behind a build constraint,
  so released binaries are statically linked again and run on musl images.
  **Consequence worth knowing:** a released binary skips Avenue B for Python and
  TypeScript projects. Those still scan, because Avenue A is language-agnostic
  and the two avenues merge; what is lost is semantic batching, not support for
  the language. A locally built binary with cgo enabled retains both.

## [1.0.5] - 2026-07-15

- CI: move the workflow actions off the deprecated Node 20 runtime to Node 24.

## [1.0.4] - 2026-07-15

- Fix: remediate eight verified defects surfaced by a dual code review
  (provider wiring, model selection, and output-handling correctness).

## [1.0.3] - 2026-07-15

- Fix: honor the saved-config primary model, and pre-pull the models the scan
  finalize step and the standalone `bridges` / `triage` commands need, so a
  first run does not fail partway on a missing model.

## [1.0.2] - 2026-07-15

- Docs: set the Marketplace display name to "Obviously Concept Scanner".

## [1.0.1] - 2026-07-14

- Fix (Action): hand root-created output back to the workspace owner and stop
  writing scratch files into the scanned tree.

## [1.0.0] - 2026-07-14

- Initial release: the provider abstraction (local Ollama or any
  OpenAI-compatible remote endpoint) and the GitHub Action, publishing the
  container images to GHCR and Docker Hub.

Releases from 1.0.6 onward are published to this repository. Versions 1.0.0
through 1.0.5 predate the split and were released from the source repository,
which is private, so they have no page here.
