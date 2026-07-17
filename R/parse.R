boj_character <- function(x, default = "") {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(default)
  }
  as.character(x[[1L]])
}

boj_number <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(NA_real_)
  }
  value <- suppressWarnings(as.numeric(x[[1L]]))
  if (is.na(value)) NA_real_ else value
}

boj_integer <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(NA_integer_)
  }
  value <- suppressWarnings(as.integer(x[[1L]]))
  if (is.na(value)) NA_integer_ else value
}

boj_parse_yyyymmdd <- function(x) {
  x <- boj_character(x, default = NA_character_)
  if (is.na(x) || !grepl("^[0-9]{8}$", x)) {
    return(as.Date(NA_character_))
  }
  suppressWarnings(as.Date(x, format = "%Y%m%d"))
}

boj_period_date <- function(time, frequency) {
  if (length(time) == 0L) {
    return(as.Date(character()))
  }
  if (length(frequency) == 1L) {
    frequency <- rep(frequency, length(time))
  }
  out <- mapply(
    boj_period_date_one,
    as.character(time),
    as.character(frequency),
    USE.NAMES = FALSE
  )
  as.Date(out, origin = "1970-01-01")
}

boj_period_date_one <- function(time, frequency) {
  if (is.na(time) || !nzchar(time) || is.na(frequency) || !nzchar(frequency)) {
    return(as.Date(NA_character_))
  }

  if ((identical(frequency, "DAILY") || startsWith(frequency, "WEEKLY(")) &&
      grepl("^[0-9]{8}$", time)) {
    return(suppressWarnings(as.Date(time, format = "%Y%m%d")))
  }

  if (!grepl("^[0-9]{4}([0-9]{2})?$", time)) {
    return(as.Date(NA_character_))
  }
  year <- as.integer(substr(time, 1L, 4L))
  period <- if (nchar(time) == 6L) as.integer(substr(time, 5L, 6L)) else NA_integer_

  month <- switch(
    frequency,
    "ANNUAL" = 1L,
    "ANNUAL(MAR)" = 4L,
    "SEMIANNUAL" = if (period == 1L) 1L else if (period == 2L) 7L else NA_integer_,
    "SEMIANNUAL(SEP)" = if (period == 1L) 4L else if (period == 2L) 10L else NA_integer_,
    "QUARTERLY" = if (period %in% 1:4) 1L + (period - 1L) * 3L else NA_integer_,
    "MONTHLY" = if (period %in% 1:12) period else NA_integer_,
    NA_integer_
  )
  if (is.na(month)) {
    return(as.Date(NA_character_))
  }
  as.Date(sprintf("%04d-%02d-01", year, month))
}

boj_parse_series <- function(series, db, lang, aliases = NULL) {
  if (length(series) == 0L) {
    return(boj_empty_data())
  }

  rows <- vector("list", length(series))
  for (i in seq_along(series)) {
    item <- series[[i]]
    if (!is.list(item)) {
      boj_abort("A BOJ RESULTSET item is not a JSON object.", class = "boj_parse_error")
    }

    code <- boj_character(item$SERIES_CODE)
    frequency <- boj_character(item$FREQUENCY)
    values_object <- item$VALUES %||% list()
    times_raw <- values_object$SURVEY_DATES %||% list()
    values_raw <- values_object$VALUES %||% list()
    if (!is.list(times_raw)) times_raw <- as.list(times_raw)
    if (!is.list(values_raw)) values_raw <- as.list(values_raw)

    if (length(times_raw) != length(values_raw)) {
      boj_abort(
        sprintf(
          "Series %s has %s period codes but %s values.",
          if (nzchar(code)) code else i,
          length(times_raw),
          length(values_raw)
        ),
        class = "boj_parse_error",
        series_code = code
      )
    }
    if (length(times_raw) == 0L) {
      rows[[i]] <- NULL
      next
    }

    time <- vapply(times_raw, boj_character, character(1L))
    value <- vapply(values_raw, boj_number, double(1L))
    name_key <- if (identical(lang, "jp")) "NAME_OF_TIME_SERIES_J" else "NAME_OF_TIME_SERIES"
    unit_key <- if (identical(lang, "jp")) "UNIT_J" else "UNIT"
    category_key <- if (identical(lang, "jp")) "CATEGORY_J" else "CATEGORY"
    name <- boj_character(item[[name_key]], boj_character(item$NAME_OF_TIME_SERIES))
    unit <- boj_character(item[[unit_key]], boj_character(item$UNIT))
    category <- boj_character(item[[category_key]], boj_character(item$CATEGORY))
    alias <- if (!is.null(aliases) && code %in% names(aliases)) aliases[[code]] else code

    rows[[i]] <- tibble::tibble(
      db = rep(db, length(time)),
      series = rep(alias, length(time)),
      series_code = rep(code, length(time)),
      name = rep(name, length(time)),
      unit = rep(unit, length(time)),
      frequency = rep(frequency, length(time)),
      category = rep(category, length(time)),
      last_update = rep(boj_parse_yyyymmdd(item$LAST_UPDATE), length(time)),
      time = time,
      date = boj_period_date(time, frequency),
      value = value
    )
  }

  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(boj_empty_data())
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  boj_check_duplicate_observations(tibble::as_tibble(out))
}

boj_check_duplicate_observations <- function(data) {
  if (nrow(data) == 0L) return(data)
  key <- paste(data$db, data$series_code, data$time, sep = "\r")
  duplicated_key <- duplicated(key) | duplicated(key, fromLast = TRUE)
  if (!any(duplicated_key)) return(data)

  groups <- split(seq_len(nrow(data))[duplicated_key], key[duplicated_key])
  conflicting <- vapply(groups, function(index) {
    values <- data$value[index]
    length(unique(ifelse(is.na(values), "<NA>", format(values, digits = 17)))) > 1L
  }, logical(1L))
  if (any(conflicting)) {
    boj_abort(
      "The BOJ API returned conflicting values for the same series and period.",
      class = "boj_incomplete_download"
    )
  }
  data[!duplicated(key), , drop = FALSE]
}

boj_parse_metadata <- function(series, db, lang) {
  if (length(series) == 0L) {
    return(boj_empty_metadata())
  }

  rows <- vector("list", length(series))
  for (i in seq_along(series)) {
    item <- series[[i]]
    if (!is.list(item)) {
      boj_abort("A BOJ metadata RESULTSET item is not a JSON object.", class = "boj_parse_error")
    }
    frequency <- boj_character(item$FREQUENCY)
    start_time <- boj_character(item$START_OF_THE_TIME_SERIES)
    end_time <- boj_character(item$END_OF_THE_TIME_SERIES)
    name_key <- if (identical(lang, "jp")) "NAME_OF_TIME_SERIES_J" else "NAME_OF_TIME_SERIES"
    unit_key <- if (identical(lang, "jp")) "UNIT_J" else "UNIT"
    category_key <- if (identical(lang, "jp")) "CATEGORY_J" else "CATEGORY"
    notes_key <- if (identical(lang, "jp")) "NOTES_J" else "NOTES"
    series_code <- boj_character(item$SERIES_CODE)

    rows[[i]] <- tibble::tibble(
      db = db,
      series_code = series_code,
      name = boj_character(item[[name_key]], boj_character(item$NAME_OF_TIME_SERIES)),
      unit = boj_character(item[[unit_key]], boj_character(item$UNIT)),
      frequency = frequency,
      category = boj_character(item[[category_key]], boj_character(item$CATEGORY)),
      layer1 = boj_integer(item$LAYER1), layer2 = boj_integer(item$LAYER2),
      layer3 = boj_integer(item$LAYER3), layer4 = boj_integer(item$LAYER4),
      layer5 = boj_integer(item$LAYER5),
      start_time = start_time,
      end_time = end_time,
      start_date = boj_period_date(start_time, frequency),
      end_date = boj_period_date(end_time, frequency),
      last_update = boj_parse_yyyymmdd(item$LAST_UPDATE),
      notes = boj_character(item[[notes_key]], boj_character(item$NOTES)),
      is_series = nzchar(series_code),
      lang = lang
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

boj_widen <- function(data) {
  if (nrow(data) == 0L) {
    return(tibble::tibble(time = character(), date = as.Date(character())))
  }
  series <- unique(data$series)
  if (any(!nzchar(series)) || anyDuplicated(series)) {
    boj_abort(
      "Series aliases must be non-empty and unique when `wide = TRUE`.",
      class = "boj_parameter_error"
    )
  }
  id <- unique(data[c("time", "date")])
  id <- id[order(id$date, id$time, na.last = TRUE), , drop = FALSE]
  key <- id$time
  for (label in series) {
    values <- data[data$series == label, c("time", "value"), drop = FALSE]
    id[[label]] <- values$value[match(key, values$time)]
  }
  tibble::as_tibble(id)
}

