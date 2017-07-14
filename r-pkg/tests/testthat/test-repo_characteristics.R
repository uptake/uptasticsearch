context("Checking repo characteristics")

# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

# Currently limiting external files included in the package to be no more than
# 10 MB on disk. Will revisit if anyone submits a PR that breaks this rule.
test_that("Files in extdata/ and testdata/ should be smaller than 10MB on disk"
          , {dataDirs <- c("extdata", "testdata", "inst/extdata", "inst/testdata")
          results <- lapply(dataDirs, function(dirName){
              dirPath <- paste0(find.package("uptasticsearch"), "/", dirName)
              infoDF <- file.info(list.files(path = dirPath
                                             , full.names = TRUE
                                             , recursive = TRUE))
              return(data.table::data.table(infoDF, keep.rownames = TRUE))})
          infoDT <- data.table::rbindlist(results)
          sizesInMB <- infoDT[, size] / (1024^2)
          
          # nrow() check accounts for case where we pass a bad path and get
          # back an empty DF
          expect_true(nrow(infoDT) != 0 && max(sizesInMB) < 10)}
)


# R CMD Check stuff. Current upper lims: 0 errors, 0 warnings, 0 notes
test_that('R CMD check should not return any unexpected errors, warnings, or notes', {
    
    # Do not run this if tests are being run from R CMD check --as-cran 
    testthat::skip_on_cran()
    
    # Check the package
    x <- devtools::check(pkg = '../../../uptasticsearch'
                         , document = TRUE
                         , args = '--no-tests --ignore-vignettes'
                         , quiet = FALSE)
    
    # Should not return any errors
    expect_true(length(x[["errors"]]) == 0)
    
    # Should not return any warnings except possibly one that is caused
    # by running this on a system where MASS is not available
    expect_true(length(x[["warnings"]]) == 0 || x[["warnings"]] == "checking Rd cross-references ... WARNING\nError in find.package(package, lib.loc) : \n  there is no package called ‘MASS’\nCalls: <Anonymous> -> lapply -> FUN -> find.package\nExecution halted")
    
    # Should not return any notes
    expect_true(length(x[["notes"]]) == 0)
})

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
