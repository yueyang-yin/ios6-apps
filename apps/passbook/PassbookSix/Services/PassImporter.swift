import Foundation
import PassKit
import zlib

enum PassImportError: Error { case invalid, tooLarge, unsupported }

enum PassImporter {
  static func decode(_ data: Data) throws -> PocketPass {
    guard data.count <= 20_000_000 else { throw PassImportError.tooLarge }
    // PassKit verifies the signed package before any contents become trusted pass data.
    let verified = try PKPass(data: data)
    let archive = try PassArchive(data: data)
    var pass = try decodeJSON(archive.entry("pass.json"))
    pass.id = "\(verified.passTypeIdentifier):\(verified.serialNumber)"
    pass.logoData = try archive.optionalEntry("logo@2x.png") ?? archive.optionalEntry("logo.png")
    pass.stripData = try archive.optionalEntry("strip@2x.png") ?? archive.optionalEntry("strip.png")
    return pass
  }

  static func decodeJSON(_ data: Data) throws -> PocketPass {
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let organization = json["organizationName"] as? String,
      let serial = json["serialNumber"] as? String,
      let type = json["passTypeIdentifier"] as? String,
      let kind = PassKind.allCases.first(where: { json[$0.rawValue] is [String: Any] }),
      let body = json[kind.rawValue] as? [String: Any]
    else { throw PassImportError.invalid }
    func fields(_ name: String) -> [PassField] {
      let entries = body[name] as? [[String: Any]] ?? []
      var seen = Set<String>()
      return entries.enumerated().compactMap { index, item in
        let key = item["key"] as? String ?? "field-\(index)"
        guard seen.insert(key).inserted, let value = item["value"] else { return nil }
        let text: String
        if let currency = item["currencyCode"] as? String, let number = value as? NSNumber {
          text = number.doubleValue.formatted(
            .currency(code: currency).locale(AppLanguage.current.locale))
        } else if let string = value as? String, item["dateStyle"] != nil,
          let date = ISO8601DateFormatter().date(from: string)
        {
          text = date.formatted(.dateTime.year().month().day().locale(AppLanguage.current.locale))
        } else {
          text = String(describing: value)
        }
        return .init(key: key, label: item["label"] as? String ?? "", value: text)
      }
    }
    let rawBarcode =
      (json["barcodes"] as? [[String: Any]])?.first ?? json["barcode"] as? [String: Any]
    let barcode = rawBarcode.flatMap { item -> PassBarcode? in
      guard let message = item["message"] as? String, let format = item["format"] as? String else {
        return nil
      }
      return .init(
        message: message, format: format, alternateText: item["altText"] as? String ?? "",
        encoding: item["messageEncoding"] as? String ?? "iso-8859-1")
    }
    return PocketPass(
      id: "\(type):\(serial)", kind: kind, organization: organization,
      title: json["description"] as? String ?? organization,
      colorHex: color(json["backgroundColor"] as? String, fallback: kind.hex),
      foregroundHex: color(json["foregroundColor"] as? String, fallback: "FFFFFF"),
      labelHex: color(json["labelColor"] as? String, fallback: "FFFFFF"),
      header: fields("headerFields"), primary: fields("primaryFields"),
      secondary: fields("secondaryFields"), auxiliary: fields("auxiliaryFields"),
      back: fields("backFields"),
      barcode: barcode,
      relevantDate: (json["relevantDate"] as? String).flatMap {
        ISO8601DateFormatter().date(from: $0)
      },
      expirationDate: (json["expirationDate"] as? String).flatMap {
        ISO8601DateFormatter().date(from: $0)
      })
  }

  static func color(_ string: String?, fallback: String) -> String {
    guard let string else { return fallback }
    if string.hasPrefix("#"), string.count == 7,
      UInt64(string.dropFirst(), radix: 16) != nil
    {
      return String(string.dropFirst())
    }
    let values = string.replacingOccurrences(of: "rgb(", with: "")
      .replacingOccurrences(of: ")", with: "").split(separator: ",")
      .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    guard values.count == 3, values.allSatisfy({ (0...255).contains($0) }) else { return fallback }
    return values.map { String(format: "%02X", $0) }.joined()
  }
}

// Read only named entries into bounded buffers; never extract an archive to the filesystem.
struct PassArchive {
  private let bytes: [UInt8]
  private let entries: [String: Entry]
  private struct Entry {
    var offset: Int
    var compressed: Int
    var size: Int
    var method: Int
  }

  init(data: Data) throws {
    guard data.count >= 22, data.count <= 20_000_000 else { throw PassImportError.invalid }
    let bytes = [UInt8](data)
    func number(_ offset: Int, _ length: Int) throws -> Int {
      guard offset >= 0, offset + length <= bytes.count else { throw PassImportError.invalid }
      return (0..<length).reduce(0) { $0 | Int(bytes[offset + $1]) << (8 * $1) }
    }
    guard
      let end = stride(from: bytes.count - 22, through: max(0, bytes.count - 65_557), by: -1)
        .first(where: { bytes[$0..<$0 + 4].elementsEqual([0x50, 0x4b, 0x05, 0x06]) })
    else { throw PassImportError.invalid }
    let count = try number(end + 10, 2)
    guard count <= 500 else { throw PassImportError.tooLarge }
    var cursor = try number(end + 16, 4)
    var entries: [String: Entry] = [:]
    for _ in 0..<count {
      guard try number(cursor, 4) == 0x0201_4b50 else { throw PassImportError.invalid }
      let nameLength = try number(cursor + 28, 2)
      let extraLength = try number(cursor + 30, 2)
      let commentLength = try number(cursor + 32, 2)
      guard cursor + 46 + nameLength <= bytes.count else { throw PassImportError.invalid }
      let name = String(decoding: bytes[(cursor + 46)..<(cursor + 46 + nameLength)], as: UTF8.self)
      entries[name] = Entry(
        offset: try number(cursor + 42, 4),
        compressed: try number(cursor + 20, 4), size: try number(cursor + 24, 4),
        method: try number(cursor + 10, 2))
      cursor += 46 + nameLength + extraLength + commentLength
    }
    self.bytes = bytes
    self.entries = entries
  }

  func optionalEntry(_ name: String) throws -> Data? {
    guard entries[name] != nil else { return nil }
    return try entry(name)
  }

  func entry(_ name: String) throws -> Data {
    guard let entry = entries[name], entry.size > 0, entry.size <= 5_000_000,
      entry.offset >= 0, entry.offset + 30 <= bytes.count,
      bytes[entry.offset..<entry.offset + 4].elementsEqual([0x50, 0x4b, 0x03, 0x04])
    else { throw PassImportError.invalid }
    func short(_ offset: Int) -> Int { Int(bytes[offset]) | Int(bytes[offset + 1]) << 8 }
    let start = entry.offset + 30 + short(entry.offset + 26) + short(entry.offset + 28)
    guard entry.compressed > 0, start + entry.compressed <= bytes.count else {
      throw PassImportError.invalid
    }
    let input = Array(bytes[start..<(start + entry.compressed)])
    if entry.method == 0 {
      guard input.count == entry.size else { throw PassImportError.invalid }
      return Data(input)
    }
    guard entry.method == 8 else { throw PassImportError.unsupported }
    var output = [UInt8](repeating: 0, count: entry.size)
    var stream = z_stream()
    guard
      inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK
    else { throw PassImportError.invalid }
    defer { inflateEnd(&stream) }
    let status = input.withUnsafeBytes { source in
      output.withUnsafeMutableBytes { target in
        stream.next_in = UnsafeMutablePointer(
          mutating: source.bindMemory(to: Bytef.self).baseAddress)
        stream.avail_in = uInt(input.count)
        stream.next_out = target.bindMemory(to: Bytef.self).baseAddress
        stream.avail_out = uInt(entry.size)
        return inflate(&stream, Z_FINISH)
      }
    }
    guard status == Z_STREAM_END, stream.total_out == entry.size else {
      throw PassImportError.invalid
    }
    return Data(output)
  }
}
