import os
import unittest

from chalicelib.auth import (
    AuthenticationConfigurationError,
    AuthenticationError,
    require_api_key,
)
from chalicelib.config import GPT_DOCS_API_KEY_ENV, GPT_DOCS_API_KEY_HEADER


class AuthTests(unittest.TestCase):
    def test_require_api_key_fails_closed_without_server_secret(self):
        with self.assertRaisesRegex(
            AuthenticationConfigurationError,
            "API authentication is not configured",
        ):
            require_api_key(
                {GPT_DOCS_API_KEY_HEADER: "caller-key"},
                environ={},
            )

    def test_require_api_key_rejects_missing_or_wrong_caller_secret(self):
        environ = {GPT_DOCS_API_KEY_ENV: "server-key"}

        with self.assertRaisesRegex(AuthenticationError, "Unauthorized"):
            require_api_key({}, environ=environ)

        with self.assertRaisesRegex(AuthenticationError, "Unauthorized"):
            require_api_key(
                {GPT_DOCS_API_KEY_HEADER: "wrong-key"},
                environ=environ,
            )

    def test_require_api_key_accepts_configured_header(self):
        require_api_key(
            {GPT_DOCS_API_KEY_HEADER.lower(): "server-key"},
            environ={GPT_DOCS_API_KEY_ENV: "server-key"},
        )

    def test_require_api_key_accepts_bearer_authorization_header(self):
        require_api_key(
            {"Authorization": "Bearer server-key"},
            environ={GPT_DOCS_API_KEY_ENV: "server-key"},
        )

    def test_default_environment_can_authorize_request(self):
        previous = os.environ.get(GPT_DOCS_API_KEY_ENV)
        os.environ[GPT_DOCS_API_KEY_ENV] = "server-key"
        try:
            require_api_key({GPT_DOCS_API_KEY_HEADER: "server-key"})
        finally:
            if previous is None:
                os.environ.pop(GPT_DOCS_API_KEY_ENV, None)
            else:
                os.environ[GPT_DOCS_API_KEY_ENV] = previous


if __name__ == "__main__":
    unittest.main()
