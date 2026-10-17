import Foundation

struct Stock: Codable, Identifiable, Equatable, Sendable {
  var symbol: String
  var name: String
  var exchange: String = ""
  var id: String { symbol }
  var displaySymbol: String {
    switch symbol {
    case "^IXIC": "NASDAQ"
    case "^GSPC": "S&P 500"
    case "^DJI": "DOW J"
    case "^FTSE": "FTSE 100"
    case "^GDAXI": "DAX"
    default: symbol
    }
  }
  func displayName(language: AppLanguage = .current) -> String {
    language == .chinese
      ? L10n.text(symbol, language: language) == symbol
        ? name : L10n.text(symbol, language: language) : name
  }
  static let defaults: [Stock] = [
    Stock(symbol: "^IXIC", name: "NASDAQ Composite", exchange: "NASDAQ"),
    Stock(symbol: "^GSPC", name: "S&P 500", exchange: "SNP"),
    Stock(symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ"),
    Stock(symbol: "GOOG", name: "Alphabet Inc.", exchange: "NASDAQ"),
    Stock(symbol: "^FTSE", name: "FTSE 100", exchange: "FTSE"),
    Stock(symbol: "^GDAXI", name: "DAX Performance Index", exchange: "XETRA"),
    Stock(symbol: "^N225", name: "Nikkei 225", exchange: "OSE"),
  ]
  static let catalog: [Stock] =
    defaults + [
      Stock(symbol: "MSFT", name: "Microsoft Corporation", exchange: "NASDAQ"),
      Stock(symbol: "NVDA", name: "NVIDIA Corporation", exchange: "NASDAQ"),
      Stock(symbol: "AMZN", name: "Amazon.com Inc.", exchange: "NASDAQ"),
      Stock(symbol: "TSLA", name: "Tesla Inc.", exchange: "NASDAQ"),
      Stock(symbol: "META", name: "Meta Platforms Inc.", exchange: "NASDAQ"),
      Stock(symbol: "^DJI", name: "Dow Jones Industrial Average", exchange: "DJI"),
      Stock(symbol: "000001.SS", name: "SSE Composite Index", exchange: "Shanghai"),
      Stock(symbol: "0700.HK", name: "Tencent Holdings Limited", exchange: "Hong Kong"),
      Stock(symbol: "EURUSD=X", name: "EUR / USD", exchange: "CCY"),
    ]
  static func localSearch(_ query: String, language: AppLanguage = .current) -> [Stock] {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return [] }
    return catalog.filter {
      [$0.symbol, $0.name, $0.displayName(language: language)].contains {
        $0.localizedCaseInsensitiveContains(query)
      }
    }
  }
}

enum ChartRange: String, CaseIterable, Identifiable, Codable, Sendable {
  case day = "1d"
  case week = "1w"
  case month = "1m"
  case threeMonths = "3m"
  case sixMonths = "6m"
  case year = "1y"
  case twoYears = "2y"
  var id: String { rawValue }
  var title: String { L10n.text(rawValue) }
  var apiRange: String {
    switch self {
    case .week: "5d"
    case .month: "1mo"
    case .threeMonths: "3mo"
    case .sixMonths: "6mo"
    default: rawValue
    }
  }
  var interval: String { self == .day ? "5m" : self == .week ? "30m" : "1d" }
}

enum ChangeDisplay: String, CaseIterable, Codable {
  case price, percent, marketCap
  var title: String {
    L10n.text(
      self == .price ? "Price Change" : self == .percent ? "Percentage Change" : "Market Cap")
  }
  var next: Self { self == .price ? .percent : self == .percent ? .marketCap : .price }
}

struct PricePoint: Codable, Equatable, Identifiable, Sendable {
  var date: Date
  var close: Double
  var volume: Double
  var id: Date { date }
}

struct StockQuote: Codable, Equatable, Sendable {
  var symbol: String
  var price: Double
  var previousClose: Double?
  var open: Double?
  var high: Double?
  var low: Double?
  var volume: Double?
  var marketCap: Double?
  var yearHigh: Double?
  var yearLow: Double?
  var currency: String
  var exchange: String
  var timestamp: Date
  var marketStart: Date?
  var marketEnd: Date?
  var change: Double? { previousClose.map { price - $0 } }
  var percent: Double? { previousClose.flatMap { $0 == 0 ? nil : (price - $0) / $0 * 100 } }
  func isMarketOpen(at date: Date) -> Bool {
    guard let marketStart, let marketEnd else { return false }
    return date >= marketStart && date <= marketEnd
  }
  func changeText(_ display: ChangeDisplay, language: AppLanguage = .current) -> String {
    switch display {
    case .price: change.map { StockFormat.signed($0, language: language) } ?? "—"
    case .percent: percent.map { StockFormat.signed($0, language: language) + "%" } ?? "—"
    case .marketCap: StockFormat.compact(marketCap, language: language)
    }
  }
}

struct StockChart: Codable, Equatable, Sendable {
  var quote: StockQuote
  var points: [PricePoint]
}

struct StockNews: Codable, Equatable, Identifiable, Sendable {
  var id: String
  var title: String
  var publisher: String
  var url: URL
  var date: Date
}

enum StockFormat {
  static func number(_ value: Double?, digits: Int = 2, language: AppLanguage = .current) -> String
  {
    guard let value, value.isFinite else { return "—" }
    return value.formatted(.number.precision(.fractionLength(digits)).locale(language.locale))
  }
  static func signed(_ value: Double, language: AppLanguage = .current) -> String {
    (value >= 0 ? "+" : "−") + number(abs(value), language: language)
  }
  static func compact(_ value: Double?, language: AppLanguage = .current) -> String {
    guard let value, value.isFinite else { return "—" }
    for (divisor, key) in [(1e12, "T"), (1e9, "B"), (1e6, "M"), (1e3, "K")] {
      if abs(value) >= divisor {
        return number(value / divisor, language: language) + L10n.text(key, language: language)
      }
    }
    return number(value, digits: 0, language: language)
  }
  static func date(_ date: Date, time: Bool = false, language: AppLanguage = .current) -> String {
    if time {
      return date.formatted(
        .dateTime.month(.abbreviated).day().hour().minute().locale(language.locale))
    }
    return date.formatted(.dateTime.year().month(.abbreviated).day().locale(language.locale))
  }
}
