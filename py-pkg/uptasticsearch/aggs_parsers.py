
import pandas as pd


def _terms_agg_to_df(aggs_json):
    """
    Given the JSON returned by an Elasticsearch aggs "terms" query,
    parse that JSON into a Pandas DataFrame. Currently only has
    support for a one-field aggs.

    The "terms" query is analogous to a COUNT() and GROUPBY in SQL world.
    It returns counts of unique values for a given attribute. For more, see
    https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html

    Args:
        **aggs_json (dict)**: A dictionary representation of an aggs query
            result. If a str is passed, it will be converted to a dictionary.

    Returns:
        A pandas DataFrame representation of the aggs query.
    """

    if not isinstance(aggs_json, str):
        raise TypeError("aggs_json must be a dictionary, you gave {}".format(type(aggs_json)))

    # Parse the result into a DF
    key_name = list(aggs_json.keys())[0]

    parsed_obs = [[obs['key'], obs['doc_count']] for obs in aggs_json[key_name]['buckets']]
    out_df = pd.DataFrame(parsed_obs, columns=[key_name, 'doc_count'])

    return(out_df)


def _extended_stats_agg_to_df(aggs_json):
    """
    Given the JSON returned by an Elasticsearch "extended_stats" aggregation,
    parse that JSON into a Pandas DataFrame. Currently only has
    support for a one-field aggs.

    The "extended_stats" aggregation computes the following summary statistics
    on a given numerical field: count, min, max, mean, sum, sum of squares,
    variance, and standard deviation. For more, see
    https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-extendedstats-aggregation.html

    Args:
        **aggs_json (dict)**: A dictionary representation of an aggs query
            result. If a str is passed, it will be converted to a dictionary.

    Returns:
        A pandas DataFrame representation of the aggs query.
    """

    if not isinstance(aggs_json, str):
        raise TypeError("aggs_json must be a dictionary, you gave {}".format(type(aggs_json)))

    # Parse the result into a DF
    key_name = list(aggs_json.keys())[0]

    out_df = pd.DataFrame({'agg_field': key_name,
                           'count': aggs_json[key_name]['count'],
                           'min': aggs_json[key_name]['min'],
                           'max': aggs_json[key_name]['max'],
                           'avg': aggs_json[key_name]['avg'],
                           'sum': aggs_json[key_name]['sum'],
                           'sum_of_squares': aggs_json[key_name]['sum_of_squares'],
                           'variance': aggs_json[key_name]['variance'],
                           'std_deviation': aggs_json[key_name]['std_deviation']
                           }, index=[0])

    return(out_df)


def _stats_agg_to_df(aggs_json):
    """
    Given the JSON returned by an Elasticsearch "stats" aggregation,
    parse that JSON into a Pandas DataFrame. Currently only has
    support for a one-field aggs.

    The "stats" aggregation computes the following summary statistics
    on a given numerical field: count, min, max, mean, sum. For more, see
    https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-stats-aggregation.html

    Args:
        **aggs_json (dict)**: A dictionary representation of an aggs query
            result. If a str is passed, it will be converted to a dictionary.

    Returns:
        A pandas DataFrame representation of the aggs query.
    """

    if not isinstance(aggs_json, str):
        raise TypeError("aggs_json must be a dictionary, you gave {}".format(type(aggs_json)))

    # Parse the result into a DF
    key_name = list(aggs_json.keys())[0]

    out_df = pd.DataFrame({'agg_field': key_name,
                           'count': aggs_json[key_name]['count'],
                           'min': aggs_json[key_name]['min'],
                           'max': aggs_json[key_name]['max'],
                           'avg': aggs_json[key_name]['avg'],
                           'sum': aggs_json[key_name]['sum']
                           }, index=[0])

    return(out_df)


def _date_histogram_agg_to_df(aggs_json):
    """
    Given the JSON returned by an Elasticsearch aggs "date_histogram" query,
    parse that JSON into a Pandas DataFrame. Currently only has
    support for a one-field aggs.

    The "date_histogram" aggregation is used to bucket records into discrete,
    equal-sized time windows. The plain-vanilla date_histogram aggregation
    returns counts of documents within each window, but the most common use
    case involves nested other aggregations within a date_histogram to
    create time-series features. For more, see:
    https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-datehistogram-aggregation.html

    Args:
        **aggs_json (dict)**: A dictionary representation of an aggs query
            result. If a str is passed, it will be converted to a dictionary.

    Returns:
        A pandas DataFrame representation of the aggs query.
    """

    if not isinstance(aggs_json, str):
        raise TypeError("aggs_json must be a dictionary, you gave {}".format(type(aggs_json)))

    # Parse the result into a DF
    key_name = list(aggs_json.keys())[0]

    parsed_obs = [[obs['key_as_string'], obs['doc_count']] for obs in aggs_json[key_name]['buckets']]
    out_df = pd.DataFrame(parsed_obs, columns=[key_name, 'doc_count'])

    return(out_df)


def _percentiles_agg_to_df(aggs_json):
    """
    Given the JSON returned by an Elasticsearch aggs "percentiles" query,
    parse that JSON into a Pandas DataFrame. Currently only has
    support for a one-field aggs.

    The "percentiles" aggregation takes in a vector of desired percentiles
    and returns the corresponding percentiles from the distribution of a
    numeric field. For more, see
    https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-percentile-aggregation.html

    Args:
        **aggs_json (dict)**: A dictionary representation of an aggs query
            result. If a str is passed, it will be converted to a dictionary.

    Returns:
        A pandas DataFrame representation of the aggs query.
    """

    if not isinstance(aggs_json, str):
        raise TypeError("aggs_json must be a dictionary, you gave {}".format(type(aggs_json)))

    # Parse the result into a DF
    key_name = list(aggs_json.keys())[0]

    out_dict = {'agg_field': key_name}
    out_dict.update(aggs_json[key_name]['values'])
    out_df = pd.DataFrame(out_dict, index=[0])

    return(out_df)
