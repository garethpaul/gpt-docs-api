import boto3
from chalicelib.config import CACHE_TABLE_NAME

# Create a DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Get the table reference
cache_table = dynamodb.Table(CACHE_TABLE_NAME)


def get_cached_response(query):
    """
    Get the cached response for the given query string.
    """
    cache_entry = cache_table.get_item(Key={'query_string': query}).get('Item')
    return cache_entry


def store_in_cache(query, response, links):
    """
    Store the response and links in the cache.
    """
    cache_table.put_item(
        Item={'query_string': query, 'response': response, 'links': links})
