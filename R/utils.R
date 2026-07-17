boj_default <- function(option, default) {
  getOption(paste0("bojapi.", option), default)
}

boj_scalar_character <- function(x, arg, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(NULL)
  }
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    boj_abort(
      sprintf("`%s` must be one non-empty character value.", arg),
      class = "boj_parameter_error"
    )
  }
  x
}

boj_scalar_number <- function(x, arg, min = -Inf, integer = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) || x < min) {
    boj_abort(
      sprintf("`%s` must be one number greater than or equal to %s.", arg, min),
      class = "boj_parameter_error"
    )
  }
  if (integer && x != floor(x)) {
    boj_abort(
      sprintf("`%s` must be a whole number.", arg),
      class = "boj_parameter_error"
    )
  }
  x
}

boj_match_lang <- function(lang = boj_default("lang", "en")) {
  if (is.null(lang)) {
    lang <- "en"
  }
  lang <- tolower(boj_scalar_character(lang, "lang"))
  if (!lang %in% c("en", "jp")) {
    boj_abort("`lang` must be either \"en\" or \"jp\".", class = "boj_parameter_error")
  }
  lang
}

boj_normalize_db <- function(db) {
  db <- toupper(boj_scalar_character(db, "db"))
  if (!grepl("^[A-Z0-9]{2,4}$", db)) {
    boj_abort(
      "`db` must contain 2 to 4 ASCII letters or digits (for example, \"FM08\").",
      class = "boj_parameter_error"
    )
  }
  db
}

boj_check_ascii <- function(x, arg) {
  ascii <- iconv(x, from = "UTF-8", to = "ASCII", sub = NA_character_)
  forbidden <- grepl("[<>\"!|\\\\;']", x)
  if (anyNA(ascii) || any(forbidden)) {
    boj_abort(
      sprintf("`%s` contains a full-width or BOJ-prohibited character.", arg),
      class = "boj_parameter_error"
    )
  }
  invisible(x)
}

boj_normalize_codes <- function(code) {
  if (!is.character(code) || length(code) < 1L || anyNA(code) || any(!nzchar(code))) {
    boj_abort("`code` must be a non-empty character vector.", class = "boj_parameter_error")
  }
  boj_check_ascii(unname(code), "code")
  unname(code)
}

boj_normalize_frequency <- function(frequency) {
  frequency <- toupper(boj_scalar_character(frequency, "frequency"))
  if (!frequency %in% .bojapi_frequencies) {
    boj_abort(
      sprintf(
        "`frequency` must be one of %s.",
        paste(sprintf("\"%s\"", .bojapi_frequencies), collapse = ", ")
      ),
      class = "boj_parameter_error"
    )
  }
  frequency
}

boj_normalize_layer <- function(layer) {
  if (is.numeric(layer)) {
    if (anyNA(layer) || any(layer < 0) || any(layer != floor(layer))) {
      boj_abort("Numeric `layer` values must be non-negative whole numbers.", class = "boj_parameter_error")
    }
    layer <- as.character(layer)
  }

  if (is.character(layer) && length(layer) == 1L && grepl(",", layer, fixed = TRUE)) {
    layer <- strsplit(layer, ",", fixed = TRUE)[[1L]]
  }
  if (!is.character(layer) || length(layer) < 1L || length(layer) > 5L || anyNA(layer)) {
    boj_abort("`layer` must contain between one and five hierarchy values.", class = "boj_parameter_error")
  }
  layer <- trimws(layer)
  if (any(!grepl("^(\\*|[0-9]+)$", layer))) {
    boj_abort("Each `layer` value must be a non-negative integer or \"*\".", class = "boj_parameter_error")
  }
  paste(layer, collapse = ",")
}

boj_normalize_period <- function(x, arg, frequency = NULL) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.numeric(x) && length(x) == 1L && !is.na(x) && x == floor(x)) {
    x <- format(x, scientific = FALSE, trim = TRUE)
  }
  x <- boj_scalar_character(x, arg)
  if (!grepl("^[0-9]+$", x) || !nchar(x) %in% c(4L, 6L)) {
    boj_abort(
      sprintf("`%s` must use BOJ format YYYY or YYYYPP.", arg),
      class = "boj_parameter_error"
    )
  }
  year <- as.integer(substr(x, 1L, 4L))
  if (year < 1850L || year > 2050L) {
    boj_abort(sprintf("The year in `%s` must be between 1850 and 2050.", arg), class = "boj_parameter_error")
  }

  if (!is.null(frequency)) {
    required_nchar <- if (frequency %in% c("CY", "FY")) 4L else 6L
    if (nchar(x) != required_nchar) {
      boj_abort(
        sprintf("`%s` has the wrong format for frequency \"%s\".", arg, frequency),
        class = "boj_parameter_error"
      )
    }
    if (nchar(x) == 6L) {
      period <- as.integer(substr(x, 5L, 6L))
      valid <- switch(
        frequency,
        CH = period %in% 1:2,
        FH = period %in% 1:2,
        Q = period %in% 1:4,
        M = period %in% 1:12,
        W = period %in% 1:12,
        D = period %in% 1:12,
        FALSE
      )
      if (!valid) {
        boj_abort(
          sprintf("`%s` contains an invalid period for frequency \"%s\".", arg, frequency),
          class = "boj_parameter_error"
        )
      }
    }
  } else if (nchar(x) == 6L) {
    period <- as.integer(substr(x, 5L, 6L))
    if (!period %in% 1:12) {
      boj_abort(
        sprintf("`%s` contains an invalid two-digit period.", arg),
        class = "boj_parameter_error"
      )
    }
  }
  x
}

boj_check_period_order <- function(start_date, end_date) {
  if (!is.null(start_date) && !is.null(end_date) && start_date > end_date) {
    boj_abort("`end_date` must be equal to or later than `start_date`.", class = "boj_parameter_error")
  }
  invisible(NULL)
}

boj_chunks <- function(x, size = .bojapi_max_codes) {
  split(x, ceiling(seq_along(x) / size))
}

boj_pause <- function(wait) {
  wait <- boj_scalar_number(wait, "wait", min = 0)
  if (wait > 0) {
    Sys.sleep(wait)
  }
  invisible(NULL)
}

boj_empty_data <- function() {
  tibble::tibble(
    db = character(),
    series = character(),
    series_code = character(),
    name = character(),
    unit = character(),
    frequency = character(),
    category = character(),
    last_update = as.Date(character()),
    time = character(),
    date = as.Date(character()),
    value = double()
  )
}

boj_empty_metadata <- function() {
  tibble::tibble(
    db = character(), series_code = character(), name = character(),
    unit = character(), frequency = character(), category = character(),
    layer1 = integer(), layer2 = integer(), layer3 = integer(),
    layer4 = integer(), layer5 = integer(), start_time = character(),
    end_time = character(), start_date = as.Date(character()),
    end_date = as.Date(character()), last_update = as.Date(character()),
    notes = character(), is_series = logical(), lang = character()
  )
}
