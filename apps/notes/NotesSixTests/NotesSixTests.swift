import Network
import PDFKit
import UIKit
import XCTest

@testable import NotesSix

@MainActor
final class NotesSixTests: XCTestCase {
  private var directory: URL!
  private var url: URL { directory.appendingPathComponent("notes.json") }

  override func setUp() {
    super.setUp()
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: directory)
    super.tearDown()
  }

  func testTrashMeshStartsAtTheOriginalPageAndFinishesInsideTheBin() {
    let page = CGRect(x: 0, y: 44, width: 390, height: 700)
    let target = CGPoint(x: 243.75, y: 766)
    let mesh = PaperTrashMesh(page: page, target: target)
    for (u, v) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)] {
      let start = mesh.vertex(u: u, v: v, progress: 0)
      XCTAssertEqual(start.point.x, page.minX + u * page.width, accuracy: 0.001)
      XCTAssertEqual(start.point.y, page.minY + v * page.height, accuracy: 0.001)
      let finish = mesh.vertex(u: u, v: v, progress: 1)
      XCTAssertEqual(finish.point.x, target.x, accuracy: 0.001)
      XCTAssertEqual(finish.point.y, target.y, accuracy: 0.001)
    }
  }

  func testTrashMeshRemainsFiniteAcrossCompactTallAndLandscapePages() {
    for size in [
      CGSize(width: 335, height: 460), CGSize(width: 375, height: 460),
      CGSize(width: 420, height: 720),
      CGSize(width: 800, height: 190),
    ] {
      let mesh = PaperTrashMesh(
        page: CGRect(origin: CGPoint(x: 0, y: 44), size: size),
        target: CGPoint(x: size.width * 0.625, y: size.height + 66))
      for phase in stride(from: 0.0, through: 1.0, by: 0.05) {
        for row in 0...14 {
          for column in 0...10 {
            let vertex = mesh.vertex(u: CGFloat(column) / 10, v: CGFloat(row) / 14, progress: phase)
            XCTAssertTrue(
              vertex.point.x.isFinite && vertex.point.y.isFinite && vertex.depth.isFinite)
          }
        }
      }
      let left = mesh.vertex(u: 0.25, v: 0.5, progress: 0.6)
      let right = mesh.vertex(u: 0.75, v: 0.5, progress: 0.6)
      XCTAssertLessThan(abs(left.point.x - right.point.x), 65)
    }
  }

  func testCreateUpdateReloadAndDelete() {
    let store = NotesStore(fileURL: url)
    XCTAssertTrue(store.notes.isEmpty)
    let id = store.create()!
    store.update(id, text: "My note\nA second line")
    let reopened = NotesStore(fileURL: url)
    XCTAssertEqual(reopened.note(id)?.title, "My note")
    XCTAssertEqual(reopened.note(id)?.text, "My note\nA second line")
    reopened.delete(id)
    XCTAssertTrue(NotesStore(fileURL: url).notes.isEmpty)
  }

  func testMostRecentlyEditedFirstAndCreationDateIsPreserved() {
    let store = NotesStore(fileURL: url)
    let start = Date(timeIntervalSince1970: 100)
    let first = store.create(now: start)!
    let second = store.create(now: start.addingTimeInterval(10))!
    XCTAssertEqual(store.sortedNotes.map(\.id), [second, first])
    store.update(first, text: "Edited", now: start.addingTimeInterval(20))
    XCTAssertEqual(store.sortedNotes.map(\.id), [first, second])
    XCTAssertEqual(store.note(first)?.createdAt, start)
    store.update(first, text: "Edited", now: start.addingTimeInterval(30))
    XCTAssertEqual(store.note(first)?.modifiedAt, start.addingTimeInterval(20))
  }

  func testSearchIncludesBodyAndIgnoresCaseAndDiacritics() {
    let store = NotesStore(fileURL: url)
    let first = store.create()!
    store.update(first, text: "Weekend\nCafé in Guildford")
    let second = store.create()!
    store.update(second, text: "购物清单\n牛奶和鸡蛋")
    XCTAssertEqual(store.matching("CAFE").map(\.id), [first])
    XCTAssertEqual(store.matching("牛奶").map(\.id), [second])
    XCTAssertEqual(store.matching("  Guildford  ").map(\.id), [first])
    XCTAssertTrue(store.matching("missing").isEmpty)
    XCTAssertEqual(store.matching(" ").count, 2)
  }

  func testFirstNonemptyLineBecomesTitle() {
    XCTAssertEqual(Note(text: "\n  \n Hello world \nBody").title, "Hello world")
    XCTAssertTrue(Note(text: " \n\t").isEmpty)
    XCTAssertFalse(Note(text: "字").isEmpty)
  }

  func testAbandonedEmptyDraftIsRemovedButRealNoteIsKept() {
    let store = NotesStore(fileURL: url)
    let empty = store.create()!
    store.update(empty, text: " \n")
    store.discardEmpty(empty)
    XCTAssertNil(store.note(empty))
    let real = store.create()!
    store.update(real, text: "Keep me")
    store.discardEmpty(real)
    XCTAssertNotNil(NotesStore(fileURL: url).note(real))
  }

  func testFontPersistsAndAllOriginalFontsAreAvailable() {
    let store = NotesStore(fileURL: url)
    for font in NoteFont.allCases {
      store.setFont(font)
      XCTAssertEqual(NotesStore(fileURL: url).font, font)
      XCTAssertNotNil(UIFont(name: font.postScriptName, size: 20))
    }
  }

  func testCorruptArchiveIsPreservedAndCannotBeOverwritten() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let original = Data("unreadable archive".utf8)
    try original.write(to: url)
    let store = NotesStore(fileURL: url)
    XCTAssertFalse(store.canWrite)
    XCTAssertNotNil(store.storageError)
    XCTAssertNil(store.create())
    store.persist()
    XCTAssertEqual(try Data(contentsOf: url), original)
  }

  func testFutureArchiveVersionIsPreserved() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let original = try JSONEncoder().encode(NotesArchive(version: 9, notes: [Note(text: "Future")]))
    try original.write(to: url)
    let store = NotesStore(fileURL: url)
    XCTAssertFalse(store.canWrite)
    XCTAssertEqual(try Data(contentsOf: url), original)
  }

  func testSaveFailureKeepsUnsavedTextAndRetryRecovers() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let blocked = directory.appendingPathComponent("blocked")
    try Data("file".utf8).write(to: blocked)
    let store = NotesStore(fileURL: blocked.appendingPathComponent("notes.json"))
    let id = store.create()!
    store.update(id, text: "Recover this text")
    XCTAssertNotNil(store.storageError)
    XCTAssertEqual(store.note(id)?.text, "Recover this text")
    try FileManager.default.removeItem(at: blocked)
    store.persist()
    XCTAssertNil(store.storageError)
    XCTAssertEqual(NotesStore(fileURL: store.fileURL).note(id)?.text, "Recover this text")
  }

  func testSystemLanguageMatchesWeatherRules() {
    XCTAssertEqual(AppLanguage.preferred(["zh-Hans-CN", "en"]), .chinese)
    XCTAssertEqual(AppLanguage.preferred(["zh-Hant-TW"]), .chinese)
    XCTAssertEqual(AppLanguage.preferred(["en-GB", "zh-Hans"]), .english)
    XCTAssertEqual(AppLanguage.preferred(["fr-FR", "zh-Hans"]), .english)
    XCTAssertEqual(AppLanguage.preferred([]), .english)
  }

  func testBilingualResourcesAndHomeScreenNames() throws {
    let keys = [
      "Notes", "Accounts", "Search", "Delete Note", "Share Note", "Previous Note", "Next Note",
      "Font", "Note text", "Mail", "Print", "Copy", "Mail Not Available", "Unable to Print",
      "Printer Options", "Printers", "Printer", "Select Printer", "Fewer Copies", "More Copies",
      "Looking for Printers…", "Connecting to Printer…", "No AirPrint Printers Found",
    ]
    for key in keys {
      XCTAssertNotEqual(L10n.text(key, language: .chinese), key)
      XCTAssertEqual(L10n.text(key, language: .english), key)
    }
    XCTAssertEqual(L10n.noteCount(1, language: .english), "1 Note")
    XCTAssertEqual(L10n.noteCount(12, language: .chinese), "12 条备忘录")
    for language in AppLanguage.allCases {
      let path = try XCTUnwrap(Bundle.main.path(forResource: language.rawValue, ofType: "lproj"))
      let bundle = try XCTUnwrap(Bundle(path: path))
      XCTAssertEqual(
        bundle.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist"),
        L10n.text("Notes", language: language))
      XCTAssertNotEqual(
        bundle.localizedString(
          forKey: "NSLocalNetworkUsageDescription", value: nil, table: "InfoPlist"),
        "NSLocalNetworkUsageDescription")
    }
    XCTAssertEqual(
      Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String],
      ["_ipp._tcp", "_ipps._tcp"])
    XCTAssertEqual(L10n.format("%d Copy", 1, language: .english), "1 Copy")
    XCTAssertEqual(L10n.format("%d Copies", 2, language: .chinese), "2 份")
  }

  func testPrintCopiesStayWithinSupportedBounds() {
    let model = ClassicPrintModel()
    model.changeCopies(by: -1)
    XCTAssertEqual(model.copies, 1)
    model.changeCopies(by: 1)
    XCTAssertEqual(model.copies, 2)
    model.changeCopies(by: 200)
    XCTAssertEqual(model.copies, 99)
    model.changeCopies(by: -200)
    XCTAssertEqual(model.copies, 1)
  }

  func testPrinterURLPreservesBonjourResourceAndIPv6Address() throws {
    let ipv4 = try XCTUnwrap(
      ClassicPrintModel.printerURL(
        host: NWEndpoint.Host("192.168.1.50"), port: NWEndpoint.Port(rawValue: 631)!,
        path: "/ipp/print/", secure: false))
    XCTAssertEqual(ipv4.absoluteString, "ipp://192.168.1.50:631/ipp/print")
    let ipv6 = try XCTUnwrap(
      ClassicPrintModel.printerURL(
        host: NWEndpoint.Host("fe80::1%en0"), port: NWEndpoint.Port(rawValue: 631)!,
        path: "printers/Office Printer", secure: true))
    XCTAssertEqual(ipv6.scheme, "ipps")
    XCTAssertTrue(ipv6.absoluteString.contains("[fe80::1%25en0]"))
    XCTAssertEqual(ipv6.path, "/printers/Office Printer")
  }

  func testPrintPDFPaginatesCompleteBilingualNote() throws {
    let beginning = "中文备忘录 English note"
    let ending = "最后一行 Final line"
    let text =
      beginning + "\n" + (0..<180).map { "Line \($0): 记住这件事" }.joined(separator: "\n") + "\n"
      + ending
    let document = try XCTUnwrap(PDFDocument(data: NotePrintDocument.pdf(text: text)))
    XCTAssertGreaterThan(document.pageCount, 1)
    let extracted = try XCTUnwrap(document.string)
    XCTAssertTrue(extracted.contains(beginning))
    XCTAssertTrue(extracted.contains(ending))
  }

  func testLanguageChangeDoesNotTranslateUserContent() {
    let store = NotesStore(fileURL: url)
    let id = store.create()!
    store.update(id, text: "中文内容\nEnglish content")
    XCTAssertEqual(NotesStore(fileURL: url).note(id)?.text, "中文内容\nEnglish content")
    XCTAssertTrue(NotesStore.sampleNotes(language: .chinese)[0].text.hasPrefix("欢迎"))
    XCTAssertTrue(NotesStore.sampleNotes(language: .english)[0].text.hasPrefix("Welcome"))
  }

  func testTimestampAndRelativeLabelsUseSelectedLanguage() {
    let now = Date.now
    XCTAssertEqual(AppLanguage.chinese.relativeDate(now), "今天")
    XCTAssertEqual(AppLanguage.english.relativeDate(now), "Today")
    XCTAssertTrue(AppLanguage.chinese.timestamp(now).contains("月"))
    XCTAssertFalse(AppLanguage.chinese.timestamp(now).contains("AM"))
  }

  func testTranslationTablesHaveMatchingKeys() throws {
    func table(_ language: AppLanguage) throws -> [String: String] {
      let path = try XCTUnwrap(
        Bundle.main.path(
          forResource: "Localizable", ofType: "strings", inDirectory: language.rawValue + ".lproj"))
      return try XCTUnwrap(
        PropertyListSerialization.propertyList(
          from: Data(contentsOf: URL(fileURLWithPath: path)), format: nil) as? [String: String])
    }
    XCTAssertEqual(Set(try table(.english).keys), Set(try table(.chinese).keys))
  }
}
