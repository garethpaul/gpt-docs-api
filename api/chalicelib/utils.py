from typing import Dict
import json


MAX_QUERY_LENGTH = 4000


def validate_request_payload(request_json) -> str:
    """
    Validate the request payload and extract the query.
    """
    if not isinstance(request_json, dict) or not request_json:
        raise ValueError('Request body must be JSON')
    query = request_json.get('query')
    if query is None:
        raise ValueError('Missing "query" key in request body')
    if not isinstance(query, str):
        raise ValueError('Query must be a string')
    query = query.strip()
    if not query:
        raise ValueError('Missing "query" key in request body')
    if len(query) > MAX_QUERY_LENGTH:
        raise ValueError('Query is too long')
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
