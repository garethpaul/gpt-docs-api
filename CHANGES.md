# Changes

## 2026-06-12

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
