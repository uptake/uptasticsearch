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

#--- 1. es_search

    # Works as expected
    test_that("es_search works as expected for a simple request",
              {testthat::skip_on_cran()
                
               outDT <- es_search(es_host = "http://127.0.0.1:9200"
                                  , es_index = "shakespeare"
                                  , max_hits = 100)

               expect_true("data.table" %in% class(outDT))
               expect_true(nrow(outDT) == 100)
              }
             )

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
