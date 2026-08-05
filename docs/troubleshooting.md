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

**Fix:** the scanner retries on truncation with a larger budget automatically. If
it still truncates, raise the budget for the affected pass with the `CS_BUDGET_*`
environment variables (see [PROVIDERS.md](providers.md)). Reasoning-heavy models
spend more tokens before the answer, so they need a larger budget.

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
