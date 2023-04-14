import openai
import os
from typing import List, Dict
from chalicelib.config import OPENAI_API_KEY_ENV, EMBEDDING_MODEL, GPT_MODEL
from chalicelib.utils import extract_json_object

def get_embeddings(query: str) -> List[float]:
    """Get embeddings for the query text."""
    embed_model = EMBEDDING_MODEL
    openai.api_key = os.environ.get(OPENAI_API_KEY_ENV)
    res = openai.Embedding.create(
        input=[query],
        engine=embed_model
    )
    embedding_vector = res['data'][0]['embedding']
    return embedding_vector


def generate_response(query: str) -> str:
    """Generate a response using GPT."""
    primer = f"""You are Q&A bot. A highly intelligent system that answers
    user questions based on the information provided by the user above
    each question. If the user asks for long response, respond with 4
    paragraphs. If the information can not be found in the information 
    provided by the user you truthfully say "I don't know".
    """
    open_res = openai.ChatCompletion.create(
        model=GPT_MODEL,
        messages=[
            {"role": "system", "content": primer},
            {"role": "user", "content": query}
        ]
    )
    return open_res['choices'][0]['message']['content']


def generate_classification(model: str, query: str) -> Dict[str, float]:
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
        response = openai.ChatCompletion.create(
            model=model,
            messages=[
                {"role": "system", "content": primer},
                {"role": "user", "content": query}
            ]
        )
        api_resp = response['choices'][0]['message']['content']
        return extract_json_object(api_resp)
    except Exception as error:
        raise Exception(f"Failed to generate classification: {str(error)}")
