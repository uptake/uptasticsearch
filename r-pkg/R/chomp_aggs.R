#' @title Aggs query to data.table
#' @name chomp_aggs
#' @description Given some raw JSON from an aggs query in Elasticsearch, parse the
#'              aggregations into a data.table.
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
#' @return A data.table representation of the result or NULL if the aggregation result is empty.
chomp_aggs <- function(aggs_json = NULL) {

    # If nothing was passed to aggs_json, return NULL and warn
    if (is.null(aggs_json)) {
        msg <- "You did not pass any input data to chomp_aggs. Returning NULL."
        log_warn(msg)
        return(invisible(NULL))
    }

    if (!("character" %in% class(aggs_json))) {
        msg <- paste0("The first argument of chomp_aggs must be a character vector."
                      , "You may have passed an R list. Try querying with uptasticsearch:::.search_request()")
        log_fatal(msg)
    }

    # Parse the input JSON to a list object
    jsonList <- jsonlite::fromJSON(aggs_json, flatten = TRUE)

    # Get first agg name
    aggNames <- names(jsonList[["aggregations"]])
    assertthat::assert_that(
        assertthat::is.string(aggNames)
        , msg = "aggregations are expected to have a single user-assigned name. This is a malformed aggregations response."
    )

    # Gross special-case handler for one-level extended_stats aggregation
    if (.IsExtendedStatsAgg(jsonList[["aggregations"]][[aggNames]])){
        log_info("es_search is assuming that this result is a one-level 'extended_stats' result.")
        jsonList[["aggregations"]][[1]][["std_deviation_bounds.upper"]] <- jsonList[["aggregations"]][[1]][["std_deviation_bounds"]][["upper"]]
        jsonList[["aggregations"]][[1]][["std_deviation_bounds.lower"]] <- jsonList[["aggregations"]][[1]][["std_deviation_bounds"]][["lower"]]
        jsonList[["aggregations"]][[1]][["std_deviation_bounds"]] <- NULL
    }

    # Gross special-case handler for one-level percentiles aggregation
    if (.IsPercentilesAgg(jsonList[["aggregations"]][[aggNames]])){
        log_info("es_search is assuming that this result is a one-level 'percentiles' result.")

        # Replace names like `25.0` with something that will be easier for users to understand
        # Doing this changes column names like thing.values.25.0 to thing.percentile_25.0
        percValues <- jsonList[["aggregations"]][[aggNames]][["values"]]
        names(percValues) <- paste0("percentile_", names(percValues))
        jsonList[["aggregations"]][[aggNames]] <- percValues
    }

    if (.IsSigTermsAgg(jsonList[["aggregations"]][[aggNames]])){
        log_info("es_search is assuming that this result is a one-level 'significant terms' result.")

        # We can grab that nested data.frame and break out right now
        outDT <- data.table::as.data.table(jsonList[["aggregations"]][[aggNames]][["buckets"]])
        data.table::setnames(outDT, 'key', aggNames)
        return(outDT)
    }

    # check for an empty result
    if (identical(jsonList[["aggregations"]][[aggNames]][["buckets"]], list())){
        log_info("this aggregation result was empty. Returning NULL")
        return(invisible(NULL))
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
                data.table::setnames(outDT, paste0(aggNames, ".", names(outDT)))
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
        data.table::setcolorder(
            outDT,
            c(aggNames, base::setdiff(names(outDT), c(aggNames, "doc_count")), "doc_count")
        )
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
