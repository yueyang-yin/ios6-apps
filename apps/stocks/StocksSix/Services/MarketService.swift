import Foundation

protocol MarketProviding: Sendable {
  func chart(symbol: String, range: ChartRange) async throws -> StockChart
  func search(_ query: String) async throws -> [Stock]
  func news(symbol: String) async throws -> [StockNews]
}

enum MarketError: Error {
  case unavailable, invalidSymbol, noPrices
}

struct MarketService: MarketProviding {
  private func request(path: String, parameters: [String: String]) async throws -> Data {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "query1.finance.yahoo.com"
    components.path = path
    components.queryItems = parameters.sorted { $0.key < $1.key }.map {
      URLQueryItem(name: $0.key, value: $0.value)
    }
    guard let url = components.url else { throw MarketError.invalidSymbol }
    var request = URLRequest(url: url)
    request.timeoutInterval = 18
    request.setValue("StocksSix/1.0", forHTTPHeaderField: "User-Agent")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw MarketError.unavailable
    }
    return data
  }
  func chart(symbol: String, range: ChartRange) async throws -> StockChart {
    let data = try await request(
      path: "/v8/finance/chart/\(symbol)",
      parameters: [
        "range": range.apiRange, "interval": range.interval, "includePrePost": "false",
      ])
    return try Self.decodeChart(data, range: range)
  }
  static func decodeChart(_ data: Data, range: ChartRange) throws -> StockChart {
    let envelope = try JSONDecoder().decode(ChartEnvelope.self, from: data)
    guard let result = envelope.chart.result?.first else { throw MarketError.invalidSymbol }
    let meta = result.meta
    guard let price = meta.regularMarketPrice, price.isFinite else { throw MarketError.noPrices }
    let values = result.indicators.quote.first
    let timestamps = result.timestamp ?? []
    let points = timestamps.enumerated().compactMap { index, timestamp -> PricePoint? in
      guard let close = values?.close, index < close.count, let value = close[index], value.isFinite
      else { return nil }
      let volume = values?.volume.flatMap { index < $0.count ? $0[index] : nil } ?? 0
      return PricePoint(
        date: Date(timeIntervalSince1970: timestamp), close: value, volume: max(0, volume))
    }
    // chartPreviousClose is the range baseline; only a one-day request can use it for daily change.
    let previous = meta.previousClose ?? (range == .day ? meta.chartPreviousClose : nil)
    let regular = meta.currentTradingPeriod?.regular
    let quote = StockQuote(
      symbol: meta.symbol, price: price, previousClose: previous,
      open: range == .day ? values?.open?.compactMap { $0 }.first : nil,
      high: meta.regularMarketDayHigh, low: meta.regularMarketDayLow,
      volume: meta.regularMarketVolume, marketCap: meta.marketCap,
      yearHigh: meta.fiftyTwoWeekHigh, yearLow: meta.fiftyTwoWeekLow,
      currency: meta.currency ?? "", exchange: meta.fullExchangeName ?? meta.exchangeName ?? "",
      timestamp: Date(timeIntervalSince1970: meta.regularMarketTime ?? 0),
      marketStart: regular.map { Date(timeIntervalSince1970: $0.start) },
      marketEnd: regular.map { Date(timeIntervalSince1970: $0.end) }
    )
    return StockChart(quote: quote, points: points)
  }
  func search(_ query: String) async throws -> [Stock] {
    let data = try await searchData(query, count: 15, news: 0)
    return try JSONDecoder().decode(SearchEnvelope.self, from: data).quotes?.compactMap {
      guard let symbol = $0.symbol, $0.isYahooFinance != false else { return nil }
      return Stock(
        symbol: symbol, name: $0.longname ?? $0.shortname ?? symbol, exchange: $0.exchDisp ?? "")
    } ?? []
  }
  func news(symbol: String) async throws -> [StockNews] {
    let data = try await searchData(symbol, count: 0, news: 12)
    return try JSONDecoder().decode(SearchEnvelope.self, from: data).news?.compactMap {
      guard let url = URL(string: $0.link), url.scheme == "https" else { return nil }
      return StockNews(
        id: $0.uuid, title: $0.title, publisher: $0.publisher, url: url,
        date: Date(timeIntervalSince1970: $0.providerPublishTime))
    } ?? []
  }
  private func searchData(_ query: String, count: Int, news: Int) async throws -> Data {
    try await request(
      path: "/v1/finance/search",
      parameters: [
        "q": query, "quotesCount": String(count), "newsCount": String(news),
      ])
  }
}

private struct ChartEnvelope: Decodable {
  var chart: ChartBody
  struct ChartBody: Decodable { var result: [Result]? }
  struct Result: Decodable {
    var meta: Meta
    var timestamp: [Double]?
    var indicators: Indicators
  }
  struct Meta: Decodable {
    var symbol: String
    var regularMarketPrice: Double?
    var previousClose: Double?
    var chartPreviousClose: Double?
    var regularMarketTime: Double?
    var regularMarketDayHigh: Double?
    var regularMarketDayLow: Double?
    var regularMarketVolume: Double?
    var marketCap: Double?
    var fiftyTwoWeekHigh: Double?
    var fiftyTwoWeekLow: Double?
    var currency: String?
    var exchangeName: String?
    var fullExchangeName: String?
    var currentTradingPeriod: TradingPeriod?
  }
  struct TradingPeriod: Decodable { var regular: Period? }
  struct Period: Decodable {
    var start: Double
    var end: Double
  }
  struct Indicators: Decodable { var quote: [Values] }
  struct Values: Decodable {
    var close: [Double?]
    var open: [Double?]?
    var volume: [Double?]?
  }
}
private struct SearchEnvelope: Decodable {
  var quotes: [Quote]?
  var news: [News]?
  struct Quote: Decodable {
    var symbol: String?
    var shortname: String?
    var longname: String?
    var exchDisp: String?
    var isYahooFinance: Bool?
  }
  struct News: Decodable {
    var uuid: String
    var title: String
    var publisher: String
    var link: String
    var providerPublishTime: Double
  }
}
