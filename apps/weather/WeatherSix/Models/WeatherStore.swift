import Foundation
import Observation

@MainActor @Observable
final class WeatherStore {
  var cities: [WeatherCity]
  var selectedCityID: String
  var unit: TemperatureUnit { didSet { save() } }
  var demoMode: Bool { didSet { save() } }
  var reports: [String: WeatherReport] = [:]
  var loading: Set<String> = []
  var errors: [String: String] = [:]
  let service: any WeatherProviding
  private let defaults: UserDefaults
  private let isolated: Bool
  private let fixtureArguments: [String]
  private var refreshIDs: [String: UUID] = [:]

  init(
    defaults: UserDefaults = .standard, service: any WeatherProviding = OpenMeteoService(),
    arguments: [String] = ProcessInfo.processInfo.arguments
  ) {
    self.defaults = defaults
    self.service = service
    isolated = arguments.contains("--uitesting")
    fixtureArguments = isolated ? arguments : []
    let saved = defaults.data(forKey: "cities").flatMap {
      try? JSONDecoder().decode([WeatherCity].self, from: $0)
    }
    let initialCities = isolated ? WeatherCity.defaults : (saved ?? WeatherCity.defaults)
    cities = initialCities
    selectedCityID = initialCities.first?.id ?? ""
    let migrateTemperatureUnit = !isolated && defaults.integer(forKey: "temperatureUnitVersion") < 1
    unit =
      isolated || migrateTemperatureUnit
      ? .celsius
      : TemperatureUnit(rawValue: defaults.string(forKey: "unit") ?? "") ?? .celsius
    if migrateTemperatureUnit {
      defaults.set(TemperatureUnit.celsius.rawValue, forKey: "unit")
      defaults.set(1, forKey: "temperatureUnitVersion")
    }
    demoMode = arguments.contains("--demo") || (!isolated && defaults.bool(forKey: "demoMode"))
    if !isolated, let cache = defaults.data(forKey: "reports"),
      let decoded = try? JSONDecoder().decode([String: WeatherReport].self, from: cache)
    {
      reports = decoded
    }
  }

  var selectedCity: WeatherCity? { cities.first { $0.id == selectedCityID } ?? cities.first }

  func report(for city: WeatherCity) -> WeatherReport? {
    guard demoMode else { return reports[city.id] }
    var report = WeatherReport.demo(for: city)
    #if DEBUG
      if let index = fixtureArguments.firstIndex(of: "--fixture-condition"),
        fixtureArguments.indices.contains(index + 1),
        let condition = WeatherCondition(rawValue: fixtureArguments[index + 1])
      {
        report.condition = condition
      }
      if fixtureArguments.contains("--fixture-night") { report.isDay = false }
      if let index = fixtureArguments.firstIndex(of: "--fixture-temperature"),
        fixtureArguments.indices.contains(index + 1),
        let temperature = Double(fixtureArguments[index + 1]), temperature.isFinite
      {
        report.temperature = temperature
      }
    #endif
    return report
  }

  func refresh(_ city: WeatherCity, force: Bool = false) async {
    guard !demoMode, !loading.contains(city.id) else { return }
    if !force, let report = reports[city.id], Date().timeIntervalSince(report.updatedAt) < 600 {
      return
    }
    loading.insert(city.id)
    let requestID = UUID()
    refreshIDs[city.id] = requestID
    errors[city.id] = nil
    defer {
      if refreshIDs[city.id] == requestID {
        loading.remove(city.id)
        refreshIDs[city.id] = nil
      }
    }
    do {
      let report = try await service.forecast(for: city)
      guard !Task.isCancelled, refreshIDs[city.id] == requestID, cities.contains(city) else {
        return
      }
      reports[city.id] = report
      if let index = cities.firstIndex(where: { $0.id == city.id }) {
        cities[index].timeZone = report.timeZone
      }
      save()
    } catch {
      guard !Task.isCancelled, refreshIDs[city.id] == requestID else { return }
      errors[city.id] = error.localizedDescription
    }
  }

  func add(_ city: WeatherCity) {
    if let index = cities.firstIndex(where: {
      $0.id == city.id
        || ($0.name.localizedCaseInsensitiveCompare(city.name) == .orderedSame
          && abs($0.latitude - city.latitude) < 0.02 && abs($0.longitude - city.longitude) < 0.02)
    }) {
      cities[index].country = city.country
      if city.timeZone != "GMT" { cities[index].timeZone = city.timeZone }
      selectedCityID = cities[index].id
      save()
      return
    }
    cities.append(city)
    selectedCityID = city.id
    save()
  }

  func setLocal(_ city: WeatherCity) {
    demoMode = false
    cities.removeAll { $0.isLocal }
    reports[city.id] = nil
    errors[city.id] = nil
    refreshIDs[city.id] = nil
    loading.remove(city.id)
    cities.insert(city, at: 0)
    selectedCityID = city.id
    save()
  }

  func remove(_ city: WeatherCity) {
    cities.removeAll { $0.id == city.id }
    reports[city.id] = nil
    errors[city.id] = nil
    if selectedCityID == city.id { selectedCityID = cities.first?.id ?? "" }
    save()
  }

  func move(_ source: IndexSet, to destination: Int) {
    let moving = source.sorted().map { cities[$0] }
    for index in source.sorted().reversed() { cities.remove(at: index) }
    let adjusted = destination - source.filter { $0 < destination }.count
    cities.insert(contentsOf: moving, at: max(0, min(adjusted, cities.count)))
    if let localIndex = cities.firstIndex(where: \.isLocal), localIndex != 0 {
      let local = cities.remove(at: localIndex)
      cities.insert(local, at: 0)
    }
    save()
  }

  private func save() {
    guard !isolated else { return }
    defaults.set(try? JSONEncoder().encode(cities), forKey: "cities")
    defaults.set(try? JSONEncoder().encode(reports), forKey: "reports")
    defaults.set(unit.rawValue, forKey: "unit")
    defaults.set(demoMode, forKey: "demoMode")
  }
}
