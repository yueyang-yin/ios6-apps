# iOS 6 Apps

A collection of native app recreations inspired by the skeuomorphic design of iOS 6. Each app has its own Xcode project, source, assets, tests, scripts, and documentation.

Camera Roll and Photos compile their matching graphite navigation and glossy controls from [`shared/PhotoChrome`](shared/PhotoChrome/ClassicPhotoChrome.swift). Keep that directory alongside `apps/` when opening either independent project.

## Getting started

Open `iOS6Apps.xcworkspace` at the collection root and select the app's scheme. Weather uses `WeatherSix`; Notes uses `NotesSix`; Calculator uses `CalculatorSix`; Compass uses `CompassSix`; Clock uses `ClockSix`; Calendar uses `CalendarSix`; Reminders uses `RemindersSix`; Camera uses `CameraSix`; Photos uses `PhotosSix`; Maps uses `MapsSix`; Stocks uses `StocksSix`; Passbook uses `PassbookSix`. All require iOS 17 or later.

| App | Project | Documentation |
| --- | --- | --- |
| Weather | `apps/weather/WeatherSix.xcodeproj` | [Run instructions](apps/weather/README.md), [Verification record](apps/weather/docs/verification.md) |
| Notes | `apps/notes/NotesSix.xcodeproj` | [Run instructions](apps/notes/README.md), [Verification record](apps/notes/docs/verification.md) |
| Compass | `apps/compass/CompassSix.xcodeproj` | [Run instructions](apps/compass/README.md), [Verification record](apps/compass/docs/verification.md) |
| Calculator | `apps/calculator/CalculatorSix.xcodeproj` | [Run instructions](apps/calculator/README.md), [Verification record](apps/calculator/docs/verification.md) |
| Clock | `apps/clock/ClockSix.xcodeproj` | [Run instructions](apps/clock/README.md), [Verification record](apps/clock/docs/verification.md) |
| Calendar | `apps/calendar/CalendarSix.xcodeproj` | [Run instructions](apps/calendar/README.md), [Verification record](apps/calendar/docs/verification.md) |
| Reminders | `apps/reminders/RemindersSix.xcodeproj` | [Run instructions](apps/reminders/README.md), [Verification record](apps/reminders/docs/verification.md) |
| Camera | `apps/camera/CameraSix.xcodeproj` | [Run instructions](apps/camera/README.md), [Verification record](apps/camera/docs/verification.md) |
| Photos | `apps/photos/PhotosSix.xcodeproj` | [Run instructions](apps/photos/README.md), [Verification record](apps/photos/docs/verification.md) |
| Maps | `apps/maps/MapsSix.xcodeproj` | [Run instructions](apps/maps/README.md), [Verification record](apps/maps/docs/verification.md) |
| Stocks | `apps/stocks/StocksSix.xcodeproj` | [Run instructions](apps/stocks/README.md), [Verification record](apps/stocks/docs/verification.md) |
| Passbook | `apps/passbook/PassbookSix.xcodeproj` | [Run instructions](apps/passbook/README.md), [Verification record](apps/passbook/docs/verification.md) |

Weather defaults to Celsius, and its app icon displays `23°`. Use Current Location requests foreground location access and loads live weather. If access was denied, Open Settings provides a recovery path. Set a simulated location using Simulator → Features → Location when running on Simulator.

The weather interface follows the iPhone's system or app language in English or Chinese (Simplified). Search results follow the query language independently, and saved cities preserve available names in both languages.

Notes recreates the brown leather navigation, yellow ruled paper, original font choices, note list, search, previous/next controls, and paper-crumpling deletion. Its full-screen framing follows Weather's city-management layout. It saves text automatically on the device and uses the same system/per-app Chinese and English language rules as Weather. User-written text retains its original language. Run with `--demo` for an isolated sample notebook; normal launches start with an empty local notebook.

Calculator recreates the olive LCD, glossy memory and number keys, tall orange equals, and rotation-driven scientific keypad. It includes real arithmetic/scientific operations, memory, swipe-to-delete, clipboard actions, and saved calculation state, using the same English/Simplified Chinese language rules as Weather.

Compass recreates the iOS 6 walnut cabinet, brass rim, ivory compass rose, bearing, coordinates, Maps shortcut, and magnetic/true-north settings. Physical devices use Core Location heading and location updates. Simulator previews are explicitly labeled sample data. It uses the same English/Simplified Chinese language rules as Weather.

Calendar recreates the blue-gray glossy chrome, embossed month grid, selected-day agenda, searchable event list, day timeline, and rotation-driven week view of the iPhone calendar. It includes persistent local calendars, event editing, recurrence and exception scopes, all-day events, reminders, and optional EventKit access to configured system accounts. It follows Weather's system/per-app English and Simplified Chinese language rules. Launch with `--demo` for isolated sample events; normal launches start with empty local calendars.

Reminders recreates the black pebbled leather, off-white paper, red list headings, double margin rules, square checkboxes, and dimensional controls of iOS 6. It includes persistent lists and reminders, completion history, search, manual ordering, date and location alerts, recurrence, priorities, notes, a seven-day date strip, and optional system Reminders accounts through EventKit. It follows Weather's English/Simplified Chinese language behavior. Launch with `--demo` for isolated sample lists; ordinary launches start with an empty local list.

Camera recreates the silver viewfinder controls, oval metal shutter, black camera/video slider, blue focus rectangle, iris transition, options panel, and panorama guide of iOS 6. It uses AVFoundation for real photo/video capture, microphone audio, flash/torch, focus lock, zoom, HDR exposure bracketing, and motion-guided panoramas. Captures persist locally and can be saved to Photos. The camera roll supports browsing, playback, import, sharing/printing, and basic photo editing, with Weather-compatible English/Simplified Chinese language behavior. Simulator launches use clearly labeled original illustrated demo scenes.

Photos recreates the graphite metal navigation, compact white album rows, parenthesized counts, four-column portrait grid, black viewer, and Albums / Photo Stream / Places tabs of iOS 6. It uses the real system photo library for album organization, viewing, location browsing, sharing/printing, image editing, and video trimming. Edits preserve the original and save new copies. Photos and Camera share saved system assets and support bidirectional links to an exact capture. Photos follows Weather's English/Simplified Chinese language behavior; `--demo` uses isolated illustrated media. The retired My Photo Stream service is represented honestly through available iCloud Shared Albums and a service explanation.

Maps recreates silver search/navigation chrome, red pushpins, the curled map corner and linen options, and green navigation signs. It uses current Apple MapKit maps, real place search, driving/walking routes, location updates, foreground voice guidance, satellite/Flyover imagery, traffic, persistent bookmarks and recents, sharing, and printing. It follows Weather's English/Simplified Chinese language rules. Map data, coverage, and system-owned panels use the current OS; background navigation is available through the Apple Maps action.

Stocks recreates the alternating blue/slate watchlist, dimensional change buttons, three-page summary/chart/news area, and rotation-driven full-screen chart. It supports Yahoo Finance quotes, symbol search, news, local watchlist editing, cached data, and Weather-compatible English/Simplified Chinese. Launch with `--demo` for explicitly labeled isolated sample data.

Passbook recreates the graphite welcome screen, four colored ticket silhouettes, closely stacked passes, illustrated pass faces, information flip, bottom pass tray, and paper-shred deletion of iOS 6. It supports persistent local passes, issuer-signed `.pkpass` import, QR/PDF417/Aztec/Code128 barcodes, notes, ordering, sharing, and adding imported passes to Apple Wallet. It follows Weather's English/Simplified Chinese language rules. Normal launches start empty; `--demo` uses an isolated sample collection. System Wallet handles Lock Screen relevance and issuer updates.

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
│   ├── passbook/
│   ├── stocks/
│   │   ├── StocksSix.xcodeproj/
│   │   ├── StocksSix/
│   │   ├── StocksSixTests/
│   │   ├── StocksSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── maps/
│   ├── photos/
│   │   ├── PhotosSix.xcodeproj/
│   │   ├── PhotosSix/
│   │   ├── PhotosSixTests/
│   │   ├── PhotosSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── camera/
│   │   ├── CameraSix.xcodeproj/
│   │   ├── CameraSix/
│   │   ├── CameraSixTests/
│   │   ├── CameraSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── reminders/
│   │   ├── RemindersSix.xcodeproj/
│   │   ├── RemindersSix/
│   │   ├── RemindersSixTests/
│   │   ├── RemindersSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── calendar/
│   │   ├── CalendarSix.xcodeproj/
│   │   ├── CalendarSix/
│   │   ├── CalendarSixTests/
│   │   ├── CalendarSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── compass/
│   │   ├── CompassSix.xcodeproj/
│   │   ├── CompassSix/
│   │   ├── CompassSixTests/
│   │   ├── CompassSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── calculator/
│   │   ├── CalculatorSix.xcodeproj/
│   │   ├── CalculatorSix/
│   │   ├── CalculatorSixTests/
│   │   ├── CalculatorSixUITests/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
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
