# Bank of Japan API credit

`bojapi` is an independently developed, unofficial package. It is not
affiliated with, endorsed by, or maintained by the Bank of Japan.

When publishing a service that uses this package, follow the Bank of Japan's
current [Notice Regarding the Use of the API Service](https://www.stat-search.boj.or.jp/info/api_notice_en.pdf).

The requested English credit is:

> This service uses the API provided by the "Bank of Japan Time-Series Data
> Search." The Bank of Japan does not guarantee the content of the service.

The requested Japanese credit is:

> このサービスは、日本銀行時系列統計データ検索サイトの API 機能を使用しています。
> サービスの内容は日本銀行によって保証されたものではありません。

The notice also asks publishers to notify `post.rsd17@boj.or.jp`. The notice can
change without prior notice, so verify the current official version before a
public release.

## Source and rights boundaries

The MIT license applies to the original code and documentation authored for
`bojapi`. It does not relicense Bank of Japan data, metadata, database
identifiers or names, prescribed credit text, official documents, or other
third-party content. Any rights in such content remain with their respective
rightsholders and its use remains subject to the applicable terms.

No Bank of Japan time-series dataset or API manual is bundled with the package.
Numerical observations in test fixtures are synthetic. The fixed database
identifiers and English and Japanese database names used by `boj_databases()`
are based on the Bank of Japan's February 18, 2026 API manuals:

- [API User Manual for BOJ Time-Series Data Search](https://www.stat-search.boj.or.jp/info/api_manual_en.pdf)
- [時系列統計データ検索サイト API 機能利用マニュアル](https://www.stat-search.boj.or.jp/info/api_manual.pdf)

See the installed `COPYRIGHTS` file for a concise inventory.
