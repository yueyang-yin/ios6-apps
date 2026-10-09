# iOS 6 Apps

A collection of native app recreations inspired by the skeuomorphic design of iOS 6. Each app has its own Xcode project, source, assets, tests, scripts, and documentation.

## Getting started

Open `iOS6Apps.xcworkspace` at the collection root and select the app's scheme. Weather uses `WeatherSix`; Notes uses `NotesSix`. Both require iOS 17 or later.

| App | Project | Documentation |
| --- | --- | --- |
| Weather | `apps/weather/WeatherSix.xcodeproj` | [Run instructions](apps/weather/README.md), [Verification record](apps/weather/docs/verification.md) |
| Notes | `apps/notes/NotesSix.xcodeproj` | [Run instructions](apps/notes/README.md), [Verification record](apps/notes/docs/verification.md) |

Weather defaults to Celsius, and its app icon displays `23°`. Use Current Location requests foreground location access and loads live weather. If access was denied, Open Settings provides a recovery path. Set a simulated location using Simulator → Features → Location when running on Simulator.

The weather interface follows the iPhone's system or app language in English or Chinese (Simplified). Search results follow the query language independently, and saved cities preserve available names in both languages.

Notes recreates the brown leather navigation, yellow ruled paper, original font choices, note list, search, previous/next controls, and paper-crumpling deletion. Its full-screen framing follows Weather's city-management layout. It saves text automatically on the device and uses the same system/per-app Chinese and English language rules as Weather. User-written text retains its original language. Run with `--demo` for an isolated sample notebook; normal launches start with an empty local notebook.

## Shared design language

Use the [shared iOS 6 design language](docs/design-language.md) where its patterns fit the screen. Applicable Notes, detail, management, and settings screens can extend the body color/texture through status and bottom safe areas while keeping navigation as an independent panel. Weather's main forecast retains its own original glass panel and paging layout. Specialized main screens do not need the Notes/settings frame; each app keeps its historical materials, typography, dimensional controls, and motion.

The guide defines selective application, classic sheets and alerts, system-UI boundaries, English/Chinese adaptation, accessibility, concrete Weather/Notes component references, and visual acceptance for new apps. The root `AGENTS.md` requires reading it and deciding what applies before app UI work.

## Layout

```text
ios6-apps/
├── AGENTS.md
├── README.md
├── iOS6Apps.xcworkspace/
├── apps/
│   ├── notes/
│   │   ├── NotesSix.xcodeproj/
│   │   ├── NotesSix/
│   │   ├── NotesSixTests/
│   │   ├── NotesSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   └── weather/
│       ├── WeatherSix.xcodeproj/
│       ├── WeatherSix/
│       ├── WeatherSixTests/
│       ├── WeatherSixUITests/
│       ├── scripts/
│       ├── docs/
│       └── README.md
└── docs/
    ├── design-language.md
    └── project-layout.md
```

To add an app, read the [design language](docs/design-language.md), create `apps/<app-name>/`, add its independent Xcode project to the root workspace, and register it in the table above. See the [project layout guide](docs/project-layout.md).

## License

This project is licensed under the [MIT License](LICENSE).

Third-party data and services remain subject to their own licenses and terms; see [Weather data and references](apps/weather/README.md#data-and-references). The MIT License does not grant rights to third-party trademarks or materials. This is an independent project and is not affiliated with, sponsored by, or endorsed by Apple Inc.
