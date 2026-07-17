#' Retrieve Bank of Japan time-series data by series code
#'
#' `boj_data()` is the main data function. It accepts one or more BOJ series
#' codes, splits requests into safe batches of 250 codes, follows
#' `NEXTPOSITION` until complete, and returns one observation per row. All codes
#' in a BOJ code request must have the same frequency.
#'
#' A named `code` vector creates convenient aliases, following the style of
#' `WDI::WDI()`. The original BOJ code is always retained in `series_code`.
#'
#' @param db BOJ database identifier, such as `"FM08"`.
#' @param code Character vector of series codes without the database prefix.
#'   For example, use `"MADR1Z@D"`, not `"IR01'MADR1Z@D"`. Names become
#'   aliases in the `series` column and wide output.
#' @param start_date,end_date Optional BOJ period codes. Accepted request forms
#'   are `YYYY` or `YYYYPP`; daily and weekly filters also use `YYYYMM`.
#' @param lang Response language, `"en"` or `"jp"`.
#' @param wide If `FALSE` (default), return normalized long data. If `TRUE`,
#'   return `time`, parsed `date`, and one column per code or alias.
#' @param wait Requested seconds between automatic requests. The default is one
#'   second, and values below one are treated as one whenever another request is
#'   needed, to avoid high-frequency access prohibited by the BOJ.
#' @param timeout Request timeout in seconds.
#' @param retries Number of retries for network and transient server errors.
#'
#' @return A tibble. Long output contains `db`, `series`, `series_code`, `name`,
#'   `unit`, `frequency`, `category`, `last_update`, `time`, `date`, and
#'   `value`. `time` preserves the exact BOJ period code. `date` is the first
#'   day of non-daily periods (April 1 for fiscal years); use `time` when exact
#'   period semantics matter.
#'
#' @export
#' @examples
#' \dontrun{
#' fx <- boj_data(
#'   db = "FM08",
#'   code = c(usd_yen = "FXERM07"),
#'   start_date = "202401",
#'   end_date = "202412"
#' )
#'
#' boj_data(
#'   "FM08",
#'   c(usd_yen = "FXERM07", euro_yen = "FXERM09"),
#'   start_date = "202401",
#'   wide = TRUE
#' )
#' }
boj_data <- function(
    db,
    code,
    start_date = NULL,
    end_date = NULL,
    lang = boj_default("lang", "en"),
    wide = FALSE,
    wait = boj_default("wait", 1),
    timeout = boj_default("timeout", 30),
    retries = boj_default("retries", 3)) {
  db <- boj_normalize_db(db)
  lang <- boj_match_lang(lang)
  original_names <- names(code)
  code <- boj_normalize_codes(code)
  if (anyDuplicated(code)) {
    boj_abort("`code` must not contain duplicate series codes.", class = "boj_parameter_error")
  }
  start_date <- boj_normalize_period(start_date, "start_date")
  end_date <- boj_normalize_period(end_date, "end_date")
  boj_check_period_order(start_date, end_date)
  if (!is.logical(wide) || length(wide) != 1L || is.na(wide)) {
    boj_abort("`wide` must be TRUE or FALSE.", class = "boj_parameter_error")
  }
  wait <- boj_scalar_number(wait, "wait", min = 0)
  timeout <- boj_scalar_number(timeout, "timeout", min = 0)
  retries <- boj_scalar_number(retries, "retries", min = 0, integer = TRUE)

  aliases <- code
  names(aliases) <- code
  if (!is.null(original_names)) {
    use_name <- !is.na(original_names) & nzchar(original_names)
    aliases[use_name] <- original_names[use_name]
  }
  if (isTRUE(wide) && anyDuplicated(unname(aliases))) {
    boj_abort("Named `code` aliases must be unique for wide output.", class = "boj_parameter_error")
  }

  chunks <- boj_chunks(code)
  raw_series <- list()
  for (i in seq_along(chunks)) {
    if (i > 1L) boj_pause(wait)
    params <- list(
      format = "json", lang = lang, db = db,
      code = paste(chunks[[i]], collapse = ",")
    )
    if (!is.null(start_date)) params$startDate <- start_date
    if (!is.null(end_date)) params$endDate <- end_date
    raw_series <- c(
      raw_series,
      boj_fetch_pages("getDataCode", params, wait, timeout, retries)
    )
  }

  out <- boj_parse_series(raw_series, db = db, lang = lang, aliases = aliases)
  returned_frequencies <- unique(out$frequency[nzchar(out$frequency)])
  if (length(returned_frequencies) > 1L) {
    boj_abort(
      paste0(
        "All `code` values must have the same BOJ frequency; the response contained: ",
        paste(returned_frequencies, collapse = ", "), "."
      ),
      class = "boj_parameter_error",
      frequencies = returned_frequencies
    )
  }
  if (nrow(out) == 0L) boj_warn_no_data()
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- list(db = db, code = code, start_date = start_date, end_date = end_date, lang = lang)
  if (isTRUE(wide)) boj_widen(out) else out
}

#' Retrieve Bank of Japan time-series data by hierarchy
#'
#' Uses the BOJ layer API to retrieve all series matching a database hierarchy
#' and frequency. The function follows `NEXTPOSITION` automatically. A layer
#' condition that identifies more than 1,250 series is rejected by the BOJ API;
#' this count is evaluated before the frequency filter.
#'
#' @param db BOJ database identifier.
#' @param frequency One of `"CY"`, `"FY"`, `"CH"`, `"FH"`, `"Q"`, `"M"`,
#'   `"W"`, or `"D"`.
#' @param layer One to five hierarchy values supplied as a vector or a
#'   comma-separated string. `"*"` is a wildcard; for example, `c(1, "*", 2)`.
#' @inheritParams boj_data
#'
#' @return A long or wide tibble with the same structure as [boj_data()].
#' @export
#' @examples
#' \dontrun{
#' boj_layer(
#'   db = "BP01", frequency = "M", layer = c(1, 1, 1),
#'   start_date = "202504", end_date = "202509"
#' )
#' }
boj_layer <- function(
    db,
    frequency,
    layer,
    start_date = NULL,
    end_date = NULL,
    lang = boj_default("lang", "en"),
    wide = FALSE,
    wait = boj_default("wait", 1),
    timeout = boj_default("timeout", 30),
    retries = boj_default("retries", 3)) {
  db <- boj_normalize_db(db)
  frequency <- boj_normalize_frequency(frequency)
  layer <- boj_normalize_layer(layer)
  lang <- boj_match_lang(lang)
  start_date <- boj_normalize_period(start_date, "start_date", frequency)
  end_date <- boj_normalize_period(end_date, "end_date", frequency)
  boj_check_period_order(start_date, end_date)
  if (!is.logical(wide) || length(wide) != 1L || is.na(wide)) {
    boj_abort("`wide` must be TRUE or FALSE.", class = "boj_parameter_error")
  }

  params <- list(
    format = "json", lang = lang, db = db,
    frequency = frequency, layer = layer
  )
  if (!is.null(start_date)) params$startDate <- start_date
  if (!is.null(end_date)) params$endDate <- end_date
  raw_series <- boj_fetch_pages("getDataLayer", params, wait, timeout, retries)
  out <- boj_parse_series(raw_series, db = db, lang = lang)
  if (nrow(out) == 0L) boj_warn_no_data()
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- list(
    db = db, frequency = frequency, layer = layer,
    start_date = start_date, end_date = end_date, lang = lang
  )
  if (isTRUE(wide)) boj_widen(out) else out
}
