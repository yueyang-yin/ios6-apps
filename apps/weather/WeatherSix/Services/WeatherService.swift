import Foundation

protocol WeatherProviding: Sendable {
  func forecast(for city: WeatherCity) async throws -> WeatherReport
  func search(_ query: String) async throws -> [WeatherCity]
}

struct OpenMeteoService: WeatherProviding {
  var session: URLSession = .shared
  var placeSearch: PlaceSearchService = .shared

  func forecast(for city: WeatherCity) async throws -> WeatherReport {
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
    components.queryItems = [
      .init(name: "latitude", value: String(city.latitude)),
      .init(name: "longitude", value: String(city.longitude)),
      .init(name: "current", value: "temperature_2m,weather_code,is_day"),
      .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
      .init(name: "hourly", value: "temperature_2m,weather_code,precipitation_probability,is_day"),
      .init(name: "timezone", value: "auto"),
      .init(name: "temperature_unit", value: "celsius"),
      .init(name: "timeformat", value: "unixtime"),
      .init(name: "forecast_days", value: "7"),
    ]
    let response: ForecastResponse = try await fetch(components.url!)
    return try response.report(now: Date())
  }

  func search(_ query: String) async throws -> [WeatherCity] {
    try await placeSearch.search(query, session: session)
  }

  private func fetch<T: Decodable>(_ url: URL) async throws -> T {
    var request = URLRequest(url: url)
    request.timeoutInterval = 20
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw WeatherServiceError.unavailable
    }
    return try JSONDecoder().decode(T.self, from: data)
  }
}

enum WeatherServiceError: LocalizedError {
  case unavailable, incomplete

  var errorDescription: String? {
    switch self {
    case .unavailable: "Weather is unavailable. Check your connection and try again."
    case .incomplete: "The weather service returned an incomplete forecast."
    }
  }
}

struct ForecastResponse: Decodable {
  struct Current: Decodable {
    var temperature2m: Double
    var weatherCode: Int
    var isDay: Int

    enum CodingKeys: String, CodingKey {
      case temperature2m = "temperature_2m"
      case weatherCode = "weather_code"
      case isDay = "is_day"
    }
  }
  struct Daily: Decodable {
    var time: [Double]
    var weatherCode: [Int]
    var temperature2mMax: [Double]
    var temperature2mMin: [Double]

    enum CodingKeys: String, CodingKey {
      case time
      case weatherCode = "weather_code"
      case temperature2mMax = "temperature_2m_max"
      case temperature2mMin = "temperature_2m_min"
    }
  }
  struct Hourly: Decodable {
    var time: [Double]
    var temperature2m: [Double]
    var weatherCode: [Int]
    var precipitationProbability: [Int?]
    var isDay: [Int]

    enum CodingKeys: String, CodingKey {
      case time
      case temperature2m = "temperature_2m"
      case weatherCode = "weather_code"
      case precipitationProbability = "precipitation_probability"
      case isDay = "is_day"
    }
  }
  var timezone: String
  var current: Current
  var daily: Daily
  var hourly: Hourly

  func report(now: Date) throws -> WeatherReport {
    guard daily.time.count >= 6,
      daily.weatherCode.count == daily.time.count,
      daily.temperature2mMax.count == daily.time.count,
      daily.temperature2mMin.count == daily.time.count,
      hourly.temperature2m.count == hourly.time.count,
      hourly.weatherCode.count == hourly.time.count,
      hourly.precipitationProbability.count == hourly.time.count,
      hourly.isDay.count == hourly.time.count
    else {
      throw WeatherServiceError.incomplete
    }
    let hours = hourly.time.indices.filter { hourly.time[$0] >= now.timeIntervalSince1970 }.prefix(
      12)
    guard hours.count == 12 else { throw WeatherServiceError.incomplete }
    return WeatherReport(
      temperature: current.temperature2m,
      condition: WeatherCondition(code: current.weatherCode),
      isDay: current.isDay == 1,
      daily: daily.time.indices.prefix(6).map {
        DailyWeather(
          date: Date(timeIntervalSince1970: daily.time[$0]),
          condition: WeatherCondition(code: daily.weatherCode[$0]),
          high: daily.temperature2mMax[$0], low: daily.temperature2mMin[$0])
      },
      hourly: hours.map {
        HourlyWeather(
          date: Date(timeIntervalSince1970: hourly.time[$0]),
          temperature: hourly.temperature2m[$0],
          condition: WeatherCondition(code: hourly.weatherCode[$0]),
          precipitation: hourly.precipitationProbability[$0] ?? 0, isDay: hourly.isDay[$0] == 1)
      },
      updatedAt: now, timeZone: timezone
    )
  }
}

struct GeocodingResponse: Decodable {
  struct Result: Decodable {
    var id: Int
    var name: String
    var country: String?
    var admin1: String?
    var admin2: String?
    var admin3: String?
    var admin4: String?
    var featureCode: String?
    var latitude: Double
    var longitude: Double
    var timezone: String?

    enum CodingKeys: String, CodingKey {
      case id, name, country, admin1, admin2, admin3, admin4, latitude, longitude, timezone
      case featureCode = "feature_code"
    }
  }
  var results: [Result]?

  var cities: [WeatherCity] {
    (results ?? []).compactMap { result in
      guard result.latitude.isFinite, result.longitude.isFinite,
        (-90...90).contains(result.latitude), (-180...180).contains(result.longitude),
        result.featureCode == nil || result.featureCode?.hasPrefix("PPL") == true
          || result.featureCode?.hasPrefix("ADM") == true
      else { return nil }
      return WeatherCity(
        id: String(result.id), name: result.name,
        country: PlaceQuery.context(
          [result.admin4, result.admin3, result.admin2, result.admin1, result.country],
          excluding: result.name),
        latitude: result.latitude, longitude: result.longitude, timeZone: result.timezone ?? "GMT")
    }
  }
}
