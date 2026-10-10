import UIKit
import XCTest

@MainActor
final class CalculatorSixUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    app = XCUIApplication()
  }

  override func tearDown() {
    XCUIDevice.shared.orientation = .portrait
    super.tearDown()
  }

  private func launch(_ language: String = "en") {
    app.launchArguments = [
      "--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale",
      language.hasPrefix("zh") ? "zh_CN" : "en_US",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["key-7"].waitForExistence(timeout: 8))
  }

  private func press(_ keys: String...) {
    for key in keys { app.buttons["key-" + key].tap() }
  }
  private var display: XCUIElement { app.staticTexts["calculator-display"] }
  private var expression: XCUIElement { app.staticTexts["calculator-expression"] }

  private func capture(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  func testEnglishPortraitArithmeticMemoryAndClear() {
    launch()
    XCTAssertEqual(display.label, "Current expression")
    XCTAssertEqual(app.buttons["key-m+"].label, "Add to memory")
    press("1", "2", "+", "3", "equals")
    XCTAssertEqual(display.value as? String, "15")
    press("equals")
    XCTAssertEqual(display.value as? String, "18")
    press("m+", "clear", "clear", "mr")
    XCTAssertEqual(display.value as? String, "18")
    XCTAssertEqual(app.buttons["key-mr"].value as? String, "Memory stored")
    capture("en-portrait-memory")
    press("mc")
    XCTAssertEqual(app.buttons["key-mr"].value as? String, "")
  }

  func testChineseLocalizationErrorAndRecovery() {
    launch("zh-Hans")
    XCTAssertEqual(display.label, "当前运算式")
    XCTAssertEqual(app.buttons["key-clear"].label, "全部清除")
    XCTAssertEqual(app.buttons["key-÷"].label, "除")
    press("9", "÷", "0", "equals")
    XCTAssertEqual(display.value as? String, "错误")
    capture("zh-portrait-error")
    press("7", ".", "5")
    XCTAssertEqual(display.value as? String, "7.5")
    display.swipeLeft()
    XCTAssertEqual(display.value as? String, "7.")
  }

  func testScientificRotationParenthesesSecondFunctionsAndState() {
    launch()
    press("2", "+", "3")
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(app.buttons["key-sin"].waitForExistence(timeout: 5))
    XCTAssertEqual(display.value as? String, "2 + 3")
    press("×", "4", "equals")
    XCTAssertEqual(display.value as? String, "14")
    press("clear", "clear", "(", "2", "+", "3", ")", "×", "4", "equals")
    XCTAssertEqual(display.value as? String, "20")
    press("clear", "clear", ".", "5", "second", "sin")
    XCTAssertEqual(display.value as? String, "30")
    XCTAssertEqual(app.buttons["key-sin"].label, "Inverse sine")
    capture("en-landscape-scientific")
    XCUIDevice.shared.orientation = .portrait
    XCTAssertTrue(app.buttons["key-7"].waitForExistence(timeout: 5))
    XCTAssertEqual(display.value as? String, "30")
    XCTAssertFalse(app.buttons["key-sin"].exists)
  }

  func testChineseScientificLabelsBothLandscapeDirectionsAndGeometry() {
    launch("zh-Hant")
    for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
      XCUIDevice.shared.orientation = orientation
      XCTAssertTrue(app.buttons["key-sin"].waitForExistence(timeout: 5))
      XCTAssertEqual(app.buttons["key-sin"].label, "正弦")
      XCTAssertEqual(app.buttons["key-angle"].label, "使用弧度")
      for id in ["sin", "rand", "equals", "mc", "0", "."] {
        let key = app.buttons["key-" + id]
        XCTAssertTrue(key.isHittable)
        XCTAssertGreaterThanOrEqual(key.frame.height, 44)
        XCTAssertGreaterThanOrEqual(key.frame.width, 44)
        XCTAssertTrue(app.frame.contains(key.frame))
      }
      capture(orientation == .landscapeLeft ? "zh-landscape-left" : "zh-landscape-right")
    }
    press("3", "0", "sin")
    XCTAssertEqual(display.value as? String, "0.5")
    press("second")
    XCTAssertEqual(app.buttons["key-ln"].label, "以二为底的对数")
    XCTAssertEqual(app.buttons["key-cosh"].label, "反双曲余弦")
  }

  func testUnsupportedLanguageFallsBackToEnglish() {
    launch("fr")
    XCTAssertEqual(display.label, "Current expression")
    XCTAssertEqual(app.buttons["key-clear"].label, "All clear")
    capture("fallback-portrait")
  }

  func testCopyPasteAndLongDisplayWithLargeText() {
    app.launchArguments = [
      "--uitesting", "-AppleLanguages", "(zh-Hans)",
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["key-7"].waitForExistence(timeout: 8))
    press("1", "2", "3", "4", "5", "6", "7", "8", "9")
    XCTAssertEqual(display.value as? String, "123456789")
    display.press(forDuration: 1)
    let copy = app.buttons["copy-result"]
    XCTAssertTrue(copy.waitForExistence(timeout: 3))
    XCTAssertEqual(copy.label, "复制")
    copy.tap()
    press("clear", "clear")
    display.press(forDuration: 1)
    let paste = app.buttons["paste-result"]
    XCTAssertTrue(paste.waitForExistence(timeout: 3))
    XCTAssertEqual(paste.label, "粘贴")
    paste.tap()
    XCTAssertEqual(display.value as? String, "123456789")
    XCTAssertTrue(app.frame.contains(display.frame))
    capture("zh-large-text-portrait")
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(app.buttons["key-pi"].waitForExistence(timeout: 5))
    press("pi")
    XCTAssertEqual(display.value as? String, "π")
    XCTAssertFalse(expression.exists)
    press("equals")
    XCTAssertEqual(display.value as? String, "3.14159265358979")
    XCTAssertTrue(app.frame.contains(display.frame))
    capture("zh-large-text-landscape")
  }

  func testVisibleExpressionEntryEditingEqualsAndRotation() {
    launch("zh-Hans")
    XCTAssertEqual(display.label, "当前运算式")
    XCTAssertFalse(expression.exists)
    XCTAssertEqual(display.value as? String, "0")
    capture("zh-lcd-single-zero")
    press("7", "×", "7")
    XCTAssertEqual(display.value as? String, "7 × 7")
    XCTAssertFalse(expression.exists)
    capture("zh-expression-entry")
    press("equals")
    XCTAssertEqual(display.label, "显示屏")
    XCTAssertEqual(expression.label, "当前运算式")
    XCTAssertEqual(expression.value as? String, "7 × 7 =")
    XCTAssertEqual(display.value as? String, "49")
    capture("zh-expression-result")
    press("clear", "clear", "2", "+", "3")
    display.swipeLeft()
    XCTAssertEqual(display.value as? String, "2 + 0")
    press("3")
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(app.buttons["key-sin"].waitForExistence(timeout: 5))
    XCTAssertEqual(display.value as? String, "2 + 3")
    XCTAssertFalse(expression.exists)
    capture("zh-expression-landscape-entry")
    press("×", "4", "equals")
    XCTAssertEqual(expression.value as? String, "2 + 3 × 4 =")
    XCTAssertEqual(display.value as? String, "14")
    capture("zh-expression-landscape")
  }

  func testLongExpressionScrollingAndEnglishAccessibility() {
    launch()
    XCTAssertEqual(display.label, "Current expression")
    press("1", "2", "3", "4", "5", "6", "7", "8", "9")
    for _ in 0..<6 { press("+", "1", "2", "3", "4", "5", "6", "7", "8", "9") }
    XCTAssertTrue((display.value as? String)?.hasSuffix("+ 123456789") == true)
    XCTAssertFalse(expression.exists)
    let scroll = app.scrollViews["calculator-input-scroll"]
    XCTAssertTrue(scroll.isHittable)
    XCTAssertTrue(app.frame.contains(scroll.frame))
    scroll.swipeRight()
    capture("en-expression-scroll-start")
    press("equals")
    XCTAssertTrue((expression.value as? String)?.hasSuffix("+ 123456789 =") == true)
    XCTAssertEqual(display.value as? String, "864197523")
    capture("en-expression-scroll-result")
    press("clear", "clear")
    XCTAssertFalse(expression.exists)
    XCTAssertEqual(display.value as? String, "0")
  }
}
