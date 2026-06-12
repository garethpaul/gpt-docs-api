# Chalice Vendor Cleanup

status: completed

## Context

The repository tracks `api/vendor/`, a 1,618-file, approximately 94 MB
Python 3.9 Linux site-packages snapshot added in April 2023. The tree includes
compiled extension modules, package tests, metadata, and transitive libraries,
but the current application declares its maintained dependencies in
`api/requirements.txt` and does not import from `api/vendor` directly.

AWS Chalice packages compatible third-party dependencies from
`requirements.txt`. Its `vendor/` mechanism is intended for custom content or
packages that cannot be installed from compatible wheels. Keeping an
unreviewed interpreter-specific environment snapshot in source control makes
dependency provenance ambiguous, inflates every clone and diff, and can
silently override the pinned dependency graph during packaging.

Reference: <https://aws.github.io/chalice/topics/packaging.html>

## Priority

1. Remove the stale tracked `api/vendor/` environment snapshot.
2. Prevent generated or manually installed dependency trees from returning.
3. Prove the pinned requirements can produce a complete Chalice deployment
   package without the snapshot.
4. Keep larger dependency API migrations, production deployment, and external
   service integration testing as separately scoped work.

## Requirements

- R1. Delete every tracked path under `api/vendor/` without rewriting Git
  history or removing application-owned code under `api/chalicelib/`.
- R2. Ignore `api/vendor/` as generated deployment input and reject any tracked
  vendor path through the repository baseline.
- R3. Keep `api/requirements.txt` as the single declared third-party dependency
  source for Chalice packaging.
- R4. Build a real Chalice deployment package from a clean dependency install
  and verify that it contains the application plus required runtime imports.
- R5. Keep the package build credential-free, sourced from version-controlled
  requirements, bounded in CI, and free of generated artifacts in Git. Do not
  claim bit-for-bit reproducibility while transitive dependencies remain
  resolver-managed rather than hash-locked.
- R6. Preserve all API routes, authentication, cache, classification,
  extension rendering, GitHub Pages, and Vercel behavior.
- R7. Document the packaging boundary, verification evidence, and remaining
  deployment risks in maintained project documentation.

## Implementation Units

### U1. Remove stale packaged dependencies

- **Files:** `api/vendor/**`, `.gitignore`
- Delete the tracked site-packages snapshot and add an explicit ignore rule for
  regenerated Chalice vendor content.
- Do not modify application-owned `api/chalicelib/` modules or the pinned
  dependency declarations.

### U2. Enforce dependency and artifact boundaries

- **Files:** `scripts/check-baseline.sh`
- Require `api/requirements.txt` and the vendor ignore rule.
- Reject any tracked `api/vendor/` path, generated package archive, Chalice
  package output, Python bytecode, or cache directory.
- Keep the check dependency-free so it runs before package installation.

### U3. Verify a real Chalice package

- **Files:** `scripts/verify-chalice-package.sh`, `Makefile`,
  `.github/workflows/check.yml`
- Add a bounded package verification command that builds into a temporary
  directory, writes only a temporary non-secret Chalice app configuration,
  inspects the generated archive structurally, and removes all output
  automatically.
- Run the package check after the pinned requirements install in hosted CI.
- Verify the archive contains `app.py`, `chalicelib/`, and importable runtime
  dependencies while excluding repository-owned tests, copied local caches,
  generated vendor input, and local secrets. Validate the generated SAM
  function runtime and archive reference as part of the same check.

### U4. Record the maintained packaging contract

- **Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
  `AGENTS.md`, `docs/plans/2026-06-12-chalice-vendor-cleanup.md`
- Explain that deployable dependencies come from pinned requirements during a
  clean Chalice package build, not from checked-in interpreter artifacts.
- Record completed verification and the distinction between package proof and
  a production AWS deployment.

## Scope Boundaries

- Do not deploy to AWS or require AWS, OpenAI, Pinecone, or caller credentials.
- Do not merge or modify the separate Vercel ownership PR.
- Do not upgrade Chalice, OpenAI, Pinecone, or boto3 APIs in this change.
- Do not introduce a generated freeze as a false lockfile; full transitive
  hash-locking remains a separate dependency-management change.
- Do not rewrite repository history to purge the old blobs.
- Do not claim that package construction proves live service integration.

## Verification

- `PYTHONPATH=api python -m unittest discover -s api/tests`: 41 tests passed on
  Python 3.10.19.
- `make build`: application, helper, and test compilation passed.
- `make package-check`: Chalice 1.33.0 completed IAM analysis after the
  comprehension-incompatible link deduplication was rewritten as an explicit
  equivalent loop; the temporary credential-isolated build produced a valid
  package with 5,311 entries.
- Plan-aware review found that automatic policy generation omitted DynamoDB
  calls imported from `chalicelib`. The final package uses a tracked policy
  limited to `GetItem` and `PutItem` on `gpt_docs`, plus Lambda log delivery,
  and verifies the exact action/resource set in the generated SAM role so
  wildcard permission broadening is rejected.
- Verified Chalice deployment package output contains the maintained
  application and declared runtime dependency boundary.
- Structural archive inspection found `app.py`, the maintained `chalicelib/`
  modules, and the Chalice, OpenAI, and Pinecone runtime packages without
  repository-owned tests, local configuration, or the removed vendor tree.
- `make verify`, `make lint`, `make test`, `make build`, `make check`,
  `git diff --check`, and hosted Python 3.10 package verification are required
  final gates.
- The tracked-file audit requires zero `api/vendor/`, bytecode, cache, or
  generated package paths.
- Hostile mutations rejected six regressions: a tracked vendor file, a removed
  ignore rule, a missing package dependency contract, tracked bytecode,
  removed hosted package verification, and wildcard IAM permission broadening.

## Remaining Risks

- The historical binary blobs remain in Git history unless a separately
  authorized history rewrite is performed.
- Package construction does not validate AWS account configuration, Lambda
  execution, API Gateway behavior, or real external-service credentials.
- Future dependency upgrades still require compatibility testing against the
  Chalice, OpenAI, Pinecone, and boto3 APIs used by the application.
