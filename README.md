# Concept Scanner

> **This is a distribution repository.** It carries the documentation, the
> GitHub Action, and the released binaries. The source lives in a private
> repository and is not published here, so there is nothing to build or send a
> pull request against: every file here is generated from the source repo on
> each release and is overwritten by the next one. Bug reports and feature
> requests are welcome in this repo's issue tracker.

Local-first **engineering concept scanner** for codebases. Point it at a repository or directory and it surfaces distinctive technical mechanisms ("concepts"), scores them on four core engineering-quality axes (technical distinctiveness, implementation depth, problem specificity, generality) plus supplementary signals, and saves the results locally for you to review.

The JSON output is a draft format an importer can read, with a version on each record type, in engineering vocabulary only, with no legal-statute language. Legal review is a separate, downstream step performed by qualified humans.

By default all analysis runs against a local [Ollama](https://ollama.ai) model, so **your code stays on your machine**: no API keys, no cloud calls, no per-scan cost. You can optionally point it at a remote OpenAI-compatible provider (`--provider openai-compatible`), which sends your source to that endpoint; see [PROVIDERS.md](docs/providers.md). The only other request it makes asks GitHub for the latest release: when you run `concept-scanner update`, and, only if you have said yes to it, at most once a day when a scan starts. It sends nothing about you or your code.

## Use it in a window

Most people never need a terminal:

- **Mac:** download `concept-scanner-macos.dmg` from the
  [latest release](https://github.com/Obviously-Not/concept-scanner-public/releases/latest),
  open it, drag Concept Scanner to Applications, and open it from there. One
  download runs on Apple silicon and Intel Macs (macOS 12 or later).
- **Windows:** download and run `concept-scanner-setup.exe` from the same page.
  It installs for you alone, with no administrator prompt, and puts Concept
  Scanner in the Start menu.
- **Installed with the one-line install below?** Run `concept-scanner ui`.

For scans on your own computer, install [Ollama](https://ollama.ai) and open it;
the window's Settings says whether it is running.

The window opens in your browser. Choose a folder and scan it, watch it run,
review what it found, approve, reject or export it, and choose the model, or a
cloud provider and its key, in Settings. The scan screen's **Models for this
scan** card picks each model a scan calls, as the terminal's models screen does,
and says which ones the scan will download first. A suggested next step that
needs a value opens its command's form with the rest filled in. Every action is one of this program's
own commands, so a scan an agent starts appears in the window while it runs, and
a model or key you choose there is what a scan from a terminal uses. Closing the
browser tab leaves the window running; Quit stops it (or `concept-scanner ui
--stop`).

Reviewing a scan in the window is quicker from the keyboard: j and k move
between the concepts, and a, r and s approve, reject and skip the one in focus,
as A, R and S do in the terminal (a text field keeps its own keys). Select
several concepts to decide them in one step. A rejection can say why
(duplicate, routine, wrong location, inaccurate, or other with a note), which is
kept beside the scan and never exported. The **Held back** tab lists what the
gates held back, each with why, and records whether you think each hold was
right.

It runs on your computer only: it listens on 127.0.0.1, refuses requests from
any other machine or any other website, and hands your browser a secret once,
when it opens. The Mac app and the Windows install update themselves: Settings
shows a newer release, and **Install and restart** replaces the program after
its signature checks out. Uninstalling (Settings > Apps on Windows, the Trash on
a Mac) keeps your scans, settings and keys in `~/.concept-scanner`.

Installed both ways, the app and the one-line install? Those are two copies of
the program. Each updates itself, both read the same scans, settings and keys,
and opening the window from the newer one replaces an older one that is open
(unless a command it started is still running).

## Quick start

```bash
# 1. Install Ollama (https://ollama.ai) and open it, or run:
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
#    On the first run, setup asks Local (Ollama) vs Cloud. At a terminal,
#    on a local Ollama, the scan then opens on its models screen (each model
#    the scan calls, starting from the profile your machine's memory
#    recommends), downloads any the server lacks after saying so, then shows
#    what the project is for (read from its own documents), which folders it
#    would read first with their tokens and time, and asks before it starts
#    (see "Choosing a model" and "Reading part of a repository first").
concept-scanner scan ./my-project

# 4. Review the discovered concepts interactively
concept-scanner review <scan-id>

# 5. Export an approved concept as a JSON draft
concept-scanner export <scan-id> <concept-id>

# From a script or an agent: wait for a scan to end, and exit with its exit
# code. A scan not run at a terminal names this command, with its run id, in
# its first line.
concept-scanner status --wait <run-id>

# Later: check for a newer release. At a terminal it asks before installing,
# and it replaces this copy only after the release's signature verifies.
concept-scanner update
```

**Hearing about new releases.** After your first scan at a terminal, the scanner asks once whether it may check for a newer version when a scan starts, at most once a day. It is off unless you say yes, and it only ever tells you; installing is still `concept-scanner update` and your yes. Change it any time with `concept-scanner update --auto-check on` or `off`.

**Installing by hand.** Download the binary for your platform from the [latest release](https://github.com/Obviously-Not/concept-scanner-public/releases/latest) (`darwin-arm64`, `darwin-amd64`, `linux-amd64`, `linux-arm64` or `windows-amd64.exe`, or the Mac app's `concept-scanner-macos.dmg` and the Windows installer `concept-scanner-setup.exe`) and check it against `checksums.txt`. The Windows binary is signed (Microsoft Artifact Signing), and the macOS binaries are signed with a Developer ID and notarized by Apple. A bare command-line binary cannot carry its notarization with it, so the first time you run a macOS binary downloaded in a browser, run it from Terminal while online: macOS checks with Apple then. (Double-clicking it in Finder does not work for any command-line tool, signed or not; to double-click, use the Mac app.) See [TROUBLESHOOTING.md](docs/troubleshooting.md).

**Uninstalling.** Run the same script with `--uninstall` (macOS and Linux: `curl ... | sh -s -- --uninstall`) or, on Windows, `-Uninstall`: `powershell -ExecutionPolicy ByPass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1))) -Uninstall"`. It removes the program, the line it added to your shell's startup file or your PATH, and the extraction cache. Your scans, settings and any API keys you saved in `~/.concept-scanner` stay, and it prints how to delete them. The Mac app goes to the Trash, and the Windows installer's copy is removed in Settings > Apps; both keep `~/.concept-scanner` too.

**Shell completions:** `concept-scanner completion --help`.

Hitting an error or empty/thin output? See **[TROUBLESHOOTING.md](docs/troubleshooting.md)** for the common failure modes and how to recover.

## Running in Docker

Prebuilt images are published to GHCR and Docker Hub:

```bash
docker pull ghcr.io/obviously-not/concept-scanner:v4
# or: docker pull leegitw/concept-scanner:v4
```

The scanner runs against your **host Ollama**. Inside a container, `localhost` is the container's own loopback, not the host, so point `--ollama-host` at the host:

```bash
# macOS / Windows (Docker Desktop):
docker run --rm -v "$PWD:/workspace" ghcr.io/obviously-not/concept-scanner:v4 \
  scan /workspace --ollama-host http://host.docker.internal:11434

# Linux: add the host-gateway mapping (or use --network host):
docker run --rm --add-host=host.docker.internal:host-gateway \
  -v "$PWD:/workspace" ghcr.io/obviously-not/concept-scanner:v4 \
  scan /workspace --ollama-host http://host.docker.internal:11434
```

For a remote provider instead of host Ollama, pass `--provider openai-compatible --base-url ...` and the API-key env var. On OpenRouter the model defaults to the measured best-value option (see `concept-scanner models --cloud`); pass `--primary-model` to override. On any other endpoint pass `--primary-model` and `--secondary-model`; the scan asks for them before it sends anything. See [PROVIDERS.md](docs/providers.md). A remote scan shows its estimated cost before it spends; set `BUDGET_PER_OP`, `BUDGET_DAILY` or `BUDGET_MONTHLY` to stop one at a ceiling (see PROVIDERS.md).

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
      - uses: Obviously-Not/concept-scanner-public@v4
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

- **Local (Ollama)**: private; your code stays on your machine. Falls through to the
  models screen, or the memory-aware model picker, below.
- **Cloud (OpenAI-compatible endpoint)**: faster/larger models, but your source is sent
  to the endpoint. Shows a **cost/quality-ranked shortlist** and saves the model you pick
  for every later scan. Your API key comes from the environment, or is saved once with
  `concept-scanner init --with-key` (never as a flag; see "Settings, keys and where they
  live"). Concrete endpoints and model strings live in [PROVIDERS.md](docs/providers.md);
  `concept-scanner models --cloud` prints the same shortlist any time.

Explicit flags, `--no-interactive`, or a saved config skip the prompt entirely, so
scripted and CI runs are unaffected. A scan never prompts when a coding agent or CI
runs it, under `--json`, or with `TERM=dumb`: it uses the saved profile or the
defaults and says so. On a terminal the choices take the arrow keys and Enter as
well as their letters.

### Local model profiles

**At a terminal, a scan on a local Ollama opens on its models screen**, the first
of the setup screens (see "Reading part of a repository first" for the others).
It shows each model the scan calls (discovery, drafting, grading, and the second
model of a multi-model scan), starting from the profile your machine's memory
recommends, or from a model flag or your saved profile, and says which of them
the server does not have yet. You can switch profile or change any one model.
Continuing readies every one of them, downloading what is missing after saying
so, before the next screen. On a first run the choice is saved as your profile.

Where the screens do not run (a coverage flag such as `--intent`, a
`--progress plain` display), the first interactive run shows the
**memory-aware picker** instead; `concept-scanner init` always does. Both detect
your RAM and recommend a profile, flagging any option too large for your
machine. On Apple Silicon the picker also notes that MLX-optimized builds (an
`-mlx` tag) run faster and can be chosen via Custom. Your choice is saved in
`~/.concept-scanner/settings.json` in your home folder and reused on later
runs. Re-pick your **local profile** any time with
`concept-scanner init`, or save one with no questions with
`concept-scanner init --profile <key>`. To use a cloud provider for every command,
save it once: `concept-scanner init --provider openai-compatible --base-url <endpoint>/v1 --model <model>`,
and its key once: `concept-scanner init --with-key` reads it from stdin and keeps it for that endpoint's host only.
A flag given to any command still wins over what is saved, and `concept-scanner init --json`
shows what is saved and which environment variables are in force.

Each figure counts every model a profile's scans call, the grader included,
and is rounded up to the next whole GB. Every profile grades its concepts (Pass
2) with `gpt-oss:20b`, which is why Fast needs 17 GB although its own discovery
model is much smaller; `--skip-review` leaves the grader out. Which profile
is recommended is your machine's answer: the picker, the models screen and
`models` mark it. A 32 GB machine is recommended Fast, since Balanced's 23 GB
is more than 70% of its memory; Balanced is still yours to choose.

| Profile | Model(s) | Approx. RAM | Notes |
|---------|----------|-------------|-------|
| **Fast** | `qwen2.5-coder:7b` | ~17 GB | The smallest discovery model; its grader, `gpt-oss:20b`, sets the memory it needs |
| **Balanced** | `qwen3-coder:30b` | ~23 GB | Best capability/size ratio |
| **Validated** | `qwen3-coder:30b` + `gpt-oss:20b` | ~39 GB | Both models read every file and each draws up its own list of concepts, and the two lists are merged with where they agree recorded in `agreement.json` (`--multi-model`), with each file's outcome, where your code was sent, and any step that degraded. Pass 2 validation runs at every profile, not only this one |
| **Thorough** | `qwen3-coder-next:latest` | ~52 GB | Larger MoE model; its speed against Balanced has not been measured at current settings |
| **Custom** | any Ollama tag | depends on the model | Type your own model |

**Speed, from recorded scans on one machine.** Fast is not reliably faster than Balanced: Balanced took 1.4 and
1.25 times Fast's time on repositories of 8 and 19 files, and 0.79 times on one of 258 files, where Fast was the
slower. The larger model finds about one and a half times as many concepts per file, and Fast's fewer concepts
each cost more. Validated took 72 and 84 minutes on a 12-file repository of about 45 KB, where Balanced takes about
21. A scan's time follows its bytes and the concepts it finds more than its file count, so expect these ratios to
move with your repository.

**Your repository's time, beside each profile's memory.** The models screen says how long a scan of the whole
repository you are about to scan takes with each profile's models, priced as a dry run prices a read: from this
machine's recorded calls, or before it has any, from a starting estimate set high on purpose, which it says.
`concept-scanner models --workspace <folder>` gives the same times in its table and as each profile's `time` under
`--json`, and the window's models card shows them for the folder in the scan form; the first-run picker a scan
shows where the setup screens do not run says them too. Where a profile has a time, it is that profile's speed; the
ratios above are what is left where there is no repository to price.

Model resolution precedence: explicit flags (`--primary-model` / `--multi-model`) →
the saved profile in `~/.concept-scanner/settings.json` → interactive picker (TTY only) →
built-in defaults. At a terminal where the setup screens run, the models screen
opens on that choice and the scan calls what you leave it on. To run
non-interactively (CI, scripts), pass `--no-interactive` with `--primary-model`:

```bash
# Use a specific installed model, no prompts (works single-pass or multi-model)
concept-scanner scan ./my-project --no-interactive --primary-model qwen2.5-coder:7b

# Two models in parallel with a merge step
concept-scanner scan ./my-project --multi-model \
  --primary-model qwen3-coder:30b --secondary-model gpt-oss:20b
```

**Every model a run calls is ready before its first call.** Each command that
calls a model asks the server about every one of them first: a local Ollama
server that lacks one gets it downloaded, after one line naming each model
about to be downloaded, the flag that chose it, and, where the model registry
records it, about how much it is; on a
remote endpoint each model is checked against its catalog instead. Only then is
anything sent. `--no-auto-pull`, which every command that calls a model takes,
refuses the run instead, naming every missing model at once. A scan that shows
no setup screen or start-up card (an agent's, CI's) prints one `Models:` line
naming each model it calls, the flag that chose it, and the server. If Ollama is
not answering, the message says which of four things is true: Ollama is not
installed on this machine, it is installed and not running, the address is
another machine's server, or the run was on an OpenAI-compatible server, which
`ollama serve` does not start.
Any installed Ollama model is accepted; unrecognized tags get a one-line note and run as-is.

## How it works

1. **Collect** source files (skipping `vendor`, `node_modules`, `.git`, etc.).
2. **Validate** the target before scanning: a symlink that escapes it or a device file refuses the scan (remote clones also get repository size / file-count caps), and a `.zip` that would expand like a zip bomb is named in a note and left unopened, as every archive is.
3. **Distill** each file with Principle-Based Distillation (PBD) via the local model.
4. **Discover** candidate concepts.
5. **Locate, then characterize.** A concept whose cited file did not resolve is first located (a path the model mangled is corrected, a location listing several files takes the first that exists, and the model is asked which candidate file holds it), so a concept only that step can place is still characterized. Each concept is then scored on the four core engineering axes (technical distinctiveness, implementation depth, problem specificity, generality) plus supplementary signals (commonness, paradigm-shift). An axis the model did not score is `null`, never 0, and the text output says "not scored". Of the commercial axes, defensibility is emitted as `null`: concept-scanner doesn't have your market context, so whatever reads the drafts next (your review process, or the app that imports them) fills it in. Product-centrality is `null` too unless Pass 5 ran over the concept (below), which writes the centrality it judged; whatever reads the drafts next fills a `null` and keeps a value. The output also carries the concept's key insight, inputs/outputs, components, and comparable techniques. A characterized concept still missing a field it requires (its category, technical approach, key insight, inputs and outputs, or components and how they interact) after the scanner has asked the model for the missing fields once more is held back (`required_field_missing`) rather than shipped incomplete.
6. **Combine** concepts (Pass 3): combinations of concepts that work together, scored for how well they do. This is where a scan finds how its parts are arranged. It runs by default when inference is not billed per token (Ollama, wherever it runs, or an OpenAI-compatible server on this machine); `--no-combinations` skips it, and `--combinations` runs it against a hosted endpoint too, which a default never does because those calls are paid. Each combination says whether its own text claims a feedback loop (`asserts_feedback_cycle`); that describes the text, not a check of the code. Pass 3 asks the model about the top candidates by graph score (how strongly two concepts share a folder, complementary categories, components, or one's output feeding another's input), with a share kept for combinations of three or more concepts and a penalty for concepts already chosen. Each combination carries its candidate's `graph_score` (0 to 1, the share of the most a pair can score) and `candidate_rank` (from 1), and every candidate it asked about and did not ship is a row `held <scan-id>` lists with its score and rank: one the model declined, one scored below the synergy floor, an answer missing its name, its synergy or enough of the candidate's concepts, a call that failed, and one folded into a near duplicate.
7. **Find patterns** (Pass 5, `--patterns`): read the shipped concepts for product-level patterns, the ones that, taken together, say how the product is put together, each scored and named by the concepts it rests on. It is off by default; `patterns <scan-id> --workspace <path>` runs it over a stored scan without scanning again. Each concept it reads carries the centrality it judged, its `product_centrality` (`null` when no answer judged it), and a later `patterns` run's value replaces it in the stored scan, where `export` reads an exported concept whose value changed as one to export again. When the model answers its request for a list of combinations with one combination, that one is kept and the run says so in its closing lines and its notice, since the model may have found others it did not name.
8. **Enrich** with dependency-license risk and git authorship: `git blame` over the lines of the declarations a concept's own text names. The summary's **Authorship** line says how many concepts carry contributors and why the rest carry none (no declaration named, a file in another language, a folder git does not track, `git blame` failing at the scan's commit, ...), with a count for each.
9. **Save** results under `~/.concept-scanner/data/scans/` whatever folder you run from, the run's summary (`summary.json`: what it found, shipped and held back, what it read, the models it called, where its code went, what it cost and how long it took), a `SUMMARY.md` that opens with that summary and lays each concept out like a specification (and is written again when a review decision or a figure changes its concepts), and a provenance audit log under `~/.concept-scanner/data/audit/`. Set `DATA_DIR` to keep them somewhere else; the container image and the GitHub Action keep them in the scanned repository's `data/` folder.

A stage the scan did not run, or ran capped (Pass 3 or Pass 5 not asked for, Pass 4 with no documentation to read, Pass 3 asking about only part of its candidates), and each kind of file it left out that a flag reads, is named in the summary under **Not run or capped**, with why and the flag or command that changes it: `combine <scan-id>` and `patterns <scan-id> --workspace <path>` run Passes 3 and 5 over the stored scan, and the scan offers each as a next step.

A file larger than the read cap (`--max-file-size-bytes`, 102,400 bytes built in) is collected and not read. The summary's **Coverage** line, which is also the `--json` notice's account of the run, names each such file, largest first, with its size and the `--max-file-size-bytes` value that reads it, and says apart the files that did not fit a discovery call's share of the model's window; `files_dropped_too_large` counts them on both scan paths.

Generation that hits its token cap **fails loud** rather than silently truncating, and all
emitted text passes an output-layer check that keeps legal-statute vocabulary out of the results.

## Commands

| Command | Purpose |
|---------|---------|
| `scan <path-or-url>` | Scan a directory or remote repo for concepts; with `--resume <run-id>` the path may be left out, and the stopped run's is used |
| `review` | List the stored scans as scan histories, by the id to review each with, with their passes, counts, and the file-set flags a read of more files repeats |
| `review <scan-id>` | Step through discovered concepts and approve/reject; those awaiting a decision come first, then `--sort score` (the default, strongest first) or `--sort file` |
| `figure draw <scan-id> [concept-id]` | Draw a concept's figure (or `--all`) with your primary model: a small graph of how its components connect, stored in `figures.json` beside the scan (see "Figures") |
| `figure apply <scan-id> <concept-id>` | Correct a figure by hand: `--rename`, `--remove` and `--add` change the concept's components; `--edge c1>c4=label` draws an arrow between two of them |
| `export <scan-id> <concept-id>` | Export an approved concept (or combination) from that scan as a JSON draft in the shape the importer reads; over a scan history, name a concept with its pass as `<pass-id>/<id>`, as `review --set` does |
| `show <scan-id> <concept-id>` | Say where a concept lives: the file on this machine, its lines and the declarations they cover, the commit and branch of the pass that found it, whether the file has changed since, and a link to it at the scanned commit on GitHub, GitLab or Bitbucket; `--open` opens it at its lines in your editor, `--web` opens the link (see "Opening a concept's code") |
| `locate <scan-id> --workspace <path>` | Look again for the file of each concept whose location is unconfirmed, on a completed scan (`scan` does this automatically; this re-runs it after model/prompt changes) |
| `combine <scan-id>` | Find combinations of concepts that work together across subsystems (Pass 3) over a completed scan; given the first scan of a scan history, over every pass its review shows, so a combination can join concepts two passes found. A re-run keeps every stored combination and its decision and numbers new ones after them, and asks only about member sets no earlier run over the scan, its scan history or a scan it continues asked about (the stored combinations, and the candidates `held` lists, a candidate whose call failed excepted, whose row the re-run's outcome replaces), so a skipped candidate uses none of `--combination-max-candidates`; a run at a larger cap adds to the last and is not a superset of it. A run that finds none, or asks about only part of its candidates, says why from its own numbers and leads with the command that changes it. `--dry-run` counts and prices the calls it would make (one a candidate, less those asked before, and under `--workspace` the characterization first) and makes none |
| `patterns <scan-id> --workspace <path>` | Find product-level patterns (Pass 5) over a completed scan, or over every pass of a scan history given its first scan: which of its concepts, taken together, say how the product is put together. `--workspace` is the folder the scan read, where its README and architecture documents are; it reads them with the file set the scan recorded. `--dry-run` counts and prices its calls (the load-bearing calls as a range, its combination call and its scoring call) and makes none |
| `models` | List the recommended model profiles, every model each one's scans call and what each does there, and which the server already has; the profile this machine's memory recommends is marked. Given the scan's model flags (`--primary-model`, `--draft-model`, `--secondary-model`, `--multi-model`, `--skip-review`, `--thorough`) it also says which models a scan given them would call, what it would download, and the `init` arguments that save that choice. With `--workspace <folder>` each profile also says how long a scan of the whole repository there takes with its models, beside its memory |
| `models describe <model>` | Save what a model is for one endpoint: the window its server applies (`--window`, or `--measure` on a server on this machine), its largest answer (`--max-output`) and its think value (`--reasoning`); every later run on that endpoint uses it |
| `bench` | Measure whether your model server actually runs requests in parallel |
| `tiers run` / `tiers report` | Run one scan per model profile over one corpus and report what each produced |
| `held <scan-id>` | List what the quality gates held back, and every candidate combination Pass 3 asked about and did not ship, across every pass of a scan history, each with why, who the verdict points at, and the ref `--set` names it by |
| `held <scan-id> --set <ref>=right` | Record whether a hold was right (`right`, or `wrong` when the concept should have shipped, repeatable), with `--note` to say why; only a concept a gate held back takes one |
| `review <scan-id> --why <concept>` | Say why one concept was held back: the gate, what it measured, and how the number it failed was set |
| `review <scan-id> --set <id>=approved` | Record a decision without a prompt (`approved`, `rejected` or `skipped`, repeatable), for a script or an agent; it can change an earlier one, and `--json` reports the new tallies. Over a scan history, name a concept with the pass that found it: `<pass-id>/<id>`. `--reason` says why the rejections it records were made (`duplicate`, `routine`, `wrong-location`, `inaccurate` or `other`), with `--note` in your own words; it is kept beside the scan, never exported, and a later decision without one clears it |
| `status [run-id]` | Show what a scan is doing, or `--wait` for it to finish; `--running` lists every run in progress (see "Watching a scan"). For a scan strict Pass 2 stopped it offers the resume command, or says why it offers none (`resume_refused`) |
| `anchoring-check` | Check whether a model is repeating the prompt back rather than reading the code |
| `help --json` | Every command, argument and flag, with types, defaults, allowed values, what each argument names, and the rules between flags the commands enforce: the catalog a program can build forms or tool definitions from; a flag that sets a value a person can change carries a `setting` (its key, area, what it bounds, built-in value and range) |
| `ui` | Open the window: this program in your browser (`--stop` quits it, `--serve` runs its server in this terminal and opens no browser) |
| `init` | Choose the model, the provider and the advanced settings every command uses: the memory-aware picker, or `--profile <key>` (with `--secondary-model` for a grader of your own, and `--multi-model` for a two-model profile), or `--provider openai-compatible --base-url <url> --model <id>` with no questions; `--<key> N` saves an advanced setting and `--budget-<name> N` an output budget; `--reset <key>` or `--reset all` removes them (a key this version does not know is removed only by name); `--json` shows what is saved, every adjustable value included |
| `version` | Print the version and default models |

## Useful flags (`scan`)

| Flag | Description |
|------|-------------|
| `--primary-model` / `--secondary-model` | Choose the model(s) explicitly (any installed Ollama tag) |
| `--profile <key>` | Run a model profile's models by its key (`fast`, `balanced`, `validated`, `thorough`): it stands for the model flags the models screen writes for it, which the scan's record and every step it prints repeat. A model flag given beside it keeps its own value; `--primary-model` beside it is refused |
| `--multi-model` | Run two local models in parallel and merge results |
| `--no-interactive` | Skip the first-run picker; use saved config or defaults (for CI/scripts) |
| `--skip-review` | Single-pass only: skip the Pass 2 validation model (faster), so the grader is neither called nor downloaded |
| `--thorough` | Use the larger, higher-quality model |
| `--include-textbook` | Also emit what the quality gates hold back by default: concepts characterization scored below the minimum distinctiveness score (`characterized-min-score`), whether or not they were classified `textbook` (see below) |
| `--combinations` / `--no-combinations` | Pass 3, which finds combinations of concepts, runs by default when inference is not billed per token (Ollama, wherever it runs, or an OpenAI-compatible server on this machine); `--no-combinations` skips it, and `--combinations` runs it on a hosted endpoint too |
| `--patterns` | Run Pass 5 after the scan, which reads the shipped concepts for product-level patterns. Off by default; a scan that does not run it names `patterns <scan-id>` in its summary and as a next step |
| `--two-phase` | Experimental. Run generation as two calls (freeform distill, then structured extract) instead of one grammar-constrained call (see "Two-phase generation" below). Also settable via `CS_TWO_PHASE=1`. |
| `--extract-model` | Phase-2 extraction model for `--two-phase` (default `gpt-oss:20b` locally and the Pass 2 model on a remote provider). Also `CS_EXTRACT_MODEL`. |
| `--timeout` | Per-request inference timeout (default 10m; under `--two-phase` at least 30m, a smaller value being raised, except for `--multi-model`'s own extraction, synthesis and merge calls, which take the value as given). A request that reaches it is sent at most twice in all, by the client, and no later stage sends it again; the error then says how many sends timed out. Raise for slow models or large batches. |
| `--no-locate` | Do not look for the file of a concept whose cited file did not resolve (faster; such a concept's location stays unconfirmed rather than found or confirmed missing, and a concept only this step could locate is then not characterized) |
| `--characterize-docs` | On a repository that is not docs-only, also characterize and gate its documentation concepts as code concepts are, so they ship as concepts (one characterization call each). Without it they are context for documentation matching only. A docs-only scan characterizes its documents anyway. The setup screens offer the same choice, saved for the repository |
| `--resume <run-id>` | Carry on a scan that strict Pass 2 validation stopped, from that run's `unfinished.json`: discovery and every batch Pass 2 finished are re-used and the rest is run, as a new scan. The repository may be left out, and the stopped run's is used. What is compared is what the run used, never how its flags were spelled: the files collected, each by its content, whether Pass 3 runs, each model and its weights, every value that differs from its built-in one, and a remote endpoint's address. The resume is refused, with the reason, when any of those or this program's version changed since (timeouts, retries, how the run is shown and the spend ceilings may change). A scan started on the setup screens is resumed too: its record holds the flags that make the screens' choices, with the plan they chose saved under the scan's id in your home folder. The stopped run's error, `status` and the window's Resume card give the exact command |
| `--tests` | How test files are used: `off` (default), `evidence` or `source` (see "Tests as evidence"). Also `CONCEPT_SCANNER_TESTS`. `--include-tests` is the older spelling of `--tests source`. |
| `--no-auto-pull` | Refuse the run when the local Ollama server lacks a model the run calls, instead of downloading it, naming every missing model at once with the flag that chose it. Every command that calls a model takes it |
| `--no-semantic-batching` | Disable PBD-guided semantic batching (use size-based batching only) |
| `--max-file-size-bytes` | The read cap: the largest file, in bytes, a scan reads (102,400 built in; `init --max-file-size-bytes N` saves another). A larger file is not read, and the plan, a `--dry-run` and the run's summary name each one with its size and the value that reads it. Raised, a file larger than one discovery call is read in parts, and characterization is sent the part a concept came from when the whole file does not fit; a `--multi-model` scan sends each file whole to each model, so there a file too long for each model's window is not read, and a model with a larger window reads it |
| `--depth` | How many files may share one discovery call, from 1 to the depth ceiling in force (4 built in; `--depth-ceiling` changes it, or `init --depth-ceiling N` saves it), or 0 to work it out from the file sizes, aiming at about two per call, which is the default. The `Depth:` line each scan prints says which of the two it was, and a number above the ceiling is refused before the scan starts, naming the range. Not available with `--multi-model` or a saved multi-model profile, which have no discovery batches |
| `--allow-external-symlinks` | Allow symlinks pointing outside the repository (skips symlink-escape validation) |
| `--ollama-host` | Ollama API URL (default `http://localhost:11434`) |
| `--local-only` | Refuse to run unless the model server is on this machine (`localhost` or a loopback address), judged from its host, and refuse a model a local Ollama runs on another machine, before anything is sent; give it on every run, since it is never saved. See [PROVIDERS.md](docs/providers.md#privacy) |
| `--parallel-batches` | How many requests a run keeps in flight. By default one at a time against a model server on this machine (`localhost` or a loopback address) and 4 against a remote endpoint; a value you give, or save with `init` (whose picker asks for one, opening on that same rule and saving a number only when you change it), holds wherever the server is. The model server serves as many at once as it has slots (Ollama's `OLLAMA_NUM_PARALLEL`, default 1) and queues the rest, so on a default server more is not faster. On a server with several slots, concurrent requests share the work and a scan is then **not byte-reproducible** run to run; one at a time is the setting at which a scan on this machine was measured repeating its discovery answers, though a model's answers are not guaranteed to repeat and a classification label can still differ. `models.json` beside each scan records the server's slots when the server runs on this machine and its log can be read. A scan run one at a time also reuses the answers of earlier scans to identical discovery requests (see "Reusing discovery answers") |
| `--verify-cache` | Ask every discovery request again instead of reusing its stored answer, after unloading the model, and report whether each stored answer reproduced; one that did not is removed and counted, the rest of the scan asks every request again rather than reuse one, and the scan still exits 0, since a model's answers are not guaranteed to repeat. A scan in which the cache is off (see "Reusing discovery answers") checked nothing, so it exits 1 and says why |
| `--full-history` | Fetch full git history for richer file provenance |
| `--json` | Machine-readable `{ data, next_steps, notice }` envelope (see "Machine-readable output") |
| `--progress` | How the run is shown on stderr: `auto` (default), `live`, `static`, `plain` or `jsonl` (see "Watching a scan"). Also `CONCEPT_SCANNER_PROGRESS`. |
| `-v, --verbose` | Detailed progress output, and at the end why each concept held back was held back (the same text as `review --why`) |

Run `concept-scanner scan --help` for the complete list.

## Reading part of a repository first

A large repository can take hours to scan whole. A scan can instead read the
part closest to what the project is for first, and read more of it later.

**At a terminal**, with none of the flags below, setup screens come before the
scan: on a local Ollama the models screen first (see "Choosing a model"), then
these three. On a remote provider its models are chosen with the provider
(`init`, or the window's Settings), so the three come alone.

1. **Intent.** The scanner finds the project's own documents without a model
   (the README, other top-level Markdown, the package description, entry pages
   under `docs/`, the Go package comment) and asks your model what the project
   is for and which behaviours the documents say it has. A behaviour is kept
   only with a quote of at least ten characters found in the document it
   cites. You can edit the purpose, untick a behaviour, or add your own.
2. **What to scan.** The model names the files and folders most likely to
   implement each behaviour, and the scanner ranks every file outward from
   those along the code's dependencies and its folders. The screen lists the
   folders in that order, grouped by the read that takes them (the first read,
   the second read), with their tokens, and the
   time discovery is expected to take. `+` and `-` move the share read first,
   which opens on the suggested first read: as many files of the repository's
   average size as your model profile is set to read at a time (12 on
   Balanced, set from recorded scans of small repositories for about half an
   hour; `init --suggested-read-files-balanced N` changes it), as a share of
   the bytes rounded up to 10 points, or every file when the repository holds
   no more; the screen says how many files that share holds. Space pins a
   folder in or drops one out.
3. **Ready.** What will run, with its tokens and time, and the command that
   would run the same plan without the screens.

Everywhere else (a coding agent, CI, `--json`, `--no-interactive`,
`--progress plain`) a scan reads every file, as before, unless it passes:

| Flag | Description |
|------|-------------|
| `--intent "..."` | The project's purpose, typed. It ranks which files are read first and is never sent to the scan's own prompts. |
| `--intent-file <file>` | The purpose from a file: plain text, an `intent.json` from an earlier scan, or a saved plan (which needs no model call to place it, and keeps its pinned and dropped folders). |
| `--intent-from-docs` | Read the project's documents and ask the model for its purpose, without review. |
| `--coverage <pct>` | The share of the scannable bytes to read, 1 to 100. Below 100 it needs one of the three above. |
| `--time-budget <duration>` | Read the largest share whose estimated time, at the high end of its range, fits the budget (`2h`, `90m`), outward from the purpose as `--coverage` reads. It needs one of the three above, cannot be given with `--coverage` or `--changed`, chooses before the scan starts and never stops a running one; the plan says the share it chose and what the next would take, and a budget no read fits is refused, naming the smallest read and its estimate. A `--resume` reads the share the stopped run chose, with the same budget. |
| `--pin <glob>` | Always read files matching this glob in the first read (repeatable). A pin that pins no file is warned of with why, and the scan runs: a file over the read cap (with the `--max-file-size-bytes` value that reads it), a file dropped from the scan history or left out of the scan (an `--exclude`, `--only`, a test file, the documents mode), a folder a scan skips on the way to it, or no such path. The saved plan and `arc.json` record each pin's outcome under `pin_outcomes`. |
| `--drop <path>` | Leave this exact path out of the scan and of every later read that continues it: a file, or a folder and everything in it (repeatable). The flag form of a drop chosen on the setup screens. |
| `--behaviour <text>` | A behaviour the project has, beside the purpose `--intent` states (repeatable, up to 8); the files implementing each are read first. Needs `--intent`. |
| `--after <scan-id>` | Read more of the repository after an earlier scan: only files no scan in its history has read, in the same order. `--coverage` is then the total share, by default what the history has read and the suggested read of more files: as many more files of the repository's average size as the model profile reads at a time, or every file once no more are left. A file edited since it was read is listed, not read again. If a later read already continues the scan you name, this read starts a second branch beside it, reading again what that read read: the plan (and `--dry-run`) says so, with how many of its files the other branch read and the `--after` that continues that branch instead. If the earlier scan's coverage record sits in a data folder inside the repository, or inside any git checkout, and this machine has no record of writing it (the container image and the Action keep scans in the repository), it is not trusted: the scan reads every file instead, as a first scan that continues no scan history, and says so. |
| `--dry-run` | Show every read this scan and each read of more files after it would make, with its files, tokens and time; save the plan; read nothing with the model. It also says how much to read first for the repository's size and your model profile (`suggested_coverage` under `--json`), and its next step plans that read. |
| `--changed` | With `--after`, re-read the files of that scan history whose contents have changed since it read them. It re-runs the whole discovery call that held each one, not the file alone, because a file read on its own is a different question from the one that produced its concepts. A file git can see was RENAMED with its content unchanged keeps its concepts' answers and is followed to its new path, in this pass and every later one, with no call (`--rerun-pure-renames 1` re-runs the calls that held it instead), and a `--changed` pass with nothing else to re-read is refused, naming the move; a renamed file that was also edited is re-read like any changed file. One that is GONE retires its concepts. |
| `--with-dependents` | With `--changed`, also re-read the files that depend on a changed one (direct only, at most 50). Their own contents have not changed, so their concepts are not treated as out of date. |

Every path flag (`--pin`, `--drop`, `--exclude`, `--only`, `--keep-dir`) reads
a path the same way: relative to the repository's root (a leading `./` and a
trailing `/` change nothing, and `./` alone means the files at the top),
without its letter case, naming a file or a folder and everything in it. A
glob flag's value is also matched at every folder level, so `--exclude
README.md` leaves out every README; one holding `*`, `?` or `[` that names a
real file or folder, such as `src/app/[slug]/page.tsx`, matches only it. A
value that is absolute, leaves the repository or is not a glob that can be
read is refused before anything runs.

A plan, and a `--dry-run`'s notice and saved plan, also name the files over
the read cap, which no read at that cap takes (`oversize` in the saved plan
and `arc.json`, largest first), with the `--max-file-size-bytes` value that
reads them.

Each such scan writes `intent.json` (where the purpose came from, what was
kept and dropped, and why) and `arc.json` (which files were read, the rank of
every file, the scan history, and the estimate beside what the run took) beside the
scan, and its summary and `--json` notice say that it read part of the
repository; every scan result's `coverage` says how much of the repository it
read and which scan history it belongs to. What you chose on the screens is kept per repository in
`~/.concept-scanner/repos/` in your home folder, never in the data directory,
so a later scan of the same repository opens on the ready screen and can read
more after the last one.

After a read of more files, the scan says how much of the repository its own
branch of the scan history has read and how much every branch has read
together: `This branch has covered 40% of the scannable bytes so far (...);
every branch of this scan history together 55%`. `arc.json` records the same as
`repository_share` (what every pass of the history has read, on every branch)
and `reread_share` (what this pass read that an earlier pass had read), so the
passes' `achieved_share` less their `reread_share`, summed, is the last pass's
`repository_share` while the repository's scannable files stay the same. A pass
on another branch whose record could not be read, or is not trusted, is named in
`peers_not_read` and left out, and the line then says the branches together
have read at least the share it gives.

Time estimates price each stage the scan will run (a stage its flags remove is
left out) from this machine's earlier calls of that stage with that model, said
as rough while fewer than 20 calls back it. Before this machine has any, a stage
is priced from starting rates taken from scans recorded on another machine, set
high on purpose, and the figure says so; this machine's own calls replace them
stage by stage, and `init` changes a starting rate (`init --json` lists them).
A stage that cannot be priced yet is named and the whole figure says "at
least"; one whose calls are larger than any recorded says it is extrapolated.

**Reviewing a scan history.** Give `concept-scanner review` the id of your
FIRST scan and it reviews every pass that continued it, saying so: `union of 3
passes, 41 concepts (38 current, 2 stale, 1 retired)`. You do not need the
other passes' ids. Two reads of more files after one scan are two branches, and
both are reviewed. A concept found more than once, by two branches or by a later pass
that re-read its file, is shown once: the same file, and either the same name or
the same two or more code symbols named in its description, which is how a
concept a model renamed between passes is still recognised. A pass the review
leaves out is named, with why, under NOT SHOWN.
Each decision is saved against the pass that found the concept (and against
every branch's copy of it), so re-running an earlier pass cannot undo it. A concept whose file
changed since it was found shows STALE with the two content hashes, unless a
later pass re-read the file and found it again, which makes it current; one
whose symbols are no longer in that file shows RETIRED with the names that no
longer resolve, as does one naming no code symbol that a re-read did not find
again. Both can still be approved and exported, and `export` names the state
rather than refusing: those are disclosures about a concept's evidence, not
verdicts on whether the mechanism exists. A concept whose file was renamed
shows MOVED, and `review --json` and `export` give it at the path the file has
now. A concept the store cannot load is
reported as INCOMPLETE rather than quietly left out.

The combinations of every pass the review shows are reviewed too, after the
concepts, awaiting a decision first and then the strongest synergy first (a
combination has no file, so `--sort file` orders them the same way). Over a
scan history a combination is named with the pass that holds it, as
`<pass-id>/<id>` (every pass numbers its combinations from `b001-`), and a
decision on it is saved against that pass. `combine` and `patterns` given the
first scan read the same passes, so a combination or a pattern can join
concepts two passes found; what they add is saved in the first scan, and a
concept a later pass retired is left out of both, which each says. Every
member of a combination and every concept a pattern names is written
`<scan-id>/<concept-id>`, naming the scan that found it, in the output, in the
stored scan and in an exported draft.

## Concept output and grounding state

Concept descriptions (`summary`, `technical_approach`, `components`) are
**engineering observations to verify against the cited code, not final
findings**. They can misstate the code they point at, so every concept ships with
`review_status: pending` and a `location` to check. Treat a description as a
pointer to review, not an authority; the `review` command exists for exactly that
pass.

Each discovered concept ships with a `grounding` field that records how the
scanner verified its `location.file`:

| State | `grounding` | Meaning |
|-------|-------------|---------|
| location verified | `grounded` | The path the model emitted resolves to a real file in the workspace as-is. |
| location corrected | `repaired` | The model emitted a malformed path that the finalize-pass automatically fixed (e.g. `src/foo.ts` → `app/src/foo.ts`), or a location listing several files, of which the first that exists was taken (the list is kept in `grounding_original_file`). |
| location found | `rescued` | A fuzzy basename search, or a model call asking which candidate file holds the concept, found the real file the concept actually lives in. The original LLM-emitted path is preserved in `grounding_original_file`. |
| file missing | `file_missing` | The concept named a file that exists nowhere in the workspace, and no file could be found for it anywhere: most likely a hallucination. A concept that named no file is never `file_missing`, since nothing it cited is missing. |
| uncertain | `uncertain` | The model was asked which file holds the concept and wouldn't commit either way. |
| location unconfirmed | `pending` | Not verified: looking for the file was skipped (`--no-locate`), every call that looked for the concept's file failed, or the concept named no file and there was nothing to search for it with or no file holds any of its terms. |

`file_missing` and `uncertain` concepts are held back rather than shipped (the
scan counts them as `ungrounded_dropped`, and `held <scan-id>` lists them).
A concept whose location is unconfirmed ships, unverified and, with no file to
read, not characterized; treat it with skepticism.

Every scoring axis is a number when the model scored it and `null` when it did
not: a 0 is a score, never a stand-in for a missing one. The text output and
`SUMMARY.md` say "not scored" for a concept no axis scored, and `SUMMARY.md`
lists such concepts in a section of their own.

A concept's `location.start_line` and `end_line` are the lines of the
declarations its own text names in the file it cites, read from that file after
every model call: no model is shown a line number or asked for one, and a range
a model writes anyway is discarded and counted (`line_ranges_zeroed`). They are
`null` when the concept names none of the file's declarations, or cites a file
in a language other than Go, TypeScript, JavaScript and Python (Go's are read
from its syntax tree, the other three's by pattern, checked against
tree-sitter); `provenance.lines_from` names the declarations they cover and how
they were read. A concept
naming declarations more than 200 lines apart is given the first function or
method it names, or its first declaration when it names none
(`--lines-max-span`). `provenance.description_grounding` says whether the
code-shaped names its description gives appear in that file (`grounded`,
`partial`, `absent` or `not_covered`), which is a different question from
`grounding`: that one says only that the file exists. `grounding.json` beside
the scan says how each concept got its lines, or why it has none.

### Opening a concept's code

```bash
concept-scanner show <scan-id> <concept-id>
concept-scanner show <scan-id> <concept-id> --open
concept-scanner show <scan-id> <concept-id> --web
```

`show` says where a concept lives and opens it. Without a flag it prints the
file and its absolute path on this machine, the lines and the declarations they
cover, the commit and branch of the scan pass that found the concept, whether
the file has changed since that scan (by the hash recorded when it was read),
and a link to the file at its lines on GitHub, GitLab or Bitbucket. The link
names the scanned commit, so a commit you never pushed is not there yet, which
`show` says; it also says when the file had uncommitted edits when the scan read
it, or the checkout moved to another commit while the scan ran. A file the scan
history followed through a rename is shown at the path it has now, with the
commit of the pass that saw the rename, which is also what `export` sends.

`--open` opens the file at its lines in the editor you saved, or else in the
system's text editor (TextEdit on macOS, Notepad on Windows), never in the
system's default application, which can run what it opens. Linux has no text
editor of that kind, so there save one first. An editor is its program and then
each argument, one per `--editor`, naming the file with `{file}` and the line
with `{line}`:

```bash
concept-scanner init --editor code --editor -g --editor '{file}:{line}'
concept-scanner init --editor vim --editor '+{line}' --editor '{file}'
concept-scanner init --editor idea --editor --line --editor '{line}' --editor '{file}'
```

The program is found on your `PATH` when you save it and kept as a full path;
`init --reset editor` removes it (`init --reset all` keeps it). Only a source or
documentation file inside the repository the scan read is opened, and only for a
scan this machine recorded; a scan of a URL keeps no copy of the code, so only
`--web` opens it. In the window, each concept's card has **Open in editor** and
**View on the host**, shown only where each can run, and the review key `o`
presses Open in editor.

## Figures

`figure draw` asks your primary model, once per concept, for a small graph of
how the concept's own components connect, and stores it with its Mermaid source
in `figures.json` beside the scan. Each box in the figure cites a component by
its number (`c1` is the first entry of `components`); a box that cites none is
drawn dashed and counted, so a figure cannot pass off a box the model added as
one of the concept's own components. A figure is a drawing to check a concept against: nothing in
a scan reads it.

`figure apply` corrects one. Renaming, removing or adding a component writes it
back to the concept's `components`, so `export` exports the correction; give
`--interaction` with new prose too, or the figure is marked `prose_unedited`. An
arrow you draw between two components (`--edge c1>c4=feeds`) is exported with
the concept as `component_edges`, `{"from": "c1", "to": "c4", "label": "feeds"}`;
an arrow touching a dashed box stays on the figure. The arrows the model drew
are never exported. The window shows each figure in its review screen, with the
same corrections, and asks before a redraw discards arrows you drew.

A concept you have already exported can be exported again after a correction:
`export` writes the draft once more and the importer reads it as an update to the
draft it holds. A second export with nothing changed is refused and says so.

A figure draws 2 to 12 components, so a correction is refused where it would
take the count further outside that: a concept that already carries more
components than a figure draws can still be renamed, re-described or given an
arrow, and a removal that brings it closer is allowed. A concept that carries
more components than a figure draws is drawn as far as the limit, and the
figure's note says how many of its components are not drawn.

## Tests as evidence

Test files are not read as a source by default. A test's setup data can
describe a mechanism that does not exist, and a model that reads it as real
ships a concept that is not in your code. Instead, after a scan decides which
concepts it ships, each concept is paired with the tests that use the
declarations of the file it cites: a Go concept among the test functions in its
own directory, read from the syntax tree, and a Python concept with the test
files beside its module and every test in the repository that imports it, read
by pattern. TypeScript and JavaScript concepts are counted and not paired (see
below). The tests that use a declaration the concept's own text names come
first, ahead of the rest of the file's tests. No model is involved, no concept
changes, and the result is written beside the scan as `tests.json`, with one
line in the output, which ends with the `--tests` mode the scan ran with, as
the pairing stage's own line does:

```
Tests: 12 of 30 shipped concepts are paired with tests that exercise them; --tests off, so no model read a test (tests.json)
```

| `--tests` | What it adds |
|-----------|--------------|
| `off` (default) | Pairing only. No model reads a test. |
| `evidence` | Also asks the model what each concept's paired tests assert that its description does not say, one call per paired concept. A property is kept only when its quote is found in the test's name, a failure message reported on the test's own `t`, the condition that guards one, or a case label the test prints and does not pass to the code under test, and when its statement repeats no phrase found only in the test's setup data. Every rejection is listed with its cause. The check is on where a quote comes from; it cannot tell whether the statement reads the assertion correctly. |
| `source` | `evidence`, plus test files and test directories are read as a source, in batches of their own, for mechanisms that live only in tests, such as a test harness. Tests are read with the data they construct masked, in discovery and in characterization, and under `--multi-model` before either model reads the file, so a fixture's made-up values cannot become a concept's, and a concept whose name or summary still copies one, or the placeholder that masked it, is held back (`copied_test_data`). |

Tests often state what a mechanism refuses or never does, which a description
of what the code does tends to leave out, so `evidence` is where to look for
it.

What pairing cannot see: concepts in TypeScript and JavaScript are counted, not
paired; a Go test outside the concept's directory that exercises the same code
is not seen; and a concept that cites the wrong file pairs that file's tests.
TypeScript, JavaScript and Python were paired by pattern in 1.3.0 and stopped
in 2.0.0: measured against hand labels on one real repository each, that
pairing found about one in five of the tests that exercise the code (recall
0.18 and 0.19, where 0.7 was required), because those tests mostly live away
from the code they test. Python pairs again since 2.0.0, by what a test imports
as well as by where it sits, which passed the same measurement; TypeScript and
JavaScript did not. `tests.json` records the names each test was paired on, so you can check
why. It is not part of the `--json` envelope, and nothing in it changes a
concept.

## Classification (`distinctive` / `borderline` / `textbook`)

The scanner **surfaces and classifies every mechanism it finds; it never
silently drops one.** Each concept carries a `classification`:

| Class | Meaning |
|-------|---------|
| `distinctive` | Clears all three engineering bars (technical distinctiveness, implementation depth, problem specificity). |
| `borderline` | Clears one or two, or is a strong instance of an otherwise-common pattern. |
| `textbook` | A standard library use, common design pattern, or routine implementation. |

The keep/drop decision is a **downstream, tunable step**, not something the model
does in the prompt: by default the results include `distinctive` + `borderline`
and **hold `textbook` back when characterization also scores it below the
minimum distinctiveness score** (the count is reported so nothing is hidden); a
concept classified `textbook` and scored at or above that minimum ships, with
its classification. Pass `--include-textbook` to include what is held. This is why a capable frontier model no
longer returns an empty set on a thin codebase: it classifies the standard
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
characterization, locating files, combinations). Concepts from both are merged and deduped
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

**Language coverage:** Avenue B runs when go-pbd can encode the language of the
files the scan reads: Go, TypeScript, Python and Markdown, in every build.
TypeScript and Python are read by pattern, in pure Go, so a binary built
without C (cgo), as every release binary is, groups them by meaning as a build
with C does, and the same files give the same batches whatever the binary. On
the two repositories its comparison was registered on, the pattern reader agreed
with tree-sitter on every declaration, span and dependency edge; on a third, a
larger TypeScript repository, 2 of 9,821 dependency edges differed.

| Build | Grouped by meaning (Avenue B) | Batched by size only |
|---|---|---|
| Built without C: the release binaries, the app, the installer, the container image and the Action | Go, TypeScript, Python, Markdown | none |
| Built with C | Go, TypeScript, Python, Markdown | none |

`concept-scanner version --json` says which languages a binary groups by
meaning (`semantic_batching`). A scan's Avenue B line names the language it
read and how (`Running discovery on 3 semantic batches (TypeScript, read by
pattern)`), and the run's `summary.json` records the same in its
`semantic_batching`. The same encoder builds the dependency graph a read of part of a
repository ranks its files by, so the same languages have one there. Every
other language (Rust, Zig, C, Java and the rest) is batched by size only in every
build. Avenue A reads every file whatever Avenue B does, and when Avenue B skips,
the scan's Avenue B line says why.

**Opt-out:** pass `--no-semantic-batching` to run Avenue A only.

**Cost:** PBD encoding is free (no LLM). The batch-suggestion call is one LLM
request with a compressed store (~3-10KB for a medium project). The discovery
calls per batch are identical to Avenue A.

## Reusing discovery answers

A scan run one request at a time (the default against a model server on this
machine, or `--parallel-batches 1`) keeps each discovery request's answer, and
a later scan that sends an identical request (the same files with the same
contents, the same model on the same model server and server version, and the
same request settings, including a model's think setting and anything set for a
remote endpoint) reuses it instead of asking again. Re-scanning after a small edit then asks again only for
the batches whose files changed. Each scan says what it did:

```
Discovery cache: 5 answer(s) reused, 1 asked, 0 answer(s) naming no concept asked again; about 1m32s of model time and 2357 output tokens saved; 1 asked again to check: 1 reproduced, 0 differed and were removed.
```

- **Only scans run one batch at a time reuse answers.** Run that way, a scan on
  this machine was measured repeating its discovery answers; with several batches
  at once it was not. A model's answers are not guaranteed to repeat, which is why
  a scan that reuses answers checks one (below), and a concept's classification
  label can still differ between two such scans (see "Two scans of the same code
  give different results" in [TROUBLESHOOTING.md](docs/troubleshooting.md)). A scan
  with several batches in flight (the default of 4 on a remote endpoint, or a
  number you gave or saved) reuses nothing and its notice says so. Since a local
  scan now runs one at a time unless told otherwise, it reuses answers by
  default.
- **Every scan that reuses answers checks one**: it asks that request again,
  after unloading the model, and compares. An answer that does not reproduce is
  removed and named in the notice, and the rest of that scan asks every request
  again rather than reuse one. `--verify-cache` checks every one, and reports a
  difference the same way rather than failing the scan.
- **An answer that named no concept is always asked again**, so a model that
  goes quiet on a file stays visible. A failed request is never kept, and
  neither is an answer to a prompt the server cut short.
- **The answers live in your user cache folder**, never in the folder being
  scanned (on macOS `~/Library/Caches/concept-scanner/discovery`, on Linux
  `~/.cache/concept-scanner/discovery`, on Windows
  `%LocalAppData%\concept-scanner\discovery`). Deleting that folder is always safe;
  the next scan asks again.
- **On a cloud endpoint** a reused answer is one of the answers it gives, since a
  remote model is not reproducible, and a model changed behind the same name
  cannot be detected. For the same reason a remote scan does not check a sample;
  `--verify-cache` still asks every one again and reports what differed.
- **The cache is off** for two-phase and `--multi-model` discovery, under
  `--record-examples` (which records every request), in each `tiers run` arm
  (whose time and answers are the measurement), and when
  `CS_DISCOVERY_CACHE_OFF` is set. The `Discovery cache:` line says which.

## Two-phase generation (`--two-phase`, experimental)

By default each generative pass (discovery, characterization, finding
combinations) is a single call that answers in JSON from its first token
(discovery and combinations under a JSON schema; characterization from the fields its prompt
names, with no schema on Ollama's own API and its own schema on an
OpenAI-compatible endpoint, a server on this machine included). That is fast
and reliable for
instruct/code models, but it leaves a reasoning model no room to reason and, on
a remote provider, tends to under-populate the descriptive fields.

`--two-phase` runs each of those passes as **two** calls instead:

1. **Distill (freeform):** the primary model describes the mechanism in prose,
   with no schema constraint, so a reasoning model can actually reason.
2. **Extract (structured):** a fast instruct model (`--extract-model`, default
   `gpt-oss:20b` locally and the Pass 2 model on a remote provider) turns that
   prose into the schema-shaped JSON.

This mirrors the pattern the scanner is shape-matched to, and is expected to let
reasoning models participate in discovery and to populate the descriptive fields
natively (retiring the remote-characterization completion fallback). It costs two
calls per item instead of one; the extract call is small and fast.

The mode is **off by default** and being A/B'd against the single-call path
before the default flips. Enable it with `--two-phase` (or `CS_TWO_PHASE=1`), and
pick the extractor with `--extract-model <tag>` (or `CS_EXTRACT_MODEL`). It
currently applies to the single-model path plus characterization and finding
combinations; multi-model (`--multi-model`) Pass 1 discovery is not yet two-phase.

The freeform distill is slower per batch (it generates prose, and a reasoning
model reasons at length), so `--two-phase` raises the per-request timeout floor
to **30 minutes** so large batches finish instead of being killed mid-distill.
Override with `--timeout` if your models need more, and note that two calls per
item make wall-time meaningfully higher than the single-call path.

## Machine-readable output (`--json`)

`--json` is accepted by every command that produces output (`scan`, `review`,
`export`, `combine`, `locate`, `models`) and emits the same
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
    { "action": "Review the discovered concepts", "command": "concept-scanner review scan-1782",
      "args": ["review", "scan-1782"],
      "priority": "high", "reason": "Approval gates export", "timing": "soon" }
  ],
  "notice": "12 concepts classified 'textbook' and scored below the minimum score held back (use --include-textbook to include them). Disclosures: grounding, 9 descriptions checked, 0 naming only symbols absent from the file cited; tests, 4 of 9 shipped concepts paired with tests. This run put 40 files in front of the model, and reports 9 concepts while holding back 12. Anything not listed was not assessed."
}
```

A scan's `notice` always carries that last part, the **run caveat**: how many
files the model actually saw (and how many it never did), how many concepts the
run reports and holds back, how many cited a file that could not be found, and
how many generations were discarded on an output cap. It is built from the run's
own numbers, so two runs that differ in any of them never print the same
sentence; a human-readable scan prints it as its `Coverage:` line. Before it,
one `Disclosures:` clause gives what each check beside the scan counted
(grounding, tests and the rest), naming no file; the disclosures next step names
the files. On failure, `data` is `null` and the error is in `notice`,
including a failure before the command runs (a flag it does not have, a missing
argument) when `--json` was given. A step that runs this program with nothing left to fill in also carries
`args`, its arguments after the program's name, so a program can run it without
a shell reading `command` back. A step that needs a value first (a model, a
file) carries `prefill`, the arguments it does have, and `fill`, each value
still to give as its `command` shows it (`--primary-model <model>`); it is
never run as it is, and the window opens that command's form with the rest
filled in. A step has `args` or `prefill`, never both, and a step that points
at a document has neither.

**Waiting for a scan from a script:** `concept-scanner status --wait <run-id>`
exits with the scan's own exit code when it ends (see "Watching a scan"). A scan
not run at a terminal names that command, with its run id, in its first line.

A scan's answer also carries `summary` at the top level, beside `data`: the
run's summary, the same value as the `summary.json` it writes beside itself.
Its `counts` say what the run found, shipped and held back, and how spread its
scores are (`score_spread`, with a `limit` of its own; nothing decides on it),
its `disclosures` what each check beside the scan counted, its `models` each
model it called by role, its `route` where its code was sent, and its `lines`
the summary as the terminal prints it at the end of a scan, among them one
labelled `Not run or capped` for each stage the run did not run or ran capped,
and each kind of file it left out that a flag reads, with the flag or command
that changes it. Its `tree_changed` says whether the repository changed while
the scan read it: the commit at the start and at the end, the files the scan
read that changed after it read them, compared by content for a scan that read
part of the repository and with git otherwise, and the cited files that
differed from the commit when the scan started; when the tree changed, the
summary's status (the scan's last line) says so, with a `Changed while scanning`
line. `data` keeps the
shape below, so nothing that imports a scan sees a change.

A scan's `data` is the scan result, version 3.0.0 of its shape. Each member of a
combination (`contributing_concept_ids`) and each concept a pattern names
(`concrete_refs`) is written `<scan-id>/<concept-id>`, naming the scan that
found it. It names the
repository by its git origin URL, with any credentials removed, or by its
folder's name when it has none, never by a path on your machine; says how much
of the repository the scan read (`coverage`) and which folders it skipped
(`directories_skipped`); gives its time as `duration_ms`; and gives its cost
in US dollars, or `null` when a remote call that read or wrote something had
neither a listed price nor a cost its endpoint reported (a call that read and
wrote nothing costs 0). The cost includes Pass 5 whichever command ran it:
`scan --patterns`, or `patterns`, which adds its run's Pass 5 spend to the
stored scan's cost, and `synthesis_cost.cost` is Pass 5's own part.
`dependency_map` names a file by its path in the repository, or a licence in
the module cache by `module@version`, never by a folder on your machine.

**Exit codes:** `0` success; `1` a usage, configuration or other general error;
`3` the model or the model server (not running or stuck, a model missing or not
downloadable, a model the endpoint does not have, a model call that failed, or a
pass whose every call failed). `2` is reserved. Every command's output
(and every error) carries at least two prioritized `next_steps`, at most five,
each with a reason, so a human or an AI agent always knows what to do next,
including when zero concepts are returned. Each is shown once: two steps that
run the same command, in any flag order, are one, kept at the higher priority
and in its own words. What a scan did not run is in its summary whatever the
five leave out. A response with fewer than two steps
of its own is given general ones for the command that ran (its options, and
where to look next), never another command's.

## Watching a scan

A scan takes minutes to hours, and it says what it is doing the whole time. So
does every other command that calls a model (`combine`, `locate`, `patterns`,
`bench`, `anchoring-check`, `distill gate`) and `tiers run`, which shows a stage
per arm: each takes the same `--progress` and writes the same status file.
`status --running` lists every run in progress, each with its command and
target; a run's status names what it is (`command`, `target`), whether it
continues a scan and how (`parent_scan_id`, and `changed_rescan` for a
`--changed` re-read of changes), and a model download's progress in bytes (`download`).

- **On a terminal**, a status line at the bottom shows the stage and how far
  through it is, how long the current model call has run, the time left (always
  marked `~`, with its range and the number of recorded calls it rests on, or "a
  starting estimate" before there are any), tokens, cost, and a count of
  warnings and errors, with the last few log lines under it. Discovery's stage
  names its batches and its calls ("Pass 1 discovery (137 batches, 144
  calls)"): the count beside it is of batches, and the time left is of calls,
  which are more when a file is read in parts. A model the server loads again
  under the run is said when it happens. Results and warnings print above it
  and stay in your scrollback. Ctrl+C stops the scan,
  and its last line says what this machine's caches kept and the command that
  reuses it (`status` offers the same command as a step).
- **Everywhere else** (CI, the Action, a pipe, a coding agent), each stage's
  start and end is a line stamped with the time since the run began, always
  `[H:MM:SS]`, with a heartbeat line at least every 30 seconds, and no cursor
  movement or colour.
- **Every run writes a status file and a log** under `runs/<run-id>/` in the data folder (`~/.concept-scanner/data`, or `DATA_DIR`),
  and prints the run id when it starts; not at a terminal, that first line also
  names the command that waits for it, `concept-scanner status --wait <run-id>`.

**For scripts and agents:** wait on a scan with `concept-scanner status --wait`
rather than by watching the process list. It exits with the scan's own exit code
when the scan ends, and with 1 and a notice if the scan was cancelled, its
process died (reported as **stale**), or `--timeout` passed. `status --json`
gives the status as the usual envelope. `--progress jsonl` streams one JSON
event per line on stderr instead (run, stage, progress, model call, retry,
warning, error and heartbeat events), leaving stdout to `--json`.

## Settings, keys and where they live

Everything you choose is kept for your user in `~/.concept-scanner` (on Windows,
`%USERPROFILE%\.concept-scanner`), and it is the same whether you use the window,
a terminal, or an agent does:

| In `~/.concept-scanner` | Holds |
|---|---|
| `settings.json` | The model profile, the provider with its endpoint and model, `think` settings, output budgets, saved advanced settings, the editor `show --open` uses, and your yes or no to the update check |
| `credentials.json` | API keys saved with `init --with-key`, readable only by you, each saved for one endpoint |
| `data/` | Scans, the audit log, and each run's status and log (`DATA_DIR` moves them) |
| `repos/` | Each repository's purpose, pins, drops and last scan, which the setup screens and `scan --dry-run` show |
| `ui.json`, `ui.log` | While the window runs: its address and the secret it gives your browser, and its log |

`concept-scanner init --json` shows what is saved. Output budgets, the most
tokens a model may write in one answer per kind of call, are saved with
`concept-scanner init --budget-<name> N` or in the window's Settings, and a
command's `--budget-<name>` changes one run; see
[PROVIDERS.md](docs/providers.md#advanced-output-token-budgets). To use a cloud
provider with no questions, and save its key once:

```bash
concept-scanner init --provider openai-compatible --base-url <url> --model <model-id> --with-key
```

`--with-key` reads the key from standard input: hidden as you type at a terminal,
or piped (`printf %s "$KEY" | concept-scanner init --with-key`). A key is never a
flag, so it never lands in your shell history, and it is saved only for that
endpoint's host. A key in the environment comes first (see
[PROVIDERS.md](docs/providers.md)); `init --remove-key` deletes the saved endpoint's
key, and `init --remove-key --base-url <url>` another endpoint's, changing nothing
else. `init --json` shows each saved key only by its host and its last four
characters, with the command that removes it.
A project's `.env.local` cannot set a key, nor anything that steers what a key is
spent on.

## Requirements

- [Ollama](https://ollama.ai) installed and running, for scans on your own computer
  (open the Ollama app, or `ollama serve`)
- For the Mac app, macOS 12 or later; for the Windows installer, 64-bit Windows 10 or 11
- Enough RAM/VRAM for the chosen models. The picker and the models screen flag
  profiles that exceed your detected memory. The smallest, **Fast**, needs about
  17 GB, set by its grader (`gpt-oss:20b`); with `--skip-review` its scans call
  only its discovery model (`qwen2.5-coder:7b`).

## Privacy

Your code goes to the model you chose and nowhere else. This binary sends
nothing about you or your scans to us.

It opens exactly four kinds of connection, and the full list is in
`outbound_calls_test.go`, which fails the build if a new one is added without
being described here:

- **the model server you run**, for inference, downloading a model, the
  approved-model manifest, the pre-run residency check, checking the server is
  reachable, checking any `think` settings you saved against what each model
  accepts, and recording what the server ran a scan with;
- **the provider you chose**, when you run with `--provider openai-compatible`
  on your own key, for inference, that provider's model list, and, for a server
  on this machine, asking it the window it holds a model at (when a scan
  reads part of a repository first, that includes excerpts of the project's
  documents and the list of its file paths);
- **GitHub's public releases page for this project**, for checking for a newer
  release: when you type `update`, and, only if you said yes to it, at most once
  a day when a scan starts. Nothing else contacts us, and nothing reports usage;
- **its own window, on this machine**, when you run `concept-scanner ui`: the
  window listens on 127.0.0.1 only, so no other machine can reach it, refuses
  requests from any other site, and needs a secret it hands your browser once;
  `ui` talks to it for checking whether the window is already open and for
  asking it to quit.

Unlimited scans, no per-call costs, when the model server is your own.

**Two things decide whether your code stays on your machine, and both are your
choice.** Pointing `--ollama-host` at a remote address sends the request there;
the scanner logs a warning at startup, and sends it anyway. Choosing an
OpenAI-compatible provider sends your code to that provider under their terms,
not ours. Run the model server locally and the code never leaves the machine.

## Contributing & community

- [TROUBLESHOOTING.md](docs/troubleshooting.md): common failure modes and recovery
- [CHANGELOG.md](CHANGELOG.md): what changed between releases
- [SECURITY.md](SECURITY.md): how to report security issues privately
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): Contributor Covenant 2.1
- [patent-skills](https://github.com/Obviously-Not/patent-skills): a sibling
  open-source project in the ObviouslyNot ecosystem (AI agent skills for patent
  scanning). A link for context, not a dependency: concept-scanner runs standalone.

## License

Apache-2.0; see [LICENSE](LICENSE).
