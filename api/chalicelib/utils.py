from typing import Dict
import hmac
import json


def header_value(headers, name):
    """
    Return a request header value using case-insensitive lookup.
    """
    if not headers:
        return None
    lowered = name.lower()
    for key, value in headers.items():
        if key.lower() == lowered:
            return value
    return None


def request_api_key(headers):
    """
    Extract the inbound caller API key from supported auth headers.
    """
    authorization = header_value(headers, 'Authorization')
    if authorization:
        scheme, _, token = authorization.partition(' ')
        if scheme.lower() == 'bearer' and token:
            return token.strip()

    api_key = header_value(headers, 'X-API-Key')
    if api_key:
        return api_key.strip()

    return None


def is_authorized_request(headers, expected_api_key):
    """
    Validate caller credentials without leaking timing information.
    """
    supplied_api_key = request_api_key(headers)
    if not expected_api_key or not supplied_api_key:
        return False
    return hmac.compare_digest(str(supplied_api_key),
                               str(expected_api_key))


def validate_request_payload(request_json) -> str:
    """
    Validate the request payload and extract the query.
    """
    if not request_json:
        raise ValueError('Request body must be JSON')
    query = request_json.get('query')
    if not query:
        raise ValueError('Missing "query" key in request body')
    return query


def extract_json_object(text) -> Dict[str, float]:
    """
    Extract and parse the JSON object from the API response.

    Args:
        api_resp (str): The API response containing the JSON object.

    Returns:
        Dict[str, float]: A dictionary containing the classification and
        weights.
    """
    # Find the start and end indices of the JSON object
    start_index = text.find('{')
    end_index = text.rfind('}') + 1

    if start_index == -1 or end_index == 0:
        return {}

    # Extract the JSON substring
    json_str = text[start_index:end_index]

    # Parse the JSON substring and convert it to a Python dictionary
    try:
        json_obj = json.loads(json_str)
    except json.JSONDecodeError:
        json_obj = {}

    return json_obj
