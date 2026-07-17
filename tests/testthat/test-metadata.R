test_that("metadata cache avoids repeated API calls", {
  calls <- 0L
  local_mocked_bindings(
    boj_fetch_json = function(...) {
      calls <<- calls + 1L
      fixture_payload(resultset = fixture_metadata("en"))
    },
    .package = "bojapi"
  )
  cache_dir <- tempfile("bojapi-cache-")
  first <- boj_metadata("FM08", cache_dir = cache_dir, wait = 0)
  second <- boj_metadata("FM08", cache_dir = cache_dir, wait = 0)
  expect_equal(calls, 1L)
  expect_equal(first, second, ignore_attr = TRUE)
})

test_that("metadata cache writes replace completed files without leftovers", {
  cache_dir <- tempfile("bojapi-cache-")
  dir.create(cache_dir)
  cache_path <- bojapi:::boj_metadata_cache_file("FM08", "en", cache_dir)
  metadata <- bojapi:::boj_parse_metadata(fixture_metadata("en"), "FM08", "en")

  expect_true(bojapi:::boj_write_metadata_cache(metadata, cache_path))
  updated <- metadata
  updated$name[[1L]] <- "updated"
  expect_true(bojapi:::boj_write_metadata_cache(updated, cache_path))

  expect_identical(readRDS(cache_path)$name[[1L]], "updated")
  files <- setdiff(list.files(cache_dir, all.files = TRUE), c(".", ".."))
  expect_identical(files, basename(cache_path))
})

test_that("expired and invalid metadata cache entries are removed", {
  cache_dir <- tempfile("bojapi-cache-")
  dir.create(cache_dir)
  metadata <- bojapi:::boj_parse_metadata(fixture_metadata("en"), "FM08", "en")

  expired <- bojapi:::boj_metadata_cache_file("FM08", "en", cache_dir)
  saveRDS(metadata, expired)
  Sys.setFileTime(expired, Sys.time() - 3600)
  expect_null(bojapi:::boj_read_metadata_cache(expired, max_age = 60))
  expect_false(file.exists(expired))

  corrupt <- bojapi:::boj_metadata_cache_file("BP01", "en", cache_dir)
  writeBin(charToRaw("not an RDS file"), corrupt)
  expect_null(bojapi:::boj_read_metadata_cache(corrupt, max_age = 60))
  expect_false(file.exists(corrupt))

  wrong_schema <- bojapi:::boj_metadata_cache_file("CO", "en", cache_dir)
  partial <- metadata[, c("db", "series_code", "name", "frequency", "is_series", "lang")]
  saveRDS(partial, wrong_schema)
  expect_null(bojapi:::boj_read_metadata_cache(wrong_schema, max_age = 60))
  expect_false(file.exists(wrong_schema))
})

test_that("metadata cache cleanup never recursively removes directories", {
  cache_dir <- tempfile("bojapi-cache-")
  dir.create(cache_dir)
  cache_path <- bojapi:::boj_metadata_cache_file("FM08", "en", cache_dir)
  dir.create(cache_path)
  marker <- file.path(cache_path, "keep.txt")
  file.create(marker)

  expect_warning(
    expect_null(bojapi:::boj_read_metadata_cache(cache_path, max_age = 60)),
    "Refusing to remove a directory"
  )
  expect_true(dir.exists(cache_path))
  expect_true(file.exists(marker))
})

test_that("boj_cache can prune and clear selected cache entries", {
  cache_dir <- tempfile("bojapi-cache-")
  dir.create(cache_dir)
  metadata <- bojapi:::boj_parse_metadata(fixture_metadata("en"), "FM08", "en")

  fresh <- bojapi:::boj_metadata_cache_file("FM08", "en", cache_dir)
  expired <- bojapi:::boj_metadata_cache_file("BP01", "jp", cache_dir)
  invalid <- bojapi:::boj_metadata_cache_file("CO", "en", cache_dir)
  unrelated <- file.path(cache_dir, "unrelated.rds")
  saveRDS(metadata, fresh)
  saveRDS(metadata, expired)
  Sys.setFileTime(expired, Sys.time() - 3600)
  saveRDS(list(not = "metadata"), invalid)
  saveRDS(list(keep = TRUE), unrelated)

  pruned <- boj_cache(action = "prune", max_age = 60, cache_dir = cache_dir)
  expect_setequal(pruned$file, basename(c(fresh, expired, invalid)))
  expect_identical(pruned$status[pruned$file == basename(fresh)], "kept")
  expect_identical(pruned$reason[pruned$file == basename(fresh)], "fresh")
  expect_identical(pruned$status[pruned$file == basename(expired)], "removed")
  expect_identical(pruned$reason[pruned$file == basename(expired)], "expired")
  expect_identical(pruned$status[pruned$file == basename(invalid)], "removed")
  expect_identical(pruned$reason[pruned$file == basename(invalid)], "invalid")
  expect_true(file.exists(fresh))
  expect_false(file.exists(expired))
  expect_false(file.exists(invalid))
  expect_true(file.exists(unrelated))

  cleared <- boj_cache("FM08", lang = "en", action = "clear", cache_dir = cache_dir)
  expect_identical(cleared$status, "removed")
  expect_identical(cleared$reason, "clear")
  expect_false(file.exists(fresh))

  missing <- boj_cache("FM08", lang = "en", action = "clear", cache_dir = cache_dir)
  expect_identical(missing$status, "missing")
})

test_that("boj_cache validates its management action", {
  expect_error(boj_cache(action = "delete"), class = "boj_parameter_error")
})

test_that("metadata can omit hierarchy headings", {
  local_mocked_bindings(
    boj_fetch_json = function(...) fixture_payload(resultset = fixture_metadata("en")),
    .package = "bojapi"
  )
  out <- boj_metadata("FM08", cache = FALSE, include_groups = FALSE, wait = 0)
  expect_true(all(out$is_series))
  expect_equal(nrow(out), 1L)
})

test_that("boj_search supports literal and regular expression searches", {
  metadata <- bojapi:::boj_parse_metadata(fixture_metadata("en"), "FM08", "en")
  literal <- boj_search("U.S. Dollar", metadata = metadata)
  expect_equal(literal$series_code, "FXERM07")

  regex <- boj_search("dollar|euro", metadata = metadata, regex = TRUE)
  expect_equal(nrow(regex), 1L)

  groups <- boj_search("Daily", metadata = metadata, include_groups = TRUE)
  expect_false(groups$is_series[[1L]])
})

test_that("database registry and credit are complete", {
  expect_equal(nrow(boj_databases()), 50L)
  expect_true(all(c("FM08", "CO", "FF", "BIS") %in% boj_databases()$db))
  credit <- boj_api_credit("en")
  expect_match(credit$credit, "does not guarantee", fixed = TRUE)
  expect_identical(credit$email, "post.rsd17@boj.or.jp")
})
