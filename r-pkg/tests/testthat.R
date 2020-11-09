# This line ensures that R CMD check can run tests.
# See https://github.com/hadley/testthat/issues/144
Sys.setenv("R_TESTS" = "")

library(uptasticsearch)

testthat::test_check('uptasticsearch')
