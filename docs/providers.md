# Providers

concept-scanner runs against **local Ollama** (the default) or **any OpenAI-compatible endpoint**. You bring the backend; no endpoint or key is baked in.

## Selecting a provider

- `--provider ollama` (default): local Ollama. `--ollama-host` sets the host (default `http://localhost:11434`). Your code never leaves your machine.
- `--provider openai-compatible`: a remote endpoint. Set `--base-url` to the endpoint's `/v1` URL. `--primary-model` is optional on OpenRouter, where it defaults to `deepseek/deepseek-v4-flash` (the measured best-value model on cost per distinctive concept). On any other endpoint, pass it (or save one with `init --model`): the scan does not guess a model that catalog may not have, and stops to ask before it sends anything. **Your source is sent to that endpoint** (the tool prints a notice when a remote provider is selected).
- **Saved once, used everywhere.** `concept-scanner init --provider openai-compatible --base-url <url> --model <id>` saves the provider, endpoint and model to `~/.concept-scanner/settings.json`, and every command that calls a model uses them when its own flags name no provider, so `concept-scanner scan .` from any terminal, or an agent's call, runs on them with nothing passed. The run says it is using the saved provider. A flag wins for that run: `--provider ollama` runs locally, and another `--base-url` does not inherit the saved model. `init --profile <key>` (or picking a profile in `init`) switches back to local Ollama. `--ollama-host` given to `init` is saved too.

The API key comes from the **environment first, then from a key you saved** (never a flag, which would leak into shell history and CI logs). Save one once with `concept-scanner init --with-key`: it reads the key from stdin (hidden at a terminal; piped, as in `printf '%s' "$KEY" | concept-scanner init --with-key`, otherwise), saves it in `~/.concept-scanner/credentials.json` (readable only by you) for the exact host of your saved endpoint, and every command uses it for that host and no other. `init --remove-key` removes it (with `--base-url <url>`, the key saved for that endpoint instead, leaving the saved provider as it is), and `init --json` shows which hosts have one, by their last four characters, each with the command that removes it. Selection is **matched to the endpoint host** so one exported key can't leak to a different vendor: a vendor key is used only when the base-URL host is that vendor's (`OPENROUTER_API_KEY` for an `openrouter.ai` host, `OPENAI_API_KEY` for an `openai.com` host). For any other host (a self-hosted gateway, Groq, a private proxy) set the generic `CONCEPT_SCANNER_API_KEY`; a vendor key is never sent to a host it doesn't match. Keyless endpoints (for example a local Ollama `/v1`) need no key. A key is never part of the address either: a `--base-url` whose query string carries `key=`, `api_key=`, `access_token=`, `sig=` or a similar parameter is refused before anything is sent or saved, naming the parameter and never its value; parameters such as Azure's `api-version` are kept.

**A local `.env.local` during development.** If a file named `.env.local` sits in the directory you run the scanner from, it is read at startup and may supply the scanner's own `CS_*` / `CONCEPT_SCANNER_*` settings in your environment's place, **except any API key and anything that steers what a key is spent on or where a run's data goes**: `DATA_DIR`, `CS_EXTRACT_MODEL`, `CS_TWO_PHASE`, `CS_SEMANTIC_BATCHING`, `CS_REMOTE_CONTEXT_CAP`, `CS_RECORD_EXAMPLES`, `CONCEPT_SCANNER_TESTS`, every `CS_BUDGET_*`, every `BUDGET_*` spend ceiling and `CS_REMOTE_EXTRA_BODY`. Set those in your real environment. A real environment variable always wins over the file. (`OLLAMA_HOST` is not read: point at another local server with `--ollama-host`.) Two rules keep it to the case it exists for:

- **Only those names are applied.** Anything else in the file is ignored and the run says how many were skipped. This matters because the file is read from the working directory, and the scanner is often pointed at a repository it did not write.
- **It is not read at all inside the container image or in the GitHub Action**, where the working directory is the repository under scan. Those runs take their configuration from the environment you pass them. If a `.env.local` is present there, the run says it was ignored and why.

## First-run setup and the model shortlist

On an interactive first run with no `--provider` (and no saved config), the scanner asks **Local (Ollama) vs Cloud**. Choosing Cloud shows a cost/quality-ranked shortlist and **saves the model you pick** as the provider every command uses, then, if no key is found, shows the two ways to give one: `concept-scanner init --with-key` (saved once, for that endpoint only) or `export <KEY>=...` (never a flag), and the plain `concept-scanner scan <path>` to run once it is set.

**In the window** (`concept-scanner ui`, or the Mac app and the Windows install), Settings does the same: an address, a model and a key, saved by one `init --provider openai-compatible --base-url ... --model ... --with-key`, with the key passed to it on standard input, never as an argument. A provider and key saved in the window are what a terminal or an agent then uses, and the reverse. `concept-scanner models --cloud` prints the same shortlist any time. Cost is verified against the live catalog on a dated snapshot; quality tiering is provisional until measured against this tool, so treat it as a starting point and verify current prices with your provider. Explicit flags, `--no-interactive`, or a saved config skip the prompt, so scripted and CI runs are unaffected.

## Endpoints and model strings

| Target | `--base-url` | `--primary-model` example |
|---|---|---|
| OpenRouter | `https://openrouter.ai/api/v1` | `anthropic/claude-sonnet-5`, `openai/gpt-5.6-terra`, `deepseek/deepseek-v4-pro` |
| OpenAI direct | `https://api.openai.com/v1` | a current GPT model id (for example `gpt-5.6`) |
| Local Ollama (OpenAI mode, run on Ollama's own API) | `http://localhost:11434/v1` | `qwen3-coder:30b` |
| Azure / Groq / other | that provider's `/v1` URL | that provider's model id |

**A local server reached as OpenAI-compatible chooses its own context window.**
The OpenAI request has no field for it, so Ollama's `/v1` uses the server's
setting (`OLLAMA_CONTEXT_LENGTH`, or by GPU memory: 4k tokens under 24 GiB, 32k
up to 48 GiB, 256k above), and LM Studio, llama.cpp and vLLM use what the model
was loaded with. This tool sizes a run for 32k tokens. So:

- **An Ollama server on this machine given as `--base-url .../v1` is run on
  Ollama's own API**, which sets the window on every call. It is the same server
  and the same loaded model, and the run says so in one line.
- **For any other server on this machine, the window it applies is learned
  before anything is sent**: read from the server where it says (llama.cpp's
  server, from its slots; LM Studio 0.4 and later, for a model already loaded;
  vLLM, from its model list, on this machine or elsewhere), and otherwise
  measured with three prompts per model (two short, one the size of the window,
  which a large model can take several minutes to read; the run waits once, up
  to ten minutes a prompt). A refusal that names the server's window, as
  llama.cpp's and vLLM's do, counts as a measurement of it. A smaller window is the one every
  stage is sized for, down to 8,192 tokens; below that the run is refused with
  the steps that fix it. Load the model with a context of at least 32k tokens to
  run at full size.
- **A prompt the server cuts anyway stops the run**, for example after another
  program reloads the model with a smaller window: the call's answer is not
  used, nothing is saved, and a scan keeps its work in `unfinished.json` in the
  run's folder. `input truncation: NOT CHECKED` now means no source could say
  what the window is.
- On a very large window with several slots a model may not load at all; the
  run then says the server never ran the model, rather than that it declined.

Model ids change often; the examples above are illustrative, not pinned. Use
your provider's current catalog (for OpenRouter, `GET /api/v1/models`) and pass
any model that endpoint accepts. A capable general or coding model works well;
`anthropic/claude-sonnet-5` is the one validated against this tool.

**Every model a run calls is checked before its first call.** On an
OpenAI-compatible endpoint each one is looked up in the endpoint's model list,
and one the list lacks refuses the run before anything is sent, naming each
missing model with the flag that chose it; nothing can be downloaded there. (A
list that cannot be read is said in a note, and the run goes on unchecked.) On
Ollama, a model the server lacks is downloaded first, after one line saying so,
unless `--no-auto-pull` is given. A run against a remote endpoint keeps 4
requests in flight unless you give or save another number; against a server on
this machine, Ollama or not, it sends one at a time by default.

## Examples

```bash
# Local Ollama (default), fully private:
concept-scanner scan ./my-project

# OpenRouter (default model: deepseek/deepseek-v4-flash):
export OPENROUTER_API_KEY=sk-...
concept-scanner scan ./my-project \
  --provider openai-compatible \
  --base-url https://openrouter.ai/api/v1

# OpenRouter with explicit model:
export OPENROUTER_API_KEY=sk-...
concept-scanner scan ./my-project \
  --provider openai-compatible \
  --base-url https://openrouter.ai/api/v1 \
  --primary-model anthropic/claude-sonnet-5

# OpenAI direct:
export OPENAI_API_KEY=sk-...
concept-scanner scan ./my-project \
  --provider openai-compatible \
  --base-url https://api.openai.com/v1 \
  --primary-model gpt-5.6

# Or save the endpoint, the model and the key once, then scan with no flags,
# from any terminal, an agent, or the window:
concept-scanner init --provider openai-compatible \
  --base-url https://openrouter.ai/api/v1 \
  --model anthropic/claude-sonnet-5 --with-key   # paste the key, then Enter
concept-scanner scan ./my-project
```

The same `--provider` / `--base-url` / `--primary-model` flags work on the `bridges` and `triage` commands. **Semantic batching** (Avenue B) uses the same provider and model as discovery; no additional configuration is required.

## Per-pass models (remote)

The scan runs a discovery pass (Pass 1) and a validation/classification pass
(Pass 2). `--primary-model` sets the discovery model; `--secondary-model` sets
the validation model. On a remote provider whose catalog the model registry
lists them for (OpenRouter, today), both have defaults:

- **Primary** defaults to the measured best-value model (see `concept-scanner
  models --cloud`).
- **Secondary** defaults to a model validated to complete Pass 2 classification
  reliably on OpenRouter. This is intentionally a DIFFERENT model than the
  primary so the scan does not grade its own output.
- **On any other catalog** neither has a default: the scan stops before any
  model call and asks for `--primary-model` and `--secondary-model`, rather
  than send every call for a model that catalog does not have. The pre-flight
  check covers both defaults.

- **Drafting** (`--draft-model`) defaults, on an **off-machine** endpoint whose
  catalog the model registry lists it in, to a PAID model that is not your
  primary: `anthropic/claude-sonnet-5` on OpenRouter, `claude-sonnet-5` on
  Anthropic's own endpoint. On any other catalog it is your primary. The scan
  prints which model drafts and why, and the pre-flight check covers it.
  Everywhere else it defaults to your primary model, and that includes a
  LOOPBACK `--base-url` under `--provider openai-compatible` (LM Studio,
  llama.cpp, vLLM, Ollama's own `/v1`): those serve local model names and have
  never heard of the paid default, so asking for it would fail on every
  concept.

**What the drafting model is spent on, because it is more than its name
suggests.** It is not only the synthesis passes. It is read by
**characterization, which is one call per concept**, by triage, by test-evidence
extraction, by bridges and by synthesis. So on a remote provider a scan that
names a cheap `--primary-model` and no `--draft-model` still sends the bulk of
its calls to the paid default above. Pass `--draft-model` to choose it yourself,
or pass your primary's id to keep everything on one model:

```bash
concept-scanner scan . --provider openai-compatible \
  --base-url https://openrouter.ai/api/v1 \
  --primary-model deepseek/deepseek-v4-pro \
  --draft-model deepseek/deepseek-v4-pro        # else drafting is the paid default
```

Until 2026-10-06 four `--draft-model` help strings said the default was "same
as primary", which was true locally and wrong on every remote run.

`--multi-model` reads every file with two models in parallel and merges each
file's two readings, then has both models synthesize concepts and merges the two
lists, recording which concepts both models named on each concept
(`model_agreement`) and in `agreement.json` beside the scan; a single-model scan
carries no `model_agreement`. `agreement.json` also says how the two readings
of each file compared, which model server each step sent your code to and
whether that server is this machine (read from its host name), and which steps
degraded. That is one more synthesis call and one merge call per scan than a
single model makes, and `--timeout` applies to every one of its calls. It **requires a distinct secondary** (pass `--secondary-model`, or
save a multi-model profile) plus an optional `--merge-model`, which runs both
merges. A `--multi-model` run with no resolvable secondary now
errors rather than quietly falling back to a single model.

**Choosing the multi-model primary.** Prefer a lighter, less-verbose model as the `--multi-model` **primary** (for example a `gpt-4o-mini`-class model). A very verbose model as primary can, in the multi-model path, non-deterministically return an empty concept set on a given run (synthesis retries an empty result automatically, but the retry is a mitigation, not a guarantee). The secondary synthesizes too, so an empty primary list no longer empties the scan: the secondary's concepts ship, marked as that model's alone in `agreement.json`. A more verbose or higher-capability model still fits best single-model, or as the `--secondary-model`.

## Structured output across providers

On Ollama's own API the characterization call sends no output schema: its
prompt names every field it asks for, and nothing at the wire requires any of
them. On an OpenAI-compatible endpoint, a server on this machine included
(llama.cpp's server, LM Studio, vLLM), it sends characterization's schema as
`json_schema` with strict mode off, listing the descriptive fields first and the
scores after them, since a decoder held to a schema writes in its order. That is
new in this version and not yet measured on those servers; set
`CS_REMOTE_JSON_SCHEMA=0` to send none, in which case the request asks for
`json_object`, or, on a server that refuses `json_object` (LM Studio takes only
`json_schema` or plain text), asks for plain text. Either way some models omit the
descriptive fields (components, category, inputs/outputs, ...) while still
returning the numeric scores. The scanner detects this and runs a second,
extraction-only pass that asks for every missing field from the same source; a
concept still missing a field it requires after that pass is held back
(`required_field_missing`) rather than shipped incomplete, and an axis the model
did not score is `null`, never 0. No configuration is needed; the second pass
only fires when a field is missing. The warning a scan prints when fields were
missing says whether the schema reached the endpoint: sent, turned off with
`CS_REMOTE_JSON_SCHEMA=0`, or refused by the endpoint for that model and
replaced with `json_object`, or with plain text where the endpoint refuses
`json_object` too.

A characterization answer that cannot be decoded is sent again only to an
OpenAI-compatible endpoint off this machine. Ollama, and an OpenAI-compatible
server on this machine, are not sent the same request again.

**What is sent again, and what is not.** A request an endpoint rejects with a
4xx status other than 429 (a key it does not accept, a bad request, payment
required, a model it does not serve) is not sent again by any stage: the run
fails with the endpoint's status. A rate limit (429) and a server error (5xx)
are retried. A call that reaches `--timeout` is sent at most twice in all, by
the client, and no stage sends it again; a cut answer is not sent again at the
same size. With `request-attempts` at 1, an endpoint that refuses the output
schema is still sent the plain JSON request its refusal asks for, and one that
refuses `json_object` is still sent the plain text request.

The decode is also type-tolerant: a model that returns a number as a string
(`"0.8"`), or an object where a string was asked for, is coerced rather than
failing the whole characterization, so one mistyped field never discards a
concept's engineering scores. Output that a schema constrains already has the
right types, so the coercion changes nothing there.

**Automatic `json_schema` (with fallback).** By default, a call that carries a
schema passes it to a remote endpoint as `json_schema` with strict mode off, so
the shape and its `required` fields reach the model at the wire; whether a
non-strict schema is enforced is the endpoint's choice. Because `json_schema`
support varies by provider and is not reliably advertised, this is
**self-detecting and safe**: if an endpoint rejects `json_schema` for a model,
the scanner transparently downgrades that model to `json_object` for the rest of
the run, losing only the wire-level constraint, and remembers it, so at most one
request per model is spent discovering support. A server that refuses
`json_object` as well (LM Studio accepts only `json_schema` or plain text, and
answers HTTP 400 to `json_object`) is sent no response format from then on, for
the rest of the run and for every model: the prompt still asks for JSON, the
answer is read as text, and one refused request per server is spent finding
out. The calls that ask for JSON without a schema (the summaries and the
documentation matching that enrich code concepts, and `figure draw`) take the
same path. Set `CS_REMOTE_JSON_SCHEMA=0` to force `json_object` everywhere
(plain text on a server that refuses it) and skip the probe; that includes
characterization's schema above.

**Two-phase mode (`--two-phase`, experimental).** The completion fallback above
is a repair for a fused single call. The experimental two-phase path removes its
cause: it distills the mechanism into freeform prose first, then extracts the
structured JSON from that complete prose, which populates the descriptive fields
natively (including on a remote `json_object` provider). It also lets a reasoning
model participate, since the distill phase carries no schema constraint. Enable
with `--two-phase` (or `CS_TWO_PHASE=1`); the Phase-2 extractor is `--extract-model`
(default: `CS_EXTRACT_MODEL`, else the saved extract model on a local provider,
else `gpt-oss:20b` locally and the Pass 2 model on a remote provider). Off by default while it is A/B'd;
when on, the completion fallback becomes a dormant safety net. It currently covers
the single-model path plus characterization and bridge synthesis; multi-model
Pass 1 discovery is not yet two-phase. The freeform distill is slower per batch,
so `--two-phase` raises the per-request timeout floor to 30 minutes (override with
`--timeout`) so large batches finish instead of being killed mid-distill.

## Cost before a scan, and spend ceilings

**A remote scan says what it will cost before it spends.** The setup screens,
`scan --dry-run` (and its `--json`, per ring: `discovery_usd`,
`whole_low_usd`, `whole_high_usd`, `prices_as_of`, `prices_stale`,
`money_basis`, `whole_money_basis`, `ceiling_warnings`) and a line printed
before a remote scan's first model call all give an estimate in US dollars. It
is the same forecast the console prices for time, multiplied by the model
shortlist's per-token prices, and it names the date of those prices (and their
age when they are older than 90 days). It covers discovery; the whole scan is
given as a range only after three earlier priced scans with the same model,
because the passes after discovery (characterization alone is one call per
concept to the drafting model) are priced from history. When there is no
figure it says why: a model with no listed price, a call size not known yet,
`--two-phase`, or `--multi-model`. A run on Ollama, wherever it runs, or on an
OpenAI-compatible server at a loopback address, is not billed per token and is
never priced: it shows no money, and the scan's cost line says "Ollama, not
billed per token" or "an OpenAI-compatible server on this machine, not billed
per token". A remote scan records what it actually cost in `arc.json`, beside
the estimate, counting each call's reported cost where its endpoint gave one.

**What a call cost, as the endpoint says.** Some endpoints report, with each
answer, what the call cost and which upstream provider served it. Both are
read: each call's row in the run's `calls.jsonl` carries `cost_reported` and
`served_by`, and `models.json` beside the scan lists, for each model, every
upstream that served it and how many calls each served. A scan's cost is the
reported cost where the endpoint gave one, else the shortlist's listed price,
and `null` only when a call that read or wrote something had neither (a call
that read and wrote nothing, such as one the endpoint rejected, costs 0
whatever its model); a priced scan's cost line says "reported or listed
prices". It includes Pass 5 whichever command ran it (`scan --synthesize`, or
`synthesize`, which adds its run's Pass 5 spend to the stored scan's cost), and
`synthesis_cost.cost` is Pass 5's own part. The calls the setup screens make
before a scan count in its running cost and toward the spend ceilings' next
check. A reported cost is read as US dollars, which has not yet been
checked against a live endpoint's answer.

When more than one upstream served one model's calls, the scan says so at its
end, because they may run the model at different precisions, so its answers
may not all come from one configuration. To keep a scan on one, send the
endpoint's own routing field with `CS_REMOTE_EXTRA_BODY`, set in your real
environment (never `.env.local`, which refuses it): a JSON object whose keys are
model ids, each holding extra fields for that model's requests, with `"*"` for
any model without its own entry. On OpenRouter, for example:

```bash
export CS_REMOTE_EXTRA_BODY='{"qwen/qwen3-coder-30b-a3b-instruct": {"provider": {"only": ["<upstream>"], "allow_fallbacks": false}}, "*": {}}'
```

When it is set, a call for a model with no entry and no `"*"` entry is refused,
so it cannot cover some of a scan's models and silently miss others, and an
entry may not set a field this tool sets itself (the model, the messages, the
output cap, the sampling settings, the response format). A run that would call
such a model, the default drafting model included when no `--draft-model` is
given, is refused before its first model call, naming the model and the option
that chose it.

**Spend ceilings are opt-in.** Set any of these in your real environment
(never `.env.local`, which refuses them), in US dollars:

- `BUDGET_PER_OP`: one run.
- `BUDGET_DAILY`: today's runs together.
- `BUDGET_MONTHLY`: this month's runs together.

Unset or 0 means no ceiling; a value that is not a non-negative number stops
the command, naming the variable. With a ceiling set, a remote run warns at 80%
of it, and once it is reached sends no further model call and exits 1 saying
which ceiling, what was spent, the price date, and what to change. An estimate
that already reaches a set ceiling is warned about before the scan starts; the
running check is what stops it. A run that is never priced (above) is never
affected. Each call counts for the larger of its listed price and the cost its
endpoint reported, so an endpoint's own figure can raise what a call counts for
and never lower it; a model not on the shortlist counts for what its endpoint
reports. A call with neither is not counted: the run says so once, and the
running cost on the status line then ends in `+`. Limits: calls already in
flight when a ceiling is reached can pass it; only the last 50 runs this tool
keeps count toward the daily and monthly totals; and the prices are a dated
snapshot.

## Advanced: output-token budgets

Each kind of model call has an output budget: the most tokens a model may
write in one answer. An answer that reaches its budget is thrown away and asked
for again with twice the room, so a budget too small for a model costs the time
of every discarded answer; a scan's closing note says how many, by stage and
model. The defaults suit local Ollama; a verbose model can need more (most
often the multi-model per-file merge through an OpenAI-compatible provider,
whose default is already 16384). Every budget is changeable, with precedence
**flag > environment > saved > built-in**:

- **One run:** `--budget-<name> N` on each command whose run reads that budget
  (`concept-scanner help --json` lists them), for example
  `concept-scanner scan <path> --multi-model --budget-pbd-extract 12288`. `0`,
  the default, means not given.
- **Environment:** `CS_BUDGET_<NAME>`, uppercase with underscores
  (`CS_BUDGET_MERGE_REMOTE=24000`).
- **Saved default:** `concept-scanner init --budget-<name> N` saves it to the
  `"budgets"` section of `~/.concept-scanner/settings.json` (its keys are
  lowercase with underscores, `merge_remote`) for every command that reads it,
  and `0` removes it; the window's Settings screen does the same.
  `concept-scanner init --json` lists every budget with its value, where the
  value came from and the commands that read it.

Names: `characterization`, `completion`, `triage`, `figure`, `warmup`,
`synthesis`, `synthesis-repair`, `pass5`, `context-fit`, `pbd-extract`,
`merge-local`, `merge-remote`, `pass2`, `discovery`, `batch-suggest`,
`distill`, `extract`, `enrich-tldr`, `enrich-match`, `enrich-summary`,
`test-evidence`, `project-intent`, `locate-paths`, `bridge`. A value from 0 to 262144 is
accepted. `concept-scanner init --reset <name>` removes a saved budget too. A
saved budget or a `CS_BUDGET_*` variable that is not a whole number from 1 to
262144 is set aside, alone, and said when a command that reads it starts: the
next value in the order above applies, and `init --json` names it.

## Advanced: defaults

Besides the output budgets, a value this program would otherwise take as built
in can be changed: about 330 of them (the gates on what ships, Pass 3 and Pass
5, the model transport and context windows, timeouts and retries, batching, the
security limits, size limits, the console and the window, coverage ranking and
the measurement commands). Precedence: a flag for this run, then the value
saved with `init`, then the built-in value. No environment variable sets one,
except `default-remote-context-cap`, which `CS_REMOTE_CONTEXT_CAP` still sets,
between a flag and a saved value.

- **One run:** `--<key> N` on each command whose run reads it, for example
  `concept-scanner scan <path> --intent "<purpose>" --coverage 30
  --page-rank-damping 0.7`. These flags are hidden from `--help`;
  `concept-scanner help --json` lists each with its range, in the flag's
  `setting`.
- **Saved:** `concept-scanner init --<key> N` writes the `"defaults"` section
  of `~/.concept-scanner/settings.json`, and the window's Settings screen does
  the same. `0` is a real value for many defaults, so it does not remove one:
  `concept-scanner init --reset <key>` does, and `init --reset all` removes
  every saved default and output budget this version knows. A saved key it
  does not know is ignored, with a note on the runs that read defaults, and
  removed only by name: one an earlier version had and this one removed
  (`default-concurrency` and `default-remote-concurrency`, whose work
  `--parallel-batches` does, and `native-request-timeout`, whose work
  `default-ollama-timeout` does), or one a newer version saved.
- **The window:** each command's form groups the values it takes by area,
  with a search; a field left empty takes the saved value, else the built-in
  one.
- A value outside its range is refused, naming the range.
  `concept-scanner init --json` lists every value with its range (`range_text`), the value in
  force, where it came from and the commands that read it.

## Privacy

Local Ollama keeps your code on your machine (no API keys, no cloud calls). A remote provider **sends your source to that endpoint**. For proprietary code, prefer local Ollama or an endpoint you control. A concept's own file is sent for characterization only when the scan read it: a file that `--exclude`, `--only`, a dropped folder, or the documents and tests settings leave out is never sent, even when a concept names it. With `--tests evidence`, a test beside a concept's file is sent only when the scan would have read it had tests been a source: a test outside `--only`, matched by `--exclude`, or in a dropped folder is never sent. `triage` sends candidate files from the scan's own file set.

**Keeping code on this machine.** Pass `--local-only` to any command that calls a model, and it refuses before sending anything (exit 1) unless the model server is `localhost` or a loopback address. It judges the `--ollama-host` or `--base-url` host, never the provider: a local Ollama on another machine of your network is refused, and an OpenAI-compatible server on loopback (LM Studio, llama.cpp, vLLM, Ollama's own `/v1`) is allowed. It is never saved and no environment variable or `.env.local` sets it, so a script that relies on it passes it on every run. It also asks a local Ollama, before the first request, whether it runs each model on this machine, and refuses one it forwards elsewhere (a cloud model after `ollama signin`, which Ollama reports as `remote_host`), naming the model, its flag and the host; if a server says so only in an answer, the run stops after that one request and says the prompt left the machine. It cannot ask an OpenAI-compatible server on this machine that is not Ollama, and says so; a model a server forwards without saying so passes.

When a scan reads part of a repository first (the setup screens, or `--intent-from-docs` and `--coverage`), two more calls go to the same endpoint before the scan: one sends excerpts of the project's documents (up to 24,000 bytes in all, none that `--exclude` matches or `--only` leaves out) to ask what the project is for, and one sends the list of the repository's file paths (or its folders, when the list is too long for the model's window) to ask which of them implement each behaviour. A typed `--intent` or a saved plan skips the first; a saved plan skips both.

> This is the one file permitted to name concrete providers by their wire identifiers (`openrouter`, `anthropic/claude-*`, `deepseek/deepseek-*`); the leak-guard allowlists it. Keep all other source and docs vendor-neutral.
