.log_debug <- function(msg) {
    write(sprintf("[DEBUG] %s", msg), stdout())
    return(invisible(NULL))
}

.log_info <- function(msg) {
    write(sprintf("[INFO] %s", msg), stdout())
    return(invisible(NULL))
}

.log_warn <- function(msg) {
    write(sprintf("[WARN] %s", msg), stdout())
    warning(msg)
    return(invisible(NULL))
}

.log_fatal <- function(msg) {
    write(sprintf("[FATAL] %s", msg), stdout())
    stop(msg)
}
