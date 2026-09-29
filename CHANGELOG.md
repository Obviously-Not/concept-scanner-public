# Changelog

All notable changes to concept-scanner are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are the
`v*` tags in this repository.

## [Unreleased]

Nothing yet.

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
