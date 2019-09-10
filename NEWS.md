# uptasticsearch development version

# uptasticsearch 0.4.0

## Features

### Added support for ES7.x
- [#161](https://github.com/uptake/uptasticsearch/pull/161) Added support for ES7.x. The biggest changes between that major version and 6.x were the removal of `_all` as a way to reference all indices, changing the response format of `hits.total` into an object like `{"hits": {"total": 50}}`, and restricting all indices to have a single type of document. More details can be found at https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-7.0.html.

# uptasticsearch 0.3.1

## Bugfixes

### Minor changes to unit tests to comply with CRAN
- [#136](https://github.com/uptake/uptasticsearch/pull/136) removed calls to `closeAllConnections()` in unit tests because they were superfluous and causing problems on certain operating systems in the CRAN check farm.

### Changed strategy for removing duplicate records
- [#138](https://github.com/uptake/uptasticsearch/pull/138) changed our strategy for deduping records from `unique(outDT)` to `unique(outDT, by = "_id")`. This was prompted by [Rdatatable/data.table#3332](https://github.com/Rdatatable/data.table/issues/3332) (changes in `data.table` 1.12.0), but it's actually faster and safer anyway!

# uptasticsearch 0.3.0

## Features

### Full support for ES6.x
- [#64](https://github.com/uptake/uptasticsearch/pull/64) added support for ES6.x. The biggest change between that major version and v5.x is that as of ES6.x all requests issued to the ES HTTP API must pass an explicit `Content-Type` header. Previous versions of ES tried to guess the `Content-Type` when none was declared
- [#66](https://github.com/uptake/uptasticsearch/pull/66) completed support for ES6.x. ES6.x changed the supported strategy for issuing scrolling requests. `uptasticsearch` will now hit the cluster to try to figure out which version of ES it is running, then use the appropriate scrolling strategy.

## Bugfixes

### `get_fields` when your index has no aliases
- previously, `get_fields` broke on some legacy versions of Elasticsearch where no aliases had been created. The response on the `_cat/aliases` endpoint has changed from major version to major version. [#66](https://github.com/uptake/uptasticsearch/pull/66) fixed this for all major versions of ES from 1.0 to 6.2

### `get_fields` when your index has multiple aliases
- previously, if you had multiple aliases pointing to the same physical index, `get_fields` would only return one of those. As of [#73](https://github.com/uptake/uptasticsearch/pull/73), mappings for the underlying physical index will now be duplicated once per alias in the table returned by `get_fields`.

### bad parsing of ES major version
- as of [#64](https://github.com/uptake/uptasticsearch/pull/64), `uptasticsearch` attempts to query the ES host to figure out what major version of Elasticsearch is running there. Implementation errors in that PR led to versions being parsed incorrectly but silently passing tests. This was fixed in [#66](https://github.com/uptake/uptasticsearch/pull/66). NOTE: this only impacted the dev version of the library on Github.

### `ignore_scroll_restriction` not being respected
- In previous versions of `uptasticsearch`, the value passed to `es_search` for `ignore_scroll_restriction` was not actually respected. This was possible because an internal function had defaults specified, so we never caught the fact that that value wasn't getting passed through. [#66](https://github.com/uptake/uptasticsearch/pull/66) instituted the practice of not specifying defaults on function arguments in internal functions, so similar bugs won't be able to silently get through testing in the future.

## Deprecations and Removals
- [#69](https://github.com/uptake/uptasticsearch/pull/69) added a deprecation warning on `get_counts`. This function was outside the core mission of the package and exposed us unnecessarily to changes in the Elasticsearch DSL

# uptasticsearch 0.2.0

## Features

### Faster `unpack_nested_data`
- [#51](https://github.com/uptake/uptasticsearch/pull/51) changed the parsing strategy for nested data and made it 9x faster than the previous implementation

### Retry logic
- Functions that make HTTP calls will now use retry logic via `httr::RETRY` instead of one-shot `POST` or `GET` calls

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
