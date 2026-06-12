# AGENTS.md

## Repository purpose

`garethpaul/gpt-docs-api` is a static web project. Q&A Type Interface to ask questions against the Twilio docs with GPT-4.

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `api` - repository source or sample assets
- `chrome_extension` - repository source or sample assets
- `screenshots` - repository source or sample assets

## Development commands

- Install dependencies: no repository-specific install command is documented.
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Python (8), JavaScript (4).

## Testing guidance

- Test-related files detected: `api/chalicelib/public/test.html`, `api/tests/`, `api/tests/test_app_auth.py`, `api/tests/test_auth.py`, `api/tests/test_cache.py`, `api/tests/test_classification.py`, `api/tests/test_utils.py`, `api/vendor/aiohttp/pytest_plugin.py`, `api/vendor/aiohttp/test_utils.py`, `api/vendor/numpy/_pyinstaller/test_pyinstaller.py`
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- Detected references to OpenAI, Pinecone, AWS, and Twilio. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- Set `GPT_DOCS_API_KEY` on deployments that expose `/ask` or `/classify/builder`. Callers must send the same value in `X-GPT-Docs-API-Key` or `Authorization: Bearer <token>` before those routes read request bodies or spend server-side OpenAI/Pinecone credentials.
- Set `OPENAI_API_KEY`, `PINECONE_API_KEY`, `PINECONE_ENVIRONMENT`, and AWS credentials only in local or deployment environment configuration.
- Keep `/ask` and `/classify/builder` behind the shared caller API-key guard or a stronger API Gateway/JWT authorizer. Public asset routes may remain unauthenticated, but public asset routes must stay path-bound to `api/chalicelib/public`.
- Keep request query validation bounded by a maximum query length before routes invoke OpenAI, Pinecone, DynamoDB, or cache helpers.
- Keep the classification weight schema limited to numeric `with_code`, `minimal_code`, and `no_code` values.
- Checked-in binary libraries are present; do not replace them without documenting toolchain and checksums.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
