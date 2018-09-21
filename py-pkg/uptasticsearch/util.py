"""
Small function to validate and format an Elasticsearch hostname string.
"""

import re


def _format_es_url(es_host):
    """
    Given a string with an Elasticsearch hostname, confirm its validity and,
    in some cases, fix issues.

    A valid Elasticsearch hostname has the following components:
        * Begins with a transfer protocol, e.g. "http://"
        * transfer protocol is followed by DNS name or IP to a running
          Elasticsearch cluster. e.g. "myindex.mybusiness.com"
        * Cluster name is following by a port number, e.g. ":9200"

    Args:
        es_host (str): A string containing an Elasticsearch hostname

    Returns:
        A string with a cleaned-up Elasticsearch hostname
    """

    if not isinstance(es_host, str):
        raise TypeError('es_host should be of type "str", you provided {}'.format(type(es_host)))

    if " " in es_host:
        raise ValueError("urls must not contain literal spaces")

    # es_host does not end in a slash
    trailing_slash_pattern = '/+$'
    if re.search(trailing_slash_pattern, es_host):
        es_host = re.sub('/+$', '', es_host)

    # es_host has a port number
    port_pattern = ':[0-9]+$'
    if not re.search(port_pattern, es_host):
        msg = 'No port found in es_host. es_host should be a string of the form ' + \
              '[transfer_protocol][hostname]:[port]. For example: ' + \
              '"http://myindex.mysite.com:9200"'
        raise ValueError(msg)

    # es_host has a valid protocol
    protocol_pattern = '^[A-Za-z]+://'
    if not re.search(protocol_pattern, es_host):
        print('You did not provide a protocol with es_host. Assuming http')

        # Doing this to avoid cases where you just missed a slash or something,
        # e.g. "http:/es.thing.com:9200" --> "es.thing.com:9200"
        # This will also match IP addresses, e.g. '0.0.0.0:9200
        host_m = re.search('(\.?[A-Za-z0-9]+)*:[0-9]+$', es_host)
        host = es_host[host_m.start():host_m.end()]

        es_host = 'http://' + host

    return es_host


def convert_to_sec(duration_string):
    """
    Given a string that could be passed as a datemath expression to
        Elasticsearch (e.g. "2m"), parse it and return numerical value
        in seconds.

    Args:
        duration_string (str): A string of the form '<number><time_unit>'
            (e.g. '21d', '15h'). Currently, 's', 'm', 'h', 'd', and 'w'
            are supported.

    Returns:
        Numeric value (in seconds) of duration_string.
    """
    if not isinstance(duration_string, str):
        raise TypeError("A string of the form '<number><time_unit>' must be provided")

    # Grab string from the end (e.g. "2d" --> "d")
    time_unit = re.search('([A-Za-z])+$', duration_string).groups()[0]

    # Grab numeric component
    time_num = int(re.sub(time_unit, '', duration_string))

    # Build up switch dict on time_unit
    time_converter = {
        's': lambda x: x,
        'm': lambda x: x * 60,
        'h': lambda x: x * 60 * 60,
        'd': lambda x: x * 60 * 60 * 24,
        'w': lambda x: x * 60 * 60 * 24 * 7
    }

    # Try to convert duration string to numeric value
    converter = time_converter.get(time_unit)
    if converter is None:
        msg = 'Could not figure out units of datemath ' + \
              'string! Only durations in seconds (s), ' + \
              'minutes (m), hours (h), days (d), or weeks (w) ' + \
              'are supported. You provided: ' + str(duration_string)
        raise ValueError(msg)

    time_in_seconds = converter(time_num)

    return time_in_seconds
