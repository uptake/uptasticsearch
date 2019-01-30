
#' @title Execute an ES query and get a data.table
#' @name es_search
#' @description Given a query and some optional parameters, \code{es_search} gets results
#'              from HTTP requests to Elasticsearch and returns a data.table
#'              representation of those results.
#' @param max_hits Integer. If specified, \code{es_search} will stop pulling data as soon
#'                 as it has pulled this many hits. Default is \code{Inf}, meaning that
#'                 all possible hits will be pulled.
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
#' @param n_cores Number of cores to distribute fetching and processing over.
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
#' @inheritParams doc_shared
#' @importFrom assertthat is.count is.flag is.number is.string is.writeable
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
#' @references \href{https://www.elastic.co/guide/en/elasticsearch/reference/6.x/search-request-scroll.html}{ES 6 scrolling strategy}
es_search <- function(es_host
                      , es_index
                      , size = 10000
                      , query_body = '{}'
                      , scroll = "5m"
                      , max_hits = Inf
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
        log_fatal(msg)
    }

    # prevent NULL index
    if (is.null(es_index)){
        msg <- paste0(
            "You passed NULL to es_index. This is not supported. If you want to "
            , "search across all indices, use es_index = '_all'."
        )
        log_fatal(msg)
    }

    # assign 1 core by default, if the number of cores is NA
    if (is.na(n_cores) || !assertthat::is.count(n_cores)){
      msg <- "detectCores() returned NA. Assigning number of cores to be 1."
      log_warn(msg)
      n_cores <- 1
    }

    # Other input checks we don't have explicit error messages for
    .assert(
        assertthat::is.string(es_host)
        , es_host != ""
        , assertthat::is.string(es_index)
        , es_index != ""
        , assertthat::is.string(query_body)
        , query_body != ""
        , assertthat::is.string(scroll)
        , scroll != ""
        , max_hits >= 0
        , assertthat::is.count(n_cores)
        , n_cores >= 1
        , assertthat::is.flag(break_on_duplicates)
        , !is.na(break_on_duplicates)
        , assertthat::is.flag(ignore_scroll_restriction)
        , !is.na(ignore_scroll_restriction)
        , assertthat::is.string(intermediates_dir)
        , assertthat::is.writeable(intermediates_dir)
    )

    # Aggregation Request
    if (grepl('aggs', query_body)){

        # Let them know
        msg <- paste0("es_search detected that this is an aggs request ",
                      "and will only return aggregation results.")
        log_info(msg)

        # Get result
        # NOTE: setting size to 0 so we don't spend time getting hits
        result <- .search_request(
            es_host = es_host
            , es_index = es_index
            , trailing_args = "size=0"
            , query_body = query_body
        )

        return(chomp_aggs(aggs_json = result))
    }

    # Normal search request
    log_info("Executing search request")
    return(.fetch_all(es_host = es_host
                      , es_index = es_index
                      , size = size
                      , query_body = query_body
                      , scroll = scroll
                      , max_hits = max_hits
                      , n_cores = n_cores
                      , break_on_duplicates = break_on_duplicates
                      , ignore_scroll_restriction = ignore_scroll_restriction
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
# [param] max_hits Integer. If specified, \code{es_search} will stop pulling data as soon
#                  as it has pulled this many hits. Default is \code{Inf}, meaning that
#                  all possible hits will be pulled.
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
#' @importFrom httr RETRY content
#' @importFrom jsonlite fromJSON
#' @importFrom parallel clusterMap makeForkCluster makePSOCKcluster stopCluster
#' @importFrom uuid UUIDgenerate
.fetch_all <- function(es_host
                     , es_index
                     , size
                     , query_body
                     , scroll
                     , max_hits
                     , n_cores
                     , break_on_duplicates
                     , ignore_scroll_restriction
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
        log_fatal(msg)
    }

    # If max_hits < size, we should just request exactly that many hits
    # requesting more hits than you get is not costless:
    # - ES allocates a temporary data structure of size <size>
    # - you end up transmitting more data over the wire than the user wants
    if (max_hits < size) {
        msg <- paste0(sprintf("You requested a maximum of %s hits", max_hits),
                      sprintf(" and a page size of %s.", size),
                      sprintf(" Resetting size to %s for efficiency.", max_hits))
        log_warn(msg)

        size <- max_hits
    }

    # Warn if you are gonna give back a few more hits than max_hits
    if (!is.infinite(max_hits) && max_hits %% size != 0) {
        msg <- paste0("When max_hits is not an exact multiple of size, it is ",
                      "possible to get a few more than max_hits results back.")
        log_warn(msg)
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
    firstResultJSON <- .search_request(
        es_host = es_host
        , es_index = es_index
        , trailing_args = paste0('size=', size, '&scroll=', scroll)
        , query_body = query_body
    )

    # Parse to JSON to get total number of documents matching the query
    firstResult <- jsonlite::fromJSON(firstResultJSON, simplifyVector = FALSE)
    hits_to_pull <- min(firstResult[["hits"]][["total"]], max_hits)

    # If we got everything possible, just return here
    hits_pulled <- length(firstResult[["hits"]][["hits"]])

    if (hits_pulled == 0) {
      msg <- paste0('Query is syntactically valid but 0 documents were matched. '
                    , 'Returning NULL')
      log_warn(msg)
      return(invisible(NULL))
    }

    if (hits_pulled == hits_to_pull) {
        # Parse to data.table
        esDT <- chomp_hits(
            hits_json = firstResultJSON
            , keep_nested_data_cols = TRUE
        )
        return(esDT)
    }

    # If we need to pull more stuff...grab the scroll Id from that first result
    scroll_id <- enc2utf8(firstResult[["_scroll_id"]])

    # Write to disk
    write(x = firstResultJSON, file = file.path(out_path, paste0(uuid::UUIDgenerate(), ".json")))

    # Clean up memory
    rm("firstResult", "firstResultJSON")

    ###===== Pull the Rest of the Data =====###

    # Calculate number of hits to pull
    msg <- paste0("Total hits to pull: ", hits_to_pull)
    log_info(msg)

    # Pull all the results (single-threaded)
    msg <- "Scrolling over additional pages of results..."
    log_info(msg)
    .keep_on_pullin(
        scroll_id = scroll_id
        , out_path = out_path
        , max_hits = max_hits
        , es_host = es_host
        , scroll = scroll
        , hits_pulled = hits_pulled
        , hits_to_pull = hits_to_pull
    )

    log_info("Done scrolling over results.")

    log_info("Reading and parsing pulled records...")

    # Find the temp files we wrote out above
    tempFiles <- list.files(
        path = out_path
        , pattern = "\\.json$"
        , full.names = TRUE
    )

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
            parallel::clusterMap(
                cl = cl
                , fun = .read_and_parse_tempfile
                , file_name = tempFiles
                , MoreArgs = c(keep_nested_data_cols = TRUE)
                , RECYCLE = FALSE
                , .scheduling = 'dynamic'
            )
            , fill = TRUE
            , use.names = TRUE
        )

        # Close the connection
        parallel::stopCluster(cl)
    }

    log_info("Done reading and parsing pulled records.")

    # It's POSSIBLE that the parallel process gave us duplicates. Correct for that
    data.table::setkeyv(outDT, NULL)
    outDT <- unique(outDT, by = "_id")

    # Check we got the number of unique records we expected
    if (nrow(outDT) < hits_to_pull && break_on_duplicates){
        msg <- paste0("Some data was lost during parallel pulling + writing to disk.",
                      " Expected ", hits_to_pull, " records but only got ", nrow(outDT), ".",
                      " File collisions are unlikely but possible with this function.",
                      " Try increasing the value of the scroll param.",
                      " Then try re-running and hopefully you won't see this error.")
        log_fatal(msg)
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
    resultDT <- uptasticsearch::chomp_hits(
        paste0(readLines(file_name))
        , keep_nested_data_cols = keep_nested_data_cols
    )
    return(resultDT)
}

# [description] Given a scroll id generate with an Elasticsearch scroll search
#               request, this function will:
#                   - hit the scroll context to grab the next page of results
#                   - call chomp_hits to process that page into a data.table
#                   - write that table to disk in .json format
#                   - return null
# [notes] When Elasticsearch receives a query w/ a scroll request, it does the following:
#                   - evaluates the query and scores all matching documents
#                   - creates a stack, where each item on the stack is one page of results
#                   - returns the first page + a scroll_id which uniquely identifies the stack
# [params] scroll_id   - a unique key identifying the search context
#          out_path    - A file path to write temporary output to. Passed in from .fetch_all
#          max_hits    - max_hits, comes from .fetch_all. If left as Inf in your call to
#                       .fetch_all, this param has no influence and you will pull all the data.
#                       otherwise, this is used to limit the result size.
#          es_host     - Elasticsearch hostname
#          scroll      - How long should the scroll context be held open?
#          hits_pulled - Number of hits pulled in the first batch of results. Used
#                       to keep a running tally for logging and in controlling
#                       execution when users pass an argument to max_hits
#          hits_to_pull - Total hits to be pulled (documents matching user's query).
#                       Or, in the case where max_hits < number of matching docs,
#                       max_hits.
#' @importFrom httr add_headers content RETRY stop_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom uuid UUIDgenerate
.keep_on_pullin <- function(scroll_id
                            , out_path
                            , max_hits
                            , es_host
                            , scroll
                            , hits_pulled
                            , hits_to_pull
){

    # Note that the old scrolling strategy was deprecated in ES5.x and
    # officially dropped in ES6.x. Need to grab the correct method here
    major_version <- .get_es_version(es_host)
    scrolling_request <- switch(
        major_version
        , "1" = .legacy_scroll_request
        , "2" = .legacy_scroll_request
        , "5" = .new_scroll_request
        , "6" = .new_scroll_request
        , .new_scroll_request
    )

    while (hits_pulled < max_hits){

        # Grab a page of hits, break if we got back an error.
        result <- scrolling_request(
            es_host = es_host
            , scroll = scroll
            , scroll_id = scroll_id
        )
        httr::stop_for_status(result)
        resultJSON <- httr::content(result, as = "text")

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
        log_info(msg)

    }

    return(invisible(NULL))
}


# [title] Make a scroll request with the strategy supported by ES 5.x and later
# [name] .new_scroll_request
# [description] Make a scrolling request and return the result
# [references] https://www.elastic.co/guide/en/elasticsearch/reference/6.x/search-request-scroll.html
#' @importFrom httr add_headers RETRY
.new_scroll_request <- function(es_host, scroll, scroll_id){

    # Set up scroll_url
    scroll_url <- paste0(es_host, "/_search/scroll")

    # Get the next page
    result <- httr::RETRY(
        verb = "POST"
        , httr::add_headers(c('Content-Type' = 'application/json'))
        , url = scroll_url
        , body = sprintf('{"scroll": "%s", "scroll_id": "%s"}', scroll, scroll_id)
    )
    return(result)
}

# [title] Make a scroll request with the strategy supported by ES 1.x and ES 2.x
# [name] .legacy_scroll_request
# [description] Make a scrolling request and return the result
#' @importFrom httr add_headers RETRY
.legacy_scroll_request <- function(es_host, scroll, scroll_id){

    # Set up scroll_url
    scroll_url <- paste0(es_host, "/_search/scroll?scroll=", scroll)

    # Get the next page
    result <- httr::RETRY(
        verb = "POST"
        , httr::add_headers(c('Content-Type' = 'application/json'))
        , url = scroll_url
        , body = scroll_id
    )
    return(result)
}


# [title] Check that a string is a valid host for an Elasticsearch cluster
# [param] A string of the form [transfer_protocol][hostname]:[port].
#         If any of those elements are missing, some defaults will be added
.ValidateAndFormatHost <- function(es_host){

    # [1] es_host is a string
    if (! "character" %in% class(es_host)){
        msg <- paste0("es_host should be a string! You gave an object of type"
                      , paste0(class(es_host), collapse = '/'))
        log_fatal(msg)
    }

    # [2] es_host is length 1
    if (! length(es_host) == 1){
        msg <- paste0("es_host should be length 1!"
                      , " You provided an object of length "
                      , length(es_host))
        log_fatal(msg)
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
        log_fatal(msg)
    }

    # [4] es_host has a valid transfer protocol
    protocolPattern <- '^[A-Za-z]+://'
    if (! grepl(protocolPattern, es_host) == 1){
        msg <- paste0('You did not provide a transfer protocol (e.g. http://) with es_host.'
                      , 'Assuming http://...')
        log_warn(msg)

        # Doing this to avoid cases where you just missed a slash or something,
        # e.g. "http:/es.thing.com:9200" --> 'es.thing.com:9200'
        # This pattern should also catch IP hosts, e.g. '0.0.0.0:9200'
        hostWithoutPartialProtocol <- stringr::str_extract(es_host, '[[A-Za-z0-9]+\\.[A-Za-z0-9]+]+\\.[A-Za-z0-9]+:[0-9]+$')
        es_host <- paste0('http://', hostWithoutPartialProtocol)
    }

    return(es_host)
}


# [title] Get ES cluster version
# [name] .get_es_version
# [description] Hit the cluster and figure out the major
#               version of Elasticsearch.
# [param] es_host A string identifying an Elasticsearch host. This should be of the form
#         [transfer_protocol][hostname]:[port]. For example, 'http://myindex.thing.com:9200'.
#' @importFrom httr content RETRY stop_for_status
.get_es_version <- function(es_host){

    # Hit the cluster root to get metadata
    log_info("Checking Elasticsearch version...")
    result <- httr::RETRY(
        verb = "GET"
        , httr::add_headers(c('Content-Type' = 'application/json'))
        , url = es_host
    )
    httr::stop_for_status(result)

    # Extract version number from the result
    version <- httr::content(result, as = "parsed")[["version"]][["number"]]
    log_info(sprintf("uptasticsearch thinks you are running Elasticsearch %s", version))

    # Parse out just the major version. We can adjust this if we find
    # API differences that occured at the minor version level
    major_version <- .major_version(version)
    return(major_version)
}


# [title] parse version string
# [name] .major_version
# [description] Get major version from a dot-delimited version string
# [param] version_string A dot-delimited version string
#' @importFrom stringr str_split
.major_version <- function(version_string){
    components <- stringr::str_split(version_string, "\\.")[[1]]
    return(components[1])
}


# [title] Execute a Search request against an Elasticsearch cluster
# [name] .search_request
# [description] Given a query string (JSON with valid DSL), execute a request
#               and return the JSON result as a string
# [param] es_host A string identifying an Elasticsearch host. This should be of the form
#        [transfer_protocol][hostname]:[port]. For example, 'http://myindex.thing.com:9200'.
# [param] es_index The name of an Elasticsearch index to be queried.
# [param] trailing_args Arguments to be appended to the end of the request URL (optional).
#         For example, to limit the size of the returned results, you might pass
#         "size=0". This can be a single string or a character vector of params, e.g.
#         \code{c('size=0', 'scroll=5m')}
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
#' @importFrom httr add_headers content RETRY stop_for_status
.search_request <- function(es_host
                          , es_index
                          , trailing_args = NULL
                          , query_body
){

    # Input checking
    es_host <- .ValidateAndFormatHost(es_host)

    # Build URL
    reqURL <- paste0(es_host, '/', es_index, '/_search')
    if (!is.null(trailing_args)){
        reqURL <- paste0(reqURL, '?', paste0(trailing_args, collapse = "&"))
    }

    # Make request
    result <- httr::RETRY(
        verb = "POST"
        , httr::add_headers(c('Content-Type' = 'application/json'))
        , url = reqURL
        , body = query_body
    )
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
#' @importFrom stringr str_extract
.ConvertToSec <- function(duration_string) {

    # Grab string from the end (e.g. "2d" --> "d")
    timeUnit <- stringr::str_extract(duration_string, '[A-Za-z]+$')

    # Grab numeric component
    timeNum <- as.numeric(gsub(timeUnit, '', duration_string))

    # Convert numeric value to seconds
    timeInSeconds <- switch(
        timeUnit
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
            log_fatal(msg)
        }
    )

    return(timeInSeconds)
}
