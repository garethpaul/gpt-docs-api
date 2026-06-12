---
title: Vercel Deployment Ownership
type: fix
status: completed
date: 2026-06-12
origin: repository-wide pull request audit
execution: code
---

# Vercel Deployment Ownership

## Context

The repository began as a Vercel Flask sample with `api/index.py` and a rewrite
that sent every request to `/api/index`. Commit `2ad24a9` deleted that function
when the API moved to AWS Chalice in April 2023, but the original rewrite and
connected Vercel project remained. Vercel therefore reported failed production
deployments on otherwise green commits while GitHub Pages continued to publish
the static repository content successfully.

The Chalice entry point uses the AWS Lambda event/context interface, its pinned
dependencies live under `api/`, and the repository includes historical binary
vendor artifacts. Treating that tree as an inferred Vercel Python function
would create a second, undocumented deployment architecture rather than repair
the maintained one.

## Requirements

- R1. Automatic Vercel Git deployments must be disabled for every branch.
- R2. The configuration must use the current `git.deploymentEnabled` setting.
- R3. The retired `/api/index` rewrite must not remain in configuration.
- R4. The canonical baseline must parse the configuration and reject missing,
  malformed, selectively enabled, or globally enabled deployment settings.
- R5. Documentation must identify the Chalice API target and GitHub Pages as
  the maintained deployment surfaces.
- R6. Existing API, extension, test, and GitHub Actions behavior must remain
  unchanged.

## Implementation

- Added root `vercel.json` with `git.deploymentEnabled` set to `false`.
- Added a structured JSON contract to `scripts/check-baseline.sh`.
- Documented deployment ownership in the README, vision, and changelog.

## Verification

- `make verify`
- `git diff --check`
- A mutation that sets `git.deploymentEnabled` to `true` must fail.
- A mutation that replaces the global boolean with a branch map must fail.
- A mutation that restores the `/api/index` rewrite must fail.
- A mutation that removes `vercel.json` must fail.

Completed on 2026-06-12 after the full offline API and extension baseline passed
and hostile Vercel configuration mutations were rejected.

## Work Completed

- Disabled automatic Vercel Git deployments globally with the current
  `git.deploymentEnabled` setting and removed the retired `/api/index` rewrite.
- Preserved AWS Chalice as the maintained API target and GitHub Pages as the
  maintained static publishing surface.
- Added structured configuration validation and deployment-ownership
  documentation without changing API, extension, test, or Actions behavior.

## Verification Completed

- `make verify`, all 41 API tests, Python compilation, the API baseline,
  extension-rendering checks, and `git diff --check` passed locally on Python
  3.12.
- Implementation push run `27395011365` and pull-request run `27395017871`
  passed at commit `e8787d8914229c5524d267820284cfe3a753ae67`.
- Mutations enabling deployments globally, using a branch map, restoring the
  retired rewrite, or removing `vercel.json` were rejected by the baseline.
- This evidence validates the repository configuration; no claim is made that
  an external Vercel project setting was inspected through the Vercel API.
