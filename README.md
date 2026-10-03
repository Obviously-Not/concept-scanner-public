# Concept Scanner

> **This is a distribution repository.** It carries the documentation, the
> GitHub Action, and the released binaries. The source lives in a private
> repository and is not published here, so there is nothing to build or send a
> pull request against: every file here is generated from the source repo on
> each release and is overwritten by the next one. Bug reports and feature
> requests are welcome in this repo's issue tracker.

Local-first **engineering concept scanner** for codebases. Point it at a repository or directory and it surfaces distinctive technical mechanisms ("concepts"), scores them on four core engineering-quality axes (technical distinctiveness, implementation depth, problem specificity, generality) plus supplementary signals, and saves the results locally for you to review.

The JSON output is shape-matched to the [Obviously-Not platform's](https://github.com/Obviously-Not) `code_scan` pipeline (`CharacterizationOutputSchema` v1.3.0) — engineering vocabulary only, no legal-statute language. Compatibility is by field-level inspection; it has not yet been validated against a live platform parser. Legal review is a separate, downstream step performed by qualified humans.

By default all analysis runs against a local [Ollama](https://ollama.ai) model, so **your code stays on your machine**: no API keys, no cloud calls, no per-scan cost. You can optionally point it at a remote OpenAI-compatible provider (`--provider openai-compatible`), which sends your source to that endpoint; see [PROVIDERS.md](docs/providers.md). The only other request it makes asks GitHub for the latest release: when you run `concept-scanner update`, and, only if you have said yes to it, at most once a day when a scan starts. It sends nothing about you or your code.

## Quick start

```bash
# 1. Install and start Ollama (https://ollama.ai)
ollama serve

# 2. Install the scanner for your user: no administrator rights, no Go toolchain.
#    macOS and Linux:
curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.sh | sh
#    Windows (PowerShell):
powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1 | iex"
#    It installs to ~/.local/bin (on Windows, %LOCALAPPDATA%\Programs\concept-scanner),
#    puts that on your PATH, and checks the download against the release's
#    checksums. Open a new terminal afterwards. Or run it via Docker (see
#    "Running in Docker" below).

# 3. Scan a local directory (or a remote repo URL).
#    On the first run, setup asks Local (Ollama) vs Cloud, then a
#    memory-aware picker helps you choose a model.
concept-scanner scan ./my-project

# 4. Review the discovered concepts interactively
concept-scanner review <scan-id>

# 5. Export an approved concept as a JSON draft
concept-scanner submit <concept-id>

# Later: check for a newer release. At a terminal it asks before installing,
# and it replaces this copy only after the release's signature verifies.
concept-scanner update
```

**Hearing about new releases.** After your first scan at a terminal, the scanner asks once whether it may check for a newer version when a scan starts, at most once a day. It is off unless you say yes, and it only ever tells you; installing is still `concept-scanner update` and your yes. Change it any time with `concept-scanner update --auto-check on` or `off`.

**Installing by hand.** Download the binary for your platform from the [latest release](https://github.com/Obviously-Not/concept-scanner-public/releases/latest) (`darwin-arm64`, `darwin-amd64`, `linux-amd64`, `linux-arm64` or `windows-amd64.exe`) and check it against `checksums.txt`. The Windows binary is signed (Microsoft Artifact Signing), and the macOS binaries are signed with a Developer ID and notarized by Apple. A bare command-line binary cannot carry its notarization with it, so the first time you run a macOS binary downloaded in a browser, run it from Terminal while online: macOS checks with Apple then. (Double-clicking it in Finder does not work for any command-line tool, signed or not.) See [TROUBLESHOOTING.md](docs/troubleshooting.md).

**Uninstalling.** Run the same script with `--uninstall` (macOS and Linux: `curl ... | sh -s -- --uninstall`) or, on Windows, `-Uninstall`: `powershell -ExecutionPolicy ByPass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1))) -Uninstall"`. It removes the program, the line it added to your shell's startup file or your PATH, and `~/.concept-scanner`; scan results in each project's `data/` folder are left alone.

**Shell completions:** `concept-scanner completion --help`.

Hitting an error or empty/thin output? See **[TROUBLESHOOTING.md](docs/troubleshooting.md)** for the common failure modes and how to recover.

## Running in Docker

Prebuilt images are published to GHCR and Docker Hub:

```bash
docker pull ghcr.io/obviously-not/concept-scanner:v1
# or: docker pull leegitw/concept-scanner:v1
```

The scanner runs against your **host Ollama**. Inside a container, `localhost` is the container's own loopback, not the host, so point `--ollama-host` at the host:

```bash
# macOS / Windows (Docker Desktop):
docker run --rm -v "$PWD:/workspace" ghcr.io/obviously-not/concept-scanner:v1 \
  scan /workspace --ollama-host http://host.docker.internal:11434

# Linux: add the host-gateway mapping (or use --network host):
docker run --rm --add-host=host.docker.internal:host-gateway \
  -v "$PWD:/workspace" ghcr.io/obviously-not/concept-scanner:v1 \
  scan /workspace --ollama-host http://host.docker.internal:11434
```

For a remote provider instead of host Ollama, pass `--provider openai-compatible --base-url ...` and the API-key env var. The model defaults to the measured best-value option (see `concept-scanner models --cloud`); pass `--primary-model` to override. See [PROVIDERS.md](docs/providers.md).

To bundle Ollama alongside the scanner (no host Ollama needed), use the included [`docker-compose.yml`](docker-compose.yml). Note: Ollama in a container is CPU-only unless a GPU is passed through (NVIDIA/Linux only; Docker on Apple Silicon cannot pass the GPU), so on a Mac the host-Ollama approach above is usually faster.

## GitHub Action

Run a concept scan in CI. This is a Docker action, so it runs on **Linux runners only**. GitHub-hosted runners cannot run a local LLM, so use a remote OpenAI-compatible provider there; on a self-hosted runner with Ollama you can use the local, no-egress mode instead.

```yaml
# .github/workflows/concept-scan.yml
name: concept-scan
on: [workflow_dispatch]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Obviously-Not/concept-scanner-public@v1
        with:
          provider: openai-compatible
          base-url: <your provider's /v1 URL>   # see PROVIDERS.md
          # model: optional, defaults to the measured best-value model
          api-key: ${{ secrets.YOUR_PROVIDER_API_KEY }}   # a secret, never inline
```

Inputs: `repo-path` (default `.`), `provider`, `base-url`, `model` (optional, defaults to the measured best-value model; see `concept-scanner models --cloud`), `ollama-host`, `api-key`, `extra-args`. The `api-key` must be passed as a secret. Concrete endpoints and model strings are in [PROVIDERS.md](docs/providers.md). The action ships no default provider or key: you supply the backend, exactly as a local run does.

## Choosing a model

On an interactive first run (no `--provider` and no saved config), setup first asks
**where inference runs**:

- **Local (Ollama)** — private; your code stays on your machine. Falls through to the
  memory-aware model picker below.
- **Cloud (OpenAI-compatible endpoint)** — faster/larger models, but your source is sent
  to the endpoint. Shows a **cost/quality-ranked shortlist**, assembles the exact
  `--provider openai-compatible` command for the model you pick, and reminds you to export
  your API key (which stays in the environment, never a flag). Concrete endpoints and model
  strings live in [PROVIDERS.md](docs/providers.md); `concept-scanner models --cloud` prints the
  same shortlist any time.

Explicit flags, `--no-interactive`, or a saved config skip the prompt entirely, so
scripted and CI runs are unaffected. A scan never prompts when a coding agent or CI
runs it, under `--json`, or with `TERM=dumb`: it uses the saved profile or the
defaults and says so. On a terminal the choices take the arrow keys and Enter as
well as their letters.

### Local model profiles

The first interactive run shows a **memory-aware picker** that detects your RAM and
recommends a profile, flagging any option too large for your machine. On Apple Silicon it
also notes that MLX-optimized builds (an `-mlx` tag) run faster and can be chosen via
Custom. Your choice is saved to `data/config.json` and reused on later runs. Re-pick your
**local profile** any time with `concept-scanner init`. To switch between local
and cloud, or to change a cloud model, re-run `scan` with explicit `--provider` /
`--primary-model` flags, or delete `data/config.json` to see the first-run
local-vs-cloud setup again.

| Profile | Model(s) | Approx. RAM | Notes |
|---------|----------|-------------|-------|
| **Fast** | `qwen2.5-coder:7b` | ~7 GB | Quick scans on any laptop |
| **Balanced** (recommended) | `qwen3-coder:30b` | ~22 GB | Best capability/size ratio |
| **Validated** | `qwen3-coder:30b` + `gpt-oss:20b` | ~38 GB | Runs a second extraction model in parallel and merges (`--multi-model`). Pass 2 validation runs at every profile, not only this one |
| **Thorough** | `qwen3-coder-next` | ~50 GB | Larger MoE model, slower |
| **Custom** | any Ollama tag | — | Type your own model |

Model resolution precedence: explicit flags (`--primary-model` / `--multi-model`) →
saved `data/config.json` → interactive picker (TTY only) → built-in defaults. To run
non-interactively (CI, scripts), pass `--no-interactive` with `--primary-model`:

```bash
# Use a specific installed model, no prompts (works single-pass or multi-model)
concept-scanner scan ./my-project --no-interactive --primary-model qwen2.5-coder:7b

# Two models in parallel with a merge step
concept-scanner scan ./my-project --multi-model \
  --primary-model qwen3-coder:30b --secondary-model gpt-oss:20b
```

Missing models are auto-downloaded on first use unless you pass `--no-auto-pull`.
Any installed Ollama model is accepted; unrecognized tags get a one-line note and run as-is.

## How it works

1. **Collect** source files (skipping `vendor`, `node_modules`, `.git`, etc.).
2. **Validate** the target before scanning — symlink-escape, device-file, and zip-bomb checks (remote clones also get repository size / file-count caps).
3. **Distill** each file with Principle-Based Distillation (PBD) via the local model.
4. **Synthesize** candidate concepts.
5. **Characterize** each concept on the four core engineering axes (technical distinctiveness, implementation depth, problem specificity, generality) plus supplementary signals (commonness, paradigm-shift). The commercial axes (product-centrality, defensibility) are emitted as `null` — concept-scanner doesn't have your market context, so a downstream consumer (your review process or platform ingress) fills these in. The output also carries the concept's key insight, inputs/outputs, components, and comparable techniques.
6. **Enrich** with dependency-license risk and git authorship.
7. **Save** results under `./data/scans/`, a `SUMMARY.md`, and a provenance audit log under `./data/audit/`.

Generation that hits its token cap **fails loud** rather than silently truncating, and all
emitted text passes an output-layer check that keeps legal-statute vocabulary out of the results.

## Commands

| Command | Purpose |
|---------|---------|
| `scan <path-or-url>` | Scan a directory or remote repo for concepts |
| `review <scan-id>` | Step through discovered concepts and approve/reject |
| `submit <concept-id>` | Export an approved concept as a platform-shaped JSON draft |
| `triage <scan-id> --workspace <path>` | Re-run grounding triage on a completed scan (`scan` runs it automatically; this re-runs after model/prompt changes) |
| `bridges <scan-id>` | Discover cross-concept bridges (Pass 3 combinations) over a completed scan |
| `models` | List the recommended model profiles + which are already pulled |
| `bench` | Measure whether your model server actually runs requests in parallel |
| `tiers run` / `tiers report` | Run one scan per model profile over one corpus and report what each produced |
| `refusals <scan-id>` | Review what the quality gates held back, and who each verdict points at |
| `review <scan-id> --why <concept>` | Say why one concept was held back: the gate, what it measured, and how the number it failed was set |
| `status [run-id]` | Show what a scan is doing, or `--wait` for it to finish (see "Watching a scan") |
| `anchoring-check` | Check whether a model is repeating the prompt back rather than reading the code |
| `init` | Re-run the memory-aware model picker and save the choice |
| `version` | Print the version and default models |

## Useful flags (`scan`)

| Flag | Description |
|------|-------------|
| `--primary-model` / `--secondary-model` | Choose the model(s) explicitly (any installed Ollama tag) |
| `--multi-model` | Run two local models in parallel and merge results |
| `--no-interactive` | Skip the first-run picker; use saved config or defaults (for CI/scripts) |
| `--skip-review` | Single-pass only — skip the Pass 2 validation model (faster) |
| `--thorough` | Use the larger, higher-quality model |
| `--include-textbook` | Also emit concepts classified `textbook` (default: classify every mechanism, hold `textbook` back — see below) |
| `--two-phase` | Experimental. Run generation as two calls (freeform distill, then structured extract) instead of one grammar-constrained call (see "Two-phase generation" below). Also settable via `CS_TWO_PHASE=1`. |
| `--extract-model` | Phase-2 extraction model for `--two-phase` (default `gpt-oss:20b`). Also `CS_EXTRACT_MODEL`. |
| `--timeout` | Per-request inference timeout (default 10m single-call, 30m under `--two-phase`). Raise for slow models or large batches. |
| `--no-triage` | Skip the per-concept grounding triage pass (faster; leaves ungrounded concepts tagged `pending` instead of `file_missing` or `rescued`) |
| `--tests` | How test files are used: `off` (default), `evidence` or `source` (see "Tests as evidence"). Also `CONCEPT_SCANNER_TESTS`. `--include-tests` is the older spelling of `--tests source`. |
| `--no-auto-pull` | Fail if a model is missing instead of downloading it |
| `--no-semantic-batching` | Disable PBD-guided semantic batching (use size-based batching only) |
| `--allow-external-symlinks` | Allow symlinks pointing outside the repository (skips symlink-escape validation) |
| `--ollama-host` | Ollama API URL (default `http://localhost:11434`) |
| `--parallel-batches` | How many requests a scan keeps in flight (default 4). The model server serves as many at once as it has slots (Ollama's `OLLAMA_NUM_PARALLEL`, default 1) and queues the rest, so on a default server more is not faster. On a server with several slots, concurrent requests share the work and a scan is then **not byte-reproducible** run to run; use `1` when you need the same output twice. `models.json` beside each scan records the server's slots when the server runs on this machine and its log can be read |
| `--full-history` | Fetch full git history for richer file provenance |
| `--json` | Machine-readable `{ data, next_steps, notice }` envelope (see "Machine-readable output") |
| `--progress` | How the run is shown on stderr: `auto` (default), `live`, `static`, `plain` or `jsonl` (see "Watching a scan"). Also `CONCEPT_SCANNER_PROGRESS`. |
| `-v, --verbose` | Detailed progress output, and at the end why each refused concept was refused (the same text as `review --why`) |

Run `concept-scanner scan --help` for the complete list.

## Concept output and grounding state

Concept descriptions (`summary`, `technical_approach`, `components`) are
**engineering observations to verify against the cited code, not final
findings**. They can misstate the code they point at, so every concept ships with
`review_status: pending` and a `location` to check. Treat a description as a
pointer to review, not an authority; the `review` command exists for exactly that
pass.

Each discovered concept ships with a `grounding` field that records how the
scanner verified its `location.file`:

| State | Meaning |
|-------|---------|
| `grounded` | The path the model emitted resolves to a real file in the workspace as-is. |
| `repaired` | The model emitted a malformed path that the finalize-pass automatically fixed (e.g. `src/foo.ts` → `app/src/foo.ts`). |
| `rescued` | A fuzzy basename search or LLM triage call found the real file the concept actually lives in. The original LLM-emitted path is preserved in `grounding_original_file`. |
| `file_missing` | The triage pass searched candidate files but couldn't ground the concept anywhere — most likely a hallucination. |
| `uncertain` | Triage ran but the model wouldn't commit either way. |
| `pending` | Triage was skipped (`--no-triage`). |

Downstream consumers typically filter on `grounded`, `repaired`, or `rescued`
and treat `file_missing` / `uncertain` with appropriate skepticism.

## Tests as evidence

Test files are not read as a source by default. A test's setup data can
describe a mechanism that does not exist, and a model that reads it as real
ships a concept that is not in your code. Instead, after a scan decides which
concepts it ships, each concept is paired with the tests beside it that use the
declarations in its line range: for Go, the test functions in its own
directory; for TypeScript and JavaScript, the `.test.` and `.spec.` files in
its directory and its `__tests__` directory; for Python, the test files in its
directory and the `tests/` or `test/` files named for its module or mirroring
its path. Go is read from its syntax tree and the other three by pattern, which
is less exact (see below). Models usually give no
line range, so then the tests that use a declaration the concept's description
names come first, ahead of the rest of the file's tests. No model is involved,
no concept changes, and the result is written beside the scan as `tests.json`,
with one line in the output:

```
Tests: 12 of 30 shipped concepts are paired with tests that exercise them (tests.json)
```

| `--tests` | What it adds |
|-----------|--------------|
| `off` (default) | Pairing only. No model reads a test. |
| `evidence` | Also asks the model what each concept's paired tests assert that its description does not say, one call per paired concept. A property is kept only when its quote is found in the test's name, a failure message reported on the test's own `t`, the condition that guards one, or a case label the test prints and does not pass to the code under test, and when its statement repeats no phrase found only in the test's setup data. In TypeScript, JavaScript and Python the quote may come from the test's name or its assertion lines (`expect(...)`, `assert ...`), and there is no setup check. Every rejection is listed with its cause. The check is on where a quote comes from; it cannot tell whether the statement reads the assertion correctly. |
| `source` | `evidence`, plus test files and test directories are read as a source, in batches of their own, for mechanisms that live only in tests, such as a test harness. |

Tests often state what a mechanism refuses or never does, which a description
of what the code does tends to leave out, so `evidence` is where to look for
it.

What pairing cannot see: concepts in other languages are counted, not paired; a
test outside its language's convention that exercises the same code is not
seen; in TypeScript, JavaScript and Python a declaration or test written in a
form the patterns do not list is missed, and a name a test declares itself can
pair by accident; and pairing uses the line range a model wrote, so a wrong
range pairs the wrong tests. Whether the pattern-based languages pair well
enough to keep is being measured (precision and recall of at least 0.7 against
hand labels on one real repository each). `tests.json` records the names each test was paired on, so you can check
why. It is not part of the `--json` envelope, and nothing in it changes a
concept.

## Classification (`distinctive` / `borderline` / `textbook`)

The scanner **surfaces and classifies every mechanism it finds — it never
silently drops one.** Each concept carries a `classification`:

| Class | Meaning |
|-------|---------|
| `distinctive` | Clears all three engineering bars (technical distinctiveness, implementation depth, problem specificity). |
| `borderline` | Clears one or two, or is a strong instance of an otherwise-common pattern. |
| `textbook` | A standard library use, common design pattern, or routine implementation. |

The keep/drop decision is a **downstream, tunable step**, not something the model
does in the prompt: by default the results include `distinctive` + `borderline`
and **hold `textbook` back** (the count is reported so nothing is hidden). Pass
`--include-textbook` to include them. This is why a capable frontier model no
longer returns an empty set on a thin codebase — it classifies the standard
patterns as `textbook` rather than self-censoring to nothing.

## Semantic batching (dual-avenue discovery)

By default the scanner runs **two discovery avenues in parallel**:

- **Avenue A (size-based):** files are packed into batches until a context budget
  fills, in filesystem order. This is battle-tested and catches mechanisms that
  happen to land together.
- **Avenue B (PBD-guided):** uses go-pbd
  semantic analysis (domain, intent, dependencies) to group related files that
  would be scattered by size-based batching. An LLM suggests file groupings
  based on the semantic index, surfacing cross-file mechanisms (a protocol
  implemented across client/server, a validation pipeline split across modules).

Both avenues feed the same downstream pipeline (Pass 2 classification,
characterization, triage, bridges). Concepts from both are merged and deduped
before classification.

**`--docs-only` reads Markdown.** Only `.md` is collected as scannable
documentation; `.txt`, `.rst`, `.adoc` and `.org` are excluded by design, so
prose fixtures holding third-party text cannot enter as source. A `--docs-only`
scan of a repository whose documentation is not Markdown therefore selects
nothing, and says so rather than falling back to the code.

**Avenue attribution is not carried per concept.** A merged concept does not
record which avenue found it, so you cannot filter or group the output by
avenue. The run's progress output reports how many concepts each avenue
contributed and how many remained after the merge, which is enough to tell
whether Avenue B is earning its time on your repository, and that is all the
attribution there is.

**Language coverage:** Avenue B runs only when go-pbd can encode the workspace.
Supported languages: Go, TypeScript, Python, Markdown. For unsupported languages
(Rust, Zig, C, Java, etc.) Avenue B skips silently and Avenue A runs alone.

**Opt-out:** pass `--no-semantic-batching` to run Avenue A only.

**Cost:** PBD encoding is free (no LLM). The batch-suggestion call is one LLM
request with a compressed store (~3-10KB for a medium project). The discovery
calls per batch are identical to Avenue A.

## Two-phase generation (`--two-phase`, experimental)

By default each generative pass (discovery, characterization, bridge synthesis)
is a single call whose decode is grammar-constrained to a JSON schema. That is
fast and reliable for instruct/code models, but it leaves a reasoning model no
room to reason (the schema forces JSON tokens from the first token) and, on a
remote provider, tends to under-populate the descriptive fields.

`--two-phase` runs each of those passes as **two** calls instead:

1. **Distill (freeform):** the primary model describes the mechanism in prose,
   with no schema constraint, so a reasoning model can actually reason.
2. **Extract (structured):** a fast instruct model (`--extract-model`, default
   `gpt-oss:20b`) turns that prose into the schema-shaped JSON.

This mirrors the pattern the scanner is shape-matched to, and is expected to let
reasoning models participate in discovery and to populate the descriptive fields
natively (retiring the remote-characterization completion fallback). It costs two
calls per item instead of one; the extract call is small and fast.

The mode is **off by default** and being A/B'd against the single-call path
before the default flips. Enable it with `--two-phase` (or `CS_TWO_PHASE=1`), and
pick the extractor with `--extract-model <tag>` (or `CS_EXTRACT_MODEL`). It
currently applies to the single-model path plus characterization and bridge
synthesis; multi-model (`--multi-model`) Pass 1 discovery is not yet two-phase.

The freeform distill is slower per batch (it generates prose, and a reasoning
model reasons at length), so `--two-phase` raises the per-request timeout floor
to **30 minutes** so large batches finish instead of being killed mid-distill.
Override with `--timeout` if your models need more, and note that two calls per
item make wall-time meaningfully higher than the single-call path.

## Machine-readable output (`--json`)

`--json` is accepted by every command that produces output (`scan`, `review`,
`submit`, `bridges`, `triage`, `models`) and emits the same platform-aligned
HATEOAS envelope: the same shape on success and on error, so one parser handles
all of them. Progress goes to stderr, so stdout is pure JSON. (`review --json` is
a non-interactive **status** projection; it reports the current review state
rather than prompting. `models --json` is a catalog projection: local profiles
with install status plus the cloud shortlist, where `installed` is `null` rather
than `false` when Ollama is unreachable, so "not pulled" and "could not check"
stay distinguishable.)

```json
{
  "data": { "scan_id": "...", "concepts": [ ... ], "textbook_held": 12 },
  "next_steps": [
    { "action": "Review the discovered concepts", "command": "concept-scanner review <id>",
      "priority": "high", "reason": "Approval gates submission", "timing": "soon" }
  ],
  "notice": "12 textbook-classified concept(s) held back (use --include-textbook to include them). This run put 40 file(s) in front of the model, and reports 9 concept(s) while holding back 12. Anything not listed was not assessed."
}
```

A scan's `notice` always ends with that last part, the **run caveat**: how many
files the model actually saw (and how many it never did), how many concepts the
run reports and holds back, how many cited a file that could not be found, and
how many generations were discarded on an output cap. It is built from the run's
own numbers, so two runs that differ in any of them never print the same
sentence; a human-readable scan prints it as its `Coverage:` line. On failure,
`data` is `null` and the error is in `notice`.

**Exit codes:** `0` success; `1` a usage, configuration or other general error;
`3` the model or the model server (not running or stuck, a model missing or not
downloadable, a model the endpoint does not have, a model call that failed, or a
pass whose every call failed). `2` is reserved. Every command's output
(and every error) carries at least two prioritized `next_steps` with a reason and
a ready-to-run `command`, so a human or an AI agent always knows what to do
next — including when zero concepts are returned.

## Watching a scan

A scan takes minutes to hours, and it says what it is doing the whole time.

- **On a terminal**, a status line at the bottom shows the stage and how far
  through it is, how long the current model call has run, the time left once
  there is history to estimate it from (always marked `~`), tokens, cost, and a
  count of warnings and errors, with the last few log lines under it. Results and
  warnings print above it and stay in your scrollback. Ctrl+C stops the scan.
- **Everywhere else** (CI, the Action, a pipe, a coding agent), each stage's
  start and end is a timestamped line, with a heartbeat line at least every 30
  seconds, and no cursor movement or colour.
- **Every run writes a status file and a log** under `DATA_DIR/runs/<run-id>/`,
  and prints the run id when it starts.

**For scripts and agents:** wait on a scan with `concept-scanner status --wait`
rather than by watching the process list. It exits with the scan's own exit code
when the scan ends, and with 1 and a notice if the scan was cancelled, its
process died (reported as **stale**), or `--timeout` passed. `status --json`
gives the status as the usual envelope. `--progress jsonl` streams one JSON
event per line on stderr instead (run, stage, progress, model call, retry,
warning, error and heartbeat events), leaving stdout to `--json`.

## Requirements

- [Ollama](https://ollama.ai) running locally
- Enough RAM/VRAM for the chosen model. The picker flags profiles that exceed your
  detected memory; the **Fast** profile (`qwen2.5-coder:7b`) runs on most laptops.

## Privacy

Your code goes to the model you chose and nowhere else. This binary sends
nothing about you or your scans to us.

It opens exactly three kinds of connection, and the full list is in
`outbound_calls_test.go`, which fails the build if a new one is added without
being described here:

- **the model server you run**, for inference, downloading a model, the
  approved-model manifest, the pre-run residency check, checking the server is
  reachable, checking any `think` settings you saved against what each model
  accepts, and recording what the server ran a scan with;
- **the provider you chose**, when you run with `--provider openai-compatible`
  on your own key, for inference and that provider's model list;
- **GitHub's public releases page for this project**, for checking for a newer
  release: when you type `update`, and, only if you said yes to it, at most once
  a day when a scan starts. Nothing else contacts us, and nothing reports usage.

Unlimited scans, no per-call costs, when the model server is your own.

**Two things decide whether your code stays on your machine, and both are your
choice.** Pointing `--ollama-host` at a remote address sends the request there;
the scanner logs a warning at startup, and sends it anyway. Choosing an
OpenAI-compatible provider sends your code to that provider under their terms,
not ours. Run the model server locally and the code never leaves the machine.

## Contributing & community

- [TROUBLESHOOTING.md](docs/troubleshooting.md): common failure modes and recovery
- [CHANGELOG.md](CHANGELOG.md): what changed between releases
- [SECURITY.md](SECURITY.md) — how to report security issues privately
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — Contributor Covenant 2.1
- [patent-skills](https://github.com/Obviously-Not/patent-skills) — a sibling
  open-source project in the ObviouslyNot ecosystem (AI agent skills for patent
  scanning). A link for context, not a dependency: concept-scanner runs standalone.

## License

Apache-2.0 — see [LICENSE](LICENSE).
