# Changes

## 2026-06-08

- Added a repository changelog for maintenance history.
- Added a shared API-key guard for `/ask` and `/classify/builder` so public
  callers cannot spend server OpenAI/Pinecone credentials without
  `GPT_DOCS_API_KEY` authorization.
- Added a source baseline guard and wired it into `make verify`.
- Preserved deterministic unit tests and compile checks for the Chalice API
  without requiring live OpenAI, Pinecone, AWS, or Twilio credentials.
