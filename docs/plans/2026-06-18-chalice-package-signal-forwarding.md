---
title: "fix: Stop Chalice package verification promptly"
type: fix
date: 2026-06-18
status: planned
---

# fix: Stop Chalice package verification promptly

## Summary

Make the temporary Chalice package verifier forward termination signals to its
active package command, so cancellation does not wait for the full package
timeout before cleanup completes.

## Problem Frame

`scripts/verify-chalice-package.sh` traps `HUP`, `INT`, and `TERM`, but the trap
only removes the temporary directory. While the shell is waiting for GNU
`timeout`, signal handling is deferred, and `timeout` runs the package command
in a separate process group. A bounded reproduction showed that terminating
the verifier waited until the child timeout expired instead of exiting
promptly. With the maintained default, that delay can be 600 seconds.

## Requirements

- R1. `HUP`, `INT`, and `TERM` must stop an active package command and return a
  nonzero status promptly.
- R2. Normal successful and failed package verification must retain temporary
  directory cleanup.
- R3. The baseline must reject removal of signal forwarding, active-child
  tracking, or the package gate's cleanup contract.
- R4. Existing package-content, dependency-lock, test, syntax, and baseline
  verification must remain unchanged.

## Implementation

- Track the active package command and forward trapped termination signals to
  it before exiting with the conventional signal-derived status.
- Keep cleanup idempotent and preserve the existing timeout boundary.
- Add a bounded subprocess regression that uses a fake Chalice command to prove
  prompt termination and temporary-directory cleanup.
- Extend the baseline's static and mutation contracts and record the fix in
  `CHANGES.md`.

## Scope Boundaries

- No application, OpenAI, Pinecone, AWS, Twilio, IAM, dependency-lock, package
  content, workflow, credential, or deployment behavior changes.
- No live provider, package publication, or deployment operation is executed.

## Verification Planned

- Run the focused package-signal regression and shell syntax checks.
- Run the maintained package gate with its existing bounded timeout.
- Run `make verify` and the external-directory baseline gate.
- Prove isolated mutations are rejected for signal-forwarding, child-tracking,
  cleanup, test, and plan-evidence regressions.
- Confirm no generated package, bytecode, cache, credential, or secret artifact
  remains in the worktree.
