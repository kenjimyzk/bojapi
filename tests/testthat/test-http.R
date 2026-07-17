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

