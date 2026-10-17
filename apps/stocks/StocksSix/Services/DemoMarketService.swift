import Foundation

struct DemoMarketService: MarketProviding {
  static let timestamp = Date(timeIntervalSince1970: 1_344_254_400)
  func chart(symbol: String, range: ChartRange) async throws -> StockChart {
    let index = Stock.catalog.firstIndex { $0.symbol == symbol } ?? 2
    let prices = [
      3023.37, 1406.08, 633.84, 668.73, 5864.78, 6974.39, 8929.88, 30.91, 14.23, 234.38,
    ]
    let price = prices[index % prices.count]
    let change = [0.85, 1.97, 3.84, -8.72, 32.90, 64.71, -44.73][index % 7]
    let points = (0..<100).map { step in
      let x = Double(step)
      let trend = 0.78 + x * 0.0018 + sin(x * 0.085) * 0.10
      let detail = sin(x * 1.9) * 0.009 + cos(x * 0.71) * 0.028
      let span: Double = range == .day ? 234 : range == .week ? 4300 : 150000
      return PricePoint(
        date: Self.timestamp.addingTimeInterval((x - 99) * span), close: price * (trend + detail),
        volume: 1e6 * (0.3 + abs(sin(x * 1.72))))
    }
    return StockChart(
      quote: StockQuote(
        symbol: symbol, price: price, previousClose: price - change, open: price - 2.31,
        high: price + 3.87, low: price - 8.56, volume: 92.57e6,
        marketCap: symbol.hasPrefix("^") ? nil : price * 937e6,
        yearHigh: price * 1.06, yearLow: price * 0.60,
        currency: symbol == "^N225"
          ? "JPY" : symbol == "^FTSE" ? "GBP" : symbol == "^GDAXI" ? "EUR" : "USD",
        exchange: Stock.catalog.first { $0.symbol == symbol }?.exchange ?? "NASDAQ",
        timestamp: Self.timestamp, marketStart: nil, marketEnd: nil), points: points)
  }
  func search(_ query: String) async throws -> [Stock] { Stock.localSearch(query) }
  func news(symbol: String) async throws -> [StockNews] {
    [
      StockNews(
        id: "demo-1", title: L10n.text("Demo Headline 1"), publisher: L10n.text("Demo News"),
        url: URL(
          string:
            "https://finance.yahoo.com/quote/\(symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol)/"
        )!, date: Self.timestamp),
      StockNews(
        id: "demo-2", title: L10n.text("Demo Headline 2"), publisher: L10n.text("Demo News"),
        url: URL(string: "https://finance.yahoo.com/")!,
        date: Self.timestamp.addingTimeInterval(-3600)),
      StockNews(
        id: "demo-3", title: L10n.text("Demo Headline 3"), publisher: L10n.text("Demo News"),
        url: URL(string: "https://finance.yahoo.com/")!,
        date: Self.timestamp.addingTimeInterval(-7200)),
    ]
  }
}
