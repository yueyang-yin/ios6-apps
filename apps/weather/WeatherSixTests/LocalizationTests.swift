import XCTest

@testable import WeatherSix

@MainActor
final class LocalizationTests: XCTestCase {
  func testSystemLanguageAndQueryLanguageAreIndependent() {
    XCTAssertEqual(AppLanguage.preferred(["zh-CN", "en"]), .chinese)
    XCTAssertEqual(AppLanguage.preferred(["zh-Hant-TW"]), .chinese)
    XCTAssertEqual(AppLanguage.preferred(["en-GB", "zh-Hans"]), .english)
    XCTAssertEqual(AppLanguage.preferred(["fr-FR", "zh-Hans"]), .english)
    XCTAssertEqual(AppLanguage.searchLanguage(for: "泉山区", fallback: .english), .chinese)
    XCTAssertEqual(AppLanguage.searchLanguage(for: "QuanShan", fallback: .chinese), .english)
    XCTAssertEqual(AppLanguage.searchLanguage(for: "100000", fallback: .chinese), .chinese)
    XCTAssertEqual(AppLanguage.searchLanguage(for: "100000", fallback: .english), .english)
  }

  func testBundledTranslationsFormatRealTemperaturesAndControls() {
    XCTAssertEqual(L10n.text("Weather", language: .chinese), "天气")
    XCTAssertEqual(L10n.text("Use Current Location", language: .chinese), "使用当前位置")
    XCTAssertEqual(L10n.text("ON", language: .chinese), "开")
    XCTAssertEqual(L10n.format("%lld degrees celsius", -42, language: .chinese), "-42 摄氏度")
    XCTAssertEqual(
      L10n.format("%lld degrees fahrenheit", 118, language: .english), "118 degrees fahrenheit")
    XCTAssertEqual(L10n.text("Weather", language: .english), "Weather")
    XCTAssertEqual(
      L10n.text("Unknown official place", language: .chinese), "Unknown official place")
  }

  func testDatesFollowLanguageWithoutChangingCityTimeZone() {
    let date = Date(timeIntervalSince1970: 0)
    XCTAssertEqual(
      WeatherDate.string(date, format: "EEEE", timeZone: "GMT", language: .chinese), "星期四")
    XCTAssertEqual(
      WeatherDate.string(date, format: "EEEE", timeZone: "GMT", language: .english), "Thursday")
    XCTAssertEqual(
      WeatherDate.string(date, format: "h:mm a", timeZone: "Asia/Shanghai", language: .chinese),
      "08:00")
    XCTAssertEqual(
      WeatherDate.string(date, format: "h:mm a", timeZone: "GMT", language: .chinese), "00:00")
  }

  func testMissingForeignTranslationKeepsOfficialNameInsteadOfChinesePinyin() {
    XCTAssertEqual(AppLanguage.english.normalizePlaceName("東京都", countryCode: "JP"), "東京都")
    XCTAssertEqual(AppLanguage.chinese.normalizePlaceName("東京", countryCode: "JP"), "东京")
    XCTAssertFalse(
      PlaceQuery.containsHan(AppLanguage.english.normalizePlaceName("泉山区", countryCode: "CN")))
  }

  func testChineseSearchChoiceKeepsEnglishNameAndSurvivesPersistence() throws {
    let suite = "LocalizationTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = WeatherStore(defaults: defaults, arguments: [])
    let city = WeatherCity.defaults[1].displaying(.chinese)
    XCTAssertEqual(city.name, "伦敦")
    XCTAssertEqual(city.displayName(language: .english), "London")
    store.add(city)
    let restored = WeatherStore(defaults: defaults, arguments: [])
    let saved = try XCTUnwrap(restored.cities.first { $0.id == "london" })
    XCTAssertEqual(saved.displayName(language: .chinese), "伦敦")
    XCTAssertEqual(saved.displayName(language: .english), "London")
    XCTAssertEqual(saved.displayCountry(language: .chinese), "英国")
    XCTAssertEqual(saved.latitude, city.latitude)
    XCTAssertEqual(saved.id, city.id)
  }

  func testPreviouslySavedCityDecodesWithoutLocalizationFields() throws {
    let data = Data(
      """
      {"id":"legacy","name":"London","country":"United Kingdom","latitude":51.5,
       "longitude":-0.12,"timeZone":"Europe/London","isLocal":false}
      """.utf8)
    let city = try JSONDecoder().decode(WeatherCity.self, from: data)
    XCTAssertNil(city.localizedNames)
    XCTAssertEqual(city.displayName(language: .chinese), "伦敦")
    XCTAssertEqual(city.displayCountry(language: .english), "United Kingdom")
    XCTAssertEqual(city.timeZone, "Europe/London")
  }

  func testTranslatedLabelUpdatesALegacyIdentifierWithoutAddingAnotherCity() {
    let store = WeatherStore(arguments: ["--uitesting"])
    let original = store.cities[1]
    var translated = original.displaying(.chinese)
    translated.id = "new-provider-id"
    store.add(translated)
    XCTAssertEqual(store.cities.count, 3)
    XCTAssertEqual(store.selectedCityID, original.id)
    XCTAssertEqual(store.cities[1].displayName(language: .chinese), "伦敦")
    XCTAssertEqual(store.cities[1].displayName(language: .english), "London")
  }

  func testNameLocalizationDoesNotDiscardAnInflightForecast() async {
    let defaults = UserDefaults(suiteName: "LocalizationTests.\(UUID().uuidString)")!
    let store = WeatherStore(
      defaults: defaults, service: LocalizingWeatherService(), arguments: ["--uitesting"])
    let city = store.cities[0]
    async let names: Void = store.localizeCity(city)
    async let forecast: Void = store.refresh(city, force: true)
    _ = await (names, forecast)
    XCTAssertEqual(store.cities[0].displayName(language: .chinese), "库比蒂诺")
    XCTAssertEqual(store.reports[city.id]?.temperature, 23)
    XCTAssertTrue(store.loading.isEmpty)
  }
}

private struct LocalizingWeatherService: WeatherProviding {
  func search(_ query: String) async throws -> [WeatherCity] { [] }
  func localizedCity(_ city: WeatherCity) async -> WeatherCity {
    try? await Task.sleep(for: .milliseconds(10))
    return city.displaying(.chinese)
  }
  func forecast(for city: WeatherCity) async throws -> WeatherReport {
    try await Task.sleep(for: .milliseconds(40))
    return .demo(for: city)
  }
}
