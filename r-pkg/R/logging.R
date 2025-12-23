.format_log_msg <- function(log_level, msg) {
    return(sprintf(
        "%s [%s] %s"
        , log_level
        , strftime(Sys.time(), format = "%Y-%m-%d %H:%M:%S")
        , msg
    ))
}

.log_debug <- function(msg) {
    write(.format_log_msg("DEBUG", msg), stdout())
    return(invisible(NULL))
}

.log_info <- function(msg) {
    write(.format_log_msg("INFO", msg), stdout())
    return(invisible(NULL))
}

.log_warn <- function(msg) {
    write(.format_log_msg("WARN", msg), stdout())
    warning(msg)
    return(invisible(NULL))
}

.log_fatal <- function(msg) {
    write(.format_log_msg("FATAL", msg), stdout())
    stop(msg)
}
