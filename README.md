# iOS 6 Apps

A collection of native app recreations inspired by the skeuomorphic design of iOS 6. Each app has its own Xcode project, source, assets, tests, scripts, and documentation.

## Getting started

Open `iOS6Apps.xcworkspace` at the collection root and select the app's scheme. The weather app uses the `WeatherSix` scheme and requires iOS 17 or later.

| App | Project | Documentation |
| --- | --- | --- |
| Weather | `apps/weather/WeatherSix.xcodeproj` | [Run instructions](apps/weather/README.md), [Verification record](apps/weather/docs/verification.md) |

Weather defaults to Celsius, and its app icon displays `23°`. Use Current Location requests foreground location access and loads live weather. If access was denied, Open Settings provides a recovery path. Set a simulated location using Simulator → Features → Location when running on Simulator.

The weather interface follows the iPhone's system or app language in English or Chinese (Simplified). Search results follow the query language independently, and saved cities preserve available names in both languages.

## Layout

```text
ios6-apps/
├── AGENTS.md
├── README.md
├── iOS6Apps.xcworkspace/
├── apps/
│   └── weather/
│       ├── WeatherSix.xcodeproj/
│       ├── WeatherSix/
│       ├── WeatherSixTests/
│       ├── WeatherSixUITests/
│       ├── scripts/
│       ├── docs/
│       └── README.md
└── docs/
    └── project-layout.md
```

To add an app, create `apps/<app-name>/`, add its independent Xcode project to the root workspace, and register it in the table above. See the [project layout guide](docs/project-layout.md).

## License

This project is licensed under the [MIT License](LICENSE).

Third-party data and services remain subject to their own licenses and terms; see [Weather data and references](apps/weather/README.md#data-and-references). The MIT License does not grant rights to third-party trademarks or materials. This is an independent project and is not affiliated with, sponsored by, or endorsed by Apple Inc.
