---
title: Source Baseline Guard
type: chore
status: completed
date: 2026-06-08
---

# Source Baseline Guard

## Summary

Add a repository-owned source guard that preserves the deterministic unit test,
compile, dependency, and documentation baseline for the Chalice GPT Docs API.

## Requirements

- R1. `make verify` must run tests, syntax compilation, and the source guard.
- R2. `CHANGES.md` must record maintenance history.
- R3. The guard must protect compatible dependency pins and import-safe helper
  boundaries.
- R4. The guard must preserve no-credential cache, utility, and OpenAI adapter
  tests.
- R5. README and VISION must document `make verify` and the external service
  credential boundary.

## Verification

- `make verify`
- `scripts/check-baseline.sh`
- `git diff --check`
