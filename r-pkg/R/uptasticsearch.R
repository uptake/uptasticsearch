# Globals to make R CMD check not spit out "no visible binding for global
#   variable" notes.
# Basically, R CMD check doesn't like it when you don't quote the "V1" in
#   a call like DT[, V1].
# See: http://stackoverflow.com/a/12429344
# Also: see hadley's comments on his own post there. They're great.

utils::globalVariables(c(
    "."
    , ".I"
    , ".id"
    , "alias"
    , "field"
    , "index"
    , "V1"
    , "V2"
))


# NULL object for common parameter documentation
#' @param es_host A string identifying an Elasticsearch host. This should be of the form
#'        \code{[transfer_protocol][hostname]:[port]}. For example, \code{'http://myindex.thing.com:9200'}.
#' @param es_index The name of an Elasticsearch index to be queried. Note that passing
#'                 \code{NULL} is not supported. Technically, not passing an index
#'                 to Elasticsearch is legal and results in searching over all indexes.
#'                 To be sure that this very expensive query is not executed by accident,
#'                 uptasticsearch forbids this. If you want to execute a query over
#'                 all indexes in the cluster, set this argument to \code{"_all"}.
#' @param verbose \code{TRUE} if verbose logs should be printed. \code{FALSE} by default.
#' @name doc_shared
#' @title NULL Object For Common Documentation
#' @description This is a NULL object with documentation so that later functions can call
#'              inheritParams
#' @keywords internal
NULL
