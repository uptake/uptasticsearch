#' @title Hits to data.tables
#' @name chomp_hits
#' @description A function for converting Elasticsearch docs into R data.tables. It
#'              uses \code{\link[jsonlite]{fromJSON}} with \code{flatten = TRUE} to convert a
#'              JSON into an R data.frame, and formats it into a data.table.
#' @importFrom jsonlite fromJSON
#' @importFrom data.table as.data.table setnames
#' @export
#' @param hits_json A character vector. If its length is greater than 1, its elements will be pasted
#'                  together. This can contain a JSON returned from a \code{search} query in
#'                  Elasticsearch, or a filepath or URL pointing at one.
#' @param keep_nested_data_cols a boolean (default TRUE); whether to keep columns that are nested
#'                              arrays in the original JSON. A warning will be given if these
#'                              columns are deleted.
#' @examples
#' # A sample raw result from a hits query:
#' result <- '[{"_source":{"timestamp":"2017-01-01","cust_name":"Austin","details":{
#' "cust_class":"big_spender","location":"chicago","pastPurchases":[{"film":"The Notebook",
#' "pmt_amount":6.25},{"film":"The Town","pmt_amount":8.00},{"film":"Zootopia","pmt_amount":7.50,
#' "matinee":true}]}}},{"_source":{"timestamp":"2017-02-02","cust_name":"James","details":{
#' "cust_class":"peasant","location":"chicago","pastPurchases":[{"film":"Minions",
#' "pmt_amount":6.25,"matinee":true},{"film":"Rogue One","pmt_amount":10.25},{"film":"Bridesmaids",
#' "pmt_amount":8.75},{"film":"Bridesmaids","pmt_amount":6.25,"matinee":true}]}}},{"_source":{
#' "timestamp":"2017-03-03","cust_name":"Nick","details":{"cust_class":"critic","location":"cannes",
#' "pastPurchases":[{"film":"Aala Kaf Ifrit","pmt_amount":0,"matinee":true},{
#' "film":"Dopo la guerra (Apres la Guerre)","pmt_amount":0,"matinee":true},{
#' "film":"Avengers: Infinity War","pmt_amount":12.75}]}}}]'
#'
#' # Chomp into a data.table
#' sampleChompedDT <- chomp_hits(hits_json = result, keep_nested_data_cols = TRUE)
#' print(sampleChompedDT)
#'
#' # (Note: use es_search() to get here in one step)
#'
#' # Unpack by details.pastPurchases
#' unpackedDT <- unpack_nested_data(chomped_df = sampleChompedDT
#'                                  , col_to_unpack = "details.pastPurchases")
#' print(unpackedDT)
chomp_hits <- function(hits_json = NULL, keep_nested_data_cols = TRUE) {

    # If nothing was passed to hits_json, return NULL and warn
    if (is.null(hits_json)) {
        msg <- "You did not pass any input data to chomp_hits. Returning NULL."
        .log_warn(msg)
        return(invisible(NULL))
    }

    if (!is.character(hits_json)) {
        msg <- paste0("The first argument of chomp_hits must be a character vector."
                      , "You may have passed an R list. In that case, if you already "
                      , "used jsonlite::fromJSON(), you can just call "
                      , "data.table::as.data.table().")
        .log_fatal(msg)
    }

    # Parse the input JSON to a list object
    jsonList <- jsonlite::fromJSON(hits_json, flatten = TRUE)

    # If this came from a raw query result, we need to grab the hits.hits element.
    # Otherwise, just assume we have a list of hits
    if (all(c("took", "timed_out", "_shards", "hits") %in% names(jsonList))) {
        batchDT <- data.table::as.data.table(jsonList[["hits"]][["hits"]])
    } else {
        batchDT <- data.table::as.data.table(jsonList)
    }

    # Strip "_source" from all the column names because blegh
    data.table::setnames(batchDT, gsub("_source.", "", names(batchDT), fixed = TRUE))

    # Warn the user if there's nested data
    colTypes <- sapply(batchDT, mode)
    if (any(colTypes == "list")) {
        if (keep_nested_data_cols) {
            msg <- paste(
                "Keeping the following nested data columns."
                , "Consider using unpack_nested_data for one:\n"
                , toString(names(colTypes)[colTypes == "list"])
            )
            .log_info(msg)
        } else {

            msg <- paste(
                "Deleting the following nested data columns:\n"
                , toString(names(colTypes)[colTypes == "list"])
            )
            .log_warn(msg)
            batchDT <- batchDT[, !names(colTypes[colTypes == "list"]), with = FALSE]
        }
    }

    return(batchDT)
}
