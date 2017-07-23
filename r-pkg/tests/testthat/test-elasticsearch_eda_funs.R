context("Elasticsearch eda functions")

# Configure logger (suppress all logs in testing)
loggerOptions <- futile.logger::logger.options()
if (!identical(loggerOptions, list())){
    origLogThreshold <- loggerOptions[[1]][['threshold']]    
} else {
    origLogThreshold <- futile.logger::INFO
}
futile.logger::flog.threshold(0)

#--- 1. get_counts



#--- 2. get_fields

    # Gives an informative error if es_indexes is NULL or an empty string
    test_that("get_fields should give an informative error if es_indexes is NULL or an empty string",
              {
                  expect_error(get_fields(es_host = "http://es.custdb.mycompany.com:9200"
                                          , es_indexes = NULL),
                               regexp = "get_fields must be passed a valid es_indexes")
                  expect_error(get_fields(es_host = "http://es.custdb.mycompany.com:9200"
                                          , es_indexes = ''),
                               regexp = "get_fields must be passed a valid es_indexes")
              }
    )
    
    # Works if one index is passed
    test_that("get_fields should work if the mapping for one index is provided",
              {
                  test_json <- system.file("testdata", "one_index_mapping.json", package = "uptasticsearch")
                  mapping <- jsonlite::fromJSON(txt = test_json)
                  mappingDT <- uptasticsearch:::.flatten_mapping(mapping = mapping)
                  expected <- data.table::data.table(
                      index = rep('basketball', 5)
                      , type = rep('players', 5)
                      , field = c('team', 'name.first', 'name.last', 'age', 'position')
                      , data_type = c('keyword', 'text', 'text', 'integer', 'keyword')
                  )
                  expect_identical(mappingDT, expected)
              }
    )
    
    # works if multiple indexes are passed
    test_that("get_fields should work if the mapping for multiple indexes are provided",
              {
                  test_json <- system.file("testdata", "two_index_mapping.json", package = "uptasticsearch")
                  mapping <- jsonlite::fromJSON(txt = test_json)
                  mappingDT <- uptasticsearch:::.flatten_mapping(mapping = mapping)
                  expected <- data.table::data.table(
                      index = c(rep('company', 3), rep('hotel', 5))
                      , type = c(rep('building', 3), rep('bed_room', 2), rep('conference_room', 3))
                      , field = c('id', 'address', 'address.keyword', 'num_beds', 'description'
                                  , 'num_people', 'purpose', 'purpose.keyword')
                      , data_type = c('long', 'text', 'keyword', 'integer', 'text', 'integer'
                                      , 'text', 'keyword')
                  )
                  expect_identical(mappingDT, expected)
              }
    )
    