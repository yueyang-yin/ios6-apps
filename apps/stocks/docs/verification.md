# StocksSix verification

Verified on 17 October 2026 in the collection checkout. The [latest visual refinement](#compact-footer-and-bottom-continuity) below addresses the browser comments about the bottom seam and oversized footer. The final browser preview runs the normal Chinese-language app with provider data, not the demo fixture.

## Build and test evidence

| Environment | Verification | Result |
| --- | --- | --- |
| iPhone Air / iOS 26.2 | Complete suite: 13 unit tests and 8 UI tests | 21 passed, 0 failed, 0 skipped |
| iPhone Air / iOS 26.2 | Final compact-row geometry assertion and portrait interactions | 1 passed, 0 failed, 0 skipped |
| iPhone SE, 3rd generation / iOS 17.5 | Complete suite before the final comparison-order test was added | 20 passed, 0 failed, 0 skipped |
| iPhone SE / iOS 17.5 | Provider decoding, chronological comparison ordering, and two-finger landscape interaction after chart refinement | 6 passed, 0 failed, 0 skipped |
| iPhone SE / iOS 17.5 | Final portrait geometry, Chinese summary/news, and management after compact-row refinement | 2 passed, 0 failed, 0 skipped |
| iPhone Air / iOS 26.2 | Final build, install, and normal Chinese launch | Succeeded; build tool reported no warnings or errors |
| Source/resources | Strict swift-format, bilingual resource checks, plist/project validation, Python syntax, and whitespace | Passed |

Result bundles are under `~/Library/Developer/XcodeBuildMCP/workspaces/ios6-apps-5274783ae1de/result-bundles/`:

- Air complete suite: `test_sim_2026-10-17T10-39-20-486Z_pid36588_b5504162.xcresult`
- Air final portrait: `test_sim_2026-10-17T10-41-18-662Z_pid36588_5d1e41f8.xcresult`
- SE complete suite: `test_sim_2026-10-17T10-36-45-875Z_pid36588_2e0cb951.xcresult`
- SE chart refinement: `test_sim_2026-10-17T10-38-51-004Z_pid36588_9e904c21.xcresult`
- SE final portrait and Chinese panels: `test_sim_2026-10-17T10-41-34-307Z_pid36588_265359cd.xcresult`

The first build inherited Finder/file-provider metadata inside its build product, which codesign rejected. Building in `/private/tmp/StocksSix-DerivedData` resolved that environment issue. The discarded intermediate build directory was removed from the source checkout. No signing checks were disabled.

## Functional coverage

The tests cover all seven ranges; stock selection; cycling price/percent/capitalization; summary and news pages; quick horizontal page swipes; adding and canceling search; empty search results; duplicate protection; deletion; drag reordering; an empty watchlist and direct search recovery; persistence after relaunch; both landscape orientations; single-finger inspection; and a real synthesized two-finger gesture producing a highlighted interval and percentage.

Unit checks cover Yahoo chart null prices and unequal array lengths, provider failure, missing metrics, daily-versus-historical baselines, cached quote preservation after failure, responses arriving after a selection change or removal, comparison finger-order independence, and local persistence. English, Simplified Chinese, Traditional Chinese mapped to Simplified Chinese, and unsupported-language fallback are exercised. Both resource tables contain 96 matching keys with matching format placeholders; Home Screen names have English and Simplified Chinese resources.

UI testing uses its own resettable UserDefaults domain. Demo prices, curves, and sample headlines are visibly labeled and isolated from normal data.

## Visual evidence

The [Apple iOS 6 manual](https://cdsassets.apple.com/live/6GJYWVAV/user/ma1658_iphone_ios6_user_guide.pdf), pages 91–92, was rendered and inspected. The supplied conversation's image tokens were not downloadable attachments. The implementation follows the manual's main composition, range selector, information paging, value cycling, and landscape inspection rather than introducing a modern navigation title or tab bar.

Inspected screenshots show the pinstripe watchlist and real status bar, glossy changes and selected row, price/volume chart, summary, news, linen management, search keyboard, empty state, and both rotation directions. Top and bottom body continuity and modern safe areas were checked together. On SE, the final layout keeps all seven default rows fully visible; larger row sizes use a whole-row scroll viewport.

| Evidence | Files |
| --- | --- |
| Final English portrait | [Air](screenshots/iphone-air/en-portrait.png), [SE](screenshots/iphone-se/en-portrait.png) |
| Chinese portrait | [Air](screenshots/iphone-air/zh-portrait.png), [SE](screenshots/iphone-se/zh-portrait.png) |
| Chinese summary and news | [Air summary](screenshots/iphone-air/zh-summary.png), [SE summary](screenshots/iphone-se/zh-summary.png), [Air news](screenshots/iphone-air/zh-news.png) |
| Management and keyboard | [Air management](screenshots/iphone-air/zh-management.png), [SE management](screenshots/iphone-se/zh-management.png), [Air search](screenshots/iphone-air/en-search-keyboard.png), [SE search](screenshots/iphone-se/en-search-keyboard.png) |
| Landscape and comparison | [Air comparison](screenshots/iphone-air/en-landscape-comparison.png), [SE comparison](screenshots/iphone-se/en-landscape-comparison.png), [Air Chinese](screenshots/iphone-air/zh-landscape.png), [SE Chinese](screenshots/iphone-se/zh-landscape.png) |
| Empty-state recovery | [Air](screenshots/iphone-air/en-empty.png), [SE](screenshots/iphone-se/en-empty.png) |
| Real provider data in the live browser | [Quotes and chart](screenshots/browser-live-stocks.png), [News](screenshots/browser-live-news.png) |

SE landscape attachments were normalized to their displayed orientation. Other screenshots retain their captured pixels.

## Live data and simulator browser

The real Yahoo chart and search endpoints returned valid responses. Normal-mode execution inside Simulator then displayed current provider quotes, a six-month AAPL chart, localized quote timestamps, and actual publisher headlines. Provider values are time-specific observations, not guaranteed real-time exchange prices. Missing capitalization remains `—` rather than a fabricated value.

The scoped serve-sim helper is attached to Air UDID `E092AACD-B2F6-493E-8BAE-E9D7A704ABD8`. The Codex side browser at `http://localhost:3200` showed **live** and rendered actual frames. A pointer click in the mirror opened stock management and Done returned to quotes; page-dot interaction also loaded actual news. The final preview tab is retained for the user, and its server terminal remains running.

XcodeBuildMCP's standalone runtime snapshot returned no semantic targets on this setup; native XCTest supplied the semantic UI evidence. The serve-sim text-size and Reduce Motion switches were disabled, so runtime toggling of those settings was not claimed. Code reads Reduce Motion to suppress transitions and uses scalable fonts/row sizing; a full VoiceOver and maximum accessibility-text-size audit was not performed. No physical-device run was requested or performed.

The independent app stores watchlists locally; iCloud synchronization and the retired built-in Notification Center ticker are not implemented. Current system keyboards and URL-sharing surfaces remain system owned. See the [README](../README.md) for data-source constraints and supported behavior.

## Watchlist colors and panel width refinement

The browser comments identified two visible differences. The Apple manual screenshot shows alternating muted-blue and gray-blue rows plus a separate navy selection; normal rows previously shared the same transparent background. The quote list now paints both base tones by visible row position while keeping stable symbol identity and the independent selected treatment.

The information container previously had 5-point horizontal and top padding and rounded top clipping, which exposed strips of the body texture. Those insets and rounded clipping have been removed. The chart, summary, news, range bar, and footer share a full-width rectangular panel. Internal plot/axis spacing and the separate body safe-area surface remain intentional.

| Device | Affected UI regressions | Result |
| --- | --- | --- |
| iPhone Air / iOS 26.2 | Portrait selection/ranges/value cycling, Chinese summary/news/management, paging/reordering, and landscape inspection/comparison/return | 4 passed, 0 failed, 0 skipped |
| iPhone SE / iOS 17.5 | The same four affected regressions | 4 passed, 0 failed, 0 skipped |

The portrait test also asserts that the first and last range controls and the footer's information control reach the corresponding screen edges. Screenshot inspection on both devices confirms three visible row treatments and filled side edges in all three information pages, including after reordering. Strict swift-format, resource consistency, and whitespace checks passed.

Result bundles under the same XcodeBuildMCP result directory:

- Air: `test_sim_2026-10-17T10-50-15-992Z_pid36588_00524dba.xcresult`
- SE: `test_sim_2026-10-17T10-51-26-268Z_pid36588_74944c11.xcresult`

Latest evidence: [Air portrait](screenshots/watchlist-panels/iphone-air/zh-portrait.png), [Air summary](screenshots/watchlist-panels/iphone-air/zh-summary.png), [Air news](screenshots/watchlist-panels/iphone-air/zh-news.png), [Air reordered](screenshots/watchlist-panels/iphone-air/en-reordered.png), [SE portrait](screenshots/watchlist-panels/iphone-se/zh-portrait.png), [SE summary](screenshots/watchlist-panels/iphone-se/zh-summary.png), [SE news](screenshots/watchlist-panels/iphone-se/zh-news.png), and the [retained live browser](screenshots/watchlist-panels/browser-final.png).


## Compact footer and bottom continuity

The main footer now uses a 48-point scaled height at the default text size, reduced from 88 points. Quote status and date sit above the three page indicators within the same compact panel. The chart receives the recovered 40 points; the watchlist and chart-range bar retain their proportions. Yahoo and information controls retain 48-point targets, and the page buttons retain 44-point-wide targets. Pull-to-refresh remains available; holding a page indicator presents Refresh Quotes, also exposed as a localized accessibility action.

The footer gradient continues through the modern bottom safe area. Only the decorative background ignores the bottom safe area; controls stay above it. Clipping belongs to the paged content rather than its footer container, so no pale pinstripe strip reappears below the panel. Management retains its independent linen surface. This explicit Stocks treatment follows the user's reviewed visual preference and overrides the shared guide's default matching top/bottom material.

Affected verification on the compact layout:

| Device | Checks | Result |
| --- | --- | --- |
| iPhone Air / iOS 26.2 | Portrait geometry, all ranges, stock/change selection; landscape inspection/comparison/return | 2 passed |
| iPhone Air / iOS 26.2 | Chinese summary/news/management, page-indicator refresh menu and return | 1 passed |
| iPhone SE / iOS 17.5 | The same portrait and landscape checks | 2 passed |
| iPhone SE / iOS 17.5 | Chinese summary/news/management, refresh menu and return | 1 passed |

Result bundles in the directory listed above:

- Air portrait/landscape: `test_sim_2026-10-17T10-59-04-754Z_pid36588_d47a1e46.xcresult` (these two checks passed; its intermediate refresh-menu test failed and was corrected).
- Air final Chinese/menu flow: `test_sim_2026-10-17T11-06-29-538Z_pid36588_e16abd59.xcresult`.
- SE portrait/landscape: `test_sim_2026-10-17T11-03-59-061Z_pid36588_52ee060f.xcresult` (these two checks passed; its immediate post-menu hit-test failed).
- SE final Chinese/menu flow: `test_sim_2026-10-17T11-05-44-722Z_pid36588_d797d391.xcresult`.

The menu test presses the visible indicator and waits for the menu dismissal animation before checking the restored controls. iOS 26 emitted UIKit context-menu reparenting warnings during this passing flow; no app crash or failed assertion remained. No complete suite rerun is claimed for this visual-only refinement.

Both devices' final portrait, summary, news, refresh-menu, and management captures were inspected. The normal Chinese app was relaunched in the retained live browser, confirming the enlarged chart and continuous lower surface with provider data.

Latest captures: [Air chart](screenshots/compact-footer/iphone-air/zh-portrait.png), [SE chart](screenshots/compact-footer/iphone-se/zh-portrait.png), [Air summary](screenshots/compact-footer/iphone-air/zh-summary.png), [SE summary](screenshots/compact-footer/iphone-se/zh-summary.png), [Air news](screenshots/compact-footer/iphone-air/zh-news.png), [SE news](screenshots/compact-footer/iphone-se/zh-news.png), [Air refresh menu](screenshots/compact-footer/iphone-air/zh-refresh-menu.png), [SE refresh menu](screenshots/compact-footer/iphone-se/zh-refresh-menu.png), [Air management](screenshots/compact-footer/iphone-air/zh-management.png), [SE management](screenshots/compact-footer/iphone-se/zh-management.png), and [live browser](screenshots/compact-footer/browser-final.png).
