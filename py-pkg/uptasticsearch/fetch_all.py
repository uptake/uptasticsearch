"""Functions for Pulling data from ES and unpacking into a table
"""

import pandas as pd
import json

from uptasticsearch.clients import uptasticsearch_factory


def es_search(es_host, es_index, query_body="{}", size=10000, max_hits=None, scroll="5m"):
    """
    Execute a query to elasticsearch and get a DataFrame back

    Args:
        es_host (string): a url of the elasticsearch cluster e.g. http://localhost:9200
        es_index (string): the name of the ES index
        query_body (json): json query
        size (int): the number of hits per page. Note: the size will not affect max_hits, 
            but it will affect the time to return the max_hits.
        max_hits (int, None): the total number of hits to allow. If None, no limit
        scroll (str): the time to keep the scroll context alive for each page

    Return:
        A pandas DataFrame

    """

    client = uptasticsearch_factory(es_host)

    # Figure out if we are scrolling or getting an aggs result
    if json.loads(query_body).get("aggs") is not None:
        msg = "es_search detected that this is an aggs request " + \
              "and will only return aggregation results."
        print(msg)

        # TODO (james.lamb@uptake.com): implemented the aggs parser
        raise NotImplementedError("es_search aggs parser has not been implemented yet!")

    else:
        docs = client.search(query_body,
                             index=es_index,
                             scroll_context_timer=scroll,
                             page_size=size,
                             max_hits=max_hits)

        if len(docs) > 0:
            return pd.io.json.json_normalize(docs)
        else:
            return None
