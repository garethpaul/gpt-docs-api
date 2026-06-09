import importlib
import os
import sys
import types
import unittest
from unittest.mock import Mock, patch

from chalicelib.config import GPT_DOCS_API_KEY_ENV, GPT_DOCS_API_KEY_HEADER


class FakeRequest:
    def __init__(self, headers=None, json_body=None):
        self.headers = headers or {}
        self._json_body = json_body
        self.json_body_accesses = 0

    @property
    def json_body(self):
        self.json_body_accesses += 1
        return self._json_body


class FakeResponse:
    def __init__(self, body=None, status_code=200, headers=None):
        self.body = body
        self.status_code = status_code
        self.headers = headers or {}


class FakeCORSConfig:
    def __init__(self, **kwargs):
        self.kwargs = kwargs


class FakeChalice:
    def __init__(self, app_name):
        self.app_name = app_name
        self.current_request = None

    def route(self, *args, **kwargs):
        def decorator(func):
            return func

        return decorator


class BadRequestError(Exception):
    pass


def import_app_with_fakes():
    chalice_module = types.SimpleNamespace(
        BadRequestError=BadRequestError,
        Chalice=FakeChalice,
        CORSConfig=FakeCORSConfig,
        Response=FakeResponse,
    )
    pinecone_module = types.SimpleNamespace()

    sys.modules.pop("app", None)
    with patch.dict(
        sys.modules,
        {"chalice": chalice_module, "pinecone": pinecone_module},
    ):
        return importlib.import_module("app")


class AppAuthTests(unittest.TestCase):
    def setUp(self):
        self.app_module = import_app_with_fakes()

    def tearDown(self):
        sys.modules.pop("app", None)

    def test_ask_rejects_unauthenticated_callers_before_body_or_model_work(self):
        request = FakeRequest(headers={}, json_body={"query": "How?"})
        self.app_module.app.current_request = request

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}):
            make_query = Mock(side_effect=AssertionError("should not run"))
            with patch.object(self.app_module, "make_query", make_query):
                response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.body, {"error": "Unauthorized"})
        self.assertEqual(request.json_body_accesses, 0)
        make_query.assert_not_called()

    def test_ask_fails_closed_when_auth_is_not_configured(self):
        request = FakeRequest(
            headers={GPT_DOCS_API_KEY_HEADER: "server-key"},
            json_body={"query": "How?"},
        )
        self.app_module.app.current_request = request

        with patch.dict(os.environ, {}, clear=True):
            response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 503)
        self.assertEqual(
            response.body,
            {"error": "API authentication is not configured"},
        )
        self.assertEqual(request.json_body_accesses, 0)

    def test_ask_allows_authorized_callers_and_preserves_response_shape(self):
        request = FakeRequest(
            headers={GPT_DOCS_API_KEY_HEADER: "server-key"},
            json_body={"query": "How?"},
        )
        self.app_module.app.current_request = request

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}):
            with patch.object(self.app_module, "get_cached_response", return_value=None):
                with patch.object(
                    self.app_module,
                    "make_query",
                    return_value=("answer", ["https://twilio.com/docs"]),
                ) as make_query:
                    with patch.object(self.app_module, "store_in_cache") as cache:
                        response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.body,
            {"response": "answer", "links": ["https://twilio.com/docs"]},
        )
        self.assertEqual(request.json_body_accesses, 1)
        make_query.assert_called_once_with("How?")
        cache.assert_called_once_with("How?", "answer", ["https://twilio.com/docs"])

    def test_classify_rejects_unauthenticated_callers_before_body_or_model_work(self):
        request = FakeRequest(headers={}, json_body={"query": "How?"})
        self.app_module.app.current_request = request

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}):
            classifier = Mock(side_effect=AssertionError("should not run"))
            with patch.object(self.app_module, "generate_classification", classifier):
                response = self.app_module.classify_builder()

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.body, {"error": "Unauthorized"})
        self.assertEqual(request.json_body_accesses, 0)
        classifier.assert_not_called()

    def test_serve_public_returns_known_asset_with_content_type(self):
        response = self.app_module.serve_public("test.html")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers["Content-Type"], "text/html")
        self.assertIsInstance(response.body, bytes)
        self.assertIn(b"<html", response.body)

    def test_serve_public_returns_404_for_missing_asset(self):
        response = self.app_module.serve_public("missing.js")

        self.assertEqual(response.status_code, 404)
        self.assertEqual(response.body, {"error": "File 'missing.js' not found."})

    def test_serve_public_rejects_path_traversal(self):
        response = self.app_module.serve_public("../app.py")

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.body, {"error": "Invalid public file path"})

    def test_is_twilio_doc_url_requires_https_twilio_host(self):
        self.assertTrue(
            self.app_module.is_twilio_doc_url("https://www.twilio.com/docs/sms")
        )
        self.assertTrue(
            self.app_module.is_twilio_doc_url("https://docs.twilio.com/reference")
        )
        self.assertFalse(
            self.app_module.is_twilio_doc_url("http://www.twilio.com/docs/sms")
        )
        self.assertFalse(
            self.app_module.is_twilio_doc_url("https://example.com/?next=twilio.com")
        )
        self.assertFalse(self.app_module.is_twilio_doc_url(None))

    def test_make_query_filters_links_by_twilio_host(self):
        class FakeIndex:
            def query(self, *args, **kwargs):
                return {
                    "matches": [
                        {
                            "metadata": {
                                "text": "context a",
                                "url": "https://www.twilio.com/docs/b",
                            }
                        },
                        {
                            "metadata": {
                                "text": "context b",
                                "url": "https://example.com/?next=twilio.com",
                            }
                        },
                        {
                            "metadata": {
                                "text": "context c",
                                "url": "http://www.twilio.com/docs/a",
                            }
                        },
                        {
                            "metadata": {
                                "text": "context d",
                                "url": "https://docs.twilio.com/reference",
                            }
                        },
                    ]
                }

        with patch.object(self.app_module, "get_embeddings", return_value=[0.1]):
            with patch.object(self.app_module, "get_index", return_value=FakeIndex()):
                with patch.object(
                    self.app_module,
                    "generate_response",
                    return_value="answer",
                ):
                    response, links = self.app_module.make_query("How?")

        self.assertEqual(response, "answer")
        self.assertEqual(
            links,
            [
                "https://docs.twilio.com/reference",
                "https://www.twilio.com/docs/b",
            ],
        )


if __name__ == "__main__":
    unittest.main()
