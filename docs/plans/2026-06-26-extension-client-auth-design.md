# Extension Client Authentication Design

Status: approved

## Problem

Both checked-in Manifest V3 clients call `/ask` and `/classify/builder`
without either credential accepted by the deployed API. Embedding the
deployment's shared `GPT_DOCS_API_KEY` in either extension bundle would expose
the server secret to every installer.

## Evidence

- `api/chalicelib/auth.py` accepts `X-GPT-Docs-API-Key` or a bearer token and
  fails closed when the server secret is absent or mismatched.
- `api/chalicelib/public/content.js` and `chrome_extension/content.js` make both
  API requests without an authorization header.
- Both manifests are Manifest V3 extension bundles, so the same client model
  can cover the deployed public assets and the source extension.
- Chrome documents that content scripts run in an isolated world and can
  message extension contexts.
- Chrome documents that `storage.session` is memory-only, is cleared on browser
  restart, is not exposed to content scripts by default, and requires Chrome
  102+ in Manifest V3.
- Chrome documents that content-script cross-origin requests remain subject to
  the page origin and CORS, so the configured self-hosted API must explicitly
  permit the Twilio Docs origins.

Official references:

- https://developer.chrome.com/docs/extensions/develop/concepts/content-scripts
- https://developer.chrome.com/docs/extensions/reference/api/storage
- https://developer.chrome.com/docs/extensions/develop/concepts/network-requests

## Options

### 1. Ship the deployment secret

Rejected. A bundled key is public and recreates the unauthenticated spending
boundary under a recoverable shared credential.

### 2. Add a hosted identity-aware proxy

Rejected for this maintenance change. It would require a new account system,
token lifecycle, authorization model, and production service.

### 3. Require per-user self-hosted configuration

Selected. Users provide their own HTTPS API base URL and their own deployment
key. The base URL persists locally; the key remains only in
`chrome.storage.session` and must be re-entered after browser restart.

## Design

Add one options page and one background service worker to each mirrored
extension bundle. The options page validates an HTTPS base URL, stores it in
`chrome.storage.local`, and stores the key in `chrome.storage.session`. The
background worker returns the current configuration only to messages from its
own extension, and the content script requests it through `chrome.runtime`.

The content script builds fixed `/ask` and `/classify/builder` URLs from the
configured base URL, adds `X-GPT-Docs-API-Key`, and performs the existing CORS
requests. It never accepts an arbitrary route from page content, never logs the
key, and fails with a deterministic configuration message before network work
when either value is missing.

Both extension directories keep byte-identical authentication helpers,
background workers, and options assets. Existing response rendering remains
text-only and URL-filtered.

## Error Handling

- Missing configuration: show a user-facing prompt to open extension options;
  do not call `fetch`.
- Invalid base URL: reject it in the options page and again in the content
  helper; require HTTPS and remove trailing slashes.
- API 401/503 or CORS/network failure: preserve the existing failed-request
  path without exposing credentials or server internals.
- Browser restart: the endpoint remains, but the session key is absent until
  the user enters it again.

## Validation

- Node VM tests prove both routes use the configured base URL and API-key
  header.
- Tests prove missing or invalid configuration makes zero network requests.
- Tests prove the key is stored only in `storage.session`, never in local or
  sync storage.
- Baseline contracts require mirrored assets, Manifest V3 storage/options/
  background declarations, guidance, and completed plan evidence.
- Run `make verify`, extension rendering checks, syntax checks, hostile
  mutations, secret scanning, and hosted CodeQL.

## Residual Risk

The user-supplied key is available to the extension process while the browser
session is active and the self-hosted API must configure CORS correctly. The
design does not provide per-user authorization for the repository owner's
hosted deployment; that requires a separate identity-aware service.
