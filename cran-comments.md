## Test environments

- local macOS Tahoe 26.5.2 (arm64), R 4.5.2

## R CMD check results

0 errors | 0 warnings | 2 notes

The notes are:

- the expected `New submission` note for version 0.1.0;
- local HTML validation was skipped because the installed HTML Tidy is too old.

The check included CRAN incoming feasibility and URL checks with Internet
access. The rebuilt source tarball passed the top-level file check.

## Submission

This is the first submission of `bojapi`. It is distinct from the existing
`BOJ` package: `bojapi` targets the Bank of Japan's current code, hierarchy, and
metadata API, and provides metadata search, automatic batching, and pagination.
Compared with the multi-central-bank `bbk` package, `bojapi` additionally wraps
the hierarchy endpoint and provides WDI-style search, batching beyond 250
series, complete `NEXTPOSITION` pagination, long/wide normalization, explicit
request pacing, and cache pruning and clearing.

Live API tests are opt-in through `BOJAPI_RUN_LIVE_TESTS=true`; regular tests use
deterministic fixtures and do not contact the Bank of Japan.

## Downstream dependencies

There are no downstream CRAN dependencies because this is a new package.
