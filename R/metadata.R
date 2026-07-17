boj_cache_dir <- function(cache_dir = boj_default(
    "cache_dir",
    tools::R_user_dir("bojapi", which = "cache")
  )) {
  boj_scalar_character(cache_dir, "cache_dir")
}

boj_metadata_cache_file <- function(db, lang, cache_dir) {
  file.path(cache_dir, paste0(tolower(db), "-", lang, ".rds"))
}

boj_read_metadata_cache <- function(path, max_age) {
  if (!file.exists(path)) return(NULL)
  age <- as.numeric(difftime(Sys.time(), file.info(path)$mtime, units = "secs"))
  if (is.na(age) || age > max_age) return(NULL)
  out <- tryCatch(readRDS(path), error = function(e) NULL)
  if (!inherits(out, "data.frame")) return(NULL)
  attr(out, "source") <- "cache"
  out
}

boj_write_metadata_cache <- function(data, path) {
  directory <- dirname(path)
  if (!dir.exists(directory) && !dir.create(directory, recursive = TRUE, showWarnings = FALSE)) {
    warning("Could not create the bojapi metadata cache directory.", call. = FALSE)
    return(invisible(FALSE))
  }
  ok <- tryCatch({
    saveRDS(data, path)
    TRUE
  }, error = function(e) FALSE)
  if (!ok) warning("Could not write the bojapi metadata cache.", call. = FALSE)
  invisible(ok)
}

#' Retrieve Bank of Japan series metadata
#'
#' Downloads the complete metadata table for one BOJ database. Metadata
#' includes both hierarchy headings (blank `series_code`) and actual series.
#' By default it is cached for 24 hours, matching the API's daily metadata
#' update cycle and reducing load on the BOJ service.
#'
#' @param db BOJ database identifier, such as `"FM08"`.
#' @param lang Response language, `"en"` or `"jp"`. Japanese responses also
#'   contain some English fields, but this function consistently returns the
#'   requested language in `name`, `unit`, `category`, and `notes`.
#' @param cache Whether to read and write the on-disk metadata cache.
#' @param refresh If `TRUE`, ignore an existing cache entry.
#' @param max_age Maximum cache age in seconds; default 86,400 (24 hours).
#' @param cache_dir Metadata cache directory.
#' @param include_groups Include hierarchy-heading rows whose `series_code` is
#'   blank. These rows are useful when constructing [boj_layer()] queries.
#' @inheritParams boj_data
#'
#' @return A tibble with normalized metadata. `start_time` and `end_time`
#'   preserve exact BOJ period codes. Parsed date columns indicate the first day
#'   of each period and are `NA` for hierarchy headings.
#' @export
#' @examples
#' \dontrun{
#' metadata <- boj_metadata("FM08", lang = "jp")
#' subset(metadata, is_series)
#' }
boj_metadata <- function(
    db,
    lang = boj_default("lang", "en"),
    cache = TRUE,
    refresh = FALSE,
    max_age = 24 * 60 * 60,
    cache_dir = boj_default("cache_dir", tools::R_user_dir("bojapi", "cache")),
    include_groups = TRUE,
    timeout = boj_default("timeout", 30),
    retries = boj_default("retries", 3),
    wait = boj_default("wait", 1)) {
  db <- boj_normalize_db(db)
  lang <- boj_match_lang(lang)
  for (item in c("cache", "refresh", "include_groups")) {
    value <- get(item)
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      boj_abort(sprintf("`%s` must be TRUE or FALSE.", item), class = "boj_parameter_error")
    }
  }
  max_age <- boj_scalar_number(max_age, "max_age", min = 0)
  cache_dir <- boj_cache_dir(cache_dir)
  cache_file <- boj_metadata_cache_file(db, lang, cache_dir)

  out <- NULL
  if (isTRUE(cache) && !isTRUE(refresh)) {
    out <- boj_read_metadata_cache(cache_file, max_age)
  }
  if (is.null(out)) {
    payload <- boj_fetch_json(
      endpoint = "getMetadata",
      params = list(format = "json", lang = lang, db = db),
      timeout = timeout,
      retries = retries,
      wait = wait
    )
    out <- boj_parse_metadata(payload$RESULTSET %||% list(), db = db, lang = lang)
    attr(out, "retrieved_at") <- Sys.time()
    attr(out, "source") <- "api"
    attr(out, "query") <- list(db = db, lang = lang)
    if (isTRUE(cache)) boj_write_metadata_cache(out, cache_file)
  }

  if (!isTRUE(include_groups)) {
    out <- out[out$is_series, , drop = FALSE]
    rownames(out) <- NULL
  }
  tibble::as_tibble(out)
}

#' Refresh metadata for one or more Bank of Japan databases
#'
#' `boj_cache()` is the counterpart to `WDI::WDIcache()`: it retrieves current
#' BOJ metadata and saves it to the local cache used by [boj_search()]. When
#' `db = NULL`, all databases in [boj_databases()] are refreshed. This takes
#' about one minute with the default one-second interval.
#'
#' @param db Character vector of database identifiers, or `NULL` for all known
#'   databases.
#' @param refresh Ignore current cache entries and download fresh metadata.
#' @inheritParams boj_metadata
#'
#' @return A combined metadata tibble. The data are also written to the
#'   per-database cache.
#' @export
#' @examples
#' \dontrun{
#' current_fx_metadata <- boj_cache("FM08")
#' all_metadata <- boj_cache()
#' }
boj_cache <- function(
    db = NULL,
    lang = boj_default("lang", "en"),
    refresh = TRUE,
    max_age = 24 * 60 * 60,
    cache_dir = boj_default("cache_dir", tools::R_user_dir("bojapi", "cache")),
    include_groups = TRUE,
    wait = boj_default("wait", 1),
    timeout = boj_default("timeout", 30),
    retries = boj_default("retries", 3)) {
  if (is.null(db)) db <- .boj_databases$db
  if (!is.character(db) || length(db) < 1L || anyNA(db)) {
    boj_abort("`db` must be NULL or a non-empty character vector.", class = "boj_parameter_error")
  }
  db <- unique(vapply(db, boj_normalize_db, character(1L)))
  wait <- boj_scalar_number(wait, "wait", min = 0)

  results <- vector("list", length(db))
  for (i in seq_along(db)) {
    if (i > 1L) boj_pause(wait)
    results[[i]] <- boj_metadata(
      db = db[[i]], lang = lang, cache = TRUE, refresh = refresh,
      max_age = max_age, cache_dir = cache_dir,
      include_groups = include_groups,
      wait = wait, timeout = timeout, retries = retries
    )
  }
  out <- do.call(rbind, results)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Search Bank of Japan series metadata
#'
#' Searches current BOJ metadata in the same spirit as `WDI::WDIsearch()`.
#' Supply a database to fetch/cache metadata, or pass a metadata tibble directly
#' for an offline or reproducible search.
#'
#' @param pattern One non-empty search string or regular expression.
#' @param db One or more database identifiers. Not needed when `metadata` is
#'   supplied.
#' @param fields Metadata columns to search. Defaults to series code, name,
#'   category, and notes.
#' @param regex Treat `pattern` as a regular expression. The default performs a
#'   literal substring search.
#' @param ignore_case Ignore letter case.
#' @param metadata Optional data frame returned by [boj_metadata()] or
#'   [boj_cache()].
#' @param include_groups Include matching hierarchy-heading rows.
#' @inheritParams boj_metadata
#'
#' @return A filtered metadata tibble.
#' @export
#' @examples
#' \dontrun{
#' boj_search("U.S. Dollar", db = "FM08")
#' boj_search("FXERM07", db = "FM08", lang = "jp")
#' boj_search("exchange|euro", db = "FM08", regex = TRUE)
#' }
boj_search <- function(
    pattern,
    db = NULL,
    fields = c("series_code", "name", "category", "notes"),
    regex = FALSE,
    ignore_case = TRUE,
    metadata = NULL,
    lang = boj_default("lang", "en"),
    cache = TRUE,
    refresh = FALSE,
    max_age = 24 * 60 * 60,
    cache_dir = boj_default("cache_dir", tools::R_user_dir("bojapi", "cache")),
    include_groups = FALSE,
    wait = boj_default("wait", 1),
    timeout = boj_default("timeout", 30),
    retries = boj_default("retries", 3)) {
  pattern <- boj_scalar_character(pattern, "pattern")
  if (!is.character(fields) || length(fields) < 1L || anyNA(fields)) {
    boj_abort("`fields` must be a non-empty character vector.", class = "boj_parameter_error")
  }
  for (item in c("regex", "ignore_case", "include_groups")) {
    value <- get(item)
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      boj_abort(sprintf("`%s` must be TRUE or FALSE.", item), class = "boj_parameter_error")
    }
  }

  if (is.null(metadata)) {
    if (is.null(db)) {
      boj_abort("Supply `db` or a `metadata` data frame.", class = "boj_parameter_error")
    }
    if (!is.character(db) || length(db) < 1L || anyNA(db)) {
      boj_abort("`db` must be a non-empty character vector.", class = "boj_parameter_error")
    }
    if (length(db) == 1L) {
      metadata <- boj_metadata(
        db, lang = lang, cache = cache, refresh = refresh,
        max_age = max_age, cache_dir = cache_dir, include_groups = TRUE,
        wait = wait, timeout = timeout, retries = retries
      )
    } else if (isTRUE(cache)) {
      metadata <- boj_cache(
        db, lang = lang, refresh = refresh, max_age = max_age,
        cache_dir = cache_dir, include_groups = TRUE,
        wait = wait, timeout = timeout, retries = retries
      )
    } else {
      db <- unique(vapply(db, boj_normalize_db, character(1L)))
      pieces <- vector("list", length(db))
      for (i in seq_along(db)) {
        if (i > 1L) boj_pause(wait)
        pieces[[i]] <- boj_metadata(
          db[[i]], lang = lang, cache = FALSE, refresh = refresh,
          max_age = max_age, cache_dir = cache_dir, include_groups = TRUE,
          wait = wait, timeout = timeout, retries = retries
        )
      }
      metadata <- do.call(rbind, pieces)
    }
  }
  if (!inherits(metadata, "data.frame")) {
    boj_abort("`metadata` must be a data frame returned by bojapi.", class = "boj_parameter_error")
  }
  missing_fields <- setdiff(fields, names(metadata))
  if (length(missing_fields) > 0L) {
    boj_abort(
      sprintf("Unknown metadata field(s): %s.", paste(missing_fields, collapse = ", ")),
      class = "boj_parameter_error"
    )
  }

  matched <- rep(FALSE, nrow(metadata))
  search_one <- function(x) {
    x[is.na(x)] <- ""
    search_pattern <- pattern
    if (!isTRUE(regex) && isTRUE(ignore_case)) {
      x <- tolower(as.character(x))
      search_pattern <- tolower(pattern)
    }
    tryCatch(
      grepl(
        search_pattern,
        as.character(x),
        ignore.case = isTRUE(ignore_case) && isTRUE(regex),
        fixed = !regex
      ),
      error = function(e) {
        boj_abort(
          paste0("Invalid search pattern: ", conditionMessage(e)),
          class = "boj_parameter_error",
          parent = e
        )
      }
    )
  }
  for (field in fields) matched <- matched | search_one(metadata[[field]])
  if (!isTRUE(include_groups) && "is_series" %in% names(metadata)) {
    matched <- matched & metadata$is_series
  }
  out <- metadata[matched, , drop = FALSE]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
