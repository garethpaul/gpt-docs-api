import os
import math
from typing import List, Dict
from openai import OpenAI
from chalicelib.config import OPENAI_API_KEY_ENV, EMBEDDING_MODEL, GPT_MODEL
from chalicelib.utils import extract_json_object

CLASSIFICATION_KEYS = ("with_code", "minimal_code", "no_code")


def create_openai_client():
    """Create an OpenAI client from the configured API key."""
    api_key = os.environ.get(OPENAI_API_KEY_ENV)
    if not api_key:
        raise ValueError("OpenAI API key is not configured")
    return OpenAI(api_key=api_key)


def get_embeddings(query: str, openai_client=None) -> List[float]:
    """Get embeddings for the query text."""
    client = create_openai_client() if openai_client is None else openai_client
    response = client.embeddings.create(
        input=[query],
        model=EMBEDDING_MODEL,
    )
    return response.data[0].embedding


def generate_response(query: str, openai_client=None) -> str:
    """Generate a response using GPT."""
    primer = f"""You are Q&A bot. A highly intelligent system that answers
    user questions based on the information provided by the user above
    each question. If the user asks for long response, respond with 4
    paragraphs. If the information can not be found in the information 
    provided by the user you truthfully say "I don't know".
    """
    client = create_openai_client() if openai_client is None else openai_client
    response = client.chat.completions.create(
        model=GPT_MODEL,
        messages=[
            {"role": "system", "content": primer},
            {"role": "user", "content": query}
        ]
    )
    return response.choices[0].message.content


def validate_classification_weights(weights: Dict[str, float]) -> Dict[str, float]:
    """Validate and normalize classifier weights returned by the model."""
    if not isinstance(weights, dict):
        raise ValueError("Classification response must be a JSON object")

    if set(weights.keys()) != set(CLASSIFICATION_KEYS):
        raise ValueError(
            "Classification response must include with_code, minimal_code, and no_code"
        )

    validated = {}
    for key in CLASSIFICATION_KEYS:
        value = weights[key]
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError("Classification weights must be finite numbers")

        weight = float(value)
        if not math.isfinite(weight):
            raise ValueError("Classification weights must be finite numbers")
        if weight < 0 or weight > 1:
            raise ValueError("Classification weights must be between 0 and 1")

        validated[key] = weight

    return validated


def generate_classification(model: str,
                            query: str,
                            openai_client=None) -> Dict[str, float]:
    """
    Generate a classification for a given query using the specified OpenAI
    model.

    Args:
        model (str): The name of the OpenAI GPT model to use.
        query (str): The user query for classification.

    Returns:
        Dict[str, float]: A dictionary containing the classification and
        weights.

    Raises:
        Exception: If the OpenAI API returns an error.
    """
    primer = (
        "You are a classification expert. You must provide a weighting"
        " estimate for each with_code, minimal_code, and no_code. You must"
        " provide a best guess at the estimate in a JSON object only respond"
        f" with the object and no other text:\n\n {query}"
    )

    try:
        client = create_openai_client() if openai_client is None else openai_client
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": primer},
                {"role": "user", "content": query}
            ]
        )
        api_resp = response.choices[0].message.content
        return validate_classification_weights(extract_json_object(api_resp))
    except Exception as error:
        raise Exception(f"Failed to generate classification: {str(error)}")
