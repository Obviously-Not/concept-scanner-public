# Changelog

All notable changes to concept-scanner are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are the
`v*` tags in this repository.

## [Unreleased]

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

- **Vocabulary neutralization now matches the platform exactly.** Six phrases
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
