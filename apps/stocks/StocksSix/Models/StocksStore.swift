import Foundation
import Observation

@MainActor @Observable
final class StocksStore {
  private(set) var watchlist: [Stock]
  private(set) var quotes: [String: StockQuote] = [:]
  private(set) var charts: [String: StockChart] = [:]
  private(set) var headlines: [String: [StockNews]] = [:]
  private(set) var quoteFailures: Set<String> = []
  private(set) var chartFailures: Set<String> = []
  private(set) var newsFailures: Set<String> = []
  private(set) var refreshing = false
  private(set) var loadingChart = false
  private(set) var loadingNews = false
  var selectedSymbol: String { didSet { save() } }
  var range: ChartRange { didSet { save() } }
  var changeDisplay: ChangeDisplay { didSet { save() } }
  let demo: Bool
  @ObservationIgnored private let service: any MarketProviding
  @ObservationIgnored private let defaults: UserDefaults?
  @ObservationIgnored private var chartRequests: Set<String> = []
  @ObservationIgnored private var newsRequests: Set<String> = []

  init(
    demo: Bool = false, defaults: UserDefaults? = .standard, service: (any MarketProviding)? = nil
  ) {
    self.demo = demo
    self.defaults = defaults
    self.service = service ?? (demo ? DemoMarketService() : MarketService())
    let saved = defaults?.data(forKey: "stocks-state").flatMap {
      try? JSONDecoder().decode(Saved.self, from: $0)
    }
    watchlist = saved?.watchlist ?? Stock.defaults
    selectedSymbol = saved?.selectedSymbol ?? "AAPL"
    range = saved?.range ?? .sixMonths
    changeDisplay = saved?.changeDisplay ?? .price
    if !watchlist.contains(where: { $0.symbol == selectedSymbol }) {
      selectedSymbol = watchlist.first?.symbol ?? ""
    }
    if !demo,
      let cache = defaults?.data(forKey: "stocks-cache").flatMap({
        try? JSONDecoder().decode(Cache.self, from: $0)
      })
    {
      quotes = cache.quotes
      charts = cache.charts
    }
  }
  var selectedStock: Stock? { watchlist.first { $0.symbol == selectedSymbol } }
  var selectedQuote: StockQuote? { quotes[selectedSymbol] }
  var chartKey: String { key(selectedSymbol, range) }
  var selectedChart: StockChart? { charts[chartKey] }
  func key(_ symbol: String, _ range: ChartRange) -> String { "\(symbol):\(range.rawValue)" }
  func add(_ stock: Stock) {
    if !watchlist.contains(where: { $0.symbol == stock.symbol }) { watchlist.append(stock) }
    selectedSymbol = stock.symbol
    save()
  }
  func remove(_ symbol: String) {
    watchlist.removeAll { $0.symbol == symbol }
    if selectedSymbol == symbol { selectedSymbol = watchlist.first?.symbol ?? "" }
    save()
  }
  func move(_ symbol: String, before target: String) {
    guard symbol != target, let from = watchlist.firstIndex(where: { $0.symbol == symbol }),
      watchlist.contains(where: { $0.symbol == target })
    else { return }
    let item = watchlist.remove(at: from)
    guard let to = watchlist.firstIndex(where: { $0.symbol == target }) else { return }
    watchlist.insert(item, at: to)
    save()
  }
  func move(_ symbol: String, offset: Int) {
    guard let from = watchlist.firstIndex(where: { $0.symbol == symbol }) else { return }
    let to = from + offset
    guard watchlist.indices.contains(to) else { return }
    watchlist.swapAt(from, to)
    save()
  }
  func cycleDisplay() { changeDisplay = changeDisplay.next }
  func refresh() async {
    guard !refreshing else { return }
    refreshing = true
    defer { refreshing = false }
    let symbols = watchlist.map(\.symbol)
    for symbol in symbols {
      guard !Task.isCancelled else { return }
      do {
        let chart = try await service.chart(symbol: symbol, range: .day)
        guard watchlist.contains(where: { $0.symbol == symbol }) else { continue }
        quotes[symbol] = chart.quote
        charts[key(symbol, .day)] = chart
        quoteFailures.remove(symbol)
      } catch {
        if !Task.isCancelled { quoteFailures.insert(symbol) }
      }
    }
    persistCache()
  }
  func loadChart(force: Bool = false) async {
    let symbol = selectedSymbol
    let range = range
    let key = key(symbol, range)
    guard !symbol.isEmpty, !chartRequests.contains(key), force || charts[key] == nil || !demo else {
      return
    }
    chartRequests.insert(key)
    loadingChart = true
    defer {
      chartRequests.remove(key)
      loadingChart = !chartRequests.isEmpty
    }
    do {
      let chart = try await service.chart(symbol: symbol, range: range)
      guard !Task.isCancelled, watchlist.contains(where: { $0.symbol == symbol }) else { return }
      charts[key] = chart
      if range == .day { quotes[symbol] = chart.quote }
      chartFailures.remove(key)
      persistCache()
    } catch {
      if !Task.isCancelled { chartFailures.insert(key) }
    }
  }
  func loadNews(force: Bool = false) async {
    let symbol = selectedSymbol
    guard !symbol.isEmpty, !newsRequests.contains(symbol), force || headlines[symbol] == nil else {
      return
    }
    newsRequests.insert(symbol)
    loadingNews = true
    defer {
      newsRequests.remove(symbol)
      loadingNews = !newsRequests.isEmpty
    }
    do {
      let items = try await service.news(symbol: symbol)
      guard !Task.isCancelled, watchlist.contains(where: { $0.symbol == symbol }) else { return }
      headlines[symbol] = items
      newsFailures.remove(symbol)
    } catch { if !Task.isCancelled { newsFailures.insert(symbol) } }
  }
  func search(_ query: String) async throws -> [Stock] { try await service.search(query) }
  private func save() {
    let saved = Saved(
      watchlist: watchlist, selectedSymbol: selectedSymbol, range: range,
      changeDisplay: changeDisplay)
    if let data = try? JSONEncoder().encode(saved) { defaults?.set(data, forKey: "stocks-state") }
  }
  private func persistCache() {
    let symbols = Set(watchlist.map(\.symbol))
    let cache = Cache(
      quotes: quotes.filter { symbols.contains($0.key) },
      charts: charts.filter { symbols.contains($0.value.quote.symbol) })
    if let data = try? JSONEncoder().encode(cache) { defaults?.set(data, forKey: "stocks-cache") }
  }
  private struct Saved: Codable {
    var watchlist: [Stock]
    var selectedSymbol: String
    var range: ChartRange
    var changeDisplay: ChangeDisplay
  }
  private struct Cache: Codable {
    var quotes: [String: StockQuote]
    var charts: [String: StockChart]
  }
}
