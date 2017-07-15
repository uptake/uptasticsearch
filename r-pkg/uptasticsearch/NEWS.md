# uptasticsearch 0.1.0

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
