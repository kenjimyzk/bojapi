json_response <- function(status_code = 200L, body) {
  httr2::response(
    status_code = status_code,
    headers = list(`content-type` = "application/json"),
    body = charToRaw(body)
  )
}

ok_json <- paste0(
  '{"STATUS":200,"MESSAGEID":"M181000I","MESSAGE":"OK",',
  '"NEXTPOSITION":null,"RESULTSET":[]}'
)

test_that("the User-Agent identifies the public project URL", {
  request <- bojapi:::boj_request("getMetadata", list(format = "json"), 30)
  expect_match(
    request$options$useragent,
    "^bojapi/.+ \\(R; \\+https://github.com/kenjimyzk/bojapi\\)$"
  )
})

test_that("transient HTTP responses are retried exactly", {
  responses <- list(
    json_response(500L, '{"STATUS":500,"MESSAGEID":"M181090S","MESSAGE":"retry"}'),
    json_response(200L, ok_json)
  )
  calls <- 0L
  pauses <- 0L
  local_mocked_bindings(
    boj_perform = function(request) {
      calls <<- calls + 1L
      responses[[calls]]
    },
    boj_retry_pause = function(...) pauses <<- pauses + 1L,
    .package = "bojapi"
  )

  out <- bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 1, 0)
  expect_identical(out$STATUS, 200L)
  expect_equal(calls, 2L)
  expect_equal(pauses, 1L)
})

test_that("transient API status inside HTTP 200 is retried", {
  responses <- list(
    json_response(200L, '{"STATUS":503,"MESSAGEID":"M181091S","MESSAGE":"retry"}'),
    json_response(200L, ok_json)
  )
  calls <- 0L
  local_mocked_bindings(
    boj_perform = function(request) {
      calls <<- calls + 1L
      responses[[calls]]
    },
    boj_retry_pause = function(...) NULL,
    .package = "bojapi"
  )
  out <- bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 1, 0)
  expect_identical(out$STATUS, 200L)
  expect_equal(calls, 2L)
})

test_that("network failures are retried", {
  calls <- 0L
  local_mocked_bindings(
    boj_perform = function(request) {
      calls <<- calls + 1L
      if (calls == 1L) stop("temporary connection failure")
      json_response(200L, ok_json)
    },
    boj_retry_pause = function(...) NULL,
    .package = "bojapi"
  )
  expect_no_error(
    bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 1, 0)
  )
  expect_equal(calls, 2L)
})

test_that("excessive Retry-After delays fail without blocking", {
  response <- httr2::response(
    status_code = 429L,
    headers = list(`retry-after` = "3600"),
    body = raw()
  )
  error <- tryCatch(
    bojapi:::boj_retry_pause(response, attempt = 1L, wait = 1),
    error = identity
  )
  expect_s3_class(error, "boj_http_error")
  expect_identical(error$retry_after, 3600)
  expect_identical(error$retry_after_limit, 60)
})

test_that("official HTTP 400 JSON retains BOJ error details", {
  local_mocked_bindings(
    boj_perform = function(request) json_response(
      400L,
      '{"STATUS":400,"MESSAGEID":"M181005E","MESSAGE":"Invalid DB"}'
    ),
    .package = "bojapi"
  )
  error <- tryCatch(
    bojapi:::boj_fetch_json("getMetadata", list(db = "BAD"), 30, 0, 0),
    error = identity
  )
  expect_s3_class(error, "boj_api_response_error")
  expect_identical(error$message_id, "M181005E")
})

test_that("malformed successful response is a parse error", {
  local_mocked_bindings(
    boj_perform = function(request) httr2::response(
      status_code = 200L,
      headers = list(`content-type` = "text/html"),
      body = charToRaw("not json")
    ),
    .package = "bojapi"
  )
  expect_error(
    bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 0, 0),
    class = "boj_parse_error"
  )
})

test_that("valid JSON with an invalid top-level shape is a parse error", {
  bodies <- c("1", "[]")
  for (body in bodies) {
    local_mocked_bindings(
      boj_perform = function(request) json_response(200L, body),
      .package = "bojapi"
    )
    error <- tryCatch(
      bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 0, 0),
      error = identity
    )
    expect_s3_class(error, "boj_parse_error")
    expect_match(error$message, "JSON object", fixed = TRUE)
    expect_identical(error$endpoint, "getMetadata")
  }
})

test_that("invalid STATUS fields produce informative parse errors", {
  cases <- list(
    list(body = "{}", message = "does not contain a STATUS field"),
    list(body = '{"STATUS":[]}', message = "exactly one value"),
    list(body = '{"STATUS":[200,500]}', message = "exactly one value"),
    list(body = '{"STATUS":true}', message = "finite whole number"),
    list(body = '{"STATUS":"not-a-status"}', message = "finite whole number")
  )

  for (case in cases) {
    local_mocked_bindings(
      boj_perform = function(request) json_response(200L, case$body),
      .package = "bojapi"
    )
    error <- tryCatch(
      bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 0, 0),
      error = identity
    )
    expect_s3_class(error, "boj_parse_error")
    expect_match(error$message, case$message, fixed = TRUE)
  }
})

test_that("a scalar character STATUS remains compatible", {
  local_mocked_bindings(
    boj_perform = function(request) json_response(
      200L,
      '{"STATUS":"200","MESSAGEID":"M181000I","MESSAGE":"OK","RESULTSET":[]}'
    ),
    .package = "bojapi"
  )
  out <- bojapi:::boj_fetch_json("getMetadata", list(db = "FM08"), 30, 0, 0)
  expect_identical(out$STATUS, "200")
})

test_that("malformed API error details retain a classed response error", {
  error <- tryCatch(
    bojapi:::boj_check_response(
      list(STATUS = 400L, MESSAGEID = list(), MESSAGE = c("a", "b")),
      endpoint = "getMetadata"
    ),
    error = identity
  )
  expect_s3_class(error, "boj_api_response_error")
  expect_identical(error$message_id, "")
  expect_identical(error$api_message, "Unknown BOJ API error")
})

test_that("invalid NEXTPOSITION shapes fail safely", {
  invalid <- list(c(2L, 3L), list(2L), TRUE, NA_integer_, 1.5, 0L)
  for (value in invalid) {
    payload <- fixture_payload(resultset = list(), next_position = value)
    expect_error(
      bojapi:::boj_next_position(payload, "getDataCode"),
      class = "boj_pagination_error"
    )
  }
})

test_that("pagination stops at its safety limit", {
  calls <- 0L
  local_mocked_bindings(
    .bojapi_max_pages = 3L,
    boj_fetch_json = function(...) {
      calls <<- calls + 1L
      fixture_payload(resultset = list(), next_position = calls + 1L)
    },
    .package = "bojapi"
  )

  error <- tryCatch(
    bojapi:::boj_fetch_pages("getDataCode", list(), 0, 30, 0),
    error = identity
  )
  expect_s3_class(error, "boj_pagination_error")
  expect_match(error$message, "safety limit of 3 pages", fixed = TRUE)
  expect_identical(error$pages, 3L)
  expect_identical(error$page_limit, 3L)
  expect_identical(error$next_position, "4")
  expect_equal(calls, 3L)
})
