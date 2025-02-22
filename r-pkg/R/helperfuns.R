# [title] Extract the content of an HTTP response into a different format
# [name] .content
# [description] Mainly here to making mocking easier in testing.
# [references] https://testthat.r-lib.org/reference/local_mocked_bindings.html#namespaced-calls
#' @importFrom jsonlite fromJSON
.content <- function(response, as) {
    text_content <- rawToChar(response$content)
    if (as == "text") {
        return(text_content)
    }

    # if not plain text, assume we want to parse JSON into an R list
    return(jsonlite::fromJSON(
        txt = text_content
        , simplifyVector = FALSE
        , simplifyDataFrame = FALSE
        , simplifyMatrix = FALSE
    ))
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

# [title] List out HTTP codes that should be treated as retryable
# [name] .should_retry
# [description] Here because {curl} doesn't ship a retry mechanism, so this library
#               implements its own.
.should_retry <- function(response) {
    retryable_error_codes <- c(
        # 408 - timeout
        408L
        # 422 - unprocessable entity
        , 422L
        # 425 - too early
        , 425L
        # 429 - too many requests
        , 429L
        # 500 - internal server error
        , 500L
        # 502 - bad gateway
        , 502L
        # 503 - service unavailable
        , 503L
        # 504 - gateway timeout
        , 504L
    )
    return(response$status_code %in% retryable_error_codes)
}

# [title] Execute an HTTP request and return the result
# [name] .request
# [description] Mainly here to making mocking easier in testing, but this
#               also centralizes the mechanism for HTTP request execution in one place.
# [references] https://testthat.r-lib.org/reference/local_mocked_bindings.html#namespaced-calls
#' @importFrom curl curl_fetch_memory handle_setheaders handle_setopt new_handle
.request <- function(verb, url, body, add_json_headers) {
    handle <- curl::new_handle()

    # set headers
    if (isTRUE(add_json_headers)) {
        curl::handle_setheaders(
            handle = handle
            , "Accept" = "application/json"
            , "Content-Type" = "application/json"
        )
    }

    # set HTTP method
    curl::handle_setopt(handle = handle, customrequest = verb)

    # add body
    if (!is.null(body)) {
        curl::handle_setopt(
            handle = handle
            , copypostfields = body
        )
    }

    # actually execute request
    result <- curl::curl_fetch_memory(
        url = url
        , handle = handle
    )

    # TODO(jameslamb): add retries
    return(result)
}

# [title] Raise an exception if an HTTP response indicates an error
# [name] .stop_for_status
# [description] 3xx, 4xx, and 5xx responses are treated as errors.
#               curl should automatically follow redirects (which is what most
#               3xx responses are), so if that's working well then this code should
#               never actually see a 3xx response.
.stop_for_status <- function(response) {
    if (response$status_code <= 300L) {
        return(invisible(NULL))
    }
    log_fatal(sprintf(
        "Request failed (status code %i): '%s %s'"
        , response$status_code
        , response$method
        , response$url
    ))
}
