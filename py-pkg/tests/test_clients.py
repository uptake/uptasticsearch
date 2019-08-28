"""Integration Tests - test against each version of Elasticsearch
"""
import pytest
import json
import pandas as pd

from uptasticsearch.clients import Uptasticsearch1
from uptasticsearch.clients import Uptasticsearch2
from uptasticsearch.clients import Uptasticsearch5
from uptasticsearch.clients import Uptasticsearch6
from uptasticsearch.clients import Uptasticsearch7
from uptasticsearch.clients import uptasticsearch_factory

from uptasticsearch.fetch_all import es_search


class TestEsSearch(object):
    """
    es_search should work an return a pandas DataFrame
    """
    host = "http://127.0.0.1:9200"
    def test_rectangle(self):
        assert isinstance(es_search(self.host,
                                    "shakespeare",
                                    query_body=json.dumps({}),
                                    size=10000,
                                    max_hits=10,
                                    scroll="1m"),
                          pd.DataFrame)
