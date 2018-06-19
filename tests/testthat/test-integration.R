context("Elasticsearch integration tests")

# tests in this file are run automatically on Travis and require
# an actual Elasticsearch cluster to be up and running. For details,
# see: https://github.com/UptakeOpenSource/uptasticsearch/blob/master/.travis.yml

# Sample data from:
# - https://www.elastic.co/guide/en/kibana/current/tutorial-load-dataset.html

# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

#--- es_search

    # search request
    test_that("es_search works as expected for a simple search request", {
        testthat::skip_on_cran()
        
        outDT <- es_search(
            es_host = "http://127.0.0.1:9200"
            , es_index = "shakespeare"
            , max_hits = 100
            , size = 100
        )

       expect_true(data.table::is.data.table(outDT))
    })
    
    test_that("es_search works when you have to scroll", {
        testthat::skip_on_cran()
        
        outDT <- es_search(
            es_host = "http://127.0.0.1:9200"
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
            es_host = "http://127.0.0.1:9200"
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
                es_host = "http://127.0.0.1:9200"
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
                es_host = "http://127.0.0.1:9200"
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
                es_host = "http://127.0.0.1:9200"
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
                es_host = "http://127.0.0.1:9200"
                , es_index = "empty_index"
            )
        }, regexp = "Query is syntactically valid but 0 documents were matched")
        expect_null(outDT)
    })
    
    # aggregation request
    test_that("es_search works as expected for a simple aggregation request", {
        testthat::skip_on_cran()
        
        outDT <- es_search(
            es_host = "http://127.0.0.1:9200"
            , es_index = "shakespeare"
            , max_hits = 100
            , query = '{"aggs": {"thing": {"terms": {"field": "speaker", "size": 12}}}}'
        )
        
        expect_true(data.table::is.data.table(outDT))
        expect_true(nrow(outDT) == 4)
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
            es_host = "http://127.0.0.1:9200"
            , es_index = "shakespeare"
            , max_hits = 100
            , query = '{"aggs": {"name_i_picked": {"terms": {"field": "speaker", "size": 12}}}}'
        )
        
        # main test
        expect_named(
            outDT
            , c("name_i_picked", "doc_count")
            , ignore.case = FALSE
            , ignore.order = TRUE
        )
        
        # ther stuff we might as well test
        expect_true(data.table::is.data.table(outDT))
        expect_true(is.numeric(outDT[, doc_count]))
        expect_true(is.character(outDT[, name_i_picked]))
        expect_true(all(outDT[, doc_count > 0]))
    })
    
    # We have tests on static empty results, but this test will catch
    # changes across versions in the way ES actually responds to aggs results that
    # return nothing
    test_that("es_search correctly handles empty bucketed aggregation result", {
        testthat::skip_on_cran()

        outDT <- es_search(
            es_host = "http://127.0.0.1:9200"
            , es_index = "shakespeare"
            , max_hits = 100
            , query = '{"aggs": {"blegh": {"terms": {"field": "nonsense_field"}}}}'
        ) 
        expect_null(outDT)
    })

#--- .get_es_version
    
    test_that(".get_es_version works", {
        testthat::skip_on_cran()
        
        ver <- uptasticsearch:::.get_es_version(es_host = "http://127.0.0.1:9200")
        
        # is a string
        expect_true(assertthat::is.string(ver), info = paste0("returned version: ", ver))
        
        # Decided to check that it's coercible to an integer instead of
        # hard-coding known ES versions so this test won't require
        # attention or break builds if/when ES7 or whatever the next major verison
        # is comes out
        expect_true(!is.na(as.integer(ver)), info = paste0("returned version: ", ver))
    })
    
#--- get_fields and .get_aliases
    
    # set up helper function for manipulating aliases. Valid actions below are
    # "add" and "remove"
    .alias_action <- function(action, alias_name){
        res <- httr::POST(
            url = "http://127.0.0.1:9200/_aliases"
            , httr::add_headers(c('Content-Type' = 'application/json'))
            , body = sprintf(
                '{"actions": [{"%s": {"index": "shakespeare", "alias": "%s"}}]}'
                , action
                , alias_name
            )
        )
        httr::stop_for_status(res)
        return(invisible(NULL))
    }
    
    test_that(".get_aliases returns NULL when no aliases have been created in the cluster", {
        testthat::skip_on_cran()
        
        result <- .get_aliases(
            es_host = "http://127.0.0.1:9200"
        )
        expect_null(result)
    })
    
    test_that("get_fields works on an actual running ES cluster with no aliases", {
        testthat::skip_on_cran()
        
        fieldDT <- get_fields(
            es_host = "http://127.0.0.1:9200"
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
        expect_true(sum(is.na(fieldDT)) == 0)
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
            es_host = "http://127.0.0.1:9200"
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
        expect_true(sum(is.na(fieldDT)) == 0)
        
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
        .alias_action('add', 'the_test_alias')
        .alias_action('add', 'the_best_alias')
        .alias_action('add', 'the_nest_alias')
    
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
        fieldDT <- get_fields(
            es_host = "http://127.0.0.1:9200"
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
        expect_true(sum(is.na(fieldDT)) == 0)
        
        # get_fields should replace index names with their aliases
        expect_true(fieldDT[, all(c("the_best_alias", "the_nest_alias", "the_test_alias") %in% index)])
        expect_true(
            fieldDT[, sum(index == "shakespeare")] == 0
            , info = "get_fields didn't replace index names with their aliases"
        )
        
        # since we aliased the same index three times, the subsections should all be identical
        expect_true(identical(
            fieldDT[index == 'the_best_alias', .(type, field, data_type)]
            , fieldDT[index == 'the_nest_alias', .(type, field, data_type)]
        ))
        expect_true(identical(
            fieldDT[index == 'the_best_alias', .(type, field, data_type)]
            , fieldDT[index == 'the_test_alias', .(type, field, data_type)]
        ))
        
        # get_fields should work targeting a specific index with aliases
        fieldDT <- get_fields(
            es_host = "http://127.0.0.1:9200"
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
        expect_true(sum(is.na(fieldDT)) == 0)
        
        # get_fields should replace index names with their aliases
        expect_true(fieldDT[, all(c("the_best_alias", "the_nest_alias", "the_test_alias") %in% index)])
        expect_true(
            fieldDT[, sum(index == "shakespeare")] == 0
            , info = "get_fields didn't replace index names with their aliases"
        )
        
        # since we aliased the same index three times, the subsections should all be identical
        expect_true(identical(
            fieldDT[index == 'the_best_alias', .(type, field, data_type)]
            , fieldDT[index == 'the_nest_alias', .(type, field, data_type)]
        ))
        expect_true(identical(
            fieldDT[index == 'the_best_alias', .(type, field, data_type)]
            , fieldDT[index == 'the_test_alias', .(type, field, data_type)]
        ))
        
        # delete the aliases we created (to keep tests self-contained)
        .alias_action('remove', 'the_test_alias')
        .alias_action('remove', 'the_best_alias')
        .alias_action('remove', 'the_nest_alias')
        
        # confirm that they're gone
        resultDT <- .get_aliases("http://127.0.0.1:9200")
        expect_null(resultDT)
    })
    
    test_that("get_fields works when you target a single index with no aliases", {
        
        testthat::skip_on_cran()
        
        fieldDT <- get_fields(
            es_host = "http://127.0.0.1:9200"
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
        expect_true(sum(is.na(fieldDT)) == 0)
        
        # should only give us back records on the one index we requested
        expect_true(fieldDT[, all(index == "empty_index")])
    })
    
    
    test_that("get_fields works when you pass a vector of index names", {
        
        testthat::skip_on_cran()
        
        fieldDT <- get_fields(
            es_host = "http://127.0.0.1:9200"
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
        expect_true(sum(is.na(fieldDT)) == 0)
        
        # should only give us back records on indexes we requested
        expect_true(fieldDT[, any(index == "empty_index")])
        expect_true(fieldDT[, length(unique(index))] >= 2)
    })

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
