import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
  case english = "en"
  case chinese = "zh-Hans"

  static var current: Self { preferred(Locale.preferredLanguages) }

  static func preferred(_ languages: [String]) -> Self {
    languages.first?.lowercased().hasPrefix("zh") == true ? .chinese : .english
  }

  var locale: Locale { Locale(identifier: self == .chinese ? "zh_CN" : "en_US") }
}

enum L10n {
  static func text(_ key: String, language: AppLanguage = .current) -> String {
    guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
      let bundle = Bundle(path: path)
    else { return key }
    return bundle.localizedString(forKey: key, value: key, table: "Localizable")
  }
}
