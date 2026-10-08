import XCTest

@testable import WeatherSix

@MainActor
final class WeatherSixTests: XCTestCase {
  private var defaults: UserDefaults!
  private var suite: String!

  override func setUp() {
    super.setUp()
    suite = "WeatherSixTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suite)!
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suite)
    defaults = nil
    super.tearDown()
  }

  func testTemperatureConversionIncludingFreezingAndNegativeValues() {
    XCTAssertEqual(TemperatureUnit.fahrenheit.value(0), 32)
    XCTAssertEqual(TemperatureUnit.fahrenheit.value(-40), -40)
    XCTAssertEqual(TemperatureUnit.fahrenheit.formatted(23), "73°")
    XCTAssertEqual(TemperatureUnit.celsius.value(-1.6), -2)
  }

  func testThunderstormLightningIncludesUpperArmAndLowerTip() {
    let bolt = WeatherArtwork.lightningPath
    XCTAssertEqual(bolt.cgPath.boundingBoxOfPath.minY, 73)
    XCTAssertEqual(bolt.cgPath.boundingBoxOfPath.maxY, 123)
    XCTAssertTrue(bolt.contains(CGPoint(x: 84, y: 83)))
    XCTAssertTrue(bolt.contains(CGPoint(x: 73, y: 113)))
  }

  func testCelsiusDefaultsAndOneTimeMigrationPreserveLaterUserChoice() {
    defaults.set(TemperatureUnit.fahrenheit.rawValue, forKey: "unit")
    let store = WeatherStore(defaults: defaults, arguments: [])
    XCTAssertEqual(store.unit, .celsius)
    XCTAssertEqual(defaults.integer(forKey: "temperatureUnitVersion"), 1)
    store.unit = .fahrenheit
    let restored = WeatherStore(defaults: defaults, arguments: [])
    XCTAssertEqual(restored.unit, .fahrenheit)
    let isolated = WeatherStore(defaults: defaults, arguments: ["--uitesting"])
    XCTAssertEqual(isolated.unit, .celsius)
    XCTAssertEqual(defaults.string(forKey: "unit"), "fahrenheit")
  }

  func testCurrentLocationExitsDemoAndInvalidatesPreviousLocalForecast() async {
    let service = StubWeatherService()
    let store = WeatherStore(defaults: defaults, service: service, arguments: [])
    var local = WeatherCity.defaults[1]
    local.id = "local"
    local.isLocal = true
    store.setLocal(local)
    await store.refresh(local)
    XCTAssertNotNil(store.reports["local"])
    store.demoMode = true
    local.latitude = 35.6762
    local.longitude = 139.6503
    store.setLocal(local)
    XCTAssertFalse(store.demoMode)
    XCTAssertNil(store.reports["local"])
    await store.refresh(local, force: true)
    let calls = await service.calls
    XCTAssertEqual(calls, 2)
  }

  func testWMOCodesCoverSnowShowersFogAndHail() {
    XCTAssertEqual(WeatherCondition(code: 86), .snow)
    XCTAssertEqual(WeatherCondition(code: 48), .fog)
    XCTAssertEqual(WeatherCondition(code: 99), .thunderstorm)
    XCTAssertEqual(WeatherCondition(code: 81), .rain)
  }

  func testCitiesUnitsAndModePersistAcrossLaunches() {
    let store = WeatherStore(defaults: defaults, arguments: [])
    store.unit = .celsius
    store.demoMode = true
    store.remove(store.cities[1])
    store.move(IndexSet(integer: 1), to: 0)
    let restored = WeatherStore(defaults: defaults, arguments: [])
    XCTAssertEqual(restored.cities.map(\.id), ["beijing", "cupertino"])
    XCTAssertEqual(restored.unit, .celsius)
    XCTAssertTrue(restored.demoMode)
  }

  func testDuplicateCoordinatesSelectExistingCityAndDeletingSelectionStaysValid() {
    let store = WeatherStore(defaults: defaults, arguments: [])
    var duplicate = store.cities[0]
    duplicate.id = "a-geocoder-id"
    store.add(duplicate)
    XCTAssertEqual(store.cities.count, 3)
    XCTAssertEqual(store.selectedCityID, "cupertino")
    store.remove(store.cities[0])
    XCTAssertEqual(store.selectedCityID, "london")
    for city in store.cities { store.remove(city) }
    XCTAssertNil(store.selectedCity)
  }

  func testLocalWeatherRemainsFirstWhenCitiesAreReordered() {
    let store = WeatherStore(defaults: defaults, arguments: [])
    var local = WeatherCity.defaults[1]
    local.id = "local"
    local.isLocal = true
    store.setLocal(local)
    store.move(IndexSet(integer: 3), to: 0)
    XCTAssertEqual(store.cities.map(\.id), ["local", "beijing", "cupertino", "london"])
  }

  func testNearbyDistinctDistrictCanBeAddedAndExistingPlaceContextIsUpdated() {
    let store = WeatherStore(defaults: defaults, arguments: ["--uitesting"])
    var district = store.cities[0]
    district.id = "nearby-district"
    district.name = "West District"
    district.latitude += 0.005
    store.add(district)
    XCTAssertEqual(store.cities.count, 4)
    XCTAssertEqual(store.selectedCityID, district.id)
    district.id = "alternate-provider"
    district.country = "Cupertino, California, United States"
    store.add(district)
    XCTAssertEqual(store.cities.count, 4)
    XCTAssertEqual(store.selectedCityID, "nearby-district")
    XCTAssertEqual(store.selectedCity?.country, district.country)
  }

  func testForecastResolvesAndPersistsSearchResultTimeZone() async {
    let store = WeatherStore(defaults: defaults, service: ZonedWeatherService(), arguments: [])
    let city = WeatherCity(
      id: "quanshan", name: "Quanshan", country: "Xuzhou, Jiangsu, China",
      latitude: 34.2273368, longitude: 117.1884578, timeZone: "GMT")
    store.add(city)
    await store.refresh(city)
    XCTAssertEqual(store.selectedCity?.timeZone, "Asia/Shanghai")
    let restored = WeatherStore(defaults: defaults, arguments: [])
    XCTAssertEqual(restored.cities.first { $0.id == city.id }?.timeZone, "Asia/Shanghai")
  }

  func testRefreshCachesAndOfflineFailureKeepsLastReport() async {
    let service = StubWeatherService()
    let store = WeatherStore(defaults: defaults, service: service, arguments: [])
    let city = store.cities[0]
    await store.refresh(city)
    await store.refresh(city)
    let count = await service.calls
    XCTAssertEqual(count, 1)
    XCTAssertNotNil(store.report(for: city))
    await service.setFailing()
    await store.refresh(city, force: true)
    XCTAssertNotNil(store.report(for: city))
    XCTAssertNotNil(store.errors[city.id])
    XCTAssertTrue(store.loading.isEmpty)
    let restored = WeatherStore(defaults: defaults, arguments: [])
    XCTAssertNotNil(restored.report(for: city))
  }

  func testForecastUsesAbsoluteTimesAndRejectsIncompleteArrays() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let hours = (0..<24).map { now.timeIntervalSince1970 - 1800 + Double($0) * 3600 }
    var response = ForecastResponse(
      timezone: "Asia/Tokyo",
      current: .init(temperature2m: 18, weatherCode: 2, isDay: 0),
      daily: .init(
        time: (0..<7).map { now.timeIntervalSince1970 + Double($0) * 86400 },
        weatherCode: Array(repeating: 0, count: 7),
        temperature2mMax: Array(repeating: 22, count: 7),
        temperature2mMin: Array(repeating: 12, count: 7)),
      hourly: .init(
        time: hours, temperature2m: Array(repeating: 18, count: 24),
        weatherCode: Array(repeating: 2, count: 24),
        precipitationProbability: Array(repeating: nil, count: 24),
        isDay: Array(repeating: 0, count: 24))
    )
    let report = try response.report(now: now)
    XCTAssertEqual(report.daily.count, 6)
    XCTAssertEqual(report.hourly.count, 12)
    XCTAssertGreaterThan(report.hourly[0].date, now)
    XCTAssertEqual(report.hourly[0].precipitation, 0)
    XCTAssertFalse(report.isDay)
    XCTAssertEqual(
      WeatherDate.string(Date(timeIntervalSince1970: 0), format: "HH", timeZone: "Asia/Tokyo"), "09"
    )
    response.hourly.weatherCode.removeLast()
    XCTAssertThrowsError(try response.report(now: now))
  }

  func testDemoModeDoesNotFetchOrOverwriteRealCache() async {
    let service = StubWeatherService()
    let store = WeatherStore(defaults: defaults, service: service, arguments: [])
    let city = store.cities[0]
    await store.refresh(city)
    let live = store.reports[city.id]?.updatedAt
    store.demoMode = true
    await store.refresh(city, force: true)
    let count = await service.calls
    XCTAssertEqual(count, 1)
    XCTAssertEqual(store.reports[city.id]?.updatedAt, live)
  }

  func testDecodesCapturedOpenMeteoResponse() throws {
    let url = try XCTUnwrap(
      Bundle(for: Self.self).url(forResource: "open-meteo-forecast", withExtension: "json"))
    let data = try Data(contentsOf: url)
    let response = try JSONDecoder().decode(ForecastResponse.self, from: data)
    let report = try response.report(now: Date(timeIntervalSince1970: 1_791_464_400))
    XCTAssertEqual(report.timeZone, "America/Los_Angeles")
    XCTAssertEqual(report.daily.count, 6)
    XCTAssertEqual(report.hourly.count, 12)
    XCTAssertEqual(report.temperature, 14.8, accuracy: 0.01)
    XCTAssertFalse(report.isDay)
  }
}

private actor ZonedWeatherService: WeatherProviding {
  func forecast(for city: WeatherCity) async throws -> WeatherReport {
    var report = WeatherReport.demo(for: city)
    report.timeZone = "Asia/Shanghai"
    return report
  }

  func search(_ query: String) async throws -> [WeatherCity] { [] }
}

private actor StubWeatherService: WeatherProviding {
  var calls = 0
  var failing = false
  func setFailing() { failing = true }

  func forecast(for city: WeatherCity) async throws -> WeatherReport {
    calls += 1
    if failing { throw WeatherServiceError.unavailable }
    return .demo(for: city)
  }

  func search(_ query: String) async throws -> [WeatherCity] { [] }
}
