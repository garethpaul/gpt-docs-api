# Changes

## 2026-06-09

- Tightened request query validation so `/ask` and `/classify/builder` reject
  whitespace-only or non-string queries before OpenAI or Pinecone work starts.
- Added a maximum query length guard before OpenAI, Pinecone, DynamoDB, or cache
  helpers receive request payloads.
- Added Twilio link host filtering so generated answer links must use HTTPS
  `twilio.com` or `*.twilio.com` hosts.
- Added a classification weight schema guard so `/classify/builder` only returns
  finite numeric `with_code`, `minimal_code`, and `no_code` weights.

## 2026-06-08

- Added a repository changelog for maintenance history.
- Added a shared API-key guard for `/ask` and `/classify/builder` so public
  callers cannot spend server OpenAI/Pinecone credentials without
  `GPT_DOCS_API_KEY` authorization.
- Added a public file path guard so asset requests stay inside
  `api/chalicelib/public` and missing assets return 404.
- Added a source baseline guard and wired it into `make verify`.
- Preserved deterministic unit tests and compile checks for the Chalice API
  without requiring live OpenAI, Pinecone, AWS, or Twilio credentials.
