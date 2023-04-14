# Copyright @GPJ
# License: MIT
"""Chalice app for the GPT Docs app."""
import logging
import pinecone
import os
from chalice import Chalice, Response, CORSConfig, BadRequestError
from typing import Tuple, List
from chalicelib.cache import get_cached_response, store_in_cache
from chalicelib.classification import (
    generate_response,
    get_embeddings,
    generate_classification
)
from chalicelib.config import (
    PINECONE_API_KEY_ENV,
    PINECONE_ENVIRONMENT_ENV,
    INDEX_NAME,
    INDEX_DIMENSION,
    INDEX_METRIC,
    GPT_MODEL
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# CORS configuration to allow all origins
cors_config = CORSConfig(
    allow_origin='*',
    allow_headers=['Content-Type'],
    max_age=600,
    expose_headers=['Content-Type'],
    allow_credentials=True
)


# Create a Chalice app
app = Chalice(app_name='flask_to_lambda')

# Get the directory containing the app.py file
current_directory = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the public directory
directory_path = os.path.join(current_directory, 'chalicelib', 'public')


@app.route('/public/{filename}', methods=['GET'])
def serve_public(filename):
    """
    Serve the public files from the specified directory.
    """
    try:
        # Construct the full file path
        file_path = os.path.join(directory_path, filename)
        # Check if the file exists
        if not os.path.isfile(file_path):
            raise BadRequestError(f"File '{filename}' not found.")

        # Read the file content
        with open(file_path, 'rb') as file:
            file_content = file.read()

        # Set the content type based on the file extension (optional)
        content_type = None
        if file_path.endswith('.txt'):
            content_type = 'text/plain'
        elif file_path.endswith('.json'):
            content_type = 'application/json'
        elif file_path.endswith('.html'):
            content_type = 'text/html'
        elif file_path.endswith('.js'):
            content_type = 'application/javascript'
        elif file_path.endswith('.css'):
            content_type = 'text/css'
        elif file_path.endswith('.png'):
            content_type = 'image/png'
        elif file_path.endswith('.svg'):
            content_type = 'image/svg+xml'
        # Add more content types if needed

        # Return the file content as a response
        return Response(body=file_content,
                        status_code=200,
                        headers={'Content-Type': content_type})

    except Exception as error:
        # Handle any unexpected errors
        return Response(body=str(error), status_code=500)


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


def create_index_if_not_exists(index_name: str,
                               dimension: int,
                               metric: str) -> None:
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


@app.route('/ask', methods=['POST'], cors=cors_config)
def ask_question():
    """
    Process a user query and return a generated response and relevant links.
    Expects a JSON payload with a 'query' key in the request body.

    Returns:
        resp (json): A JSON response containing the generated response and relevant links.
    """
    try:
        # Extract the JSON payload from the request
        request_json = app.current_request.json_body

        # Check if the request body is JSON
        if not request_json:
            return Response(body={'error': 'Request body must be JSON'},
                            status_code=400)

        # Extract the query from the request JSON body
        query = request_json.get('query')
        if not query:
            return Response(body={'error': 'Missing "query" key in request body'},
                            status_code=400)

        # Check cache for a matching query
        cache_entry = get_cached_response(query)
        if cache_entry:
            return Response(body={'response': cache_entry['response'],
                                  'links': cache_entry['links']},
                            status_code=200)

        # Get the response and links using the make_query function
        response, links = make_query(query)

        # Push the cache entry to the cache
        store_in_cache(query, response, links)

        # Create a JSON response with the response and links
        resp = Response(body={'response': response,
                        'links': links}, status_code=200)
        return resp

    except Exception as error:
        # Handle any unexpected errors
        return Response(body={'error': str(error)}, status_code=500)


@app.route('/hello', methods=['GET'], cors=cors_config)
def hello_world():
    """
    A simple hello world endpoint.

    Returns:
        resp (json): A JSON response containing a hello world message."""
    resp = {'message': 'Hello World!'}
    return resp


@app.route('/classify/builder', methods=['POST'])
def classify_builder():
    """
    An endpoint for classifying users based on the question they ask.

    Returns:
        resp(json): A JSON response containing the classification label."""
    try:
        # Extract the JSON payload from the request
        request_json = app.current_request.json_body

        # Check if the request body is JSON
        if not request_json:
            return Response(body={'error': 'Request body must be JSON'},
                            status_code=400)

        # Extract the query from the request JSON body
        query = request_json.get('query')
        if not query:
            return Response(body={'error': 'Missing "query" key in request body'}, status_code=400)

        # Get the response and links using the make_query function
        classifier = generate_classification(GPT_MODEL, query)

        # Create a JSON response with the response and links
        resp = Response(body={'weights': classifier}, status_code=200)
        return resp

    except Exception as error:
        # Handle any unexpected errors
        return Response(body={'error': str(error)}, status_code=500)
