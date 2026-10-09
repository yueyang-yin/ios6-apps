# Shared iOS 6 Design Language

This document records reusable visual and interaction conventions for this collection. It preserves the approved Notes framing and the Weather city-management reference so later recreations can use appropriate patterns without depending on chat history. Read it before app UI work, then decide which conventions fit the screen.

These are repository conventions for recreating classic apps on modern devices. They are not a universal screen template or a claim that every historical iOS 6 screen used identical materials, dimensions, or status bars. An explicit user instruction takes precedence over these defaults. Preserving the original app and screen's character takes priority over making every screen look alike.

## Apply patterns selectively

Use this language where it helps the particular screen. Do not add a navigation panel, texture, grouped list, or common frame just because it appears in this guide.

| Screen type | Treatment |
| --- | --- |
| Notes list/reader, accounts, classic printer options | Use the approved continuous body background and independent navigation panel |
| Weather city-management, applicable detail/information or settings screens | Reuse the matching framing and classic control patterns where the screen has navigation and a body surface |
| Weather's main forecast screen | Preserve the original forecast composition, glass border, weather artwork, paging, and app-specific chrome; do not impose the Notes/settings frame |
| Other specialized main screens, such as a camera viewfinder, map, calculator, or dial pad | Follow their own historical structure; adopt only individual materials, controls, or behaviors that fit |

Classify by the actual screen structure and reference, not simply whether a view is named "Detail" or "Settings." A screen without a navigation bar does not need one added. A historical content panel with rounded glass edges may retain them. If no pattern here fits, keep the screen's own design and document its reference and adaptation. A new app may use different patterns on its main page and supporting pages.

## Screen framing

For screens that use the Notes/settings-style frame, separate three responsibilities: a continuous body surface, an independent navigation panel, and safe-area-aware content and controls. The rules below apply to that frame; they do not replace specialized main-page layouts.

1. Extend the current screen's body background behind the system status area. Its color, texture, and relevant pattern must continue through that area. A yellow paper page has a yellow paper status background; a gray pinstripe page has a gray pinstripe status background; a dark linen page has a dark linen status background.
2. Keep the navigation bar as an independent panel below the status area. Notes uses brown leather; Weather management uses a dark glossy panel; classic printer settings use blue-gray chrome. Do not extend the navigation material upward merely to fill the status area.
3. Fill the display behind the bottom safe area with the body surface. Avoid an unpainted strip, a duplicated footer spacer, or a second background whose edge appears above the home indicator.
4. Keep text, interactive controls, and scrolling content clear of the status area, Dynamic Island/notch, home indicator, and keyboard. Extending a decorative background does not authorize extending controls into those regions.
5. Let the device display supply the screen's outer corners. Do not add an inset rounded wrapper, top/bottom cap, black gutter, or duplicate device mask merely to imitate the simulator frame or force a common template. Historically appropriate content panels, such as Weather's rounded glass forecast panel, and individual grouped lists/buttons may retain their own corners.
6. Keep the framing consistent in portrait and landscape. A landscape notch may require control insets; it must not reveal gaps in the decorative body background.

Use the real system status bar. Dark time and icons suit light paper and gray pinstripes; light time and icons suit dark linen or other dark surfaces. Select their appearance for contrast with the body behind them. Do not draw duplicate status text, a fake notch/Dynamic Island, or a fake home indicator.

Within this frame, the status background is determined by the active screen, including a presented settings screen. It is not permanently tied to the app's main-page material. Specialized main screens may retain their own historically informed status/chrome treatment, with readable real system content and modern device compatibility.

## Material and depth

Treat materials as functional surfaces: paper carries written content, leather or shaded chrome forms navigation panels, linen supports management/settings screens, and glass or metal gives controls visible depth. Select materials from the app's historical reference rather than applying brown leather to every app.

- Use subtle, stable grain or fibers at the appropriate scale. Textures should remain consistent during editing, scrolling, and state changes rather than regenerating random noise.
- Preserve pattern alignment at the boundary between the body and status area. Paper rules and margins must still align with the content they organize; a separately restarted texture must not create a visible seam.
- Use a consistent light source: light along upper edges, darker lower edges, restrained inset lines, and small contact shadows. Embossed light navigation text usually has a dark shadow just above its baseline; dark text on light controls may have a fine light edge below.
- Give buttons a filled surface, bevel/border, and visible pressed/disabled states. Use the app's classic back-arrow shape and glossy primary action treatment where the historical reference supports them.
- Keep fine texture and shading subordinate to readable text. Avoid heavy blur, oversized floating shadows, translucent modern glass, or decorative noise that obscures controls.

Textures and artwork should be original drawings or appropriately licensed assets. Historical screenshots are references, not bundled production assets.

## Current reference palette and geometry

These values describe existing reference components and useful starting points. They are not a shared Swift package or a requirement to recolor every app.

| Role | Current reference | Use |
| --- | --- | --- |
| Notes paper | RGB `1.00, 0.98, 0.73`, approximately `#FFFABA` | Note pages and their status/bottom backgrounds |
| Notes ink | RGB `0.24, 0.15, 0.09`, approximately `#3D2617` | Warm, readable note content |
| Paper rule | RGB `0.67, 0.66, 0.43`, approximately `#ABA86E`, with reduced opacity | Subtle page rules |
| Leather base | RGB `0.35, 0.21, 0.14`, approximately `#593624` | Notes navigation and shaded buttons |
| Light pinstripes | RGB `0.82, 0.84, 0.87`, approximately `#D1D6DE` | Notes accounts and printer settings |
| Dark linen | `#27282D` | Weather management/settings |
| Classic settings value | RGB `0.23, 0.32, 0.46`, approximately `#3B5275` | Printer selection values and settings text |

Notes and printing navigation bars are 44 points high; Weather management currently uses 50 points. Notes navigation titles are typically 20-point bold Helvetica Neue; Weather management uses 24 points. Preserve app-specific proportions rather than changing validated screens solely to make all numbers identical.

For new controls, provide at least a 44-by-44-point interaction area even when the visible beveled button is smaller. Compact back buttons in Notes are visually about 29 points high. Grouped settings rows are approximately 49–50 points high, with restrained corner radii around 10 points and fine separators. Side padding depends on the original screen: classic printer groups use 10 points; Weather's management groups use 20 points. These are examples, not a universal grid.

## Typography, symbols, and information hierarchy

Use Helvetica Neue and its appropriate weights for classic navigation, lists, settings, and controls. Preserve an original app's specialized content fonts where applicable, such as Notes' Noteworthy, Helvetica, and Marker Felt choices. Provide suitable Chinese glyph fallback and keep user content unchanged when the interface language changes.

Navigation titles should stay visually centered, with enough space for both side controls and the longest supported translation. Protect important action labels from truncation. Allow user-selected content sizing and sensible text wrapping where needed; adapt spacing instead of clipping Chinese text or longer accessibility sizes.

Choose simple classic silhouettes. Custom vector artwork is appropriate for iconic skeuomorphic controls; a system symbol is acceptable when its silhouette fits the reference. Avoid introducing modern outlined pills, oversized contact avatars, floating drag handles, or current-OS toolbar styling into an app-owned classic surface.

Use grouped rows, disclosure indicators, inset borders, and clear hierarchy where the original screen uses them. Retain honest empty, loading, error, selected, and disabled states; decorative replicas must remain usable controls.

## Sheets, alerts, and system integration

App-owned share panels and service/settings screens should continue the classic visual language. The Notes reference uses a shaded bottom share panel with dimensional Mail/Print/Copy tiles, a separate glossy Cancel button, and a dimmed page. Printer Options uses blue-gray navigation, pinstripes, white grouped rows, a silver copies control, and a dark blue Print button.

Use recoverable classic alerts for app-owned errors. Modal dismissal must restore interaction with the previous screen, including after an error, a canceled task, or repeated presentation. Invisible or fading overlays must stop intercepting touches. Preserve accessibility focus and modal semantics; verify return/reopen flows on the supported runtimes rather than relying only on a screenshot.

Keep integrations functional through public APIs. Some system-owned surfaces, such as keyboards, permission prompts, text selection menus, mail composition, and print progress, retain the current OS appearance. Document those boundaries in the app README instead of claiming complete historical fidelity or using private APIs to force it. Choose a custom app-owned surface only when the underlying action can still work correctly.

## Motion and accessibility

Animations should explain a physical action: a page turns, a panel rises, a card flips, or a note folds into the bin. Match the original interaction's pacing and direction without adding unrelated bounce or modern morphing effects. Disable accidental repeated actions while a transition or destructive operation is active.

Honor Reduce Motion with a short fade or immediate state change. Rotation, backgrounding, interruption, and empty-content boundaries must leave the app in a usable state. Complex motion needs actual playback verification in addition to still captures.

Provide localized accessibility labels, real selected/disabled states, adequate interaction areas, contrast, and an accessible equivalent for gestures. Decorative texture must not pollute the accessibility hierarchy.

## Language adaptation

Follow the existing Weather/Notes language rule: the first system or per-app preferred language selects the interface; Chinese variants use Simplified Chinese, English uses English, and unsupported languages fall back to English.

Cover all user-facing text, dates, counts, accessibility labels, errors, permission explanations, and the Home Screen name. Preserve user-written content and stored preferences across language changes. Verify both languages, including longer labels and compact screens. System-owned UI can follow the device language independently, so distinguish app localization from system localization in verification records.

## Reference implementations and visual proof

Use these components as concrete references. Read their surrounding screen layout before copying an isolated modifier or view.

| Concern | Reference |
| --- | --- |
| Body background extending through safe areas | [NotesRootView](../apps/notes/NotesSix/Views/NotesRootView.swift), [Weather CityManagerView](../apps/weather/WeatherSix/Views/CityManagerView.swift) |
| Paper, leather, beveled back buttons, and Notes navigation | [Notes ClassicTheme](../apps/notes/NotesSix/Views/ClassicTheme.swift) |
| Light pinstripes | [Notes AccountsView](../apps/notes/NotesSix/Views/AccountsView.swift) |
| Dark linen, glossy navigation, and classic ON/OFF switch | [Weather ClassicTheme](../apps/weather/WeatherSix/Views/ClassicTheme.swift) |
| Classic sharing and app-owned error alerts | [ClassicSharePanel](../apps/notes/NotesSix/Views/ClassicSharePanel.swift) |
| Classic printer settings and printer selection | [ClassicPrintView](../apps/notes/NotesSix/Views/ClassicPrintView.swift) |
| Material-driven deletion motion | [PaperTrashAnimation](../apps/notes/NotesSix/Views/PaperTrashAnimation.swift) |
| System/per-app language helpers | [Notes AppLanguage](../apps/notes/NotesSix/Models/AppLanguage.swift), [Weather AppLanguage](../apps/weather/WeatherSix/Models/AppLanguage.swift) |

Approved Notes framing is illustrated by the [paper-backed status area](../apps/notes/docs/screenshots/full-screen-layout/browser-final.jpg) and [pinstripe-backed accounts](../apps/notes/docs/screenshots/full-screen-layout/browser-accounts.jpg). The [classic printing capture](../apps/notes/docs/screenshots/classic-print/browser-final.jpg) demonstrates a separate blue-gray navigation panel above a continuous pinstripe surface. Consult each app's verification record for the capture's scope and runtime; these references do not imply that every existing component has already been audited against every rule in this document.

## Applying the language to another app

1. Read this guide and identify a historical reference for the target app's screens, controls, and interactions. Record what belongs to the original design and what adapts it to a modern device.
2. Decide which screens benefit from the shared frame and which should retain specialized original layouts. Define materials, typography, controls, and motion for each. Use independent navigation panels and status/bottom continuity on applicable screens; do not introduce those elements on screens that do not need them. Include both interface languages in the initial layout.
3. Implement within the app's independent project. Reuse existing component patterns where their appearance and behavior fit. Extract shared code only for a concrete common requirement; this guide does not require a speculative package or a bulk refactor of Weather and Notes.
4. Check portrait and landscape, a compact device and a modern notched device, both languages, the keyboard, empty/long content, disabled/error states, modal cancellation/reopening, and Reduce Motion where animations are affected.
5. Save representative screenshots and record meaningful build, visual, and affected-flow validation in the app's `docs/verification.md`. Use isolated test data and preserve the user's real data.
6. Link this guide from the app README, note which patterns apply and which screens keep their own layout, and register the app in the collection workspace and root README as described in the [project layout guide](project-layout.md).

For visual changes, validate the requested result in the actual app or live simulator rather than treating generated artwork or compilation as proof of layout. Choose test scope according to the change; a documentation-only update does not require rebuilding the apps.
