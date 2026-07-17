#' Return the Bank of Japan API credit and release notice
#'
#' The BOJ asks publishers of services using its API to show a specified
#' credit and notify its Research and Statistics Department. The terms can
#' change without prior notice; verify the linked official notice before
#' releasing a service.
#'
#' @param lang Credit language, `"en"` or `"jp"`.
#'
#' @return A named list containing the requested credit, contact address,
#'   subject line, and official notice URL.
#' @export
#' @examples
#' boj_api_credit("en")
#' boj_api_credit("jp")$credit
boj_api_credit <- function(lang = c("en", "jp")) {
  lang <- match.arg(lang)

  if (identical(lang, "jp")) {
    return(list(
      credit = paste0(
        "\u3053\u306E\u30B5\u30FC\u30D3\u30B9\u306F\u3001\u65E5\u672C\u9280\u884C\u6642\u7CFB\u5217\u7D71\u8A08\u30C7\u30FC\u30BF\u691C\u7D22\u30B5\u30A4\u30C8\u306E API \u6A5F\u80FD\u3092\u4F7F\u7528\u3057\u3066\u3044\u307E\u3059\u3002",
        "\u30B5\u30FC\u30D3\u30B9\u306E\u5185\u5BB9\u306F\u65E5\u672C\u9280\u884C\u306B\u3088\u3063\u3066\u4FDD\u8A3C\u3055\u308C\u305F\u3082\u306E\u3067\u306F\u3042\u308A\u307E\u305B\u3093\u3002"
      ),
      email = "post.rsd17@boj.or.jp",
      subject = "\u3010\u691C\u7D22\u30B5\u30A4\u30C8 API \u3092\u5229\u7528\u3057\u305F\u30B5\u30FC\u30D3\u30B9\u516C\u958B\u3011",
      notice_url = "https://www.stat-search.boj.or.jp/info/api_notice.pdf"
    ))
  }

  list(
    credit = paste0(
      "This service uses the API provided by the \"Bank of Japan Time-Series Data Search.\" ",
      "The Bank of Japan does not guarantee the content of the service."
    ),
    email = "post.rsd17@boj.or.jp",
    subject = "[Release of the service using the API]",
    notice_url = "https://www.stat-search.boj.or.jp/info/api_notice_en.pdf"
  )
}
