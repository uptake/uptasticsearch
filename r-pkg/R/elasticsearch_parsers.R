
#' @title Parse date-times from Elasticsearch records
#' @name parse_date_time
#' @description Given a data.table with date-time strings,
#'              this function converts those dates-times to type POSIXct with the appropriate
#'              time zone. Assumption is that dates are of the form "2016-07-25T22:15:19Z"
#'              where T is just a separator and the last letter is a military timezone.
#'              
#'              This is a side-effect-free function: it returns a new data.table and the
#'              input data.table is unmodified.
#' @importFrom data.table copy
#' @importFrom futile.logger flog.fatal
#' @importFrom purrr map2 simplify
#' @importFrom stringr str_extract
#' @export
#' @param input_df a data.table with one or more date-time columns you want to convert
#' @param date_cols Character vector of column names to convert. Columns should have
#'                string dates of the form "2016-07-25T22:15:19Z".
#' @param assume_tz Timezone to convert to if parsing fails. Default is UTC
#' @references \url{https://www.timeanddate.com/time/zones/military}
#' @references \url{https://en.wikipedia.org/wiki/List_of_tz_database_time_zones}
#' @examples
#' # Sample es_search(), chomp_hits(), or chomp_aggs() output:
#' someDT <- data.table::data.table(id = 1:5
#'                                  , company = c("Apple", "Apple", "Banana", "Banana", "Cucumber")
#'                                  , timestamp = c("2015-03-14T09:26:53B", "2015-03-14T09:26:54B"
#'                                                  , "2031-06-28T08:53:07Z", "2031-06-28T08:53:08Z"
#'                                                  , "2000-01-01"))
#'           
#' # Note that the date field is character right now
#' str(someDT)
#' 
#' # Let's fix that!
#' someDT <- parse_date_time(input_df = someDT
#'                           , date_cols = "timestamp"
#'                           , assume_tz = "UTC")
#' str(someDT)
parse_date_time <- function(input_df
                          , date_cols
                          , assume_tz = "UTC"
){
    
    # Break if input_df isn't actually a data.table
    if (!any(class(input_df) %in% "data.table")){
        msg <- paste("parse_date_time expects to receive a data.table object."
                     , "You provided an object of class"
                     , paste(class(input_df), collapse = ", ")
                     , "to input_df.")
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Break if date_cols is not a character vector
    if (!identical(class(date_cols), "character")) {
        msg <- paste("The date_cols argument in parse_date_time expects",
                     "a character vector of column names. You gave an object",
                     "of class", paste(class(date_cols), collapse = ", "))
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Break if any of the date_cols are not actually in this DT
    if (!all(date_cols %in% names(input_df))){
        not_there <- date_cols[!(date_cols %in% names(input_df))]
        msg <- paste("The following columns, which you passed to date_cols,",
                     "do not actually exist in input_df:",
                     paste(not_there, collapse = ", "))
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Work on a copy of the DT to avoid side effects
    outDT <- data.table::copy(input_df)
    
    # Map one-letter TZs to valid timezones to be passed to lubridate functions
    # Military (one-letter) times: 
    # Mapping UTC to etc --> https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    tzHash <- vector("character")
    tzHash["A"] <-  "Etc/GMT-1" # UTC +1
    tzHash["B"] <-  "Etc/GMT-2" # UTC +2
    tzHash["C"] <-  "Etc/GMT-3" # UTC +3
    tzHash["D"] <-  "Etc/GMT-4" # UTC +4
    tzHash["E"] <-  "Etc/GMT-5" # UTC +5
    tzHash["F"] <-  "Etc/GMT-6" # UTC +6
    tzHash["G"] <-  "Etc/GMT-7" # UTC +7
    tzHash["H"] <-  "Etc/GMT-8" # UTC +8
    tzHash["I"] <-  "Etc/GMT-9" # UTC +9
    tzHash["K"] <-  "Etc/GMT-10" # UTC +10
    tzHash["L"] <-  "Etc/GMT-11" # UTC +11
    tzHash["M"] <-  "Etc/GMT-12" # UTC +12
    tzHash["N"] <-  "Etc/GMT+1" # UTC -1
    tzHash["O"] <-  "Etc/GMT+2" # UTC -2
    tzHash["P"] <-  "Etc/GMT+3" # UTC -3
    tzHash["Q"] <-  "Etc/GMT+4" # UTC -4
    tzHash["R"] <-  "Etc/GMT+5" # UTC -5
    tzHash["S"] <-  "Etc/GMT+6" # UTC -6
    tzHash["T"] <-  "Etc/GMT+7" # UTC -7
    tzHash["U"] <-  "Etc/GMT+8" # UTC -8
    tzHash["V"] <-  "Etc/GMT+9" # UTC -9
    tzHash["W"] <-  "Etc/GMT+10" # UTC -10
    tzHash["X"] <-  "Etc/GMT+11" # UTC -11
    tzHash["Y"] <-  "Etc/GMT+12" # UTC -12
    tzHash["Z"] <-  "UTC" # UTC  
    
    # Parse dates, return POSIXct UTC dates
    for (dateCol in date_cols){
        
        # Grab this vector to work on
        dateVec <- outDT[[dateCol]]
        
        # Parse out timestamps and military timezone strings
        dateTimes <- paste0(stringr::str_extract(dateVec, "^\\d{4}-\\d{2}-\\d{2}"), " ",
                            stringr::str_extract(dateVec, "\\d{2}:\\d{2}:\\d{2}"))
        tzKeys <- stringr::str_extract(dateVec, "[A-Za-z]{1}$")
        
        # Grab a vector of timezones
        timeZones <- tzHash[tzKeys]
        timeZones[is.na(timeZones)] <- assume_tz
        
        # Combine the timestamp and timezone vector to convert to POSIXct
        dateTimes <- purrr::map2(dateTimes, timeZones, 
                                 function(dateTime, timeZone){as.POSIXct(dateTime, tz = timeZone)})
        utcDates  <- as.POSIXct.numeric(purrr::simplify(dateTimes), origin = "1970-01-01", tz = "UTC")
        
        # Put back in the data.table
        outDT[, (dateCol) := utcDates]
    }
    
    return(outDT)
}

#' @title Aggs query to data.table
#' @name chomp_aggs
#' @description Given some raw JSON from an aggs query in Elasticsearch, parse the
#'              aggregations into a data.table.
#' @importFrom futile.logger flog.warn flog.fatal
#' @importFrom jsonlite fromJSON
#' @importFrom data.table as.data.table setnames setcolorder
#' @export
#' @param aggs_json A character vector. If its length is greater than 1, its elements will be pasted 
#'        together. This can contain a JSON returned from an \code{aggs} query in Elasticsearch, or
#'        a filepath or URL pointing at one.
#' @examples
#' # A sample raw result from an aggs query combining date_histogram and extended_stats:
#' result <- '{"aggregations":{"dateTime":{"buckets":[{"key_as_string":"2016-12-01T00:00:00.000Z",
#' "key":1480550400000,"doc_count":123,"num_potatoes":{"count":120,"min":0,"max":40,"avg":15,
#' "sum":1800,"sum_of_squares":28000,"variance":225,"std_deviation":15,"std_deviation_bounds":{
#' "upper":26,"lower":13}}},{"key_as_string":"2017-01-01T00:00:00.000Z","key":1483228800000,
#' "doc_count":134,"num_potatoes":{"count":131,"min":0,"max":39,"avg":16,"sum":2096,
#' "sum_of_squares":34000,"variance":225,"std_deviation":15,"std_deviation_bounds":{"upper":26,
#' "lower":13}}}]}}}'
#' 
#' # Parse into a data.table
#' aggDT <- chomp_aggs(aggs_json = result)
#' print(aggDT)
chomp_aggs <- function(aggs_json = NULL) {
    
    # If nothing was passed to aggs_json, return NULL and warn
    if (is.null(aggs_json)) {
        msg <- "You did not pass any input data to chomp_aggs. Returning NULL."
        futile.logger::flog.warn(msg)
        warning(msg)
        return(NULL)
    }
    
    if (!("character" %in% class(aggs_json))) {
        msg <- paste0("The first argument of chomp_aggs must be a character vector."
                      , "You may have passed an R list. Try querying with uptasticsearch:::.search_request()")
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Parse the input JSON to a list object
    jsonList <- jsonlite::fromJSON(aggs_json, flatten = TRUE)
    
    # Get first agg name
    aggNames <- names(jsonList[["aggregations"]])      # should be length 1
    
    # Gross special-case handler for one-level extended_stats aggregation
    if (.IsExtendedStatsAgg(jsonList[["aggregations"]][[aggNames]])){
        futile.logger::flog.info("es_search is assuming that this result is a one-level 'extended_stats' result.")
        jsonList[["aggregations"]][[1]][["std_deviation_bounds.upper"]] <- jsonList[["aggregations"]][[1]][["std_deviation_bounds"]][["upper"]]
        jsonList[["aggregations"]][[1]][["std_deviation_bounds.lower"]] <- jsonList[["aggregations"]][[1]][["std_deviation_bounds"]][["lower"]]
        jsonList[["aggregations"]][[1]][["std_deviation_bounds"]] <- NULL
    } 
    
    # Gross special-case handler for one-level percentiles aggregation
    if (.IsPercentilesAgg(jsonList[["aggregations"]][[aggNames]])){
        futile.logger::flog.info("es_search is assuming that this result is a one-level 'percentiles' result.")
        
        # Replace names like `25.0` with something that will be easier for users to understand
        # Doing this changes column names like thing.values.25.0 to thing.percentile_25.0
        percValues <- jsonList[["aggregations"]][[aggNames]][["values"]]
        names(percValues) <- paste0("percentile_", names(percValues))
        jsonList[["aggregations"]][[aggNames]] <- percValues
    }
    
    if (.IsSigTermsAgg(jsonList[["aggregations"]][[aggNames]])){
        futile.logger::flog.info("es_search is assuming that this result is a one-level 'significant terms' result.")
        
        # We can grab that nested data.frame and break out right now
        outDT <- data.table::as.data.table(jsonList[["aggregations"]][[aggNames]][["buckets"]])
        data.table::setnames(outDT, 'key', aggNames)
        return(outDT)
    }
    
    # Get the data.table. One of these columns is a list of data.frames.
    outDT <- data.table::as.data.table(jsonList[["aggregations"]][[aggNames]])
    
    # Keep unpacking the nested arrays until you hit 'break'
    while(TRUE) {
        # Clean up the column names
        .clean_aggs_colnames(outDT)
        
        # Rename the key to the agg name on this level
        if ("key_as_string" %in% names(outDT)) {
            data.table::setnames(outDT, "key_as_string", aggNames[length(aggNames)])
            outDT <- outDT[, !"key", with = FALSE]
        } else {
            
            # Other bucketed aggregations (not date_histogram) will have "key"
            if ("key" %in% names(outDT)){
                data.table::setnames(outDT, "key", aggNames[length(aggNames)])
            } else {
                # If we get down here, we know it's not a bucketed aggregation
                # So we want to take like "count", "min", "max" and change them to 
                # e.g. "some_field.count", "some_field.min", "some_field.max"
                data.table::setnames(outDT, names(outDT), paste0(aggNames, ".", names(outDT)))
            }
        }
        
        # What types are the remaining columns? If one's a list, loop back again.
        colTypes <- sapply(outDT, mode)
        if (any(colTypes == "list")) {
            
            # Store the new agg name
            aggNames[length(aggNames) + 1] <- names(colTypes[colTypes == "list"])
            
            # Remove unwanted columns
            badCols <- grep("doc_count", names(outDT))
            if (length(badCols) > 0){
                outDT <- outDT[, !badCols, with = FALSE]
            }
            
            # Unpack the list column
            outDT <- unpack_nested_data(outDT, aggNames[length(aggNames)])
            
        } else {
            # Remove unwanted columns, but keep doc_count
            badCols <- base::setdiff(grep("doc_count", names(outDT), value = TRUE), "doc_count")
            if (length(badCols) > 0) {
                outDT <- outDT[, !badCols, with = FALSE]
            }
            break
        }
    }
    
    # Re-set the column order to mirror the way the user specified their aggs query
    # NOTE: If there's no "doc_count" in the names, we know that this was not a bucketed
    # / nested query and reordering is unnecessary
    if ("doc_count" %in% names(outDT)){
        data.table::setcolorder(outDT, c(aggNames
                                     , base::setdiff(names(outDT), c(aggNames, "doc_count"))
                                     , "doc_count"))
    }
    
    return(outDT)
    
}


# Cleans the column names of a data.table so they don't include ".buckets" or "buckets."
# Used in chomp_aggs. Call this by reference, not assignment.
#' @importFrom data.table setnames
.clean_aggs_colnames <- function(DT) {
    old <- grep("buckets", names(DT), value = TRUE)
    new <- gsub("\\.?buckets\\.?", "", old)
    data.table::setnames(DT, old, new)
}

# [name] .IsExtendedStatsAgg
# [description] Detect whether or not a particular aggregation result is a one-level
#               "extended_stats" aggregation. data.table doesn't handle those
#               in a way that's consistent with the way this package handles all other aggregations
# [param] aggsList R list-object representation of an "aggs" result from Elasticsearch
.IsExtendedStatsAgg <- function(aggsList){
    statsNames <- c("count", "min", "max", "avg", "sum", "sum_of_squares"
                    , "variance", "std_deviation", "std_deviation_bounds")
    
    return(all(statsNames %in% names(aggsList)))
}

# [name] .IsPercentilesAgg
# [description] Detect whether or not a particular aggregation result is a one-level
#               "Percentiles" aggregation. data.table doesn't handle those
#               in a way that's consistent with the way this package handles all other aggregations
# [param] aggsList R list-object representation of an "aggs" result from Elasticsearch
.IsPercentilesAgg <- function(aggsList){
    
    # check 1 - has a single element called "values"
    if (! identical("values", names(aggsList))){
        return(FALSE)
    }
    
    # check 2 - all names of "values" are convertible to numbers
    numNames <- as.numeric(names(aggsList[["values"]]))
    if (all(vapply(numNames, function(val){!is.na(val)}, FUN.VALUE = TRUE))){
        return(TRUE)
    } else {
        return(FALSE)
    }
}


# [name] .IsSigTermsAgg
# [description] Detect whether or not a particular aggregation result is a one-level
#               "significant terms" aggregation. data.table doesn't handle those
#               in a way that's consistent with the way this package handles all other aggregations
# [param] aggsList R list-object representation of an "aggs" result from Elasticsearch
.IsSigTermsAgg <- function(aggsList){
    
    # check 1 - has exactly two keys - "doc_count", "buckets"
    if (! identical(sort(names(aggsList)), c('buckets', 'doc_count'))){
        return(FALSE)
    }
    
    # check 2 - "buckets" is a data.frame 
    if (!"data.frame" %in% class(aggsList[['buckets']])){
        return(FALSE)
    }
    
    # check 3 - "buckets" has at least the columns "key", "doc_count", and "bg_count"
    if (!all(c('key', 'doc_count', 'bg_count') %in% names(aggsList[['buckets']]))){
        return(FALSE)
    }
    
    return(TRUE)
}


#' @title Unpack a nested data.table
#' @name unpack_nested_data
#' @description After calling a \code{chomp_*} function or \code{es_search}, if 
#'   you had a nested array in the JSON, its corresponding column in the 
#'   resulting data.table is a data.frame itself (or a list of vectors). This 
#'   function expands that nested column out, adding its data to the original 
#'   data.table, and duplicating metadata down the rows as necessary.
#'   
#'   This is a side-effect-free function: it returns a new data.table and the
#'   input data.table is unmodified.
#' @importFrom data.table copy as.data.table rbindlist setnames
#' @importFrom futile.logger flog.fatal
#' @export
#' @param chomped_df a data.table
#' @param col_to_unpack a character vector of length one: the column name to 
#'   unpack
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
unpack_nested_data <- function(chomped_df, col_to_unpack) {
    
    # Input checks
    if (!("data.table" %in% class(chomped_df))) {
        msg <- "For unpack_nested_data, chomped_df must be a data.table"
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    if (".id" %in% names(chomped_df)) {
        msg <- "For unpack_nested_data, chomped_df cannot have a column named '.id'"
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    if (!("character" %in% class(col_to_unpack)) || length(col_to_unpack) != 1) {
        msg <- "For unpack_nested_data, col_to_unpack must be a character of length 1"
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    if (!(col_to_unpack %in% names(chomped_df))) {
        msg <- "For unpack_nested_data, col_to_unpack must be one of the column names"
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Avoid side effects
    outDT <- data.table::copy(chomped_df)
    
    # Get the column to unpack
    listDT <- outDT[[col_to_unpack]]
    
    # Make each row a data.table
    listDT <- lapply(listDT, data.table::as.data.table)
    
    # Remove the empty ones... important, due to data.table 1.10.4 bug
    oldIDs <- which(sapply(listDT, nrow) != 0)
    listDT <- listDT[oldIDs]
    
    # Bind them together with an ID to match to the other data
    newDT <- data.table::rbindlist(listDT, fill = TRUE, idcol = TRUE)
    
    # If we tried to unpack an empty column, fail
    if (nrow(newDT) == 0) {
        msg <- "The column given to unpack_nested_data had no data in it."
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Fix the ID because we may have removed some empty elements due to that bug
    newDT[, .id := oldIDs[.id]]
    
    # Merge
    outDT[, .id := .I]
    outDT <- newDT[outDT, on = ".id"]
    
    # Remove the id column and the original column
    outDT <- outDT[, !c(".id", col_to_unpack), with = FALSE]
    
    # Rename unpacked column if it didn't get a name
    if ("V1" %in% names(outDT)) {
        data.table::setnames(outDT, "V1", col_to_unpack)
    }
    
    return(outDT)
    
}

#' @title Hits to data.tables
#' @name chomp_hits
#' @description
#' A generic function for converting Elasticsearch docs into R data.tables. It
#' uses \code{\link[jsonlite]{fromJSON}} with \code{flatten = TRUE} to convert a
#' JSON into an R data.frame, and formats it into a data.table.
#' @importFrom futile.logger flog.fatal flog.warn flog.info
#' @importFrom jsonlite fromJSON
#' @importFrom data.table as.data.table setnames
#' @export
#' @param hits_json A character vector. If its length is greater than 1, its elements will be pasted 
#'        together. This can contain a JSON returned from a \code{search} query in Elasticsearch, or
#'        a filepath or URL pointing at one.
#' @param keep_nested_data_cols a boolean (default TRUE); whether to keep columns that are nested
#'        arrays in the original JSON. A warning will be given if these columns are deleted.
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
        futile.logger::flog.warn(msg)
        warning(msg)
        return(NULL)
    }
    
    if (!("character" %in% class(hits_json))) {
        msg <- paste0("The first argument of chomp_hits must be a character vector."
                      , "You may have passed an R list. In that case, if you already "
                      , "used jsonlite::fromJSON(), you can just call "
                      , "data.table::as.data.table().")
        futile.logger::flog.fatal(msg)
        stop(msg)
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
    data.table::setnames(batchDT, old = names(batchDT), new = gsub("_source\\.", "", names(batchDT)))
    
    # Warn the user if there's nested data
    colTypes <- sapply(batchDT, mode)
    if (any(colTypes == "list")) {
        if (keep_nested_data_cols) {
            msg <- paste("Keeping the following nested data columns."
                         , "Consider using unpack_nested_data for one:\n"
                         , paste(names(colTypes)[colTypes == "list"]
                                 , collapse = ", "))
            futile.logger::flog.info(msg)
        } else {
            
            msg <- paste("Deleting the following nested data columns:\n"
                         , paste(names(colTypes)[colTypes == "list"]
                                 , collapse = ", "))
            futile.logger::flog.warn(msg)
            warning(msg)
            batchDT <- batchDT[, !names(colTypes[colTypes == "list"]), with = FALSE]
        }
    }
    
    return(batchDT)
}


#' @title Execute an ES query and get a data.table
#' @name es_search
#' @description Given a query and some optional parameters, \code{es_search} gets results 
#'              from HTTP requests to Elasticsearch and returns a data.table 
#'              representation of those results.
#' @param es_host A string identifying an Elasticsearch host. This should be of the form 
#'        \code{[transfer_protocol][hostname]:[port]}. For example, \code{'http://myindex.thing.com:9200'}.
#' @param es_index The name of an Elasticsearch index to be queried.
#' @param max_hits Integer. If specified, \code{es_search} will stop pulling data as soon as it has pulled this many hits.
#' @param size Number of records per page of results. See \href{https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-from-size.html}{Elasticsearch docs} for more.
#'             Note that this will be reset to 0 if you submit a \code{query_body} with
#'             an "aggs" request in it. Also see \code{max_hits}.
#' @param query_body String with a valid Elasticsearch query. Default is an empty query.
#' @param scroll How long should the scroll context be held open? This should be a
#'               duration string like "1m" (for one minute) or "15s" (for 15 seconds). 
#'               The scroll context will be refreshed every time you ask Elasticsearch
#'               for another record, so this parameter should just be the amount of 
#'               time you expect to pass between requests. See the 
#'               \href{https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html}{Elasticsearch scroll/pagination docs}
#'               for more information.
#' @param n_cores Number of cores to distribute fetching + processing over.
#' @param break_on_duplicates Boolean, defaults to TRUE. \code{es_search} uses the size of the final object it returns
#'                          to check whether or not some data were lost during the processing.
#'                          If you have duplicates in the source data, you will have to set this flag to
#'                          FALSE and just trust that no data have been lost. Sorry :( .
#' @param ignore_scroll_restriction There is a cost associated with keeping an 
#'                                Elasticsearch scroll context open. By default,
#'                                this function does not allow arguments to \code{scroll}
#'                                which exceed one hour. This is done to prevent
#'                                costly mistakes made by novice Elasticsearch users.
#'                                If you understand the cost of keeping the context
#'                                open for a long time and would like to pass a \code{scroll}
#'                                value longer than an hour, set \code{ignore_scroll_restriction}
#'                                to \code{TRUE}.
#' @param intermediates_dir When scrolling over search results, this function writes
#'        intermediate results to disk. By default, `es_search` will create a temporary
#'        directory in whatever working directory the function is called from. If you
#'        want to change this behavior, provide a path here. `es_search` will create 
#'        and write to a temporary directory under whatever path you provide.
#' @importFrom futile.logger flog.fatal flog.info
#' @importFrom parallel detectCores
#' @export
#' @examples
#' \dontrun{
#' 
#' ###=== Example 1: Get low-scoring food survey results ===###
#'
#' query_body <- '{"query":{"filtered":{"filter":{"bool":{"must":[
#'                {"exists":{"field":"customer_comments"}},
#'                {"terms":{"overall_satisfaction":["very low","low"]}}]}}},
#'                "query":{"match_phrase":{"customer_comments":"food"}}}}'
#' 
#' # Execute the query, parse into a data.table
#' commentDT <- es_search(es_host = 'http://mydb.mycompany.com:9200'
#'                        , es_index = "survey_results"
#'                        , query_body = query_body
#'                        , scroll = "1m"
#'                        , n_cores = 4)
#'                  
#' ###=== Example 2: Time series agg features ===###
#' 
#' # Create query that will give you daily summary stats for revenue
#' query_body <- '{"query":{"filtered":{"filter":{"bool":{"must":[
#'                {"exists":{"field":"pmt_amount"}}]}}}},
#'                "aggs":{"timestamp":{"date_histogram":{"field":"timestamp","interval":"day"},
#'                "aggs":{"revenue":{"extended_stats":{"field":"pmt_amount"}}}}},"size":0}'
#'                
#' # Execute the query and get the result
#' resultDT <- es_search(es_host = "http://es.custdb.mycompany.com:9200"
#'                       , es_index = 'ticket_sales'
#'                       , query_body = query_body)
#' }
es_search <- function(es_host
                      , es_index
                      , size = 10000
                      , query_body = '{}'
                      , scroll = "5m"
                      , max_hits = NULL
                      , n_cores = ceiling(parallel::detectCores()/2)
                      , break_on_duplicates = TRUE
                      , ignore_scroll_restriction = FALSE
                      , intermediates_dir = getwd()
){
    
    # Check if this is an aggs or straight-up search query
    if (length(query_body) > 1 || ! "character" %in% class(query_body)){
        msg <- sprintf(paste0("query_body should be a single string. ",
                              "You gave an object of length %s")
                       , length(query_body))
        futile.logger::flog.fatal(msg)
        stop(msg)
    }
    
    # Aggregation Request
    if (grepl('aggs', query_body)){
        
        # Let them know
        msg <- paste0("es_search detected that this is an aggs request ",
                      "and will only return aggregation results.")
        futile.logger::flog.info(msg)
        
        # Get result
        # NOTE: setting size to 0 so we don't spend time getting hits
        result <- .search_request(es_host = es_host
                                  , es_index = es_index
                                  , trailing_args = "size=0"
                                  , query_body = query_body)
        return(chomp_aggs(aggs_json = result))
    }
    
    # Normal search request
    futile.logger::flog.info("Executing search request")
    return(.fetch_all(es_host = es_host
                      , es_index = es_index
                      , size = size
                      , query_body = query_body
                      , scroll = scroll
                      , max_hits = max_hits
                      , n_cores = n_cores
                      , break_on_duplicates = break_on_duplicates
                      , intermediates_dir = intermediates_dir))
}

# [title] Use "scroll" in Elasticsearch to pull a large number of records
# [name] .fetch_all
# [description] Use the Elasticsearch scroll API to pull as many records as possible
#              matching a given Elasticsearch query, and format into a nice data.table.
# [param] es_host A string identifying an Elasticsearch host. This should be of the form 
#        [transfer_protocol][hostname]:[port]. For example, 'http://myindex.thing.com:9200'.
# [param] es_index The name of an Elasticsearch index to be queried.
# [param] size Number of records per page of results. See \href{https://www.elastic.co/guide/en/Elasticsearch/reference/current/search-request-from-size.html}{Elasticsearch docs} for more
# [param] query_body String with a valid Elasticsearch query to be passed to \code{\link[elastic]{Search}}.
#                  Default is an empty query.
# [param] scroll How long should the scroll context be held open? This should be a
#               duration string like "1m" (for one minute) or "15s" (for 15 seconds). 
#               The scroll context will be refreshed every time you ask Elasticsearch
#               for another record, so this parameter should just be the amount of 
#               time you expect to pass between requests. See the 
#               \href{https://www.elastic.co/guide/en/Elasticsearch/guide/current/scroll.html}{Elasticsearch scroll/pagination docs}
#               for more information.
# [param] max_hits Integer. If specified, \code{.fetch_all} will stop pulling data as soon as it passes this threshold.
# [param] n_cores Number of cores to distribute fetching + processing over.
# [param] break_on_duplicates Boolean, defaults to TRUE. \code{.fetch_all} uses the size of the final object it returns
#                          to check whether or not some data were lost during the processing.
#                          If you have duplicates in the source data, you will have to set this flag to
#                          FALSE and just trust that no data have been lost. Sorry :( .
# [param] ignore_scroll_restriction There is a cost associated with keeping an 
#                                Elasticsearch scroll context open. By default,
#                                this function does not allow arguments to \code{scroll}
#                                which exceed one hour. This is done to prevent
#                                costly mistakes made by novice Elasticsearch users.
#                                If you understand the cost of keeping the context
#                                open for a long time and would like to pass a \code{scroll}
#                                value longer than an hour, set \code{ignore_scroll_restriction}
#                                to \code{TRUE}.
# [param] intermediates_dir passed through from es_search. See es_search docs.
# [examples]
# \dontrun{
#
# #=== Example 1: Get every site whose name starts with a "J" ===#
#
# # Get every customer
# siteDT <- uptasticsearch:::.fetch_all(es_host = "http://es.custdb.mycompany.com:9200"
#                                       , es_index = "theaters"
#                                       , query_body = '{"query": {"wildcard": {"location_name" : {"value": "J*"}}}}'
#                                       , n_cores = 4)
# }
# [references ]
# See the links below for more information on how scrolling in Elasticsearch works
# and why certain design decisions were made in this function.
# \itemize{
# \item \href{https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html}{Elasticsearch documentation on scrolling search}
# \item \href{https://github.com/elastic/elasticsearch/issues/14954}{GitHub issue thread explaining why this function does not parallelize requests}
# \item \href{https://github.com/elastic/elasticsearch/issues/11419}{GitHub issue thread explaining common symptoms that the scroll_id has changed and you are not using the correct Id}
# \item \href{http://stackoverflow.com/questions/25453872/why-does-this-elasticsearch-scan-and-scroll-keep-returning-the-same-scroll-id}{More background on how/why Elasticsearch generates and changes the scroll_id}
# }
#' @importFrom data.table rbindlist setkeyv
#' @importFrom futile.logger flog.fatal
#' @importFrom httr POST content
#' @importFrom jsonlite fromJSON
#' @importFrom parallel clusterMap detectCores makeForkCluster makePSOCKcluster stopCluster
#' @importFrom uuid UUIDgenerate
.fetch_all <- function(es_host
                     , es_index
                     , size = 10000
                     , query_body = '{}'
                     , scroll = "5m"
                     , max_hits = NULL
                     , n_cores = ceiling(parallel::detectCores()/2)
                     , break_on_duplicates = TRUE
                     , ignore_scroll_restriction = FALSE
                     , intermediates_dir
){
    
    # Check es_host
    es_host <- .ValidateAndFormatHost(es_host)
    
    # Protect against costly scroll settings
    if (.ConvertToSec(scroll) > 60*60 & !ignore_scroll_restriction){
        msg <- paste0("By default, this function does not permit scroll requests ",
                      "which keep the scroll context open for more than one hour.\n",
                      "\nYou provided the following value to 'scroll': ",
                      scroll,
                      "\n\nIf you understand the costs and would like to make requests ",
                      "with a longer-lived context, re-run this function with ",
                      "ignore_scroll_restriction = TRUE.\n",
                      "\nPlease see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html ",
                      "for more information.")
        futile.logger::flog.fatal(msg)
        stop(msg)
    }

    # If max_hits < size, we should just request exactly that many hits
    # requesting more hits than you get is not costless:
    # - ES allocates a temporary data structure of size <size>
    # - you end up transmitting more data over the wire than the user wants
    if (!is.null(max_hits) && max_hits < size){
        msg <- paste0(sprintf("You requested a maximum of %s hits", max_hits),
                      sprintf(" and a page size of %s.", size),
                      sprintf(" Resetting size to %s for efficiency.", max_hits))
        futile.logger::flog.warn(msg)
        warning(msg)
        
        size <- max_hits
    }

    # Warn if you are gonna give back a few more hits than max_hits
    if (!is.null(max_hits) && max_hits %% size != 0){
        msg <- paste0("When max_hits is not an exact multiple of size, it is ",
                      "possible to get a few more than max_hits results back.")
        futile.logger::flog.warn(msg)
        warning(msg)
    }
    
    # Find a safe path to write to and create it
    repeat {
        out_path <- file.path(intermediates_dir, uuid::UUIDgenerate())
        if (!dir.exists(out_path)) {
            break
        }
    }
    dir.create(out_path)
    on.exit({
        unlink(out_path, recursive = TRUE)
    })
    
    ###===== Pull the first hit =====###
    
    # Get the first result as text
    firstResultJSON <- .search_request(es_host = es_host
                                     , es_index = es_index
                                     , trailing_args = paste0('size=', size, '&scroll=', scroll)
                                     , query_body = query_body)
    
    # Parse to JSON to get total number of documents matching the query
    firstResult <- jsonlite::fromJSON(firstResultJSON, simplifyVector = FALSE)
    hits_to_pull <- min(firstResult[["hits"]][["total"]], max_hits)
    
    # If we got everything possible, just return here
    hits_pulled <- length(firstResult[["hits"]][["hits"]])
    if (hits_pulled == hits_to_pull) {
        # Parse to data.table
        esDT <- chomp_hits(hits_json = firstResultJSON
                          , keep_nested_data_cols = TRUE)
        return(esDT)
    }
    
    # If we need to pull more stuff...grab the scroll Id from that first result
    scroll_id   <- enc2utf8(firstResult[["_scroll_id"]])
    
    # Write to disk
    write(x = firstResultJSON, file = file.path(out_path, paste0(uuid::UUIDgenerate(), ".json")))
    
    # Clean up memory
    rm("firstResult", "firstResultJSON")
    
    ###===== Pull the Rest of the Data =====###
    
    # Calculate number of hits to pull
    msg <- paste0("Total hits to pull: ", hits_to_pull)
    futile.logger::flog.info(msg)
    
    # Set up scroll_url (will be the same everywhere)
    scroll_url <- paste0(es_host, "/_search/scroll?scroll=", scroll)
    
    # Pull all the results (single-threaded)
    msg <- "Scrolling over additional pages of results..."
    futile.logger::flog.info(msg)
    .keep_on_pullin(scroll_id = scroll_id
                    , out_path = out_path
                    , max_hits = max_hits
                    , scroll_url = scroll_url
                    , hits_pulled = hits_pulled
                    , hits_to_pull = hits_to_pull)
    futile.logger::flog.info("Done scrolling over results.")
    
    
    futile.logger::flog.info("Reading and parsing pulled records...")
    
    # Find the temp files we wrote out above
    tempFiles <- list.files(path = out_path, pattern = "\\.json$", full.names = TRUE)
    
    # If the user requested 1 core, just run single-threaded.
    # Not worth the overhead of setting up the cluster.
    if (n_cores == 1){
        outDT <- data.table::rbindlist(
            lapply(tempFiles
                   , FUN = .read_and_parse_tempfile
                   , keep_nested_data_cols = TRUE)
            , fill = TRUE
            , use.names = TRUE
        )
    } else {
        
        # Set up cluster. Note that Fork clusters cannot be used on Windows
        if (grepl('windows', Sys.info()[['sysname']], ignore.case = TRUE)){
            cl <- parallel::makePSOCKcluster(names = n_cores)   
        } else {
            cl <- parallel::makeForkCluster(nnodes = n_cores)    
        }
        
        # Read in and parse all the files
        outDT <- data.table::rbindlist(
                    parallel::clusterMap(cl = cl
                                         , fun = .read_and_parse_tempfile
                                         , file_name = tempFiles
                                         , MoreArgs = c(keep_nested_data_cols = TRUE)
                                         , RECYCLE = FALSE
                                         , .scheduling = 'dynamic')
                    , fill = TRUE
                    , use.names = TRUE)
    
        # Close the connection
        parallel::stopCluster(cl)
    }
    
    futile.logger::flog.info("Done reading and parsing pulled records.")
    
    # It's POSSIBLE that the parallel process gave us duplicates. Correct for that
    data.table::setkeyv(outDT, NULL)
    outDT <- unique(outDT)
    
    # Check we got the number of unique records we expected
    if (nrow(outDT) < hits_to_pull && break_on_duplicates){
        errorMsg <- paste0("Some data was lost during parallel pulling + writing to disk.",
                           " Expected ", hits_to_pull, " records but only got ", nrow(outDT), ".",
                           " File collisions are unlikely but possible with this function.",
                           " Try increasing the value of the scroll param.", 
                           " Then try re-running and hopefully you won't see this error.")
        futile.logger::flog.fatal(errorMsg)
        stop(errorMsg)
    }
    
    return(outDT)
}


# [name] .read_and_parse_tempfile
# [description] Given a path to a .json file with a query result on disk,
#               read in the file and parse it into a data.table.
# [params] file_name Full path to a .json file with a query result
# [params] keep_nested_data_cols Boolean flag indicating whether or not to
#          preserver columns that could not be flattened in the result
#          data.table (i.e. live as arrays with duplicate keys in the result from ES)
.read_and_parse_tempfile <- function(file_name, keep_nested_data_cols){
    
    # NOTE: namespacing uptasticsearch here to prevent against weirdness
    #       when distributing this function to multiple workers in a cluster
    resultDT <- uptasticsearch::chomp_hits(paste0(readLines(file_name))
                                           , keep_nested_data_cols = keep_nested_data_cols)
    return(resultDT)
}

# [description] Given a scroll id generate with an Elasticsearch scroll search
#               request, this function will:
#                   - hit the scroll context to grab the next page of results
#                   - call chomp_hits to process that page into a data table
#                   - write that table to disk in .json format
#                   - return null
# [notes] When Elasticsearch receives a query w/ a scroll request, it does the following:
#                   - evaluates the query and scores all matching documents
#                   - creates a stack, where each item on the stack is one page of results
#                   - returns the first page + a scroll_id which uniquely identifies the stack
# [params] scroll_id   - a unique key identifying the search context 
#          out_path    - A file path to write temporary output to. Passed in from .fetch_all
#          max_hits    - max_hits, comes from .fetch_all. If left as NULL in your call to
#                       .fetch_all, this param has no influence and you will pull all the data.
#                       otherwise, this is used to limit the result size.
#          scroll_url  - Elasticsearch URL to hit to get the next page of data
#          hits_pulled - Number of hits pulled in the first batch of results. Used
#                       to keep a running tally for logging and in controlling
#                       execution when users pass an argument to max_hits
#          hits_to_pull - Total hits to be pulled (documents matching user's query).
#                       Or, in the case where max_hits < number of matching docs,
#                       max_hits.
#' @importFrom futile.logger flog.info
#' @importFrom httr content POST stop_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom uuid UUIDgenerate
.keep_on_pullin <- function(scroll_id
                            , out_path
                            , max_hits = Inf
                            , scroll_url
                            , hits_pulled
                            , hits_to_pull
){
    
    # Deal with case where user tries to say "don't limit me" by setting
    # max_hits = NULL explicitly
    if (is.null(max_hits)){
        max_hits <- Inf
    }
    
    while (hits_pulled < max_hits){
        
        # Grab a page of hits, break if we got back an error
        result  <- httr::POST(url = scroll_url, body = scroll_id)
        httr::stop_for_status(result)
        resultJSON  <- httr::content(result, as = "text")

        # Parse to JSON to get total number of documents + new scroll_id
        resultList <- jsonlite::fromJSON(resultJSON, simplifyVector = FALSE)
        
        # Break if we got nothing
        hitsInThisPage <- length(resultList[["hits"]][["hits"]])
        if (hitsInThisPage == 0){break}
        
        # If we have more to pull, get the new scroll_id
        # NOTE: http://stackoverflow.com/questions/25453872/why-does-this-elasticsearch-scan-and-scroll-keep-returning-the-same-scroll-id
        scroll_id <- resultList[['_scroll_id']]
        
        # Write out JSON to a temporary file
        write(x = resultJSON, file = file.path(out_path, paste0(uuid::UUIDgenerate(), ".json")))
        
        # Increment the count
        hits_pulled <- hits_pulled + hitsInThisPage
        
        # Tell the people
        msg <- sprintf('Pulled %s of %s results', hits_pulled, hits_to_pull)
        futile.logger::flog.info(msg)
        
    }
    
    return(NULL)
}

# [title] Check that a string is a valid host for an Elasticsearch cluster
# [param] A string of the form [transfer_protocol][hostname]:[port]. 
#         If any of those elements are missing, some defaults will be added
.ValidateAndFormatHost <- function(es_host){
    
    # [1] es_host is a string
    if (! "character" %in% class(es_host)){
        msg <- paste0("es_host should be a string! You gave an object of type"
                      , paste0(class(es_host), collapse = '/'))
        stop(msg)
    }
    
    # [2] es_host is length 1
    if (! length(es_host) == 1){
        msg <- paste0("es_host should be length 1!"
                      , " You provided an object of length "
                      , length(es_host))
        stop(msg)
    }
    
    # [3] Does not end in a slash
    trailingSlashPattern <- '/+$'
    if (grepl(trailingSlashPattern, es_host)){
        # Remove it
        es_host <- gsub('/+$', '', es_host)
    }
    
    # [4] es_host has a port number
    portPattern <- ':[0-9]+$'
    if (! grepl(portPattern, es_host) == 1){
        msg <- paste0('No port found in es_host! es_host should be a string of the'
                      , 'form [transfer_protocol][hostname]:[port]). for '
                      , 'example: "http://myindex.mysite.com:9200"')
        stop(msg)
    }
    
    # [4] es_host has a valid transfer protocol
    protocolPattern <- '^[A-Za-z]+://'
    if (! grepl(protocolPattern, es_host) == 1){
        msg <- paste0('You did not provide a transfer protocol (e.g. http://) with es_host.'
                      , 'Assuming http://...')
        warning(msg)
        
        # Doing this to avoid cases where you just missed a slash or something,
        # e.g. "http:/es.thing.com:9200" --> 'es.thing.com:9200'
        # This pattern should also catch IP hosts, e.g. '0.0.0.0:9200'
        hostWithoutPartialProtocol <- stringr::str_extract(es_host, '[[A-Za-z0-9]+\\.[A-Za-z0-9]+]+\\.[A-Za-z0-9]+:[0-9]+$')
        es_host <- paste0('http://', hostWithoutPartialProtocol)
    }
    
    return(es_host)
    
}


# [title] Execute a Search request against an Elasticsearch cluster
# [name] .search_request
# [description] Given a query string (JSON with valid DSL), execute a request
#              and return the JSON result as a string
# [param] es_host A string identifying an Elasticsearch host. This should be of the form 
#        [transfer_protocol][hostname]:[port]. For example, 'http://myindex.thing.com:9200'.
# [param] es_index The name of an Elasticsearch index to be queried.
# [param] trailing_args Arguments to be appended to the end of the request URL (optional).
#        For example, to limit the size of the returned results, you might pass
#        "size=0". This can be a single string or a character vector of params, e.g.
#        \code{c('size=0', 'scroll=5m')}
# [param] query_body A JSON string with valid Elasticsearch DSL
# [examples]
# \dontrun{
# 
# #==== Example 1: Fetch 100 sample docs ====#
# 
# # Get a batch of 100 documents
# result <- uptasticsearch:::.search_request(es_host = 'http://mysite.mydomain.com:9200'
#                                            , es_index = 'workorders'
#                                            , trailing_args = 'size=100'
#                                            , query_body = '{}')
#                         
#  # Write to disk
#  write(result, 'results.json')
#  
#  #==== Example 2: Aggregation Results ====#
#  
#  # We have an aggs query, so set size=0 to ignore raw recors
#  query_body <- "{'aggs':{'docType':{'terms': {'field': 'documentType'}}}}"
#  result <- uptasticsearch:::.search_request(es_host = 'http://mysite.mydomain.com:9200'
#                                             , es_index = 'workorders'
#                                             , trailing_args = 'size=0'
#                                             , query_body = query_body)
#
#  # Write to disk
#  write(result, 'results.json')
# 
# }
#' @importFrom httr content POST stop_for_status
.search_request <- function(es_host
                          , es_index
                          , trailing_args = NULL
                          , query_body = '{}'
){
    
    # Input checking
    es_host <- .ValidateAndFormatHost(es_host)
    
    # Build URL
    reqURL <- paste0(es_host, '/', es_index, '/_search')
    if (!is.null(trailing_args)){
        reqURL <- paste0(reqURL, '?', paste0(trailing_args, collapse = "&"))
    }
    
    # Make request
    result <- httr::POST(url = reqURL, body = query_body)
    httr::stop_for_status(result)
    result <- httr::content(result, as = "text")
    
    return(result)
    
}

# [name] ConvertToSec
# [title] Convert a datemath string to duration in seconds
# [description] Given a string that could be passed as a datemath expression to
#               Elasticsearch (e.g. "2m"), parse it and return numerical value
#               in seconds
# [param] timeString (character) A string of the form "<number><time_unit>" (e.g. "21d", "15h").
#                   Currently, "s", "m", "h", "d", and "w" are supported
# [export]
# [examples]
# \dontrun{
# #--- Example 1: Basic Usage ---#
# .ConvertToSec('1h') # returns 60*60 = 3600
# .ConvertToSec('15m') # returns 60*15 = 900
# }
#' @importFrom futile.logger flog.fatal
#' @importFrom stringr str_extract
.ConvertToSec <- function(duration_string) {
    
    # Grab string from the end (e.g. "2d" --> "d")
    timeUnit <- stringr::str_extract(duration_string, '[A-Za-z]+$')
    
    # Grab numeric component
    timeNum <- as.numeric(gsub(timeUnit, '', duration_string))
    
    # Convert numeric value to seconds
    timeInSeconds <- switch(timeUnit
                            , 's' = timeNum
                            , 'm' = timeNum * 60
                            , 'h' = timeNum * 60 * 60
                            , 'd' = timeNum * 60 * 60 * 24
                            , 'w' = timeNum * 60 * 60 * 24 * 7
                            , {
                                msg <- paste0('Could not figure out units of datemath ',
                                              'string! Only durations in seconds (s), ',
                                              'minutes (m), hours (h), days (d), or weeks (w) ',
                                              'are supported. You provided: ',
                                              duration_string)
                                futile.logger::flog.fatal(msg)
                                stop(msg)
                            }
                           )
                            
    return(timeInSeconds)
}
