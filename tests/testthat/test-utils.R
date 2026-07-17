test_that("automatic request pauses enforce a one-second minimum", {
  observed <- numeric()
  local_mocked_bindings(
    boj_sleep = function(seconds) observed <<- c(observed, seconds),
    .package = "bojapi"
  )

  bojapi:::boj_pause(0)
  bojapi:::boj_pause(0.25)
  bojapi:::boj_pause(2)

  expect_equal(observed, c(1, 1, 2))
  expect_error(bojapi:::boj_pause(-1), class = "boj_parameter_error")
})
