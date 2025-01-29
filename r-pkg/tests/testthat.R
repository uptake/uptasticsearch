library(testthat)
library(uptasticsearch)  # nolint[unused_import]

testthat::test_check(
    package = "uptasticsearch"
    , stop_on_failure = TRUE
    , stop_on_warning = FALSE
    , reporter = testthat::SummaryReporter$new()
)
