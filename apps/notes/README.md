# Notes Six

A native iPhone notes app inspired by Notes in iOS 6. It uses SwiftUI and UIKit, requires **iOS 17 or later**, and has no third-party app dependencies.

Use the applicable patterns in the collection's [shared design language](../../docs/design-language.md) for app UI changes. Notes supplies the reference paper/leather framing, body-backed status areas, and classic share/printing components; other apps may retain different main-page layouts.

## Run

Open `../../iOS6Apps.xcworkspace` and select **NotesSix**, or open `NotesSix.xcodeproj` directly. Select an iPhone simulator and run. Physical-device installation requires your own development team and signing configuration.

Normal launches start with an empty notebook. Add `--demo` to the scheme's launch arguments to show four sample notes in a separate, persistent demo notebook. Demo changes do not affect the normal notebook. Sample content is written in the app's language on the demo notebook's first launch and remains unchanged on subsequent language changes.

## Classic interface

- Brown leather navigation bars with grain, embossed titles, shaded buttons, and arrow-shaped back buttons.
- Pale yellow paper with subtle fibers, horizontal rules, a double margin, and a torn top edge.
- A chronological note list with first-line titles, dates, a search field, a note count, and swipe-to-delete buttons.
- Tap-to-edit notes with a native text selection, cursor, undo menu, spelling support, and a keyboard-aware layout.
- Previous/next navigation with native page-curl transitions, a paper-colored toolbar, sharing, and a classic deletion confirmation panel.
- A classic bottom share panel with a dark shaded surface, original vector Mail/Print/Copy icons, embossed labels, and a separate glossy Cancel button. Tapping the dimmed page or using the accessibility escape action dismisses it. The panel adapts to portrait, landscape, and bottom safe areas, and honors Reduce Motion.
- Classic Printer Options and printer-selection screens with a blue-gray navigation bar, pinstripe background, white grouped rows, silver copies stepper, and glossy Print button. These screens follow Apple's historical printing reference rather than presenting the current system options sheet.
- Confirming deletion in the reader opens the bin lid, folds the actual note page into a shaded paper ball, and drops it into the bin. The animation uses public Core Animation APIs and a textured triangular mesh, with immediate deletion when Reduce Motion is enabled. Backgrounding or rotating the app completes a confirmed deletion without leaving an animation overlay behind.
- The screen follows Weather Six's city-management layout: an edge-to-edge textured background, a full-width navigation bar, and controls inside the safe area. The navigation bar remains a separate leather panel. The status area extends the current page's body background: yellow paper and its texture/rules for notes, or gray pinstripes for accounts. Dark system text stays readable on these light surfaces. The background also fills the bottom safe area, with no inset card or extra footer spacer; the device display provides the outer corner shape.
- The original Noteworthy, Helvetica, and Marker Felt font choices, available under **Accounts → Settings**. Preferences persist across launches.
- A natively drawn legal-pad app icon. No original Apple bitmap assets are bundled.
- VoiceOver labels, accessibility actions for deletion, minimum 44-point navigation hit areas, scalable editor text, and Reduce Motion support.

## Notes and storage

The first nonempty line becomes the title. Notes are ordered by their most recent edit. Search checks the full text, including the body, with case- and diacritic-insensitive matching. Search handles Chinese and English independently of the interface language.

Changes save automatically using atomic JSON file replacement in the app's private Application Support directory. Empty drafts are removed when leaving the editor. Font preferences are stored with the notebook. A damaged or newer unsupported archive is preserved and cannot be overwritten by this app. A failed save retains the latest text in memory and displays a retry control.

This version implements the local **On My iPhone** account. **All Notes** and **On My iPhone** show the same local notebook. iCloud, Gmail/Yahoo/IMAP synchronization, and cross-device sync are not implemented. Printer discovery and printing use the local network; notes are not uploaded to a cloud service.

The share button opens the app's iOS 6-style panel. **Copy** copies the complete note to the local clipboard. **Mail** opens the system mail composer with the first-line title as its subject and the complete note as its plain-text body; a configured Mail account is required. **Print** opens the app's classic settings. Choose an AirPrint printer on the same Wi-Fi network and set 1–99 copies. Bonjour discovery uses `_ipp._tcp` and `_ipps._tcp`, and printer selection checks availability with `UIPrinter.contactPrinter`. Local network access is requested only when opening printer selection.

The complete note is paginated as a plain-text A4 PDF. Copies are submitted as repeated documents in collated order, using the public direct-to-printer API without the modern options sheet. Print is disabled until a printer is selected. Discovery, connection, and print errors are recoverable; canceling options preserves the note. This implementation provides single-sided printing with printer/default paper handling, without paper-size, page-range, scaling, orientation, or duplex controls. The status bar, keyboard, text menus, mail composer, local network permission prompt, and printing progress indicator use the current operating system. Mail delivery and physical printing have not been verified.

## Language

The language selection matches Weather Six: the first preferred system or per-app language selects English or Simplified Chinese; all Chinese variants select Simplified Chinese, and other languages fall back to English. The UI, search placeholder, relative dates, timestamps, note counts, storage errors, accessibility labels, printer settings/discovery messages, local network permission explanation, and Home Screen name are localized. Chinese timestamps use 24-hour time; English timestamps use 12-hour time.

Change the iPhone language or the app's language in Settings, when available, and reopen the app. Your own notes are never automatically translated. Native keyboard, mail, permission prompts, and print-progress text can follow the simulator/device language separately from the app's language, especially when testing with launch arguments.

## Simulator in the browser

With the desired simulator running:

```sh
bash scripts/serve_sim.sh <simulator-udid>
```

Open the exact local URL printed by [serve-sim](https://github.com/EvanBacon/serve-sim) in Codex's in-app browser. Keep the terminal running while using the mirror. Stop it with Ctrl-C to clean up that simulator's helper. The script scopes cleanup to the supplied UDID and does not kill other simulator mirrors.

## Verification

See [the verification record](docs/verification.md) for tested devices, flows, screenshots, and known limits.

```sh
xcodebuild test -project NotesSix.xcodeproj -scheme NotesSix \
  -destination 'platform=iOS Simulator,name=iPhone Air' \
  -parallel-testing-enabled NO

xcrun swift-format lint --recursive --strict \
  NotesSix NotesSixTests NotesSixUITests scripts/generate_icon.swift
```

UI tests use `--uitesting --demo --reset-notes` and real `AppleLanguages` arguments. They write to a dedicated test notebook and do not clear normal or demo data. `--long-list` adds scroll fixtures only when both UI-testing and reset arguments are present.

`--print-fixtures` provides two printer rows only with `--uitesting`; the fixture destinations cannot submit a print job. `--print-empty` provides a deterministic empty discovery result under the same test guard. Normal launches always use real Bonjour discovery.

## Reference and scope

The primary reference is [Apple's iPhone User Guide for iOS 6, Chapter 17: Notes, pages 86–87](https://cdsassets.apple.com/live/6GJYWVAV/user/ma1658_iphone_ios6_user_guide.pdf). The app recreates the classic iPhone visual language and local note workflows on a current iOS runtime. It is not an iOS 6 binary or a pixel-identical replacement for every historical system component. The in-app settings entry is a convenience adaptation; the original font setting lived in the system Settings app. Portrait and landscape iPhone layouts are supported. The crumpling animation recreates the classic interaction using original code rather than Apple's private animation or assets. A dedicated iPad layout is not provided.

The share actions also follow the Notes screenshot in [My iPad for Kids (iOS 6), page 137](https://ptgmedia.pearsoncmg.com/images/9780789748645/samplepages/0789748649.pdf). The iPhone panel's shading and Cancel treatment follow [a contemporary iOS 6 share-panel capture](https://isirix.wordpress.com/2012/06/13/hot-ios-6-principali-novita-e-videoprova/). Icons are drawn by this app; reference images are not bundled.

Printer Options follows Figure 5-3 in [Apple's archived Drawing and Printing Guide for iOS](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/Printing/Printing.html). The navigation, grouped rows, copies control, and action button are drawn by the app; Apple's reference bitmap is not bundled.

This is an independent project and is not affiliated with, sponsored by, or endorsed by Apple Inc. The collection's MIT license applies to this project's original code and artwork, not to third-party names or reference material.

## Source

- `NotesSix/Models/`: note records, persistence, fonts, localization, printer discovery, and PDF pagination.
- `NotesSix/Views/`: classic artwork, list, native ruled editor, accounts/settings, and sharing.
- `NotesSixTests/`: storage, ordering, search, recovery, fonts, localization, printer URLs, and PDF pagination tests.
- `NotesSixUITests/`: full app flows, language changes, keyboard layout, and scrolling regressions.
- `scripts/`: reproducible project/icon generation and simulator browser launcher.

Project and icon generation scripts are optional; normal Xcode builds do not run them.
