# PassbookSix verification

## Unframed detail-page pass tray — 17 October 2026

Removed the tray's padded black panel and its enclosing border. The colored paper edges and front pass now sit directly on the continuous graphite background. Only the front card receives its own rounded contour, fine paper edge, and small contact shadow; no rectangular container surrounds the stack.

The exact Starbucks detail state from the user's feedback was checked in the live browser: [updated browser capture](screenshots/tray-clear/browser-starbucks.png). Focused UI checks passed on iPhone Air / iOS 26.2 (every pass type, expansion, information flip, bottom-tray return, and landscape; 2 checks in `test_sim_2026-10-17T16-54-03-237Z_pid37874_4e32d298.xcresult`) and iPhone SE / iOS 17.5 (landscape flip and repeated return; 1 check in `test_sim_2026-10-17T16-55-13-117Z_pid37874_cfdeaa3d.xcresult`). Additional captures: [Air Starbucks](screenshots/tray-clear/air-starbucks.png) and [SE information in landscape](screenshots/tray-clear/se-landscape-back.png). Strict formatting and whitespace checks passed. The signed device build also succeeded, and the update installed and launched on the same physical iPhone without uninstalling PassbookSix or resetting its collection. Interactive visual evidence for this revision is from the simulators.

## Welcome cutouts and interactive pull — 17 October 2026

Ticket silhouettes now subtract the punch shapes from the paper outline. The earlier even-odd compound path also filled the outside half of each circle, leaving visible dark circles in the welcome illustrations. The same corrected contour is used for clipping and the edge highlight, so only the actual notched paper casts a shadow.

Each library card keeps a full face behind the exposed header. The resting stack still fills the available height. Upward finger movement progressively compresses the stack toward its top and reveals more of the last card; transient gesture state springs back on release or cancellation. Reduce Motion removes the return spring. Ordinary scrolling remains available for collections whose headers exceed the viewport. The pull first accounts for the remaining normal scroll distance, and then reveals the last card. Selection is suppressed during the drag and its return, preventing a release from opening the card that moved beneath the finger.

Final focused checks passed on iPhone Air / iOS 26.2 (8 checks, `test_sim_2026-10-17T16-45-41-944Z_pid37874_769ab99b.xcresult`) and iPhone SE / iOS 17.5 (4 UI checks, `test_sim_2026-10-17T16-48-43-054Z_pid37874_7beaa0f3.xcresult`). Coverage includes notch bounds, proportional reveal and clamping, one/two/nine-pass resting layouts, short and long held pulls followed by automatic retraction, tap navigation after release, welcome/catalog flows, all pass types, and landscape return. The gesture check was recorded once more on Air and passed (`test_sim_2026-10-17T16-50-35-704Z_pid37874_6e3b3d02.xcresult`).

The [10-second runtime recording](elastic-pull-preview.mp4) shows a partial pull, release, a full pull with the QR code and bottom edge visible, and release back to the resting stack. Frames were inspected for the continuous reveal and return. Evidence: [corrected welcome](screenshots/elastic-pull/welcome-fixed.png), [fully revealed card](screenshots/elastic-pull/full-reveal.png), [Air after release](screenshots/elastic-pull/air-after-release.png), [SE after release](screenshots/elastic-pull/se-after-release.png), and [live browser after release](screenshots/elastic-pull/browser-rest.png). Real browser pointer drags also returned to the nine-pass Chinese stack.

The updated signed app was reinstalled on the same physical iPhone without uninstalling PassbookSix or resetting its data. Launch succeeded without a debugger, and a separate process query found PID 27949 in the new app container. These are update/runtime checks; the gesture assertions above are simulator evidence. Physical interactive verification remains subject to the microphone/camera sharing restriction described below.

## Physical-device deployment — 17 October 2026

A connected, paired iPhone Air running iOS 27.0.1 was identified with Developer Mode enabled. The signed arm64 device build succeeded using `/tmp/passbooksix-device-deriveddata`, and strict code-signature verification passed. The build emitted only an App Intents metadata-extraction warning because this app does not link AppIntents.

The first signed build stopped with `No Accounts`; the user signed in through Xcode before the successful retry. The first installation then hit the actual free-development app limit, identifying CameraSix, PhotosSix, and MapsSix. Under the user's conditional authorization, only `com.yinyueyang.camerasix` was uninstalled. The subsequent PassbookSix installation succeeded. A fresh installed-app query confirmed PassbookSix, PhotosSix, MapsSix, and DOVE, with CameraSix absent.

`devicectl device process launch` succeeded with normal launch arguments, without attaching a debugger. An independent process query confirmed PassbookSix at PID 27743. A direct device screenshot showed the correctly localized Chinese welcome screen: [physical-device welcome](screenshots/device/01-welcome-zh.png). The device's icon service returned the installed, non-placeholder 1024 x 1024 icon, which was visually checked against the approved leather-and-tickets design: [installed icon](screenshots/device/02-installed-icon.png).

Interactive physical-device verification is still pending. Device Hub reported that screen sharing was unavailable while another app used the phone's microphone or camera; the user was asked to pause that activity and keep the device unlocked. No other app or recording session was forcibly stopped. Installation, launch, screenshot, and icon evidence do not establish that every interactive feature works on this device.

## Icon revision — 17 October 2026

Replaced the four-stripe placeholder with a generated recreation of the historical black leather pocket and three fanned green/yellow/blue tickets. The approved source and generation prompt are retained in [artwork](../artwork/README.md); the resource generator now installs that master rather than redrawing the retired placeholder.

The 1024 x 1024 asset is opaque RGB, and a pixel comparison confirmed that it matches the approved master after the documented resize. Resource validation and `git diff --check` passed. Build/install/launch succeeded without reported warnings or errors in `build_run_sim_2026-10-17T15-47-45-734Z_pid37874_eb809ea1.log`. A real serve-sim browser frame showed the new leather icon under the Chinese Home Screen name, next to the separate system Wallet app; see the [Home Screen capture](screenshots/air-icon-home.jpg). No app uninstall or data reset was needed.

Verified on 17 October 2026 using Build iOS Apps / XcodeBuildMCP and Apple's device CLI. The automated functional results below are from simulators; physical-device delivery evidence and the remaining interactive checks are described above. A real issuer-signed pass was not available for end-to-end testing.

## Final behavior

- Historical nine-pass order and individual brand layouts replace the initial uniform colored headers.
- The library overlaps full pass faces. Available screen height determines the resting exposure of each card. One and two passes reveal more paper; nine passes overlap more. Pulling temporarily reveals the final card and releasing restores the resting stack. Large collections scroll when necessary to preserve a minimum header/tap region.
- Covered card areas cannot intercept another pass's taps. Navigation is disabled briefly while expansion, collapse, or flipping is in progress.
- The active card opens, flips to information, returns, and can be deleted with confirmation. The bottom tray represents the remaining passes rather than repeating the selected pass.
- English and Simplified Chinese use Weather's language-selection rule; Chinese variants use Simplified Chinese, and unsupported languages use English. Chinese alias bundles also provide the localized Home Screen name.
- Normal, demo, and UI-test collections use separate storage directories. Demo passes are explicitly labeled and have `DEMO:` payloads.

## Automated checks

| Runtime | Checks | Result bundle |
| --- | --- | --- |
| iPhone SE (3rd generation), iOS 17.5 | Initial complete 22-test suite: persistence, import parsing, archive bounds, all barcode formats, localization, creation, cancellation/deletion, relaunch, landscape, every pass kind | `test_sim_2026-10-17T15-31-15-705Z_pid37874_62b6c7f7.xcresult` — 22 passed |
| iPhone SE, iOS 17.5 | Historical tray and every-kind/landscape regression | `test_sim_2026-10-17T15-33-38-576Z_pid37874_c7b418ca.xcresult` — 2 passed |
| iPhone Air, iOS 26.2 | Adaptive-stack model tests plus real UI checks for one/two/nine passes, landscape, and every pass kind | `test_sim_2026-10-17T15-37-16-408Z_pid37874_3a8cea3c.xcresult` — 12 passed |
| iPhone SE, iOS 17.5 | Final adaptive-stack one/two/nine layout and landscape return | `test_sim_2026-10-17T15-38-54-022Z_pid37874_2bbbfcaa.xcresult` — 2 passed |
| iPhone Air, iOS 26.2 | Final one/two/nine layout after bottom-aligned barcode spacing | `test_sim_2026-10-17T15-40-33-921Z_pid37874_41eb15be.xcresult` — 1 passed |

Result bundles are retained under the host's XcodeBuildMCP workspace directory, `result-bundles/`. These are successive scoped checks, not a claim that the complete source suite was rerun in full on both devices.

The barcode checks actually decode generated QR, PDF417, Aztec, and Code128 images back to their payloads using Vision. A UTF-8 Chinese payload is also decoded. Vision's revision 1 CPU decoder is selected explicitly for consistent simulator support; the newer default decoder failed to create an inference context on iOS 26.2.

Earlier layout failures exposed a real tap-region/transition problem. The final stack separates decorative full card surfaces from exposed interactive regions, and the UI tests wait for enabled controls before subsequent actions. Both runtimes passed the corrected return/reopen checks.

Resource validation passed for 104 paired English/Simplified Chinese strings, placeholders, static localization keys, four original image assets, document registration, and workspace registration. Chinese alias bundles contain the same Simplified Chinese resources. Strict Swift formatting, plist/project parsing, and `git diff --check` passed.

## Visual and interaction evidence

- [Final Chinese stack on iPhone Air](screenshots/air-stack-zh.jpg)
- [Air: one pass](screenshots/air/10-One-Pass-Full-Height.jpg), [two passes](screenshots/air/11-Two-Passes-Full-Height.jpg), [nine passes](screenshots/air/12-Nine-Passes-Full-Height.jpg)
- [SE: one pass](screenshots/se/10-One-Pass-Full-Height.jpg), [two passes](screenshots/se/11-Two-Passes-Full-Height.jpg), [nine passes](screenshots/se/12-Nine-Passes-Full-Height.jpg)
- [English welcome](screenshots/air/01-Welcome-English.jpg), [boarding pass](screenshots/air/02-Boarding-Pass.jpg), [information](screenshots/air/03-Information.jpg)
- [Recorded paper-strip deletion](shred-preview.mp4)

The Codex in-app browser was opened at the exact `http://localhost:3200/` URL printed by a UDID-scoped `serve-sim` terminal. CUA browser screenshots confirmed a real `live` frame. A browser pointer tap opened Starbucks, the information button flipped the card, and a confirmed sample deletion ran the paper-strip animation. The eight remaining passes redistributed across the full height. Adding the sample collection restored all nine passes. Recording frames were inspected to verify expansion, flipping, and the falling strips, rather than inferring motion from still images.

The final mirror remains open on iPhone Air `E092AACD-B2F6-493E-8BAE-E9D7A704ABD8`, displaying the restored nine-pass Chinese sample collection. Browser-frame rotation was reset to upright portrait. The app's regular collection was not modified during these checks.

## Boundaries and setup observations

- Real issuer signatures and Add to Apple Wallet require a valid signed `.pkpass` and a supported device. Tests cover JSON/ZIP decoding, invalid-package rejection, and original payload rendering; successful real-issuer import and system Wallet installation remain unverified.
- Lock Screen relevance, automatic issuer updates, iCloud synchronization, and Apple Pay are not reproduced by a standalone app. Signed passes added to Apple Wallet use the system's capabilities.
- Historical brand marks are original approximations and the scenes are original drawings; the app does not bundle screenshot crops or claim pixel-identical issuer artwork.
- Native runtime snapshots returned no app controls on this host, so semantic app verification used XCUITest. Browser Canvas pixels alone are not the source of functional test assertions.
- The first build under a Documents-backed DerivedData directory failed codesigning because Finder metadata was attached to the app bundle. Building under `/tmp/passbooksix-deriveddata` and `/tmp/passbooksix-deriveddata-se` resolved it without changing signing policy.
- The default npm cache was sandbox-blocked. The mirror was started with a temporary npm cache and the required host access; no global npm ownership change was made. Cleanup remains scoped to the selected simulator.
