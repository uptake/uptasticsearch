
#' @title Get the names and data types of the indexed fields in an index
#' @name get_fields
#' @description For a given Elasticsearch index, return the mapping from field name
#'              to data type for all indexed fields.
#' @importFrom data.table := rbindlist uniqueN
#' @importFrom httr add_headers content GET stop_for_status
#' @importFrom purrr map2
#' @param es_indices A character vector that contains the names of indices for
#'                   which to get mappings. Default is \code{'_all'}, which means
#'                   get the mapping for all indices. Names of indices can be
#'                   treated as regular expressions.
#' @inheritParams doc_shared
#' @export
#' @return A data.table containing four columns: index, type, field, and data_type
#' @examples \dontrun{
#' # get the mapping for all indexed fields in the ticket_sales and customers indices
#' mappingDT <- get_fields(es_host = "http://es.custdb.mycompany.com:9200"
#'                               , es_indices = c("ticket_sales", "customers"))
#' }
get_fields <- function(es_host
                       , es_indices = '_all'
) {

    # Input checking
    es_url <- .ValidateAndFormatHost(es_host)

    .assert(
        is.character("es_indices")
        , length(es_indices) > 0
    )

    # collapse character vectors into comma separated strings. If any arguments
    # are NULL, create an empty string
    indices <- paste(es_indices, collapse = ',')

    ########################## build the query ################################
    if (nchar(indices) > 0) {
        es_url <- paste(es_url, indices, '_mapping', sep = '/')
    } else {
        msg <- paste("get_fields must be passed a valid es_indices."
                     , "You provided", paste(es_indices, collapse = ', ')
                     , 'which resulted in an empty string')
        log_fatal(msg)
    }

    ########################## make the query ################################
    log_info(paste('Getting indexed fields for indices:', indices))

    result <- httr::GET(
        url = es_url
        , httr::add_headers(c('Content-Type' = 'application/json'))
    )
    httr::stop_for_status(result)
    resultContent <- httr::content(result, as = 'parsed')

    ######################### flatten the result ##############################
    mappingDT <- .flatten_mapping(mapping = resultContent)

    ##################### get aliases for index names #########################
    rawAliasDT <- .get_aliases(es_host = es_host)
    if (!is.null(rawAliasDT)) {

        log_info("Replacing index names with aliases")

        # duplicate the mapping results for every alias. Idea is that you should be able to rely
        # on the results of get_fields to programmatically generate queries, and you should have a
        # preference for hitting aliases over straight-up index name
        aliasDT <- data.table::rbindlist(
            purrr::map2(
                .x = rawAliasDT[["index"]]
                , .y = rawAliasDT[["alias"]]
                , .f = function(idx_name, alias_name, mappingDT){
                    tmpDT <- mappingDT[index == idx_name]
                    tmpDT[, index := alias_name]
                    return(tmpDT)
                }
                , mappingDT = mappingDT
            )
            , fill = TRUE
        )

        # Merge these alias records with the other mapping data that came from indexes
        # without any aliases. I know this seems overly complicated, but it makes it possible
        # to deal with the very-real state of the world where one index has multiple aliases
        # pointing to it
        mappingDT <- data.table::rbindlist(
            list(aliasDT, mappingDT[!(index %in% rawAliasDT[["index"]])])
            , fill = TRUE
        )
    }

    # log some information about this request to the user
    numFields <- nrow(mappingDT)
    numIndex <- mappingDT[, data.table::uniqueN(index)]
    log_info(paste('Retrieved', numFields, 'fields across', numIndex, 'indices'))

    return(mappingDT)
}

# [title] Flatten a mapping list of field name to data type into a data.table
# [mapping] A list of json that is returned from a request to the mappings API
#' @importFrom data.table := data.table setnames
#' @importFrom stringr str_detect str_split_fixed str_replace_all
.flatten_mapping <- function(mapping) {

    ######################### parse the result ###############################
    # flatten the list object that is returned from the query
    flattened <- unlist(mapping)

    # the names of the flattened object has the index, type, and field name
    # however, it also has extra terms that we can use to split the name
    # into three distinct parts
    mappingCols <- stringr::str_split_fixed(names(flattened), '\\.(mappings|properties)\\.', n = 3)

    # convert to data.table and add the data type column
    mappingDT <- data.table::data.table(
        meta = mappingCols
        , data_type = as.character(flattened)
    )
    newColNames <- c('index', 'type', 'field', 'data_type')
    data.table::setnames(mappingDT, newColNames)

    # remove any rows, where the field does not end in ".type" to remove meta info
    mappingDT <- mappingDT[stringr::str_detect(field, '\\.type$')]

    # mappings in nested objects have sub-fields called properties
    # mappings of fields that are indexed in different ways have multiple fields
    # we want to remove these terms from the field name
    metaRegEx <- '\\.(properties|fields|type)'
    mappingDT[, field := stringr::str_replace_all(field, metaRegEx, '')]

    return(mappingDT)
}

# [title] Get a data.table containing names of indices and aliases
# [es_host] A string identifying an Elasticsearch host.
#' @importFrom httr add_headers content GET stop_for_status
.get_aliases <- function(es_host) {

    # construct the url to the alias endpoint
    url <- paste0(es_host, '/_cat/aliases')

    # make the request
    result <- httr::GET(
        url = url
        , httr::add_headers(c('Content-Type' = 'application/json'))
    )
    httr::stop_for_status(result)
    resultContent <- httr::content(result, as = 'text')

    # NOTES:
    # - with ES1.7.2., this returns an empty array "[]"
    # - with ES6, this results in an empty string instead of a NULL
    if (is.null(resultContent) || identical(resultContent, "") || identical(resultContent, "[]")) {
        # there are no aliases in this Elasticsearch cluster
        return(invisible(NULL))
    } else {
        major_version <- .get_es_version(es_host)
        process_alias <- switch(
            major_version
            , "1" = .process_legacy_alias
            , "2" = .process_legacy_alias
            , "5" = .process_new_alias
            , "6" = .process_new_alias
            , .process_new_alias
        )
        return(process_alias(alias_string = resultContent))
    }
}


# [title] Process the string returned by the GET alias API into a data.table
# [description] Older version of ES (pre-5.x) had a slightly different return
#               format for aliases. This handles those
# [alias_string] A string returned by the alias API with index and alias name
#' @importFrom data.table as.data.table
#' @importFrom jsonlite fromJSON
.process_legacy_alias <- function(alias_string){
    aliasDT <- data.table::as.data.table(
        jsonlite::fromJSON(
            alias_string
            , simplifyDataFrame = TRUE
            , flatten = TRUE
        )
    )
    return(aliasDT[, .(alias, index)])
}

# [title] Process the string returned by the GET alias API into a data.table
# [description] This only works for ES5 and up
# [alias_string] A string returned by the alias API with index and alias name
#' @importFrom data.table data.table
#' @importFrom utils read.table
.process_new_alias <- function(alias_string) {

    # process the string provided by the /_cat/aliases API into a data.frame and then a data.table
    aliasDT <- data.table::data.table(
        utils::read.table(
            text = alias_string
            , stringsAsFactors = FALSE
        )
    )

    # return only the first two columns
    return(aliasDT[, .(alias = V1, index = V2)])
}
