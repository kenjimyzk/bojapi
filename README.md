**English** | [日本語](https://github.com/kenjimyzk/bojapi/blob/main/README.ja.md)

# bojapi

`bojapi` is an unofficial R package for accessing the official API of the
Bank of Japan Time-Series Data Search site. No API key is required.

Its primary workflow is similar to WDI: search the metadata to find series
codes, specify a period, and retrieve the observations as a data frame. The
package uses JSON internally, avoiding differences in Japanese CSV encodings
and the API behavior of returning errors as JSON even when CSV is requested.

## Features

- `boj_search()`: Search series names, codes, categories, and notes
- `boj_data()`: Retrieve time series by series code
- `boj_layer()`: Retrieve multiple series using the five-level hierarchy
- `boj_metadata()`: Retrieve normalized metadata, including hierarchy,
  coverage, update dates, and notes
- `boj_cache()`: Refresh metadata in a WDIcache-style workflow
- Automatic batching in groups of 250 series and complete `NEXTPOSITION`
  pagination
- Missing values retained as observation rows containing `NA`
- Series aliases through named vectors, with long and wide output
- Frequency-aware date conversion for daily, weekly, monthly, quarterly,
  calendar-half-year, fiscal-half-year, calendar-year, and fiscal-year data
- gzip compression, timeouts, retries, and a default one-second delay between
  pages
- English and Japanese API responses

## Installation

Install the development version from the repository root:

```r
install.packages("remotes")
remotes::install_local(".")
```

After the package is published on GitHub, the intended installation command is:

```r
remotes::install_github("kenjimyzk/bojapi")
```

## Quick start

```r
library(bojapi)

# 1. List available databases
boj_databases()

# 2. Search for a series code (the metadata are cached for 24 hours)
boj_search("U.S. Dollar", db = "FM08")
boj_search("米ドル", db = "FM08", lang = "jp")

# 3. Retrieve monthly U.S. dollar/yen exchange rates
fx <- boj_data(
  db = "FM08",
  code = c(usd_yen = "FXERM07"),
  start_date = "202401",
  end_date = "202412",
  lang = "en"
)

fx
```

Supply series codes without the database prefix. All codes in a single
`boj_data()` call must have the same frequency.

In long output, `time` preserves the original BOJ period code and `date`
contains a parsed date for analysis. For quarterly data, `202402` means the
second quarter of 2024, not February 2024, so it becomes
`date = 2024-04-01`.

```r
# Retrieve multiple series in wide format
fx_wide <- boj_data(
  "FM08",
  c(month_end = "FXERM06", monthly_average = "FXERM07"),
  start_date = "202401",
  end_date = "202412",
  lang = "en",
  wide = TRUE
)
```

## Hierarchy API

You can retrieve a category of series using metadata fields `layer1` through
`layer5`, without listing every series code individually.

```r
meta <- boj_metadata("BP01", lang = "en", include_groups = TRUE)

balance_of_payments <- boj_layer(
  db = "BP01",
  frequency = "M",
  layer = c(1, 1, 1),
  start_date = "202504",
  end_date = "202509",
  lang = "en"
)
```

The BOJ API returns an error when a hierarchy condition matches more than
1,250 series. This limit is evaluated before the `frequency` filter. If it is
exceeded, split the query by the first hierarchy level or another suitable
level.

## Comparison with existing R packages

Because a package named `BOJ` already exists on CRAN, this package is named
`bojapi`.

| Package | Primary data source | New code API | Hierarchy API | WDI-style search | Automatic batching beyond 250 series |
|---|---|---:|---:|---:|---:|
| `BOJ` | Legacy bulk flat files | - | - | - | - |
| `bbk` | Multiple central-bank APIs | ✓ | - | - | - |
| `bojapi` | Dedicated BOJ new-API client | ✓ | ✓ | ✓ | ✓ |

`bojapi` is a dedicated client that also handles normalized hierarchy and
coverage metadata, missing observations, automatic pagination, and delays
between requests.

## Request rate and errors

The BOJ prohibits high-frequency access over a short period. When an operation
requires multiple requests, `bojapi` waits one second by default. Do not shorten
this interval; increase it when appropriate.

```r
options(bojapi.wait = 2, bojapi.timeout = 60, bojapi.retries = 3)
```

API errors have class `boj_api_response_error`, communication errors have class
`boj_http_error`, and unexpected response structures have class
`boj_parse_error`. A no-data response (`M181030I`) is not an error: the package
issues a warning and returns an empty tibble with consistent column types.

## Credit for public services

If you publish a service that uses this package, follow the Bank of Japan's
[Notice Regarding the Use of the API Service](https://www.stat-search.boj.or.jp/info/api_notice_en.pdf),
including displaying the requested credit and notifying the Research and
Statistics Department about the release.

```r
boj_api_credit("en")
```

The terms may change without notice, so always check the official document
before publishing a service. The package's MIT license applies only to its
source code; it does not relicense data, metadata, documents, or other material
provided by the Bank of Japan.

## API documentation

- [API Manual](https://www.stat-search.boj.or.jp/info/api_manual_en.pdf)
- [Notice Regarding the Use of the API Service](https://www.stat-search.boj.or.jp/info/api_notice_en.pdf)
- [Japanese API Manual](https://www.stat-search.boj.or.jp/info/api_manual.pdf)
- [Japanese Notice Regarding the Use of the API Service](https://www.stat-search.boj.or.jp/info/api_notice.pdf)
