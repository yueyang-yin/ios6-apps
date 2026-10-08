import CoreLocation
import Observation

@MainActor
protocol LocationManaging: AnyObject {
  var authorizationStatus: CLAuthorizationStatus { get }
  func locationServicesEnabled() async -> Bool
  var delegate: CLLocationManagerDelegate? { get set }
  func requestWhenInUseAuthorization()
  func requestLocation()
  func stopUpdatingLocation()
}

extension CLLocationManager: LocationManaging {
  func locationServicesEnabled() async -> Bool {
    await Task.detached { CLLocationManager.locationServicesEnabled() }.value
  }
}

@MainActor @Observable
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
  enum Phase { case idle, checking, permission, locating, resolving }

  private(set) var phase = Phase.idle
  private(set) var message: String?
  private(set) var showSettings = false
  var onCity: ((WeatherCity) -> Void)?
  var isRequesting: Bool { phase != .idle }
  private let manager: any LocationManaging
  private let geocoder: any CityReverseGeocoding
  private let locationTimeout: Duration
  private let geocodingTimeout: Duration
  private var deadlineTask: Task<Void, Never>?
  private var retryTask: Task<Void, Never>?
  private var geocodingTask: Task<Void, Never>?
  private var requestID: UUID?

  init(
    manager: (any LocationManaging)? = nil,
    geocoder: (any CityReverseGeocoding)? = nil,
    locationTimeout: Duration = .seconds(20), geocodingTimeout: Duration = .seconds(5)
  ) {
    let manager = manager ?? CLLocationManager()
    self.manager = manager
    self.geocoder = geocoder ?? AppleCityGeocoder()
    self.locationTimeout = locationTimeout
    self.geocodingTimeout = geocodingTimeout
    super.init()
    if let manager = manager as? CLLocationManager {
      manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    manager.delegate = self
  }

  func request() async {
    guard !isRequesting else { return }
    message = nil
    showSettings = false
    let id = UUID()
    requestID = id
    phase = .checking
    scheduleDeadline(.seconds(60)) {
      self.fail("Location permission wasn't received. Try again or add a city manually.")
    }
    let enabled = await manager.locationServicesEnabled()
    guard !Task.isCancelled, requestID == id else { return }
    guard enabled else {
      fail(
        "Location Services are off. Enable them in Settings to use local weather.", settings: true)
      return
    }
    switch manager.authorizationStatus {
    case .notDetermined:
      phase = .permission
      manager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse: locate()
    case .denied: permissionDenied()
    case .restricted: fail("Location access is restricted on this device. Add a city manually.")
    @unknown default: fail("Location is unavailable. Add a city manually.")
    }
  }

  func cancel() {
    requestID = nil
    phase = .idle
    deadlineTask?.cancel()
    retryTask?.cancel()
    geocodingTask?.cancel()
    manager.stopUpdatingLocation()
    geocoder.cancel()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationChanged()
  }

  func authorizationChanged() {
    guard isRequesting else { return }
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      if phase == .permission { locate() }
    case .denied: permissionDenied()
    case .restricted: fail("Location access is restricted on this device. Add a city manually.")
    default: break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    receive(locations)
  }

  func receive(_ locations: [CLLocation]) {
    guard phase == .locating,
      let location = locations.last(where: {
        $0.horizontalAccuracy >= 0 && CLLocationCoordinate2DIsValid($0.coordinate)
          && abs($0.timestamp.timeIntervalSinceNow) < 120
      }), let id = requestID
    else { return }
    manager.stopUpdatingLocation()
    retryTask?.cancel()
    phase = .resolving
    let fallback = WeatherCity.local(at: location)
    scheduleDeadline(geocodingTimeout) { self.finish(fallback) }
    geocodingTask = Task {
      let city = (try? await geocoder.city(for: location)) ?? fallback
      guard !Task.isCancelled, requestID == id, phase == .resolving else { return }
      finish(city)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    receive(error)
  }

  func receive(_ error: Error) {
    guard isRequesting else { return }
    if let error = error as? CLError {
      if error.code == .denied {
        permissionDenied()
        return
      }
      if error.code == .locationUnknown, phase == .locating {
        let id = requestID
        retryTask?.cancel()
        retryTask = Task {
          try? await Task.sleep(for: .milliseconds(500))
          guard !Task.isCancelled, requestID == id, phase == .locating else { return }
          manager.requestLocation()
        }
        return
      }
    }
    fail("Couldn't find your location. Check Location Services and try again.")
  }

  private func locate() {
    phase = .locating
    scheduleDeadline(locationTimeout) {
      #if targetEnvironment(simulator)
        self.fail(
          "No location was received. In Simulator, choose Features → Location → a location, then try again."
        )
      #else
        self.fail("Location timed out. Try again outdoors or add a city manually.")
      #endif
    }
    manager.requestLocation()
  }

  private func scheduleDeadline(_ duration: Duration, action: @escaping @MainActor () -> Void) {
    deadlineTask?.cancel()
    let id = requestID
    deadlineTask = Task {
      do { try await Task.sleep(for: duration) } catch { return }
      guard requestID == id, isRequesting else { return }
      action()
    }
  }

  private func finish(_ city: WeatherCity) {
    cancel()
    message = nil
    showSettings = false
    onCity?(city)
  }

  private func permissionDenied() {
    fail(
      "Location access is off for Weather. Open Settings and allow access while using the app.",
      settings: true)
  }

  private func fail(_ text: String, settings: Bool = false) {
    cancel()
    message = text
    showSettings = settings
  }
}

extension WeatherCity {
  static func local(
    at location: CLLocation, name: String = "Local Weather", country: String = "Current location",
    timeZone: String = TimeZone.current.identifier
  ) -> WeatherCity {
    WeatherCity(
      id: "local", name: name, country: country, latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude, timeZone: timeZone, isLocal: true)
  }
}
