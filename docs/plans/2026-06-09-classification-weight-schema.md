# Classification Weight Schema

status: completed

## Context

`/classify/builder` asks OpenAI for a JSON object with `with_code`,
`minimal_code`, and `no_code` weights. The route previously returned whatever
JSON object the model produced, which allowed missing keys, extra keys, strings,
booleans, or non-finite values to become part of the API response.

## Completed Scope

- Added a classifier weight schema helper for the three expected labels.
- Rejected missing, extra, non-numeric, non-finite, and out-of-range weights.
- Preserved the existing wrapped `Failed to generate classification` error
  contract for malformed model responses.
- Added deterministic unit tests with fake OpenAI clients and extended the
  source baseline guard.
- Updated README, VISION, CHANGES, and SECURITY notes so the model-output
  boundary stays visible.

## Verification

- `PYTHONPATH=api python -m unittest api.tests.test_classification`
- `make verify`
- `git diff --check`
