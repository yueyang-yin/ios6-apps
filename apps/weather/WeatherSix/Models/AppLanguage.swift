import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
  case english = "en"
  case chinese = "zh-Hans"

  static var current: Self { preferred(Locale.preferredLanguages) }

  static func preferred(_ languages: [String]) -> Self {
    languages.first?.lowercased().hasPrefix("zh") == true ? .chinese : .english
  }

  static func searchLanguage(for query: String, fallback: Self = .current) -> Self {
    if PlaceQuery.containsHan(query) { return .chinese }
    if query.range(of: "[A-Za-z]", options: .regularExpression) != nil { return .english }
    return fallback
  }

  var locale: Locale { Locale(identifier: self == .chinese ? "zh_CN" : "en_US") }
  var photonCode: String { self == .chinese ? "default" : "en" }
  var geocodingCode: String { self == .chinese ? "zh" : "en" }
  var other: Self { self == .chinese ? .english : .chinese }

  func normalizePlaceName(_ name: String, countryCode: String? = nil) -> String {
    if self == .chinese {
      let translated = L10n.text(name, language: self)
      return translated.applyingTransform(StringTransform("Traditional-Simplified"), reverse: false)
        ?? translated
    }
    guard countryCode?.uppercased() == "CN", PlaceQuery.containsHan(name) else { return name }
    return name.applyingTransform(.toLatin, reverse: false)?
      .applyingTransform(.stripDiacritics, reverse: false) ?? name
  }
}

enum L10n {
  static func text(_ key: String, language: AppLanguage = .current) -> String {
    guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
      let bundle = Bundle(path: path)
    else { return key }
    return bundle.localizedString(forKey: key, value: key, table: "Localizable")
  }

  static func format(
    _ key: String, _ arguments: CVarArg..., language: AppLanguage = .current
  ) -> String {
    String(format: text(key, language: language), locale: language.locale, arguments: arguments)
  }
}
