import Foundation

actor PlaceSearchService {
  static let shared = PlaceSearchService()

  private struct CacheEntry {
    var cities: [WeatherCity]
    var expires: Date
  }

  private var cache: [String: CacheEntry] = [:]
  private let clock = ContinuousClock()
  private var nextRequest = ContinuousClock.now
  private let minimumInterval: Duration

  init(minimumInterval: Duration = .seconds(1)) {
    self.minimumInterval = minimumInterval
  }

  func search(_ query: String, session: URLSession = .shared) async throws -> [WeatherCity] {
    let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard value.count >= 2 else { return [] }
    let key = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    try Task.checkCancellation()
    if let entry = cache[key], entry.expires > Date() { return entry.cities }

    do {
      let response: PlaceSearchResponse = try await fetch(
        Self.request(for: value), session: session)
      let cities = response.cities(for: value)
      if !cities.isEmpty {
        remember(cities, key: key, lifetime: 900)
        return cities
      }
    } catch {
      try Task.checkCancellation()
    }

    // Retain the original provider when the broader place index is unavailable or incomplete.
    let response: GeocodingResponse = try await fetch(
      Self.fallbackRequest(for: value), session: session)
    let cities = response.cities
    if !cities.isEmpty { remember(cities, key: key, lifetime: 60) }
    return cities
  }

  private func fetch<T: Decodable>(_ request: URLRequest, session: URLSession) async throws -> T {
    while clock.now < nextRequest {
      try await clock.sleep(until: nextRequest)
    }
    try Task.checkCancellation()
    nextRequest = clock.now.advanced(by: minimumInterval)
    let (data, response) = try await session.data(for: request)
    try Task.checkCancellation()
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw WeatherServiceError.unavailable
    }
    return try JSONDecoder().decode(T.self, from: data)
  }

  private func remember(_ cities: [WeatherCity], key: String, lifetime: TimeInterval) {
    cache = cache.filter { $0.value.expires > Date() }
    if cache.count >= 50, let oldest = cache.min(by: { $0.value.expires < $1.value.expires }) {
      cache.removeValue(forKey: oldest.key)
    }
    cache[key] = CacheEntry(cities: cities, expires: Date().addingTimeInterval(lifetime))
  }

  static func request(for query: String) -> URLRequest {
    let postal = PlaceQuery.isPostalCode(query)
    var components = URLComponents(
      string: "https://photon.komoot.io/\(postal ? "structured" : "api/")")!
    components.queryItems = [
      .init(name: postal ? "postcode" : "q", value: PlaceQuery.normalized(query)),
      .init(name: "limit", value: "30"),
      .init(name: "lang", value: PlaceQuery.containsHan(query) ? "default" : "en"),
    ]
    if !postal {
      components.queryItems! += ["city", "district", "county", "locality", "state"].map {
        .init(name: "layer", value: $0)
      }
    }
    var request = URLRequest(url: components.url!)
    request.timeoutInterval = 12
    request.setValue("WeatherSix/1.0 (iOS weather place search)", forHTTPHeaderField: "User-Agent")
    return request
  }

  private static func fallbackRequest(for query: String) -> URLRequest {
    var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
    components.queryItems = [
      .init(name: "name", value: query), .init(name: "count", value: "50"),
      .init(name: "language", value: PlaceQuery.containsHan(query) ? "zh" : "en"),
      .init(name: "format", value: "json"),
    ]
    var request = URLRequest(url: components.url!)
    request.timeoutInterval = 12
    return request
  }
}

enum PlaceQuery {
  static func containsHan(_ value: String) -> Bool {
    value.range(of: "\\p{Han}", options: .regularExpression) != nil
  }

  static func normalized(_ value: String) -> String {
    // Separate adjoining Chinese administrative names without a hard-coded city catalog.
    value.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(
        of: "(?<=\\p{Han}{2}[省市区县旗镇乡])(?=\\p{Han}{2})", with: " ",
        options: .regularExpression)
  }

  static func isPostalCode(_ value: String) -> Bool {
    let compact = value.filter { !$0.isWhitespace && $0 != "-" }.uppercased()
    guard (3...10).contains(compact.count),
      compact.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) })
    else { return false }
    if compact.allSatisfy(\.isNumber) { return true }
    return compact.range(
      of:
        "^(?:[A-Z]{1,2}[0-9][A-Z0-9]?(?:[0-9][A-Z]{2})?|[A-Z][0-9][A-Z][0-9][A-Z][0-9]|[0-9]{4}[A-Z]{2}|[A-Z][0-9]{2}[A-Z0-9]{4})$",
      options: .regularExpression) != nil
  }

  static func context(_ parts: [String?], excluding name: String) -> String {
    var seen = Set([name.lowercased()])
    return parts.compactMap { part in
      guard let value = part?.trimmingCharacters(in: .whitespacesAndNewlines),
        !value.isEmpty, seen.insert(value.lowercased()).inserted
      else { return nil }
      return value
    }.joined(separator: ", ")
  }
}

struct PlaceSearchResponse: Decodable {
  struct Feature: Decodable {
    struct Geometry: Decodable {
      var type: String
      var coordinates: [Double]
    }
    struct Properties: Decodable {
      var osmType: String?
      var osmID: Int64?
      var osmKey: String?
      var type: String?
      var name: String?
      var district: String?
      var city: String?
      var county: String?
      var state: String?
      var country: String?
      var postcode: String?

      enum CodingKeys: String, CodingKey {
        case osmType = "osm_type"
        case osmID = "osm_id"
        case osmKey = "osm_key"
        case type, name, district, city, county, state, country, postcode
      }
    }
    var geometry: Geometry
    var properties: Properties
  }
  var features: [Feature]

  func cities(for query: String) -> [WeatherCity] {
    let postal = PlaceQuery.isPostalCode(query)
    var seen = Set<String>()
    return features.compactMap { feature in
      let p = feature.properties
      guard feature.geometry.type == "Point", feature.geometry.coordinates.count >= 2,
        ["place", "boundary"].contains(p.osmKey ?? ""),
        postal || ["city", "district", "county", "locality", "state"].contains(p.type ?? ""),
        let sourceName = p.name?.trimmingCharacters(in: .whitespacesAndNewlines),
        !sourceName.isEmpty
      else { return nil }
      if postal {
        let requested = query.filter { $0.isLetter || $0.isNumber }.lowercased()
        let returned = (p.postcode ?? sourceName).filter { $0.isLetter || $0.isNumber }.lowercased()
        guard returned == requested else { return nil }
      }
      let longitude = feature.geometry.coordinates[0]
      let latitude = feature.geometry.coordinates[1]
      guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude),
        (-180...180).contains(longitude)
      else { return nil }
      let name = postal ? (p.city ?? p.county ?? sourceName) : sourceName
      let context = PlaceQuery.context(
        [postal ? sourceName : nil, p.district, p.city, p.county, p.state, p.country],
        excluding: name)
      let id =
        p.osmID.map { "osm-\(p.osmType ?? "N")-\($0)" }
        ?? "place-\(latitude)-\(longitude)-\(name)"
      let identity = "\(name.lowercased())|\(context.lowercased())"
      guard seen.insert(identity).inserted else { return nil }
      return WeatherCity(
        id: id, name: name, country: context, latitude: latitude, longitude: longitude,
        timeZone: "GMT")
    }
  }
}
