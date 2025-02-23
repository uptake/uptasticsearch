
# [title] assert something and raise an exception if it isn't true
# [name] .assert
# [description] If the condition passed to .assert() does not evaluate to TRUE,
#               issues a FATAL-level log message and then raises an R exception,
#               both with the content of `msg`.
.assert <- function(expr, msg) {
    res <- eval(expr, envir = parent.frame())
    if (isTRUE(res)) {
        return(invisible(TRUE))
    }
    .log_fatal(msg)
}

# [title] check if an object is a count
# [name] .is_count
# [description] Returns TRUE if `x` is a single positive integer
#               and FALSE otherwise.
.is_count <- function(x) {
    return(
        length(x) == 1 &&
            is.numeric(x) &&
            !is.na(x) &&
            x > 0 &&
            trunc(x) == x
    )
}

# [title] check if an object is a scalar logical
# [name] .is_flag
# [description] Returns TRUE if `x` is `TRUE` or `FALSE`
#               and `FALSE` otherwise.
.is_flag <- function(x) {
    return(
        is.logical(x) &&
            length(x) == 1L &&
            !is.na(x)
    )
}

# [title] check if an object is a string
# [name] .is_string
# [description] Returns TRUE if `x` is a non-empty string
#               and FALSE otherwise.
.is_string <- function(x) {
    return(
        is.character(x) &&
        length(x) == 1L &&
        !is.na(x) &&
        x != ""
    )
}

# [title] check if an object is a writeable filepath that exists
# [name] .is_writeable
# [description] Returns TRUE if `x` is a filepath that already exists
#               and is writeable, and FALSE otherwise.
.is_writeable <- function(x) {
    return(
        .is_string(x) &&
            file.exists(x) &&
            file.access(x, mode = 2L)[[1L]] == 0L
    )
}
