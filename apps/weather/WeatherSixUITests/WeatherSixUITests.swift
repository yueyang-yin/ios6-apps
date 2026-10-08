import CoreLocation
import XCTest

final class WeatherSixUITests: XCTestCase {
  @MainActor
  func testClassicWeatherCityAndTemperatureFlow() throws {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--demo"]
    app.launch()
    XCTAssertTrue(app.staticTexts["cityName_cupertino"].waitForExistence(timeout: 10))
    XCTAssertEqual(app.staticTexts["cityName_cupertino"].label, "Cupertino")
    XCTAssertEqual(app.staticTexts["currentTemperature_cupertino"].label, "23 degrees celsius")
    XCTAssertTrue(app.staticTexts["H: 25"].exists)
    XCTAssertTrue(app.staticTexts["L: 16"].exists)
    attachScreenshot("01-Daytime")

    app.buttons["Show London"].tap()
    XCTAssertEqual(app.staticTexts["cityName_london"].label, "London")
    app.buttons["Show Beijing"].tap()
    XCTAssertEqual(app.staticTexts["cityName_beijing"].label, "Beijing")
    attachScreenshot("02-Nighttime")

    app.buttons["manageCities_beijing"].tap()
    XCTAssertTrue(app.buttons["celsius"].waitForExistence(timeout: 5))
    app.buttons["fahrenheit"].tap()
    app.buttons["doneManaging"].tap()
    XCTAssertEqual(app.staticTexts["currentTemperature_beijing"].label, "64 degrees fahrenheit")
    app.buttons["manageCities_beijing"].tap()
    app.buttons["celsius"].tap()
    attachScreenshot("03-City-Manager")
    app.buttons["doneManaging"].tap()
    XCTAssertTrue(app.staticTexts["currentTemperature_beijing"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["currentTemperature_beijing"].label.contains("18"))

    app.buttons["manageCities_beijing"].tap()
    app.buttons["addCity"].tap()
    let search = app.textFields["citySearch"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("Tokyo")
    let result = app.buttons["searchResult_tokyo"]
    XCTAssertTrue(result.waitForExistence(timeout: 5))
    attachScreenshot("04-City-Search")
    result.tap()
    XCTAssertTrue(app.buttons["cityRow_tokyo"].waitForExistence(timeout: 5))
    app.buttons["doneManaging"].tap()
    XCTAssertEqual(app.staticTexts["cityName_tokyo"].label, "Tokyo")

    app.buttons["manageCities_tokyo"].tap()
    let delete = app.buttons["deleteCity_tokyo"]
    XCTAssertTrue(delete.waitForExistence(timeout: 5))
    delete.tap()
    let confirm = app.buttons["confirmDelete_tokyo"]
    XCTAssertTrue(confirm.waitForExistence(timeout: 5))
    confirm.tap()
    XCTAssertFalse(app.buttons["cityRow_tokyo"].exists)
    app.buttons["doneManaging"].tap()
    XCTAssertEqual(app.staticTexts["cityName_cupertino"].label, "Cupertino")
  }

  @MainActor
  func testCompactHourlyAndAboutFlow() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--demo"]
    app.launch()
    XCTAssertTrue(app.staticTexts["cityName_cupertino"].waitForExistence(timeout: 10))
    if app.frame.height < 700 {
      XCTAssertTrue(app.buttons["hourlyToggle"].exists)
    }
    if app.buttons["hourlyToggle"].exists {
      app.buttons["hourlyToggle"].tap()
      attachScreenshot("05-Compact-Hourly")
      app.buttons["hourlyToggle"].tap()
    }
    app.buttons["Weather sources and app information"].tap()
    XCTAssertTrue(app.staticTexts["Weather, circa 2012."].waitForExistence(timeout: 5))
    app.buttons["closeAbout"].tap()
    XCTAssertTrue(app.buttons["manageCities_cupertino"].waitForExistence(timeout: 5))
  }

  @MainActor
  func testAnimatedFlipThenAddCity() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--demo", "--animate-flips"]
    app.launch()
    XCTAssertTrue(app.buttons["manageCities_cupertino"].waitForExistence(timeout: 10))
    app.buttons["manageCities_cupertino"].tap()
    let add = app.buttons["addCity"]
    XCTAssertTrue(add.waitForExistence(timeout: 5))
    let ready = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in add.isEnabled }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
    add.tap()
    XCTAssertTrue(app.textFields["citySearch"].waitForExistence(timeout: 5))
    app.buttons["Cancel"].tap()
    app.buttons["doneManaging"].tap()
    let front = app.buttons["manageCities_cupertino"]
    XCTAssertTrue(front.waitForExistence(timeout: 5))
    let frontReady = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in front.isEnabled }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [frontReady], timeout: 5), .completed)
    XCTAssertTrue(front.isHittable)
  }

  @MainActor
  func testHeroArtworkNeverOverlapsHeaderAcrossWeatherConditions() {
    continueAfterFailure = false
    let conditions = ["clear", "partlyCloudy", "cloudy", "fog", "rain", "snow", "thunderstorm"]
    for condition in conditions {
      verifyHeroLayout(condition: condition)
    }
    for condition in ["clear", "partlyCloudy"] {
      verifyHeroLayout(condition: condition, night: true)
    }
  }

  @MainActor
  func testHeroArtworkKeepsNegativeAndThreeDigitTemperaturesClear() {
    continueAfterFailure = false
    verifyHeroLayout(condition: "cloudy", temperature: "-42", expected: "-42 degrees celsius")
    verifyHeroLayout(
      condition: "thunderstorm", temperature: "48", fahrenheit: true,
      expected: "118 degrees fahrenheit")
  }

  @MainActor
  private func verifyHeroLayout(
    condition: String, night: Bool = false, temperature: String = "23", fahrenheit: Bool = false,
    expected: String = "23 degrees celsius"
  ) {
    let app = XCUIApplication()
    app.launchArguments =
      [
        "--uitesting", "--demo", "--fixture-condition", condition, "--fixture-temperature",
        temperature,
      ] + (night ? ["--fixture-night"] : [])
    app.launch()
    let value = app.staticTexts["currentTemperature_cupertino"]
    XCTAssertTrue(value.waitForExistence(timeout: 10))
    if fahrenheit {
      app.buttons["manageCities_cupertino"].tap()
      app.buttons["fahrenheit"].tap()
      app.buttons["doneManaging"].tap()
    }
    XCTAssertEqual(value.label, expected)
    let artwork = app.descendants(matching: .any).matching(identifier: "heroArtwork_cupertino")
      .firstMatch
    XCTAssertTrue(artwork.exists)
    XCTAssertGreaterThan(artwork.frame.height, 0)
    XCTAssertGreaterThanOrEqual(value.frame.minY, artwork.frame.maxY + 7)
    XCTAssertFalse(artwork.frame.intersects(value.frame))
    XCTAssertFalse(artwork.frame.intersects(app.staticTexts["cityName_cupertino"].frame))
    XCTAssertTrue(app.buttons["manageCities_cupertino"].isHittable)
    XCTAssertTrue(app.buttons["Weather sources and app information"].isHittable)
    XCTAssertTrue(app.frame.contains(value.frame))
    XCTAssertTrue(app.frame.contains(artwork.frame))
    attachScreenshot("Hero-\(condition)-\(night ? "Night" : "Day")-\(temperature)")
    app.terminate()
  }

  @MainActor
  func testLiveDistrictSearchAndForecast() throws {
    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["WEATHER_SEARCH_TESTS"] == "1",
      "Live district search checks are opt-in.")
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()
    let manage = app.buttons["manageCities_cupertino"]
    XCTAssertTrue(manage.waitForExistence(timeout: 10))
    manage.tap()
    app.buttons["addCity"].tap()
    let search = app.textFields["citySearch"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("QuanShan")
    let district = app.buttons["searchResult_osm-R-3218567"]
    XCTAssertTrue(district.waitForExistence(timeout: 30))
    XCTAssertTrue(district.label.contains("Xuzhou, Jiangsu Province, China"))
    attachScreenshot("09-Quanshan-Search")
    district.tap()
    XCTAssertTrue(app.buttons["cityRow_osm-R-3218567"].waitForExistence(timeout: 5))
    app.buttons["doneManaging"].tap()
    XCTAssertEqual(app.staticTexts["cityName_osm-R-3218567"].label, "Quanshan")
    let temperature = app.staticTexts["currentTemperature_osm-R-3218567"]
    let loaded = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        temperature.exists && temperature.label.contains("degrees celsius")
      }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [loaded], timeout: 30), .completed)
    XCTAssertFalse(app.buttons["refreshWeather"].label.contains("Demo"))
    attachScreenshot("10-Quanshan-Live-Weather")
  }

  @MainActor
  func testLiveWeatherAndSearch() throws {
    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["WEATHER_LIVE_TESTS"] == "1",
      "Live API checks are opt-in.")
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()
    let temperature = app.staticTexts["currentTemperature_cupertino"]
    XCTAssertTrue(temperature.waitForExistence(timeout: 10))
    let forecast = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        temperature.exists && temperature.label.contains("degrees celsius")
      }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [forecast], timeout: 25), .completed)
    attachScreenshot("06-Live-Weather")
    app.buttons["manageCities_cupertino"].tap()
    app.buttons["addCity"].tap()
    let search = app.textFields["citySearch"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("Tokyo")
    let result = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'searchResult_'"))
      .firstMatch
    XCTAssertTrue(result.waitForExistence(timeout: 25))
    let cityID = result.identifier.replacingOccurrences(of: "searchResult_", with: "")
    result.tap()
    app.buttons["doneManaging"].tap()
    XCTAssertEqual(app.staticTexts["cityName_\(cityID)"].label, "Tokyo")
    let tokyo = app.staticTexts["currentTemperature_\(cityID)"]
    let tokyoForecast = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        tokyo.exists && tokyo.label.contains("degrees celsius")
      }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [tokyoForecast], timeout: 25), .completed)
  }

  @MainActor
  func testCurrentLocationPermissionAndForecast() throws {
    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["WEATHER_LOCATION_TESTS"] == "1",
      "Native location checks are opt-in.")
    continueAfterFailure = false
    let device = XCUIDevice.shared
    let previousLocation = device.location
    defer { device.location = previousLocation }
    device.location = XCUILocation(location: CLLocation(latitude: 51.5085, longitude: -0.1257))
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--demo"]
    app.resetAuthorizationStatus(for: .location)
    app.launch()
    XCTAssertTrue(app.buttons["manageCities_cupertino"].waitForExistence(timeout: 10))
    app.buttons["manageCities_cupertino"].tap()
    app.buttons["currentLocation"].tap()
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let firstAlert =
      app.alerts.firstMatch.waitForExistence(timeout: 3)
      ? app.alerts.firstMatch : springboard.alerts.firstMatch
    XCTAssertTrue(firstAlert.waitForExistence(timeout: 5))
    let deny = firstAlert.buttons.matching(
      NSPredicate(format: "label IN %@", ["Don't Allow", "Don’t Allow", "不允许"])
    ).firstMatch
    XCTAssertTrue(deny.exists, firstAlert.debugDescription)
    deny.tap()
    XCTAssertTrue(app.staticTexts["locationError"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["locationSettings"].exists)
    attachScreenshot("07-Location-Permission")
    app.buttons["locationSettings"].tap()
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 5))

    app.resetAuthorizationStatus(for: .location)
    app.launch()
    XCTAssertTrue(app.buttons["manageCities_cupertino"].waitForExistence(timeout: 10))
    app.buttons["manageCities_cupertino"].tap()
    app.buttons["currentLocation"].tap()
    let alert =
      app.alerts.firstMatch.waitForExistence(timeout: 3)
      ? app.alerts.firstMatch : springboard.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout: 5))
    let allow = alert.buttons.matching(
      NSPredicate(
        format: "label IN %@",
        [
          "Allow While Using App", "While Using the App", "使用App期间", "使用 App 期间", "允许使用App期间",
          "使用App时允许", "Allow Once", "允许一次",
        ])
    ).firstMatch
    XCTAssertTrue(allow.exists, alert.debugDescription)
    allow.tap()
    let temperature = app.staticTexts["currentTemperature_local"]
    XCTAssertTrue(temperature.waitForExistence(timeout: 30))
    let loaded = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        temperature.exists && temperature.label.contains("degrees celsius")
      }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [loaded], timeout: 25), .completed)
    XCTAssertFalse(app.buttons["refreshWeather"].label.contains("Demo"))
    attachScreenshot("08-Local-Weather")
  }

  @MainActor
  private func attachScreenshot(_ name: String) {
    let settled = expectation(description: "View transitions completed")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { settled.fulfill() }
    wait(for: [settled], timeout: 2)
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
