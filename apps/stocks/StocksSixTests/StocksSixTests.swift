import XCTest

@testable import StocksSix

final class MarketDecodingTests: XCTestCase {
  private let fixture = Data(
    #"{"chart":{"result":[{"meta":{"symbol":"AAPL","currency":"USD","regularMarketPrice":101,"regularMarketTime":1700000000,"chartPreviousClose":90,"regularMarketDayHigh":103,"regularMarketDayLow":98,"regularMarketVolume":400,"currentTradingPeriod":{"regular":{"start":1699990000,"end":1700010000}}},"timestamp":[1,2,3,4],"indicators":{"quote":[{"close":[100,null,101,102],"open":[99,null,100,101],"volume":[50,null,80]}]}}],"error":null}}"#
      .utf8)
  func testNullPricesAndMismatchedVolumeArrays() throws {
    let result = try MarketService.decodeChart(fixture, range: .day)
    XCTAssertEqual(result.points.map(\.close), [100, 101, 102])
    XCTAssertEqual(result.points.map(\.volume), [50, 80, 0])
    XCTAssertEqual(result.quote.open, 99)
    XCTAssertEqual(result.quote.previousClose, 90)
    XCTAssertEqual(result.quote.change, 11)
    XCTAssertEqual(result.quote.currency, "USD")
    XCTAssertTrue(result.quote.isMarketOpen(at: Date(timeIntervalSince1970: 1_700_000_000)))
    XCTAssertFalse(result.quote.isMarketOpen(at: Date(timeIntervalSince1970: 1_700_020_000)))
  }
  func testHistoricalBaselineIsNotDailyChange() throws {
    let result = try MarketService.decodeChart(fixture, range: .sixMonths)
    XCTAssertNil(result.quote.previousClose)
    XCTAssertNil(result.quote.change)
    XCTAssertNil(result.quote.open)
    XCTAssertEqual(result.quote.changeText(.price), "—")
  }
  func testProviderErrorDoesNotBecomeAZeroPrice() {
    XCTAssertThrowsError(
      try MarketService.decodeChart(
        Data(#"{"chart":{"result":null,"error":{"code":"Not Found"}}}"#.utf8), range: .day))
  }
  func testComparisonDoesNotDependOnFingerArrivalOrder() {
    let forward = ChartSelection(first: 0.2, second: 0.8)
    let reverse = ChartSelection(first: 0.8, second: 0.2)
    XCTAssertEqual(forward, reverse)
    XCTAssertEqual(reverse.first, 0.2)
    XCTAssertEqual(reverse.second, 0.8)
  }
  func testRangeContracts() {
    XCTAssertEqual(ChartRange.week.apiRange, "5d")
    XCTAssertEqual(ChartRange.month.apiRange, "1mo")
    XCTAssertEqual(ChartRange.sixMonths.apiRange, "6mo")
    XCTAssertEqual(ChartRange.day.interval, "5m")
    XCTAssertEqual(ChartRange.week.interval, "30m")
    XCTAssertEqual(ChartRange.twoYears.interval, "1d")
  }
}

final class LocalizationTests: XCTestCase {
  func testWeatherLanguageRules() {
    for language in ["zh", "zh-CN", "zh-Hant-TW", "zh-HK", "ZH-hans"] {
      XCTAssertEqual(AppLanguage.preferred([language]), .chinese)
    }
    for languages in [["en-GB"], ["fr", "zh"], ["de"], []] {
      XCTAssertEqual(AppLanguage.preferred(languages), .english)
    }
  }
  func testLocalizedCatalogAndSearch() {
    XCTAssertEqual(Stock.defaults[2].displayName(language: .chinese), "苹果公司")
    XCTAssertEqual(Stock.defaults[2].displayName(language: .english), "Apple Inc.")
    XCTAssertEqual(Stock.localSearch("苹果", language: .chinese).map(\.symbol), ["AAPL"])
    XCTAssertEqual(Stock.localSearch(" microsoft ", language: .english).map(\.symbol), ["MSFT"])
    XCTAssertEqual(StockFormat.compact(nil), "—")
    XCTAssertEqual(StockFormat.compact(1.5e9, language: .chinese), "1.50十亿")
    XCTAssertEqual(StockFormat.signed(-1.25, language: .english), "−1.25")
  }
  func testResourcesHaveMatchingKeysAndPlaceholders() throws {
    func strings(_ language: String) throws -> [String: String] {
      let folder = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
      let data = try Data(
        contentsOf: URL(fileURLWithPath: folder).appendingPathComponent("Localizable.strings"))
      return try XCTUnwrap(
        try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
    }
    let english = try strings("en")
    let chinese = try strings("zh-Hans")
    XCTAssertEqual(Set(english.keys), Set(chinese.keys))
    let regex = try NSRegularExpression(pattern: "%[@df]")
    for key in english.keys {
      let en = english[key]!
      let zh = chinese[key]!
      XCTAssertEqual(
        regex.numberOfMatches(in: en, range: NSRange(en.startIndex..., in: en)),
        regex.numberOfMatches(in: zh, range: NSRange(zh.startIndex..., in: zh)), key)
    }
    XCTAssertEqual(L10n.text("Stocks", language: .chinese), "股市")
    XCTAssertEqual(L10n.text("Done", language: .english), "Done")
  }
}

@MainActor
final class StocksStoreTests: XCTestCase {
  func testWatchlistPersistenceDuplicateProtectionAndSelectionRecovery() {
    let name = "stocks-unit-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let store = StocksStore(demo: true, defaults: defaults)
    let stock = Stock(symbol: "MSFT", name: "Microsoft")
    store.add(stock)
    store.add(stock)
    XCTAssertEqual(store.watchlist.filter { $0.symbol == "MSFT" }.count, 1)
    store.move("MSFT", before: "^IXIC")
    store.range = .year
    store.cycleDisplay()
    let restored = StocksStore(demo: true, defaults: defaults)
    XCTAssertEqual(restored.watchlist.first?.symbol, "MSFT")
    XCTAssertEqual(restored.selectedSymbol, "MSFT")
    XCTAssertEqual(restored.changeDisplay, .percent)
    XCTAssertEqual(restored.range, .year)
    restored.remove("MSFT")
    XCTAssertEqual(restored.selectedSymbol, restored.watchlist.first?.symbol)
    for item in restored.watchlist { restored.remove(item.symbol) }
    XCTAssertTrue(restored.watchlist.isEmpty)
    XCTAssertNil(restored.selectedStock)
    XCTAssertTrue(StocksStore(demo: true, defaults: defaults).watchlist.isEmpty)
  }
  func testDemoRefreshAndRangeSelection() async {
    let store = StocksStore(demo: true, defaults: nil)
    await store.refresh()
    XCTAssertEqual(store.quotes.count, 7)
    XCTAssertFalse(store.refreshing)
    XCTAssertTrue(store.quoteFailures.isEmpty)
    await store.loadChart()
    XCTAssertEqual(store.selectedChart?.points.count, 100)
    let dailyChange = store.selectedQuote?.change
    store.range = .year
    await store.loadChart()
    XCTAssertNotNil(store.selectedChart)
    XCTAssertEqual(store.selectedQuote?.change, dailyChange)
    await store.loadNews()
    XCTAssertEqual(store.headlines[store.selectedSymbol]?.count, 3)
  }
  func testFailedRefreshKeepsCachedPricesAndSignalsFailure() async {
    let service = SwitchingService()
    let store = StocksStore(defaults: nil, service: service)
    await store.refresh()
    let old = store.quotes["AAPL"]
    await service.fail()
    await store.refresh()
    XCTAssertEqual(store.quotes["AAPL"], old)
    XCTAssertTrue(store.quoteFailures.contains("AAPL"))
    await store.loadChart(force: true)
    XCTAssertTrue(store.chartFailures.contains(store.chartKey))
    await store.loadNews()
    XCTAssertTrue(store.newsFailures.contains("AAPL"))
  }
  func testLateChartResponseCannotReplaceSelectedSymbol() async {
    let store = StocksStore(defaults: nil, service: SlowService())
    let pending = Task { await store.loadChart() }
    await Task.yield()
    store.selectedSymbol = "GOOG"
    await pending.value
    XCTAssertEqual(store.selectedSymbol, "GOOG")
    XCTAssertNil(store.selectedChart)
    XCTAssertNotNil(store.charts["AAPL:6m"])
    await store.loadChart()
    XCTAssertEqual(store.selectedChart?.quote.symbol, "GOOG")
  }
  func testRemovedStockDoesNotReturnFromInFlightResponse() async {
    let store = StocksStore(defaults: nil, service: SlowService())
    let pending = Task { await store.loadChart() }
    await Task.yield()
    store.remove("AAPL")
    await pending.value
    XCTAssertNil(store.charts["AAPL:6m"])
  }
}

private actor SwitchingService: MarketProviding {
  var failing = false
  func fail() { failing = true }
  func chart(symbol: String, range: ChartRange) async throws -> StockChart {
    if failing { throw MarketError.unavailable }
    return try await DemoMarketService().chart(symbol: symbol, range: range)
  }
  func news(symbol: String) async throws -> [StockNews] { throw MarketError.unavailable }
  func search(_ query: String) async throws -> [Stock] { [] }
}
private struct SlowService: MarketProviding {
  func chart(symbol: String, range: ChartRange) async throws -> StockChart {
    try await Task.sleep(for: .milliseconds(80))
    return try await DemoMarketService().chart(symbol: symbol, range: range)
  }
  func news(symbol: String) async throws -> [StockNews] { [] }
  func search(_ query: String) async throws -> [Stock] { [] }
}
