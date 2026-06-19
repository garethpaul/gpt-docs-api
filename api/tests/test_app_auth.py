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

    def test_ask_reapplies_twilio_link_policy_to_cached_response(self):
        request = FakeRequest(
            headers={GPT_DOCS_API_KEY_HEADER: "server-key"},
            json_body={"query": "How?"},
        )
        self.app_module.app.current_request = request
        cached_response = {
            "response": "cached answer",
            "links": [
                "https://www.twilio.com/docs/b",
                "https://example.com/?next=twilio.com",
                "http://www.twilio.com/docs/a",
                "https://docs.twilio.com/reference",
                "https://www.twilio.com/docs/b",
            ],
        }

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}):
            with patch.object(
                self.app_module,
                "get_cached_response",
                return_value=cached_response,
            ):
                with patch.object(
                    self.app_module,
                    "make_query",
                    side_effect=AssertionError("should not run"),
                ) as make_query:
                    with patch.object(self.app_module, "store_in_cache") as cache:
                        response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.body,
            {
                "response": "cached answer",
                "links": [
                    "https://docs.twilio.com/reference",
                    "https://www.twilio.com/docs/b",
                ],
            },
        )
        make_query.assert_not_called()
        cache.assert_not_called()

    def test_ask_bypasses_cache_read_failure(self):
        request = FakeRequest(
            headers={GPT_DOCS_API_KEY_HEADER: "server-key"},
            json_body={"query": "How?"},
        )
        self.app_module.app.current_request = request

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}):
            with patch.object(
                self.app_module,
                "get_cached_response",
                side_effect=RuntimeError("dynamodb unavailable"),
            ):
                with patch.object(
                    self.app_module,
                    "make_query",
                    return_value=("answer", ["https://twilio.com/docs"]),
                ) as make_query:
                    with patch.object(self.app_module, "store_in_cache") as cache:
                        with patch.object(
                            self.app_module.logger, "exception"
                        ) as log:
                            response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.body,
            {"response": "answer", "links": ["https://twilio.com/docs"]},
        )
        make_query.assert_called_once_with("How?")
        cache.assert_called_once_with("How?", "answer", ["https://twilio.com/docs"])
        log.assert_called_once_with(
            "Failed to read response cache; bypassing cache"
        )

    def test_ask_returns_generated_response_when_cache_write_fails(self):
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
                ):
                    with patch.object(
                        self.app_module,
                        "store_in_cache",
                        side_effect=RuntimeError("dynamodb unavailable"),
                    ):
                        with patch.object(
                            self.app_module.logger, "exception"
                        ) as log:
                            response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.body,
            {"response": "answer", "links": ["https://twilio.com/docs"]},
        )
        log.assert_called_once_with(
            "Failed to write response cache; returning generated response"
        )

    def test_ask_returns_generic_error_for_unexpected_failures(self):
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
                    side_effect=RuntimeError("upstream failure detail"),
                ):
                    with patch.object(self.app_module.logger, "exception") as log:
                        response = self.app_module.ask_question()

        self.assertEqual(response.status_code, 500)
        self.assertEqual(response.body, {"error": "Internal server error"})
        log.assert_called_once_with("Failed to process ask request")

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

    def test_classify_returns_generic_error_for_unexpected_failures(self):
        request = FakeRequest(
            headers={GPT_DOCS_API_KEY_HEADER: "server-key"},
            json_body={"query": "How?"},
        )
        self.app_module.app.current_request = request

        with patch.dict(os.environ, {GPT_DOCS_API_KEY_ENV: "server-key"}):
            with patch.object(
                self.app_module,
                "generate_classification",
                side_effect=RuntimeError("classifier failure detail"),
            ):
                with patch.object(self.app_module.logger, "exception") as log:
                    response = self.app_module.classify_builder()

        self.assertEqual(response.status_code, 500)
        self.assertEqual(response.body, {"error": "Internal server error"})
        log.assert_called_once_with("Failed to process classify request")

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

    def test_make_query_skips_incomplete_metadata(self):
        class FakeIndex:
            def query(self, *args, **kwargs):
                return {
                    "matches": [
                        {"metadata": {"url": "https://www.twilio.com/docs/skip"}},
                        {
                            "metadata": {
                                "text": "   ",
                                "url": "https://www.twilio.com/docs/blank",
                            }
                        },
                        {"metadata": {"text": "context a", "url": None}},
                        {
                            "metadata": {
                                "text": "context b",
                                "url": "https://www.twilio.com/docs/b",
                            }
                        },
                        {},
                    ]
                }

        with patch.object(self.app_module, "get_embeddings", return_value=[0.1]):
            with patch.object(self.app_module, "get_index", return_value=FakeIndex()):
                with patch.object(
                    self.app_module,
                    "generate_response",
                    return_value="answer",
                ) as generate_response:
                    response, links = self.app_module.make_query("How?")

        self.assertEqual(response, "answer")
        self.assertEqual(links, ["https://www.twilio.com/docs/b"])
        generate_response.assert_called_once()
        augmented_query = generate_response.call_args[0][0]
        self.assertEqual(
            augmented_query,
            "context a\n\n---\n\ncontext b\n\n-----\n\nHow?",
        )

    def test_retrieval_metadata_handles_unsupported_accessors(self):
        metadata = {"text": "context"}

        class ObjectMatch:
            def __init__(self):
                self.metadata = metadata

        class NonCallableGetMatch(dict):
            get = None

        class RaisingGetMatch(dict):
            def get(self, key):
                raise RuntimeError("provider mapping failure")

        class RaisingMetadataMatch:
            get = None

            @property
            def metadata(self):
                raise RuntimeError("provider attribute failure")

        self.assertEqual(metadata, self.app_module.retrieval_metadata({
            "metadata": metadata,
        }))
        self.assertEqual(
            metadata,
            self.app_module.retrieval_metadata(ObjectMatch()),
        )
        self.assertIsNone(
            self.app_module.retrieval_metadata(NonCallableGetMatch()),
        )
        self.assertIsNone(
            self.app_module.retrieval_metadata(RaisingGetMatch()),
        )
        self.assertIsNone(
            self.app_module.retrieval_metadata(RaisingMetadataMatch()),
        )

    def test_make_query_skips_metadata_accessor_failures(self):
        class RaisingGetMatch(dict):
            def get(self, key):
                raise RuntimeError("provider mapping failure")

        class FakeIndex:
            def query(self, *args, **kwargs):
                return {
                    "matches": [
                        RaisingGetMatch(),
                        {
                            "metadata": {
                                "text": "usable context",
                                "url": "https://www.twilio.com/docs/usable",
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
                ) as generate_response:
                    response, links = self.app_module.make_query("How?")

        self.assertEqual(response, "answer")
        self.assertEqual(links, ["https://www.twilio.com/docs/usable"])
        generate_response.assert_called_once_with(
            "usable context\n\n-----\n\nHow?"
        )

    def test_make_query_ignores_malformed_matches_containers(self):
        malformed_matches = (None, "matches", 1, {"metadata": {}})

        for matches in malformed_matches:
            with self.subTest(matches=matches):
                class FakeIndex:
                    def query(self, *args, **kwargs):
                        return {"matches": matches}

                with patch.object(
                    self.app_module, "get_embeddings", return_value=[0.1]
                ):
                    with patch.object(
                        self.app_module, "get_index", return_value=FakeIndex()
                    ):
                        with patch.object(
                            self.app_module,
                            "generate_response",
                            return_value="answer",
                        ) as generate_response:
                            response, links = self.app_module.make_query("How?")

                self.assertEqual(response, "answer")
                self.assertEqual(links, [])
                generate_response.assert_called_once_with("\n\n-----\n\nHow?")

    def test_retrieval_matches_accepts_list_and_tuple(self):
        match = {"metadata": {"text": "context"}}

        self.assertEqual([match], self.app_module.retrieval_matches({
            "matches": [match]
        }))
        self.assertEqual((match,), self.app_module.retrieval_matches(type(
            "Response", (), {"matches": (match,)}
        )()))

    def test_retrieval_matches_handles_unsupported_accessors(self):
        match = {"metadata": {"text": "context"}}

        class NonCallableGetResponse:
            get = None
            matches = [match]

        class RaisingGetResponse:
            def get(self, key, default):
                raise RuntimeError("provider mapping failure")

        class RaisingMatchesResponse:
            @property
            def matches(self):
                raise RuntimeError("provider attribute failure")

        self.assertEqual(
            [match],
            self.app_module.retrieval_matches(NonCallableGetResponse()),
        )
        self.assertEqual((), self.app_module.retrieval_matches(RaisingGetResponse()))
        self.assertEqual(
            (),
            self.app_module.retrieval_matches(RaisingMatchesResponse()),
        )

    def test_make_query_uses_query_only_prompt_after_accessor_failure(self):
        class RaisingGetResponse:
            def get(self, key, default):
                raise RuntimeError("provider mapping failure")

        class FakeIndex:
            def query(self, *args, **kwargs):
                return RaisingGetResponse()

        with patch.object(self.app_module, "get_embeddings", return_value=[0.1]):
            with patch.object(self.app_module, "get_index", return_value=FakeIndex()):
                with patch.object(
                    self.app_module,
                    "generate_response",
                    return_value="answer",
                ) as generate_response:
                    response, links = self.app_module.make_query("How?")

        self.assertEqual(response, "answer")
        self.assertEqual(links, [])
        generate_response.assert_called_once_with("\n\n-----\n\nHow?")

    def test_make_query_truncates_overlong_metadata_text(self):
        long_context = "x" * (self.app_module.MAX_RETRIEVAL_CONTEXT_LENGTH + 25)

        class FakeIndex:
            def query(self, *args, **kwargs):
                return {
                    "matches": [
                        {
                            "metadata": {
                                "text": long_context,
                                "url": "https://www.twilio.com/docs/long",
                            }
                        }
                    ]
                }

        with patch.object(self.app_module, "get_embeddings", return_value=[0.1]):
            with patch.object(self.app_module, "get_index", return_value=FakeIndex()):
                with patch.object(
                    self.app_module,
                    "generate_response",
                    return_value="answer",
                ) as generate_response:
                    response, links = self.app_module.make_query("How?")

        self.assertEqual(response, "answer")
        self.assertEqual(links, ["https://www.twilio.com/docs/long"])
        generate_response.assert_called_once()
        augmented_query = generate_response.call_args[0][0]
        self.assertEqual(
            augmented_query,
            "x" * self.app_module.MAX_RETRIEVAL_CONTEXT_LENGTH + "\n\n-----\n\nHow?",
        )

    def test_make_query_bounds_total_context_and_excludes_unused_links(self):
        first_context = "a" * 1000
        second_context = "b" * self.app_module.MAX_RETRIEVAL_CONTEXT_LENGTH

        class FakeIndex:
            def query(self, *args, **kwargs):
                return {
                    "matches": [
                        {
                            "metadata": {
                                "text": first_context,
                                "url": "https://www.twilio.com/docs/first",
                            }
                        },
                        {
                            "metadata": {
                                "text": second_context,
                                "url": "https://www.twilio.com/docs/second",
                            }
                        },
                        {
                            "metadata": {
                                "text": "excluded context",
                                "url": "https://www.twilio.com/docs/excluded",
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
                ) as generate_response:
                    response, links = self.app_module.make_query("How?")

        self.assertEqual(response, "answer")
        self.assertEqual(
            links,
            [
                "https://www.twilio.com/docs/first",
                "https://www.twilio.com/docs/second",
            ],
        )
        augmented_query = generate_response.call_args[0][0]
        context_text, query = augmented_query.split("\n\n-----\n\n", 1)
        self.assertEqual(query, "How?")
        self.assertEqual(
            len(context_text),
            self.app_module.MAX_RETRIEVAL_CONTEXT_LENGTH,
        )
        self.assertEqual(
            context_text,
            first_context
            + self.app_module.RETRIEVAL_CONTEXT_SEPARATOR
            + "b" * (
                self.app_module.MAX_RETRIEVAL_CONTEXT_LENGTH
                - len(first_context)
                - len(self.app_module.RETRIEVAL_CONTEXT_SEPARATOR)
            ),
        )


if __name__ == "__main__":
    unittest.main()
