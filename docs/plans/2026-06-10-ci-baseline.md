# GPT Docs API CI Baseline

status: completed

## Context

The project already has deterministic tests and source checks that avoid live
OpenAI, Pinecone, AWS, or Twilio credentials. The missing guard was hosted CI
that runs the same baseline on pushes and pull requests.

## Changes

- Added `.github/workflows/check.yml` for GitHub Actions.
- Installed the checked-in `api/requirements.txt` pins on Python 3.10.
- Ran `make check` as the hosted baseline, matching local verification.
- Extended the baseline script and docs to keep the CI workflow part of the
  maintained project contract.

## Verification

- `make check`
- `git diff --check`
