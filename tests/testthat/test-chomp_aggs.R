
# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

context("chomp_aggs")

# Works with 1 variable from an R string
test_that("chomp_aggs should work from an R string with one grouping variable",
          {oneVarJSON <- '{"took": 5,
          "timed_out": false,
          "_shards": {"total": 16, "successful": 16, "failed": 0},
          "hits": {"total": 110207,"max_score": 0,"hits": []},
          "aggregations": {
          "some_variable": {
          "doc_count_error_upper_bound": 0,
          "sum_other_doc_count": 0,
          "buckets": [
          {"key": "level1", "doc_count": 62159},
          {"key": "level2", "doc_count": 21576},
          {"key": "level3", "doc_count": 10575}
          ]
          }}}'
                  expect_identical(chomp_aggs(aggs_json = oneVarJSON)
                                   , data.table::data.table(some_variable = c("level1", "level2", "level3")
                                                            , doc_count = c(62159L, 21576L, 10575L)))}
          )

# Works w/ one variable from a file
test_that("chomp_aggs should work from a file with one grouping variable",
          {test_json <- system.file("testdata", "one_var_agg.json", package = "uptasticsearch")
          expect_identical(chomp_aggs(aggs_json = test_json)
                           , data.table::data.table(some_variable = c("level1", "level2", "level3")
                                                    , doc_count = c(62159L, 21576L, 10575L)))}
)

# Works with multiple grouping vars from an R string
test_that("chomp_aggs should work from an R string with multiple grouping variables",
          {oneVarJSON <- '{"took":494,"timed_out":false,"_shards":{"total":16,"successful":16,"failed":0},"hits":{"total":11335918,"max_score":0,"hits":[]},"aggregations":{"a_grouping_var":{"doc_count_error_upper_bound":0,"sum_other_doc_count":526088,"buckets":[{"key":0,"doc_count":3403964,"another_one":{"doc_count_error_upper_bound":23422,"sum_other_doc_count":2941783,"buckets":[{"key":2915,"doc_count":188629,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"lupe_fiasco","doc_count":168098},{"key":"tech_n9ne","doc_count":20531}]}},{"key":3952,"doc_count":146357,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"lupe_fiasco","doc_count":145484},{"key":"tech_n9ne","doc_count":873}]}},{"key":2632,"doc_count":127195,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"lupe_fiasco","doc_count":121318},{"key":"tech_n9ne","doc_count":5877}]}}]}},{"key":2,"doc_count":3360049,"another_one":{"doc_count_error_upper_bound":13449,"sum_other_doc_count":2105828,"buckets":[{"key":2349,"doc_count":542582,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"childish_gambino","doc_count":485820},{"key":"tech_n9ne","doc_count":56762}]}},{"key":2201,"doc_count":505387,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"childish_gambino","doc_count":470503},{"key":"tech_n9ne","doc_count":34884}]}},{"key":2247,"doc_count":206252,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"childish_gambino","doc_count":188375},{"key":"tech_n9ne","doc_count":17877}]}}]}},{"key":1,"doc_count":2600800,"another_one":{"doc_count_error_upper_bound":17346,"sum_other_doc_count":1692470,"buckets":[{"key":2126,"doc_count":433735,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"lupe_fiasco","doc_count":405476},{"key":"tech_n9ne","doc_count":28259}]}},{"key":777,"doc_count":277387,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"lupe_fiasco","doc_count":241894},{"key":"tech_n9ne","doc_count":35493}]}},{"key":663,"doc_count":197208,"yet_another_one":{"doc_count_error_upper_bound":0,"sum_other_doc_count":0,"buckets":[{"key":"lupe_fiasco","doc_count":193540},{"key":"tech_n9ne","doc_count":3668}]}}]}}]}}}'
          xDT <- chomp_aggs(aggs_json = oneVarJSON)
          yDT <- data.table::data.table(a_grouping_var = c(rep(0L, 6), rep(2L, 6), rep(1L, 6))
                                        , another_one = c(2915L, 2915L, 3952L, 3952L, 2632L, 2632L,
                                                          2349L, 2349L, 2201L, 2201L, 2247L, 2247L,
                                                          2126L, 2126L, 777L, 777L, 663L, 663L)
                                        , yet_another_one = c(rep(c("lupe_fiasco", "tech_n9ne"), 3),
                                                              rep(c("childish_gambino", "tech_n9ne"), 3),
                                                              rep(c("lupe_fiasco", "tech_n9ne"), 3))
                                        , doc_count = c(168098L, 20531L, 145484L, 873L, 121318L, 5877L,
                                                        485820L, 56762L, 470503L, 34884L, 188375L, 17877L,
                                                        405476L, 28259L, 241894L, 35493L, 193540L, 3668L))
          expect_identical(xDT, yDT)
          })

# Works with multiple variables from a file
test_that("chomp_aggs should work from a file with multiple grouping variables",
          {test_json <- system.file("testdata", "three_var_agg.json", package = "uptasticsearch")
          expect_identical(chomp_aggs(aggs_json = test_json)
                           , data.table::data.table(a_grouping_var = c(rep(0L, 6), rep(2L, 6), rep(1L, 6))
                                                    , another_one = c(2915L, 2915L, 3952L, 3952L, 2632L, 2632L,
                                                                      2349L, 2349L, 2201L, 2201L, 2247L, 2247L,
                                                                      2126L, 2126L, 777L, 777L, 663L, 663L)
                                                    , yet_another_one = c(rep(c("lupe_fiasco", "tech_n9ne"), 3),
                                                                          rep(c("childish_gambino", "tech_n9ne"), 3),
                                                                          rep(c("lupe_fiasco", "tech_n9ne"), 3))
                                                    , doc_count = c(168098L, 20531L, 145484L, 873L, 121318L, 5877L,
                                                                    485820L, 56762L, 470503L, 34884L, 188375L, 17877L,
                                                                    405476L, 28259L, 241894L, 35493L, 193540L, 3668L)))}
)

# Works from a multi-element character vector (1 variable and multi-var)
test_that("chomp_aggs should work from a multi-element character vector",
          {test_json <- system.file("testdata", "three_var_agg.json", package = "uptasticsearch")
          jsonVec <- suppressWarnings(readLines(test_json))
          chompDT <- chomp_aggs(aggs_json = jsonVec)
          expect_identical(chompDT
                           , data.table::data.table(a_grouping_var = c(rep(0L, 6), rep(2L, 6), rep(1L, 6))
                                                    , another_one = c(2915L, 2915L, 3952L, 3952L, 2632L, 2632L,
                                                                      2349L, 2349L, 2201L, 2201L, 2247L, 2247L,
                                                                      2126L, 2126L, 777L, 777L, 663L, 663L)
                                                    , yet_another_one = c(rep(c("lupe_fiasco", "tech_n9ne"), 3),
                                                                          rep(c("childish_gambino", "tech_n9ne"), 3),
                                                                          rep(c("lupe_fiasco", "tech_n9ne"), 3))
                                                    , doc_count = c(168098L, 20531L, 145484L, 873L, 121318L, 5877L,
                                                                    485820L, 56762L, 470503L, 34884L, 188375L, 17877L,
                                                                    405476L, 28259L, 241894L, 35493L, 193540L, 3668L)))}
)

# Returns NULL if you don't pass in any data
test_that("chomp_aggs should return NULL and warn if you don't give it any data",
          {chompResult <- suppressWarnings(chomp_aggs(aggs_json = NULL))
          expect_true(is.null(chompResult))
          expect_warning(chomp_aggs(aggs_json = NULL),
                         regexp = "You did not pass any input data to chomp_aggs")}
)

# Should break with an informative error if you pass something weird (not a list or character) to chomp_aggs
test_that("chomp_aggs should break with an informative error for malformed inputs",
          {expect_error(chomp_aggs(aggs_json = list(a = 1, b = "2")),
                        regexp = "The first argument of chomp_aggs must be a character vector")}
)

# [cardinality] chomp_aggs should work for a one-level cardinality result
test_that("chomp_aggs should work for a one-level 'cardinality' aggregation",
          {
              result <- system.file("testdata", "aggs_cardinality.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, 'number_of_things.value')
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 1)
              expect_identical(chompDT, data.table::data.table(number_of_things.value = 777L))
          })

# [date_histogram] chomp_aggs should work for a one-level date_histogram result
test_that("chomp_aggs should work for a one-level 'date_histogram' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 10)
              expect_identical(chompDT[10, report_week], "2017-05-01T00:00:00.000Z")
          })

# [date_histogram-cardinality] chomp_aggs should work for a date_histogram-cardinality result
test_that("chomp_aggs should work for a 'date_histogram' - 'cardinality' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_cardinality.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'num_customers.value', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 10)
              expect_identical(chompDT[10, report_week], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(num_customers.value)]), c(4L, 5L))
          })

# [date_histogram-extended_stats] chomp_aggs should work for a date_histogram-extended_stats result
test_that("chomp_aggs should work for a 'date_histogram' - 'extended_stats' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_extended_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'some_score.count',
                                      'some_score.min', 'some_score.max', 'some_score.avg',
                                      'some_score.sum', 'some_score.sum_of_squares',
                                      'some_score.variance', 'some_score.std_deviation',
                                      'some_score.std_deviation_bounds.upper',
                                      'some_score.std_deviation_bounds.lower',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 10)
              expect_identical(chompDT[10, report_week], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(some_score.max)]), c(3L, 7L))
          })

# [date_histogram-histogram] chomp_aggs should work for a date_histogram-histogram result
test_that("chomp_aggs should work for a 'date_histogram' - 'histogram' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_histogram.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'num_customers', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 26)
              expect_identical(chompDT[26, report_week], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(num_customers)]), c(0L, 2L, 6L))
          })

# [date_histogram-percentiles] chomp_aggs should work for a date_histogram-percentiles result
test_that("chomp_aggs should work for a 'date_histogram' - 'percentiles' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_percentiles.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'some_score.values.1.0',
                                      'some_score.values.5.0', 'some_score.values.25.0',
                                      'some_score.values.50.0',
                                      'some_score.values.75.0', 'some_score.values.95.0',
                                      'some_score.values.99.0', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 10)
              expect_identical(chompDT[10, report_week], "2017-05-01T00:00:00.000Z")
              expect_true(all(chompDT$some_score.values.99.0 > 50))
              expect_true(all(chompDT$some_score.values.99.0 < 60))
          })

# [date_histogram-significant_terms] chomp_aggs should work for a date_histogram-significant_terms result
test_that("chomp_aggs should work for a 'date_histogram' - 'significant_terms' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_significant_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'key_words', 'score',
                                      'bg_count', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 50)
              expect_identical(chompDT[10, report_week], "2017-03-06T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(key_words)])
                               , c("believe", "blue", "child", "cont", "frankly",
                                   "glorious", "history", "no", "nor", "norm",
                                   "normal", "preposterous", "sa", "sam", "samp",
                                   "sampl", "think"))
          })

# [date_histogram-stats] chomp_aggs should work for a date_histogram-stats result
test_that("chomp_aggs should work for a 'date_histogram' - 'stats' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'some_score.count',
                                      'some_score.min', 'some_score.max', 'some_score.avg',
                                      'some_score.sum','doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 10)
              expect_identical(chompDT[10, report_week], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(some_score.max)]), c(3L, 7L))
          })

# [date_histogram-terms] chomp_aggs should work for a date_histogram-terms result
test_that("chomp_aggs should work for a 'date_histogram' - 'terms' aggregation",
          {
              result <- system.file("testdata", "aggs_date_histogram_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('report_week', 'theater_number', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 31)
              expect_identical(chompDT[31, report_week], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(theater_number)]), c(0L, 1L, 2L, 3L))
              expect_true(max(chompDT$doc_count) == 8306)
          })

# [extended_stats] chomp_aggs should work for a one-level extended_stats result
test_that("chomp_aggs should work for a one-level 'extended_stats' aggregation",
          {
              result <- system.file("testdata", "aggs_extended_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('affinity_score.count',
                                      'affinity_score.min',
                                      'affinity_score.max',
                                      'affinity_score.avg',
                                      'affinity_score.sum',
                                      'affinity_score.sum_of_squares',
                                      'affinity_score.variance',
                                      'affinity_score.std_deviation',
                                      'affinity_score.std_deviation_bounds.upper',
                                      'affinity_score.std_deviation_bounds.lower')
                           , ignore.order = TRUE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 1)
              expect_true("integer" %in% class(chompDT[, affinity_score.count]))
              expect_true(sum(sapply(chompDT, class) == 'numeric') == 9) # all but count will be numeric
          })

# [histogram] chomp_aggs should work for a histogram result
test_that("chomp_aggs should work for a 'histogram' aggregation",
          {
              result <- system.file("testdata", "aggs_histogram.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('affinity_score', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 5)
              expect_identical(chompDT$affinity_score, c(-50L, -25L, 0L, 25L, 50L))
          })

# [percentiles] chomp_aggs should work for a one-level percentiles result
test_that("chomp_aggs should work for a one-level 'percentiles' aggregation",
          {
              result <- system.file("testdata", "aggs_percentiles.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('affinity_score.percentile_1.0',
                                      'affinity_score.percentile_5.0',
                                      'affinity_score.percentile_25.0',
                                      'affinity_score.percentile_50.0',
                                      'affinity_score.percentile_65.489756',
                                      'affinity_score.percentile_75.0',
                                      'affinity_score.percentile_95.0',
                                      'affinity_score.percentile_99.0')
                           , ignore.order = TRUE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 1)
              expect_identical(round(chompDT[1, affinity_score.percentile_99.0], 2), 55.49)
          })

# [significant_terms] chomp_aggs should work for a one-level significant_terms result
test_that("chomp_aggs should work for a one-level 'significant terms' aggregation",
          {
              result <- system.file("testdata", "aggs_significant_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('top_tweet_keywords',
                                      'doc_count',
                                      'score',
                                      'bg_count')
                           , ignore.order = TRUE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 5)
              expect_true("integer" %in% class(chompDT[, doc_count]))
              expect_identical(chompDT[, top_tweet_keywords], c('no', 'cont', 'sa', 'norm', 'nor'))
              expect_identical(chompDT[, bg_count], c(384901L, 328493L, 330583L, 340281L, 340300L))
          })

# [stats] chomp_aggs should work for a one-level stats result
test_that("chomp_aggs should work for a one-level 'stats' aggregation",
          {
              result <- system.file("testdata", "aggs_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('affinity_score.count',
                                      'affinity_score.min',
                                      'affinity_score.max',
                                      'affinity_score.avg',
                                      'affinity_score.sum')
                           , ignore.order = TRUE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 1)
              expect_true("integer" %in% class(chompDT[, affinity_score.count]))
              expect_true(sum(sapply(chompDT, class) == 'numeric') == 4) # all but count will be numeric
          })

# [terms] chomp_aggs should work for a one-level terms result
test_that("chomp_aggs should work for a one-level 'terms' aggregation",
          {
              result <- system.file("testdata", "aggs_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('magic_number', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 10)
          })

# [terms-cardinality chomp_aggs should work for a terms - cardinality nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'cardinality' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_cardinality.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customerNumber', 'purchase_types.value', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 3)
              expect_identical(chompDT$purchase_types.value, c(4L, 4L, 2L))
          })

# [terms-date_histogram] chomp_aggs should work for a terms - date_histogram nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customerNumber', 'purchase_date', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 30)
              expect_identical(unique(chompDT$customerNumber), c(3L, 5L, 19L))
              expect_identical(chompDT[1, purchase_date], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[30, purchase_date], "2017-05-01T00:00:00.000Z")
          })

# [terms-date_histogram-cardinality] chomp_aggs should work for a terms - date_histogram - cardinality nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' - 'cardinality' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram_cardinality.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('theater_number', 'report_week', 'screenings.value', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 46)
              expect_identical(chompDT[1, report_week], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[30, report_week], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(theater_number)]), c(0L, 1L, 2L, 3L, 7L))
          })

# [terms-date_histogram-extended_stats] chomp_aggs should work for a terms - date_histogram - extended_stats nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' - 'extended_stats' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram_extended_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customer_type', 'report_week',
                                      'satisfaction_score.count', 'satisfaction_score.min',
                                      'satisfaction_score.max', 'satisfaction_score.avg',
                                      'satisfaction_score.sum', 'satisfaction_score.sum_of_squares',
                                      'satisfaction_score.variance', 'satisfaction_score.std_deviation',
                                      'satisfaction_score.std_deviation_bounds.upper',
                                      'satisfaction_score.std_deviation_bounds.lower',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 50)
              expect_identical(chompDT[, min(report_week)], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[, max(report_week)], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(customer_type)])
                               , c('big_spender', 'movie_buff', 'popcorn_fiend',
                                   'weekend_warrior', 'your_nemesis'))
          })

# [terms-date_histogram-percentiles] chomp_aggs should work for a terms - date_histogram - percentiles nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' - 'percentiles' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram_percentiles.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customer_type', 
                                      'report_week',
                                      'satisfaction_score.values.1.0',
                                      'satisfaction_score.values.5.0',
                                      'satisfaction_score.values.25.0',
                                      'satisfaction_score.values.50.0',
                                      'satisfaction_score.values.75.0',
                                      'satisfaction_score.values.95.0',
                                      'satisfaction_score.values.99.0',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 46)
              expect_identical(chompDT[, min(report_week)], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[, max(report_week)], "2017-05-01T00:00:00.000Z")
              expect_identical(sort(chompDT[, unique(customer_type)])
                               , c(0L, 1L, 2L, 3L, 7L))
              expect_true(chompDT[, min(satisfaction_score.values.1.0)] < -34.0)
          })

# [terms-date_histogram-significant_terms] chomp_aggs should work for a terms - date_histogram - significant_terms nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' - 'significant_terms' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram_significant_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('theater_number', 
                                      'report_week',
                                      'top_tweet_keywords',
                                      'score',
                                      'bg_count',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 151)
              expect_identical(chompDT[, min(report_week)], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[, max(report_week)], "2017-05-01T00:00:00.000Z")
              expect_true('detergent' %in% chompDT$top_tweet_keywords)
          })

# [terms-date_histogram-stats] chomp_aggs should work for a terms - date_histogram - stats nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' - 'stats' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customer_type',
                                      'report_week',
                                      'satisfaction_score.count',
                                      'satisfaction_score.min',
                                      'satisfaction_score.max',
                                      'satisfaction_score.avg',
                                      'satisfaction_score.sum',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 50)
              expect_identical(chompDT[, min(report_week)], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[, max(report_week)], "2017-05-01T00:00:00.000Z")
              expect_true('big_spender' %in% chompDT[, unique(customer_type)])
          })

# [terms-date_histogram-terms] chomp_aggs should work for a terms - date_histogram - terms nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'date_histogram' - 'terms' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_date_histogram_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customer_type',
                                      'report_week',
                                      'topCustomer',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 64)
              expect_identical(chompDT[, min(report_week)], "2017-02-27T00:00:00.000Z")
              expect_identical(chompDT[, max(report_week)], "2017-05-01T00:00:00.000Z")
              expect_true('Jean Valjean' %in% chompDT$topCustomer)
          })

# [terms-extended_stats] chomp_aggs should work for a terms - extended_stats nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'extended_stats' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_extended_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('campaign_status', 'some_score.count',
                                      'some_score.min', 'some_score.max', 'some_score.avg',
                                      'some_score.sum', 'some_score.sum_of_squares',
                                      'some_score.variance', 'some_score.std_deviation',
                                      'some_score.std_deviation_bounds.upper',
                                      'some_score.std_deviation_bounds.lower',
                                      'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 3)
          })



# [terms-histogram] chomp_aggs should work for a terms - histogram nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'histogram' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_histogram.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('campaign_status', 'affinity_score', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 7)
              expect_identical(sort(chompDT[, unique(affinity_score)]), c(-50L, 0L, 50L))
          })

# [terms-percentiles] chomp_aggs should work for a terms - percentiles nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'percentiles' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_percentiles.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('campaign_status', 'some_score.values.1.0',
                                      'some_score.values.5.0', 'some_score.values.25.0',
                                      'some_score.values.50.0', 'some_score.values.60.58934',
                                      'some_score.values.75.0', 'some_score.values.95.0',
                                      'some_score.values.99.0', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 3)
          })

# [terms-significant_terms] chomp_aggs should work for a terms - significant_terms nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'significant_terms' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_significant_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('popularity_score', 'comment_term', 'score',
                                      'bg_count', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 30)
              expect_identical(sort(chompDT[, unique(popularity_score)]), c('opinion', 'reviews', 'summaries'))
          })

# [terms-stats] chomp_aggs should work for a terms - stats nested aggregation
test_that("chomp_aggs should work for a 'terms' - 'stats' nested aggregation",
          {
              result <- system.file("testdata", "aggs_terms_stats.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('customerNumber', 'some_score.count',
                                      'some_score.min', 'some_score.max', 'some_score.avg',
                                      'some_score.sum', 'doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 3)
              expect_identical(sort(chompDT$customerNumber), c(3L, 9L, 19L))
          })

# [terms-terms] chomp_aggs should work for a two-level terms result
test_that("chomp_aggs should work for a two-level 'terms' aggregation",
          {
              result <- system.file("testdata", "aggs_terms_terms.json", package = "uptasticsearch")
              chompDT <- chomp_aggs(aggs_json = result)
              
              expect_named(chompDT, c('magic_number', 'customerType','doc_count')
                           , ignore.order = FALSE, ignore.case = FALSE)
              expect_true('data.table' %in% class(chompDT))
              expect_true(nrow(chompDT) == 3)
              expect_true(all(chompDT$customerType == 'type_a'))
          })

# empty results
test_that("chomp_aggs should work for an empty terms result", {
    result <- system.file("testdata", "empty_terms.json", package = "uptasticsearch")
    chompDT <- chomp_aggs(aggs_json = result)
    expect_null(chompDT)
})

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
