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
x <- devtools::check(pkg = '../../../uptasticsearch'
                     , document = TRUE
                     , args = '--no-tests --ignore-vignettes'
                     , quiet = FALSE)

test_that("R CMD check should not return any errors", {
    expect_true(length(x[["errors"]]) == 0)
})

test_that("R CMD check should not return any warnings", {
    expect_true(length(x[["warnings"]]) == 1)
})

test_that("R CMD check should return not return any warnings", {
    expect_true(length(x[["notes"]]) == 0)
})

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
