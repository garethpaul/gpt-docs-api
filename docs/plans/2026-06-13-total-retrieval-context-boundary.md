# Total Retrieval Context Boundary

status: in_progress

## Context

`metadata_text_and_url` caps each Pinecone match at 4,000 characters, but
`make_query` can join up to five matches before calling OpenAI. The actual model
input can therefore contain roughly 20,000 retrieval characters plus separators
and the user query despite the documented 4,000-character retrieval boundary.

## Priority

This is a direct external-AI cost, latency, and availability boundary on an
authenticated route. A single total budget is more defensible than multiplying
the nominal limit by the provider result count.

## Scope

1. Apply `MAX_RETRIEVAL_CONTEXT_LENGTH` to the complete joined retrieval
   context, including separators.
2. Preserve match order and truncate only the final included context needed to
   fill the remaining budget.
3. Return links only for contexts included in the generated prompt.
4. Add focused multi-match, separator, truncation, and excluded-link coverage.
5. Extend the baseline and synchronize README, SECURITY, VISION, and CHANGES.

## Verification Plan

- Run focused and all API tests, Python compilation, every Make gate, package
  verification, shell syntax, diff checks, and intended-file secret scans.
- Remove the aggregate budget, exclude separator accounting, and remove the
  regression test; each hostile mutation must fail.
- Push a stacked pull request and take one bounded exact-head workflow, check,
  and CodeQL snapshot without polling.

## Risk And Rollback

Queries with more than 4,000 total retrieval characters will send less provider
context to OpenAI. Match order and the original user query remain unchanged.
Rollback restores the multiplied context size; there is no stored-data or API
schema migration.
