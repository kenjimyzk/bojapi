boj_abort <- function(message, class = "bojapi_error", ..., call = NULL) {
  fields <- list(...)
  condition <- c(
    list(message = message, call = call),
    fields
  )
  class(condition) <- unique(c(class, "bojapi_error", "error", "condition"))
  stop(condition)
}

boj_warn_no_data <- function() {
  condition <- structure(
    list(
      message = "The BOJ API completed successfully, but no observations matched the query.",
      call = NULL
    ),
    class = c("boj_no_data_warning", "bojapi_warning", "warning", "condition")
  )
  warning(condition)
}
