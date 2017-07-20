
#' @title Examine the distribution of distinct values for a field in Elasticsearch
#' @name get_counts
#' @description For a given field, return a data table with its unique values in a time range.
#' @importFrom data.table := data.table setnames setkeyv
#' @importFrom httr content POST
#' @importFrom purrr transpose
#' @export
#' @param field A valid field in whatever Elasticsearch index you are querying
#' @param es_host A string identifying an Elasticsearch host. This should be of the form 
#'        \code{[transfer_protocol][hostname]:[port]}. For example, \code{'http://myindex.thing.com:9200'}.
#' @param es_index The name of an Elasticsearch index to be queried.
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
    result     <- httr::POST(url = searchURL, body = aggsQuery)
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
    result      <- httr::POST(url = searchURL, body = missingQuery)
    numMissings <- httr::content(result, as = "parsed")[["hits"]][["total"]]
    
    # Return now if user asked to only see NAs if there are any
    if (numMissings == 0 && use_na == "ifany"){
        return(resultDT)
    }
    
    # Append count of NAs to the data table
    naDT <- data.table::data.table(keyval = NA, count = numMissings)
    
    # Reformat
    data.table::setnames(naDT, "keyval", field)
    
    # Return
    return(rbind(naDT, resultDT))
    
}

#' @title Retrieve the mapping definitions for an index or index/type in Elasticsearch
#' @name retrieve_mapping
#' @description For one or multiple index or index/type, return a data table with
#'              field names and types.
#' @importFrom httr GET, content
#' @importFrom futile.logger flog.fatal
#' @param es_host A string identifying an Elasticsearch host. This should be of
#'                the form \code{[transfer_protocol][hostname]:[port]}. For example,
#'                \code{'http://myindex.thing.com:9200'}.
#' @param es_index A character vector that contains the names of indices for
#'                 which to get mappings. Default, is \code{'_all'}, which means
#'                 get the mapping for all indices.
#' @param es_type A character vector that contains the names of types for which
#'                to get mappings. Default is \code{NULL}, which means get the
#'                mapping for all types in the chosen indices.
#' @param es_field A character vector that contains the names of fields for which
#'                 to get mappings, which can be used when the entire mapping is
#'                 not desired. Default is \code{NULL}, which means get the
#'                 mapping for all fields in the chosen types.
#' @export
#' @return A data table containing the field - definition mapping for the selected
#'         indices, types, and fields
retrieve_mapping <- function(es_host
                             , es_index = '_all'
                             , es_type = NULL
                             , es_field = NULL
) {
    
    # Input checking
    url <- .ValidateAndFormatHost(es_host)
    
    # collapse character vectors into comma separated strings. If any arguments
    # are NULL, create an empty string
    indices <- paste(es_index, collapse = ',')
    types <- paste(es_type, collapse = ',')
    fields <- paste(es_field, collapse = ',')
    
    # build the query
    if (nchar(indices) > 0) {
        url <- paste(url, indices, '_mapping', sep = '/')
    } else {
        msg <- paste("retrive_mapping must be passed a valid es_index."
                     , "You provided", paste(es_index, collapse = ', ')
                     , 'which resulted in an empty string')
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    if (nchar(types) > 0) {
        url <- paste(url, types, sep = '/')
    }
    
    if (nchar(fields) > 0) {
        url <- paste(url, 'field', fields, sep = '/')
    }
    
    # make the query
    result <- httr::GET(url = url)
    resultContent <- httr::content(result)
    
    # parse the result into a data table
    
}










