
# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())) {
    origLogThreshold <- loggerOptions[[1]][["threshold"]]
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

# Should reject NULL index
test_that("es_search should reject NULL index", {
    expect_error({
        es_search(
            es_host = "http://mycompany.com:9200"
            , es_index = NULL
        )
    }, regexp = "You passed NULL to es_index")
})

# Should reject bad queries
test_that("es_search should reject malformed queries", {
    # Length greater than 1
    expect_error({
        es_search(
            es_host = "http://mycompany.com:9200"
            , es_index = "_all"
            , query = c(
                    '{"_source": {"include": ["stuff.*"]},'
                    , '{"aggs": {"superman": {"terms": {"field": "hi"}}}}}'
                )
        )
    }, regexp = "You gave an object of length 2")

    # Specified as a list (like you might get from jsonlite::fromJSON)
    expect_error({
        es_search(
            es_host = "http://mycompany.com:9200"
            , es_index = "_all"
            , query = list(
                '{"_source": {"include": ["stuff.*"]},{"aggs": {"superman": {"terms": {"field": "hi"}}}}}'
            )
        )
    }, regexp = "query_body should be a single string")
})

#---- .ConvertToSec

# .ConvertToSec should work for seconds
test_that(".ConvertToSec should work for seconds",
          expect_identical(60, uptasticsearch:::.ConvertToSec("60s")))

# .ConverToSec should work for minutes
test_that(".ConvertToSec should work for minutes",
          expect_identical(600, uptasticsearch:::.ConvertToSec("10m")))

# .ConvertToSec should work for hours
test_that(".ConvertToSec should work for hours",
          expect_identical(72000, uptasticsearch:::.ConvertToSec("20h")))

# .ConvertToSec should work for days
test_that(".ConvertToSec should work for days",
          expect_identical(172800, uptasticsearch:::.ConvertToSec("2d")))

# .ConvertToSec should work for weeks
test_that(".ConvertToSec should work for weeks",
          expect_identical(3024000, uptasticsearch:::.ConvertToSec("5w")))

# .ConvertToSec should break on unsupported timeStrings
test_that(".ConvertToSec should work for seconds",
          expect_error(uptasticsearch:::.ConvertToSec("50Y")
                       , regexp = "Could not figure out units of datemath"))

#---- ValidateAndFormatHost

# .ValidateAndFormatHost should break if you give it a non-character input
test_that(".ValidateAndFormatHost should break if you give it a non-character input",
          expect_error(uptasticsearch:::.ValidateAndFormatHost(9200)
                       , regexp = "es_host should be a string"))

# .ValidateAndFormatHost should break if you give it a multi-element vector
test_that(".ValidateAndFormatHost should break if you give it a multi-element vector",
          expect_error(uptasticsearch:::.ValidateAndFormatHost(c("http://", "mydb.mycompany.com:9200"))
                       , regexp = "es_host should be length 1"))

# .ValidateAndFormatHost should warn you and drop trailing slashes if you have them
test_that(".ValidateAndFormatHost should handle trailing slashes", {
              # single slash
              newHost <- uptasticsearch:::.ValidateAndFormatHost("http://mydb.mycompany.com:9200/")
              expect_identical(newHost, "http://mydb.mycompany.com:9200")

              # objectively ridiculous number of slashes
              newHost2 <- uptasticsearch:::.ValidateAndFormatHost("http://mydb.mycompany.com:9200/////////")
              expect_identical(newHost2, "http://mydb.mycompany.com:9200")
})

# .ValidateAndFormatHost should break if you don't have a port
test_that(".ValidateAndFormatHost should break if you don't have a port",
          expect_error(uptasticsearch:::.ValidateAndFormatHost("http://mydb.mycompany.com")
                       , regexp = "No port found in es_host"))

# .ValidateAndFormatHost should warn if you don't have a valid transfer protocol
test_that(".ValidateAndFormatHost should warn and use http if you don't give a port", {
    # single slash
    expect_warning({
        hostWithTransfer <- uptasticsearch:::.ValidateAndFormatHost("mydb.mycompany.com:9200")
    }, regexp = "You did not provide a transfer protocol")
    expect_identical(hostWithTransfer, "http://mydb.mycompany.com:9200")
})

#---- .major_version
test_that(".major_version should correctly parse semver version strings", {

    # yay random tests
    for (i in 1:50) {
        v1 <- as.character(sample(0:9, size = 1))
        v2 <- as.character(sample(0:9, size = 1))
        v3 <- as.character(sample(0:9, size = 1))
        test_version <- paste0(v1, ".", v2, ".", v3)
        expect_identical(
            uptasticsearch:::.major_version(test_version)
            , v1
            , info = paste0("version that broke this: ", test_version)
        )
    }
})

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
