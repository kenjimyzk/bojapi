# bojapi 0.1.0

- Initial implementation of the BOJ code, layer, and metadata APIs.
- Automatic 250-code chunking and `NEXTPOSITION` pagination.
- Request pacing with a one-second minimum, retries, and timeouts.
- Metadata caching with automatic stale-entry removal and explicit refresh,
  prune, and clear operations.
- Long and wide data outputs with exact BOJ period codes and parsed dates.
