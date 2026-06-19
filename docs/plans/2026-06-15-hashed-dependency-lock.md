---
title: Hashed Deployment Dependency Lock
type: security
status: completed
date: 2026-06-15
execution: code
---

# Hashed Deployment Dependency Lock

## Summary

Separate direct API dependency intent from a generated, hash-addressed Python
3.10 Linux deployment lock, and make both hosted installation and Chalice
package verification consume that lock without changing application behavior.

---

## Problem Frame

`api/requirements.txt` pins four direct packages, but every transitive and build
dependency is resolved again during each hosted install and Chalice package
build. The same repository head can therefore install different package
versions or artifacts over time, and the current package gate cannot prove
that downloaded distributions match reviewed hashes.

The deployment target is already fixed to Python 3.10 on hosted Linux. A
resolver run for that target produces 47 packages, so the repository can make
the full dependency graph reviewable without introducing a new runtime or
changing the direct package choices.

---

## Requirements

- **R1:** Preserve the four current direct dependency declarations in a small,
  human-maintained input manifest.
- **R2:** Commit one generated Python 3.10 Linux lock containing exact versions
  and SHA-256 hashes for every direct, transitive, and build dependency.
- **R3:** Hosted dependency installation must fail if a package is missing from
  the lock, has an unreviewed version, or cannot match a recorded hash.
- **R4:** Temporary Chalice package construction must consume the same lock and
  must not fall back to unconstrained transitive resolution.
- **R5:** The baseline must reject lock truncation, missing hashes, target drift,
  direct-input drift, unhashed install commands, package-gate bypasses,
  documentation drift, and incomplete plan evidence.
- **R6:** Existing API behavior, direct dependency versions, Python 3.10 runtime,
  credential isolation, package contents, and repository artifact boundaries
  must remain unchanged.

---

## Key Technical Decisions

- **Keep intent and resolution separate:** `api/requirements.in` remains the
  concise source of the four reviewed direct dependencies, while
  `api/requirements.txt` becomes generated output for installation and
  packaging.
- **Lock for the deployment target and review date:** generate for CPython 3.10
  on x86-64 manylinux with a 2026-06-15 upload cutoff rather than the
  developer's current interpreter, host platform, or a moving package index.
- **Authenticate distributions at install time:** use pip's hash-required mode
  so exact versions alone cannot silently accept a replaced or different
  artifact.
- **Keep one lock authority:** CI and the temporary Chalice project consume the
  same committed lock; no second constraints file or generated vendor tree is
  introduced.

---

## Assumptions

- The existing Python 3.10 x86-64 Linux hosted job represents the repository's
  deployment packaging target.
- The current four direct dependency versions are intentional compatibility
  choices and are not upgraded as part of this supply-chain boundary.
- A generated lock is acceptable repository content even though generated
  package directories and deployment archives remain forbidden.

---

## Implementation Units

### U1. Create The Hashed Deployment Lock

**Goal:** Make direct intent and the complete reviewed resolution independently
visible.

**Requirements:** R1, R2, R6

**Dependencies:** None

**Files:**

- `api/requirements.in`
- `api/requirements.txt`

**Approach:** Move the four existing direct pins to the input manifest and
generate the installation manifest for Python 3.10 x86-64 manylinux with exact
versions, SHA-256 hashes, and a deterministic regeneration header.

**Patterns to follow:** Retain the repository's exact direct pins and generated
artifact exclusions; treat the lock as reviewed source rather than a vendored
environment.

**Test scenarios:**

- The input contains exactly the existing four direct dependency declarations.
- Every resolved package entry is exactly pinned and followed by at least one
  SHA-256 hash.
- Regenerating from the input for the declared target produces no diff.

**Verification:** The lock resolves and installs successfully under Python 3.10
with hash checking enabled, and regeneration is deterministic.

### U2. Enforce The Lock In Hosted And Package Builds

**Goal:** Ensure every dependency-consuming path uses the reviewed lock.

**Requirements:** R3, R4, R6

**Dependencies:** U1

**Files:**

- `.github/workflows/check.yml`
- `scripts/verify-chalice-package.sh`

**Approach:** Install the generated lock in hash-required mode in CI. Copy the
input and lock into the temporary Chalice project, expose the lock as the
project requirements consumed by Chalice, and keep the existing temporary,
credential-free, bounded package inspection unchanged.

**Execution note:** Start by proving the current package and workflow contracts
accept unhashed transitive resolution, then add the enforcement.

**Test scenarios:**

- A normal Python 3.10 install succeeds using only reviewed versions and hashes.
- Removing a required hash makes installation fail before tests or packaging.
- Changing a transitive version without regenerating hashes makes installation
  fail.
- Chalice package construction still contains the required application modules
  and runtime dependencies and excludes tests, credentials, and generated
  repository artifacts.

**Verification:** Hosted-style dependency installation, `pip check`, and the
temporary Chalice package gate all succeed from the committed lock.

### U3. Maintain The Supply-Chain Contract

**Goal:** Prevent future edits from silently returning to floating dependency
resolution.

**Requirements:** R1, R2, R3, R4, R5, R6

**Dependencies:** U1, U2

**Files:**

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `AGENTS.md`
- `docs/plans/2026-06-15-hashed-dependency-lock.md`

**Approach:** Parse the manifests structurally enough to require the direct
input set, complete exact pins and hashes, the declared generation target, and
hash-required install/package commands. Synchronize contributor and security
guidance and require this plan to retain completed, actual verification.

**Test scenarios:**

- Removing a package hash or converting an exact pin to a range is rejected.
- Removing a direct input, changing the target, or adding an unhashed CI install
  is rejected.
- Making the package gate consume the input instead of the lock is rejected.
- Removing guidance or reverting the plan status/evidence is rejected.

**Verification:** Repository and external-directory Make gates pass, and
isolated hostile mutations fail for their intended contract messages.

---

## Scope Boundaries

- Do not upgrade Chalice, OpenAI, Pinecone, boto3, Python, or application code.
- Do not commit installed packages, virtual environments, package archives,
  bytecode, credentials, or resolver caches.
- Do not claim cross-platform or bit-for-bit deployment reproducibility beyond
  the declared Python 3.10 x86-64 manylinux target and recorded artifacts.
- Do not execute live AWS, OpenAI, Pinecone, Twilio, or API Gateway operations.

### Deferred to Follow-Up Work

- Upgrade or replace legacy OpenAI and Pinecone clients with application-level
  compatibility work and focused behavioral tests.
- Add a separately reviewed lock for another architecture or Python runtime if
  the deployment target changes.

---

## Risks And Dependencies

- Resolver output can include platform-specific artifacts; generation and
  verification must use the declared deployment target rather than the host.
- Chalice may transform requirements internally during packaging, so the
  package test must prove the lock is actually honored rather than relying only
  on workflow text.
- Hash-required installation increases maintenance cost when dependencies are
  updated; the documented regeneration command must remain deterministic.

---

## Verification Completed

- The lock checker reported 47 exact, hash-addressed packages and deterministic
  regeneration for the declared Python 3.10 manylinux target.
- A clean Python 3.10 hash-required install passed, followed by `pip check`.
- The temporary Chalice package gate passed with 5,335 archive entries, one
  Python 3.10 function, required runtime packages, and scoped cache access.
- Repository and external-directory Make gates passed.
- Ten hostile mutations failed for direct-input drift, missing hashes,
  malformed hash continuation, truncation, target drift, unhashed CI
  installation, package hash bypass, package lock bypass, guidance drift, and
  plan evidence.
- Diff, generated-artifact, conflict-marker, mode, and changed-line credential
  audits passed.
- No live AWS, OpenAI, Pinecone, Twilio, or API Gateway operations were executed.
