fixture_series <- function(
    code = "FXERM07",
    lang = "en",
    frequency = "MONTHLY",
    times = list(202401L, 202402L),
    values = list(146.59, NULL)) {
  out <- list(
    SERIES_CODE = code,
    FREQUENCY = frequency,
    LAST_UPDATE = 20260703L,
    VALUES = list(SURVEY_DATES = times, VALUES = values)
  )
  if (lang == "jp") {
    out$NAME_OF_TIME_SERIES_J <- "東京市場 ドル・円"
    out$UNIT_J <- "円／米ドル"
    out$CATEGORY_J <- "外国為替市況"
  } else {
    out$NAME_OF_TIME_SERIES <- "U.S. Dollar/Yen, Tokyo Market"
    out$UNIT <- "Yen per U.S. Dollar"
    out$CATEGORY <- "Foreign Exchange Rates"
  }
  out
}

fixture_payload <- function(
    resultset = list(fixture_series()),
    next_position = NULL,
    message_id = "M181000I") {
  list(
    STATUS = 200L,
    MESSAGEID = message_id,
    MESSAGE = "Successfully completed",
    DATE = "2026-07-17T09:00:00+09:00",
    NEXTPOSITION = next_position,
    RESULTSET = resultset
  )
}

fixture_metadata <- function(lang = "en") {
  group <- list(
    SERIES_CODE = "", FREQUENCY = "", LAYER1 = 1L, LAYER2 = 0L,
    LAYER3 = 0L, LAYER4 = 0L, LAYER5 = 0L,
    START_OF_THE_TIME_SERIES = "", END_OF_THE_TIME_SERIES = "",
    LAST_UPDATE = ""
  )
  series <- list(
    SERIES_CODE = "FXERM07", FREQUENCY = "MONTHLY",
    LAYER1 = 2L, LAYER2 = 1L, LAYER3 = 2L, LAYER4 = 0L, LAYER5 = 0L,
    START_OF_THE_TIME_SERIES = "197301",
    END_OF_THE_TIME_SERIES = "202606",
    LAST_UPDATE = "20260703"
  )
  if (lang == "jp") {
    group$NAME_OF_TIME_SERIES_J <- "外国為替市況（日次）"
    group$NAME_OF_TIME_SERIES <- "Foreign Exchange Rates (Daily)"
    series$NAME_OF_TIME_SERIES_J <- "東京市場 ドル・円 月中平均"
    series$NAME_OF_TIME_SERIES <- "U.S. Dollar/Yen, Monthly Average"
    series$UNIT_J <- "円／米ドル"
    series$UNIT <- "Yen per U.S. Dollar"
    series$CATEGORY_J <- "外国為替市況"
    series$CATEGORY <- "Foreign Exchange Rates"
    series$NOTES_J <- "注(a)参照。"
    series$NOTES <- "See note (a)."
  } else {
    group$NAME_OF_TIME_SERIES <- "Foreign Exchange Rates (Daily)"
    series$NAME_OF_TIME_SERIES <- "U.S. Dollar/Yen, Monthly Average"
    series$UNIT <- "Yen per U.S. Dollar"
    series$CATEGORY <- "Foreign Exchange Rates"
    series$NOTES <- "See note (a)."
  }
  list(group, series)
}

