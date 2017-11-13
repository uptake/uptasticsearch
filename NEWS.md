# uptasticsearch 0.1.0

## Features

### Elasticsearch metadata
- `get_fields` returns a data.table with the names and types of all indexed fields across one or more indices

### Routing Temporary File Writing
- `es_search` now accepts an `intermediates_dir` parameter, giving users control over the directory used for temporary I/O at query time

## Bugfixes

### Empty Results
- Added logic to short-circuit and return early with an informative message if a query matches 0 documents

# uptasticsearch 0.0.2

## Features

### Main function
- `es_search` executes an ES query and gets a data.table

### Parse raw JSON into data.table
- `chomp_aggs` converts a raw aggs JSON to data.table
- `chomp_hits` converts a raw hits JSON to data.table

### Utilities
- `unpack_nested_data` deals with nested Elasticsearch data not in a tabular format
- `parse_date_time` parses date-times from Elasticsearch records

### Exploratory functions
- `get_counts` examines the distribution of distinct values for a field in Elasticsearch
