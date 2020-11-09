# Note that you would never run this file directly. This is used by tools::testInstallPackages()
# and other packages like covr.

# This line ensures that R CMD check can run tests.
# See https://github.com/hadley/testthat/issues/144
Sys.setenv("R_TESTS" = "")

library(uptasticsearch)

testthat::test_check('uptasticsearch')
