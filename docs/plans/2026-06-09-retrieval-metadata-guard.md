# Retrieval Metadata Guard

status: completed

## Context

`make_query` builds generated answer context from Pinecone match metadata. The
previous code directly indexed each match's `metadata.text` and `metadata.url`,
so a malformed or incomplete retrieval result could turn the `/ask` route into a
500 instead of using the remaining valid context.

## Completed Scope

- Added a retrieval metadata helper that accepts only non-empty string `text`
  values and normalizes missing or non-string URLs to an empty value.
- Updated `make_query` to skip incomplete matches before assembling the
  augmented prompt.
- Preserved Twilio host filtering for generated answer links.
- Covered incomplete retrieval metadata with deterministic route tests that do
  not require live OpenAI or Pinecone credentials.
- Extended the source baseline and docs to preserve the retrieval metadata
  guard.

## Verification

- `make verify`
- `git diff --check`
