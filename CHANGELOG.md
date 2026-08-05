# Changelog

All notable changes to concept-scanner are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are the
`v*` tags in this repository.

## [Unreleased]

The repository went **private on 2026-07-18** (see the project notes), so the
work since `v1.0.5` has not been cut as a public release. It is internal
reliability and quality work: a provider-agnostic model registry with
fail-fast id resolution, a consolidated remediation pass over the open issues,
and the two-phase (distill then extract) generation mode behind an off-by-default
flag. See `docs/plans/` for the full record.

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
  to complete Pass 2 classification without degradation. See
  `docs/plans/2026-07-23-cloud-secondary-model-reliability-bench.md` for the
  benchmark results.

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

- **README availability note.** The "Running in Docker" and "GitHub Action"
  sections now state that the GHCR image and `uses:` reference are not publicly
  consumable while the repository is private, and point to building locally,
  instead of leaving a reader to hit a 403.

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

[Unreleased]: https://github.com/Obviously-Not/concept-scanner/compare/v1.0.5...HEAD
[1.0.5]: https://github.com/Obviously-Not/concept-scanner/releases/tag/v1.0.5
[1.0.4]: https://github.com/Obviously-Not/concept-scanner/releases/tag/v1.0.4
[1.0.3]: https://github.com/Obviously-Not/concept-scanner/releases/tag/v1.0.3
[1.0.2]: https://github.com/Obviously-Not/concept-scanner/releases/tag/v1.0.2
[1.0.1]: https://github.com/Obviously-Not/concept-scanner/releases/tag/v1.0.1
[1.0.0]: https://github.com/Obviously-Not/concept-scanner/releases/tag/v1.0.0
