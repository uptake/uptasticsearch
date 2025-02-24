# [title] remove system indices from a character of index names
# [name] .remove_system_indices
# [description] Character vector of Elasticsearch indices
#               Those are considered internal implementation details of Elasticsearch,
#               but show up in a couple of APIs (namely 'GET /_cat/indices').
.remove_system_indices <- function(indices) {
    # references:
    #
    #   * why this exists: https://github.com/uptake/uptasticsearch/pull/245/files#r1960918283
    #   * list of system indices: https://github.com/elastic/elasticsearch/issues/50251
    #
    #
    # It might be possible for non-system index names to start with a ".", so this might
    # miss some things. Tried to address that with the warning message below. This seems more
    # resilient to changing Elasticsearch versions than enumerating all of the patterns for
    # all of the system indices.
    system_indices <- indices[startsWith(indices, ".")]

    # no system indices found in list, just return early
    if (length(system_indices) == 0L) {
        return(indices)
    }

    .log_warn(paste0(
        "Excluding the following indices assumed to be internal 'system' indices: ["
        , toString(indices)
        , "]. To suppress this warning and/or to query these indices, pass a vector of index names "  # nolint[non_portable_path]
        , "through 'es_indices' argument explicitly, instead of '_all'."
    ))
    return(setdiff(indices, system_indices))
}

#' @title Get the names and data types of the indexed fields in an index
#' @name get_fields
#' @description For a given Elasticsearch index, return the mapping from field name
#'              to data type for all indexed fields.
#' @importFrom data.table := as.data.table rbindlist uniqueN
#' @importFrom jsonlite fromJSON
#' @importFrom purrr map2
#' @param es_indices A character vector that contains the names of indices for
#'                   which to get mappings. Default is \code{'_all'}, which means
#'                   get the mapping for all indices. Names of indices can be
#'                   treated as regular expressions.
#' @inheritParams doc_shared
#' @export
#' @return A data.table containing four columns: index, type, field, and data_type
#' @examples
#' \dontrun{
#' # get the mapping for all indexed fields in the ticket_sales and customers indices
#' mappingDT <- get_fields(es_host = "http://es.custdb.mycompany.com:9200"
#'                               , es_indices = c("ticket_sales", "customers"))
#' }
get_fields <- function(es_host
                       , es_indices = "_all"
) {

    # Input checking
    es_url <- .ValidateAndFormatHost(es_host)

    # other input checks with simple error messages
    .assert(
        is.character(es_indices) && length(es_indices) > 0
        , "Argument 'es_indices' must be a non-empty character vector"
    )

    # collapse character vectors into comma separated strings. If any arguments
    # are NULL, create an empty string
    indices <- paste(es_indices, collapse = ",")

    if (nchar(indices) == 0) {
        msg <- paste("get_fields must be passed a valid es_indices."
                     , "You provided", toString(es_indices)
                     , "which resulted in an empty string")
        .log_fatal(msg)
    }

    major_version <- .get_es_version(
        es_host = es_host
    )

    # The use of "_all" to indicate "all indices" was removed in Elasticsearch 7.
    if (as.integer(major_version) > 6 && indices == "_all") {
        .log_warn(sprintf(
            paste0(
                "You are running Elasticsearch version '%s.x'. _all is not supported in this version."
                , " Pulling all indices with 'GET /_cat/indices' for you."  # nolint[non_portable_path]
            )
            , major_version
        ))
        res <- .request(
            verb = "GET"
            , url = sprintf("%s/_cat/indices?format=json", es_url)
            , body = NULL
        )
        indexDT <- data.table::as.data.table(
            jsonlite::fromJSON(
                .content(res, as = "text")
                , simplifyDataFrame = TRUE
            )
        )
        indices <- .remove_system_indices(indexDT[, unique(index)])
        indices <- paste(indices, collapse = ",")
    }

    ########################## build the query ################################
    es_url <- sprintf("%s/%s/_mapping", es_url, indices)  # nolint[non_portable_path]

    ########################## make the query ################################
    .log_info(paste("Getting indexed fields for indices:", indices))

    result <- .request(
        verb = "GET"
        , url = es_url
        , body = NULL
    )
    .stop_for_status(result)
    resultContent <- .content(result, as = "parsed")

    ######################### flatten the result ##############################
    if (as.integer(major_version) > 6) {
        # As of Elasticsearch 7, indices cannot contain multiple types so the concept of
        # a "type" in a mapping is irrelevant. Maintaining the field here
        # for backwards compatibility of this function.
        mappingDT <- data.table::rbindlist(
            l = lapply(
                X = names(resultContent)
                , FUN = function(index_name) {
                    props <- resultContent[[index_name]][["mappings"]][["properties"]]
                    thisIndexDT <- data.table::data.table(
                        index = index_name
                        , type = NA_character_
                        , field = names(props)
                        , data_type = sapply(props, function(x) {x$type})  # nolint[open_curly]
                    )
                    return(thisIndexDT)
                }
            )
            , fill = TRUE
        )
    } else {
        mappingDT <- .flatten_mapping(mapping = resultContent)
    }

    ##################### get aliases for index names #########################
    rawAliasDT <- .get_aliases(es_host = es_host)
    if (!is.null(rawAliasDT)) {

        .log_info("Replacing index names with aliases")

        # duplicate the mapping results for every alias. Idea is that you should be able to rely
        # on the results of get_fields to programmatically generate queries, and you should have a
        # preference for hitting aliases over straight-up index name
        aliasDT <- data.table::rbindlist(
            purrr::map2(
                .x = rawAliasDT[["index"]]
                , .y = rawAliasDT[["alias"]]
                , .f = function(idx_name, alias_name, mappingDT) {
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
    .log_info(paste("Retrieved", numFields, "fields across", numIndex, "indices"))

    return(mappingDT)
}

# [title] Flatten a mapping list of field name to data type into a data.table
# [mapping] A list of json that is returned from a request to the mappings API
#' @importFrom data.table := data.table setnames
#' @importFrom stringr str_split_fixed str_replace_all
.flatten_mapping <- function(mapping) {

    ######################### parse the result ###############################
    # flatten the list object that is returned from the query
    flattened <- unlist(mapping)

    # the names of the flattened object has the index, type, and field name
    # however, it also has extra terms that we can use to split the name
    # into three distinct parts
    mappingCols <- stringr::str_split_fixed(names(flattened), "\\.(mappings|properties)\\.", n = 3)

    # convert to data.table and add the data type column
    mappingDT <- data.table::data.table(
        meta = mappingCols
        , data_type = as.character(flattened)
    )
    newColNames <- c("index", "type", "field", "data_type")
    data.table::setnames(mappingDT, newColNames)

    # remove any rows where the field does not end in ".type" to remove meta info
    mappingDT <- mappingDT[endsWith(field, ".type")]

    # mappings in nested objects have sub-fields called properties
    # mappings of fields that are indexed in different ways have multiple fields
    # we want to remove these terms from the field name
    metaRegEx <- "\\.(properties|fields|type)"
    mappingDT[, field := stringr::str_replace_all(field, metaRegEx, "")]

    return(mappingDT)
}

# [title] Get a data.table containing names of indices and aliases
# [es_host] A string identifying an Elasticsearch host.
#' @importFrom data.table as.data.table
#' @importFrom jsonlite fromJSON
.get_aliases <- function(es_host) {

    # construct the url to the alias endpoint
    url <- paste0(es_host, "/_cat/aliases")  # nolint[absolute_path, non_portable_path]

    # make the request
    result <- .request(
        verb = "GET"
        , url = url
        , body = NULL
    )
    .stop_for_status(result)
    resultContent <- .content(result, as = "text")

    # NOTES:
    # - with Elasticsearch 1.7.2., this returns an empty array "[]"
    # - with Elasticsearch 6, this results in an empty string instead of a NULL
    if (is.null(resultContent) || identical(resultContent, "") || identical(resultContent, "[]")) {
        # there are no aliases in this Elasticsearch cluster
        return(invisible(NULL))
    } else {
        aliasDT <- data.table::as.data.table(
            jsonlite::fromJSON(
                resultContent
                , simplifyDataFrame = TRUE
                , flatten = TRUE
            )
        )
        return(aliasDT[, .(alias, index)])
    }
}
