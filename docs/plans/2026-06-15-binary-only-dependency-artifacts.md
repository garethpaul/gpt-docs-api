---
title: Binary-Only Dependency Artifacts
type: security
status: completed
date: 2026-06-15
execution: code
---

# Binary-Only Dependency Artifacts

## Problem

The generated dependency lock verifies package archive hashes, but CI and
Chalice packaging still permit source distributions. A source archive can be
hash-verified and then produce a locally built wheel whose contents depend on
the build environment rather than a reviewed binary artifact.

## Approach

- Require binary distributions for the clean CI installation and the Chalice
  package resolver.
- Keep hash verification, exact versions, Python 3.10, the x86-64 manylinux
  target, and the dependency upload cutoff unchanged.
- Add a clean binary-only installation gate and static contracts for CI,
  package construction, guidance, and completed verification evidence.

## Files

- `.github/workflows/check.yml`
- `scripts/verify-chalice-package.sh`
- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `AGENTS.md`
- `docs/plans/2026-06-15-binary-only-dependency-artifacts.md`

## Verification

- Install the full hash-locked dependency set into a clean Python 3.10
  environment with source builds disabled, then run `pip check`.
- Run repository and external-directory `make check` plus the credential-free
  Chalice package gate.
- Reject isolated CI, package, guidance, and plan-evidence mutations.
- Audit the exact diff, generated artifacts, and secret patterns.

## Non-Goals

- Do not update package versions, change the lock target, deploy to AWS, or
  modify application and IAM behavior.
- Do not claim binary wheels are reproducible builds; this boundary prevents
  unreviewed local source builds during verified installation and packaging.
- Do not merge or close stacked pull requests without owner authorization.

## Status: Completed

## Work Completed

- Required binary-only dependency resolution in the hosted clean install and
  credential-free Chalice package build while retaining hash verification.
- Added static contracts that reject source-build fallback at either resolver
  entry point.
- Updated maintained supply-chain guidance and completed-plan evidence.

## Verification Completed

- A clean Python 3.10 binary-only install passed with hash verification and
  `pip check`.
- The repository and external-directory `make check` passed all 46 API tests,
  compile checks, lock contracts, and extension checks.
- The credential-free Chalice package gate passed and retained the reviewed
  Python 3.10 runtime dependencies and scoped IAM policy.
- Six hostile mutations failed for CI binary policy, package binary policy,
  hash preservation, package environment preservation, guidance, and plan evidence.
- Exact diff, generated-artifact, conflict-marker, and secret-pattern audits passed.
- No live AWS, OpenAI, Pinecone, Twilio, or API Gateway operations were executed.
