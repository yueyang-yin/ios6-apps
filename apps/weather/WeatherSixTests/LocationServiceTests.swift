import CoreLocation
import XCTest

@testable import WeatherSix

@MainActor
final class LocationServiceTests: XCTestCase {
  func testDeniedPermissionOffersSettingsWithoutRequestingGPS() async {
    let manager = FakeLocationManager(status: .denied)
    let service = LocationService(manager: manager, geocoder: FakeCityGeocoder())
    await service.request()
    XCTAssertFalse(service.isRequesting)
    XCTAssertTrue(service.showSettings)
    XCTAssertTrue(service.message?.contains(L10n.text("Open Settings")) == true)
    XCTAssertEqual(manager.locationRequests, 0)
  }

  func testDisabledServicesAndRestrictionsAreReportedSeparately() async {
    let manager = FakeLocationManager(status: .authorizedWhenInUse)
    manager.servicesEnabled = false
    let service = LocationService(manager: manager, geocoder: FakeCityGeocoder())
    await service.request()
    XCTAssertTrue(
      service.message
        == L10n.text("Location Services are off. Enable them in Settings to use local weather."))
    XCTAssertTrue(service.showSettings)
    manager.servicesEnabled = true
    manager.authorizationStatus = .restricted
    await service.request()
    XCTAssertTrue(
      service.message
        == L10n.text("Location access is restricted on this device. Add a city manually."))
    XCTAssertFalse(service.showSettings)
  }

  func testAuthorizationChangeStartsOnlyOneLocationRequest() async {
    let manager = FakeLocationManager(status: .notDetermined)
    let service = LocationService(manager: manager, geocoder: FakeCityGeocoder())
    await service.request()
    XCTAssertEqual(manager.authorizationRequests, 1)
    XCTAssertEqual(service.phase, .permission)
    manager.authorizationStatus = .authorizedWhenInUse
    service.authorizationChanged()
    service.authorizationChanged()
    XCTAssertEqual(manager.locationRequests, 1)
    XCTAssertEqual(service.phase, .locating)
    service.cancel()
  }

  func testTransientLocationErrorRetriesAndThenDeliversCity() async {
    let manager = FakeLocationManager(status: .authorizedWhenInUse)
    let service = LocationService(manager: manager, geocoder: FakeCityGeocoder())
    let delivered = expectation(description: "Local city delivered")
    service.onCity = { city in
      XCTAssertEqual(city.name, "London")
      XCTAssertEqual(city.id, "local")
      delivered.fulfill()
    }
    await service.request()
    service.receive(CLError(.locationUnknown))
    XCTAssertTrue(service.isRequesting)
    XCTAssertNil(service.message)
    try? await Task.sleep(for: .milliseconds(600))
    XCTAssertEqual(manager.locationRequests, 2)
    service.receive([CLLocation(latitude: 51.5085, longitude: -0.1257)])
    await fulfillment(of: [delivered], timeout: 1)
    XCTAssertFalse(service.isRequesting)
  }

  func testSlowGeocodingFallsBackToCoordinatesWithoutHanging() async {
    let manager = FakeLocationManager(status: .authorizedWhenInUse)
    let geocoder = FakeCityGeocoder()
    geocoder.delay = .seconds(3)
    let service = LocationService(
      manager: manager, geocoder: geocoder, geocodingTimeout: .milliseconds(20))
    let delivered = expectation(description: "Coordinates remain usable")
    service.onCity = { city in
      XCTAssertEqual(city.name, L10n.text("Local Weather"))
      XCTAssertEqual(city.latitude, 51.5085, accuracy: 0.001)
      XCTAssertTrue(city.isLocal)
      delivered.fulfill()
    }
    await service.request()
    service.receive([CLLocation(latitude: 51.5085, longitude: -0.1257)])
    await fulfillment(of: [delivered], timeout: 1)
    XCTAssertFalse(service.isRequesting)
    XCTAssertTrue(geocoder.cancelled)
  }

  func testGPSDeadlineStopsSpinnerAndAllowsRetry() async {
    let manager = FakeLocationManager(status: .authorizedWhenInUse)
    let service = LocationService(
      manager: manager, geocoder: FakeCityGeocoder(), locationTimeout: .milliseconds(20))
    await service.request()
    try? await Task.sleep(for: .milliseconds(60))
    XCTAssertFalse(service.isRequesting)
    XCTAssertNotNil(service.message)
    await service.request()
    XCTAssertTrue(service.isRequesting)
    XCTAssertEqual(manager.locationRequests, 2)
    service.cancel()
  }

  func testCancelledRequestDoesNotPublishLateGeocodingResult() async {
    let manager = FakeLocationManager(status: .authorizedWhenInUse)
    let geocoder = FakeCityGeocoder()
    geocoder.delay = .milliseconds(60)
    let service = LocationService(manager: manager, geocoder: geocoder)
    var count = 0
    service.onCity = { _ in count += 1 }
    await service.request()
    service.receive([CLLocation(latitude: 51.5085, longitude: -0.1257)])
    service.cancel()
    try? await Task.sleep(for: .milliseconds(100))
    XCTAssertEqual(count, 0)
    XCTAssertFalse(service.isRequesting)
  }

  func testInvalidFixDoesNotBecomeALocalCity() async {
    let manager = FakeLocationManager(status: .authorizedWhenInUse)
    let service = LocationService(manager: manager, geocoder: FakeCityGeocoder())
    await service.request()
    let stale = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1), altitude: 0,
      horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date(timeIntervalSinceNow: -300))
    service.receive([stale])
    XCTAssertEqual(service.phase, .locating)
    service.cancel()
  }
}

@MainActor
private final class FakeLocationManager: LocationManaging {
  var authorizationStatus: CLAuthorizationStatus
  var servicesEnabled = true
  weak var delegate: CLLocationManagerDelegate?
  var authorizationRequests = 0
  var locationRequests = 0
  init(status: CLAuthorizationStatus) { authorizationStatus = status }
  func requestWhenInUseAuthorization() { authorizationRequests += 1 }
  func locationServicesEnabled() async -> Bool { servicesEnabled }
  func requestLocation() { locationRequests += 1 }
  func stopUpdatingLocation() {}
}

@MainActor
private final class FakeCityGeocoder: CityReverseGeocoding {
  var delay = Duration.zero
  var cancelled = false
  func city(for location: CLLocation) async throws -> WeatherCity {
    if delay != .zero { try await Task.sleep(for: delay) }
    return .local(
      at: location, name: "London", country: "United Kingdom", timeZone: "Europe/London")
  }
  func cancel() { cancelled = true }
}
