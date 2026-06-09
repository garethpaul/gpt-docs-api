# Twilio Link Host Filtering

status: completed

## Context

`make_query` returns links from Pinecone metadata beside generated answers. The
previous filter kept any URL containing the substring `twilio.com`, which could
admit unrelated hosts that only mentioned Twilio in a path or query string.

## Completed Scope

- Added a host-aware helper that accepts only HTTPS `twilio.com` or
  `*.twilio.com` URLs.
- Replaced substring filtering with deterministic, de-duplicated host filtering.
- Covered the helper and `make_query` link filtering without live OpenAI or
  Pinecone credentials.
- Extended the source baseline and docs to preserve the citation boundary.

## Verification

- `make verify`
- `git diff --check`
