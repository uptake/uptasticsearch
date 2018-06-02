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
    
#--- get_fields
    
    test_that("get_fields works on an actual running ES cluster", {
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

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
