---
title: Pip Bootstrap Pin
date: 2026-06-12
status: completed
execution: code
---

# Pip Bootstrap Pin

## Summary

Replace the Python 3.10 workflow's floating pip upgrade with exact
`pip==26.1.2` while preserving the stacked deployment-ownership and Chalice
vendor-cleanup changes, package construction, tests, requirements, and runtime.

## Priority

The hosted job currently resolves the newest installer before installing an
otherwise pinned direct dependency set. Pinning pip removes a moving
supply-chain input and makes the reviewed package gate more reproducible.

## Requirements

- Bootstrap exactly `pip==26.1.2`; official PyPI metadata declares Python
  `>=3.10` compatibility.
- Reject floating, alternate, missing, and duplicate installer bootstraps.
- Preserve Python 3.10, `api/requirements.txt`, `pip check`, `make
  package-check`, `make check`, Vercel opt-out, and the PR #22 stacking
  prerequisite.
- Keep application, tests, package inputs, and deployment behavior unchanged.
- Record local, external-working-directory, hostile-mutation, and exact-head
  hosted evidence truthfully.

## Supply-Chain Evidence

Official PyPI JSON metadata reported non-yanked `pip 26.1.2` on 2026-06-12.
The universal wheel SHA-256 is
`382ff9f685ee3bc25864f820aa50505825f10f5458ffff07e30a6d96e5715cab`; the
source archive SHA-256 is
`f49cd134c61cf2fd75e0ce2676db03e4054504a5a4986d00f8299ae632dc4605`.
This unit pins resolution but does not yet authenticate downloads by hash.

## Work Completed

- Replaced the floating upgrade with one exact installer bootstrap.
- Added exact workflow, checker, plan, and guidance contracts.

## Verification Completed

- Local and external-working-directory verification passed the canonical
  source, test, and workflow contracts.
- Python 3.10 installed exact `pip 26.1.2` and the declared requirements;
  `pip check` passed with no broken dependencies.
- The temporary Chalice package construction and structural archive gate passed
  without live AWS, OpenAI, or Pinecone credentials.
- Workflow parsing, shell syntax, and `git diff --check` passed.
- Focused hostile mutations rejected floating, alternate, missing, and
  duplicate bootstraps plus incomplete plan and documentation evidence; all
  hostile mutations rejected.
- Exact-head hosted evidence remains pending until this successor is pushed.
