# Copyright @GPJ
# License: MIT
"""Chalice app for the GPT Docs app."""
import logging
import pinecone
import os
from chalice import Chalice, Response, CORSConfig
from typing import Tuple, List
from urllib.parse import urlparse
from chalicelib.auth import (
    AuthenticationConfigurationError,
    AuthenticationError,
    require_api_key
)
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
from chalicelib.utils import validate_request_payload

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# CORS configuration to allow all origins
cors_config = CORSConfig(
    allow_origin='*',
    allow_headers=['Content-Type', 'Authorization', 'X-GPT-Docs-API-Key'],
    max_age=600,
    expose_headers=['Content-Type'],
    allow_credentials=False
)


# Create a Chalice app
app = Chalice(app_name='flask_to_lambda')

# Get the directory containing the app.py file
current_directory = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the public directory
directory_path = os.path.join(current_directory, 'chalicelib', 'public')

PUBLIC_CONTENT_TYPES = {
    '.txt': 'text/plain',
    '.json': 'application/json',
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
}
MAX_RETRIEVAL_CONTEXT_LENGTH = 4000
RETRIEVAL_CONTEXT_SEPARATOR = "\n\n---\n\n"


def safe_public_file_path(filename):
    """Return a public asset path only when it stays inside the public root."""
    public_root = os.path.realpath(directory_path)
    requested_path = os.path.realpath(os.path.join(public_root, filename))

    if requested_path != public_root and not requested_path.startswith(
        public_root + os.sep
    ):
        raise ValueError('Invalid public file path')

    if not os.path.isfile(requested_path):
        raise FileNotFoundError(f"File '{filename}' not found.")

    return requested_path


def public_content_type(file_path):
    """Return the response content type for a public asset."""
    _, extension = os.path.splitext(file_path)
    return PUBLIC_CONTENT_TYPES.get(extension.lower(), 'application/octet-stream')


def is_twilio_doc_url(url):
    """Return True for HTTPS Twilio-hosted documentation links."""
    try:
        parsed = urlparse(url)
    except (TypeError, ValueError):
        return False
    hostname = parsed.hostname or ''
    return parsed.scheme == 'https' and (
        hostname == 'twilio.com' or hostname.endswith('.twilio.com')
    )


def filter_twilio_doc_urls(urls):
    """Return unique HTTPS Twilio documentation links in deterministic order."""
    filtered_urls = []
    for url in urls:
        if is_twilio_doc_url(url) and url not in filtered_urls:
            filtered_urls.append(url)
    return sorted(filtered_urls)


def retrieval_metadata(item):
    """Return match metadata without propagating provider accessor failures."""
    try:
        if isinstance(item, dict):
            get_metadata = getattr(item, 'get', None)
            if not callable(get_metadata):
                return None
            return get_metadata('metadata')
        return getattr(item, 'metadata', None)
    except Exception:
        return None


def metadata_text_and_url(item):
    """Return usable retrieval context and URL metadata from a Pinecone match."""
    metadata = retrieval_metadata(item)
    if not isinstance(metadata, dict):
        return None, None

    text = metadata.get('text')
    if not isinstance(text, str):
        return None, None

    context = text.strip()
    if not context:
        return None, None
    if len(context) > MAX_RETRIEVAL_CONTEXT_LENGTH:
        context = context[:MAX_RETRIEVAL_CONTEXT_LENGTH]

    url = metadata.get('url')
    if not isinstance(url, str):
        url = ''

    return context, url


def retrieval_matches(response):
    """Return Pinecone matches only from a supported collection shape."""
    try:
        get_matches = getattr(response, 'get', None)
        if callable(get_matches):
            matches = get_matches('matches', [])
        else:
            matches = getattr(response, 'matches', [])
    except Exception:
        return ()

    if not isinstance(matches, (list, tuple)):
        return ()
    return matches


@app.route('/public/{filename}', methods=['GET'])
def serve_public(filename):
    """
    Serve the public files from the specified directory.
    """
    try:
        file_path = safe_public_file_path(filename)

        # Read the file content
        with open(file_path, 'rb') as file:
            file_content = file.read()

        # Return the file content as a response
        return Response(body=file_content,
                        status_code=200,
                        headers={'Content-Type': public_content_type(file_path)})

    except ValueError as error:
        return Response(body={'error': str(error)}, status_code=400)
    except FileNotFoundError as error:
        return Response(body={'error': str(error)}, status_code=404)
    except OSError as error:
        logger.error(f'Failed to serve public file: {error}')
        return Response(body={'error': 'Unable to read public file'},
                        status_code=500)


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
    return pinecone.Index(INDEX_NAME)


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
    remaining_context_length = MAX_RETRIEVAL_CONTEXT_LENGTH

    # Extract the contexts and URLs from the query results
    matches = retrieval_matches(res)
    for item in matches:
        context, url = metadata_text_and_url(item)
        if context is None:
            continue

        separator_length = len(RETRIEVAL_CONTEXT_SEPARATOR) if contexts else 0
        available_length = remaining_context_length - separator_length
        if available_length <= 0:
            break

        bounded_context = context[:available_length]
        contexts.append(bounded_context)
        urls.append(url)
        remaining_context_length -= separator_length + len(bounded_context)

        if remaining_context_length == 0:
            break

    augmented_query = RETRIEVAL_CONTEXT_SEPARATOR.join(contexts)+"\n\n-----\n\n"+query

    # Generate response
    response = generate_response(augmented_query)

    # Keep this explicit loop compatible with Chalice's IAM policy analyzer.
    urls = filter_twilio_doc_urls(urls)

    return response, urls


def authorize_request():
    """
    Return an HTTP response when the current request is not authorized.
    """
    try:
        require_api_key(app.current_request.headers)
    except AuthenticationConfigurationError as error:
        return Response(body={'error': str(error)}, status_code=503)
    except AuthenticationError as error:
        return Response(body={'error': str(error)}, status_code=401)
    return None


@app.route('/ask', methods=['POST'], cors=cors_config)
def ask_question():
    """
    Process a user query and return a generated response and relevant links.
    Expects a JSON payload with a 'query' key in the request body.

    Returns:
        resp (json): A JSON response containing the generated response and relevant links.
    """
    try:
        unauthorized_response = authorize_request()
        if unauthorized_response is not None:
            return unauthorized_response

        # Extract the JSON payload from the request
        request_json = app.current_request.json_body

        try:
            query = validate_request_payload(request_json)
        except ValueError as error:
            return Response(body={'error': str(error)}, status_code=400)

        # Check cache for a matching query
        try:
            cache_entry = get_cached_response(query)
        except Exception:
            logger.exception('Failed to read response cache; bypassing cache')
            cache_entry = None
        if cache_entry:
            return Response(body={'response': cache_entry['response'],
                                  'links': filter_twilio_doc_urls(
                                      cache_entry['links'])},
                            status_code=200)

        # Get the response and links using the make_query function
        response, links = make_query(query)

        # Push the cache entry to the cache
        try:
            store_in_cache(query, response, links)
        except Exception:
            logger.exception(
                'Failed to write response cache; returning generated response'
            )

        # Create a JSON response with the response and links
        resp = Response(body={'response': response,
                        'links': links}, status_code=200)
        return resp

    except Exception:
        # Handle any unexpected errors
        logger.exception('Failed to process ask request')
        return Response(body={'error': 'Internal server error'}, status_code=500)


@app.route('/hello', methods=['GET'], cors=cors_config)
def hello_world():
    """
    A simple hello world endpoint.

    Returns:
        resp (json): A JSON response containing a hello world message."""
    resp = {'message': 'Hello World!'}
    return resp


@app.route('/classify/builder', methods=['POST'], cors=cors_config)
def classify_builder():
    """
    An endpoint for classifying users based on the question they ask.

    Returns:
        resp(json): A JSON response containing the classification label."""
    try:
        unauthorized_response = authorize_request()
        if unauthorized_response is not None:
            return unauthorized_response

        # Extract the JSON payload from the request
        request_json = app.current_request.json_body

        try:
            query = validate_request_payload(request_json)
        except ValueError as error:
            return Response(body={'error': str(error)}, status_code=400)

        # Get the response and links using the make_query function
        classifier = generate_classification(GPT_MODEL, query)

        # Create a JSON response with the response and links
        resp = Response(body={'weights': classifier}, status_code=200)
        return resp

    except Exception:
        # Handle any unexpected errors
        logger.exception('Failed to process classify request')
        return Response(body={'error': 'Internal server error'}, status_code=500)
