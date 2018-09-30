#' @title Parse date-times from Elasticsearch records
#' @name parse_date_time
#' @description Given a data.table with date-time strings,
#'              this function converts those dates-times to type POSIXct with the appropriate
#'              time zone. Assumption is that dates are of the form "2016-07-25T22:15:19Z"
#'              where T is just a separator and the last letter is a military timezone.
#'
#'              This is a side-effect-free function: it returns a new data.table and the
#'              input data.table is unmodified.
#' @importFrom assertthat is.string
#' @importFrom data.table copy
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
        log_fatal(msg)
    }

    # Break if date_cols is not a character vector
    if (!identical(class(date_cols), "character")) {
        msg <- paste("The date_cols argument in parse_date_time expects",
                     "a character vector of column names. You gave an object",
                     "of class", paste(class(date_cols), collapse = ", "))
        log_fatal(msg)
    }

    # Break if any of the date_cols are not actually in this DT
    if (!all(date_cols %in% names(input_df))){
        not_there <- date_cols[!(date_cols %in% names(input_df))]
        msg <- paste("The following columns, which you passed to date_cols,",
                     "do not actually exist in input_df:",
                     paste(not_there, collapse = ", "))
        log_fatal(msg)
    }

    # Other input checks we don't have explicit error messages for
    .assert(
        assertthat::is.string(assume_tz)
        , assume_tz != ""
    )

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
        dateTimes <- purrr::map2(
            dateTimes
            , timeZones
            , function(dateTime, timeZone){as.POSIXct(dateTime, tz = timeZone)}
        )

        utcDates <- as.POSIXct.numeric(
            purrr::simplify(dateTimes)
            , origin = "1970-01-01"
            , tz = "UTC"
        )

        # Put back in the data.table
        outDT[, (dateCol) := utcDates]
    }

    return(outDT)
}
