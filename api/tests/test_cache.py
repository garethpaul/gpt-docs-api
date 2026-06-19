import importlib
import hashlib
import sys
import unittest
from unittest.mock import patch


class FakeTable:
    def __init__(self, item=None):
        self.item = item
        self.get_item_calls = []
        self.put_item_calls = []

    def get_item(self, **kwargs):
        self.get_item_calls.append(kwargs)
        if self.item is None:
            return {}
        return {"Item": self.item}

    def put_item(self, **kwargs):
        self.put_item_calls.append(kwargs)


class FakeResource:
    def __init__(self):
        self.table_names = []

    def Table(self, table_name):
        self.table_names.append(table_name)
        return FakeTable()


class CacheTests(unittest.TestCase):
    def test_import_does_not_create_dynamodb_resource(self):
        with patch.dict(sys.modules, {"boto3": None}):
            import chalicelib.cache as cache

            importlib.reload(cache)

    def test_cache_key_is_fixed_size_and_deterministic(self):
        from chalicelib.cache import cache_key

        expected = "query_sha256:" + hashlib.sha256(
            "hello".encode("utf-8")
        ).hexdigest()

        self.assertEqual(expected, cache_key("hello"))
        self.assertEqual(cache_key("hello"), cache_key("hello"))
        self.assertNotEqual(cache_key("hello"), cache_key("Hello"))
        self.assertEqual(77, len(cache_key("")))

    def test_cache_key_handles_long_unicode_without_plaintext(self):
        from chalicelib.cache import cache_key

        query = "\U0001f680" * 4000
        key = cache_key(query)

        self.assertEqual(77, len(key))
        self.assertTrue(key.startswith("query_sha256:"))
        self.assertNotIn("\U0001f680", key)

    def test_get_cached_response_returns_item(self):
        from chalicelib.cache import cache_key, get_cached_response

        table = FakeTable(item={
            "response": "answer",
            "links": ["url"],
            "expires_at": 200,
        })

        self.assertEqual(
            get_cached_response("hello", table=table, now=100),
            {"response": "answer", "links": ["url"], "expires_at": 200},
        )
        self.assertEqual(
            table.get_item_calls,
            [{"Key": {"query_string": cache_key("hello")}}],
        )

    def test_get_cached_response_returns_none_when_item_missing(self):
        from chalicelib.cache import get_cached_response

        self.assertIsNone(get_cached_response("missing", table=FakeTable()))

    def test_get_cached_response_rejects_expired_or_missing_expiry(self):
        from chalicelib.cache import get_cached_response

        expired = FakeTable(item={"response": "old", "expires_at": 100})
        missing_expiry = FakeTable(item={"response": "old"})

        self.assertIsNone(get_cached_response("expired", table=expired, now=100))
        self.assertIsNone(get_cached_response("legacy", table=missing_expiry, now=100))

    def test_get_cached_response_rejects_malformed_payload_shape(self):
        from chalicelib.cache import get_cached_response

        malformed_items = [
            {"links": ["url"], "expires_at": 200},
            {"response": 123, "links": ["url"], "expires_at": 200},
            {"response": "answer", "expires_at": 200},
            {"response": "answer", "links": "url", "expires_at": 200},
            {"response": "answer", "links": [123], "expires_at": 200},
        ]

        for item in malformed_items:
            with self.subTest(item=item):
                self.assertIsNone(
                    get_cached_response("legacy", table=FakeTable(item), now=100)
                )

    def test_store_in_cache_writes_existing_item_shape(self):
        from chalicelib.cache import cache_key, store_in_cache

        table = FakeTable()

        store_in_cache("hello", "answer", ["url"], table=table,
                       now=100, ttl_seconds=60)

        self.assertEqual(
            table.put_item_calls,
            [
                {
                    "Item": {
                        "query_string": cache_key("hello"),
                        "response": "answer",
                        "links": ["url"],
                        "expires_at": 160,
                    }
                }
            ],
        )

    def test_store_in_cache_rejects_invalid_ttl(self):
        from chalicelib.cache import store_in_cache

        for ttl_seconds in (0, -1, True, "60"):
            with self.subTest(ttl_seconds=ttl_seconds):
                with self.assertRaises(ValueError):
                    store_in_cache("hello", "answer", [], table=FakeTable(),
                                   now=100, ttl_seconds=ttl_seconds)

    def test_get_cache_table_uses_configured_table_name(self):
        from chalicelib.cache import get_cache_table
        from chalicelib.config import CACHE_TABLE_NAME

        resource = FakeResource()

        get_cache_table(resource=resource)

        self.assertEqual(resource.table_names, [CACHE_TABLE_NAME])


if __name__ == "__main__":
    unittest.main()
