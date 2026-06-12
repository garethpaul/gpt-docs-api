## GPT Docs API Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

GPT Docs API is an experimental Q&A interface for Twilio documentation using
crawled docs, embeddings, Pinecone, DynamoDB caching, a Chalice API, and a
Chrome extension surface.

The repository is useful as a retrieval-augmented generation prototype with a
clear disclaimer that it is not an official Twilio project. Project details and
quality gates live in [`README.md`](README.md).

The goal is to keep the experiment useful, testable, and safe around API keys,
documentation crawling, and generated answers.

The current focus is:

Priority:

- Preserve deterministic local tests that do not require live credentials
- Require caller authentication before API routes spend server AI credentials
- Keep OpenAI, Pinecone, and AWS credentials out of git
- Maintain the disclaimer and public-docs scope
- Keep crawling, embedding, retrieval, and answer generation boundaries clear
- Preserve Twilio link host filtering for generated answer citations
- Preserve the retrieval metadata guard before answer generation
- Preserve the retrieval context length guard before prompt assembly
- Preserve one-day cache expiration and the DynamoDB `expires_at` TTL attribute
- Preserve fixed-size SHA-256 cache keys so raw user queries are not DynamoDB
  partition-key material
- Keep unexpected route failures behind generic 500 errors
- Keep request validation bounded by a maximum query length before model work
- Keep the classification weight schema explicit and numeric before returning
  model output to callers
- Keep unauthenticated public asset serving path-bound to checked-in assets

Next priorities:

- Improve evaluation of answer quality and citation grounding
- Modernize OpenAI and Pinecone clients in a dedicated pass
- Keep Chrome extension behavior aligned with API changes
- Document crawler scope and robots.txt/respectful access behavior

Contribution rules:

- One PR = one focused API, crawler, embedding, extension, or documentation change.
- Run `make verify` before pushing code changes. The local gate also exposes
  `make lint`, `make test`, `make build`, and `make check` for the standard
  pre-push sequence. GitHub Actions verifies the pinned Python 3.10 dependency
  set and runs the no-live-credentials baseline without persisted checkout
  credentials.
- Do not commit API keys, cached private data, or generated credentials.
- Preserve testability without live OpenAI/Pinecone/AWS dependencies.
- Keep `/ask` and `/classify/builder` behind `GPT_DOCS_API_KEY` or a stronger
  route authorizer.
- Keep Twilio link host filtering on generated answer links.
- Keep the retrieval metadata guard on Pinecone matches before answer
  generation.
- Keep the retrieval context length guard on accepted Pinecone metadata before
  prompt assembly.
- Keep cache expiration enforced before returning generated-answer entries.
- Keep cache reads and writes on the same namespaced query digest while
  retaining the existing DynamoDB table and `query_string` attribute.
- Keep unexpected route failures logged server-side while returning generic 500
  errors to callers.
- Keep the maximum query length guard in request validation.
- Keep the classification weight schema guard on `/classify/builder` responses.
- Keep public asset routes path-bound to `api/chalicelib/public`.
- Keep GitHub Actions aligned with the no-live-credentials local gate.

## Security And Accuracy

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

RAG systems can leak secrets or generate unsupported answers. Keep credentials
server-side, avoid logging sensitive questions, and prefer answers grounded in
retrieved public docs.

The project disclaimer should remain visible.

## What We Will Not Merge (For Now)

- Committed OpenAI, Pinecone, AWS, or Twilio credentials
- Open-ended crawling beyond public docs without scope review
- Answer-generation changes without tests or evaluation notes
- Client library major upgrades bundled with unrelated behavior changes

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
