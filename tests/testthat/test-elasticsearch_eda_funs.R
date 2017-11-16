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

    # Gives an informative error if es_indices is NULL or an empty string
    test_that("get_fields should give an informative error if es_indices is NULL or an empty string",
              {
                  expect_error(get_fields(es_host = "http://es.custdb.mycompany.com:9200"
                                          , es_indices = NULL),
                               regexp = "get_fields must be passed a valid es_indices")
                  expect_error(get_fields(es_host = "http://es.custdb.mycompany.com:9200"
                                          , es_indices = ''),
                               regexp = "get_fields must be passed a valid es_indices")
              }
    )
    
    # works as expected when mocked
    test_that('get_fields works as expected when mocked',
              {
                  test_json <- system.file("testdata", "two_index_mapping.json", package = "uptasticsearch")
                  aliasDT <- data.table::data.table(alias = c('alias1', 'alias2')
                                                    , index = c('company', 'otherIndex'))
                  testthat::with_mock(
                      `httr::stop_for_status` = function(...) {return(NULL)},
                      `httr::GET` = function(...) {return(NULL)},
                      `httr::content` = function(...) {return(jsonlite::fromJSON(txt = test_json))},
                      `uptasticsearch::.get_aliases` = function(...) {return(aliasDT)},
                      {
                          outDT <- get_fields(es_host = 'http://db.mycompany.com:9200'
                                              , es_indices = c('company', 'hotel'))
                          data.table::setkey(outDT, NULL)
                          expected <- data.table::data.table(
                              index = c(rep('alias1', 3), rep('hotel', 5))
                              , type = c(rep('building', 3), rep('bed_room', 2), rep('conference_room', 3))
                              , field = c('id', 'address', 'address.keyword', 'num_beds', 'description'
                                          , 'num_people', 'purpose', 'purpose.keyword')
                              , data_type = c('long', 'text', 'keyword', 'integer', 'text', 'integer'
                                              , 'text', 'keyword')
                          )
                          expect_identical(outDT, expected)
                      }
                  )
              }
    )
    
    
#--- 3. .flatten_mapping
    
    # Works if one index is passed
    test_that(".flatten_mapping should work if the mapping for one index is provided",
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
    
    # works if multiple indices are passed
    test_that(".flatten_mapping should work if the mapping for multiple indices are provided",
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

#--- 4. .process_alias
    
    # works if one alias is passed
    test_that(".process_alias works if one alias is included",
              {
                  alias_string <- 'dwm shakespeare - - -\n'
                  aliasDT <- uptasticsearch:::.process_alias(alias_string = alias_string)
                  expected <- data.table::data.table(alias = 'dwm', index = 'shakespeare')
                  expect_identical(aliasDT, expected)
              }
    )
    
    # works if multiple aliases are passed
    test_that(".process_alias works if one alias is included",
              {
                  alias_string <- 'dwm   shakespeare - - -\nmoney bank        - - -\n'
                  aliasDT <- uptasticsearch:::.process_alias(alias_string = alias_string)
                  expected <- data.table::data.table(alias = c('dwm', 'money'), index = c('shakespeare', 'bank'))
                  expect_identical(aliasDT, expected)
              }
    )
