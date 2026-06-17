---
title: "refactor: Migrate to the OpenAI v2 client"
type: refactor
date: 2026-06-17
status: planned
---

# refactor: Migrate to the OpenAI v2 client

## Summary

Replace the retired module-level OpenAI Python interface with the current
instance client while preserving the API's existing embedding, answer, and
classification behavior. Upgrade the reviewed dependency pin to
`openai==2.41.0` and regenerate the hash-addressed Python 3.10 deployment lock.

---

## Problem Frame

The application pins `openai==0.28.1`, released in 2023, and calls
`Embedding.create` and `ChatCompletion.create` on the imported module. Current
OpenAI Python releases use an `OpenAI` instance with resource clients and typed
response objects, so the existing integration blocks dependency maintenance
and will fail if the dependency is upgraded without coordinated code and test
changes.

---

## Requirements

- R1. OpenAI calls must use an explicit client instance configured from the
  existing API-key environment variable.
- R2. Embedding requests must preserve the configured model and return the
  first embedding vector from the current response shape.
- R3. Answer and classification requests must preserve their current models,
  messages, prompts, error semantics, and returned text or validated weights.
- R4. Tests must remain credential-free and inject deterministic fake clients
  without importing or contacting live OpenAI services.
- R5. The direct dependency and hash-addressed deployment lock must pin
  `openai==2.41.0` for the repository's Python 3.10 manylinux target.
- R6. Maintained checks and documentation must reject restoration of the
  module-level pre-v1 API or stale dependency evidence.

---

## Key Technical Decisions

- **Keep Chat Completions for this migration:** the current endpoint maps
  directly to the existing message contract, while a Responses API migration
  would also change response extraction and prompt semantics.
- **Construct clients behind a small helper:** production code reads the API
  key when a call begins, while tests can continue passing a client object and
  avoid import-time credentials or network activity.
- **Use current typed response attributes:** embedding data and chat message
  content are read through resource-object attributes instead of retaining
  dictionary compatibility that could conceal an incomplete migration.
- **Regenerate, do not hand-edit, the dependency lock:** the reviewed `uv pip
  compile` target remains Python 3.10 on manylinux with hashes and the existing
  package cutoff.

---

## Implementation Units

### U1. Migrate the OpenAI runtime boundary

- **Goal:** Use the current `OpenAI` instance API for embeddings and chat
  completions without changing endpoint behavior.
- **Requirements:** R1, R2, R3.
- **Files:** `api/chalicelib/classification.py`.
- **Approach:** Add a production client factory using the existing API-key
  environment variable, preserve injectable client arguments, call the
  current embeddings and chat-completions resources, and extract typed
  response values.
- **Execution note:** Update characterization tests before replacing the
  legacy calls.
- **Test scenarios:** A configured fake client receives the expected embedding
  and chat request arguments; embedding vectors and message text are returned;
  malformed classification output and provider failures preserve current
  validation and wrapping behavior; no API key causes client construction to
  fail without a network request.
- **Verification:** Runtime tests prove all three OpenAI call paths use only the
  instance resources and preserve their established outputs.

### U2. Update offline contracts and documentation

- **Goal:** Make the client migration durable and understandable without live
  provider access.
- **Requirements:** R4, R6.
- **Dependencies:** U1.
- **Files:** `api/tests/test_classification.py`, `scripts/check-baseline.sh`,
  `README.md`, `VISION.md`, `CHANGES.md`.
- **Approach:** Replace legacy module-shaped doubles with instance-resource
  doubles, add mutation-sensitive static requirements for the factory and
  resource calls, and update maintenance guidance to distinguish completed
  OpenAI modernization from the deferred Pinecone migration.
- **Test scenarios:** The baseline rejects module-level `Embedding` or
  `ChatCompletion` calls, missing client-factory coverage, and stale guidance;
  the full test suite imports without credentials or installed provider state.
- **Verification:** Focused and complete tests plus the maintained baseline
  pass without live OpenAI, Pinecone, AWS, Twilio, or deployment calls.

### U3. Upgrade and verify the deployment dependency lock

- **Goal:** Produce a reproducible binary-only deployment set containing
  `openai==2.41.0` and its current transitive dependencies.
- **Requirements:** R5, R6.
- **Dependencies:** U1, U2.
- **Files:** `api/requirements.in`, `api/requirements.txt`,
  `scripts/check-dependency-lock.py`.
- **Approach:** Update the reviewed direct pin, regenerate the lock using its
  recorded command and cutoff, then update exact package-count and pin
  contracts from the generated result.
- **Test scenarios:** Dependency validation rejects the legacy pin, missing or
  malformed hashes, duplicate packages, unexpected direct requirements, and a
  lock whose reviewed package count does not match the generated set.
- **Verification:** Dependency consistency, binary-wheel availability, the
  Chalice package inspection, and all repository gates pass on Python 3.10.

---

## Scope Boundaries

### Deferred to Follow-Up Work

- Migrate `pinecone-client[grpc]==2.2.4` to the current Pinecone SDK and its
  control-plane/index construction APIs.
- Evaluate the Responses API or newer OpenAI model defaults as separate
  product and prompt-contract changes.

### Out of Scope

- Live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, or deployment
  requests.
- Changes to retrieval context, citations, caching, authentication, public
  assets, or endpoint response schemas.
- Unpinning direct dependencies or weakening the hash and binary-artifact
  policy.

---

## Risks And Dependencies

- OpenAI 2.41.0 requires Python 3.9 or newer; the deployment lock targets
  Python 3.10, so package verification must prove wheel availability for that
  exact platform.
- Typed response extraction is intentionally stricter than dictionary access;
  test doubles must reflect the supported production interface rather than a
  hybrid compatibility layer.
- Transitive dependency changes can alter package size or Chalice packaging;
  package inspection remains a release gate.

---

## Sources And Research

- [OpenAI Python library](https://github.com/openai/openai-python) documents
  explicit `OpenAI` clients and resource-based requests.
- [Embeddings API reference](https://platform.openai.com/docs/api-reference/embeddings?lang=python)
  uses `client.embeddings.create` and typed embedding data.
- [Chat Completions API reference](https://platform.openai.com/docs/api-reference/chat/create)
  confirms the existing message-oriented endpoint remains supported while
  recommending Responses for new product work.
- [OpenAI 2.41.0 package metadata](https://pypi.org/project/openai/2.41.0/)
  records the current release and Python `>=3.9` requirement.
