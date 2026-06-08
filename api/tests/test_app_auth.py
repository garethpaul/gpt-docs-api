import os
import sys
import types
import unittest
from unittest.mock import patch

from chalicelib.config import GPT_DOCS_API_KEY_ENV
from chalicelib.utils import (
    header_value,
    is_authorized_request,
    request_api_key,
)


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


def install_dependency_stubs():
    chalice = types.ModuleType("chalice")
    chalice.Chalice = FakeChalice
    chalice.Response = FakeResponse
    chalice.CORSConfig = FakeCORSConfig
    chalice.BadRequestError = Exception
    sys.modules.setdefault("chalice", chalice)

    pinecone = types.ModuleType("pinecone")
    pinecone.init = lambda **kwargs: None
    pinecone.list_indexes = lambda: []
    pinecone.create_index = lambda *args, **kwargs: None
    pinecone.GRPCIndex = lambda name: None
    sys.modules.setdefault("pinecone", pinecone)


install_dependency_stubs()

import app as app_module


class FakeRequest:
    def __init__(self, headers=None, json_body=None, fail_on_json=False):
        self.headers = headers or {}
        self._json_body = json_body
        self._fail_on_json = fail_on_json

    @property
    def json_body(self):
        if self._fail_on_json:
            raise AssertionError("json_body should not be read")
        return self._json_body


class AuthUtilityTests(unittest.TestCase):
    def test_header_lookup_is_case_insensitive(self):
        self.assertEqual(
            header_value({"x-api-key": "abc"}, "X-API-Key"),
            "abc",
        )

    def test_request_api_key_accepts_bearer_or_x_api_key(self):
        self.assertEqual(
            request_api_key({"Authorization": "Bearer bearer-key"}),
            "bearer-key",
        )
        self.assertEqual(
            request_api_key({"X-API-Key": "header-key"}),
            "header-key",
        )

    def test_authorization_requires_configured_matching_key(self):
        self.assertFalse(is_authorized_request({}, "server-key"))
        self.assertFalse(
            is_authorized_request({"X-API-Key": "caller-key"}, None)
        )
        self.assertFalse(
            is_authorized_request({"X-API-Key": "wrong"}, "server-key")
        )
        self.assertTrue(
            is_authorized_request({"X-API-Key": "server-key"}, "server-key")
        )


class AppAuthTests(unittest.TestCase):
    def setUp(self):
        self.original_request = app_module.app.current_request

    def tearDown(self):
        app_module.app.current_request = self.original_request

    def test_ask_rejects_missing_key_before_reading_json(self):
        app_module.app.current_request = FakeRequest(fail_on_json=True)

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}), \
                patch.object(app_module, "get_cached_response") as cache, \
                patch.object(app_module, "make_query") as make_query:
            response = app_module.ask_question()

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.body, {"error": "Unauthorized"})
        cache.assert_not_called()
        make_query.assert_not_called()

    def test_ask_accepts_bearer_token_before_calling_model_helpers(self):
        app_module.app.current_request = FakeRequest(
            headers={"Authorization": "Bearer server-key"},
            json_body={"query": "How do I send an SMS?"},
        )

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}), \
                patch.object(app_module, "get_cached_response",
                             return_value=None), \
                patch.object(app_module, "make_query",
                             return_value=("answer", ["url"])), \
                patch.object(app_module, "store_in_cache") as store:
            response = app_module.ask_question()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.body, {"response": "answer",
                                         "links": ["url"]})
        store.assert_called_once_with("How do I send an SMS?", "answer",
                                      ["url"])

    def test_classification_rejects_missing_key_before_reading_json(self):
        app_module.app.current_request = FakeRequest(fail_on_json=True)

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}), \
                patch.object(app_module, "generate_classification") as classify:
            response = app_module.classify_builder()

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.body, {"error": "Unauthorized"})
        classify.assert_not_called()

    def test_classification_accepts_x_api_key_header(self):
        app_module.app.current_request = FakeRequest(
            headers={"X-API-Key": "server-key"},
            json_body={"query": "How do I build this?"},
        )

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}), \
                patch.object(app_module, "generate_classification",
                             return_value={"with_code": 0.8}):
            response = app_module.classify_builder()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.body, {"weights": {"with_code": 0.8}})


if __name__ == "__main__":
    unittest.main()
