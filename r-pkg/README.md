# uptasticsearch

## Introduction

This project tackles the issue of getting data out of Elasticsearch and into a tabular format in R.

## Table of contents
1. [How it Works](#howitworks)
2. [Installation](#installation)
3. [Usage Examples](#paragraph2)
    1. [Get a Batch of Documents](#example1)
    2. [Aggregation Results](#example2)
4. [Next Steps](#nextsteps)
    1. [Auth Support](#authsupport)

## How it Works <a name="howitworks"></a>

The core functionality of this package is the `es_search` function. This returns a `data.table` containing the parsed result of any given query. Note that this includes `aggs` queries.

## Installation <a name="installation"></a>

The package is not yet on CRAN, but we'll be submitting soon. For now, you can install using `devtools`.

```
devtools::install_github("UptakeOpenSource/uptasticsearch", subdir = 'r-pkg/uptasticsearch')
```

## Usage Examples <a name="examples"></a>

The examples presented here pertain to a fictional Elasticsearch index holding some information on a movie theater business.

### Example 1: Get a Batch of Documents <a name="example1"></a>

The most common use case for this package will be the case where you have an ES query and want to get a data frame representation of many resulting documents. 

In the example below, we use `uptasticsearch` to look for all survey results in which customers said their satisfaction was "low" or "very low" and mentioned food in their comments.

```
# Build your query in an R string
qbody <- '{
  "query": {
    "filtered": {
      "filter": {
        "bool": {
          "must": [
            {
              "exists": {
                "field": "customer_comments"
              }
            },
            {
              "terms": {
                "overall_satisfaction": ["very low", "low"]
              }
            }
          ]
        }
      }
    },
    "query": {
      "match_phrase": {
        "customer_comments": "food"
      }
    }
  }
}'

# Execute the query, parse into a data.table
commentDT <- es_search(es_host = 'http://mydb.mycompany.com:9200'
                       , es_index = "survey_results"
                       , query_body = qbody
                       , scroll = "1m"
                       , n_cores = 4)
```

### Example 2: Aggregation Results <a name="example2"></a>

Elasticsearch ships with a rich set of aggregations for creating summarized views of your data. `uptasticsearch` has built-in support for these aggregations. 

In the example below, we use `uptasticsearch` to create daily timeseries of summary statistics like total revenue and average payment amount.

```
# Build your query in an R string
qbody <- '{
  "query": {
    "filtered": {
      "filter": {
        "bool": {
          "must": [
            {
              "exists": {
                "field": "pmt_amount"
              }
            }
          ]
        }
      }
    }
  },
  "aggs": {
    "timestamp": {
      "date_histogram": {
        "field": "timestamp",
        "interval": "day"
      },
      "aggs": {
        "revenue": {
          "extended_stats": {
            "field": "pmt_amount"
          }
        }
      }
    }
  },
  "size": 0
}'

# Execute the query, parse result into a data.table
revenueDT <- es_search(es_host = 'http://mydb.mycompany.com:9200'
                       , es_index = "transactions"
                       , size = 1000
                       , query_body = qbody
                       , n_cores = 1)
```

In the example above, we used the [date_histogram](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-datehistogram-aggregation.html) and [extended_stats](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-extendedstats-aggregation.html) aggregations. `es_search` has built-in support for many other aggregations and combinations of aggregations, with more on the way. Please see the table below for the current status of the package. Note that names of the form "agg1 - agg2" refer to the ability to handled aggregations nested inside other aggregations.

|Agg type                                     | R support?  |
|:--------------------------------------------|:-----------:|
|["cardinality"](http://bit.ly/2sn5Qiw)       |YES          |
|["date_histogram"](http://bit.ly/2qIR97Z)    |YES          |
|date_histogram - cardinality                 |YES          |
|date_histogram - extended_stats              |YES          |
|date_histogram - histogram                   |YES          |
|date_histogram - percentiles                 |YES          |
|date_histogram - significant_terms           |YES          |
|date_histogram - stats                       |YES          |
|date_histogram - terms                       |YES          |
|["extended_stats"](http://bit.ly/2qKqsDU)    |YES          |
|["histogram"](http://bit.ly/2sn4LXF)         |YES          |
|["percentiles"](http://bit.ly/2sy4z7f)       |YES          |
|["significant terms"](http://bit.ly/1KnhT1r) |YES          |
|["stats"](http://bit.ly/2sn1t74)             |YES          |
|["terms"](http://bit.ly/2mJyQ0C)             |YES          |
|terms - cardinality                          |YES          |
|terms - date_histogram                       |YES          |
|terms - date_histogram - cardinality         |YES          |
|terms - date_histogram - extended_stats      |YES          |
|terms - date_histogram - histogram           |YES          |
|terms - date_histogram - percentiles         |YES          |
|terms - date_histogram - significant_terms   |YES          |
|terms - date_histogram - stats               |YES          |
|terms - date_histogram - terms               |YES          |
|terms - extended_stats                       |YES          |
|terms - histogram                            |YES          |
|terms - percentiles                          |YES          |
|terms - significant_terms                    |YES          |
|terms - stats                                |YES          |
|terms - terms                                |YES          |
|["stats"](http://bit.ly/2sn1t74)             |YES          |

## Next Steps <a name="nextsteps"></a>

This is a fairly new project and, as the version number indicates, should be regarded as a work in progress.

### Auth Support <a name="authsupport"></a>

`uptasticsearch` does not currently support queries with authentication. This will be added in future versions.
