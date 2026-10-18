import SwiftUI
import Vision
import XCTest

@testable import PassbookSix

final class PassModelTests: XCTestCase {
  func testStackUsesFullAvailableHeightForEveryCount() {
    for count in [1, 2, 3, 5, 9] {
      let layout = PassStackLayout(count: count, availableHeight: 760)
      XCTAssertEqual(layout.top(at: 0), 0)
      XCTAssertEqual(layout.stackHeight, 760)
      XCTAssertEqual(
        layout.top(at: count - 1) + layout.exposedHeight(at: count - 1), layout.contentHeight,
        accuracy: 0.001)
      XCTAssertEqual(
        (0..<count).map { layout.exposedHeight(at: $0) }.reduce(0, +), layout.contentHeight,
        accuracy: 0.001)
      XCTAssertEqual(layout.cardHeight(at: count - 1), 760)
      XCTAssertEqual(layout.reveal, 0)
    }
  }
  func testPullRevealTracksFingerDistanceAndClampsAtFullCard() {
    for count in [2, 5, 9] {
      let rest = PassStackLayout(count: count, availableHeight: 760)
      let partial = PassStackLayout(count: count, availableHeight: 760, pullDistance: 180)
      let larger = PassStackLayout(count: count, availableHeight: 760, pullDistance: 360)
      let full = PassStackLayout(count: count, availableHeight: 760, pullDistance: 2000)
      XCTAssertEqual(rest.top(at: count - 1) - partial.top(at: count - 1), 180)
      XCTAssertEqual(
        larger.exposedHeight(at: count - 1) - partial.exposedHeight(at: count - 1), 180)
      XCTAssertEqual(full.top(at: count - 1), 0, accuracy: 0.001)
      XCTAssertEqual(full.exposedHeight(at: count - 1), 760)
      XCTAssertEqual(partial.contentHeight, rest.contentHeight)
      XCTAssertEqual(
        PassStackLayout(count: count, availableHeight: 760).top(at: count - 1),
        rest.top(at: count - 1))
    }
  }
  func testLargeStackAndLandscapeKeepEveryHeaderReachable() {
    for count in [9, 20, 50] {
      let layout = PassStackLayout(count: count, availableHeight: 270)
      XCTAssertGreaterThanOrEqual(layout.step, 60)
      XCTAssertGreaterThanOrEqual(layout.contentHeight, CGFloat(count) * 60)
      XCTAssertEqual(layout.cardHeight(at: count - 1), 520, accuracy: 0.001)
    }
  }
  func testTicketNotchesRemovePaperWithoutAddingExternalCircles() {
    let bounds = CGRect(x: 0, y: 0, width: 65, height: 85)
    for kind in [PassKind.boardingPass, .eventTicket, .coupon, .storeCard] {
      let shape = TicketSilhouette(kind: kind).path(in: bounds)
      XCTAssertTrue(bounds.contains(shape.boundingRect), kind.rawValue)
      XCTAssertTrue(shape.contains(CGPoint(x: 32, y: 40)), kind.rawValue)
    }
    let boarding = TicketSilhouette(kind: .boardingPass).path(in: bounds)
    XCTAssertFalse(boarding.contains(CGPoint(x: 2, y: 28)))
    let event = TicketSilhouette(kind: .eventTicket).path(in: bounds)
    XCTAssertFalse(event.contains(CGPoint(x: 32, y: 3)))
    let coupon = TicketSilhouette(kind: .coupon).path(in: bounds)
    XCTAssertFalse(coupon.contains(CGPoint(x: 8, y: 2)))
    XCTAssertFalse(coupon.contains(CGPoint(x: 8, y: 83)))
  }
  func testWeatherLanguageRules() {
    for language in ["zh-Hans", "zh-Hant-TW", "zh-HK", "ZH-cn"] {
      XCTAssertEqual(AppLanguage.preferred([language]), .chinese)
    }
    for languages in [[], ["en-GB"], ["fr-FR", "zh-Hans"], ["ja"]] {
      XCTAssertEqual(AppLanguage.preferred(languages), .english)
    }
  }
  func testSamplePassesHaveDistinctIdentitiesAndDemoBarcodes() throws {
    let values = PassSamples.collection
    XCTAssertEqual(Set(values.map(\.id)).count, values.count)
    XCTAssertEqual(Set(values.map(\.kind)).count, 5)
    XCTAssertTrue(values.allSatisfy(\.isDemo))
    XCTAssertTrue(values.allSatisfy { $0.barcode?.message.hasPrefix("DEMO:") == true })
    XCTAssertEqual(
      try JSONDecoder().decode([PocketPass].self, from: JSONEncoder().encode(values)), values)
  }
  func testUserContentRemainsUntranslated() {
    var pass = PassSamples.make(.storeCard)
    pass.isDemo = false
    XCTAssertEqual(pass.display("All stores"), "All stores")
  }
  func testExpiryBoundary() {
    var pass = PassSamples.make(.coupon)
    XCTAssertFalse(pass.expired(at: Date(timeIntervalSince1970: 100)))
    pass.expirationDate = Date(timeIntervalSince1970: 100)
    XCTAssertFalse(pass.expired(at: Date(timeIntervalSince1970: 100)))
    XCTAssertTrue(pass.expired(at: Date(timeIntervalSince1970: 101)))
  }
  func testAllFourBarcodeFormatsDecodeToOriginalMessage() throws {
    for format in [
      "PKBarcodeFormatQR", "PKBarcodeFormatPDF417", "PKBarcodeFormatAztec",
      "PKBarcodeFormatCode128",
    ] {
      let barcode = PassBarcode(message: "PASSBOOK-2012-123456", format: format, alternateText: "")
      let image = try XCTUnwrap(BarcodeRenderer.image(barcode)?.cgImage, format)
      let request = VNDetectBarcodesRequest()
      // Revision 1 uses the deterministic CPU decoder available on both simulator runtimes.
      request.revision = 1
      try VNImageRequestHandler(cgImage: image).perform([request])
      XCTAssertEqual(request.results?.first?.payloadStringValue, barcode.message, format)
    }
  }
  func testUnsupportedBarcodeDoesNotInventCode() {
    XCTAssertNil(
      BarcodeRenderer.image(.init(message: "1234", format: "unsupported", alternateText: "")))
  }
  func testUTF8BarcodePreservesChinesePayload() throws {
    let barcode = PassBarcode(
      message: "会员卡-123", format: "PKBarcodeFormatQR", alternateText: "", encoding: "utf-8")
    let image = try XCTUnwrap(BarcodeRenderer.image(barcode)?.cgImage)
    let request = VNDetectBarcodesRequest()
    request.revision = 1
    try VNImageRequestHandler(cgImage: image).perform([request])
    XCTAssertEqual(request.results?.first?.payloadStringValue, barcode.message)
  }
}

@MainActor
final class PassStoreTests: XCTestCase {
  private var directory: URL!
  override func setUp() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }
  override func tearDown() { try? FileManager.default.removeItem(at: directory) }
  func testNormalLaunchStartsEmptyAndSamplesAreExplicitAndIdempotent() {
    let store = PassStore(directory: directory)
    XCTAssertTrue(store.passes.isEmpty)
    store.addSamples()
    store.addSamples()
    XCTAssertEqual(store.passes.count, PassSamples.collection.count)
    XCTAssertEqual(PassStore(directory: directory).passes, store.passes)
  }
  func testReplaceMoveDeleteAndRelaunch() {
    let store = PassStore(directory: directory, demo: true)
    var pass = store.passes[1]
    pass.userNote = "User 中文 content"
    XCTAssertTrue(store.save(pass))
    store.move(pass.id, by: -1)
    store.move(pass.id, by: -100)
    let reopened = PassStore(directory: directory)
    XCTAssertEqual(reopened.passes[0].userNote, pass.userNote)
    XCTAssertEqual(reopened.passes.count, PassSamples.collection.count)
    XCTAssertTrue(reopened.remove(pass.id))
    XCTAssertNil(PassStore(directory: directory).pass(pass.id))
  }
  func testFailedWriteDoesNotCommitMemoryChanges() throws {
    let store = PassStore(directory: directory, demo: true)
    let before = store.passes
    let file = directory.appendingPathComponent("passes.json")
    try FileManager.default.removeItem(at: file)
    try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
    XCTAssertFalse(store.remove(before[0].id))
    XCTAssertEqual(store.passes, before)
    XCTAssertNotNil(store.errorMessage)
  }
  func testCorruptStoreIsPreserved() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let file = directory.appendingPathComponent("passes.json")
    let original = Data("corrupt fixture".utf8)
    try original.write(to: file)
    let store = PassStore(directory: directory)
    XCTAssertNotNil(store.errorMessage)
    XCTAssertEqual(try Data(contentsOf: file), original)
  }
  func testInvalidImportDoesNotChangeExistingPasses() throws {
    let store = PassStore(directory: directory, demo: true)
    let before = store.passes
    let file = directory.appendingPathComponent("invalid.pkpass")
    try Data("not a signed pass".utf8).write(to: file)
    store.importPass(from: file)
    XCTAssertNotNil(store.errorMessage)
    XCTAssertEqual(store.passes, before)
  }
  func testRemovingLocalCopyDoesNotLeaveItsPackage() throws {
    let store = PassStore(directory: directory)
    var pass = PassSamples.make(.storeCard)
    pass.sourceFilename = "fixture.pkpass"
    let file = directory.appendingPathComponent("fixture.pkpass")
    try Data("fixture".utf8).write(to: file)
    store.save(pass)
    XCTAssertTrue(store.remove(pass.id))
    XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
  }
}

final class PassImportTests: XCTestCase {
  func testAllKindsAndFieldGroups() throws {
    for kind in PassKind.allCases {
      let json: [String: Any] = [
        "organizationName": "Example", "serialNumber": "12", "passTypeIdentifier": "pass.example",
        "backgroundColor": "rgb(10, 20, 255)",
        kind.rawValue: [
          "headerFields": [["key": "gate", "label": "Gate", "value": "A12"]],
          "primaryFields": [["key": "name", "label": "Name", "value": "User Name"]],
          "secondaryFields": [["key": "number", "label": "Number", "value": 123]],
          "backFields": [["key": "terms", "label": "Terms", "value": "Issuer original text"]],
        ],
        "barcodes": [
          ["message": "123456", "format": "PKBarcodeFormatQR", "messageEncoding": "utf-8"]
        ],
      ]
      let pass = try PassImporter.decodeJSON(JSONSerialization.data(withJSONObject: json))
      XCTAssertEqual(pass.id, "pass.example:12")
      XCTAssertEqual(pass.kind, kind)
      XCTAssertEqual(pass.colorHex, "0A14FF")
      XCTAssertEqual(pass.header.first?.value, "A12")
      XCTAssertEqual(pass.primary.first?.value, "User Name")
      XCTAssertEqual(pass.secondary.first?.value, "123")
      XCTAssertEqual(pass.back.first?.value, "Issuer original text")
      XCTAssertEqual(pass.barcode?.encoding, "utf-8")
      XCTAssertFalse(pass.isDemo)
    }
  }
  func testColorValidation() {
    XCTAssertEqual(PassImporter.color("rgb(256, -1, 2)", fallback: "123456"), "123456")
    XCTAssertEqual(PassImporter.color("#abcdef", fallback: "000000"), "abcdef")
    XCTAssertEqual(PassImporter.color("#GGGGGG", fallback: "000000"), "000000")
  }
  func testMalformedInputsAreRejected() {
    for value in [Data(), Data("{}".utf8), Data(repeating: 0, count: 100)] {
      XCTAssertThrowsError(try PassImporter.decode(value))
      XCTAssertThrowsError(try PassArchive(data: value))
    }
    XCTAssertThrowsError(try PassImporter.decodeJSON(Data("{}".utf8)))
  }
  func testArchiveStoredAndDeflatedFixtures() throws {
    for name in ["stored", "deflated"] {
      let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "zip"))
      let archive = try PassArchive(data: Data(contentsOf: url))
      XCTAssertEqual(
        String(data: try archive.entry("pass.json"), encoding: .utf8), "{\"fixture\":true}")
      XCTAssertNil(try archive.optionalEntry("absent.png"))
      XCTAssertThrowsError(try archive.entry("missing.json"))
    }
  }
}
