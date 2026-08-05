# Providers

concept-scanner runs against **local Ollama** (the default) or **any OpenAI-compatible endpoint**. You bring the backend; no endpoint or key is baked in.

## Selecting a provider

- `--provider ollama` (default): local Ollama. `--ollama-host` sets the host (default `http://localhost:11434`). Your code never leaves your machine.
- `--provider openai-compatible`: a remote endpoint. Set `--base-url` to the endpoint's `/v1` URL. `--primary-model` is optional: if omitted, it defaults to `deepseek/deepseek-v4-flash` (the measured best-value model on cost per distinctive concept). **Your source is sent to that endpoint** (the tool prints a notice when a remote provider is selected).

The API key comes from the **environment only** (never a flag, which would leak into shell history and CI logs). Selection is **matched to the endpoint host** so one exported key can't leak to a different vendor: a vendor key is used only when the base-URL host is that vendor's (`OPENROUTER_API_KEY` for an `openrouter.ai` host, `OPENAI_API_KEY` for an `openai.com` host). For any other host (a self-hosted gateway, Groq, a private proxy) set the generic `CONCEPT_SCANNER_API_KEY`; a vendor key is never sent to a host it doesn't match. Keyless endpoints (for example a local Ollama `/v1`) need no key.

## First-run setup and the model shortlist

On an interactive first run with no `--provider` (and no saved config), the scanner asks **Local (Ollama) vs Cloud**. Choosing Cloud shows a cost/quality-ranked shortlist, assembles the exact `--provider openai-compatible` command for the model you pick, and prints the `export <KEY>=...` line (the key stays in the environment, never a flag). `concept-scanner models --cloud` prints the same shortlist any time. Cost is verified against the live catalog on a dated snapshot; quality tiering is provisional until measured against this tool, so treat it as a starting point and verify current prices with your provider. Explicit flags, `--no-interactive`, or a saved config skip the prompt, so scripted and CI runs are unaffected.

## Endpoints and model strings

| Target | `--base-url` | `--primary-model` example |
|---|---|---|
| OpenRouter | `https://openrouter.ai/api/v1` | `anthropic/claude-sonnet-5`, `openai/gpt-5.6-terra`, `deepseek/deepseek-v4-pro` |
| OpenAI direct | `https://api.openai.com/v1` | a current GPT model id (for example `gpt-5.6`) |
| Local Ollama (OpenAI mode) | `http://localhost:11434/v1` | `qwen3-coder:30b` |
| Azure / Groq / other | that provider's `/v1` URL | that provider's model id |

Model ids change often; the examples above are illustrative, not pinned. Use
your provider's current catalog (for OpenRouter, `GET /api/v1/models`) and pass
any model that endpoint accepts. A capable general or coding model works well;
`anthropic/claude-sonnet-5` is the one validated against this tool.

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
```

The same `--provider` / `--base-url` / `--primary-model` flags work on the `bridges` and `triage` commands. **Semantic batching** (Avenue B) uses the same provider and model as discovery; no additional configuration is required.

## Per-pass models (remote)

The scan runs a discovery pass (Pass 1) and a validation/classification pass
(Pass 2). `--primary-model` sets the discovery model; `--secondary-model` sets
the validation model. On a remote provider, both have sensible defaults:

- **Primary** defaults to the measured best-value model (see `concept-scanner
  models --cloud`).
- **Secondary** defaults to a model validated to complete Pass 2 classification
  reliably on OpenRouter. This is intentionally a DIFFERENT model than the
  primary so the scan does not grade its own output.

`--multi-model` runs two models in parallel and merges; it **requires a distinct
secondary** (pass `--secondary-model`, or save a multi-model profile) plus an
optional `--merge-model`. A `--multi-model` run with no resolvable secondary now
errors rather than quietly falling back to a single model.

**Choosing the multi-model primary.** Prefer a lighter, less-verbose model as the `--multi-model` **primary** (for example a `gpt-4o-mini`-class model). A very verbose model as primary can, in the multi-model path, non-deterministically return an empty concept set on a given run (synthesis retries an empty result automatically, but the retry is a mitigation, not a guarantee). Use a more verbose or higher-capability model single-model, or as the `--secondary-model`, where its output is reconciled rather than driving synthesis directly.

## Structured output across providers

Local Ollama constrains the model's decoding to the characterization schema, so
every field comes back. A remote OpenAI-compatible endpoint is called in
`json_object` mode (the widely-supported setting), which guarantees valid JSON
but does not enforce the schema's required fields, so some models omit the
descriptive fields (components, category, inputs/outputs, ...) while still
returning the numeric scores. The scanner detects this and runs a second,
extraction-only pass that fills the missing fields from the same source, so
characterization completeness holds on remote providers regardless of the
model. No configuration is needed; it only fires when a field set is missing.

The remote decode is also type-tolerant: a model that returns a number as a
string (`"0.8"`), or an object where a string was asked for, is coerced rather
than failing the whole characterization, so one mistyped field never discards a
concept's engineering scores. The local, grammar-constrained path is unaffected.

**Automatic `json_schema` (with fallback).** By default the scanner now passes the
actual schema (including its `required` fields) to the model at the wire as
`json_schema`, which enforces the shape at the source and reduces the need for the
repair pass above. Because `json_schema` support varies by provider and is not
reliably advertised, this is **self-detecting and safe**: if an endpoint rejects
`json_schema` for a model, the scanner transparently downgrades that model to
`json_object` for the rest of the run (the schema still rides the prompt) and
remembers it, so at most one request per model is spent discovering support. Set
`CS_REMOTE_JSON_SCHEMA=0` to force `json_object` everywhere and skip the probe.

**Two-phase mode (`--two-phase`, experimental).** The completion fallback above
is a repair for a fused single call. The experimental two-phase path removes its
cause: it distills the mechanism into freeform prose first, then extracts the
structured JSON from that complete prose, which populates the descriptive fields
natively (including on a remote `json_object` provider). It also lets a reasoning
model participate, since the distill phase carries no schema constraint. Enable
with `--two-phase` (or `CS_TWO_PHASE=1`); the Phase-2 extractor is `--extract-model`
(default `gpt-oss:20b`, or `CS_EXTRACT_MODEL`). Off by default while it is A/B'd;
when on, the completion fallback becomes a dormant safety net. It currently covers
the single-model path plus characterization and bridge synthesis; multi-model
Pass 1 discovery is not yet two-phase. The freeform distill is slower per batch,
so `--two-phase` raises the per-request timeout floor to 30 minutes (override with
`--timeout`) so large batches finish instead of being killed mid-distill.

## Advanced: output-token budgets

Each generation pass has a max output-token budget. The defaults suit local
Ollama; a verbose remote model can need more (most often on the multi-model PBD
**merge**, whose remote default is already raised to 16384). If a scan fails with
a `truncated output ... hit max_tokens` error, raise the relevant budget. Every
budget is tunable with precedence **flag > env > config file > default**:

- **Env:** `CS_BUDGET_<NAME>` (e.g. `CS_BUDGET_MERGE_REMOTE=24000`,
  `CS_BUDGET_CHARACTERIZATION=6000`).
- **Config file:** a `"budgets"` object in `data/config.json`, e.g.
  `{"budgets": {"merge_remote": 24000, "synthesis": 12000}}` (only the keys you
  set change).
- **Flags:** hidden `--budget-<name>` flags on `scan` / `triage` / `bridges`
  (e.g. `--budget-merge-remote 24000`); hidden from `--help` as advanced knobs.

Names: `characterization`, `completion`, `triage`, `warmup`, `synthesis`,
`synthesis-repair`, `context-fit`, `pbd-extract`, `merge-local`, `merge-remote`,
`default`, `distill`, `extract` (the last two size the two-phase distill and
extract calls; env forms uppercase with underscores, config-file forms lowercase
with underscores).

## Privacy

Local Ollama keeps your code on your machine (no API keys, no cloud calls). A remote provider **sends your source to that endpoint**. For proprietary code, prefer local Ollama or an endpoint you control.

> This is the one file permitted to name concrete providers by their wire identifiers (`openrouter`, `anthropic/claude-*`, `deepseek/deepseek-*`); the leak-guard allowlists it. Keep all other source and docs vendor-neutral.
