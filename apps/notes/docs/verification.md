# Verification

Verified on **2026-10-09** using XcodeBuildMCP, XCTest, strict Swift formatting, and the live serve-sim browser mirror.

## Physical-device installation

On **2026-10-09**, Notes Six **1.0 (1)** was built for and installed on the connected **iPhone Air running iOS 27.0.1**. The Debug device build used automatic signing with the existing development team supplied as an `xcodebuild` override; personal signing settings were not added to the Notes project. Strict code-signature verification passed, and the embedded provisioning profile includes the target device. The profile expires on **2026-10-16 at 14:22:34 UTC**; another signed installation is required to continue using this development build after expiration.

Installation and foreground launch completed through `devicectl`, with no demo/test arguments and no debugger attached. Independent process queries confirmed the normal Notes Six executable remained running as PID **8763**. A device screenshot showed the localized Home Screen icon; a subsequent foreground capture confirmed the Chinese note editor, paper-backed status area, leather navigation panel, and native keyboard rendered on the physical screen. These captures contain personal device content and are not stored in the project. No note text was changed by the installation or verification commands.

This verifies development signing, installation, independent launch, and the observed editor screen. It does not establish a complete physical-device regression, real Chinese IME composition, VoiceOver navigation, mail sending, or physical printer output. The previously documented simulator test results remain the regression evidence.

## Classic print options follow-up

The Print action now opens an app-owned full-screen Printer Options view based on Figure 5-3 of [Apple's archived Drawing and Printing Guide for iOS](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/Printing/Printing.html). A blue-gray shaded navigation bar, pinstripe background, white grouped rows, silver copies control, and dark blue Print button replace the modern system sheet. Printer selection uses the same classic treatment. The accepted notebook/status-area layout is unchanged.

The production path browses `_ipp._tcp` and `_ipps._tcp` services, reads each printer's Bonjour resource path, resolves its address, and checks availability with `UIPrinter.contactPrinter`. The app declares both Bonjour services and localized local-network permission explanations. Discovery cancellation invalidates pending callbacks, stops browsers/connections, and cancels timeout tasks. The Print button requires a selected printer. Copies are limited to 1–99. The full note is rendered as a paginated PDF and submitted directly to the chosen `UIPrinter`, with repeated documents for collated copies. The current operating system still owns permission prompts and print progress.

Automated printer-selection fixtures are guarded by `--uitesting` and cannot submit a job. The empty-discovery fixture also runs only under that guard. They verify selected destination state, localized labels, changing copies, unavailable-print recovery, returning from printer selection, cancellation, reopening with reset options, note preservation, and landscape control bounds. Unit tests validate Bonjour URL construction including scoped IPv6 and encoded resource names, copies limits, permission/resource configuration, and extraction of the first and last bilingual lines from a multi-page PDF. Existing Copy/paste, Mail-unavailable, font settings, and reader navigation/deletion tests cover the changed share entry and modal lifecycle.

| Scope | Device / runtime | Result |
| --- | --- | --- |
| Initial print implementation: 19 unit tests and 5 share/print/deletion UI tests | Air / iOS 26.2 | 24 passed, 0 failed, 0 skipped |
| Same 19 unit tests, plus Copy/paste, Mail recovery, deletion and landscape print UI | SE / iOS 17.5 | 23 passed; the selected-printer/error cancellation test needed the fixes below |
| Final selected-printer, copies, unavailable-print recovery, cancellation, and repeated presentation | Air / iOS 26.2 | 1 passed, 0 failed, 0 skipped |
| Final selected-printer/error cancellation and English landscape/empty-discovery flows | SE / iOS 17.5 | 2 passed, 0 failed, 0 skipped |

The final runs fix error-overlay hit testing after dismissal and clear the parent's print-presentation binding explicitly. The native full-screen modal owns input isolation; manually disabling the presenting view during the cover caused Air controls to remain unhittable after closing. Tests wait for dismissed controls to leave the hierarchy before interacting with the restored note. Air's landscape flow also passed after the explicit-binding change, before removal of the redundant parent input guard. All 19 unit tests and all 5 distinct affected UI flows have successful results on each device across these runs.

Result bundles:

- Air initial 24-test run: `test_sim_2026-10-09T13-46-25-255Z_pid72710_70c459cc.xcresult`.
- SE unit and other affected UI coverage: `test_sim_2026-10-09T13-48-39-480Z_pid72710_0a97257c.xcresult` (23 passed; its cancellation failure was resolved in the final run).
- Air final cancellation/reopening: `test_sim_2026-10-09T13-59-05-532Z_pid72710_ed1eb4d9.xcresult`.
- SE final printing flows: `test_sim_2026-10-09T14-00-13-839Z_pid72710_3a39bc63.xcresult`.

Final Swift source passes strict `swift-format` lint. English/Chinese string tables, permissions, app/project property lists, Python project generation, and source/documentation whitespace checks pass. Built app metadata contains both declared Bonjour services and the localized permission resources. Builds report only the toolchain's informational App Intents extraction warning for targets that do not use App Intents.

Native screenshots are in `screenshots/classic-print/iphone-air/` and `screenshots/classic-print/iphone-se/`; files containing `fixture` show deterministic test-only printers, not discovered physical devices. Real network discovery, physical printer contact, and paper output have not been verified against a printer. The direct printing implementation uses public APIs and single-sided/default printer handling; no paper-size, page-range, scaling, orientation, or duplex controls are implemented.

The final normal app was rebuilt and launched without UI-test or demo arguments on Air. Browser taps opened an existing note, the classic share panel, and the new Printer Options page. `screenshots/classic-print/browser-final.jpg` shows the real live serve-sim framebuffer and device identity. The browser remains open on that page. No printer selection, print submission, note edit, or deletion was performed on the normal notebook.

## Classic share panel follow-up

The current OS activity sheet has been replaced by an in-app iOS 6-style bottom panel. It has a dark shaded surface, three original vector icons (Mail, Print, Copy), embossed labels, and an independent glossy Cancel button. The panel slides vertically without a modern drag handle or contact-preview section. The existing leather navigation panel and body-backed status area are unchanged.

Copy writes the full note as plain text. Its integration test pastes that text through the editor's native Paste command into a new test note and compares the complete value, including line breaks. Tests also verify Cancel, backdrop dismissal, repeated opening, English/Chinese labels, preservation of the original note, landscape control bounds, the localized classic Mail-unavailable alert, system print preview, and closing print options without printing. A fading deletion confirmation no longer intercepts a subsequent toolbar tap.

| Scope | Device | Result |
| --- | --- | --- |
| All 16 unit tests, including bilingual resources and matching translation keys | Air / iOS 26.2 | 16 passed |
| Final share integration tests and page navigation/deletion regression | Air / iOS 26.2 | 4 passed, 0 failed, 0 skipped |
| Same integration and deletion tests on the minimum supported runtime and compact screen | SE / iOS 17.5 | 4 passed, 0 failed, 0 skipped |

Unit results are from the first share build; the final UI runs followed the transition and test adjustments. The updated Copy test uses explicit in-app pasting rather than reading another app's clipboard from the background test runner. System print cancellation supports both iOS 17's Cancel button and iOS 26's Close button.

Final UI result bundles:

- Air: `test_sim_2026-10-09T12-55-50-281Z_pid72710_a9246510.xcresult`
- SE: `test_sim_2026-10-09T12-57-38-035Z_pid72710_f7dd1c3a.xcresult`
- Unit results: `test_sim_2026-10-09T12-49-45-022Z_pid72710_157045f3.xcresult` (all unit tests passed; the initial UI failures were resolved in the final runs above).

Visual proof from this earlier share revision is in `screenshots/classic-share/iphone-air/` and `screenshots/classic-share/iphone-se/`: bilingual panels, landscape, the unavailable-mail alert, and former system print setup. All fixtures use the dedicated test notebook. Mail composition on a configured device, actual sending, and physical printing remain unverified. The subsequent classic printing revision above replaces the system options shown in these historical captures; mail composition remains a current OS component.

## Frame and deletion follow-up

The notebook follows the full-screen treatment in Weather Six's `CityManagerView`: a textured body background extending behind the system safe areas and a full-width navigation bar. The navigation bar remains its own leather panel. The status area uses the same body background as the current page: ruled yellow paper for notes, or gray pinstripes for accounts. System status content uses a dark style for readability. The body background also fills the bottom. Controls remain inside the safe area, with no outer card, horizontal gutter, or duplicated footer spacer. The device display supplies the outer corner shape. Weather source was read for reference and was not modified.

Confirming reader deletion snapshots the visible note page, folds a 280-facet textured surface into a shaded paper ball, and drops it into the opened bin. The original text, date, paper rules, and margin remain on the folding surface. The bin lid closes on completion and the next note appears, or the empty list appears after deleting the last note. Reduce Motion uses immediate deletion. Backgrounding or rotation safely completes a confirmed deletion and releases the display link and snapshot layers.

Deterministic test-only phase holds at 28%, 58%, and 84% provide visual attachments. They are enabled only with `--uitesting`; normal launches always play the animation. Tests exercise real timed deletion separately, including the last note in landscape. All test notebooks are separate from normal and demo notebooks.

| Follow-up scope | Device | Result |
| --- | --- | --- |
| Animation implementation: all 16 unit tests and 3 deletion UI tests | Air / iOS 26.2 | 19 passed |
| Complete animation regression: 16 unit tests and all 13 UI tests | SE / iOS 17.5 | 29 passed |
| Final full-screen layout: compact keyboard bounds, landscape editing, real animated deletion of all notes, phase captures, backgrounding, and rotation | Air / iOS 26.2 | 4 passed |
| Body-background continuity through the status area | Air / iOS 26.2 | Build and live-browser visual verification passed |
| Final Swift source and localization resources | Both app/test targets | Strict Swift lint, string-table validation, and whitespace checks passed |

All listed tests passed with zero failures or skips. The latest status-area change affects background painting and system text appearance; the full-screen geometry and deletion behavior from the final four UI tests are unchanged.

The status-area revision was rebuilt and checked in the live browser on Air. The paper-backed list and pinstripe-backed accounts were visually verified with dark status text. User note content and font preferences were not changed. Strict Swift lint and whitespace checks passed.

Latest visual proof is in `screenshots/full-screen-layout/`. `browser-final.jpg` shows the paper status background and the live simulator, and `browser-accounts.jpg` shows the matching pinstripe status background. The native phase captures show the folding page, paper ball, and entry into the bin; those captures precede the final status-area paint adjustment.

Follow-up result bundles:

- Animation implementation: `test_sim_2026-10-09T12-00-59-379Z_pid72710_0bd59f0c.xcresult`
- SE complete animation regression: `test_sim_2026-10-09T12-03-18-688Z_pid72710_31d98975.xcresult`
- Final full-screen layout: `test_sim_2026-10-09T12-23-21-805Z_pid72710_db50c0f4.xcresult`

## Initial implementation results

| Device / runtime | Scope | Result |
| --- | --- | --- |
| iPhone Air / iOS 26.2 | Complete initial suite: 14 unit tests + 8 UI tests | 22 passed, 0 failed, 0 skipped |
| iPhone Air / iOS 26.2 | Final page-curl change, long-note persistence, landscape reading/editing, and confirmed deletion | 3 passed, 0 failed, 0 skipped |
| iPhone SE (3rd generation) / iOS 17.5 | Complete final suite: 14 unit tests + 10 UI tests | 24 passed, 0 failed, 0 skipped |
| Air and SE | Full-screen landscape screenshot capture after orientation normalization | 1 passed on each device |
| Notes source, both test targets, and icon generator | `swift-format lint --recursive --strict` | Passed |
| English/Chinese resource tables and Home Screen names | Property-list validation and unit tests | Passed |
| Project and serve-sim scripts | Python compilation and `bash -n` | Passed |

The successful build/test runs reported no compiler warnings or SwiftUI state-update warnings. Air's final 24 distinct tests were covered across the complete suite and focused additions; the final 24-test suite ran together on SE. No network-dependent or optional tests were skipped.

## Coverage

- Create, edit, immediately save, reload, and delete notes.
- First nonempty line titles and most-recent-edit ordering, preserving creation dates.
- Body search, case/diacritic-insensitive search, Chinese search, no results, and cancellation.
- Empty draft removal, note counts, previous/next boundary states, and navigation after confirmed deletion.
- Horizontal swipe-to-delete without accidentally opening the note; vertical list scrolling without triggering row actions.
- Long notes across scrolling, page changes, app termination, and relaunch.
- All three original font names are available; font preferences persist and the settings selection updates.
- English and Chinese launch-language flows, localized controls/counts/timestamps/Home Screen names, resource-key parity, unsupported-language fallback, and preserving user content when the UI language changes.
- Classic share panel, full-note Copy verified through native Paste, repeated opening/cancellation, classic printer options/selection, and print cancellation. Sending mail and printing to a physical printer were not tested.
- Portrait/landscape reading and editing, keyboard dismissal, compact-screen control bounds, and available editor space above the keyboard.
- Corrupt and unsupported archive preservation, save failure retaining the in-memory text, and successful retry after the storage obstacle is removed.

## Visual and browser proof

The classic layout was compared with Apple's iOS 6 User Guide, Chapter 17, pages 86–87. Native drawings provide the leather grain, embossed controls, torn page edge, ruled yellow paper, double margin, and legal-pad icon. Default English text uses Noteworthy; Chinese text uses the system font's appropriate glyph fallback.

Initial screenshots in `screenshots/iphone-air/` and `screenshots/iphone-se/` include English/Chinese lists and details, the keyboard, font settings, the classic deletion panel, the former system share sheet, long notes, and landscape layouts. The current share panel is documented in `screenshots/classic-share/`. Landscape captures use the complete screen and normalize image orientation before PNG encoding, avoiding UIKit app-window cropping and EXIF rotation artifacts.

The browser screenshots show a real, live iPhone Air framebuffer, with its device identity and live indicator. Browser taps opened the note; rotation changed the app to landscape and back. The stream was run with **serve-sim 0.1.47**, pinned to the Air UDID, with scoped cleanup and an exit trap. A sandboxed shell could not connect to CoreSimulator, so the mirror was started with the required simulator access. An Xcode 27 input-connection issue was repaired using serve-sim's documented `repair-input` command, followed by a scoped mirror restart. Browser clicks then worked.

- `screenshots/browser-zh-list.jpg`
- `screenshots/browser-zh-detail.jpg`
- `screenshots/browser-zh-landscape.jpg`

The final preview is `http://localhost:3200/`. Its terminal must remain running while the mirror is in use. The launch script is `scripts/serve_sim.sh`; it only cleans up the simulator passed to it.

## Reproducible result bundles

Result bundles are stored by XcodeBuildMCP under the local workspace's `result-bundles/` directory:

- Air complete suite: `test_sim_2026-10-09T11-29-32-230Z_pid72710_74fba9b9.xcresult`
- Air final feature regressions: `test_sim_2026-10-09T11-32-54-997Z_pid72710_b4f9ac91.xcresult`
- SE complete final suite: `test_sim_2026-10-09T11-34-29-623Z_pid72710_1bcf9d4f.xcresult`
- SE normalized landscape capture: `test_sim_2026-10-09T11-39-19-045Z_pid72710_fc0e9b41.xcresult`
- Air normalized landscape capture: `test_sim_2026-10-09T11-39-49-606Z_pid72710_3ddd37c1.xcresult`

UI tests have their own notebook. They do not clear normal or demo notes and do not change the simulator's preferred system language.

## Scope and limits

- iPhone, iOS 17 or later; a dedicated iPad layout is not provided.
- Local storage only. iCloud and mail-account synchronization are not implemented.
- Status bars, keyboards, selection menus, mail composition, local network permission prompts, and print progress use the current operating system. Printer Options, printer selection, the share-entry panel, and unavailable-service alerts are custom classic views.
- Native page-curl transitions approximate the classic motion and honor Reduce Motion. The reader's paper-crumpling deletion animation is an original mesh-based recreation, not Apple's historical private implementation; list-row deletion retains the list interaction.
- Font settings live inside the app rather than in the historical system Settings layout.
- Physical-device development signing, installation, independent launch, and the observed editor screen are verified above. Release signing, VoiceOver navigation with a screen reader, and real Chinese IME composition were not manually tested. Automated tests entered and persisted Chinese strings; the editor avoids applying style changes during marked-text composition.
- Weather source and its Xcode project were not modified. The collection workspace and root README register the new independent Notes project.
