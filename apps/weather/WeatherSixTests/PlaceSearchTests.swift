import Foundation
import XCTest

@testable import WeatherSix

@MainActor
final class PlaceSearchTests: XCTestCase {
  func testChineseDistrictKeepsCityProvinceAndCoordinates() throws {
    let response = try decode("photon-quanshan-chinese")
    let city = try XCTUnwrap(response.cities(for: "泉山区").first)
    XCTAssertEqual(city.name, "泉山区")
    XCTAssertEqual(city.country, "徐州市, 江苏省, 中国")
    XCTAssertEqual(city.id, "osm-R-3218567")
    XCTAssertEqual(city.latitude, 34.2273368, accuracy: 0.000001)
    XCTAssertEqual(city.longitude, 117.1884578, accuracy: 0.000001)
  }

  func testPinyinFindsDistrictBeforeOtherSameNamedPlaces() throws {
    let cities = try decode("photon-quanshan-pinyin").cities(for: "QuanShan")
    XCTAssertEqual(cities.first?.name, "Quanshan")
    XCTAssertEqual(cities.first?.country, "Xuzhou, Jiangsu Province, China")
    XCTAssertTrue(cities.contains { $0.country == "Minqin County, Gansu Province, China" })
  }

  func testFiltersNonPlaceFeaturesAndDuplicateAdministrativeResults() throws {
    let cities = try decode("photon-baiyun").cities(for: "Baiyun Guangzhou")
    XCTAssertEqual(cities.filter { $0.name == "Baiyun" }.count, 1)
    XCTAssertEqual(cities.first?.country, "Guangzhou, Guangdong Province, China")
    XCTAssertFalse(cities.contains { $0.country.isEmpty })
  }

  func testPostalSearchResolvesCityAndRejectsUnrelatedFuzzyMatches() throws {
    let response = try decode("photon-uk-postcode")
    let city = try XCTUnwrap(response.cities(for: "GU1 4TY").first)
    XCTAssertEqual(city.name, "Guildford")
    XCTAssertEqual(city.country, "GU1 4TY, Surrey, England, United Kingdom")
    XCTAssertTrue(response.cities(for: "GU2 7XH").isEmpty)
  }

  func testQueryNormalizationPreservesDistrictNamesAndUsesCorrectEndpoint() {
    XCTAssertEqual(PlaceQuery.normalized("徐州市泉山区"), "徐州市 泉山区")
    XCTAssertEqual(PlaceQuery.normalized("江苏省徐州市泉山区"), "江苏省 徐州市 泉山区")
    XCTAssertEqual(PlaceQuery.normalized("市中区"), "市中区")
    XCTAssertEqual(PlaceQuery.normalized("新市区"), "新市区")
    let request = PlaceSearchService.request(for: "徐州市泉山区")
    let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
    XCTAssertEqual(items.first { $0.name == "q" }?.value, "徐州市 泉山区")
    XCTAssertEqual(items.first { $0.name == "lang" }?.value, "default")
    XCTAssertEqual(PlaceSearchService.request(for: "GU1 4TY").url?.path, "/structured")
    XCTAssertEqual(PlaceSearchService.request(for: "QuanShan").url?.path, "/api")
    XCTAssertFalse(PlaceQuery.isPostalCode("Paris 8"))
  }

  func testFallbackShowsAllAdministrativeLevelsAndOmitsAirports() throws {
    let data = Data(
      """
      {"results":[
        {"id":1,"name":"Quanshan","admin1":"Zhejiang","admin2":"Lishui Shi",
        "country":"China","latitude":27.52518,"longitude":119.0569,"feature_code":"PPL"},
        {"id":2,"name":"Xuzhou","admin1":"Jiangsu","admin2":"Xuzhou",
        "country":"China","latitude":34.20442,"longitude":117.28386,"feature_code":"PPLA2"},
        {"id":3,"name":"Airport","latitude":34.2,"longitude":117.2,"feature_code":"AIRP"}
      ]}
      """.utf8)
    let cities = try JSONDecoder().decode(GeocodingResponse.self, from: data).cities
    XCTAssertEqual(cities.count, 2)
    XCTAssertEqual(cities[0].country, "Lishui Shi, Zhejiang, China")
    XCTAssertEqual(cities[1].country, "Jiangsu, China")
  }

  func testSearchCachesSuccessfulResponsesAndFallsBackAfterFailure() async throws {
    let photon = try fixture("photon-quanshan-chinese")
    let session = makeSession(photon: photon)
    defer { session.invalidateAndCancel() }
    let service = PlaceSearchService(minimumInterval: .zero)
    _ = try await service.search("泉山区", session: session)
    _ = try await service.search("泉山区", session: session)
    XCTAssertEqual(PlaceSearchURLProtocol.requestCount, 2)

    let failed = makeSession(photon: photon, photonStatus: 503)
    defer { failed.invalidateAndCancel() }
    let fallback = PlaceSearchService(minimumInterval: .zero)
    let cities = try await fallback.search("Quanshan", session: failed)
    XCTAssertEqual(cities.first?.country, "Lishui Shi, Zhejiang, China")
    XCTAssertEqual(PlaceSearchURLProtocol.requestCount, 3)
  }

  func testInvalidCoordinatesAreNotOfferedAndCancellationDoesNotUseFallback() async throws {
    var response = try decode("photon-quanshan-chinese")
    response.features[0].geometry.coordinates = [200, 95]
    XCTAssertTrue(response.cities(for: "泉山区").isEmpty)
    response.features[0].geometry.coordinates = [117]
    XCTAssertTrue(response.cities(for: "泉山区").isEmpty)
    let session = makeSession(photon: try fixture("photon-quanshan-chinese"))
    defer { session.invalidateAndCancel() }
    let service = PlaceSearchService(minimumInterval: .zero)
    let task = Task { try await service.search("泉山区", session: session) }
    task.cancel()
    do {
      _ = try await task.value
      XCTFail("Cancelled searches must not publish results.")
    } catch is CancellationError {
      XCTAssertEqual(PlaceSearchURLProtocol.requestCount, 0)
    }
  }

  func testResultCacheSeparatesLanguagesForTheSamePostalQuery() async throws {
    let session = makeSession(photon: try fixture("photon-uk-postcode"))
    defer { session.invalidateAndCancel() }
    let service = PlaceSearchService(minimumInterval: .zero)
    let english = try await service.search("GU1 4TY", session: session, language: .english)
    let chinese = try await service.search("GU1 4TY", session: session, language: .chinese)
    XCTAssertEqual(english.first?.name, "Guildford")
    XCTAssertEqual(chinese.first?.name, "吉尔福德")
    XCTAssertTrue(chinese.first?.country.contains("英国") == true)
    XCTAssertEqual(english.first?.id, chinese.first?.id)
    XCTAssertEqual(english.first?.latitude, chinese.first?.latitude)
    XCTAssertEqual(PlaceSearchURLProtocol.requestCount, 4)
    _ = try await service.search("GU1 4TY", session: session, language: .english)
    _ = try await service.search("GU1 4TY", session: session, language: .chinese)
    XCTAssertEqual(PlaceSearchURLProtocol.requestCount, 4)
    XCTAssertEqual(chinese.first?.displayName(language: .english), "Guildford")
  }

  func testLiveChineseDistrictSearchAndForecast() async throws {
    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["WEATHER_SEARCH_TESTS"] == "1",
      "Live place search checks are opt-in.")
    let service = OpenMeteoService(placeSearch: PlaceSearchService())
    for query in ["泉山区", "徐州市泉山区", "QuanShan"] {
      let cities = try await service.search(query)
      let city = try XCTUnwrap(cities.first { $0.id == "osm-R-3218567" })
      XCTAssertEqual(city.displayName(language: .chinese), "泉山区")
      XCTAssertEqual(city.displayName(language: .english), "Quanshan")
      XCTAssertTrue(city.displayCountry(language: .chinese).contains("徐州市"))
      XCTAssertTrue(city.displayCountry(language: .english).contains("Jiangsu"))
      XCTAssertTrue(city.country.contains(query == "QuanShan" ? "Jiangsu" : "江苏省"))
      XCTAssertTrue(city.country.contains(query == "QuanShan" ? "Xuzhou" : "徐州市"))
      XCTAssertEqual(city.latitude, 34.2273368, accuracy: 0.01)
      XCTAssertEqual(city.longitude, 117.1884578, accuracy: 0.01)
      if query == "泉山区" {
        let report = try await service.forecast(for: city)
        XCTAssertEqual(report.timeZone, "Asia/Shanghai")
        XCTAssertEqual(report.daily.count, 6)
        XCTAssertEqual(report.hourly.count, 12)
        XCTAssertTrue(report.temperature.isFinite)
      }
    }
    let postal = try await service.search("GU1 4TY")
    XCTAssertEqual(postal.first?.name, "Guildford")
    XCTAssertTrue(postal.first?.country.contains("United Kingdom") == true)
  }

  private func decode(_ name: String) throws -> PlaceSearchResponse {
    try JSONDecoder().decode(PlaceSearchResponse.self, from: fixture(name))
  }

  private func fixture(_ name: String) throws -> Data {
    let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json"))
    return try Data(contentsOf: url)
  }

  private func makeSession(photon: Data, photonStatus: Int = 200) -> URLSession {
    PlaceSearchURLProtocol.configure(photon: photon, status: photonStatus)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [PlaceSearchURLProtocol.self]
    return URLSession(configuration: configuration)
  }
}

private final class PlaceSearchURLProtocol: URLProtocol, @unchecked Sendable {
  private static let lock = NSLock()
  private nonisolated(unsafe) static var photon = Data()
  private nonisolated(unsafe) static var status = 200
  private nonisolated(unsafe) static var count = 0

  static var requestCount: Int { lock.withLock { count } }

  static func configure(photon: Data, status: Int) {
    lock.withLock {
      self.photon = photon
      self.status = status
      count = 0
    }
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    let (data, code) = Self.lock.withLock {
      Self.count += 1
      if request.url?.host == "photon.komoot.io" { return (Self.photon, Self.status) }
      return (
        Data(
          """
          {"results":[{"id":1,"name":"Quanshan","admin1":"Zhejiang","admin2":"Lishui Shi",
          "country":"China","latitude":27.52518,"longitude":119.0569,"feature_code":"PPL"}]}
          """.utf8), 200
      )
    }
    let response = HTTPURLResponse(
      url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
