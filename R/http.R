boj_request <- function(endpoint, params, timeout) {
  url <- paste0(.bojapi_base_url, "/", endpoint)
  package_version <- tryCatch(
    as.character(utils::packageVersion("bojapi")),
    error = function(e) "development"
  )

  request <- httr2::request(url)
  request <- do.call(httr2::req_url_query, c(list(request), params))
  request <- httr2::req_headers(request, `Accept-Encoding` = "gzip")
  request <- httr2::req_user_agent(request, paste0("bojapi/", package_version, " (R; +https://github.com/kenjimyzk/bojapi)"))
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
    api_status <- suppressWarnings(as.integer(payload$STATUS %||% NA_integer_))
    if (api_status %in% c(500L, 503L) && attempt < max_tries) {
      boj_retry_pause(response = response, attempt = attempt, wait = wait)
      next
    }

    if (is.na(api_status) && http_status >= 400L) {
      boj_abort(
        sprintf("The BOJ API returned HTTP status %s without a valid API error object.", http_status),
        class = "boj_http_error",
        endpoint = endpoint,
        http_status = http_status
      )
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

boj_retry_pause <- function(response, attempt, wait) {
  retry_after <- NA_real_
  if (!is.null(response)) {
    retry_after <- suppressWarnings(as.numeric(httr2::resp_header(response, "retry-after")))
  }
  if (is.na(retry_after)) retry_after <- 0
  exponential <- min(8, 2^(attempt - 1L))
  jitter <- if (wait > 0) stats::runif(1L, 0, min(0.25, wait / 4)) else 0
  boj_pause(max(wait, retry_after, exponential) + jitter)
}

boj_check_response <- function(payload, endpoint) {
  if (!is.list(payload)) {
    boj_abort("The BOJ API response is not a JSON object.", class = "boj_parse_error", endpoint = endpoint)
  }

  status <- suppressWarnings(as.integer(payload$STATUS %||% NA_integer_))
  if (is.na(status)) {
    boj_abort(
      "The BOJ API response does not contain a valid STATUS field.",
      class = "boj_parse_error",
      endpoint = endpoint
    )
  }
  if (status != 200L) {
    message_id <- as.character(payload$MESSAGEID %||% "")
    api_message <- as.character(payload$MESSAGE %||% "Unknown BOJ API error")
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

boj_fetch_pages <- function(endpoint, params, wait, timeout, retries) {
  result <- list()
  next_position <- NULL
  seen_positions <- character()
  request_number <- 0L

  repeat {
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

    raw_next <- payload$NEXTPOSITION
    if (is.null(raw_next) || length(raw_next) == 0L || identical(raw_next, "")) {
      break
    }
    next_position <- as.character(raw_next[[1L]])
    if (!grepl("^[1-9][0-9]*$", next_position)) {
      boj_abort(
        "The BOJ API returned an invalid NEXTPOSITION value.",
        class = "boj_pagination_error",
        next_position = next_position,
        endpoint = endpoint
      )
    }
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
