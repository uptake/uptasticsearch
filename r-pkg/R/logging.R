#' @importFrom futile.logger flog.debug
.log_debug <- function(...) {
    futile.logger::flog.debug(...)
}

#' @importFrom futile.logger flog.info
.log_info <- function(...) {
    futile.logger::flog.info(...)
}

#' @importFrom futile.logger flog.warn
.log_warn <- function(...) {
    futile.logger::flog.warn(...)
    warning(...)
}

#' @importFrom futile.logger flog.fatal
.log_fatal <- function(...) {
    futile.logger::flog.fatal(...)
    stop(...)
}
