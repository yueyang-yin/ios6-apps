import CoreLocation
import MapKit

@MainActor
protocol CityReverseGeocoding: AnyObject {
  func city(for location: CLLocation) async throws -> WeatherCity
  func cancel()
}

@MainActor
final class AppleCityGeocoder: CityReverseGeocoding {
  private var cancelRequest: (() -> Void)?

  func city(for location: CLLocation) async throws -> WeatherCity {
    if #available(iOS 26.0, *) {
      guard let request = MKReverseGeocodingRequest(location: location) else {
        return .local(at: location)
      }
      request.preferredLocale = AppLanguage.current.locale
      cancelRequest = { request.cancel() }
      defer { cancelRequest = nil }
      let item = try await request.mapItems.first
      return .local(
        at: location, name: item?.addressRepresentations?.cityName,
        country: item?.addressRepresentations?.regionName,
        timeZone: item?.timeZone?.identifier ?? TimeZone.current.identifier)
    } else {
      let geocoder = CLGeocoder()
      cancelRequest = { geocoder.cancelGeocode() }
      defer { cancelRequest = nil }
      let placemark = try await geocoder.reverseGeocodeLocation(
        location, preferredLocale: AppLanguage.current.locale
      ).first
      return .local(
        at: location, name: placemark?.locality,
        country: placemark?.country,
        timeZone: placemark?.timeZone?.identifier ?? TimeZone.current.identifier)
    }
  }

  func cancel() {
    cancelRequest?()
    cancelRequest = nil
  }
}
