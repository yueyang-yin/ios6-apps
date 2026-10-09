import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
  case english = "en"
  case chinese = "zh-Hans"

  static var current: Self { preferred(Locale.preferredLanguages) }

  static func preferred(_ languages: [String]) -> Self {
    languages.first?.lowercased().hasPrefix("zh") == true ? .chinese : .english
  }

  var locale: Locale { Locale(identifier: self == .chinese ? "zh_CN" : "en_US") }

  func timestamp(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateFormat = self == .chinese ? "M月d日 HH:mm" : "MMM d  h:mm a"
    return formatter.string(from: date)
  }

  func listDate(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
    if calendar.isDate(date, inSameDayAs: now) {
      let formatter = DateFormatter()
      formatter.locale = locale
      formatter.dateFormat = self == .chinese ? "HH:mm" : "h:mm a"
      return formatter.string(from: date)
    }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
      calendar.isDate(date, inSameDayAs: yesterday)
    {
      return L10n.text("Yesterday", language: self)
    }
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateFormat = self == .chinese ? "yyyy/M/d" : "M/d/yy"
    return formatter.string(from: date)
  }

  func relativeDate(_ date: Date, now: Date = .now) -> String {
    let days =
      Calendar.current.dateComponents(
        [.day], from: Calendar.current.startOfDay(for: date),
        to: Calendar.current.startOfDay(for: now)
      ).day ?? 0
    if days <= 0 { return L10n.text("Today", language: self) }
    if days == 1 { return L10n.text("Yesterday", language: self) }
    return L10n.format("%d days ago", days, language: self)
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

  static func noteCount(_ count: Int, language: AppLanguage = .current) -> String {
    format(count == 1 ? "%d Note" : "%d Notes", count, language: language)
  }
}
