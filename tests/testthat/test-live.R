test_that("small live API request matches the documented schema", {
  skip_on_cran()
  skip_if_not(identical(tolower(Sys.getenv("BOJAPI_RUN_LIVE_TESTS")), "true"))

  out <- boj_data(
    "FM08", "FXERM07",
    start_date = "202401", end_date = "202402",
    wait = 1
  )
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_true(all(out$series_code == "FXERM07"))
  expect_true(all(is.finite(out$value)))

  Sys.sleep(1)
  metadata <- boj_metadata("FM08", lang = "jp", cache = FALSE, wait = 1)
  expect_gt(nrow(metadata), 50L)
  expect_true("FXERM07" %in% metadata$series_code)
  expect_identical(
    metadata$start_time[metadata$series_code == "FXERM07"],
    "197301"
  )

  Sys.sleep(1)
  layer <- boj_layer(
    "FM08", frequency = "M", layer = c(2, 1, 2),
    start_date = "202401", end_date = "202401", wait = 1
  )
  expect_true("FXERM07" %in% layer$series_code)
  expect_true(all(layer$time == "202401"))
})
