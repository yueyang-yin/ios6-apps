import SwiftUI

struct StockSummaryView: View {
  let store: StocksStore
  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        Text(store.selectedStock?.displayName() ?? L10n.text("Select a Stock"))
          .font(StockTheme.font(21, bold: true)).multilineTextAlignment(.center)
          .shadow(color: .black, radius: 0, y: 1)
          .accessibilityIdentifier("company-name")
        if let quote = store.selectedQuote {
          Text("\(quote.exchange) · \(quote.currency)").font(StockTheme.font(12)).foregroundStyle(
            .white.opacity(0.75))
          HStack(alignment: .top, spacing: 20) {
            VStack(spacing: 12) {
              metric("Open", StockFormat.number(quote.open))
              metric("High", StockFormat.number(quote.high))
              metric("Low", StockFormat.number(quote.low))
              metric("Volume", StockFormat.compact(quote.volume))
            }
            VStack(spacing: 12) {
              metric("Market Cap", StockFormat.compact(quote.marketCap))
              metric("52W High", StockFormat.number(quote.yearHigh))
              metric("52W Low", StockFormat.number(quote.yearLow))
              metric("Previous Close", StockFormat.number(quote.previousClose))
            }
          }
          Text(L10n.text(quote.isMarketOpen(at: Date()) ? "Market Open" : "Market Closed"))
            .font(StockTheme.font(13, bold: true))
          Text(L10n.text("Missing Metrics"))
            .font(StockTheme.font(11)).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(
              .center)
        } else {
          Text(L10n.text(store.refreshing ? "Loading" : "Quote Unavailable"))
          Button(L10n.text("Refresh Quotes")) { Task { await store.refresh() } }.buttonStyle(
            GlossyButtonStyle(blue: true))
        }
      }
      .padding(.horizontal, 18).padding(.vertical, 16)
    }
    .background(
      LinearGradient(
        colors: [Color(red: 0.25, green: 0.35, blue: 0.51), StockTheme.blue], startPoint: .top,
        endPoint: .bottom)
    )
    .accessibilityIdentifier("summary-page")
  }
  private func metric(_ key: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Text(L10n.text(key)).foregroundStyle(.white.opacity(0.65)).font(StockTheme.font(12))
      Spacer(minLength: 1)
      Text(value).font(StockTheme.font(14, bold: true)).minimumScaleFactor(0.7).lineLimit(1)
    }
    .accessibilityElement(children: .combine)
  }
}

struct StockNewsView: View {
  let store: StocksStore
  var body: some View {
    VStack(spacing: 0) {
      Text(store.selectedStock?.displayName() ?? L10n.text("News"))
        .font(StockTheme.font(17, bold: true)).lineLimit(1).minimumScaleFactor(0.7)
        .padding(12)
      if let items = store.headlines[store.selectedSymbol], !items.isEmpty {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(items) { item in
              Link(destination: item.url) {
                HStack(alignment: .center, spacing: 10) {
                  VStack(alignment: .leading, spacing: 5) {
                    Text(item.title).font(StockTheme.font(15, bold: true)).multilineTextAlignment(
                      .leading)
                    Text("\(item.publisher) · \(StockFormat.date(item.date, time: true))")
                      .font(StockTheme.font(11)).foregroundStyle(.white.opacity(0.65))
                  }
                  Spacer(minLength: 0)
                  Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                }.padding(.horizontal, 14).padding(.vertical, 12)
              }
              .contextMenu {
                Link(L10n.text("Open Article"), destination: item.url)
                ShareLink(item: item.url) { Text(L10n.text("Share Article")) }
              }
              .overlay(alignment: .bottom) { Color.white.opacity(0.2).frame(height: 0.5) }
            }
          }
        }
        .refreshable { await store.loadNews(force: true) }
      } else {
        StockEmptyPanel(
          title: L10n.text(
            store.loadingNews
              ? "Loading News"
              : store.newsFailures.contains(store.selectedSymbol) ? "News Unavailable" : "No News"),
          retry: { Task { await store.loadNews(force: true) } })
      }
      Text(L10n.text(store.demo ? "Demo News Notice" : "News Language Notice"))
        .font(StockTheme.font(10)).foregroundStyle(.white.opacity(0.65)).padding(6)
    }
    .background(
      LinearGradient(
        colors: [Color(red: 0.25, green: 0.35, blue: 0.51), StockTheme.blue], startPoint: .top,
        endPoint: .bottom)
    )
    .accessibilityIdentifier("news-page")
  }
}
