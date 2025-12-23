# tests in this file are run automatically in CI and require
# an actual Elasticsearch cluster to be up and running. For details,
# see: https://github.com/uptake/uptasticsearch/blob/main/.github/workflows/ci.yml

# Sample data from:
# - https://www.elastic.co/guide/en/kibana/current/tutorial-load-dataset.html

ES_HOST <- "http://127.0.0.1:9200"

#--- es_search

    # search request
    test_that("es_search works as expected for a simple search request", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = ES_HOST
            , es_index = "shakespeare"
            , max_hits = 100
            , size = 100
        )

       expect_true(data.table::is.data.table(outDT))
    })

    test_that("es_search works when you have to scroll", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = ES_HOST
            , es_index = "shakespeare"
            , max_hits = 30
            , size = 2
        )
        expect_true(data.table::is.data.table(outDT))
        expect_true(nrow(outDT) == 30)
    })

    test_that("es_search works in single-threaded mode", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = ES_HOST
            , es_index = "shakespeare"
            , max_hits = 30
            , size = 2
            , n_cores = 1
        )
        expect_true(data.table::is.data.table(outDT))
        expect_true(nrow(outDT) == 30)
    })

    test_that("es_search rejects scrolls longer than 1 hour", {
        testthat::skip_on_cran()

        expect_error({
            outDT <- es_search(
                es_host = ES_HOST
                , es_index = "shakespeare"
                , max_hits = 100
                , size = 100
                , scroll = "2h"
            )
        }, regexp = "By default, this function does not permit scroll requests which keep the scroll")

    })

    test_that("es_search warns and readjusts size if max_hits less than 10000", {
        testthat::skip_on_cran()

        expect_warning({
            outDT <- es_search(
                es_host = ES_HOST
                , es_index = "shakespeare"
                , max_hits = 9999
            )
        }, regexp = "You requested a maximum of 9999 hits and a page size of 10000")
        expect_true(data.table::is.data.table(outDT))

    })

    test_that("es_search warns when max hits is not a clean multiple of size", {
        testthat::skip_on_cran()

        expect_warning({
            outDT <- es_search(
                es_host = ES_HOST
                , es_index = "shakespeare"
                , max_hits = 12
                , size = 7
            )
        }, regexp = "When max_hits is not an exact multiple of size, it is possible to get a few more than max_hits results back")
        expect_true(data.table::is.data.table(outDT))
    })

    test_that("es_search works as expected for search requests that return nothing", {
        testthat::skip_on_cran()

        # NOTE: Creating an intentionally empty index is the safest way to test
        #       this functionality. Any other test would involve writing a query
        #       and I want to avoid exposing our tests to changes in the query DSL
        expect_warning({
            outDT <- es_search(
                es_host = ES_HOST
                , es_index = "empty_index"
            )
        }, regexp = "Query is syntactically valid but 0 documents were matched")
        expect_null(outDT)
    })

    # aggregation request
    test_that("es_search works as expected for a simple aggregation request", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = ES_HOST
            , es_index = "shakespeare"
            , max_hits = 100
            , query = '{"aggs": {"thing": {"terms": {"field": "speaker", "size": 12}}}}'  # nolint[quotes]
        )

        expect_true(data.table::is.data.table(outDT))
        num_expected_levels <- 4
        major_version <- .major_version(
            .get_es_version("http://127.0.0.1:9200")
        )
        if (as.integer(major_version) >= 7) {
            num_expected_levels <- 3
        }
        expect_true(nrow(outDT) == num_expected_levels)
        expect_named(
            outDT
            , c("thing", "doc_count")
            , ignore.case = FALSE
            , ignore.order = TRUE
        )
        expect_true(is.numeric(outDT[, doc_count]))
        expect_true(is.character(outDT[, thing]))
        expect_true(all(outDT[, doc_count > 0]))
    })

    test_that("es_search respects the names you assign to aggregation results", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = ES_HOST
            , es_index = "shakespeare"
            , max_hits = 100
            , query = '{"aggs": {"name_i_picked": {"terms": {"field": "speaker", "size": 12}}}}'  # nolint[quotes]
        )

        # main test
        expect_named(
            outDT
            , c("name_i_picked", "doc_count")
            , ignore.case = FALSE
            , ignore.order = TRUE
        )

        # the stuff we might as well test
        expect_true(data.table::is.data.table(outDT))
        expect_true(is.numeric(outDT[, doc_count]))
        expect_true(is.character(outDT[, name_i_picked]))
        expect_true(all(outDT[, doc_count > 0]))
    })

    # We have tests on static empty results, but this test will catch
    # changes across versions in the way Elasticsearch actually responds to aggs results that
    # return nothing
    test_that("es_search correctly handles empty bucketed aggregation result", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = ES_HOST
            , es_index = "shakespeare"
            , max_hits = 100
            , query = '{"aggs": {"blegh": {"terms": {"field": "nonsense_field"}}}}'  # nolint[quotes]
        )
        expect_null(outDT)
    })

#--- .get_es_version

    test_that(".get_es_version works", {
        testthat::skip_on_cran()

        ver <- uptasticsearch:::.get_es_version(es_host = ES_HOST)

        # is a string
        expect_true(.is_string(ver), info = paste0("returned version: ", ver))

        # Decided to check that it's coercible to an integer instead of
        # hard-coding known Elasticsearch versions so this test won't require
        # attention or break builds if/when Elasticsearch 7 or whatever the next major version
        # is comes out
        expect_true(!is.na(as.integer(ver)), info = paste0("returned version: ", ver))
    })

#--- get_fields and .get_aliases

    # set up helper function for manipulating aliases. Valid actions below are
    # "add" and "remove"
    .alias_action <- function(action, alias_name) {
        res <- .request(
            verb = "POST"
            , url = "http://127.0.0.1:9200/_aliases"
            , body = sprintf(
                '{"actions": [{"%s": {"index": "shakespeare", "alias": "%s"}}]}'  # nolint[quotes]
                , action
                , alias_name
            )
            , verbose = FALSE
        )
        .stop_for_status(res)
        return(invisible(NULL))
    }

    test_that(".get_aliases returns NULL when no aliases have been created in the cluster", {
        testthat::skip_on_cran()

        result <- .get_aliases(
            es_host = ES_HOST
        )
        expect_null(result)
    })

    test_that("get_fields works on an actual running Elasticsearch cluster with no aliases", {
        testthat::skip_on_cran()

        fieldDT <- get_fields(
            es_host = ES_HOST
            , es_indices = "_all"
        )
        expect_true(data.table::is.data.table(fieldDT))
        expect_true(nrow(fieldDT) > 0)
        expect_named(
            fieldDT
            , c("index", "type", "field", "data_type")
            , ignore.order = TRUE
            , ignore.case = FALSE
        )
        expect_true("shakespeare" %in% fieldDT[, unique(index)])
        expect_true(is.character(fieldDT$index))
        expect_true(is.character(fieldDT$type))
        expect_true(is.character(fieldDT$field))
        expect_true(is.character(fieldDT$data_type))
        expect_false(anyNA(fieldDT[, .(index, field, data_type)]))
    })

    test_that(".get_aliases and get_fields work as expected when exactly one alias exists for one index in the cluster", {

        testthat::skip_on_cran()

        # create an alias
        .alias_action("add", "the_test_alias")

        # get_aliases should work
        resultDT <- .get_aliases("http://127.0.0.1:9200")
        expect_true(data.table::is.data.table(resultDT))
        expect_true(nrow(resultDT) == 1)
        expect_named(
            resultDT
            , c("alias", "index")
            , ignore.case = FALSE
            , ignore.order = TRUE
        )
        expect_identical(resultDT[, index], "shakespeare")
        expect_identical(resultDT[, alias], "the_test_alias")

        # get_fields should work
        fieldDT <- get_fields(
            es_host = ES_HOST
            , es_indices = "_all"
        )

        expect_true(data.table::is.data.table(fieldDT))
        expect_true(nrow(fieldDT) > 0)
        expect_named(
            fieldDT
            , c("index", "type", "field", "data_type")
            , ignore.order = TRUE
            , ignore.case = FALSE
        )
        expect_true(is.character(fieldDT$index))
        expect_true(is.character(fieldDT$type))
        expect_true(is.character(fieldDT$field))
        expect_true(is.character(fieldDT$data_type))
        expect_false(anyNA(fieldDT[, .(index, field, data_type)]))

        # get_fields should replace index names with their aliases
        expect_true(fieldDT[, sum(index == "the_test_alias")] > 0)
        expect_true(
            fieldDT[, sum(index == "shakespeare")] == 0
            , info = "get_fields didn't replace index names with their aliases"
        )

        # delete the alias we created (to keep tests self-contained)
        .alias_action("remove", "the_test_alias")

        # confirm that it's gone
        resultDT <- .get_aliases("http://127.0.0.1:9200")
        expect_null(resultDT)
    })

    test_that(".get_aliases and get_fields work as expected when more than one alias exists for one index in the cluster", {

        testthat::skip_on_cran()

        # create an alias
        .alias_action("add", "the_test_alias")
        .alias_action("add", "the_best_alias")
        .alias_action("add", "the_nest_alias")

        # get_aliases should work
        resultDT <- .get_aliases("http://127.0.0.1:9200")
        expect_true(data.table::is.data.table(resultDT))
        expect_true(nrow(resultDT) == 3)
        expect_named(
            resultDT
            , c("alias", "index")
            , ignore.case = FALSE
            , ignore.order = TRUE
        )
        expect_identical(resultDT[, index], rep("shakespeare", 3))
        expect_true(resultDT[, all(c("the_best_alias", "the_nest_alias", "the_test_alias") %in% alias)])

        # get_fields should work for "_all" indices
        # NOTE: this was deprecated in Elasticsearch 6 and removed in
        #       Elasticsearch 7, but we use it here so that old uptasticsearch code
        #       continues to work
        fieldDT <- get_fields(
            es_host = ES_HOST
            , es_indices = "_all"
        )

        expect_true(data.table::is.data.table(fieldDT))
        expect_true(nrow(fieldDT) > 0)
        expect_named(
            fieldDT
            , c("index", "type", "field", "data_type")
            , ignore.order = TRUE
            , ignore.case = FALSE
        )
        expect_true(is.character(fieldDT$index))
        expect_true(is.character(fieldDT$type))
        expect_true(is.character(fieldDT$field))
        expect_true(is.character(fieldDT$data_type))
        expect_false(anyNA(fieldDT[, .(index, field, data_type)]))

        # get_fields should replace index names with their aliases
        expect_true(fieldDT[, all(c("the_best_alias", "the_nest_alias", "the_test_alias") %in% index)])
        expect_true(
            fieldDT[, sum(index == "shakespeare")] == 0
            , info = "get_fields didn't replace index names with their aliases"
        )

        # since we aliased the same index three times, the subsections should all be identical
        expect_true(identical(
            fieldDT[index == "the_best_alias", .(type, field, data_type)]
            , fieldDT[index == "the_nest_alias", .(type, field, data_type)]
        ))
        expect_true(identical(
            fieldDT[index == "the_best_alias", .(type, field, data_type)]
            , fieldDT[index == "the_test_alias", .(type, field, data_type)]
        ))

        # get_fields should work targeting a specific index with aliases
        fieldDT <- get_fields(
            es_host = ES_HOST
            , es_indices = "shakespeare"
        )

        expect_true(data.table::is.data.table(fieldDT))
        expect_true(nrow(fieldDT) > 0)
        expect_named(
            fieldDT
            , c("index", "type", "field", "data_type")
            , ignore.order = TRUE
            , ignore.case = FALSE
        )
        expect_true(is.character(fieldDT$index))
        expect_true(is.character(fieldDT$type))
        expect_true(is.character(fieldDT$field))
        expect_true(is.character(fieldDT$data_type))
        expect_false(anyNA(fieldDT[, .(index, field, data_type)]))

        # get_fields should replace index names with their aliases
        expect_true(fieldDT[, all(c("the_best_alias", "the_nest_alias", "the_test_alias") %in% index)])
        expect_true(
            fieldDT[, sum(index == "shakespeare")] == 0
            , info = "get_fields didn't replace index names with their aliases"
        )

        # since we aliased the same index three times, the subsections should all be identical
        expect_true(identical(
            fieldDT[index == "the_best_alias", .(type, field, data_type)]
            , fieldDT[index == "the_nest_alias", .(type, field, data_type)]
        ))
        expect_true(identical(
            fieldDT[index == "the_best_alias", .(type, field, data_type)]
            , fieldDT[index == "the_test_alias", .(type, field, data_type)]
        ))

        # delete the aliases we created (to keep tests self-contained)
        .alias_action("remove", "the_test_alias")
        .alias_action("remove", "the_best_alias")
        .alias_action("remove", "the_nest_alias")

        # confirm that they're gone
        resultDT <- .get_aliases("http://127.0.0.1:9200")
        expect_null(resultDT)
    })

    test_that("get_fields works when you target a single index with no aliases", {

        testthat::skip_on_cran()

        fieldDT <- get_fields(
            es_host = ES_HOST
            , es_indices = "empty_index"
        )
        expect_true(data.table::is.data.table(fieldDT))
        expect_true(nrow(fieldDT) > 0)
        expect_named(
            fieldDT
            , c("index", "type", "field", "data_type")
            , ignore.order = TRUE
            , ignore.case = FALSE
        )
        expect_true(is.character(fieldDT$index))
        expect_true(is.character(fieldDT$type))
        expect_true(is.character(fieldDT$field))
        expect_true(is.character(fieldDT$data_type))
        expect_false(anyNA(fieldDT[, .(index, field, data_type)]))

        # should only give us back records on the one index we requested
        expect_true(fieldDT[, all(index == "empty_index")])
    })


    test_that("get_fields works when you pass a vector of index names", {

        testthat::skip_on_cran()

        fieldDT <- get_fields(
            es_host = ES_HOST
            , es_indices = c("empty_index", "shakespeare")
        )
        expect_true(data.table::is.data.table(fieldDT))
        expect_true(nrow(fieldDT) > 0)
        expect_named(
            fieldDT
            , c("index", "type", "field", "data_type")
            , ignore.order = TRUE
            , ignore.case = FALSE
        )
        expect_true(is.character(fieldDT$index))
        expect_true(is.character(fieldDT$type))
        expect_true(is.character(fieldDT$field))
        expect_true(is.character(fieldDT$data_type))
        expect_false(anyNA(fieldDT[, .(index, field, data_type)]))

        # should only give us back records on indexes we requested
        expect_true(fieldDT[, any(index == "empty_index")])
        expect_true(fieldDT[, length(unique(index))] >= 2)
    })

#--- HTTP request helpers
test_that(".request() works for requests without a body", {
    testthat::skip_on_cran()
    response <- uptasticsearch:::.request(
        verb = "POST"
        , url = "https://httpbin.org/status/201"
        , body = NULL
        , verbose = FALSE
    )
    expect_true(response$method == "POST")
    expect_true(response$status_code == 201L)
    expect_true(response$url == "https://httpbin.org/status/201")
})

test_that(".request() works for requests with a body", {
    testthat::skip_on_cran()
    response <- uptasticsearch:::.request(
        verb = "POST"
        , url = "https://httpbin.org/anything"
        , body = '{"data": {"cool_numbers": [312, 708, 773]}}'
        , verbose = FALSE
    )
    expect_true(response$method == "POST")
    expect_true(response$status_code == 200L)
    expect_true(response$url == "https://httpbin.org/anything")
    response_content <- jsonlite::fromJSON(rawToChar(response$content))
    expect_true(identical(response_content[["json"]][["data"]][["cool_numbers"]], c(312L, 708L, 773L)))
})

test_that("retry logic works as expected", {
    testthat::skip_on_cran()
    log_lines <- testthat::capture_output({
        response <- .request(
            verb = "GET"
            , url = "https://httpbin.org/status/502"
            , body = NULL
            , verbose = TRUE
        )
    })

    # should log the failures and sleep times
    expect_true(grepl("DEBUG.*Request failed.*status code 502.*Sleeping for", log_lines))

    # should perform retry with backoff
    expect_true(grepl(".*Sleeping for 1\\.[0-9]+ seconds.*Sleeping for 2\\.[0-9]+ seconds", log_lines))

    # should return the response
    expect_true(response$method == "GET")
    expect_true(response$status_code == 502L)
    expect_true(response$url == "https://httpbin.org/status/502")
})

test_that("retry logic works as expected for requests with a body", {
    testthat::skip_on_cran()
    log_lines <- testthat::capture_output({
        response <- .request(
            verb = "POST"
            , url = "https://httpbin.org/status/429"
            , body = '{"some_key": 708}'
            , verbose = TRUE
        )
    })

    # should log the failures and sleep times
    expect_true(grepl("DEBUG.*Request failed.*status code 429.*Sleeping for", log_lines))

    # should perform retry with backoff
    expect_true(grepl(".*Sleeping for 1\\.[0-9]+ seconds.*Sleeping for 2\\.[0-9]+ seconds", log_lines))

    # should return the response
    expect_true(response$method == "POST")
    expect_true(response$status_code == 429L)
    expect_true(response$url == "https://httpbin.org/status/429")
})
