.boj_databases <- data.frame(
  db = c(
    "IR01", "IR02", "IR03", "IR04",
    "FM01", "FM02", "FM03", "FM04", "FM05", "FM06", "FM07", "FM08", "FM09",
    "PS01", "PS02",
    "MD01", "MD02", "MD03", "MD04", "MD05", "MD06", "MD07", "MD08", "MD09",
    "MD10", "MD11", "MD12", "MD13", "MD14",
    "LA01", "LA02", "LA03", "LA04", "LA05",
    "BS01", "BS02", "FF", "OB01", "OB02", "CO",
    "PR01", "PR02", "PR03", "PR04", "PF01", "PF02",
    "BP01", "BIS", "DER", "OT"
  ),
  category_en = c(
    rep("Interest Rates on Deposits and Loans", 4),
    rep("Financial Markets", 9),
    rep("Payment and Settlement", 2),
    rep("Money, Deposits and Loans", 19),
    rep("Balance Sheets", 2), "Flow of Funds",
    rep("Other Bank of Japan Statistics", 2), "TANKAN",
    rep("Prices", 4), rep("Public Finance", 2),
    rep("Balance of Payments and BIS-Related Statistics", 3), "Others"
  ),
  name_en = c(
    "The Basic Discount Rates and Basic Loan Rates",
    "Average Interest Rates Posted at Financial Institutions by Type of Deposit",
    "Average Interest Rates on Time Deposits by Term",
    "Average Contract Interest Rates on Loans and Discounts",
    "Uncollateralized Overnight Call Rate (average)",
    "Short-term Money Market Rates",
    "Amounts Outstanding in Short-term Money Market",
    "Amounts Outstanding in the Call Money Market",
    "Issuance, Redemption, and Outstanding of Public and Corporate Bonds",
    "Trading of Interest-bearing Government Bonds by Purchaser",
    "Government Bonds Sales Over the Counter / Counter Sales Ratio",
    "Foreign Exchange Rates",
    "Effective Exchange Rate",
    "Other Payment and Settlement Systems",
    "Basic Figures on Fails",
    "Monetary Base", "Money Stock", "Monetary Survey",
    "Changes in Money Stock (M2+CDs) and Credit", "Currency in Circulation",
    "Sources of Changes in BOJ Current Account Balances and Market Operations",
    "Reserves", "BOJ Current Account Balances by Sector",
    "Monetary Base and the Bank of Japan's Transactions",
    "Amounts Outstanding of Deposits by Depositor",
    "Deposits, Vault Cash, and Loans and Bills Discounted",
    "Deposits, Vault Cash, and Loans and Bills Discounted by Prefecture",
    "Principal Figures of Financial Institutions",
    "Time Deposits: Amounts Outstanding and New Deposits by Maturity",
    "Loans and Bills Discounted by Sector",
    "Loans and Discounts by the Bank of Japan", "Outstanding of Loans (Others)",
    "Commitment Lines Extended by Japanese Banks",
    "Senior Loan Officer Opinion Survey on Bank Lending Practices",
    "Bank of Japan Accounts", "Financial Institutions Accounts", "Flow of Funds",
    "Bank of Japan's Transactions with the Government",
    "Collateral Accepted by the Bank of Japan", "TANKAN",
    "Corporate Goods Price Index (CGPI)",
    "Services Producer Price Index (SPPI)",
    "Input-Output Price Index of the Manufacturing Industry by Sector",
    "Final Demand-Intermediate Demand Price Indexes",
    "Statement of Receipts and Payments of the Treasury Accounts",
    "National Government Debt", "Balance of Payments",
    "BIS International Banking Statistics in Japan",
    "Regular Derivatives Market Statistics in Japan", "Others"
  ),
  name_jp = c(
    "\u57FA\u6E96\u5272\u5F15\u7387\u304A\u3088\u3073\u57FA\u6E96\u8CB8\u4ED8\u5229\u7387", "\u9810\u91D1\u7A2E\u985E\u5225\u5E97\u982D\u8868\u793A\u91D1\u5229\u306E\u5E73\u5747\u5E74\u5229\u7387\u7B49",
    "\u5B9A\u671F\u9810\u91D1\u306E\u9810\u5165\u671F\u9593\u5225\u5E73\u5747\u91D1\u5229", "\u8CB8\u51FA\u7D04\u5B9A\u5E73\u5747\u91D1\u5229",
    "\u7121\u62C5\u4FDD\u30B3\u30FC\u30EB\uFF2F\uFF0F\uFF2E\u7269\u30EC\u30FC\u30C8\uFF08\u6BCE\u55B6\u696D\u65E5\uFF09", "\u77ED\u671F\u91D1\u878D\u5E02\u5834\u91D1\u5229",
    "\u77ED\u671F\u91D1\u878D\u5E02\u5834\u6B8B\u9AD8", "\u30B3\u30FC\u30EB\u5E02\u5834\u6B8B\u9AD8", "\u516C\u793E\u50B5\u767A\u884C\u30FB\u511F\u9084\u304A\u3088\u3073\u73FE\u5B58\u984D",
    "\u516C\u793E\u50B5\u6D88\u5316\u72B6\u6CC1\uFF08\u5229\u4ED8\u56FD\u50B5\uFF09", "\u56FD\u50B5\u7A93\u53E3\u8CA9\u58F2\u984D\u30FB\u7A93\u53E3\u8CA9\u58F2\u7387",
    "\u5916\u56FD\u70BA\u66FF\u5E02\u6CC1", "\u5B9F\u52B9\u70BA\u66FF\u30EC\u30FC\u30C8", "\u5404\u7A2E\u6C7A\u6E08", "\u30D5\u30A7\u30A4\u30EB\u306E\u767A\u751F\u72B6\u6CC1",
    "\u30DE\u30CD\u30BF\u30EA\u30FC\u30D9\u30FC\u30B9", "\u30DE\u30CD\u30FC\u30B9\u30C8\u30C3\u30AF", "\u30DE\u30CD\u30BF\u30EA\u30FC\u30B5\u30FC\u30D9\u30A4",
    "\u30DE\u30CD\u30FC\u30B5\u30D7\u30E9\u30A4\uFF08M2+CD\uFF09\u5897\u6E1B\u3068\u4FE1\u7528\u9762\u306E\u5BFE\u5FDC", "\u901A\u8CA8\u6D41\u901A\u9AD8",
    "\u65E5\u9280\u5F53\u5EA7\u9810\u91D1\u5897\u6E1B\u8981\u56E0\u3068\u91D1\u878D\u8ABF\u7BC0\uFF08\u5B9F\u7E3E\uFF09", "\u6E96\u5099\u9810\u91D1\u984D",
    "\u696D\u614B\u5225\u306E\u65E5\u9280\u5F53\u5EA7\u9810\u91D1\u6B8B\u9AD8", "\u30DE\u30CD\u30BF\u30EA\u30FC\u30D9\u30FC\u30B9\u3068\u65E5\u672C\u9280\u884C\u306E\u53D6\u5F15",
    "\u9810\u91D1\u8005\u5225\u9810\u91D1", "\u9810\u91D1\u30FB\u73FE\u91D1\u30FB\u8CB8\u51FA\u91D1", "\u90FD\u9053\u5E9C\u770C\u5225\u9810\u91D1\u30FB\u73FE\u91D1\u30FB\u8CB8\u51FA\u91D1",
    "\u8CB8\u51FA\u30FB\u9810\u91D1\u52D5\u5411", "\u5B9A\u671F\u9810\u91D1\u306E\u6B8B\u9AD8\u304A\u3088\u3073\u65B0\u898F\u53D7\u5165\u9AD8", "\u8CB8\u51FA\u5148\u5225\u8CB8\u51FA\u91D1",
    "\u65E5\u672C\u9280\u884C\u8CB8\u51FA", "\u305D\u306E\u4ED6\u8CB8\u51FA\u6B8B\u9AD8", "\u30B3\u30DF\u30C3\u30C8\u30E1\u30F3\u30C8\u30E9\u30A4\u30F3\u5951\u7D04\u984D\u3001\u5229\u7528\u984D",
    "\u4E3B\u8981\u9280\u884C\u8CB8\u51FA\u52D5\u5411\u30A2\u30F3\u30B1\u30FC\u30C8\u8ABF\u67FB", "\u65E5\u672C\u9280\u884C\u52D8\u5B9A", "\u6C11\u9593\u91D1\u878D\u6A5F\u95A2\u306E\u8CC7\u7523\u30FB\u8CA0\u50B5",
    "\u8CC7\u91D1\u5FAA\u74B0", "\u65E5\u672C\u9280\u884C\u306E\u5BFE\u653F\u5E9C\u53D6\u5F15", "\u65E5\u672C\u9280\u884C\u304C\u53D7\u5165\u308C\u3066\u3044\u308B\u62C5\u4FDD\u306E\u6B8B\u9AD8",
    "\u77ED\u89B3", "\u4F01\u696D\u7269\u4FA1\u6307\u6570", "\u4F01\u696D\u5411\u3051\u30B5\u30FC\u30D3\u30B9\u4FA1\u683C\u6307\u6570",
    "\u88FD\u9020\u696D\u90E8\u9580\u5225\u6295\u5165\u30FB\u7523\u51FA\u7269\u4FA1\u6307\u6570", "\u6700\u7D42\u9700\u8981\u30FB\u4E2D\u9593\u9700\u8981\u7269\u4FA1\u6307\u6570",
    "\u8CA1\u653F\u8CC7\u91D1\u53CE\u652F", "\u653F\u5E9C\u50B5\u52D9", "\u56FD\u969B\u53CE\u652F\u7D71\u8A08",
    "BIS\u56FD\u969B\u8CC7\u91D1\u53D6\u5F15\u7D71\u8A08\u304A\u3088\u3073\u56FD\u969B\u4E0E\u4FE1\u7D71\u8A08\u306E\u65E5\u672C\u5206\u96C6\u8A08\u7D50\u679C",
    "\u30C7\u30EA\u30D0\u30C6\u30A3\u30D6\u53D6\u5F15\u306B\u95A2\u3059\u308B\u5B9A\u4F8B\u5E02\u5834\u5831\u544A", "\u305D\u306E\u4ED6"
  ),
  stringsAsFactors = FALSE
)

#' List Bank of Japan API databases
#'
#' Returns the database identifiers accepted by `db` in the BOJ API. The
#' registry follows the February 18, 2026 API manual. New databases may be
#' accepted by the API before this package registry is updated.
#'
#' @return A tibble with database code, English category, and English and
#'   Japanese database names.
#' @export
#' @examples
#' boj_databases()
#' subset(boj_databases(), grepl("Exchange", name_en))
boj_databases <- function() {
  tibble::as_tibble(.boj_databases)
}
