# gpt-docs-api

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/gpt-docs-api` is a static web project. Q&A Type Interface to ask questions against the Twilio docs with GPT-4.

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `main` branch. The project language mix found during review was: Python (8), JavaScript (4).

## Repository Contents

- `CHANGES.md` - maintenance history
- `README.md` - project overview and local usage notes
- `api` - source or example code
- `chrome_extension` - source or example code
- `docs` - source or example code
- `Makefile` - local build or utility targets
- `SECURITY.md` - security reporting and disclosure guidance
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: api, chrome_extension, docs
- Dependency and build manifests: Makefile
- Entry points or build surfaces: Makefile
- Test-looking files: api/chalicelib/public/test.html, api/tests/test_cache.py, api/tests/test_classification.py, api/tests/test_utils.py, chrome_extension/test.html, docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md

## Getting Started

### Prerequisites

- Git

### Setup

```bash
git clone https://github.com/garethpaul/gpt-docs-api.git
cd gpt-docs-api
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Run `make` or inspect `Makefile` for available targets.

## Testing and Verification

Run the local verification gate before changing the API, cache, or classification helpers:

```bash
make lint
make test
make build
make check
make package-check
make verify
```

`make lint` runs `scripts/check-baseline.sh`, `make test` runs deterministic
unit tests without live OpenAI, Pinecone, AWS, or Twilio credentials, and
`make build` compiles the Chalice app and helper modules. `make verify` keeps
the existing combined gate across tests, compile checks, and the source
baseline. The baseline also syntax-checks both extension bundles and verifies
that remote content uses text-only rendering with HTTP(S)-only source links.
GitHub Actions installs the pinned API requirements on Python 3.10, verifies
dependency consistency, constructs and inspects a real Chalice deployment
package, checks out without persisting the workflow token, and runs the same
offline `make check` baseline. Deployable dependencies come from
`api/requirements.txt`; generated `api/vendor/` environments are not tracked.
The package verifier also confirms the generated role can read and write only
the `gpt_docs` DynamoDB cache table needed by the application.
The API implementation targets AWS Chalice, while repository settings publish
the static project content through GitHub Pages. Vercel automatic Git deployments are disabled
in `vercel.json` because their rewrite targeted the Flask entry point retired
during the 2023 Chalice migration.
Request validation rejects missing, non-string, whitespace-only, and over the
maximum query length values before model or retrieval work starts.
The retrieval context length guard caps each accepted Pinecone metadata text
chunk before generated-answer prompt assembly.
Classification responses are constrained to the expected classification weight
schema before `/classify/builder` returns model-produced JSON to callers.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- Detected references to OpenAI, Pinecone, AWS, and Twilio. Keep API keys,
  OAuth credentials, tokens, and account-specific values in local
  configuration only.
- Set `GPT_DOCS_API_KEY` on deployments that expose `/ask` or
  `/classify/builder`. Callers must send the same value in
  `X-GPT-Docs-API-Key` or `Authorization: Bearer <token>` before those routes
  read request bodies or spend server-side OpenAI/Pinecone credentials.
- Set `OPENAI_API_KEY`, `PINECONE_API_KEY`, `PINECONE_ENVIRONMENT`, and AWS
  credentials only in local or deployment environment configuration.

## Security and Privacy Notes

- Review changes touching external API calls or credential-adjacent configuration; examples from the scan include api/app.py, api/chalicelib/classification.py, api/chalicelib/public/content.css, api/chalicelib/public/content.js, and 6 more.
- Keep `/ask` and `/classify/builder` behind the shared caller API-key guard or
  a stronger API Gateway/JWT authorizer. Public asset routes may remain
  unauthenticated, but public asset routes must stay path-bound to
  `api/chalicelib/public`.
- Keep request query validation bounded by a maximum query length before routes
  invoke OpenAI, Pinecone, DynamoDB, or cache helpers.
- DynamoDB cache entries expire after one day in application reads and include
  an integer `expires_at` epoch attribute for DynamoDB TTL cleanup.
- Cache reads and writes use a fixed-size SHA-256 identity in the existing
  `query_string` key attribute, avoiding raw user questions and DynamoDB key
  length failures for accepted long or Unicode queries.
- Keep the classification weight schema limited to numeric `with_code`,
  `minimal_code`, and `no_code` values.
- Twilio link host filtering keeps generated answer links limited to HTTPS
  `twilio.com` or `*.twilio.com` hosts instead of substring matches.
- Keep the retrieval metadata guard in place so incomplete Pinecone match
  metadata is skipped before answer generation.
- Keep the retrieval context length guard in place so oversized Pinecone
  metadata cannot expand generated-answer prompts without bound.
- Keep unexpected route failures logged server-side while callers receive
  generic 500 errors.
- Keep user queries and model responses on text-only DOM rendering in both
  extension bundles. Source links must be HTTP(S)-only and use opener
  isolation when opened in a new tab.
- Review changes touching network requests, sockets, or service endpoints; examples from the scan include api/chalicelib/public/content.js, api/chalicelib/public/manifest.json, api/chalicelib/public/segment-snippet.js, chrome_extension/content.js, and 2 more.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include api/app.py, api/chalicelib/classification.py, api/chalicelib/public/content.css, api/chalicelib/public/content.js, and 5 more.
- Review changes touching database, model, or persistence code; examples from the scan include api/chalicelib/classification.py, api/tests/test_classification.py, docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md.
- Review changes touching infrastructure, proxy, cloud, or deployment configuration; examples from the scan include docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md.

## Maintenance Notes

- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `CHANGES.md` for maintenance history.
- See `docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md`
  for the current testability and dependency baseline.
- See `docs/plans/2026-06-08-source-baseline-guard.md` for the source guard.
- See `docs/plans/2026-06-08-gpt-docs-api-auth-guard.md` for the API route
  authentication guard.
- See `docs/plans/2026-06-08-public-file-boundary.md` for the public asset
  path boundary.
- See `docs/plans/2026-06-09-query-length-boundary.md` for the maximum query
  length guard.
- See `docs/plans/2026-06-09-make-gate-aliases.md` for local verification
  target guardrails.
- See `docs/plans/2026-06-09-retrieval-metadata-guard.md` for the retrieval
  metadata guard.
- See `docs/plans/2026-06-09-retrieval-context-length-guard.md` for the
  retrieval context length guard.
- See `docs/plans/2026-06-09-generic-error-responses.md` for generic 500
  errors on unexpected route failures.
- See `docs/plans/2026-06-10-ci-baseline.md` for the GitHub Actions baseline.
- See `docs/plans/2026-06-10-cache-expiration-boundary.md` for cache freshness
  and DynamoDB TTL behavior.
- See `docs/plans/2026-06-12-cache-query-key-hashing.md` for fixed-size,
  privacy-minimizing query cache identity.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
