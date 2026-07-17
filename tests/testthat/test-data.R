test_that("boj_data follows NEXTPOSITION exactly", {
  calls <- list()
  page <- 0L
  local_mocked_bindings(
    boj_fetch_json = function(endpoint, params, timeout, retries, wait) {
      page <<- page + 1L
      calls[[page]] <<- list(endpoint = endpoint, params = params)
      if (page == 1L) {
        fixture_payload(
          list(fixture_series(code = "A", times = list(202401L), values = list(1))),
          next_position = 2L
        )
      } else {
        fixture_payload(
          list(fixture_series(code = "B", times = list(202401L), values = list(2)))
        )
      }
    },
    .package = "bojapi"
  )

  out <- boj_data("FM08", c("A", "B"), wait = 0)
  expect_equal(nrow(out), 2L)
  expect_equal(length(calls), 2L)
  expect_null(calls[[1L]]$params$startPosition)
  expect_identical(calls[[2L]]$params$startPosition, "2")
})

test_that("boj_data splits more than 250 codes", {
  calls <- list()
  local_mocked_bindings(
    boj_fetch_json = function(endpoint, params, timeout, retries, wait) {
      calls[[length(calls) + 1L]] <<- params
      fixture_payload(resultset = list())
    },
    .package = "bojapi"
  )
  codes <- sprintf("C%03d", seq_len(251L))
  expect_warning(boj_data("FM08", codes, wait = 0), "no observations")
  expect_equal(length(calls), 2L)
  expect_equal(length(strsplit(calls[[1L]]$code, ",", fixed = TRUE)[[1L]]), 250L)
  expect_equal(length(strsplit(calls[[2L]]$code, ",", fixed = TRUE)[[1L]]), 1L)
})

test_that("named codes flow through long and wide outputs", {
  local_mocked_bindings(
    boj_fetch_json = function(...) fixture_payload(),
    .package = "bojapi"
  )
  long <- boj_data("FM08", c(usd_yen = "FXERM07"), wait = 0)
  expect_identical(unique(long$series), "usd_yen")
  wide <- boj_data("FM08", c(usd_yen = "FXERM07"), wide = TRUE, wait = 0)
  expect_named(wide, c("time", "date", "usd_yen"))
})

test_that("boj_layer normalizes query parameters", {
  call <- NULL
  local_mocked_bindings(
    boj_fetch_json = function(endpoint, params, timeout, retries, wait) {
      call <<- list(endpoint = endpoint, params = params)
      fixture_payload()
    },
    .package = "bojapi"
  )
  boj_layer(
    "bp01", "m", c(1, "*", 2),
    start_date = "202401", end_date = "202412", wait = 0
  )
  expect_identical(call$endpoint, "getDataLayer")
  expect_identical(call$params$db, "BP01")
  expect_identical(call$params$frequency, "M")
  expect_identical(call$params$layer, "1,*,2")
})

test_that("repeated pagination positions fail safely", {
  page <- 0L
  local_mocked_bindings(
    boj_fetch_json = function(...) {
      page <<- page + 1L
      fixture_payload(resultset = list(), next_position = 2L)
    },
    .package = "bojapi"
  )
  expect_error(boj_data("FM08", "A", wait = 0), class = "boj_pagination_error")
  expect_equal(page, 2L)
})

