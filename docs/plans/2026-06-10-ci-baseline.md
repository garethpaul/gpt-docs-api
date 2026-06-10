# GPT Docs API CI Baseline

status: completed

## Context

The project already has deterministic tests and source checks that avoid live
OpenAI, Pinecone, AWS, or Twilio credentials. The missing guard was hosted CI
that runs the same baseline on pushes and pull requests.

## Changes

- Added a least-privilege GitHub Actions workflow for pushes, pull requests,
  and manual runs.
- Pinned checkout and Python setup by commit and bounded superseded runs with
  cancellation and a timeout.
- Installed the checked-in `api/requirements.txt` pins on Python 3.10 and ran
  `pip check` before the repository baseline.
- Ran `make check` as the hosted baseline, matching local verification.
- Extended the baseline script and docs to keep the CI workflow part of the
  maintained project contract.

## Verification

- `make check`
- `git diff --check`
- Hosted Python 3.10 GitHub Actions run
