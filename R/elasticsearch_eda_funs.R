
#' @title Examine the distribution of distinct values for a field in Elasticsearch
#' @name get_counts
#' @description For a given field, return a data.table with its unique values in a time range.
#' @importFrom data.table := data.table setnames setkeyv
#' @importFrom httr content RETRY
#' @importFrom purrr transpose
#' @export
#' @param field A valid field in whatever Elasticsearch index you are querying
#' @param start_date A character Elasticsearch date-time, indicating the earliest
#'        date from which to show documents. Default is \code{"now-1w"}.
#' @param end_date A character Elasticsearch date-time, indicating the most recent
#'        date from which to show documents. Default is \code{"now"}.
#' @param time_field Name of the date-time field in the target index on which you want to filter by time.
#' @param use_na A string to control handling of missing values in the result. Options are:
#'        \enumerate{
#'        \item{\code{"always"} to give a row in the table for NAs even if there are none (default)}
#'        \item{\code{"ifany"} to include a count of missing values only if there are any}
#'        \item{\code{NULL} to never include NAs}
#'        }
#' @param max_terms What is the maximum number of unique terms to return? Many production
#'                  Elasticsearch deployments limit this to a small number by default. Default here is 1000.
#' @inheritParams doc_shared
#' @examples
#' \dontrun{
#' # Count number of customers by payment method
#' recoDT <- get_counts(field = "pmt_method"
#'                      , es_host = "http://es.custdb.mycompany.com:9200"
#'                      , es_index = "ticket_sales"
#'                      , start_date = "now-2w"
#'                      , end_date = "now"
#'                      , time_field = "dateTime")
#' }
get_counts <- function(field
                      , es_host
                      , es_index
                      , start_date = "now-1w"
                      , end_date = "now"
                      , time_field
                      , use_na = "always"
                      , max_terms = 1000
){
    
    # Input checking
    es_host <- .ValidateAndFormatHost(es_host)
    
    #===== Format and execute query =====#
    
    # Support un-dated queries
    if (is.null(start_date)){
        start_date <- "null"
    } else {
        start_date <- paste0('"', start_date, '"')  
    }
    if (is.null(end_date)){
        end_date <- "null"
    } else {
        end_date <- paste0('"', end_date, '"')  
    }
    
    # Build query
    aggsQuery <- paste0('{"query": {"filtered": {"filter": {"bool": {"must": [
                        {"range": {"', time_field, '": {"gte":', start_date, ',"lte":', end_date, '}}}
                        ]}}}}, "aggs": {"', field, '": {"terms": {"field": "', field, '", "size":', max_terms,'}}}}')
    
    #===== Build search URL =====#
    searchURL  <- paste0(es_host, "/", es_index, "/_search?size=0")
    result     <- httr::RETRY(verb = "POST", url = searchURL, body = aggsQuery)
    counts     <- httr::content(result, as = "parsed")[["aggregations"]][[field]][["buckets"]]
    
    #===== Get data =====#
    # Deal w/ case where the field doesn't exist for any records
    if (length(counts) == 0) {
        resultDT = data.table::data.table(keyval = character(0), count = integer(0))
    } else {
        # Get into a data.table
        countsT  <- purrr::transpose(counts)
        resultDT <- data.table::data.table(keyval = unlist(countsT[["key"]]), count = unlist(countsT[["doc_count"]]))
    }
    
    # Reformat
    data.table::setnames(resultDT, "keyval", field)
    
    #===== Return now if we're not dealing with NAs =====#
    if (is.null(use_na) || !use_na %in% c("always", "ifany")){
        return(resultDT)
    }
    
    #===== Find the number of missing records =====#
    # Build Query
    missingQuery <- paste0('{"query": {"filtered": {"filter": {"bool": {"must": [
        {"range": {"', time_field, '": {"gte":', start_date, ', "lte":', end_date, '}}},
        {"missing": {"field": "', field, '"}}]}}}}}')
    
    # Get result
    result      <- httr::RETRY(verb = "POST", url = searchURL, body = missingQuery)
    numMissings <- httr::content(result, as = "parsed")[["hits"]][["total"]]
    
    # Return now if user asked to only see NAs if there are any
    if (numMissings == 0 && use_na == "ifany"){
        return(resultDT)
    }
    
    # Append count of NAs to the data.table
    naDT <- data.table::data.table(keyval = NA, count = numMissings)
    
    # Reformat
    data.table::setnames(naDT, "keyval", field)
    
    # Return
    return(rbind(naDT, resultDT))
    
}

#' @title Get the names and data types of the indexed fields in an index
#' @name get_fields
#' @description For a given Elasticsearch index, return the mapping from field name
#'              to data type for all indexed fields.
#' @importFrom httr GET content stop_for_status
#' @importFrom data.table := uniqueN
#' @param es_indices A character vector that contains the names of indices for
#'                   which to get mappings. Default is \code{'_all'}, which means
#'                   get the mapping for all indices. Names of indices can be
#'                   treated as regular expressions.
#' @inheritParams doc_shared
#' @export
#' @return A data.table containing four columns: index, type, field, and data_type
#' @examples \dontrun{
#' # get the mapping for all indexed fields in the ticket_sales and customers indices
#' mappingDT <- retrieve_mapping(es_host = "http://es.custdb.mycompany.com:9200"
#'                               , es_indices = c("ticket_sales", "customers"))
#' }
get_fields <- function(es_host
                       , es_indices = '_all'
) {
    
    # Input checking
    url <- .ValidateAndFormatHost(es_host)
    
    # collapse character vectors into comma separated strings. If any arguments
    # are NULL, create an empty string
    indices <- paste(es_indices, collapse = ',')
    
    ########################## build the query ################################
    if (nchar(indices) > 0) {
        url <- paste(url, indices, '_mapping', sep = '/')
    } else {
        msg <- paste("get_fields must be passed a valid es_indices."
                     , "You provided", paste(es_indices, collapse = ', ')
                     , 'which resulted in an empty string')
        log_fatal(msg)
    }
    
    ########################## make the query ################################
    log_info(paste('Getting indexed fields for indices:', indices))
    
    result <- httr::GET(url = url)
    httr::stop_for_status(result)
    resultContent <- httr::content(result, as = 'parsed')
    
    ######################### flatten the result ##############################
    mappingDT <- .flatten_mapping(mapping = resultContent)
    
    ##################### get aliases for index names #########################
    aliasDT <- .get_aliases(es_host = es_host)
    if (!is.null(aliasDT)) {
        lookup <- aliasDT[['alias']]
        names(lookup) <- aliasDT[['index']]
        mappingDT[index %in% names(lookup), index := lookup[index]]
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
    mappingDT <- data.table::data.table(meta = mappingCols, data_type = as.character(flattened))
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
#' @importFrom httr content GET stop_for_status
.get_aliases <- function(es_host) {
    
    # construct the url to the alias endpoint
    url <- paste0(es_host, '/_cat/aliases')
    
    # make the request
    result <- httr::GET(url = url)
    httr::stop_for_status(result)
    resultContent <- httr::content(result, as = 'text')
    
    if (is.null(resultContent)) {
        # there are no aliases in this Elasticsearch cluster
        return(NULL)
    } else {
        return(.process_alias(alias_string = resultContent))
    }
}

# [title] Process the string returned by the GET alias API into a data.table
# [alias_string] A string returned by the alias API with index and alias name
#' @importFrom data.table data.table
#' @importFrom utils read.table
.process_alias <- function(alias_string) {
    # process the string provided by the /_cat/aliases API into a data.frame and then a data.table
    aliasDT <- data.table::data.table(utils::read.table(text = alias_string, stringsAsFactors = FALSE))
    
    # return only the first two columns
    return(aliasDT[, .(alias = V1, index = V2)])
}
