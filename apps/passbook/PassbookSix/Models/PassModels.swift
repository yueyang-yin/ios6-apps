import Foundation
import SwiftUI

enum PassKind: String, Codable, CaseIterable, Identifiable {
  case boardingPass, eventTicket, storeCard, coupon, generic
  var id: String { rawValue }
  var title: String {
    switch self {
    case .boardingPass: "Boarding Passes"
    case .eventTicket: "Tickets"
    case .storeCard: "Store Cards"
    case .coupon: "Coupons"
    case .generic: "Other Passes"
    }
  }
  var symbol: String {
    switch self {
    case .boardingPass: "airplane"
    case .eventTicket: "ticket.fill"
    case .storeCard: "cup.and.saucer.fill"
    case .coupon: "scissors"
    case .generic: "creditcard.fill"
    }
  }
  var hex: String {
    switch self {
    case .boardingPass: "E8B52E"
    case .eventTicket: "C53537"
    case .storeCard: "31834A"
    case .coupon: "A542BE"
    case .generic: "437EAB"
    }
  }
}

struct PassField: Codable, Hashable, Identifiable {
  var key: String
  var label: String
  var value: String
  var id: String { key }
}

struct PassBarcode: Codable, Hashable {
  var message: String
  var format: String
  var alternateText: String
  var encoding: String = "iso-8859-1"
}

struct PocketPass: Identifiable, Codable, Equatable {
  var id: String
  var kind: PassKind
  var organization: String
  var title: String
  var colorHex: String
  var foregroundHex: String = "FFFFFF"
  var labelHex: String = "FFFFFF"
  var header: [PassField] = []
  var primary: [PassField] = []
  var secondary: [PassField] = []
  var auxiliary: [PassField] = []
  var back: [PassField] = []
  var barcode: PassBarcode?
  var relevantDate: Date?
  var expirationDate: Date?
  var isDemo = false
  var sourceFilename: String?
  var stripData: Data?
  var logoData: Data?
  var userNote: String = ""
  var sampleStyle: String?

  var background: Color { Color(passHex: colorHex) }
  var foreground: Color { Color(passHex: foregroundHex) }
  var labelColor: Color { Color(passHex: labelHex) }
  func display(_ value: String) -> String { isDemo ? L10n.text(value) : value }
  func displayLabel(_ value: String) -> String { sourceFilename == nil ? L10n.text(value) : value }
  func expired(at date: Date = .now) -> Bool { expirationDate.map { $0 < date } ?? false }
  var shareText: String {
    ([organization, display(title)]
      + (header + primary + secondary + auxiliary + back).map {
        "\(displayLabel($0.label)): \(display($0.value))"
      } + [userNote]).filter { !$0.isEmpty }.joined(separator: "\n")
  }
}

extension Color {
  init(passHex: String) {
    let value =
      UInt64(passHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16)
      ?? 0x343638
    self.init(
      .sRGB, red: Double((value >> 16) & 255) / 255,
      green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
  }
}

enum PassSamples {
  static func make(_ kind: PassKind) -> PocketPass {
    let barcode = PassBarcode(
      message: "DEMO:PASSBOOK-SIX:\(kind.rawValue)",
      format: kind == .boardingPass ? "PKBarcodeFormatPDF417" : "PKBarcodeFormatQR",
      alternateText: "DEMO · 2012 0919 0006")
    var pass = PocketPass(
      id: "sample-\(kind.rawValue)", kind: kind, organization: "", title: "",
      colorHex: kind.hex, barcode: barcode, isDemo: true)
    pass.back = [PassField(key: "demo", label: "About this pass", value: "Sample pass explanation")]
    switch kind {
    case .boardingPass:
      pass.organization = "DELTA"
      pass.sampleStyle = "delta"
      pass.title = "Boarding Pass"
      pass.colorHex = "F2F2F4"
      pass.foregroundHex = "153C62"
      pass.labelHex = "3D6682"
      pass.header = [.init(key: "flight", label: "FLIGHT", value: "DL421")]
      pass.primary = [
        .init(key: "origin", label: "London Heathrow", value: "LHR"),
        .init(key: "destination", label: "San Francisco", value: "SFO"),
      ]
      pass.secondary = [
        .init(key: "name", label: "PASSENGER", value: "Alex Morgan"),
        .init(key: "boarding", label: "BOARDING", value: "09:41"),
      ]
      pass.auxiliary = [
        .init(key: "gate", label: "GATE", value: "A6"),
        .init(key: "seat", label: "SEAT", value: "12A"),
        .init(key: "group", label: "GROUP", value: "2"),
      ]
    case .eventTicket:
      pass.organization = "FANDANGO"
      pass.sampleStyle = "fandango"
      pass.colorHex = "D6D6D4"
      pass.foregroundHex = "244793"
      pass.labelHex = "546276"
      pass.title = "A Night at the Cinema"
      pass.header = []
      pass.primary = [
        .init(key: "event", label: "FEATURE PRESENTATION", value: "The Grand Adventure")
      ]
      pass.secondary = [
        .init(key: "time", label: "SHOWTIME", value: "7:00 PM"),
        .init(key: "theatre", label: "SCREEN", value: "6"),
      ]
      pass.auxiliary = [
        .init(key: "row", label: "ROW", value: "F"),
        .init(key: "seat", label: "SEAT", value: "12"),
        .init(key: "venue", label: "VENUE", value: "Grand Cinema"),
      ]
    case .storeCard:
      pass.organization = "Starbucks Card"
      pass.sampleStyle = "starbucks"
      pass.colorHex = "F5F4FA"
      pass.foregroundHex = "151515"
      pass.labelHex = "636363"
      pass.title = "Coffee Card"
      pass.header = [.init(key: "balance", label: "BALANCE", value: "$25.00")]
      pass.primary = [.init(key: "name", label: "NICKNAME", value: "Alex’s Coffee Card")]
      pass.secondary = [
        .init(key: "rewards", label: "REWARDS", value: "12 STARS"),
        .init(key: "member", label: "MEMBER SINCE", value: "2012"),
      ]
    case .coupon:
      pass.organization = "TARGET"
      pass.sampleStyle = "target"
      pass.colorHex = "E51916"
      pass.title = "A little something for you."
      pass.header = [.init(key: "discount", label: "DISCOUNT", value: "10% off")]
      pass.primary = [.init(key: "offer", label: "YOUR NEXT PURCHASE", value: "10% off")]
      pass.secondary = [
        .init(key: "code", label: "PROMO CODE", value: "HELLO2012"),
        .init(key: "valid", label: "VALID AT", value: "All stores"),
      ]
      pass.back.append(
        .init(key: "terms", label: "Terms and conditions", value: "Sample coupon terms"))
    case .generic:
      pass.organization = "W HOTELS"
      pass.sampleStyle = "w"
      pass.colorHex = "9B9B97"
      pass.header = [.init(key: "stay", label: "3 NIGHTS", value: "Jun 12 - 15")]
      pass.title = "Your stay"
      pass.primary = [.init(key: "guest", label: "GUEST", value: "Alex Morgan")]
      pass.secondary = [
        .init(key: "room", label: "ROOM", value: "619"),
        .init(key: "nights", label: "NIGHTS", value: "3"),
      ]
    }
    return pass
  }
  static var collection: [PocketPass] {
    var baseball = make(.eventTicket)
    baseball.id = "sample-baseball"
    baseball.sampleStyle = "baseball"
    baseball.organization = "Pittsburgh vs. New York"
    baseball.colorHex = "124CBA"
    baseball.foregroundHex = "FFFFFF"
    baseball.labelHex = "FFFFFF"
    baseball.header = [.init(key: "game", label: "Sept 27", value: "1:10 PM")]
    baseball.primary = [.init(key: "event", label: "BASEBALL", value: "Pittsburgh vs. New York")]
    var spg = make(.generic)
    spg.id = "sample-spg"
    spg.sampleStyle = "spg"
    spg.organization = "Starwood Preferred Guest"
    spg.colorHex = "B2B5B4"
    spg.header = [.init(key: "level", label: "", value: "Platinum")]
    spg.primary = [.init(key: "points", label: "STARPOINTS", value: "220,000")]
    var sheraton = make(.generic)
    sheraton.id = "sample-sheraton"
    sheraton.sampleStyle = "sheraton"
    sheraton.organization = "Sheraton"
    sheraton.colorHex = "9B4E30"
    sheraton.header = [.init(key: "stay", label: "3 NIGHTS", value: "Sep 22 - 25")]
    var american = make(.boardingPass)
    american.id = "sample-american"
    american.sampleStyle = "american"
    american.organization = "American Airlines"
    american.colorHex = "85CDF4"
    american.foregroundHex = "123565"
    american.labelHex = "295A80"
    american.header = [.init(key: "gate", label: "GATE", value: "41")]
    return [
      make(.eventTicket), make(.coupon), make(.boardingPass), baseball, make(.generic), spg,
      sheraton, american, make(.storeCard),
    ]
  }
}
