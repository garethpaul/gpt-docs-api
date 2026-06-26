# Changes

## 2026-06-26T22:48:23Z

- **Priority:** Security and request resource boundaries.
- **Summary:** Reject overlong raw query strings before trimming whitespace so
  authenticated callers cannot bypass the documented request-size guard with
  a tiny normalized query wrapped in excessive padding.
- **Files:** `api/chalicelib/utils.py`, `api/tests/test_utils.py`,
  `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, and `CHANGES.md`.
- **Tests:** Added a focused failing regression before implementation; Python
  3.10 `make verify` passes all 64 tests and repository baseline checks.
- **Findings:** The checked-in extension clients still call authenticated API
  routes without credentials; resolving that safely requires a separate trust
  model rather than embedding a shared server secret in public JavaScript;
  tracked separately as issue #36.
- **Blockers:** None for this request-boundary fix.
- **Next action:** Open the focused pull request and require hosted checks on
  its exact head SHA before merge.

## 2026-06-18

- Made Chalice package verification forward cancellation signals to its active
  package process and clean up promptly even when the child ignores termination.
- Replaced bytecode-writing Python compilation with in-memory syntax checks and
  made maintained test gates artifact-free.

## 2026-06-17

- Migrated the OpenAI Python client to 2.41.0 and its instance-based embedding
  and chat-completions resources while preserving credential-free test doubles.
- Normalized non-callable or failing retrieval metadata accessors to missing
  metadata while preserving mapping and object match compatibility.

## 2026-06-16

- Normalized non-callable or failing retrieval response accessors to no matches
  while preserving mapping and object response compatibility.
- Normalized malformed retrieval matches containers to an empty collection
  before per-item metadata validation.

## 2026-06-15

- Required binary-only dependency artifacts in hosted installation and Chalice packaging.
- Added a generated, hash-addressed Python 3.10 deployment dependency lock and
  required hash verification in hosted installs and Chalice package builds.

## 2026-06-13

- Made every Make verification target derive the checkout root so test,
  compile, baseline, and package gates work from external directories.
- Made DynamoDB response caching best-effort so transient read failures bypass
  the cache and write failures do not discard successfully generated answers.
- Validated cached response payloads and reapplied HTTPS Twilio citation
  filtering to cache hits so legacy data cannot bypass current link policy.
- Enforced one separator-aware 4,000-character total retrieval context budget
  across all Pinecone matches before OpenAI prompt assembly.

## 2026-06-12

- Pinned the hosted pip bootstrap to 26.1.2 and added contracts rejecting
  floating, alternate, missing, or duplicate installer upgrades.
- Removed the 1,618-file Python 3.9 `api/vendor/` snapshot so Chalice packages
  dependencies from the maintained requirements instead of checked-in binary
  artifacts.
- Added a temporary, credential-free Chalice package build and structural
  archive verification to the local command surface and hosted CI.
- Added a tracked least-privilege Lambda policy and SAM verification for
  `gpt_docs` cache reads and writes after package review found that Chalice's
  automatic analyzer omitted imported `chalicelib` cache calls.
- Added baseline contracts that reject tracked vendor trees, bytecode, caches,
  generated package output, or weakened package verification.
- Explicitly disabled unintended Vercel Git deployments so the repository's
  deployment status reflects its Chalice API and GitHub Pages workflows.
- Replaced extension `innerHTML` sinks with text-only DOM rendering, restricted
  source links to HTTP(S), isolated new tabs, and added canonical regressions.
- Replaced raw DynamoDB query partition keys with namespaced SHA-256 identities
  so accepted long and Unicode queries remain within storage key limits.
- Added deterministic, fixed-size, plaintext-absence, read/write symmetry, and
  static regression coverage without changing the cache table schema or TTL.

## 2026-06-10

- Added one-day expiration to generated-answer cache entries, rejected stale or
  legacy cache entries without `expires_at`, and emitted DynamoDB TTL metadata.
- Added a pinned, least-privilege Python 3.10 GitHub Actions workflow that
  verifies dependency consistency and runs the no-live-credentials
  auth/retrieval baseline without persisting checkout credentials; the local
  baseline rejects missing, duplicate, relocated, or contradictory settings.

## 2026-06-09

- Returned generic 500 errors for unexpected `/ask` and `/classify/builder`
  failures while logging server-side details.
- Added `make lint` and `make build` aliases so local verification has the
  expected pre-push gate targets alongside `make test`, `make check`, and
  `make verify`.
- Tightened request query validation so `/ask` and `/classify/builder` reject
  whitespace-only or non-string queries before OpenAI or Pinecone work starts.
- Added a maximum query length guard before OpenAI, Pinecone, DynamoDB, or cache
  helpers receive request payloads.
- Added Twilio link host filtering so generated answer links must use HTTPS
  `twilio.com` or `*.twilio.com` hosts.
- Added a retrieval metadata guard so incomplete Pinecone matches are skipped
  before generated answer context is assembled.
- Added a retrieval context length guard so oversized Pinecone metadata is
  capped before generated-answer prompts are assembled.
- Added a classification weight schema guard so `/classify/builder` only returns
  finite numeric `with_code`, `minimal_code`, and `no_code` weights.

## 2026-06-08

- Added a repository changelog for maintenance history.
- Added a shared API-key guard for `/ask` and `/classify/builder` so public
  callers cannot spend server OpenAI/Pinecone credentials without
  `GPT_DOCS_API_KEY` authorization.
- Added a public file path guard so asset requests stay inside
  `api/chalicelib/public` and missing assets return 404.
- Added a source baseline guard and wired it into `make verify`.
- Preserved deterministic unit tests and compile checks for the Chalice API
  without requiring live OpenAI, Pinecone, AWS, or Twilio credentials.
