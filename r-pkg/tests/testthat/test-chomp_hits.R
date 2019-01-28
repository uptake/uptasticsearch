
# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

context("chomp_hits")

# This is effectively a test of running elastic::Search(raw = TRUE) and passing it through chomp_hits()
test_that("chomp_hits should work from a one-element character vector",
          {jsonString <- '{"took": 54, "timed_out": false, "_shards": {"total": 16,"successful": 16, "failed": 0},
          "hits": {
          "total": 46872,
          "max_score": 0.882234,
          "hits": [
          {"_index": "redsawx", "_type": "ballplayer", "_id": "abc123", "_score": 0.882234,
          "_source": {"name": "David Ortiz", "stats" : {"yrs_played": 20, "final_season": {"avg": 0.315, "HR": 38, "R": 79},
          "full_career": {"avg": 0.286, "HR": 541, "R": 1419}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "def567", "_score": 0.882234,
          "_source": {"name": "Kevin Youkilis", "stats" : {"yrs_played": 10, "final_season": {"avg": 0.219, "HR": 2, "R": 12},
          "full_career": {"avg": 0.281, "HR": 150, "R": 653}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "abc567", "_score": 0.882234,
          "_source": {"name": "Trot Nixon", "stats" : {"yrs_played": 12, "final_season": {"avg": 0.171, "HR": 1, "R": 2},
          "full_career": {"avg": 0.274, "HR": 137, "R": 579}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "def123", "_score": 0.882234,
          "_source": {"name": "Manny Ramirez", "stats" : {"yrs_played": 19, "final_season": {"avg": 0.059, "HR": 0, "R": 0},
          "full_career": {"avg": 0.312, "HR": 555, "R": 1544}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "ghi890", "_score": 0.882234,
          "_source": {"name": "Jason Varitek",  "stats" : {"yrs_played": 15, "final_season": {"avg": 0.221, "HR": 11, "R": 32},
          "full_career": {"avg": 0.256, "HR": "193", "R": 664}}}}
          ]}}'
          chompDT <- chomp_hits(hits_json = jsonString)
          expect_true("data.table" %in% class(chompDT))
          expect_equivalent(dim(chompDT), c(5, 12))
          expect_true(all(c("_id", "_index", "_score", "name", "stats.final_season.avg",
                            "stats.final_season.HR", "stats.final_season.R", "stats.full_career.avg",
                            "stats.full_career.HR", "stats.full_career.R", "stats.yrs_played", "_type") %in%
                              names(chompDT)))
          expect_identical(chompDT$stats.full_career.R, as.integer(c(1419, 653, 579, 1544, 664)))
          expect_identical(chompDT$stats.full_career.HR, as.character(c(541, 150, 137, 555, 193)))}
)

# What if we're passing the hits array, not the entire result?
test_that("chomp_hits should work with just the hits array",
          {jsonString <- '[
          {"_index": "redsawx", "_type": "ballplayer", "_id": "abc123", "_score": 0.882234,
          "_source": {"name": "David Ortiz", "stats" : {"yrs_played": 20, "final_season": {"avg": 0.315, "HR": 38, "R": 79},
          "full_career": {"avg": 0.286, "HR": 541, "R": 1419}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "def567", "_score": 0.882234,
          "_source": {"name": "Kevin Youkilis", "stats" : {"yrs_played": 10, "final_season": {"avg": 0.219, "HR": 2, "R": 12},
          "full_career": {"avg": 0.281, "HR": 150, "R": 653}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "abc567", "_score": 0.882234,
          "_source": {"name": "Trot Nixon", "stats" : {"yrs_played": 12, "final_season": {"avg": 0.171, "HR": 1, "R": 2},
          "full_career": {"avg": 0.274, "HR": 137, "R": 579}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "def123", "_score": 0.882234,
          "_source": {"name": "Manny Ramirez", "stats" : {"yrs_played": 19, "final_season": {"avg": 0.059, "HR": 0, "R": 0},
          "full_career": {"avg": 0.312, "HR": 555, "R": 1544}}}},
          {"_index": "redsawx", "_type": "ballplayer", "_id": "ghi890", "_score": 0.882234,
          "_source": {"name": "Jason Varitek",  "stats" : {"yrs_played": 15, "final_season": {"avg": 0.221, "HR": 11, "R": 32},
          "full_career": {"avg": 0.256, "HR": "193", "R": 664}}}}
          ]'
          chompDT <- chomp_hits(hits_json = jsonString)
          expect_true("data.table" %in% class(chompDT))
          expect_equivalent(dim(chompDT), c(5, 12))
          expect_true(all(c("_id", "_index", "_score", "name", "stats.final_season.avg",
                            "stats.final_season.HR", "stats.final_season.R", "stats.full_career.avg",
                            "stats.full_career.HR", "stats.full_career.R", "stats.yrs_played", "_type") %in%
                              names(chompDT)))
          expect_identical(chompDT$stats.full_career.R, as.integer(c(1419, 653, 579, 1544, 664)))
          expect_identical(chompDT$stats.full_career.HR, as.character(c(541, 150, 137, 555, 193)))}
)

# This tests the type of data representation you'd get from reading in a JSON file with readLines
test_that("chomp_hits should work from a multi-element character vector",
          {test_json <- system.file("testdata", "es_hits.json", package = "uptasticsearch")
          jsonVec <- suppressWarnings(readLines(test_json))
          chompDT <- chomp_hits(hits_json = jsonVec)
          expect_true("data.table" %in% class(chompDT))
          expect_equivalent(dim(chompDT), c(5, 12))
          expect_true(all(c("_id", "_index", "_score", "name", "stats.final_season.avg",
                            "stats.final_season.HR", "stats.final_season.R", "stats.full_career.avg",
                            "stats.full_career.HR", "stats.full_career.R", "stats.yrs_played", "_type") %in%
                              names(chompDT)))
          expect_identical(chompDT$stats.full_career.R, as.integer(c(1419, 653, 579, 1544, 664)))
          expect_identical(chompDT$stats.full_career.HR, as.character(c(541, 150, 137, 555, 193)))}
)

# In case you need to have a non-R, non-Python run queries for you and store them in a file 
test_that("chomp_hits should work from a file",
          {test_json <- system.file("testdata", "es_hits.json", package = "uptasticsearch")
          chompDT <- chomp_hits(hits_json = test_json)
          expect_true("data.table" %in% class(chompDT))
          expect_equivalent(dim(chompDT), c(5, 12))
          expect_true(all(c("_id", "_index", "_score", "name", "stats.final_season.avg",
                            "stats.final_season.HR", "stats.final_season.R", "stats.full_career.avg",
                            "stats.full_career.HR", "stats.full_career.R", "stats.yrs_played", "_type") %in%
                              names(chompDT)))
          expect_identical(chompDT$stats.full_career.R, as.integer(c(1419, 653, 579, 1544, 664)))
          expect_identical(chompDT$stats.full_career.HR, as.character(c(541, 150, 137, 555, 193)))}
)

# Should warn and return null if you don't provide any data
test_that("chomp_hits should return NULL if you do not provide data",
          {result <- suppressWarnings(chomp_hits(hits_json = NULL))
          expect_true(is.null(result))
          expect_warning(chomp_hits(hits_json = NULL),
                         regexp = "You did not pass any input data to chomp_hits")}
)

# Should break if you pass the wrong kind of input
test_that("chomp_hits should break if you pass the wrong input",
          {expect_error(chomp_hits(hits_json = data.frame(a = 1:5)),
                        regexp = "The first argument of chomp_hits must be a character vector")}
)

# Should warn if the resulting data is nested with default keep_nested_data_cols = FALSE
test_that("chomp_hits should warn and delete if the resulting data is nested with keep_nested_data_cols = FALSE",
          {expect_warning({chomped <- chomp_hits(hits_json = '[{"test1":[{"a":1}],"test2":2}]'
                                                 , keep_nested_data_cols = FALSE)},
                          regexp = "Deleting the following nested data columns:")
              expect_equal(names(chomped), "test2")}
)

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
