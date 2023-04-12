import logging
from flask import Flask, send_from_directory, request, jsonify, make_response
import pinecone
import openai
import os
import json
from flask_cors import cross_origin
from typing import Tuple, List, Dict, Optional

app = Flask(__name__)

# Define default values as constants
INDEX_NAME = 'gpt-4-langchain-docs'
INDEX_DIMENSION = 1536
INDEX_METRIC = 'dotproduct'
PINECONE_API_KEY_ENV = 'PINECONE_API_KEY'
PINECONE_ENVIRONMENT_ENV = 'PINECONE_ENVIRONMENT'
EMBEDDING_MODEL = "text-embedding-ada-002"
GPT_MODEL = "gpt-3.5-turbo"
OPENAI_API_KEY_ENV = 'OPENAI_API_KEY'

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get the absolute path to the chrome_extension folder
chrome_extension_directory = os.path.abspath(os.path.join(
    os.path.dirname(__file__), '../chrome_extension'))


@app.route('/public/<path:filename>')
def serve_public(filename):
    """
    Serve the public files."""
    return send_from_directory(chrome_extension_directory, filename)


def init_pinecone() -> None:
    """Initialize the Pinecone service."""
    try:
        api_key = os.environ.get(PINECONE_API_KEY_ENV)
        environment = os.environ.get(PINECONE_ENVIRONMENT_ENV)
        if not api_key or not environment:
            raise ValueError(
                'API key or environment not set in environment variables')
        pinecone.init(api_key=api_key, environment=environment)
    except Exception as error:
        logger.error(f'Failed to initialize Pinecone: {error}')
        raise


def create_index_if_not_exists(index_name: str, dimension: int, metric: str) -> None:
    """Create a Pinecone index if it does not already exist."""
    try:
        if index_name not in pinecone.list_indexes():
            pinecone.create_index(
                index_name, dimension=dimension, metric=metric)
    except Exception as error:
        logger.error(f'Failed to create index: {error}')
        raise


def get_index():
    """
    Get or create a Pinecone index.

    Returns:
        Index: The Pinecone index object.
    """
    init_pinecone()
    create_index_if_not_exists(INDEX_NAME, INDEX_DIMENSION, INDEX_METRIC)
    return pinecone.GRPCIndex(INDEX_NAME)


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


def make_query(query: str) -> Tuple[str, List[str]]:
    """
    Make a query and generate a response based on retrieved information.

    Parameters:
        query (str): The query text.

    Returns:
        Tuple[str, List[str]]: The generated response and a list of URLs.
    """
    # Get Embeddings
    xq = get_embeddings(query)

    # Get list of retrieved text
    index = get_index()
    res = index.query(xq, top_k=5, include_metadata=True)

    # Initialize lists to store contexts and URLs
    contexts = []
    urls = []

    # Extract the contexts and URLs from the query results
    for item in res['matches']:
        context = item['metadata']['text']
        url = item['metadata']['url']
        contexts.append(context)
        urls.append(url)

    augmented_query = "\n\n---\n\n".join(contexts)+"\n\n-----\n\n"+query

    # Generate response
    response = generate_response(augmented_query)

    # Remove duplicate URLs and anything that does not contain 'twilio.com'
    urls = list(set(urls))
    urls = [url for url in urls if 'twilio.com' in url]

    return response, urls


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


@app.route('/ask', methods=['POST', 'OPTIONS'])
@cross_origin(origins=['https://garethpaul.github.io/', 'http://localhost:3000'])
def ask_question():
    """
    Process a user query and return a generated response and relevant links.
    Expects a JSON payload with a 'query' key in the request body.

    Returns:
        resp (json): A JSON response containing the generated response and relevant links.
    """
    try:
        # Check if the request body is JSON
        if not request.is_json:
            return make_response(jsonify({'error': 'Request body must be JSON'}), 400)

        # Extract the query from the request JSON body
        query = request.json.get('query')
        if not query:
            return make_response(jsonify({'error': 'Missing "query" key in request body'}), 400)

        # Get the response and links using the make_query function
        response, links = make_query(query)

        # Create a JSON response with the response and links
        resp = jsonify({'response': response, 'links': links})
        return resp

    except Exception as error:
        # Handle any unexpected errors
        return make_response(jsonify({'error': str(error)}), 500)


@app.route('/hello', methods=['GET', 'OPTIONS'])
@cross_origin()
def hello_world():
    """
    A simple hello world endpoint.

    Returns:
        resp (json): A JSON response containing a hello world message."""
    resp = jsonify({'message': 'Hello World!'})
    return resp


@app.route('/classify/builder', methods=['POST', 'OPTIONS'])
@cross_origin()
def classify_builder():
    """
    An endpoint for classifying users based on the question they ask.

    Returns:
        resp(json): A JSON response containing the classification label."""
    try:
        # Check if the request body is JSON
        if not request.is_json:
            return make_response(jsonify({'error': 'Request body must be JSON'}), 400)

        # Extract the query from the request JSON body
        query = request.json.get('query')
        if not query:
            return make_response(jsonify({'error': 'Missing "query" key in request body'}), 400)

        # Get the response and links using the make_query function
        classifier = generate_classification(GPT_MODEL, query)

        # Create a JSON response with the response and links
        resp = jsonify({'weights': classifier})
        return resp

    except Exception as error:
        # Handle any unexpected errors
        return make_response(jsonify({'error': str(error)}), 500)
