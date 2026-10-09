# Weather Six

A native SwiftUI weather app in the iOS 6 Apps collection, recreating the skeuomorphic appearance of iOS 6 Weather. Requires **iOS 17 or later** and has no third-party Swift package dependencies.

Use matching patterns from the collection's [shared design language](../../docs/design-language.md) on applicable detail, management, or settings screens. Weather's city-management screen supplies the dark linen, independent glossy navigation, and classic control references. The main forecast keeps its original glass, weather artwork, and paging layout; it does not use the Notes/settings frame.

## Run

1. Open the collection's `iOS6Apps.xcworkspace` in Xcode, or open `WeatherSix.xcodeproj` in this directory.
2. Select the `WeatherSix` scheme and an iPhone simulator, then run.
3. For a physical device, select your development team in Signing & Capabilities and change the bundle identifier as needed.

The app defaults to Celsius and live weather, with no API key required. Existing Fahrenheit preferences migrate to Celsius once; later manual unit selections remain saved. The icon's example temperature has changed from `73°` to the equivalent rounded `23°`. Tap the information button to manage cities, change units, request local weather, or enable Demo Weather. Demo mode is explicitly identified in the panel footer.

Add `--demo` under Edit Scheme → Run → Arguments to launch in demo mode. Demo cities include Cupertino, London, and Beijing, with Tokyo, Paris, New York, San Francisco, Sydney, and Guildford available through search.

## Features

- Black background, rounded glass border, blue daytime panels, and purple nighttime panels.
- Helvetica Neue typography, sun rays, textured moon, dimensional clouds, rain, snow, thunderstorms, and a matching app icon.
- Current temperature, daily high and low, city-local time, and a six-day forecast.
- A dedicated header artwork area that keeps every weather icon clear of the temperature and city name. Sun, moon, and cloud bodies have calibrated visual sizes and share a common drawing stage; glow, shadows, rain, and lightning do not determine their scale.
- A horizontally scrolling 12-hour forecast, with an hourly list option on compact screens.
- City paging, page indicators, a local weather indicator, a 3D flip transition, and Reduce Motion support.
- Dark linen city management, gradient navigation buttons, unit selection, city search, confirmed deletion, and drag reordering.
- A custom iOS 6-style ON/OFF switch with an opaque blue/gray track, a shaded white thumb, tap and drag interaction, and native accessibility semantics. Its appearance stays consistent across supported iOS versions, and its animation respects Reduce Motion.
- Global city, district, county, and postcode search with Chinese and pinyin support. Results include the parent city, county, province/state, and country where available, with duplicate administrative results and non-place features filtered out.
- App icon digits centered beneath the sun, with a separate superscript degree symbol.
- Complete thunderstorm lightning geometry, with both tips and room for its glow.
- On-demand location, distinct permission and service-disabled messages, Open Settings, transient error retries, independent GPS and city lookup deadlines, and local weather pinned first. Successful location requests exit demo mode and refresh live weather.
- Live weather and global city/postcode search, a 10-minute cache, manual refresh, retries, and the last successful forecast when offline.
- Local persistence for cities, ordering, units, demo preferences, and cached forecasts, with basic VoiceOver labels.
- Automatic Chinese/English interface selection from the system or per-app language, including controls, weekdays, timestamps, errors, permission descriptions, the Home Screen name, and accessibility labels. Other preferred languages fall back to English.
- Search-result language follows the query independently of the interface: Chinese text requests Chinese/native place names; Latin text requests English names; numeric postcodes follow the app language. Matching provider identifiers preserve both language variants when available, including across saved-city updates and relaunches.

The app supports English and Chinese (Simplified) while retaining the classic layout. Chinese time labels use a compact 24-hour format; English retains the original 12-hour styling. Change the iPhone's preferred language, or the app language in Settings when available, then reopen the app. Status bars, permission prompts, and keyboards use current iOS system components. Weather illustrations are drawn natively rather than using original bitmap assets. Cities are stored locally; iCloud city synchronization is not implemented.

## Data and references

The layout and interactions reference [Apple's iPhone User Guide for iOS 6, Chapter 15: Weather](https://cdsassets.apple.com/live/6GJYWVAV/user/ma1658_iphone_ios6_user_guide.pdf) and [2012 iPhone 5 weather screenshots](https://forums.macrumors.com/threads/how-do-i-get-the-ios-6-weather-app-to-look-like-this-on-my-iphone-4s.1458245/).

Live forecasts use the [Open-Meteo Forecast API](https://open-meteo.com/en/docs). Place search uses [Photon](https://github.com/komoot/photon/blob/master/docs/api-v1.md) with OpenStreetMap data, falling back to the [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api) and GeoNames. Weather attribution and the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) link appear in About; search also displays [OpenStreetMap attribution and its ODbL license](https://www.openstreetmap.org/copyright). The classic `Y!` detail opens the actual data-source information.

Search requests are debounced, limited to one request per second per app instance, and cached for 15 minutes. Fallback responses have a shorter cache lifetime. The public Photon endpoint permits modest use without an availability guarantee; see its [demo server policy](https://github.com/komoot/photon#demo-server) before broader distribution. Place coverage and administrative labels depend on the upstream data. Demo Weather retains its small offline preset search catalog.

Photon's public endpoint supports English and native names but does not accept Chinese as a requested language. The app combines English/native responses by stable place identifiers, normalizes Chinese script, and uses GeoNames' Chinese/English responses when falling back. Country names use the returned ISO region code where available. Missing translations retain official source names; Chinese places can use pinyin when an English name is missing. Foreign names are not converted to Mandarin pinyin. Saved cities retain their identities, coordinates, time zones, and cached forecasts when display names change.

## Verification

The artwork size and lightning fixes passed **25 core tests on iPhone Air / iOS 26.2** and **all 5 standard UI tests on iPhone SE / iOS 17.5**, with no failures or compiler warnings. Strict Swift formatting checks also passed. Two optional online integration tests were excluded from this artwork regression run; they previously passed on iPhone SE after the directory migration.

The final larger header passed both header regression tests on iPhone Air and all three relevant header/compact-layout tests on iPhone SE. Its artwork scales with available vertical space while reserving a separate text area. Compact forecast rows retain all content and bottom controls.

The 39 core unit tests cover default units and preference migration, conversions, API parsing, persistence, caching, local city updates, eight location-state regressions, complete lightning geometry, district names and administrative hierarchy, postcode queries, cancellation, provider fallback, distinct nearby districts, resolved forecast time zones, bilingual resources, query-language selection, legacy data, and language-independent place identities. Eight standard UI tests cover day/night panels, Celsius/Fahrenheit selection, city management, compact hourly forecasts, About, flip interactions, header artwork bounds, and Chinese/English interface and search flows. Header regressions exercise all seven weather conditions, both night illustrations, negative Celsius temperatures, and a three-digit Fahrenheit temperature, including Chinese labels. They assert that the artwork and temperature do not overlap, remain inside the screen, and leave the bottom controls accessible.

The place-search update passed **37 tests on iPhone Air / iOS 26.2** and **34 relevant tests on iPhone SE / iOS 17.5**, including both new online integration tests on each device. Live validation found the same Quanshan district using Chinese, combined city/district, and pinyin queries, verified Xuzhou/Jiangsu context, added it through the actual Add City UI, and loaded a live Celsius forecast with the Asia/Shanghai time zone. UK postcode search also resolved Guildford correctly.

The classic switch update passed **3 relevant UI tests on iPhone Air / iOS 26.2** and **2 on iPhone SE / iOS 17.5**, with no failures, skips, or compiler warnings. Manual Air validation through the browser mirror confirmed thumb and row taps, dragging in both directions, correct accessible switch values, and the resulting demo forecast. The `classic-switch/` screenshots record the opaque ON/OFF appearance and both screen sizes.

The localization update passed the complete **50-test iPhone Air / iOS 26.2** suite, including all four optional online/location tests. A final source-name safeguard and its new regression then passed **18 focused localization/search tests** on Air. The final **51-test iPhone SE / iOS 17.5** suite also passed with all optional integrations enabled. These runs had no failures, skips, or compiler warnings. Tests use actual `AppleLanguages` launch arguments rather than modifying the simulator's system settings. The language flows verify Chinese UI with English and Chinese searches, English UI with Chinese search, saved name variants, stable postcode identities, the legacy city format, and localized negative/three-digit temperatures. Screenshots are stored in `docs/screenshots/localization/`.

Earlier native location verification covered denied permission, the recovery message, opening the app's Settings page, granting permission, receiving simulated coordinates, resolving the city, and loading a live Celsius forecast. The older iOS path uses CLGeocoder; iOS 26 and later use MapKit reverse geocoding. Live weather/search and native location remain separate optional integration tests.

Run these commands from this app's directory:

```sh
xcodebuild test -project WeatherSix.xcodeproj -scheme WeatherSix \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO \
  -skip-testing:WeatherSixUITests/WeatherSixUITests/testLiveWeatherAndSearch \
  -skip-testing:WeatherSixUITests/WeatherSixUITests/testCurrentLocationPermissionAndForecast \
  -skip-testing:WeatherSixUITests/WeatherSixUITests/testLiveDistrictSearchAndForecast \
  -skip-testing:WeatherSixTests/PlaceSearchTests/testLiveChineseDistrictSearchAndForecast

xcrun swift-format lint --recursive --strict \
  WeatherSix WeatherSixTests WeatherSixUITests scripts/generate_icon.swift
```

For live weather and search, set `WEATHER_LIVE_TESTS=1` in the scheme's Test environment and run `testLiveWeatherAndSearch`. For native location integration, set `WEATHER_LOCATION_TESTS=1` and run `testCurrentLocationPermissionAndForecast`. The location test uses public London coordinates and restores the previous simulated location afterward. These tests skip when their environment flags are absent.

For district search integration, set `WEATHER_SEARCH_TESTS=1` and run `PlaceSearchTests.testLiveChineseDistrictSearchAndForecast` and `WeatherSixUITests.testLiveDistrictSearchAndForecast`. These opt-in tests use real geocoding and forecast services.

On 2026-10-08, the app was built, installed, and launched on a physical iPhone Air running iOS 27.0.1 using Personal Team signing. The device owner confirmed that manual current-location testing worked. This is user-reported verification; location accuracy and the software-simulation source flag were not captured. Location simulation is disabled for the normal Run action. The latest place-search, classic switch, and Chinese/English localization updates were rebuilt, installed, and launched on the same device; the owner has not yet reported a manual retest of these updates. The debugger was detached before quitting Xcode, and the app's device process was confirmed to remain running afterward. Larger header artwork, complete lightning, and centered app icon digits are also included.

Release signing has not been verified. Location requests use foreground access without background tracking. If location permission was previously denied, tap Open Settings and allow access while using the app. Simulator also requires a configured simulated location.

## Screenshots and source

Screenshots in `docs/screenshots/` include daytime, nighttime, city management, search, live weather, location permission recovery, and compact iPhone SE layouts. The `header/` folder records the initial overlap fix. The `optical/iphone-air/` and `optical/iphone-se/` folders each contain 11 screenshots of the final larger header; `optical/comparison-air.png` compares all nine day/night artwork variants. The `place-search/` folder records real Quanshan search results and live forecasts on Air and SE.

- `WeatherSix/Views/`: classic panels, skeuomorphic controls, weather drawings, and city management.
- `WeatherSix/Models/`: cities, forecasts, and persisted state.
- `WeatherSix/Services/`: weather/search APIs and location services.
- `WeatherSixTests/` and `WeatherSixUITests/`: regressions and optional live integration tests.
- `scripts/create_project.py`: project and shared-scheme generation.
- `scripts/generate_icon.swift`: app icon generation.

The generation scripts are not required for normal editing, building, or running.
