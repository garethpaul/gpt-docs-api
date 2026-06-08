import os
import hmac
from typing import Mapping, Optional

from chalicelib.config import GPT_DOCS_API_KEY_ENV, GPT_DOCS_API_KEY_HEADER


class AuthenticationConfigurationError(Exception):
    """Raised when the API is deployed without caller auth configured."""


class AuthenticationError(Exception):
    """Raised when a caller does not present valid API credentials."""


def _normalise_headers(headers: Optional[Mapping[str, str]]) -> Mapping[str, str]:
    if not headers:
        return {}
    return {
        str(key).lower(): str(value)
        for key, value in headers.items()
        if value is not None
    }


def _bearer_token(authorization_header: str) -> Optional[str]:
    scheme, _, token = authorization_header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        return None
    return token.strip()


def require_api_key(headers, environ=os.environ) -> None:
    """
    Require a shared caller API key before routes spend server credentials.

    The Chrome extension or another trusted caller can send either
    X-GPT-Docs-API-Key or Authorization: Bearer <token>. The server-side
    expected value must come from GPT_DOCS_API_KEY so deployments fail closed
    instead of silently exposing OpenAI/Pinecone-backed routes.
    """
    expected_key = environ.get(GPT_DOCS_API_KEY_ENV, "").strip()
    if not expected_key:
        raise AuthenticationConfigurationError(
            "API authentication is not configured"
        )

    normalised_headers = _normalise_headers(headers)
    provided_key = normalised_headers.get(GPT_DOCS_API_KEY_HEADER.lower())
    if not provided_key:
        provided_key = _bearer_token(normalised_headers.get("authorization", ""))

    if not hmac.compare_digest(str(provided_key).strip(), expected_key):
        raise AuthenticationError("Unauthorized")
