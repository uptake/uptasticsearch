
# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

context("Elasticsearch result-parsing functions")

#--- unpack_nested_data

    # Should work with result of chomp_hits
    test_that("unpack_nested_data should work with the result of chomp_hits",
              {test_json <- '[{"_source":{"dateTime":"2017-01-01","username":"Austin1","details":{
                "interactions":400,"userType":"active","appData":[{"appName":"farmville","minutes":500},
                {"appName":"candy_crush","value":350},{"appName":"angry_birds","typovalue":422}]}}},
                {"_source":{"dateTime":"2017-02-02","username":"Austin2","details":{"interactions":5,
                "userType":"very_active","appData":[{"appName":"minesweeper","value":28},{"appName":
                "pokemon_go","value":190},{"appName":"pokemon_stay","value":1},{"appName":"block_dude",
                "value":796}]}}}]'
              sampleChompedDT <- chomp_hits(test_json
                                             , keep_nested_data_cols = TRUE)
              unpackedDT <- unpack_nested_data(chomped_df = sampleChompedDT
                                               , col_to_unpack = "details.appData")
              expect_true("data.table" %in% class(unpackedDT))
              expect_equivalent(dim(unpackedDT), c(7, 8))
              expect_named(unpackedDT, c('dateTime', 'username', 'details.interactions', 
                                         'details.userType', 'appName', 'minutes', 'value', 'typovalue'))
              expect_identical(unpackedDT$appName, c('farmville', 'candy_crush', 'angry_birds',
                                                     'minesweeper', 'pokemon_go', 'pokemon_stay',
                                                     'block_dude'))
              expect_identical(unpackedDT$username, c(rep("Austin1", 3), rep("Austin2", 4)))
              expect_true(sum(is.na(unpackedDT$minutes)) == 6)
             })
    
    # Should work if the array is a simple array rather than an array of maps
    test_that("unpack_nested_data should work if the array is a simple array",
              {test_json <- '[{"_source":{"dateTime":"2017-01-01","username":"Austin1","details":{
              "interactions":400,"userType":"active","minutes":[500,350,422]}}},
              {"_source":{"dateTime":"2017-02-02","username":"Austin2","details":{"interactions":0,
              "userType":"never","minutes":[]}}},
              {"_source":{"dateTime":"2017-03-03","username":"Austin3","details":{"interactions":5,
              "userType":"very_active","minutes":[28,190,1,796]}}}]'
              sampleChompedDT <- chomp_hits(test_json
                                            , keep_nested_data_cols = TRUE)
              unpackedDT <- unpack_nested_data(chomped_df = sampleChompedDT
                                               , col_to_unpack = "details.minutes")
              expect_true("data.table" %in% class(unpackedDT))
              expect_equivalent(dim(unpackedDT), c(8, 5))
              expect_named(unpackedDT, c('dateTime', 'username', 'details.interactions', 
                                         'details.userType', 'details.minutes'))
              expect_equivalent(unpackedDT$details.minutes, c(500, 350, 422, NA, 28, 190, 1, 796))
              expect_identical(unpackedDT$username, c(rep("Austin1", 3), "Austin2", rep("Austin3", 4)))
              })
    
    # Should break if chomped_df is not a data.table
    test_that("unpack_nested_data should break if you don't pass a data.table",
              {expect_error(unpack_nested_data(chomped_df = 42
                                               , col_to_unpack = "blah"),
                            regexp = "chomped_df must be a data.table")}
             )
    
    # Should break if col_to_unpack is not a string
    test_that("unpack_nested_data should break if col_to_unpack is not a string",
              {expect_error(unpack_nested_data(chomped_df = data.table::data.table(wow = 7)
                                               , col_to_unpack = 8),
                            regexp = "col_to_unpack must be a character of length 1")}
             )
    
    # Should break if col_to_unpack is not of length 1
    test_that("unpack_nested_data should break if col_to_unpack is not of length 1",
              {expect_error(unpack_nested_data(chomped_df = data.table::data.table(wow = 7)
                                               , col_to_unpack = c("a", "b")),
                            regexp = "col_to_unpack must be a character of length 1")}
             )
    
    # Should break if col_to_unpack is not one of the column names
    test_that("unpack_nested_data should break if col_to_unpack is not one of the column names",
              {expect_error(unpack_nested_data(chomped_df = data.table::data.table(wow = 7)
                                               , col_to_unpack = "a"),
                            regexp = "col_to_unpack must be one of the column names")}
             )
    
    # Should break if the column doesn't include any data
    test_that("unpack_nested_data should break if the column doesn't include any data",
              {expect_error(unpack_nested_data(chomped_df = data.table::data.table(wow = 7, dang = list())
                                               , col_to_unpack = "dang"),
                            regexp = "The column given to unpack_nested_data had no data in it")}
    )
    
    test_that("unpack_nested_data should break if the column contains a non data frame/vector", {
        DT <- data.table::data.table(x = 1:2, y = list(list(2), 3))
        expect_error(unpack_nested_data(chomped_df = DT, col_to_unpack = "y")
                     , regexp = "must be a data frame or a vector")
    })
    
    test_that("unpack_nested_data should handle NA and empty rows", {
        DT <- data.table::data.table(x = 1:2, y = list(z = NA, data.table::data.table(w = 5:6, z = 7:8)))
        DT2 <- data.table::data.table(x = 1:2, y = list(z = list(), data.table::data.table(w = 5:6, z = 7:8)))
        unpackedDT <- data.table::data.table(
            x = c(1, 2, 2)
            , w = c(NA, 5, 6)
            , z = c(NA, 7, 8)
        )
        expect_equal(unpack_nested_data(DT, col_to_unpack = "y"), unpackedDT)
        expect_equal(unpack_nested_data(DT2, col_to_unpack = "y"), unpackedDT)
    })
    

##### TEST TEAR DOWN #####
futile.logger::flog.threshold(origLogThreshold)
rm(list = ls())
closeAllConnections()
