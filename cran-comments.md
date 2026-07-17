## Test environments

- local macOS Tahoe 26.5.2 (arm64), R 4.5.2
- GitHub Actions, Ubuntu 24.04.4 LTS (x86_64), R 4.6.1
- R-hub, Ubuntu 24.04.4 LTS (x86_64), R-devel
  (2026-06-21 r90185)
- R-hub, Windows Server 2022 x64 (x86_64), R-devel
  (2026-07-16 r90264 ucrt)
- R-hub, macOS Sequoia 15.7.7 (x86_64), R-devel
  (2026-06-24 r90190)

## R CMD check results

The GitHub Actions and R-hub checks for commit
`2c5ffc68bc0f8b0b8ce56c235b4ca002ecd74bc1` completed with:

0 errors | 0 warnings | 0 notes

- [GitHub Actions R-release check](https://github.com/kenjimyzk/bojapi/actions/runs/29555461158)
- [R-hub R-devel checks on Linux, Windows, and macOS](https://github.com/kenjimyzk/bojapi/actions/runs/29555705848)

The local `R CMD check --as-cran` completed with:

0 errors | 0 warnings | 2 notes

The local notes are:

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
