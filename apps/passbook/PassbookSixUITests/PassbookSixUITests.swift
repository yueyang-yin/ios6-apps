import XCTest

final class PassbookSixUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
  }
  private func launch(_ language: String = "en", demo: Bool = false, preserve: Bool = false)
    -> XCUIApplication
  {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "-AppleLanguages", "(\(language))", "-AppleLocale",
      language.hasPrefix("zh") ? "zh_CN" : "en_US",
    ]
    if demo { app.launchArguments.append("--demo") }
    if preserve { app.launchArguments.append("--preserve-test-state") }
    app.launch()
    return app
  }
  private func capture(_ name: String, app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  private func tapReady(_ element: XCUIElement) {
    let predicate = NSPredicate(format: "exists == true AND enabled == true")
    let ready = XCTNSPredicateExpectation(predicate: predicate, object: element)
    XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
    element.tap()
  }
  private func openInfo(_ app: XCUIApplication) {
    let info = app.buttons["pass-info"]
    XCTAssertTrue(info.waitForExistence(timeout: 3))
    if !info.isHittable { app.scrollViews.firstMatch.swipeUp() }
    tapReady(info)
    XCTAssertTrue(app.buttons["flip-done"].waitForExistence(timeout: 3))
  }
  func testWelcomeCatalogAndEveryPassType() {
    let app = launch()
    XCTAssertTrue(app.buttons["welcome-add"].waitForExistence(timeout: 5))
    capture("01-Welcome-English", app: app)
    tapReady(app.buttons["welcome-add"])
    tapReady(app.buttons["sample-boardingPass"])
    XCTAssertTrue(app.staticTexts["LHR"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["SFO"].exists)
    capture("02-Boarding-Pass", app: app)
    openInfo(app)
    capture("03-Information", app: app)
    tapReady(app.buttons["flip-done"])
    tapReady(app.buttons["all-passes"])
    tapReady(app.buttons["add-pass"])
    if !app.buttons["add-samples"].isHittable { app.swipeUp() }
    tapReady(app.buttons["add-samples"])
    XCTAssertTrue(app.buttons["pass-sample-storeCard"].waitForExistence(timeout: 3))
    capture("04-Pass-Stack", app: app)
    for kind in ["eventTicket", "storeCard", "coupon", "generic"] {
      let button = app.buttons["pass-sample-\(kind)"]
      if !button.isHittable { app.swipeUp() }
      tapReady(button)
      XCTAssertTrue(app.buttons["pass-info"].waitForExistence(timeout: 3))
      capture("05-\(kind)", app: app)
      tapReady(app.buttons["all-passes"])
    }
  }
  func testStackFillsScreenForOneTwoAndNinePasses() {
    let app = launch()
    tapReady(app.buttons["welcome-add"])
    tapReady(app.buttons["sample-boardingPass"])
    tapReady(app.buttons["all-passes"])
    let height = app.windows.firstMatch.frame.height
    let first = app.buttons["pass-sample-boardingPass"]
    XCTAssertTrue(first.waitForExistence(timeout: 3))
    XCTAssertGreaterThan(first.frame.height, height * 0.65)
    capture("10-One-Pass-Full-Height", app: app)
    tapReady(app.buttons["add-pass"])
    tapReady(app.buttons["sample-storeCard"])
    tapReady(app.buttons["all-passes"])
    let last = app.buttons["pass-sample-storeCard"]
    XCTAssertTrue(last.waitForExistence(timeout: 3))
    XCTAssertGreaterThan(last.frame.maxY, height * 0.82)
    XCTAssertLessThan(first.frame.minY, height * 0.2)
    capture("11-Two-Passes-Full-Height", app: app)
    tapReady(app.buttons["add-pass"])
    if !app.buttons["add-samples"].isHittable { app.swipeUp() }
    tapReady(app.buttons["add-samples"])
    XCTAssertTrue(app.buttons["pass-sample-american"].waitForExistence(timeout: 3))
    XCTAssertGreaterThan(app.buttons["pass-sample-american"].frame.maxY, height * 0.82)
    capture("12-Nine-Passes-Full-Height", app: app)
  }
  func testChineseFlipDeleteCancelAndPersistedRelaunch() {
    let app = launch("zh-Hant", demo: true)
    XCTAssertTrue(app.buttons["pass-sample-boardingPass"].waitForExistence(timeout: 5))
    capture("06-Stack-Chinese", app: app)
    tapReady(app.buttons["pass-sample-boardingPass"])
    XCTAssertTrue(app.staticTexts["伦敦希思罗"].waitForExistence(timeout: 3))
    capture("07-Boarding-Chinese", app: app)
    openInfo(app)
    tapReady(app.buttons["delete-pass"])
    tapReady(app.buttons["取消"])
    XCTAssertTrue(app.buttons["delete-pass"].exists)
    tapReady(app.buttons["delete-pass"])
    tapReady(app.buttons["alert-primary"])
    XCTAssertTrue(app.buttons["add-pass"].waitForExistence(timeout: 3))
    XCTAssertFalse(app.buttons["pass-sample-boardingPass"].exists)
    app.terminate()
    _ = launch("zh-Hans", preserve: true)
    XCTAssertFalse(app.buttons["pass-sample-boardingPass"].exists)
    XCTAssertTrue(app.buttons["pass-sample-coupon"].exists)
  }
  func testPullingStackReturnsToRestAndPreservesTapNavigation() {
    let app = launch("zh-Hans", demo: true)
    let stack = app.scrollViews["pass-stack"]
    let last = app.buttons["pass-sample-storeCard"]
    XCTAssertTrue(last.waitForExistence(timeout: 5))
    let restingFrame = last.frame
    capture("13-Stack-Before-Pull", app: app)
    let bottom = stack.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    let middle = stack.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
    let top = stack.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.04))
    bottom.press(
      forDuration: 0.05, thenDragTo: middle, withVelocity: .slow, thenHoldForDuration: 0.5)
    XCTAssertFalse(app.buttons["all-passes"].exists)
    let retracted = NSPredicate { _, _ in
      abs(last.frame.minY - restingFrame.minY) < 3
        && abs(last.frame.height - restingFrame.height) < 3
    }
    _ = expectation(for: retracted, evaluatedWith: last)
    waitForExpectations(timeout: 3)
    bottom.press(forDuration: 0.05, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 0.6)
    _ = expectation(for: retracted, evaluatedWith: last)
    waitForExpectations(timeout: 3)
    XCTAssertEqual(last.frame.minY, restingFrame.minY, accuracy: 3)
    XCTAssertEqual(last.frame.height, restingFrame.height, accuracy: 3)
    capture("14-Stack-After-Release", app: app)
    tapReady(last)
    XCTAssertTrue(app.buttons["pass-info"].waitForExistence(timeout: 3))
    tapReady(app.buttons["all-passes"])
    XCTAssertTrue(stack.waitForExistence(timeout: 3))
    for _ in 0..<4 {
      let first = app.buttons["pass-sample-eventTicket"]
      if first.isHittable { break }
      stack.swipeDown(velocity: .slow)
    }
    tapReady(app.buttons["pass-sample-eventTicket"])
    XCTAssertTrue(app.buttons["pass-info"].waitForExistence(timeout: 3))
  }
  func testCreateLocalPassAndPreserveUserTextAcrossLanguages() {
    let app = launch()
    tapReady(app.buttons["welcome-add"])
    tapReady(app.buttons["Create a local pass"])
    app.textFields["pass-organization"].tap()
    app.textFields["pass-organization"].typeText("My Club")
    app.textFields["pass-title"].tap()
    app.textFields["pass-title"].typeText("Member 2012")
    tapReady(app.buttons["Add"])
    XCTAssertTrue(app.staticTexts["Member 2012"].waitForExistence(timeout: 3))
    capture("08-Local-Pass", app: app)
    app.terminate()
    _ = launch("zh-Hans", preserve: true)
    XCTAssertTrue(
      app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "My Club")).firstMatch
        .waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["添加票据"].exists)
  }
  func testLandscapeAndRepeatedReturn() {
    let app = launch("zh-Hans", demo: true)
    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    tapReady(app.buttons["pass-sample-boardingPass"])
    openInfo(app)
    capture("09-Landscape-Chinese-Back", app: app)
    tapReady(app.buttons["flip-done"])
    tapReady(app.buttons["all-passes"])
    XCTAssertTrue(app.buttons["pass-sample-boardingPass"].waitForExistence(timeout: 3))
    tapReady(app.buttons["pass-sample-boardingPass"])
    XCTAssertTrue(app.staticTexts["LHR"].waitForExistence(timeout: 3))
  }
  func testUnsupportedLanguageAndReducedMotionDeletion() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--demo", "--reduce-motion", "-AppleLanguages", "(fr)", "-AppleLocale",
      "fr_FR",
    ]
    app.launch()
    tapReady(app.buttons["pass-sample-coupon"])
    XCTAssertTrue(app.staticTexts["10% off"].waitForExistence(timeout: 3))
    openInfo(app)
    tapReady(app.buttons["delete-pass"])
    tapReady(app.buttons["alert-primary"])
    XCTAssertTrue(app.buttons["add-pass"].waitForExistence(timeout: 3))
    XCTAssertFalse(app.buttons["pass-sample-coupon"].exists)
  }
}
