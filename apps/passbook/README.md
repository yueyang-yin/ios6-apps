# PassbookSix

A native iOS 17+ recreation of the iOS 6 Passbook experience, built with SwiftUI and public Apple frameworks. Open `PassbookSix.xcodeproj` or select **PassbookSix** in the collection workspace.

## Design

The [shared design language](../../docs/design-language.md) applies selectively. Passbook keeps its own graphite backdrop, full-width colored pass stack, ticket cutouts, card flip, and bottom pass tray. It does not use the Notes navigation frame. Body material continues behind the real status bar and home indicator; controls stay inside the safe area. Motion respects Reduce Motion.

The stack distributes passes across the entire usable display height. One or two passes reveal more paper; larger collections overlap more. Pulling upward progressively exposes the final full card in proportion to finger movement, and releasing or canceling the gesture springs the cards back to their resting stack. A drag cannot also open a pass. When headers no longer fit, the stack scrolls while preserving accessible tap regions; pulling at its bottom reveals the final card.

The welcome page follows the historical four-ticket composition: a yellow boarding pass, red event ticket, green store card, and purple coupon. Pass faces use shaded paper, fine borders, restrained shadows, Helvetica Neue, and original illustrated strips. The app icon follows the original black leather pocket with three fanned green, yellow, and blue tickets, using a retained generated master. Brand-mark approximations and scene artwork are original programmatic drawings. Brand names remain their owners' trademarks. Historical screenshots are references only. See [artwork provenance and regeneration](artwork/README.md).

## Features

- Boarding passes, event tickets, store cards, coupons, and generic passes.
- Empty welcome page, explicit sample catalog, full-height overlapping pass stack, animated expansion, information flip, bottom stack return, and paper-strip deletion after confirmation.
- Persistent local pass creation, arbitrary QR payloads, expiration dates, notes, pass ordering, and sharing.
- Issuer-signed `.pkpass` import from Files or Open In. PassKit validates the package before fields are read. ZIP entries are decompressed into bounded buffers; nothing is extracted to a filesystem path.
- Imported header, primary, secondary, auxiliary, and back fields, issuer colors, logo/strip images, expiration, relevant date, and barcode.
- QR, PDF417, Aztec, and Code128 rendering from the pass payload and declared character encoding. Unsupported or unrepresentable barcodes show an unavailable state.
- Sharing an imported pass preserves its original signed `.pkpass`. Local passes share readable text.
- Imported passes can be added to Apple Wallet through `PKAddPassesViewController` on supported devices.
- English and Simplified Chinese follow the first system/per-app preferred language, just like Weather. All Chinese variants map to Simplified Chinese; other languages fall back to English. User-entered and issuer-provided text remains unchanged.

Normal launches start with an empty local collection. Use **Add Passes** to import, create, or explicitly add examples. Sample barcodes begin with `DEMO:` and cannot be used for travel, entry, or purchases. The sample stack follows the historical reference order and branding: Fandango, Target, Delta, baseball, W Hotels, SPG, Sheraton, American Airlines, and Starbucks. These are clearly labeled design samples, with original drawn logo approximations and scene illustrations; they are not issuer-provided passes.

## Run and verify

```sh
python3 scripts/create_project.py
python3 scripts/generate_localizations.py
python3 scripts/generate_artwork.py
python3 scripts/verify_resources.py
```

Artwork regeneration requires Pillow. Building the app has no third-party package dependencies. The project uses the existing development team setting from this collection; select your own team for a physical device.

Launch arguments:

- `--demo`: isolated sample collection under `Application Support/PassbookSix-Demo`.
- `--ui-testing`: disposable test collection under `PassbookSix-UI`.
- `--reduce-motion`: deterministic reduced-motion QA, in addition to the system preference.
- `--preserve-test-state`: keep the test collection for relaunch checks.
- `-AppleLanguages '(en)'` or `-AppleLanguages '(zh-Hans)'`: language QA.

Use a DerivedData path outside a file-provider-backed Documents folder if macOS adds Finder metadata that codesign rejects:

```sh
xcodebuild -project PassbookSix.xcodeproj -scheme PassbookSix \
  -destination 'platform=iOS Simulator,name=iPhone Air' \
  -derivedDataPath /tmp/passbooksix-deriveddata test
```

Mirror a particular booted simulator in the Codex in-app browser:

```sh
./scripts/serve_sim.sh <simulator-udid>
```

Keep that terminal running and open the exact localhost URL it prints. Cleanup is scoped to that simulator. See [verification](docs/verification.md) for actual checks and evidence.

## System boundaries

This is a standalone historical recreation, not a replacement for the system Wallet app. It cannot enumerate every existing Wallet pass, create payment cards, implement Apple Pay, impersonate an issuer, or install itself as the system Lock Screen wallet. It requires no Wallet-library entitlements because imported packages are supplied explicitly by the user.

Apple Wallet and the issuer manage real pass updates, location/time relevance, and Lock Screen presentation after the user adds the signed pass to Wallet. PassbookSix stores a local snapshot and supports replacement by reimporting the same pass type and serial number. It does not claim automatic issuer refresh or iCloud synchronization.

Files, the share sheet, the keyboard, date controls, and the Add to Apple Wallet confirmation use current system UI. Imported pass localization files and custom issuer image layouts are not a complete Wallet rendering engine; original issuer field strings are retained, and common image/field groups are rendered in the historical shell. Local passes cannot be exported as signed issuer packages or added to Wallet.

Limits: one `.pkpass` per import, 20 MB package size, 5 MB per extracted entry, and at most 500 archive entries. `.pkpasses` bundles and payment passes are outside this app's scope. Removing a local pass never deletes its separate system Wallet copy. Local persistence is unencrypted app-sandbox storage and uses atomic writes; the app reports write failures without committing the changed in-memory collection.

## References

- [Historical stack and expanded pass reference](https://erikeng.se/images/passbook.png)
- [Historical welcome page reference](https://photos5.appleinsider.com/archive/passbook-120612-1.png)
- [Apple iOS 6 User Guide, chapter 16](https://cdsassets.apple.com/live/6GJYWVAV/user/ma1658_iphone_ios6_user_guide.pdf)
- [Apple Wallet Developer Guide: interacting with passes](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/PassKit_PG/Apps.html)
- [PKPass](https://developer.apple.com/documentation/passkit/pkpass)
- [PKAddPassesViewController](https://developer.apple.com/documentation/passkit/pkaddpassesviewcontroller)
- [Core Image barcode generators](https://developer.apple.com/documentation/coreimage/cifilter-swift.class)

This independent project is not affiliated with Apple. Apple names and historical designs remain their respective owners' property.
