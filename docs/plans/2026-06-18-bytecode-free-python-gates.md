---
title: "fix: Keep Python gates artifact-free"
type: fix
date: 2026-06-18
status: completed
---

# fix: Keep Python gates artifact-free

## Summary

Replace disk-writing `compileall` validation with an in-memory syntax helper
and make maintained Python test commands bytecode-free, so verification leaves
the repository clean by construction.

## Problem Frame

`make compile` and `scripts/check-baseline.sh` both call
`python -m compileall`. That command intentionally writes eleven `.pyc` files
across three `__pycache__` directories even when callers set
`PYTHONDONTWRITEBYTECODE=1`, contradicting the repository's generated-artifact
policy and repeatedly dirtying otherwise clean validation worktrees.

## Requirements

- R1. Maintained Python syntax validation must reject invalid application and
  test sources without writing bytecode.
- R2. Maintained unittest commands must disable bytecode writes explicitly.
- R3. The baseline must reject a return to `compileall`, weakened test
  invocation, missing regression coverage, or generated cache artifacts.
- R4. Root and external-directory gates must retain dependency-lock,
  57-test, extension-rendering, and API-baseline coverage.

## Implementation

- Add `scripts/check-python-syntax.py` to compile source bytes in memory.
- Route Make and baseline syntax checks through the helper and disable bytecode
  writes on maintained unittest invocations.
- Add a subprocess regression covering valid syntax, invalid syntax, and an
  empty redirected cache directory.
- Extend the baseline's static, artifact, plan-evidence, and mutation contracts;
  record the maintenance change in `CHANGES.md`.

## Scope Boundaries

- No application, OpenAI, Pinecone, AWS, Twilio, Chalice, dependency-lock,
  workflow-version, credential, or deployment behavior changes.
- Existing inherited main-branch vendor alerts remain owned by open PR #23.
- No live provider or deployment operation is executed.

## Verification Completed

- The 3 focused syntax-helper and artifact-guard regressions passed, and the
  complete API suite passed with 57 tests.
- All four Make gates passed independently: `make lint`, `make test`,
  `make build`, and `make check`.
- The external-directory Make gate also passed from `/tmp` with the same
  dependency-lock, test, extension-rendering, and API-baseline coverage.
- No `__pycache__`, `.pyc`, or `.pyo` artifact remained after the root and
  external-directory gates.
- Eight isolated mutations were rejected for compileall
  restoration, bytecode-environment removal, in-memory compile removal,
  cache-assertion weakening, artifact-guard removal, invalid-syntax success,
  plan-status regression, and plan-evidence removal.
- No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, Chalice package,
  or deployment operation was executed.
