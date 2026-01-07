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

# [title] Retry an HTTP requests a couple times (if necessary)
# [name] .retry
# [description] Implements exponential backoff with jitter, around failed requests.
#               See .should_retry() for details on which status codes are considered retryable.
#               This is here because {curl} does not have a built-in retry API.
#' @importFrom curl curl_fetch_memory
#' @importFrom stats runif
.retry <- function(handle, url, verbose) {

    max_retries <- 3L
    attempt_count <- 1L
    while (attempt_count <= max_retries) {

        # if this isn't the 1st attempt, apply backoff
        if (attempt_count > 1L) {
            # exponential backoff with jitter
            #
            #   1.45s + {jitter}
            #   2.10s + {jitter}
            #   3.05s + {jitter}
            #   etc., etc.
            #
            # ref: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
            sleep_seconds <- 1.45 ** (attempt_count - 1L) + stats::runif(n = 1L, min = 0.1, max = 0.5)
            if (isTRUE(verbose)) {
                .log_debug(sprintf("Sleeping for %.2f seconds before retrying.", sleep_seconds))
            }
            Sys.sleep(sleep_seconds)
        }

        # execute request
        response <- curl::curl_fetch_memory(
            url = url
            , handle = handle
        )

        # check if the response should be retried
        if (.should_retry(response)) {
            if (isTRUE(verbose)) {
                .log_debug(sprintf(
                    "Request failed (status code %i): '%s %s'"
                    , response$status_code
                    , response$method
                    , response$url
                ))
            }
            attempt_count <- attempt_count + 1L
        } else {
            break
        }
    }
    return(response)
}

# [title] Execute an HTTP request and return the result
# [name] .request
# [description] Mainly here to making mocking easier in testing, but this
#               also centralizes the mechanism for HTTP request execution in one place.
# [references] https://testthat.r-lib.org/reference/local_mocked_bindings.html#namespaced-calls
#' @importFrom curl handle_setheaders handle_setopt new_handle
.request <- function(verb, url, body, verbose) {
    handle <- curl::new_handle()

    # set headers
    #
    # This can safely be hard-coded here because every payload this library
    # posts and every response body it receives is JSON data.
    curl::handle_setheaders(
        handle = handle
        , "Accept" = "application/json"        # nolint[non_portable_path]
        , "Content-Type" = "application/json"  # nolint[non_portable_path]
    )

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
    response <- .retry(
        handle = handle
        , url = url
        , verbose = verbose
    )

    return(invisible(response))
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
    .log_fatal(sprintf(
        "Request failed (status code %i): '%s %s'"
        , response$status_code
        , response$method
        , response$url
    ))
}
