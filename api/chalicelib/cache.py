import hashlib
import time
from decimal import Decimal

from chalicelib.config import CACHE_TABLE_NAME, CACHE_TTL_SECONDS


def cache_key(query):
    """Return a fixed-size, privacy-minimizing identity for query text."""
    digest = hashlib.sha256(query.encode('utf-8')).hexdigest()
    return 'query_sha256:' + digest


def get_cache_table(resource=None):
    """
    Get the DynamoDB table used for cached responses.
    """
    if resource is None:
        import boto3

        resource = boto3.resource('dynamodb')
    dynamodb = resource
    return dynamodb.Table(CACHE_TABLE_NAME)


def get_cached_response(query, table=None, now=None):
    """
    Get the cached response for the given query string.
    """
    cache_table = table if table is not None else get_cache_table()
    cache_entry = cache_table.get_item(
        Key={'query_string': cache_key(query)}
    ).get('Item')
    if not cache_entry:
        return None

    expires_at = cache_entry.get('expires_at')
    if (isinstance(expires_at, bool) or
            not isinstance(expires_at, (int, Decimal))):
        return None

    current_time = int(time.time()) if now is None else now
    if expires_at <= current_time:
        return None

    return cache_entry


def store_in_cache(query, response, links, table=None, now=None,
                   ttl_seconds=CACHE_TTL_SECONDS):
    """
    Store the response and links in the cache.
    """
    if (isinstance(ttl_seconds, bool) or not isinstance(ttl_seconds, int) or
            ttl_seconds <= 0):
        raise ValueError('Cache TTL must be a positive integer')

    cache_table = table if table is not None else get_cache_table()
    current_time = int(time.time()) if now is None else now
    cache_table.put_item(
        Item={'query_string': cache_key(query),
              'response': response,
              'links': links,
              'expires_at': current_time + ttl_seconds})
