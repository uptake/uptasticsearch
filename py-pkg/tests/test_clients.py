"""Integration Tests - test against each version of Elasticsearch
"""
import pytest
import json
import pandas as pd

from uptasticsearch.clients import Uptasticsearch1
from uptasticsearch.clients import Uptasticsearch2
from uptasticsearch.clients import Uptasticsearch5
from uptasticsearch.clients import Uptasticsearch6
from uptasticsearch.clients import uptasticsearch_factory

from uptasticsearch.fetch_all import es_search


ELASTICSEARCH_HOST_1 = "es_1"
ELASTICSEARCH_HOST_2 = "es_2"
ELASTICSEARCH_HOST_5 = "es_5"
ELASTICSEARCH_HOST_6 = "es_6"


class TestUptasticsearch(object):

    def _simple_query(self, hostname):
        u = uptasticsearch_factory("http://{}:9200".format(hostname))
        results = u.search(json.dumps({
            "query": {
                "match_all": {}
            }
        }), index="shakespeare")
        assert len(results) == 25000

    def test_es_1_scroll(self):
        self._simple_query(ELASTICSEARCH_HOST_1)

    def test_es_2_scroll(self):
        self._simple_query(ELASTICSEARCH_HOST_2)

    def test_es_5_scroll(self):
        self._simple_query(ELASTICSEARCH_HOST_5)

    def test_es_6_scroll(self):
        self._simple_query(ELASTICSEARCH_HOST_6)

    def test_factory(self):
        assert isinstance(uptasticsearch_factory("http://{}:9200".format(ELASTICSEARCH_HOST_1)), Uptasticsearch1)
        assert isinstance(uptasticsearch_factory("http://{}:9200".format(ELASTICSEARCH_HOST_2)), Uptasticsearch2)
        assert isinstance(uptasticsearch_factory("http://{}:9200".format(ELASTICSEARCH_HOST_5)), Uptasticsearch5)
        assert isinstance(uptasticsearch_factory("http://{}:9200".format(ELASTICSEARCH_HOST_6)), Uptasticsearch6)


class TestEsSearch(object):

    def _test_rectangle(self, hostname):
        assert isinstance(es_search("http://{}:9200".format(hostname),
                                    "shakespeare",
                                    query_body=json.dumps({}),
                                    size=10000,
                                    max_hits=10,
                                    scroll="1m"),
                          pd.DataFrame)

    def test_es_1_scroll(self):
        self._test_rectangle(ELASTICSEARCH_HOST_1)

    def test_es_2_scroll(self):
        self._test_rectangle(ELASTICSEARCH_HOST_2)

    def test_es_5_scroll(self):
        self._test_rectangle(ELASTICSEARCH_HOST_5)

    def test_es_6_scroll(self):
        self._test_rectangle(ELASTICSEARCH_HOST_6)
