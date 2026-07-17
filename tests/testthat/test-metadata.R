test_that("metadata cache avoids repeated API calls", {
  calls <- 0L
  local_mocked_bindings(
    boj_fetch_json = function(...) {
      calls <<- calls + 1L
      fixture_payload(resultset = fixture_metadata("en"))
    },
    .package = "bojapi"
  )
  cache_dir <- tempfile("bojapi-cache-")
  first <- boj_metadata("FM08", cache_dir = cache_dir, wait = 0)
  second <- boj_metadata("FM08", cache_dir = cache_dir, wait = 0)
  expect_equal(calls, 1L)
  expect_equal(first, second, ignore_attr = TRUE)
})

test_that("metadata can omit hierarchy headings", {
  local_mocked_bindings(
    boj_fetch_json = function(...) fixture_payload(resultset = fixture_metadata("en")),
    .package = "bojapi"
  )
  out <- boj_metadata("FM08", cache = FALSE, include_groups = FALSE, wait = 0)
  expect_true(all(out$is_series))
  expect_equal(nrow(out), 1L)
})

test_that("boj_search supports literal and regular expression searches", {
  metadata <- bojapi:::boj_parse_metadata(fixture_metadata("en"), "FM08", "en")
  literal <- boj_search("U.S. Dollar", metadata = metadata)
  expect_equal(literal$series_code, "FXERM07")

  regex <- boj_search("dollar|euro", metadata = metadata, regex = TRUE)
  expect_equal(nrow(regex), 1L)

  groups <- boj_search("Daily", metadata = metadata, include_groups = TRUE)
  expect_false(groups$is_series[[1L]])
})

test_that("database registry and credit are complete", {
  expect_equal(nrow(boj_databases()), 50L)
  expect_true(all(c("FM08", "CO", "FF", "BIS") %in% boj_databases()$db))
  credit <- boj_api_credit("en")
  expect_match(credit$credit, "does not guarantee", fixed = TRUE)
  expect_identical(credit$email, "post.rsd17@boj.or.jp")
})

