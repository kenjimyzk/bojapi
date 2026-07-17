test_that("parameters are validated before network access", {
  expect_error(boj_data("bad db", "A"), class = "boj_parameter_error")
  expect_error(boj_data("FM08", character()), class = "boj_parameter_error")
  expect_error(boj_data("FM08", c("A", "A")), class = "boj_parameter_error")
  expect_error(boj_data("FM08", "FM08'FXERM07"), class = "boj_parameter_error")
  expect_error(
    boj_data("FM08", "A", start_date = "202501", end_date = "202401"),
    class = "boj_parameter_error"
  )
  expect_error(boj_layer("FM08", "X", 1), class = "boj_parameter_error")
  expect_error(boj_layer("FM08", "M", 1:6), class = "boj_parameter_error")
  expect_error(boj_layer("FM08", "Q", 1, start_date = "202405"), class = "boj_parameter_error")
})

test_that("API errors carry machine-readable fields", {
  error <- tryCatch(
    bojapi:::boj_check_response(
      list(STATUS = 400L, MESSAGEID = "M181005E", MESSAGE = "Invalid DB"),
      endpoint = "getMetadata"
    ),
    error = identity
  )
  expect_s3_class(error, "boj_api_response_error")
  expect_identical(error$status, 400L)
  expect_identical(error$message_id, "M181005E")
})

