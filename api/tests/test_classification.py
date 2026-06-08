import os
import unittest
from unittest.mock import patch

from chalicelib.classification import (
    generate_classification,
    generate_response,
    get_embeddings,
)
from chalicelib.config import EMBEDDING_MODEL, GPT_MODEL, OPENAI_API_KEY_ENV


class FakeEmbedding:
    calls = []

    @classmethod
    def create(cls, **kwargs):
        cls.calls.append(kwargs)
        return {"data": [{"embedding": [0.1, 0.2, 0.3]}]}


class FakeChatCompletion:
    calls = []
    response = {
        "choices": [
            {
                "message": {
                    "content": "Generated answer",
                }
            }
        ]
    }

    @classmethod
    def create(cls, **kwargs):
        cls.calls.append(kwargs)
        return cls.response


class FakeOpenAI:
    api_key = None
    Embedding = FakeEmbedding
    ChatCompletion = FakeChatCompletion


class ErrorChatCompletion:
    @classmethod
    def create(cls, **kwargs):
        raise RuntimeError("openai unavailable")


class ErrorOpenAI:
    ChatCompletion = ErrorChatCompletion


class ClassificationTests(unittest.TestCase):
    def setUp(self):
        FakeEmbedding.calls = []
        FakeChatCompletion.calls = []
        FakeChatCompletion.response = {
            "choices": [
                {
                    "message": {
                        "content": "Generated answer",
                    }
                }
            ]
        }
        FakeOpenAI.api_key = None

    def test_get_embeddings_uses_configured_model_and_api_key(self):
        with patch.dict(os.environ, {OPENAI_API_KEY_ENV: "test-key"}):
            result = get_embeddings("How?", openai_client=FakeOpenAI)

        self.assertEqual(result, [0.1, 0.2, 0.3])
        self.assertEqual(FakeOpenAI.api_key, "test-key")
        self.assertEqual(
            FakeEmbedding.calls,
            [{"input": ["How?"], "engine": EMBEDDING_MODEL}],
        )

    def test_generate_response_uses_primer_and_user_query(self):
        result = generate_response("What is Twilio?", openai_client=FakeOpenAI)

        self.assertEqual(result, "Generated answer")
        self.assertEqual(FakeChatCompletion.calls[0]["model"], GPT_MODEL)
        self.assertEqual(
            FakeChatCompletion.calls[0]["messages"][-1],
            {"role": "user", "content": "What is Twilio?"},
        )
        self.assertIn("I don't know", FakeChatCompletion.calls[0]["messages"][0]["content"])

    def test_generate_classification_parses_json_response(self):
        FakeChatCompletion.response = {
            "choices": [
                {
                    "message": {
                        "content": '{"with_code": 0.8, "no_code": 0.2}',
                    }
                }
            ]
        }

        result = generate_classification(
            "gpt-test",
            "How do I build this?",
            openai_client=FakeOpenAI,
        )

        self.assertEqual(result, {"with_code": 0.8, "no_code": 0.2})
        self.assertEqual(FakeChatCompletion.calls[0]["model"], "gpt-test")

    def test_generate_classification_wraps_openai_errors(self):
        with self.assertRaisesRegex(
            Exception,
            "Failed to generate classification: openai unavailable",
        ):
            generate_classification(
                "gpt-test",
                "How do I build this?",
                openai_client=ErrorOpenAI,
            )


if __name__ == "__main__":
    unittest.main()
