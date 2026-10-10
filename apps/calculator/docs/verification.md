# CalculatorSix verification

Verified on 2026-10-10 with XcodeBuildMCP and the live serve-sim browser mirror. The app is independently registered in `iOS6Apps.xcworkspace` under the `CalculatorSix` scheme.

## Final automated results

| Simulator | Runtime | Unit tests | UI tests | Failed | Skipped | Result bundle |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| iPhone Air | iOS 26.2 | 26 | 4 | 0 | 0 | `/private/tmp/CalculatorSix-LCD-Refined-Air.xcresult` |
| iPhone SE (3rd generation) | iOS 17.5 | Not repeated | 4 | 0 | 0 | `/private/tmp/CalculatorSix-LCD-Refined-SE.xcresult` |

The final no-automatic-parentheses and larger-summary refinement passed 34 scoped test executions: all 26 unit tests on Air, plus the four affected UI flows on both runtimes. These UI flows cover input/result presentation, editing, rotation, long-expression scrolling, explicit scientific parentheses, Copy/Paste, and the largest accessibility text category. Before that small refinement, the LCD phase redesign passed the full 25-unit/8-UI suite on both runtimes (66 executions), saved in `/private/tmp/CalculatorSix-LCD-Air.xcresult` and `/private/tmp/CalculatorSix-LCD-SE.xcresult`.

Build/run succeeded, strict `swift-format` lint passed for the changed Swift sources/tests, and `git diff --check` passed. Localization plist validation, Python syntax, asset JSON, and mirror-script shell syntax checks passed during the earlier implementation; these unchanged resources/scripts were not revalidated for the LCD change. Weather and Notes source files were not modified; their unrelated suites were not rerun.

Unit coverage includes arithmetic and repeated equals; basic immediate evaluation versus scientific precedence; right-associative powers; operator replacement and missing operands; C/AC and memory; decimal/sign/negative-zero input and limits; deletion/paste validation; equals ending entry; constants retaining underlying Double precision; nested parentheses and implicit multiplication; percentages/markups/discounts; powers, roots, factorials; degrees/radians and inverse trigonometry; logarithms/exponentials and all hyperbolic inverses; EE input and overflow; random bounds; invalid domains and recovery; saved-expression/preferences restoration; language selection and translation-resource completeness.

UI coverage includes English and Simplified Chinese portrait arithmetic, repeated equals, memory indicators, C/AC, localized errors and recovery, digit deletion, landscape rotation preserving a pending calculation, scientific parentheses and 2nd functions, both landscape directions, hit-target geometry, unsupported-language fallback, actual Copy/Paste menus, and long numbers with the largest accessibility text category.

The first run exposed a negative-zero entry issue and constant precision loss; both were fixed and covered by regression tests. Screenshot review also caught LCD glyph cropping at the largest text size on compact landscape. Fonts now scale within the available LCD/key height; the final captures below show the repaired layout.

## Initial recreation captures

These real simulator screenshots were exported from the initial recreation's XCTest bundles, before the expression-line addition. They preserve the original material/layout review against the historical references linked in the app README. Current LCD presentation captures are recorded below.

| State | iPhone Air | iPhone SE |
| --- | --- | --- |
| English portrait and memory ring | [Capture](screenshots/iphone-air/en-portrait-memory.png) | [Capture](screenshots/iphone-se/en-portrait-memory.png) |
| English scientific / 2nd | [Capture](screenshots/iphone-air/en-landscape-scientific.png) | [Capture](screenshots/iphone-se/en-landscape-scientific.png) |
| Chinese error | [Capture](screenshots/iphone-air/zh-portrait-error.png) | [Capture](screenshots/iphone-se/zh-portrait-error.png) |
| Chinese landscape left | [Capture](screenshots/iphone-air/zh-landscape-left.png) | [Capture](screenshots/iphone-se/zh-landscape-left.png) |
| Chinese landscape right | [Capture](screenshots/iphone-air/zh-landscape-right.png) | [Capture](screenshots/iphone-se/zh-landscape-right.png) |
| Largest accessibility text, portrait | [Capture](screenshots/iphone-air/zh-large-text-portrait.png) | [Capture](screenshots/iphone-se/zh-large-text-portrait.png) |
| Largest accessibility text, landscape | [Capture](screenshots/iphone-air/zh-large-text-landscape.png) | [Capture](screenshots/iphone-se/zh-large-text-landscape.png) |
| French preference / English fallback | [Capture](screenshots/iphone-air/fallback-portrait.png) | [Capture](screenshots/iphone-se/fallback-portrait.png) |

## Live browser mirror

The mirror is scoped to iPhone Air `E092AACD-B2F6-493E-8BAE-E9D7A704ABD8` and served at `http://localhost:3200`. Its terminal was left running for the user's requested live view. Browser state showed **live**, and a real calculator frame was captured in [portrait](screenshots/browser-portrait.jpg) and [landscape](screenshots/browser-landscape.jpg). The browser Rotate device control was used to switch to the actual scientific layout and back.

The calculator was launched with `--uitesting` and Simplified Chinese preferences, keeping this interactive preview separate from the user's normal saved calculator state. The final LCD inspection leaves the calculator foregrounded with `7 × 7 =` and `49` in the existing live mirror. Normal app launches persist calculations and memory. The mirror is local to this machine and must remain running; the screenshots remain usable after it stops.

## Boundaries and diagnostics

- This is newly written SwiftUI code for modern iOS, not the original Apple executable or an iOS 6 deployment target. Its interface materials are original drawings; the icon is a reference-guided imagegen redraw. Historical source screenshots are reference-only.
- Device status content, screen geometry, landscape system-status visibility, the home indicator, clipboard menus, and paste prompts are provided by the current OS. No duplicate status bar or device mask is drawn inside the app.
- The iOS 26.2 Copy/Paste UI test emitted system context-menu hosting warnings naming `_UIGravityWellEffectAnchorView` and `_UIReparentingView`. Both menu actions and subsequent calculator interaction passed. The app does not instantiate these private classes. The SE/iOS 17.5 final suite reported no test warnings.
- Xcode's App Intents metadata processor reported that extraction was skipped because this calculator does not depend on AppIntents; it is not a compiler error.
- After XCTest finished, the live XcodeBuildMCP semantic snapshot helper returned an empty hierarchy; this is recorded separately from the passing XCTest label/hit-target assertions. Browser frame rendering and rotation remained available.
- Accessibility labels, selected states, named deletion, hit areas, and large text were verified. A human VoiceOver listening session was outside this simulator task. Physical-device delivery was subsequently verified in the section below. Reduce Motion is honored by the key style; it was reviewed in source rather than timed in a device session.
- IEEE-754 numerical limits and app-specific entry limits are documented in the README. State restoration was tested with isolated UserDefaults, not by modifying existing user data.

## Earlier app icon margin revision

On 2026-10-10 the icon was refined into the historical four-key composition: silver perimeter, textured dark leather, three warm gray keys, and an amber equals key at bottom right. The final edit starts from the original detailed four-key master. It removes the exterior black safety margin, restores defined leather grain and key highlights, and extends silver material to the square canvas boundaries so iOS supplies the outer mask. The master and exact built-in imagegen prompt are saved in [artwork](../artwork/README.md).

The final production icon is 1024 × 1024, RGB, fully opaque. Asset JSON and image-format checks passed. XcodeBuildMCP rebuilt, installed, and launched CalculatorSix on iPhone Air/iOS 26.2 successfully. The installed result was visually inspected in the [original-resolution Home Screen PNG](screenshots/icon-corners-home-screen.png): no exterior black margin, continuous silver corner transitions, visible leather grain, and glossy embossed keys. The [browser capture](screenshots/icon-corners-browser.jpg) and [Home Screen row detail](screenshots/icon-corners-detail.jpg) show the live mirror after installation. This final refinement changes artwork and documentation only; the calculator Swift sources were unchanged, so the earlier arithmetic/UI suites were not repeated.

AppIcon SHA-256: `914990ebd275c4101c844972349095727b591b6ce6b38a075df293ec6f4a7095`.

## LCD input and result presentation

On 2026-10-10 the LCD was revised into two presentation phases. Input shows the full expression as the sole large line, including `7 × 7`. Equals moves `7 × 7 =` into the upper LCD summary and shows `49` in large type below it. Clear and a new calculation return to the single-line state, eliminating the duplicate initial zero. Standalone scientific functions can finish a calculation; functions inside a pending calculation remain part of the large input expression.

The final refinement removes automatic grouping parentheses from ordinary chained arithmetic and preserves explicit user-entered parentheses, including nested groups. Basic immediate evaluation and scientific precedence are unchanged. The upper summary is slightly larger in portrait and landscape, while remaining constrained to the available LCD height. Helvetica Neue Light numerals, olive ink, an etched highlight, and restrained inset shading maintain the classic LCD hierarchy.

Long input first shrinks within a readable limit, then scrolls horizontally while following new entry. Swiping an overflowing line reviews the expression; swiping a fitting line can still delete the last digit. The named accessibility deletion action remains available. VoiceOver exposes the full expression with localized English/Simplified Chinese labels. Expression text and presentation phase persist with numeric state, and optional saved fields preserve compatibility with older states.

The screenshots below are exported from the final scoped XCTest bundles. They cover the cleared LCD, both input/result phases, scientific rotation, long formulas, and the largest accessibility text category.

| State | iPhone Air | iPhone SE |
| --- | --- | --- |
| Cleared, single zero | [Capture](screenshots/lcd/iphone-air/zh-lcd-single-zero.png) | [Capture](screenshots/lcd/iphone-se/zh-lcd-single-zero.png) |
| Large `7 × 7` input | [Capture](screenshots/lcd/iphone-air/zh-expression-entry.png) | [Capture](screenshots/lcd/iphone-se/zh-expression-entry.png) |
| Upper `7 × 7 =` and large `49` | [Capture](screenshots/lcd/iphone-air/zh-expression-result.png) | [Capture](screenshots/lcd/iphone-se/zh-expression-result.png) |
| Large scientific input | [Capture](screenshots/lcd/iphone-air/zh-expression-landscape-entry.png) | [Capture](screenshots/lcd/iphone-se/zh-expression-landscape-entry.png) |
| Scientific result | [Capture](screenshots/lcd/iphone-air/zh-expression-landscape.png) | [Capture](screenshots/lcd/iphone-se/zh-expression-landscape.png) |
| Long input, scrolled toward the beginning | [Capture](screenshots/lcd/iphone-air/en-expression-scroll-start.png) | [Capture](screenshots/lcd/iphone-se/en-expression-scroll-start.png) |
| Long expression after equals, following the end | [Capture](screenshots/lcd/iphone-air/en-expression-scroll-result.png) | [Capture](screenshots/lcd/iphone-se/en-expression-scroll-result.png) |
| Largest text, portrait | [Capture](screenshots/lcd/iphone-air/zh-large-text-portrait.png) | [Capture](screenshots/lcd/iphone-se/zh-large-text-portrait.png) |
| Largest text, landscape and pi | [Capture](screenshots/lcd/iphone-air/zh-large-text-landscape.png) | [Capture](screenshots/lcd/iphone-se/zh-large-text-landscape.png) |

The existing serve-sim browser stream remained live after the final build/install. Device Hub taps entered `7 × 7` and then evaluated it. The [input LCD detail](screenshots/lcd/browser-input-detail.png), [result LCD detail](screenshots/lcd/browser-result-detail.png), and [final browser frame](screenshots/lcd/browser-final.png) capture both phases of that interaction. The actual system status area remains visible above the LCD; the browser tab was retained for continued use.

## App icon corner-contour refinement

On 2026-10-10 the user supplied a magnified Home Screen capture showing remaining imperfections in the four metal corners. Two built-in imagegen edits revised the peripheral leather aperture and silver-bezel highlights while retaining the four-key composition and tactile interior. The second edit uses the installed first-pass capture as diagnostic reference and targets the narrowed corner highlights. Previous masters and exact prompts are retained in [artwork](../artwork/README.md).

The final production asset is 1024 × 1024, RGB, and opaque; its asset-catalog JSON passed validation. XcodeBuildMCP built, installed, and launched the updated app on iPhone Air/iOS 26.2 successfully. The [original-resolution Home Screen PNG](screenshots/icon-contour-home-screen.png) and [magnified native Device Hub capture](screenshots/icon-contour-final-zoom.jpg) were inspected for continuous corner turns, smoother metal highlights, retained leather grain, and intact keys. This is a visual inspection, not a claim of a mathematically exact private system-mask contour. The [live browser capture](screenshots/icon-contour-browser.jpg) records the retained mirror in the Home Screen state.

The temporary native zoom and browser sizing changes were restored. Serve-sim remained live on the same Air simulator at `http://localhost:3200/`. This refinement changes artwork and documentation only; Swift calculator sources and evaluation behavior are unchanged, so the passing arithmetic/UI suites above were not repeated. `git diff --check` passed.

Current AppIcon SHA-256: `1ecb86d089b8a9fd68410e1a007388ece634947846a5c572adf7809205f9c4bd`.

## Simulator input repair and physical-device delivery

On 2026-10-10 the existing iPhone Air mirror streamed frames but did not forward browser input. The old scoped serve-sim session was stopped, the official `repair-input` command was run for that Air simulator, and `scripts/serve_sim.sh` restarted the scoped mirror at `http://localhost:3200/`. The existing Codex in-app browser tab was reloaded and retained. Browser pointer clicks cleared the LCD, entered `7`, then entered `× 7 =`; the frame changed to the upper `7 × 7 =` summary and the large `49` result. This browser interaction was repeated after physical-device deployment, confirming actual input forwarding as well as the live stream. The [full browser capture](screenshots/connection/browser-touch-working.jpg) and [LCD detail](screenshots/connection/browser-touch-detail.jpg) record the result. The server was left running for continued use.

CalculatorSix automatic signing was configured for the existing Personal Team. After the user signed into Xcode, `xcodebuild -allowProvisioningUpdates` generated the calculator's own development provisioning profile and successfully built the Debug iPhoneOS app. The profile includes the connected iPhone and expires on 2026-10-17. Xcode's run request also eventually returned a successful launch with no build errors.

The signed app was installed on **Max’s iPhone Air, iOS 27.0.1**, and launched with CoreDevice using bundle ID `com.yinyueyang.calculatorsix`. The launch result confirms foreground activation, an empty argument list, and `startStopped: false`. No debugger, UI-testing flag, or language override was used for this physical launch, so normal saved state and device/app language preferences apply. An independent CoreDevice process query subsequently found the installed CalculatorSix executable running as PID `12777`. The scoped install, launch, and process JSON results are retained locally under `/private/tmp/calculator-device-*.json`.

This verifies installation and normal process startup on the phone; it does not claim a human visual retest of every physical-device flow. No Swift calculator source changed during this connection/signing task, so the passing arithmetic/UI regression suites above were not repeated. The device build and `git diff --check` passed.
