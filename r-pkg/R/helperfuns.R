# [title] Extract the content of an HTTP response into a different format
# [name] .content
# [description] Mainly here to making mocking easier in testing.
# [references] https://testthat.r-lib.org/reference/local_mocked_bindings.html#namespaced-calls
#' @importFrom httr content
.content <- function(response, as) {
    return(httr::content(response, as = as))
}

# [title] Get a random length-n string
# [name] .random_string
# [description] Get a random length-n string of lowercase letters.
#               Note that this uses sample() and so might produce deterministic
#               results in programs where set.seed() is used to control randomness.
.random_string <- function(num_characters) {
    return(
        paste(
            sample(letters, replace = TRUE, size = num_characters)
            , collapse = ""
        )
    )
}

# [title] Execute an HTTP request and return the result
# [name] .request
# [description] Mainly here to making mocking easier in testing, but this
#               also centralizes the mechanism for HTTP request exexcution in one place.
# [references] https://testthat.r-lib.org/reference/local_mocked_bindings.html#namespaced-calls
#' @importFrom httr add_headers RETRY
.request <- function(verb, url, headers, body) {
    result <- httr::RETRY(
        verb = verb
        , url = url
        , config = httr::add_headers(.headers = headers)
        , body = body
    )
    return(result)
}

# [title] Raise an exception if an HTTP response indicates an error
# [name] .stop_for_status
# [description] Mainly here to making mocking easier in testing.
# [references] https://testthat.r-lib.org/reference/local_mocked_bindings.html#namespaced-calls
#' @importFrom httr stop_for_status
.stop_for_status <- function(response) {
    httr::stop_for_status(response)
    return(invisible(NULL))
}
