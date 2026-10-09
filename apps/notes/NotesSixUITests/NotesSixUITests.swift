import UIKit
import XCTest

@MainActor
final class NotesSixUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  private func launch(language: String = "en", reset: Bool = true, extra: [String] = []) {
    app.launchArguments = [
      "--uitesting", "--demo", "-AppleLanguages", "(\(language))", "-AppleLocale",
      language == "en" ? "en_US" : "zh_CN",
    ]
    if reset { app.launchArguments.append("--reset-notes") }
    app.launchArguments += extra
    app.launch()
    XCTAssertTrue(app.buttons["new-note"].waitForExistence(timeout: 8))
  }

  private func capture(_ name: String) {
    let image = XCUIScreen.main.screenshot().image
    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    let data = UIGraphicsImageRenderer(size: image.size, format: format).pngData { _ in
      image.draw(at: .zero)
    }
    let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func waitUntilHittable(_ element: XCUIElement) {
    let ready = NSPredicate(format: "isHittable == true")
    XCTAssertEqual(
      XCTWaiter.wait(
        for: [XCTNSPredicateExpectation(predicate: ready, object: element)], timeout: 5),
      .completed)
  }

  private func openWelcome(chinese: Bool = false) {
    app.buttons.containing(.staticText, identifier: chinese ? "欢迎使用备忘录" : "Welcome to Notes")
      .firstMatch.tap()
    XCTAssertTrue(app.textViews["note-editor"].waitForExistence(timeout: 3))
  }

  func testCreateEditSearchAndPersistence() {
    launch()
    capture("en-list")
    app.buttons["new-note"].tap()
    let editor = app.textViews["note-editor"]
    XCTAssertTrue(editor.waitForExistence(timeout: 3))
    editor.typeText("A real note\nRemember the telescope")
    capture("en-keyboard")
    app.buttons["done-editing"].tap()
    XCTAssertFalse(app.keyboards.firstMatch.exists)
    app.buttons["back-to-notes"].tap()
    let search = app.textFields["search-notes"]
    search.tap()
    search.typeText("telescope")
    XCTAssertTrue(app.staticTexts["A real note"].exists)
    XCTAssertEqual(app.staticTexts["note-count"].label, "1 Note")
    app.terminate()
    launch(reset: false)
    app.buttons.containing(.staticText, identifier: "A real note").firstMatch.tap()
    XCTAssertEqual(
      app.textViews["note-editor"].value as? String, "A real note\nRemember the telescope")
    capture("en-detail")
  }

  func testEmptyDraftAndNoSearchResults() {
    launch()
    app.buttons["new-note"].tap()
    app.buttons["back-to-notes"].tap()
    XCTAssertEqual(app.staticTexts["note-count"].label, "4 Notes")
    let search = app.textFields["search-notes"]
    search.tap()
    search.typeText("xyzzy-no-such-note")
    XCTAssertTrue(app.staticTexts["No Results"].exists)
    app.buttons["cancel-search"].tap()
    XCTAssertEqual(app.staticTexts["note-count"].label, "4 Notes")
  }

  func testPageNavigationAndConfirmedDeletion() {
    launch()
    openWelcome()
    XCTAssertFalse(app.buttons["previous-note"].isEnabled)
    app.buttons["next-note"].tap()
    XCTAssertTrue(
      (app.textViews["note-editor"].value as? String)?.hasPrefix("Weekend plans") == true)
    app.buttons["previous-note"].tap()
    app.buttons["delete-note"].tap()
    capture("en-delete-confirmation")
    app.buttons["cancel-delete"].tap()
    waitUntilHittable(app.buttons["delete-note"])
    XCTAssertTrue((app.textViews["note-editor"].value as? String)?.hasPrefix("Welcome") == true)
    app.buttons["delete-note"].tap()
    app.buttons["confirm-delete"].tap()
    XCTAssertTrue(app.buttons["confirm-delete"].waitForNonExistence(timeout: 3))
    XCTAssertTrue(app.otherElements["paper-trash-animation"].waitForNonExistence(timeout: 4))
    XCTAssertTrue(
      (app.textViews["note-editor"].value as? String)?.hasPrefix("Weekend plans") == true)
    app.buttons["back-to-notes"].tap()
    XCTAssertTrue(app.staticTexts["note-count"].waitForExistence(timeout: 3))
    XCTAssertEqual(app.staticTexts["note-count"].label, "3 Notes")
  }

  func testShareAndFontSettings() {
    launch()
    app.buttons["accounts"].tap()
    app.buttons["notes-settings"].tap()
    XCTAssertTrue(app.buttons["font-Helvetica"].waitForExistence(timeout: 3))
    app.buttons["font-Helvetica"].tap()
    XCTAssertTrue(app.buttons["font-Helvetica"].isSelected)
    capture("en-font-settings")
    app.buttons["close-settings"].tap()
    app.buttons["local-account"].tap()
    openWelcome()
    let originalText = app.textViews["note-editor"].value as? String
    app.buttons["share-note"].tap()
    XCTAssertTrue(app.buttons["share-copy"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.buttons["share-mail"].label, "Mail")
    XCTAssertEqual(app.buttons["share-print"].label, "Print")
    XCTAssertEqual(app.buttons["cancel-share"].label, "Cancel")
    capture("en-classic-share")
    app.buttons["cancel-share"].tap()
    XCTAssertTrue(app.buttons["cancel-share"].waitForNonExistence(timeout: 3))
    waitUntilHittable(app.buttons["share-note"])
    XCTAssertEqual(app.textViews["note-editor"].value as? String, originalText)
    app.buttons["share-note"].tap()
    app.buttons["share-copy"].tap()
    XCTAssertTrue(app.buttons["share-copy"].waitForNonExistence(timeout: 3))
    XCTAssertTrue(app.buttons["delete-note"].waitForExistence(timeout: 5))
    waitUntilHittable(app.buttons["new-note"])
    app.buttons["new-note"].tap()
    let editor = app.textViews["note-editor"]
    XCTAssertTrue(editor.waitForExistence(timeout: 3))
    editor.press(forDuration: 1.2)
    let paste = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label IN %@", ["Paste", "粘贴"])).firstMatch
    XCTAssertTrue(paste.waitForExistence(timeout: 5))
    paste.tap()
    XCTAssertEqual(editor.value as? String, originalText)
    app.buttons["done-editing"].tap()
  }

  func testChineseShareMailUnavailableAndBackdropCancel() {
    launch(language: "zh-Hans")
    openWelcome(chinese: true)
    let originalText = app.textViews["note-editor"].value as? String
    app.buttons["share-note"].tap()
    XCTAssertTrue(app.buttons["share-mail"].waitForExistence(timeout: 3))
    XCTAssertEqual(app.buttons["share-mail"].label, "邮件")
    XCTAssertEqual(app.buttons["share-print"].label, "打印")
    XCTAssertEqual(app.buttons["share-copy"].label, "拷贝")
    XCTAssertEqual(app.buttons["cancel-share"].label, "取消")
    capture("zh-classic-share")
    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
    XCTAssertTrue(app.buttons["cancel-share"].waitForNonExistence(timeout: 3))
    XCTAssertEqual(app.textViews["note-editor"].value as? String, originalText)
    app.buttons["share-note"].tap()
    app.buttons["share-mail"].tap()
    XCTAssertTrue(app.buttons["dismiss-share-error"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["邮件不可用"].exists)
    capture("zh-classic-mail-unavailable")
    app.buttons["dismiss-share-error"].tap()
    XCTAssertTrue(app.buttons["dismiss-share-error"].waitForNonExistence(timeout: 3))
    XCTAssertEqual(app.textViews["note-editor"].value as? String, originalText)
    app.buttons["share-note"].tap()
    app.buttons["cancel-share"].tap()
    XCTAssertTrue(app.buttons["cancel-share"].waitForNonExistence(timeout: 3))
  }

  func testShareLayoutAndPrintCancellationInLandscape() {
    launch(extra: ["--print-empty"])
    openWelcome()
    let originalText = app.textViews["note-editor"].value as? String
    app.buttons["share-note"].tap()
    XCTAssertTrue(app.buttons["share-print"].waitForExistence(timeout: 3))
    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    let wide = NSPredicate { _, _ in
      self.app.windows.firstMatch.frame.width > self.app.windows.firstMatch.frame.height
    }
    XCTAssertEqual(
      XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: wide, object: nil)], timeout: 5),
      .completed)
    let window = app.windows.firstMatch.frame
    for identifier in ["share-mail", "share-print", "share-copy", "cancel-share"] {
      XCTAssertTrue(app.buttons[identifier].isHittable, identifier)
      XCTAssertTrue(window.contains(app.buttons[identifier].frame), identifier)
    }
    capture("en-classic-share-landscape")
    app.buttons["share-print"].tap()
    XCTAssertTrue(app.buttons["cancel-print"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["confirm-print"].isEnabled)
    XCTAssertFalse(app.buttons["decrease-print-copies"].isEnabled)
    app.buttons["increase-print-copies"].tap()
    XCTAssertEqual(app.staticTexts["print-copies"].label, "2 Copies")
    app.buttons["decrease-print-copies"].tap()
    XCTAssertEqual(app.staticTexts["print-copies"].label, "1 Copy")
    for identifier in ["select-print-printer", "increase-print-copies", "confirm-print"] {
      XCTAssertTrue(window.contains(app.buttons[identifier].frame), identifier)
    }
    capture("en-classic-print-landscape")
    app.buttons["select-print-printer"].tap()
    XCTAssertTrue(app.staticTexts["no-print-printers"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["retry-print-discovery"].isHittable)
    capture("en-classic-printers-empty")
    app.buttons["retry-print-discovery"].tap()
    app.buttons["back-to-print-options"].tap()
    app.buttons["cancel-print"].tap()
    XCTAssertTrue(app.buttons["share-note"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.textViews["note-editor"].value as? String, originalText)
    app.buttons["share-note"].tap()
    app.buttons["cancel-share"].tap()
    XCTAssertTrue(app.buttons["cancel-share"].waitForNonExistence(timeout: 3))
  }

  func testChineseClassicPrintSelectionCopiesAndCancellation() {
    launch(language: "zh-Hans", extra: ["--print-fixtures"])
    openWelcome(chinese: true)
    let originalText = app.textViews["note-editor"].value as? String
    app.buttons["share-note"].tap()
    app.buttons["share-print"].tap()
    XCTAssertTrue(app.buttons["cancel-print"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.buttons["cancel-print"].label, "取消")
    XCTAssertTrue(app.staticTexts["打印选项"].exists)
    XCTAssertEqual(app.staticTexts["print-copies"].label, "1 份")
    XCTAssertEqual(app.buttons["increase-print-copies"].label, "增加份数")
    XCTAssertFalse(app.buttons["confirm-print"].isEnabled)
    capture("zh-classic-print")
    app.buttons["select-print-printer"].tap()
    XCTAssertTrue(app.buttons["print-printer-office"].waitForExistence(timeout: 3))
    capture("zh-classic-printers-fixture")
    app.buttons["print-printer-office"].tap()
    XCTAssertTrue(app.buttons["confirm-print"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["confirm-print"].isEnabled)
    XCTAssertTrue(app.staticTexts["Office LaserJet"].exists)
    app.buttons["increase-print-copies"].tap()
    app.buttons["increase-print-copies"].tap()
    XCTAssertEqual(app.staticTexts["print-copies"].label, "3 份")
    capture("zh-classic-print-selected-fixture")
    app.buttons["confirm-print"].tap()
    XCTAssertTrue(app.buttons["dismiss-share-error"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["无法打印"].exists)
    capture("zh-classic-print-error-fixture")
    app.buttons["dismiss-share-error"].tap()
    XCTAssertTrue(app.buttons["dismiss-share-error"].waitForNonExistence(timeout: 3))
    waitUntilHittable(app.buttons["cancel-print"])
    app.buttons["cancel-print"].tap()
    XCTAssertTrue(app.buttons["cancel-print"].waitForNonExistence(timeout: 3))
    XCTAssertTrue(app.buttons["share-note"].waitForExistence(timeout: 5))
    waitUntilHittable(app.buttons["share-note"])
    XCTAssertEqual(app.textViews["note-editor"].value as? String, originalText)
    app.buttons["share-note"].tap()
    app.buttons["share-print"].tap()
    XCTAssertTrue(app.buttons["cancel-print"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["print-copies"].label, "1 份")
    app.buttons["cancel-print"].tap()
  }

  func testChineseInterfaceAndNoteTextSurvivesLanguageChange() {
    launch(language: "zh-Hans")
    XCTAssertTrue(app.staticTexts["备忘录"].exists)
    XCTAssertEqual(app.staticTexts["note-count"].label, "4 条备忘录")
    capture("zh-list")
    openWelcome(chinese: true)
    capture("zh-detail")
    XCTAssertEqual(app.buttons["share-note"].label, "分享备忘录")
    app.textViews["note-editor"].tap()
    XCTAssertEqual(app.buttons["done-editing"].label, "完成")
    app.buttons["done-editing"].tap()
    app.buttons["back-to-notes"].tap()
    app.textFields["search-notes"].tap()
    app.textFields["search-notes"].typeText("咖啡")
    XCTAssertTrue(app.staticTexts["周末计划"].exists)
    app.terminate()
    launch(language: "en", reset: false)
    XCTAssertTrue(app.staticTexts["Notes"].exists)
    openWelcome(chinese: true)
    XCTAssertTrue((app.textViews["note-editor"].value as? String)?.contains("给你的想法") == true)
    XCTAssertEqual(app.buttons["share-note"].label, "Share Note")
  }

  func testListSwipeDeleteAndCancel() {
    launch()
    let row = app.buttons.containing(.staticText, identifier: "Shopping list").firstMatch
    row.swipeLeft()
    XCTAssertTrue(app.buttons["row-delete"].waitForExistence(timeout: 3))
    app.buttons["row-delete"].tap()
    app.buttons["cancel-delete"].tap()
    XCTAssertTrue(app.staticTexts["Shopping list"].exists)
    app.buttons["row-delete"].tap()
    app.buttons["confirm-delete"].tap()
    XCTAssertTrue(app.buttons["confirm-delete"].waitForNonExistence(timeout: 3))
    XCTAssertFalse(app.staticTexts["Shopping list"].exists)
  }

  func testVerticalListScrollingDoesNotOpenANote() {
    launch(extra: ["--long-list"])
    let list = app.scrollViews["notes-list"]
    list.swipeUp()
    list.swipeUp()
    XCTAssertFalse(app.textViews["note-editor"].exists)
    XCTAssertTrue(
      app.buttons.containing(.staticText, identifier: "Things to remember").firstMatch.isHittable)
    list.swipeDown()
    list.swipeDown()
    XCTAssertTrue(app.textFields["search-notes"].isHittable)
  }

  func testLandscapeReadingAndEditing() {
    launch()
    openWelcome()
    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    let wide = NSPredicate { _, _ in
      self.app.windows.firstMatch.frame.width > self.app.windows.firstMatch.frame.height
    }
    XCTAssertEqual(
      XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: wide, object: nil)], timeout: 5),
      .completed)
    XCTAssertTrue(app.buttons["share-note"].isHittable)
    capture("en-landscape")
    app.textViews["note-editor"].tap()
    XCTAssertTrue(app.buttons["done-editing"].isHittable)
    XCTAssertGreaterThan(app.textViews["note-editor"].frame.height, 70)
    app.buttons["done-editing"].tap()
    XCTAssertTrue(app.buttons["share-note"].isHittable)
  }

  func testLongNoteScrollingAndPageChangeResetsScroll() {
    launch()
    app.buttons["new-note"].tap()
    let editor = app.textViews["note-editor"]
    let text = "Long note\n" + (1...45).map { "Line \($0): remember this" }.joined(separator: "\n")
    editor.typeText(text)
    app.buttons["done-editing"].tap()
    XCTAssertEqual(editor.value as? String, text)
    editor.swipeDown()
    app.buttons["next-note"].tap()
    XCTAssertTrue((editor.value as? String)?.hasPrefix("Welcome") == true)
    app.buttons["previous-note"].tap()
    XCTAssertEqual(editor.value as? String, text)
    capture("en-long-note")
    app.buttons["back-to-notes"].tap()
    app.terminate()
    launch(reset: false)
    app.buttons.containing(.staticText, identifier: "Long note").firstMatch.tap()
    XCTAssertEqual(app.textViews["note-editor"].value as? String, text)
  }

  func testCompactEditorKeepsControlsInsideScreen() {
    launch()
    openWelcome()
    let editor = app.textViews["note-editor"]
    let window = app.windows.firstMatch.frame
    XCTAssertGreaterThan(editor.frame.height, 200)
    for identifier in [
      "back-to-notes", "new-note", "previous-note", "share-note", "delete-note", "next-note",
    ] {
      let button = app.buttons[identifier]
      XCTAssertTrue(window.contains(button.frame), identifier)
    }
    editor.tap()
    XCTAssertTrue(app.buttons["done-editing"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["done-editing"].isHittable)
    XCTAssertGreaterThan(editor.frame.height, 100)
    app.buttons["done-editing"].tap()
    XCTAssertTrue(app.buttons["share-note"].isHittable)
  }

  func testPaperCrumpleStagesAndBackgroundCompletion() {
    for (phase, name) in [("0.28", "folds"), ("0.58", "ball"), ("0.84", "into-bin")] {
      launch(extra: ["--trash-preview=\(phase)"])
      openWelcome()
      app.buttons["delete-note"].tap()
      app.buttons["confirm-delete"].tap()
      XCTAssertTrue(app.otherElements["paper-trash-animation"].waitForExistence(timeout: 4))
      capture("en-trash-\(name)")
      XCTAssertFalse(app.buttons["delete-note"].isHittable)
      if phase == "0.58" {
        XCUIDevice.shared.orientation = .landscapeLeft
      } else {
        XCUIDevice.shared.press(.home)
        app.activate()
      }
      XCTAssertTrue(app.otherElements["paper-trash-animation"].waitForNonExistence(timeout: 4))
      XCTAssertTrue((app.textViews["note-editor"].value as? String)?.hasPrefix("Weekend") == true)
      app.buttons["back-to-notes"].tap()
      XCTAssertEqual(app.staticTexts["note-count"].label, "3 Notes")
      XCUIDevice.shared.orientation = .portrait
    }
  }

  func testReduceMotionDeletionAndDeletingLastNote() {
    launch(extra: ["--reduce-motion"])
    openWelcome()
    for _ in 0..<4 {
      app.buttons["delete-note"].tap()
      app.buttons["confirm-delete"].tap()
      XCTAssertTrue(app.buttons["confirm-delete"].waitForNonExistence(timeout: 3))
      XCTAssertFalse(app.otherElements["paper-trash-animation"].exists)
    }
    XCTAssertTrue(app.staticTexts["No Notes"].waitForExistence(timeout: 3))
    XCTAssertEqual(app.staticTexts["note-count"].label, "0 Notes")
    capture("en-empty-bottom-edge")
    app.terminate()
    launch(reset: false)
    XCTAssertEqual(app.staticTexts["note-count"].label, "0 Notes")
  }

  func testLandscapeAnimatedDeletionOfLastNote() {
    launch()
    openWelcome()
    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    for _ in 0..<4 {
      app.buttons["delete-note"].tap()
      app.buttons["confirm-delete"].tap()
      XCTAssertTrue(app.buttons["confirm-delete"].waitForNonExistence(timeout: 3))
      XCTAssertTrue(app.otherElements["paper-trash-animation"].waitForNonExistence(timeout: 4))
    }
    XCTAssertTrue(app.staticTexts["No Notes"].waitForExistence(timeout: 4))
    XCTAssertEqual(app.staticTexts["note-count"].label, "0 Notes")
    capture("en-landscape-empty-bottom-edge")
  }
}
