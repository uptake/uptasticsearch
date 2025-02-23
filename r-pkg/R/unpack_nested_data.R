#' @title Unpack a nested data.table
#' @name unpack_nested_data
#' @description After calling a \code{chomp_*} function or \code{es_search}, if
#'              you had a nested array in the JSON, its corresponding column in the
#'              resulting data.table is a data.frame itself (or a list of vectors). This
#'              function expands that nested column out, adding its data to the original
#'              data.table, and duplicating metadata down the rows as necessary.
#'
#'              This is a side-effect-free function: it returns a new data.table and the
#'              input data.table is unmodified.
#' @importFrom data.table as.data.table copy is.data.table rbindlist setnames
#' @importFrom purrr map_if map_lgl map_int
#' @export
#' @param chomped_df a data.table
#' @param col_to_unpack a character vector of length one: the column name to unpack
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
unpack_nested_data <- function(chomped_df, col_to_unpack)  {

    # Input checks
    if (!data.table::is.data.table(chomped_df)) {
        msg <- "For unpack_nested_data, chomped_df must be a data.table"
        .log_fatal(msg)
    }
    if (!.is_string(col_to_unpack)) {
        msg <- "For unpack_nested_data, col_to_unpack must be a character of length 1"
        .log_fatal(msg)
    }
    if (!(col_to_unpack %in% names(chomped_df))) {
        msg <- "For unpack_nested_data, col_to_unpack must be one of the column names"
        .log_fatal(msg)
    }

    inDT <- data.table::copy(chomped_df)

    # Define a column name to store original row ID
    repeat {
        joinCol <- .random_string(36L)
        if (!(joinCol %in% names(inDT))) {
            break
        }
    }
    inDT[, (joinCol) := .I]

    # Take out the packed column
    listDT <- inDT[[col_to_unpack]]
    inDT[, (col_to_unpack) := NULL]

    # Check for empty column
    if (all(purrr::map_int(listDT, NROW) == 0)) {
        msg <- "The column given to unpack_nested_data had no data in it."
        .log_fatal(msg)
    }

    listDT[lengths(listDT) == 0] <- NA

    is_df <- purrr::map_lgl(listDT, is.data.frame)
    is_list <- purrr::map_lgl(listDT, is.list)
    is_atomic <- purrr::map_lgl(listDT, is.atomic)
    is_na <- is.na(listDT)

    # Bind packed column into one data.table
    if (all(is_atomic)) {
        newDT <- data.table::as.data.table(unlist(listDT))
        newDT[, (joinCol) := rep(seq_along(listDT), lengths(listDT))]
    } else if (all(is_df | is_list | is_na)) {
        # Find name to use for NA columns
        first_df <- min(which(is_df))
        col_name <- names(listDT[[first_df]])[1]

        .prep_na_row <- function(x, col_name) {
            x <- data.table::as.data.table(x)
            names(x) <- col_name
            return(x)
        }

        # If the packed column contains data.tables, we use rbindlist
        newDT <- purrr::map_if(listDT, is_na, .prep_na_row, col_name = col_name)
        newDT <- data.table::rbindlist(newDT, fill = TRUE, idcol = joinCol)
    } else {
        msg <- paste0("Each row in column ", col_to_unpack, " must be a data frame or a vector.")
        .log_fatal(msg)
    }

    # Join it back in
    outDT <- inDT[newDT, on = joinCol]
    outDT[, (joinCol) := NULL]

    # In the case of all atomic...
    if ("V1" %in% names(outDT)) {
        data.table::setnames(outDT, "V1", col_to_unpack)
    }

    return(outDT)
}
