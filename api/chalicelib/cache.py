from chalicelib.config import CACHE_TABLE_NAME


def get_cache_table(resource=None):
    """
    Get the DynamoDB table used for cached responses.
    """
    if resource is None:
        import boto3

        resource = boto3.resource('dynamodb')
    dynamodb = resource
    return dynamodb.Table(CACHE_TABLE_NAME)


def get_cached_response(query, table=None):
    """
    Get the cached response for the given query string.
    """
    cache_table = table or get_cache_table()
    cache_entry = cache_table.get_item(Key={'query_string': query}).get('Item')
    return cache_entry


def store_in_cache(query, response, links, table=None):
    """
    Store the response and links in the cache.
    """
    cache_table = table or get_cache_table()
    cache_table.put_item(
        Item={'query_string': query, 'response': response, 'links': links})
