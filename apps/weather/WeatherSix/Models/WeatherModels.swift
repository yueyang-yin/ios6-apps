import Foundation

struct WeatherCity: Codable, Identifiable, Hashable, Sendable {
  var id: String
  var name: String
  var country: String
  var latitude: Double
  var longitude: Double
  var timeZone: String
  var isLocal = false

  static let defaults: [WeatherCity] = [
    .init(
      id: "cupertino", name: "Cupertino", country: "California, US", latitude: 37.323,
      longitude: -122.0322, timeZone: "America/Los_Angeles"),
    .init(
      id: "london", name: "London", country: "United Kingdom", latitude: 51.5085,
      longitude: -0.1257, timeZone: "Europe/London"),
    .init(
      id: "beijing", name: "Beijing", country: "China", latitude: 39.9075, longitude: 116.3972,
      timeZone: "Asia/Shanghai"),
  ]
}

enum TemperatureUnit: String, Codable, CaseIterable {
  case fahrenheit, celsius

  var symbol: String { self == .celsius ? "°C" : "°F" }

  func value(_ celsius: Double) -> Int {
    Int((self == .celsius ? celsius : celsius * 9 / 5 + 32).rounded())
  }

  func formatted(_ celsius: Double) -> String { "\(value(celsius))°" }
}

enum WeatherCondition: String, Codable, CaseIterable, Sendable {
  case clear, partlyCloudy, cloudy, fog, rain, snow, thunderstorm

  init(code: Int) {
    switch code {
    case 0, 1: self = .clear
    case 2: self = .partlyCloudy
    case 3: self = .cloudy
    case 45, 48: self = .fog
    case 71, 73, 75, 77, 85, 86: self = .snow
    case 95, 96, 99: self = .thunderstorm
    default: self = .rain
    }
  }

  var description: String {
    switch self {
    case .clear: "Clear"
    case .partlyCloudy: "Partly cloudy"
    case .cloudy: "Cloudy"
    case .fog: "Fog"
    case .rain: "Rain"
    case .snow: "Snow"
    case .thunderstorm: "Thunderstorms"
    }
  }
}

struct DailyWeather: Codable, Identifiable, Sendable {
  var date: Date
  var condition: WeatherCondition
  var high: Double
  var low: Double
  var id: Date { date }
}

struct HourlyWeather: Codable, Identifiable, Sendable {
  var date: Date
  var temperature: Double
  var condition: WeatherCondition
  var precipitation: Int
  var isDay: Bool
  var id: Date { date }
}

struct WeatherReport: Codable, Sendable {
  var temperature: Double
  var condition: WeatherCondition
  var isDay: Bool
  var daily: [DailyWeather]
  var hourly: [HourlyWeather]
  var updatedAt: Date
  var timeZone: String

  static func demo(for city: WeatherCity) -> WeatherReport {
    let index = WeatherCity.defaults.firstIndex(where: { $0.id == city.id }) ?? 0
    let temperature = [23.0, 15.0, 18.0][index]
    let conditions: [WeatherCondition] =
      index == 0
      ? [.clear, .clear, .partlyCloudy, .clear, .partlyCloudy, .clear]
      : [.partlyCloudy, .rain, .cloudy, .partlyCloudy, .clear, .rain]
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: city.timeZone) ?? .gmt
    let now = Date()
    let midnight = calendar.startOfDay(for: now)
    let hour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
    return WeatherReport(
      temperature: temperature, condition: conditions[0], isDay: index != 2,
      daily: (0..<6).map { day in
        DailyWeather(
          date: calendar.date(byAdding: .day, value: day, to: midnight)!,
          condition: conditions[day], high: temperature + Double([2, 3, 1, 4, 5, 3][day]),
          low: temperature - Double([7, 8, 6, 7, 8, 6][day]))
      },
      hourly: (1...12).map { offset in
        let date = calendar.date(byAdding: .hour, value: offset, to: hour)!
        let localHour = calendar.component(.hour, from: date)
        let condition = conditions[offset % conditions.count]
        return HourlyWeather(
          date: date, temperature: temperature + sin(Double(offset) / 2) * 3, condition: condition,
          precipitation: condition == .rain ? 60 : 0, isDay: (7..<19).contains(localHour))
      },
      updatedAt: now, timeZone: city.timeZone
    )
  }
}

enum WeatherDate {
  static func string(_ date: Date, format: String, timeZone: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: timeZone) ?? .gmt
    formatter.dateFormat = format
    return formatter.string(from: date)
  }
}
