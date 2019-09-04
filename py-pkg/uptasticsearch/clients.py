import requests
import json
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter

import os

from uptasticsearch.util import _format_es_url
from uptasticsearch.util import convert_to_sec


class HttpClient(object):

    def __init__(self, retries=5, backoff_factor=0.1):
        self.retry = Retry(total=retries,
                           backoff_factor=backoff_factor,
                           status_forcelist=[500, 502, 503, 504])

    def get(self, url, data=None, headers=None):
        s = requests.Session()
        s.mount('http://', HTTPAdapter(max_retries=self.retry))
        return s.get(url, data=data, headers=headers)

    def post(self, url, data, headers=None):
        s = requests.Session()
        s.mount('http://', HTTPAdapter(max_retries=self.retry))
        return s.post(url, data=data, headers=headers)


class Uptasticsearch(object):

    def __init__(self, url, http_client=HttpClient()):
        self.url = _format_es_url(url)
        self.client = http_client

    def _get_total_hits(self, response_json):
        """
        Given a dictionary representing the content of a
        respose to a  ``POST /_search`` request, return the total
        number of docs matching the query
        """
        return response_json['hits']['total']

    def search(self, body, index="", doc_type="", scroll_context_timer="1m", page_size=10000,  max_hits=None):
        """Execute a Search Query on the Elasticsearch Cluster

        Args:
            body (json string): The query body
            index (string): The name of the Index to Query. Default: "" (no index)
            doc_type (string): The Doc Type to query. Default: "" (no doc_type)
            scroll_context_timer (string): A string such as "1m" or "5m" that specifies how long to keep the scroll context alive between pages for large queries. Default: "1m"
            page_size (int): The number of 'hits' per page. Default: 10000
            max_hits (int): The maximum number of 'hits' to return. Default: None, all hits will be returned

        Return:
            A List of Dicts. Each Dict is the value of the "_source" key for each of the hits.

        """

        convert_to_sec(scroll_context_timer)  # check context timer input

        response = self.client.post(os.path.join(self.url,
                                                 index,
                                                 doc_type,
                                                 "_search?scroll={}&size={}".format(scroll_context_timer,
                                                                                    page_size)),
                                    data=body,
                                    headers={'Content-Type': 'application/json'})

        page = response.json()
        total_hits = self._get_total_hits(page)
        total_hits = min(total_hits, max_hits) if max_hits is not None else total_hits

        results = [d['_source'] for d in page['hits']['hits']]
        page_size = len(results)

        while page_size > 0 and len(results) < total_hits:
            page = self._make_scroll_request(scroll_context_timer,
                                             page.get("_scroll_id")).json()
            page_size = len(page['hits']['hits'])
            results += [d['_source'] for d in page['hits']['hits']]

        if total_hits > len(results):
            raise Exception('Expected {} Results, instead got {}'.format(total_hits, len(results)))
        else:
            return results[:total_hits]

    def _make_scroll_request(self, scroll_context_timer, scroll_id):
        raise NotImplementedError("_make_scroll_request is abstract. Use a subclass instead of Uptasticsearch")


class Uptasticsearch1(Uptasticsearch):

    def _make_scroll_request(self, scroll_context_timer, scroll_id):
        return self.client.post(os.path.join(self.url,
                                             "_search/scroll?scroll={}".format(scroll_context_timer)),
                                data=scroll_id)


class Uptasticsearch2(Uptasticsearch):

    def _make_scroll_request(self, scroll_context_timer, scroll_id):
        return self.client.post(os.path.join(self.url,
                                             "_search/scroll"),
                                data=json.dumps({"scroll": scroll_context_timer,
                                                 "scroll_id": scroll_id}),
                                headers={'Content-Type': 'application/json'})


class Uptasticsearch5(Uptasticsearch):

    def _make_scroll_request(self, scroll_context_timer, scroll_id):
        return self.client.post(os.path.join(self.url,
                                             "_search/scroll"),
                                data=json.dumps({"scroll": scroll_context_timer,
                                                 "scroll_id": scroll_id}),
                                headers={'Content-Type': 'application/json'})


class Uptasticsearch6(Uptasticsearch):

    def _make_scroll_request(self, scroll_context_timer, scroll_id):
        return self.client.post(os.path.join(self.url,
                                             "_search/scroll"),
                                data=json.dumps({"scroll": scroll_context_timer,
                                                 "scroll_id": scroll_id}),
                                headers={'Content-Type': 'application/json'})

class Uptasticsearch7(Uptasticsearch6):

    def _get_total_hits(self, response_json):
        """
        Given a dictionary representing the content of a
        respose to a  ``POST /_search`` request, return the total
        number of docs matching the query
        """
        return response_json['hits']['total']['value']


def uptasticsearch_factory(url, retries=5, backoff_factor=0.1):
    http_client = HttpClient(retries=retries, backoff_factor=backoff_factor)
    es_url = _format_es_url(url)
    cluster_version = http_client.get(es_url).json()['version']['number'].split('.')[0]

    return {
        "1": Uptasticsearch1,
        "2": Uptasticsearch2,
        "5": Uptasticsearch5,
        "6": Uptasticsearch6,
        "7": Uptasticsearch7
    }[cluster_version](es_url, http_client)
