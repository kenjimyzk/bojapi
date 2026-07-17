# bojapi

`bojapi` は、日本銀行「時系列統計データ検索サイト」の公式APIにRから
アクセスするための非公式パッケージです。APIキーは不要です。

WDIと同じように「メタデータを検索して系列コードを見つけ、期間を指定して
データフレームとして取得する」流れを中心にしています。内部通信はJSONを
使い、日本語CSVの文字コード差や、CSV指定時にもエラーだけJSONで返る仕様を
避けています。

## 主な機能

- `boj_search()`: 系列名・コード・カテゴリ・備考を検索
- `boj_data()`: 系列コードによる時系列取得
- `boj_layer()`: 5階層の分類による一括取得
- `boj_metadata()`: 階層・収録期間・更新日・備考を含む全メタデータ
- `boj_cache()`: WDIcache型のメタデータ更新
- 250系列ごとの自動分割と`NEXTPOSITION`の完全追跡
- 欠損値を`NA`の観測行として保持
- named vectorによる系列名の付与、long／wide出力
- 日次・月次・四半期・半期・年度を区別した日付変換
- gzip、timeout、再試行、ページ間の既定1秒待機
- 英語・日本語レスポンス

## インストール

開発版はリポジトリのルートからインストールできます。

```r
install.packages("remotes")
remotes::install_local(".")
```

公開後は次の形式を想定しています。

```r
remotes::install_github("kenjimyzk/bojapi")
```

## クイックスタート

```r
library(bojapi)

# 1. DBを確認
boj_databases()

# 2. 系列コードを検索（結果は24時間キャッシュ）
boj_search("U.S. Dollar", db = "FM08")
boj_search("米ドル", db = "FM08", lang = "jp")

# 3. 月次のドル円を取得
fx <- boj_data(
  db = "FM08",
  code = c(usd_yen = "FXERM07"),
  start_date = "202401",
  end_date = "202412"
)

fx
```

long形式では、BOJの期間コードを`time`にそのまま保持し、分析用の日付を
`date`に格納します。四半期の`202402`は2024年2月ではなく、2024年第2四半期
なので`date = 2024-04-01`になります。

```r
# 複数系列をwide形式で取得
fx_wide <- boj_data(
  "FM08",
  c(month_end = "FXERM06", monthly_average = "FXERM07"),
  start_date = "202401",
  end_date = "202412",
  wide = TRUE
)
```

## 階層API

系列コードを個別に並べなくても、メタデータの`layer1`～`layer5`を使って
カテゴリ単位で取得できます。

```r
meta <- boj_metadata("BP01", include_groups = TRUE)

balance_of_payments <- boj_layer(
  db = "BP01",
  frequency = "M",
  layer = c(1, 1, 1),
  start_date = "202504",
  end_date = "202509"
)
```

階層条件が1,250系列を超える場合、BOJ APIは`frequency`で絞る前にエラーを
返します。その場合は階層1などを分割してください。

## 既存Rパッケージとの違い

CRANにはすでに`BOJ`があるため、本パッケージ名は`bojapi`としています。

| パッケージ | 主な対象 | 新APIコード取得 | 階層API | WDI型検索 | 250系列超の自動分割 |
|---|---|---:|---:|---:|---:|
| `BOJ` | 従来の一括フラットファイル | - | - | - | - |
| `bbk` | 複数中央銀行API | ✓ | - | - | - |
| `bojapi` | BOJ新API専用 | ✓ | ✓ | ✓ | ✓ |

`bojapi` は、新APIの全メタデータ項目、欠損観測、自動ページング、アクセス間隔
まで含めて扱う専用クライアントです。

## アクセス頻度とエラー

BOJは短時間の高頻度アクセスを禁止しています。複数リクエストが必要な場合、
`bojapi`は既定で1秒待機します。短縮せず、必要に応じて長くしてください。

```r
options(bojapi.wait = 2, bojapi.timeout = 60, bojapi.retries = 3)
```

APIエラーは`boj_api_response_error`、通信エラーは`boj_http_error`、構造変更等は
`boj_parse_error`クラスを持つconditionとして返ります。該当データなし
（`M181030I`）はエラーではなく、warningと型の揃った空tibbleを返します。

## 公開サービスでのクレジット

本パッケージを使ったサービスを公開する場合、日本銀行の
[API機能利用時の留意点](https://www.stat-search.boj.or.jp/info/api_notice.pdf)
に従い、指定クレジットを表示し、調査統計局へ公開を連絡してください。

```r
boj_api_credit("jp")
```

利用条件は予告なく変更されるため、公開前に必ず公式文書を再確認してください。
本パッケージのMITライセンスはソースコードだけに適用され、日本銀行のデータ、
メタデータ、文書等を再ライセンスするものではありません。

## 仕様資料

- [API機能利用マニュアル](https://www.stat-search.boj.or.jp/info/api_manual.pdf)
- [API機能利用時の留意点](https://www.stat-search.boj.or.jp/info/api_notice.pdf)
- [英語版APIマニュアル](https://www.stat-search.boj.or.jp/info/api_manual_en.pdf)

