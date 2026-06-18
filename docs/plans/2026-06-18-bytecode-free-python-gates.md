---
title: "fix: Keep Python gates artifact-free"
type: fix
date: 2026-06-18
status: planned
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
  55-test, extension-rendering, and API-baseline coverage.

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

## Verification Planned

- Run the focused syntax-helper regression and complete test suite.
- Run all maintained Make gates from the repository root and `make check` from
  `/tmp`, then prove no cache artifact remains.
- Reject isolated mutations for helper ownership, compileall restoration,
  bytecode-env removal, regression weakening, artifact guard removal, and plan
  evidence weakening.
- Audit exact paths, whitespace, secrets, dependency/workflow drift, conflict
  markers, and file modes before commit and push.
