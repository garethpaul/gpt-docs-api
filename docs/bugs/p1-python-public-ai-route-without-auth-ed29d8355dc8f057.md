# [P1] Require caller authentication before public AI API routes spend server credentials

## Severity

P1 - security/authentication

## Evidence

- `api/app.py:30`: `allow_origin='*',`
- `api/app.py:171`: `@app.route('/ask', methods=['POST'], cors=cors_config)`
- `api/app.py:182`: `request_json = app.current_request.json_body`
- `api/app.py:197`: `response, links = make_query(query)`
- `api/chalicelib/classification.py:4`: `from chalicelib.config import OPENAI_API_KEY_ENV, EMBEDDING_MODEL, GPT_MODEL`
- `api/chalicelib/classification.py:12`: `res = openai_client.Embedding.create(`
- `api/chalicelib/config.py:6`: `PINECONE_API_KEY_ENV = 'PINECONE_API_KEY'`
- `api/chalicelib/public/content.js:345`: `fetch("https://wj2mszjum0.execute-api.us-west-2.amazonaws.com/api/ask", {`

## Problem

The application exposes POST routes that accept caller-supplied JSON and call OpenAI-backed helpers using server-side API keys without checking an inbound authorization header, API key, or request authorizer. A reachable deployment lets arbitrary callers consume the configured model and vector search credentials, creating quota, cost, and abuse risk.

## Suggested fix

Require an API Gateway authorizer, JWT/session, or dedicated proxy API key before reading the request body or invoking OpenAI/Pinecone, narrow wildcard CORS where possible, add rate limits, and cover unauthenticated requests with tests that prove the model helpers are not called.

## Review metadata

- Repository: `garethpaul/gpt-docs-api`
- Reviewed commit: `e4476677155dfa2559c01f8e4e2673a69659774e`
- Labels: `bug`, `codex-review`, `severity:P1`
- Codex review fingerprint: `ed29d8355dc8f057`
