.bojapi_max_pages <- 1000L
.bojapi_max_retry_after <- 60

boj_request <- function(endpoint, params, timeout) {
  url <- paste0(.bojapi_base_url, "/", endpoint)
  package_version <- tryCatch(
    as.character(utils::packageVersion("bojapi")),
    error = function(e) "development"
  )

  request <- httr2::request(url)
  request <- do.call(httr2::req_url_query, c(list(request), params))
  request <- httr2::req_headers(request, `Accept-Encoding` = "gzip")
  request <- httr2::req_user_agent(
    request,
    paste0("bojapi/", package_version, " (R; +https://github.com/kenjimyzk/bojapi)")
  )
  request <- httr2::req_timeout(request, seconds = timeout)
  request <- httr2::req_error(request, is_error = function(resp) FALSE)

  request
}

boj_perform <- function(request) {
  httr2::req_perform(request)
}

boj_fetch_json <- function(endpoint, params, timeout, retries, wait) {
  timeout <- boj_scalar_number(timeout, "timeout", min = 0)
  retries <- boj_scalar_number(retries, "retries", min = 0, integer = TRUE)
  wait <- boj_scalar_number(wait, "wait", min = 0)

  max_tries <- as.integer(retries) + 1L
  transient_http <- c(408L, 429L, 500L, 502L, 503L, 504L)

  for (attempt in seq_len(max_tries)) {
    request <- boj_request(endpoint, params, timeout)
    result <- tryCatch(
      list(response = boj_perform(request), error = NULL),
      error = function(e) list(response = NULL, error = e)
    )
    if (!is.null(result$error)) {
      if (attempt < max_tries) {
        boj_retry_pause(response = NULL, attempt = attempt, wait = wait)
        next
      }
      boj_abort(
        paste0("The BOJ API request failed: ", conditionMessage(result$error)),
        class = "boj_http_error",
        parent = result$error,
        endpoint = endpoint
      )
    }

    response <- result$response
    http_status <- httr2::resp_status(response)
    if (http_status %in% transient_http && attempt < max_tries) {
      boj_retry_pause(response = response, attempt = attempt, wait = wait)
      next
    }

    payload <- tryCatch(
      httr2::resp_body_json(response, check_type = FALSE, simplifyVector = FALSE),
      error = function(e) {
        error_class <- if (http_status >= 400L) "boj_http_error" else "boj_parse_error"
        boj_abort(
          paste0("The BOJ API returned an unreadable JSON response: ", conditionMessage(e)),
          class = error_class,
          parent = e,
          endpoint = endpoint,
          http_status = http_status
        )
      }
    )
    api_status <- boj_response_status(payload, endpoint, http_status)
    if (api_status %in% c(500L, 503L) && attempt < max_tries) {
      boj_retry_pause(response = response, attempt = attempt, wait = wait)
      next
    }

    boj_check_response(payload, endpoint = endpoint)
    if (http_status >= 400L) {
      boj_abort(
        sprintf("The BOJ API returned HTTP status %s.", http_status),
        class = "boj_http_error",
        endpoint = endpoint,
        http_status = http_status
      )
    }
    return(payload)
  }

  boj_abort("The BOJ API retry loop ended unexpectedly.", class = "boj_http_error", endpoint = endpoint)
}

boj_response_status <- function(payload, endpoint, http_status = NA_integer_) {
  error_class <- if (
    length(http_status) == 1L && !is.na(http_status) && http_status >= 400L
  ) {
    "boj_http_error"
  } else {
    "boj_parse_error"
  }
  abort_invalid <- function(message) {
    boj_abort(
      message,
      class = error_class,
      endpoint = endpoint,
      http_status = http_status
    )
  }

  if (!is.list(payload) || is.null(names(payload))) {
    abort_invalid("The BOJ API response must be a JSON object.")
  }

  status_index <- which(names(payload) == "STATUS")
  if (length(status_index) == 0L) {
    abort_invalid("The BOJ API response does not contain a STATUS field.")
  }
  if (length(status_index) > 1L) {
    abort_invalid("The BOJ API response must contain exactly one STATUS field.")
  }

  raw_status <- payload[[status_index]]
  if (length(raw_status) != 1L) {
    abort_invalid("The BOJ API STATUS field must contain exactly one value.")
  }
  if (!is.numeric(raw_status) && !is.character(raw_status)) {
    abort_invalid(
      "The BOJ API STATUS field must be a finite whole number or its character representation."
    )
  }

  numeric_status <- suppressWarnings(as.numeric(raw_status))
  if (
    is.na(numeric_status) || !is.finite(numeric_status) ||
      numeric_status != floor(numeric_status)
  ) {
    abort_invalid(
      "The BOJ API STATUS field must be a finite whole number or its character representation."
    )
  }
  status <- suppressWarnings(as.integer(numeric_status))
  if (is.na(status)) {
    abort_invalid("The BOJ API STATUS field is outside the supported integer range.")
  }
  status
}

boj_retry_pause <- function(response, attempt, wait) {
  retry_after <- NA_real_
  if (!is.null(response)) {
    retry_after <- suppressWarnings(as.numeric(httr2::resp_header(response, "retry-after")))
  }
  if (is.na(retry_after) || !is.finite(retry_after) || retry_after < 0) {
    retry_after <- 0
  }
  if (retry_after > .bojapi_max_retry_after) {
    boj_abort(
      sprintf(
        "The BOJ API requested a Retry-After delay of %s seconds, exceeding the safety limit of %s seconds.",
        retry_after,
        .bojapi_max_retry_after
      ),
      class = "boj_http_error",
      retry_after = retry_after,
      retry_after_limit = .bojapi_max_retry_after
    )
  }
  exponential <- min(8, 2^(attempt - 1L))
  jitter <- if (wait > 0) stats::runif(1L, 0, min(0.25, wait / 4)) else 0
  boj_pause(max(wait, retry_after, exponential) + jitter)
}

boj_check_response <- function(payload, endpoint) {
  status <- boj_response_status(payload, endpoint)
  if (status != 200L) {
    message_id <- boj_response_text(payload, "MESSAGEID", "")
    api_message <- boj_response_text(payload, "MESSAGE", "Unknown BOJ API error")
    boj_abort(
      sprintf("BOJ API error %s (%s): %s", status, message_id, api_message),
      class = "boj_api_response_error",
      status = status,
      message_id = message_id,
      api_message = api_message,
      endpoint = endpoint
    )
  }
  invisible(payload)
}

boj_response_text <- function(payload, field, default) {
  value <- payload[[field]]
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    return(default)
  }
  value
}

boj_next_position <- function(payload, endpoint) {
  raw_next <- payload$NEXTPOSITION
  if (is.null(raw_next) || length(raw_next) == 0L || identical(raw_next, "")) {
    return(NULL)
  }
  if (
    length(raw_next) != 1L ||
      (!is.numeric(raw_next) && !is.character(raw_next)) ||
      is.na(raw_next)
  ) {
    boj_abort(
      "The BOJ API returned an invalid NEXTPOSITION value.",
      class = "boj_pagination_error",
      endpoint = endpoint
    )
  }

  next_position <- as.character(raw_next)
  if (!grepl("^[1-9][0-9]*$", next_position)) {
    boj_abort(
      "The BOJ API returned an invalid NEXTPOSITION value.",
      class = "boj_pagination_error",
      next_position = next_position,
      endpoint = endpoint
    )
  }
  next_position
}

boj_fetch_pages <- function(endpoint, params, wait, timeout, retries) {
  result <- list()
  next_position <- NULL
  seen_positions <- character()
  request_number <- 0L

  repeat {
    if (request_number >= .bojapi_max_pages) {
      boj_abort(
        sprintf(
          "The BOJ API pagination exceeded the safety limit of %s pages; the response may not be terminating.",
          .bojapi_max_pages
        ),
        class = "boj_pagination_error",
        endpoint = endpoint,
        pages = request_number,
        page_limit = .bojapi_max_pages,
        next_position = next_position
      )
    }
    if (request_number > 0L) {
      boj_pause(wait)
    }
    request_params <- params
    if (!is.null(next_position)) {
      request_params$startPosition <- next_position
    }

    payload <- boj_fetch_json(
      endpoint = endpoint,
      params = request_params,
      timeout = timeout,
      retries = retries,
      wait = wait
    )
    request_number <- request_number + 1L

    page <- payload$RESULTSET %||% list()
    if (!is.list(page)) {
      boj_abort("The BOJ API RESULTSET field is not an array.", class = "boj_parse_error", endpoint = endpoint)
    }
    result <- c(result, page)

    next_position <- boj_next_position(payload, endpoint)
    if (is.null(next_position)) break
    if (next_position %in% seen_positions) {
      boj_abort(
        "The BOJ API repeated NEXTPOSITION; pagination was stopped to avoid an infinite loop.",
        class = "boj_pagination_error",
        next_position = next_position,
        endpoint = endpoint
      )
    }
    seen_positions <- c(seen_positions, next_position)
  }

  result
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
