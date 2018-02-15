# Globals to make R CMD check not spit out "no visible binding for global 
#   variable" notes.
# Basically, R CMD check doesn't like it when you don't quote the "V1" in
#   a call like DT[, V1].
# See: http://stackoverflow.com/a/12429344
# Also: see hadley's comments on his own post there. They're great.

utils::globalVariables(c('.'
                         , '.I'
                         , '.id'
                         , 'field'
                         , 'index'
                         , 'V1'
                         , 'V2'
                       ))


# NULL object for common parameter documentation
#' @param es_host A string identifying an Elasticsearch host. This should be of the form 
#'        \code{[transfer_protocol][hostname]:[port]}. For example, \code{'http://myindex.thing.com:9200'}. 
#' @param es_index The name of an Elasticsearch index to be queried. 
#' @name doc_shared
#' @title NULL Object For Common Documentation
#' @description This is a NULL object with documentation so that later functions can call
#' inheritParams
NULL
