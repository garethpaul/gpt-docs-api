import io
import unittest
from contextlib import redirect_stdout

from chalicelib.utils import extract_json_object, validate_request_payload


class UtilsTests(unittest.TestCase):
    def test_validate_request_payload_requires_json_body(self):
        with self.assertRaisesRegex(ValueError, "Request body must be JSON"):
            validate_request_payload(None)

        with self.assertRaisesRegex(ValueError, "Request body must be JSON"):
            validate_request_payload({})

    def test_validate_request_payload_requires_query(self):
        with self.assertRaisesRegex(ValueError, 'Missing "query" key'):
            validate_request_payload({"query": ""})

    def test_validate_request_payload_returns_query(self):
        self.assertEqual(
            validate_request_payload({"query": "How do I send an SMS?"}),
            "How do I send an SMS?",
        )

    def test_extract_json_object_from_surrounding_text(self):
        self.assertEqual(
            extract_json_object('prefix {"with_code": 0.7, "no_code": 0.3} suffix'),
            {"with_code": 0.7, "no_code": 0.3},
        )

    def test_extract_json_object_returns_empty_dict_without_stdout(self):
        stdout = io.StringIO()

        with redirect_stdout(stdout):
            malformed = extract_json_object("prefix {not-json} suffix")
            missing = extract_json_object("no json here")

        self.assertEqual(malformed, {})
        self.assertEqual(missing, {})
        self.assertEqual(stdout.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
