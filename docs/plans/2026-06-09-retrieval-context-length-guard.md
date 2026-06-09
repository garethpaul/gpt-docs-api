# Retrieval Context Length Guard

status: completed

## Context

Request query validation already caps user-supplied query text before `/ask`
spends OpenAI, Pinecone, DynamoDB, or cache work. Retrieved Pinecone metadata
text was accepted after shape validation but before any size boundary, so one
oversized match could expand the generated-answer prompt without bound.

## Completed Scope

- Added a per-match retrieval context length cap before prompt assembly.
- Preserved existing metadata shape validation, Twilio host filtering, and
  generated response shape.
- Added a deterministic fake-index regression test for overlong metadata text.
- Extended the source baseline and docs so the prompt context boundary remains
  visible.

## Verification

- `PYTHONPATH=api python -m unittest api.tests.test_app_auth`
- `make verify`
- `git diff --check`
