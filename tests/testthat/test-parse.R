test_that("series responses become normalized long data", {
  out <- bojapi:::boj_parse_series(
    list(fixture_series()), db = "FM08", lang = "en",
    aliases = c(FXERM07 = "usd_yen")
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_identical(out$series, c("usd_yen", "usd_yen"))
  expect_identical(out$series_code, c("FXERM07", "FXERM07"))
  expect_equal(out$date, as.Date(c("2024-01-01", "2024-02-01")))
  expect_equal(out$value[[1L]], 146.59)
  expect_true(is.na(out$value[[2L]]))
  expect_equal(out$last_update[[1L]], as.Date("2026-07-03"))
})

test_that("Japanese response fields are normalized", {
  out <- bojapi:::boj_parse_series(
    list(fixture_series(lang = "jp")), db = "FM08", lang = "jp"
  )
  expect_identical(unique(out$name), "東京市場 ドル・円")
  expect_identical(unique(out$unit), "円／米ドル")
})

test_that("period dates retain BOJ fiscal semantics", {
  period_date <- bojapi:::boj_period_date
  expect_equal(period_date("2024", "ANNUAL(MAR)"), as.Date("2024-04-01"))
  expect_equal(period_date("202402", "QUARTERLY"), as.Date("2024-04-01"))
  expect_equal(period_date("202402", "SEMIANNUAL(SEP)"), as.Date("2024-10-01"))
  expect_equal(period_date("20240104", "DAILY"), as.Date("2024-01-04"))
})

test_that("date/value length mismatches are errors", {
  item <- fixture_series(times = list(202401L), values = list(1, 2))
  expect_error(
    bojapi:::boj_parse_series(list(item), "FM08", "en"),
    class = "boj_parse_error"
  )
})

test_that("exact duplicate observations are removed but conflicts fail", {
  first <- fixture_series(values = list(1, 2))
  same <- fixture_series(values = list(1, 2))
  out <- bojapi:::boj_parse_series(list(first, same), "FM08", "en")
  expect_equal(nrow(out), 2L)

  conflict <- fixture_series(values = list(99, 2))
  expect_error(
    bojapi:::boj_parse_series(list(first, conflict), "FM08", "en"),
    class = "boj_incomplete_download"
  )
})

test_that("metadata includes hierarchy headings and period dates", {
  out <- bojapi:::boj_parse_metadata(fixture_metadata("jp"), "FM08", "jp")
  expect_equal(nrow(out), 2L)
  expect_false(out$is_series[[1L]])
  expect_true(out$is_series[[2L]])
  expect_identical(out$name[[2L]], "東京市場 ドル・円 月中平均")
  expect_equal(out$start_date[[2L]], as.Date("1973-01-01"))
  expect_equal(out$last_update[[2L]], as.Date("2026-07-03"))
})

test_that("wide output uses series aliases", {
  data <- bojapi:::boj_parse_series(
    list(fixture_series()), "FM08", "en",
    aliases = c(FXERM07 = "usd_yen")
  )
  wide <- bojapi:::boj_widen(data)
  expect_named(wide, c("time", "date", "usd_yen"))
  expect_equal(wide$usd_yen[[1L]], 146.59)
})

