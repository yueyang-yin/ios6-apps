import XCTest

final class StocksSixUITests: XCTestCase {
  override func tearDown() {
    XCUIDevice.shared.orientation = .portrait
    super.tearDown()
  }
  private func launch(_ language: String = "en", preserving: Bool = false, live: Bool = false)
    -> XCUIApplication
  {
    XCUIDevice.shared.orientation = .portrait
    let app = XCUIApplication()
    app.launchArguments =
      (live ? [] : ["--ui-testing"]) + (preserving ? ["--preserve-test-state"] : []) + [
        "-AppleLanguages", "(\(language))", "-AppleLocale",
        language.hasPrefix("zh") ? "zh_CN" : "en_US",
      ]
    app.launch()
    XCTAssertTrue(app.buttons["manage-stocks"].waitForExistence(timeout: 15))
    return app
  }
  private func capture(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  func testPortraitSelectionRangesAndChangeDisplay() {
    let app = launch()
    XCTAssertTrue(app.buttons["stock-AAPL"].exists)
    XCTAssertTrue(app.otherElements["stock-chart"].waitForExistence(timeout: 10))
    XCTAssertLessThanOrEqual(
      app.buttons["stock-^N225"].frame.maxY, app.buttons["range-1d"].frame.minY + 1)
    XCTAssertEqual(app.buttons["range-1d"].frame.minX, app.frame.minX, accuracy: 1)
    XCTAssertEqual(app.buttons["range-2y"].frame.maxX, app.frame.maxX, accuracy: 1)
    XCTAssertEqual(app.buttons["manage-stocks"].frame.maxX, app.frame.maxX, accuracy: 1)
    capture("en-portrait")
    let change = app.buttons["change-AAPL"]
    let original = change.label
    change.tap()
    XCTAssertTrue(change.label.contains("%"))
    change.tap()
    XCTAssertTrue(change.label.contains("Market Cap"))
    change.tap()
    XCTAssertEqual(change.label, original)
    for range in ["1d", "1w", "1m", "3m", "6m", "1y", "2y"] {
      app.buttons["range-\(range)"].tap()
      XCTAssertTrue(app.buttons["range-\(range)"].isSelected)
    }
    app.buttons["stock-GOOG"].tap()
    XCTAssertTrue(app.buttons["stock-GOOG"].isSelected)
  }
  func testChineseSummaryNewsAndManagement() {
    let app = launch("zh-Hant-TW")
    XCTAssertEqual(app.buttons["manage-stocks"].label, "管理自选股票")
    capture("zh-portrait")
    app.buttons["page-1"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).press(
      forDuration: 0.8)
    let refresh = app.buttons["刷新行情"].firstMatch
    XCTAssertTrue(refresh.waitForExistence(timeout: 5))
    capture("zh-refresh-menu")
    refresh.tap()
    let menuDismissed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isHittable == true"), object: app.buttons["manage-stocks"])
    XCTAssertEqual(XCTWaiter.wait(for: [menuDismissed], timeout: 5), .completed)
    app.buttons["page-0"].tap()
    XCTAssertTrue(app.staticTexts["苹果公司"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["开盘"].exists)
    capture("zh-summary")
    app.buttons["page-2"].tap()
    XCTAssertTrue(app.staticTexts["探索公司的最新市场动态"].firstMatch.waitForExistence(timeout: 8))
    capture("zh-news")
    app.buttons["manage-stocks"].tap()
    XCTAssertTrue(app.buttons["manager-done"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.buttons["manager-done"].label, "完成")
    capture("zh-management")
    app.buttons["manager-done"].tap()
    XCTAssertTrue(app.buttons["manage-stocks"].waitForExistence(timeout: 5))
  }
  func testAddSearchCancelDeleteAndPersistence() {
    let app = launch()
    app.buttons["manage-stocks"].tap()
    app.buttons["add-stock"].tap()
    let field = app.textFields["stock-search"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("MSFT")
    XCTAssertTrue(app.buttons["result-MSFT"].waitForExistence(timeout: 8))
    capture("en-search-keyboard")
    app.buttons["result-MSFT"].tap()
    XCTAssertTrue(app.buttons["delete-MSFT"].waitForExistence(timeout: 5))
    app.buttons["manager-done"].tap()
    XCTAssertTrue(app.buttons["stock-MSFT"].waitForExistence(timeout: 5))
    app.terminate()
    let restored = launch(preserving: true)
    XCTAssertTrue(restored.buttons["stock-MSFT"].exists)
    restored.buttons["manage-stocks"].tap()
    restored.buttons["delete-MSFT"].tap()
    restored.buttons["add-stock"].tap()
    XCTAssertTrue(restored.buttons["search-cancel"].waitForExistence(timeout: 5))
    restored.buttons["search-cancel"].tap()
    XCTAssertTrue(restored.buttons["manager-done"].waitForExistence(timeout: 5))
    restored.buttons["manager-done"].tap()
    XCTAssertFalse(restored.buttons["stock-MSFT"].exists)
  }
  func testEmptyWatchlistRecovery() {
    let app = launch()
    app.buttons["manage-stocks"].tap()
    for symbol in ["^IXIC", "^GSPC", "AAPL", "GOOG", "^FTSE", "^GDAXI", "^N225"] {
      let button = app.buttons["delete-\(symbol)"]
      if !button.isHittable { app.scrollViews["managed-watchlist"].swipeUp() }
      button.tap()
    }
    app.buttons["manager-done"].tap()
    XCTAssertTrue(app.buttons["empty-add"].waitForExistence(timeout: 5))
    capture("en-empty")
    app.buttons["empty-add"].tap()
    let field = app.textFields["stock-search"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("AAPL")
    app.buttons["result-AAPL"].tap()
    app.buttons["manager-done"].tap()
    XCTAssertTrue(app.buttons["stock-AAPL"].waitForExistence(timeout: 5))
  }
  func testLandscapeScrubbingAndRotationRestore() {
    let app = launch()
    XCUIDevice.shared.orientation = .landscapeLeft
    let chart = app.otherElements["expanded-chart"]
    XCTAssertTrue(chart.waitForExistence(timeout: 8))
    let before = chart.value as? String
    chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.4)
    XCTAssertNotEqual(chart.value as? String, before)
    capture("en-landscape-inspection")
    chart.pinch(withScale: 0.7, velocity: -0.6)
    XCTAssertTrue(
      (chart.value as? String ?? "").contains("%"), "Comparison value: \(chart.value ?? "nil")")
    capture("en-landscape-comparison")
    XCUIDevice.shared.orientation = .landscapeRight
    XCTAssertTrue(chart.waitForExistence(timeout: 5))
    capture("en-landscape-right")
    XCUIDevice.shared.orientation = .portrait
    XCTAssertTrue(app.buttons["stock-AAPL"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["manage-stocks"].isHittable)
  }
  func testPageSwipeAndReordering() {
    let app = launch()
    let pages = app.otherElements["stock-chart"]
    let start = pages.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.2))
    let end = pages.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.2))
    start.press(forDuration: 0.01, thenDragTo: end)
    XCTAssertTrue(app.buttons["page-2"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["page-2"].isSelected)
    app.buttons["manage-stocks"].tap()
    let source = app.otherElements["managed-AAPL"].firstMatch
    let destination = app.otherElements["managed-^IXIC"].firstMatch
    source.press(forDuration: 0.7, thenDragTo: destination)
    app.buttons["manager-done"].tap()
    let rows = [app.buttons["stock-AAPL"], app.buttons["stock-^IXIC"]]
    XCTAssertLessThan(rows[0].frame.minY, rows[1].frame.minY)
    capture("en-reordered")
  }
  func testChineseSearchNoResultsAndLandscape() {
    let app = launch("zh-Hans")
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(app.otherElements["expanded-chart"].waitForExistence(timeout: 8))
    XCTAssertEqual(app.buttons["range-1d"].label, "显示1天图表")
    capture("zh-landscape")
    XCUIDevice.shared.orientation = .portrait
    app.buttons["manage-stocks"].tap()
    app.buttons["add-stock"].tap()
    let field = app.textFields["stock-search"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("ZZZZZZZZZZ")
    XCTAssertTrue(app.staticTexts["未找到匹配的股票"].waitForExistence(timeout: 5))
    capture("zh-no-search-results")
    app.buttons["search-cancel"].tap()
    app.buttons["manager-done"].tap()
    XCTAssertTrue(app.buttons["manage-stocks"].waitForExistence(timeout: 5))
  }
  func testUnsupportedLanguageFallsBackToEnglish() {
    let app = launch("fr-FR")
    XCTAssertEqual(app.buttons["manage-stocks"].label, "Manage Stocks")
    app.buttons["manage-stocks"].tap()
    XCTAssertEqual(app.buttons["manager-done"].label, "Done")
  }
}
