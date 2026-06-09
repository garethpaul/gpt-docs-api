# Changes

## 2026-06-09

- Tightened request query validation so `/ask` and `/classify/builder` reject
  whitespace-only or non-string queries before OpenAI or Pinecone work starts.
- Added Twilio link host filtering so generated answer links must use HTTPS
  `twilio.com` or `*.twilio.com` hosts.

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
