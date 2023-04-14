from chalice import BadRequestError
from typing import Dict
import json


def validate_request_payload(request_json) -> str:
    """
    Validate the request payload and extract the query.
    """
    if not request_json:
        raise BadRequestError('Request body must be JSON')
    query = request_json.get('query')
    if not query:
        raise BadRequestError('Missing "query" key in request body')
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

    # Extract the JSON substring
    json_str = text[start_index:end_index]

    # Parse the JSON substring and convert it to a Python dictionary
    try:
        json_obj = json.loads(json_str)
    except:
        print('Failed to parse JSON object')
        print(json_str)
        json_obj = {}

    return json_obj
