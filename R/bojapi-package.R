#' bojapi: Bank of Japan time-series data for R
#'
#' `bojapi` is a client for the official Bank of Japan (BOJ) Time-Series Data
#' Search API. It provides a small workflow:
#'
#' 1. List databases with [boj_databases()].
#' 2. Discover series with [boj_search()] or [boj_metadata()].
#' 3. Retrieve observations with [boj_data()] or [boj_layer()].
#'
#' The BOJ API requires no API key. To respect the BOJ prohibition on
#' high-frequency access, automatic multi-request operations wait one second
#' between requests by default. Change this per call with `wait`, or globally
#' with `options(bojapi.wait = 2)`.
#'
#' @section Package options:
#' - `bojapi.lang`: default response language, `"en"` or `"jp"`.
#' - `bojapi.wait`: seconds between automatic requests; default `1`.
#' - `bojapi.timeout`: request timeout in seconds; default `30`.
#' - `bojapi.retries`: retries for transient failures; default `3`.
#' - `bojapi.cache_dir`: metadata cache directory.
#'
#' @section Terms of use:
#' Public services using the API must follow the BOJ's current API notice,
#' including its requested credit and release notification. Use
#' [boj_api_credit()] to retrieve the credit and official links.
#'
#' @seealso
#' [BOJ API manual](https://www.stat-search.boj.or.jp/info/api_manual_en.pdf),
#' [BOJ API notice](https://www.stat-search.boj.or.jp/info/api_notice_en.pdf)
#'
#' @keywords internal
"_PACKAGE"

.bojapi_base_url <- "https://www.stat-search.boj.or.jp/api/v1"
.bojapi_max_codes <- 250L
.bojapi_frequencies <- c("CY", "FY", "CH", "FH", "Q", "M", "W", "D")

