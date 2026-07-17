## Test environments

- macOS, R 4.5.2

## R CMD check results

0 errors | 0 warnings | 2 notes

The notes are:

- the expected `New submission` note for version 0.1.0;
- local HTML validation was skipped because the installed HTML Tidy is too old.

Live API tests are opt-in through `BOJAPI_RUN_LIVE_TESTS=true`; regular tests use
deterministic fixtures and do not contact the Bank of Japan.
