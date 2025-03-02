# uptasticsearch 1.0.0

## Breaking Changes

### Removed support for Elasticsearch 1.0.3

- [#224](https://github.com/uptake/uptasticsearch/pull/224) The oldest support version is now 1.7.6.

## Features

### Added support for Elasticsearch 7 and 8

- [#204](https://github.com/uptake/uptasticsearch/pull/204), [#209](https://github.com/uptake/uptasticsearch/pull/209), [#213](https://github.com/uptake/uptasticsearch/pull/213), [#220](https://github.com/uptake/uptasticsearch/pull/220), [#245](https://github.com/uptake/uptasticsearch/pull/245) Added support for Elasticsearch 7.3.2 through 8.17.2. Later versions will hopefully still work, "support" here just means "validation via testing".

### Added retry logic for all HTTP requests

- [#172](https://github.com/uptake/uptasticsearch/pull/172) Changed all code in the R package to retry failed HTTP requests. This should make `{uptasticsearch}` more resilient to transient network issues.

### Reduced set of required dependencies

- [#249](https://github.com/uptake/uptasticsearch/pull/249) Dropped `{httr}` from `Imports` dependencies, replaced it with `{curl}`. Note that `{curl}` was already a hard runtime dependency of `{httr}`, so this is a net reduction in the set of dependencies required to install `{uptasticsearch}`.
- [#243](https://github.com/uptake/uptasticsearch/pull/243) Dropped `{assertthat}` from `Imports` dependencies.
- [#240](https://github.com/uptake/uptasticsearch/pull/240) Dropped `{uuid}` from `Imports` dependencies.
- [#236](https://github.com/uptake/uptasticsearch/pull/236) Switched vignettes from `{rmarkdown}` to `{markdown}`.
- [#235](https://github.com/uptake/uptasticsearch/pull/235) Removed `{covr}` from `Suggests` dependencies.
- [#211](https://github.com/uptake/uptasticsearch/pull/211) Removed `{devtools}` from development workflows, in favor of the underlying libraries its entrypoints called. `{devtools}` was not listed as a dependency in `DESCRIPTION`, so this only affects building from sources pulled from version control.

### Added compatibility with `{testthat}` 3.x

- [#237](https://github.com/uptake/uptasticsearch/pull/237) Removed uses of `testthat::with_mock()`, to avoid compatibility issues with R 4.5.0 and beyond.
- [#232](https://github.com/uptake/uptasticsearch/pull/232) Removed uses of `testthat::context()`, switched to `testthat::SummaryReporter`, some other cleanup.

### Refreshed docs website

- [#244](https://github.com/uptake/uptasticsearch/pull/244), [#246](https://github.com/uptake/uptasticsearch/pull/246) Rebuilt the docs site with the latest version of `{pkgdown}`, `{roxygen2}`, and everything they pull in.


### Added a `conda-forge` package

- [#210](https://github.com/uptake/uptasticsearch/pull/210) It's now possible to install the package with `conda`. See https://github.com/conda-forge/r-uptasticsearch-feedstock for packaging details.

```shell
conda install -c conda-forge r-uptasticsearch
```

## Bugfixes

### Fixed some small `R CMD check` issues.

- [#252](https://github.com/uptake/uptasticsearch/pull/252) Fixed NOTEs about URLs that redirect to other locations.
- [#219](https://github.com/uptake/uptasticsearch/pull/219) Fixed this:

```text
Version: 0.4.0
Check: LazyData
Result: NOTE
     'LazyData' is specified without a 'data' directory
```

### Fixed validation of `es_indices` in `get_fields()`

- [#243](https://github.com/uptake/uptasticsearch/pull/243) The type of argument `es_indices` to `get_fields()` was previously not checked, which could lead to confusing errors. `{uptasticsearch}` now correctly checks it and raises an informative error if it is not a non-empty string.

# uptasticsearch 0.4.0

## Features

### Added support for Elasticsearch 7.x
- [#161](https://github.com/uptake/uptasticsearch/pull/161) Added support for Elasticsearch 7.x. The biggest changes between that major version and 6.x were the removal of `_all` as a way to reference all indices, changing the response format of `hits.total` into an object like `{"hits": {"total": 50}}`, and restricting all indices to have a single type of document. More details can be found at https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-7.0.html.

# uptasticsearch 0.3.1

## Bugfixes

### Minor changes to unit tests to comply with CRAN
- [#136](https://github.com/uptake/uptasticsearch/pull/136) removed calls to `closeAllConnections()` in unit tests because they were superfluous and causing problems on certain operating systems in the CRAN check farm.

### Changed strategy for removing duplicate records
- [#138](https://github.com/uptake/uptasticsearch/pull/138) changed our strategy for deduping records from `unique(outDT)` to `unique(outDT, by = "_id")`. This was prompted by [Rdatatable/data.table#3332](https://github.com/Rdatatable/data.table/issues/3332) (changes in `data.table` 1.12.0), but it's actually faster and safer anyway!

# uptasticsearch 0.3.0

## Features

### Full support for Elasticsearch 6.x
- [#64](https://github.com/uptake/uptasticsearch/pull/64) added support for Elasticsearch 6.x. The biggest change between that major version and v5.x is that as of Elasticsearch 6.x all requests issued to the Elasticsearch HTTP API must pass an explicit `Content-Type` header. Previous versions of Elasticsearch tried to guess the `Content-Type` when none was declared
- [#66](https://github.com/uptake/uptasticsearch/pull/66) completed support for Elasticsearch 6.x. Elasticsearch 6.x changed the supported strategy for issuing scrolling requests. `uptasticsearch` will now hit the cluster to try to figure out which version of Elasticsearch it is running, then use the appropriate scrolling strategy.

## Bugfixes

### `get_fields()` when your index has no aliases
- previously, `get_fields()` broke on some legacy versions of Elasticsearch where no aliases had been created. The response on the `_cat/aliases` endpoint has changed from major version to major version. [#66](https://github.com/uptake/uptasticsearch/pull/66) fixed this for all major versions of Elasticsearch from 1.0 to 6.2

### `get_fields()` when your index has multiple aliases
- previously, if you had multiple aliases pointing to the same physical index, `get_fields()` would only return one of those. As of [#73](https://github.com/uptake/uptasticsearch/pull/73), mappings for the underlying physical index will now be duplicated once per alias in the table returned by `get_fields()`.

### bad parsing of Elasticsearch major version
- as of [#64](https://github.com/uptake/uptasticsearch/pull/64), `uptasticsearch` attempts to query the Elasticsearch host to figure out what major version of Elasticsearch is running there. Implementation errors in that PR led to versions being parsed incorrectly but silently passing tests. This was fixed in [#66](https://github.com/uptake/uptasticsearch/pull/66). NOTE: this only impacted the dev version of the library on Github.

### `ignore_scroll_restriction` not being respected
- In previous versions of `uptasticsearch`, the value passed to `es_search()` for `ignore_scroll_restriction` was not actually respected. This was possible because an internal function had defaults specified, so we never caught the fact that that value wasn't getting passed through. [#66](https://github.com/uptake/uptasticsearch/pull/66) instituted the practice of not specifying defaults on function arguments in internal functions, so similar bugs won't be able to silently get through testing in the future.

## Deprecations and Removals
- [#69](https://github.com/uptake/uptasticsearch/pull/69) added a deprecation warning on `get_counts()`. This function was outside the core mission of the package and exposed us unnecessarily to changes in the Elasticsearch DSL

# uptasticsearch 0.2.0

## Features

### Faster `unpack_nested_data()`
- [#51](https://github.com/uptake/uptasticsearch/pull/51) changed the parsing strategy for nested data and made it 9x faster than the previous implementation

### Retry logic
- Functions that make HTTP calls will now use retry logic via `httr::RETRY` instead of one-shot `POST` or `GET` calls

# uptasticsearch 0.1.0

## Features

### Elasticsearch metadata
- `get_fields()` returns a data.table with the names and types of all indexed fields across one or more indices

### Routing Temporary File Writing
- `es_search()` now accepts an `intermediates_dir` parameter, giving users control over the directory used for temporary I/O at query time

## Bugfixes

### Empty Results
- Added logic to short-circuit and return early with an informative message if a query matches 0 documents

# uptasticsearch 0.0.2

## Features

### Main function
- `es_search()` executes an Elasticsearch query and gets a data.table

### Parse raw JSON into data.table
- `chomp_aggs()` converts a raw aggs JSON to data.table
- `chomp_hits()` converts a raw hits JSON to data.table

### Utilities
- `unpack_nested_data()` deals with nested Elasticsearch data not in a tabular format
- `parse_date_time()` parses date-times from Elasticsearch records

### Exploratory functions
- `get_counts()` examines the distribution of distinct values for a field in Elasticsearch
