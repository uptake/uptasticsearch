# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

context("parse_date_time")


# Correctly adjusts UTC date-times
test_that("parse_date_time should transform the indicated date_cols to POSIXct with timezone UTC if they're given in UTC",{
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    newDT <- parse_date_time(testDT, date_cols = c("dateTime"))
    
    expect_true("POSIXct" %in% class(newDT$dateTime))
    expect_identical(
        newDT
        , data.table::data.table(
            id = c("a", "b", "c")
            , dateTime = as.POSIXct(c("2016-07-16 21:15:00", "2015-04-16 02:15:00", "2015-03-04 15:25:00"), tz = "UTC")
          )
    )
})

# Correctly adjusts non-UTC date-times
test_that("parse_date_time should transform the indicated date_cols to POSIXct with timezone UTC correctly even if the dates are not specified in UTC", {
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00A", "2015-03-04T15:25:00B")
    )
    newDT <- parse_date_time(testDT, date_cols = c("dateTime"))
    
    expect_true("POSIXct" %in% class(newDT$dateTime))
    expect_identical(
        newDT
        , data.table::data.table(
            id = c("a", "b", "c")
            , dateTime = as.POSIXct(c("2016-07-16 21:15:00", "2015-04-16 01:15:00", "2015-03-04 13:25:00"), tz = "UTC")
          )
    )
})

# Returns object of class POSIXct
test_that("parse_date_time should transform the indicated date_cols to class POSIXct",{
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    newDT <- parse_date_time(testDT, date_cols = c("dateTime"))
    
    expect_true("POSIXct" %in% class(newDT$dateTime))
    expect_identical(
        newDT
        , data.table::data.table(
            id = c("a", "b", "c")
            , dateTime = as.POSIXct(c("2016-07-16 21:15:00", "2015-04-16 02:15:00", "2015-03-04 15:25:00"), tz = "UTC")
          )
    )
})

# Works for one date column
test_that("parse_date_time should perform adjustments only on the columns you ask it to", {
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
        , otherDate = c("2014-03-11T12:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    newDT <- parse_date_time(testDT, date_cols = c("dateTime"))
    
    expect_true(all(c("dateTime", "otherDate") %in% names(newDT)))
    expect_true("POSIXct" %in% class(newDT$dateTime))
    expect_true("character" %in% class(newDT$otherDate))
    expect_identical(
        newDT
        , data.table::data.table(
            id = c("a", "b", "c")
            , dateTime = as.POSIXct(c("2016-07-16 21:15:00", "2015-04-16 02:15:00", "2015-03-04 15:25:00"), tz = "UTC")
            , otherDate = c("2014-03-11T12:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
          )
    )
})

# works for multiple date columns
test_that("parse_date_time should perform adjustments for multiple data columns if asked",{
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
        , otherDate = c("2014-03-11T12:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    newDT <- parse_date_time(testDT, date_cols = c("dateTime", "otherDate"))
          
    expect_true(all(c("dateTime", "otherDate") %in% names(newDT)))
    expect_true("POSIXct" %in% class(newDT$dateTime))
    expect_true("POSIXct" %in% class(newDT$otherDate))
    expect_identical(
        newDT
        , data.table::data.table(
            id = c("a", "b", "c")
            , dateTime = as.POSIXct(c("2016-07-16 21:15:00", "2015-04-16 02:15:00", "2015-03-04 15:25:00"), tz = "UTC")
            , otherDate = as.POSIXct(c("2014-03-11 12:15:00", "2015-04-16 02:15:00", "2015-03-04 15:25:00"), tz = "UTC")
          )
    )
})

# Gives an informative error if date_cols is not character vector
test_that("parse_date_time should give an informative error if you pass non-character stuff to date_cols", {
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    
    expect_error({
        parse_date_time(testDT, date_cols = list("dateTime"))
    }, regexp = "The date_cols argument in parse_date_time expects a character vector")
})

# Gives informative error if inputDT is not a data.table
test_that("parse_date_time should give an informative error if you don't pass it a data.table", {
    testDF <- data.frame(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    
    expect_error({
        parse_date_time(testDF, date_cols = "dateTime")
    }, regexp = "parse_date_time expects to receive a data\\.table object")
})

# Gives informative error if you ask to adjust date_cols that don't exist
test_that("parse_date_time should give an informative error if you give it dateCol names that don't exist in the DT", {
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    
    expect_error({
        parse_date_time(testDT, date_cols = c("dateTime", "dateTyme"))
    }, regexp = "do not actually exist in input_df")
})

# Does not have side effects (works on a copy)
test_that("parse_date_time should leave the original DT unchanged", {
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00Z", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    
    beforeDT <- data.table::copy(testDT)
    origAddress <- data.table::address(testDT)
    newDT <- parse_date_time(testDT, date_cols = "dateTime")
    
    expect_identical(testDT, beforeDT)
    expect_identical(origAddress, data.table::address(testDT))
    expect_true(origAddress != data.table::address(newDT))
})

# Substitutes in assume_tz if missing a timezone
test_that("parse_date_time should leave the original DT unchanged", {
    
    testDT <- data.table::data.table(
        id = c("a", "b", "c")
        , dateTime = c("2016-07-16T21:15:00", "2015-04-16T02:15:00Z", "2015-03-04T15:25:00Z")
    )
    beforeDT <- data.table::copy(testDT)
    origAddress <- data.table::address(testDT)
    newDT <- parse_date_time(testDT, date_cols = "dateTime", assume_tz = "UTC")
    
    expect_identical(newDT[id=="a", dateTime], as.POSIXct("2016-07-16 21:15:00", tz = "UTC"))
})

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
