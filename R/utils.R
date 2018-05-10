
# [title] assert_that wrapper
# [name] assert
# [description] When making an assertion you might call:
#   
#   \code{assertthat::assert_that(assertthat::is.date(x))}
#   
#   or something like that. This is an alias to \code{\link[assertthat]{assert_that}} to be used
#   for two benefits: \enumerate{
#     \item{This uses \code{\link{log_fatal}} instead of \code{\link{stop}} on failure}
#     \item{Much less clutter in the source code}
#   }
#' @importFrom assertthat see_if
.assert <- function(..., msg = NULL) {
    res <- assertthat::see_if(..., env = parent.frame(), msg = msg)
    if (res) {
        return(invisible(TRUE))
    } else {
        log_fatal(attr(res, "msg"))
    }
}
