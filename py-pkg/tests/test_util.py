"""Test the util module
"""

import pytest

from uptasticsearch.util import _format_es_url
from uptasticsearch.util import convert_to_sec


class TestFormatUrl(object):
    """Tests for uptasticsearch.util._format_es_url
    """
    def test_typing(self):
        """throws TypeErrors w/ bad types, returns correct type
        """
        with pytest.raises(TypeError):
            _format_es_url(3)
        with pytest.raises(TypeError):
            _format_es_url(3.14)
        with pytest.raises(TypeError):
            _format_es_url(lambda x: 'cat')
        with pytest.raises(TypeError):
            _format_es_url([1, 2, 3])
        with pytest.raises(TypeError):
            _format_es_url({"key": "value"})
        assert isinstance(_format_es_url("http://es.com:9200"), str)

    def test_normal(self):
        """returns a valid url unchanged
        """
        valid_url = "http://es.cluster.com:9200"
        assert valid_url == _format_es_url(valid_url)
        assert "http://localhost:9200" == _format_es_url("localhost:9200")

    def test_slash_removal(self):
        """removes extra trailing slashes
        """
        assert _format_es_url("http://es.cluster.com:9200/") == "http://es.cluster.com:9200"
        assert _format_es_url("http://es.cluster.com:9200///") == "http://es.cluster.com:9200"

    def test_protocol(self):
        """inserts protocol if missing/broken
        """
        assert _format_es_url("es.cluster.com:9200/") == "http://es.cluster.com:9200"
        assert _format_es_url("http:/es.cluster.com:9200/") == "http://es.cluster.com:9200"

    def test_port(self):
        """raises ValueError w/o proper port
        """
        with pytest.raises(ValueError):
            _format_es_url("es.cluster.com/")
        with pytest.raises(ValueError):
            _format_es_url("es.cluster.com")
        assert isinstance(_format_es_url("http://es.com:9200"), str)
        assert isinstance(_format_es_url("es.es.com:9200"), str)

    def test_nonsense(self):
        """test that it fails with nonsense
        """
        with pytest.raises(ValueError):
            _format_es_url("some garbage string")
        with pytest.raises(ValueError):
            _format_es_url("some garbage string that has http:// in it")
        with pytest.raises(ValueError):
            _format_es_url("some garbage string that has http:// in it:9200")
        with pytest.raises(ValueError):
            _format_es_url("s3:// some garbage string that has http:// in it:9200")


class TestConvertToSec(object):
    """Test uptasticsearch.util.convert_to_sec
    """
    def test_typing(self):
        with pytest.raises(TypeError):
            convert_to_sec(1)
        with pytest.raises(TypeError):
            convert_to_sec([1])
        with pytest.raises(TypeError):
            convert_to_sec({"cat": "dog"})
        with pytest.raises(TypeError):
            convert_to_sec(1.0)
        assert convert_to_sec("1m") == 60

    def test_garbage(self):
        with pytest.raises(ValueError):
            convert_to_sec("cactus")
        with pytest.raises(ValueError):
            convert_to_sec("1y")


    def test_normal(self):
        assert convert_to_sec("1s") == 1
        assert convert_to_sec("1m") == 60
        assert convert_to_sec("5m") == 300
        assert convert_to_sec("1h") == 3600
        assert convert_to_sec("1d") == 86400
        assert convert_to_sec("2w") == 1209600
