# CalculatorSix

A native iPhone calculator recreation inspired by the iOS 6 Calculator. The app uses an original olive LCD surface, dark woven body, glossy black number keys, gray memory/scientific keys, warm gray operators, a double-width zero key, and a tall orange equals key. It follows the original six-row portrait and eight-column landscape composition.

## Run

Open `../../iOS6Apps.xcworkspace` and choose **CalculatorSix**, or open `CalculatorSix.xcodeproj` directly. Requires iOS 17+ and Xcode 16+ with a matching simulator runtime. The project has no external runtime dependencies.

```sh
python3 scripts/create_project.py
xcodebuild -project CalculatorSix.xcodeproj -scheme CalculatorSix \
  -destination 'platform=iOS Simulator,name=iPhone Air' build
```

The generated project includes independent unit and UI test targets. The icon is a reference-guided recreation of the iOS 6 four-key icon: silver perimeter, dark pebbled leather, three warm gray keys, and an amber equals key. Reviewed artwork is saved in `artwork/calculator-icon-master.png`; `python3 scripts/generate_icon.py` prepares the opaque 1024-pixel AppIcon asset (Pillow required for this asset script only).

For a physical iPhone, choose the connected device and your Development Team with automatic signing enabled, then run CalculatorSix. Sign in under Xcode > Settings > Apple Accounts if Xcode needs to generate a development profile. Re-select the team if you regenerate the project. Normal physical-device launches use the phone's own language preferences and saved state.

For the Codex simulator mirror, run `scripts/serve_sim.sh <simulator-udid>` and keep its terminal alive. If Xcode 27 Device Hub interrupts touch input while video remains live, use the [serve-sim input repair](https://github.com/EvanBacon/serve-sim#iphone-duo): `npx --yes serve-sim@latest repair-input -d <simulator-udid>`. This restarts SpringBoard and closes running simulator apps. Restart the scoped mirror afterward, reopen CalculatorSix, and verify an actual browser tap; a live video indicator alone does not verify touch input.

## Calculator behavior

- During input, the LCD shows only the full expression in large Helvetica Neue Light type. Equals moves the completed expression into a smaller upper line and displays the large result below it. Clear/new entry restores the single-line layout, with no duplicate zero. A standalone scientific function can also complete a calculation; functions within a pending expression stay in the large input line. Long input shrinks within a readable limit, then scrolls horizontally while following the latest entry. VoiceOver reads the complete expression with a localized label.
- Portrait: memory clear/add/subtract/recall, C/AC, sign, four arithmetic operators, decimal entry, repeated equals, wide zero, and tall equals.
- Landscape: parentheses with nesting and implicit multiplication, percentage/markups/discounts, reciprocal, square/cube, power, nth root, factorial, square root, base-ten/natural/base-two logarithms, exponentials, trigonometric and hyperbolic functions with inverses, degrees/radians, pi, scientific exponent entry, and random numbers.
- **2nd** changes sin/cos/tan and sinh/cosh/tanh to their inverses, ln to log₂, and eˣ to 2ˣ. Degrees are the initial angle mode. The angle key offers the other mode.
- Basic mode evaluates chained operators immediately; scientific mode uses arithmetic precedence and right-associative powers. Parentheses override precedence. Equals closes remaining open groups. Repeated equals reapplies the final reduced operation and its operand.
- C clears the current operand; the next clear becomes AC and resets the expression. Memory survives C/AC. A white ring around mr indicates a stored memory value, including zero.
- Swipe a fitting large input line to delete an entered digit. When that line is too long to fit at the minimum font size, swiping reviews the expression instead; VoiceOver retains the named deletion action. The small completed-expression row is also scrollable. Long-press the main display for numeric Copy/Paste. Paste accepts finite numeric values, including exponent notation and comma-separated digits; invalid text is ignored.
- Normal launches restore the display, input/result presentation phase, visible and pending expression, memory, angle mode, and second-function state. Older saved states remain readable, with their numeric operands used when original expression text is unavailable. Rotation preserves calculations and presentation phase. `--uitesting` starts an isolated calculator and neither reads nor writes the normal saved state.
- Invalid domains, division by zero, and non-finite results display a localized error. A digit or clear recovers. Integer factorials are supported from 0 to 170.

The engine uses IEEE-754 Double arithmetic and formats results to 15 significant digits. Basic entry accepts up to 9 digits; scientific entry up to 16. It is not an arbitrary-precision or symbolic mathematics engine.

## Language and accessibility

Like [WeatherSix](../weather/README.md), the first system or per-app preferred language selects the interface. Chinese variants use Simplified Chinese; English and unsupported languages use English. Localized resources cover the Home Screen name, display/error labels, clipboard actions, every key's VoiceOver name, and memory/angle states. Mathematical key captions remain the historical notation in both languages. Numeric values use a decimal point in both supported locales.

The app retains actual system status content and modern safe areas. Controls stay clear of the notch and home indicator. Keys offer at least 44-point hit areas on tested compact and modern devices; labels grow with text size within the available LCD/key height, and VoiceOver reads complete localized names. Reduce Motion removes key-press animation. Clipboard menus and paste permission prompts remain system-owned current-iOS surfaces.

## Design and references

Read the [shared design language](../../docs/design-language.md). Calculator keeps its specialized LCD/keypad layout and uses only applicable material, safe-area, localization, and accessibility rules; it does not add a Notes-style navigation panel.

Full-expression input is a deliberate usability addition to the historical single-value LCD. The display keeps one prominent line while entering a calculation and introduces the upper summary only after evaluation. Thin classic numeral strokes, olive LCD ink, restrained inset shading, and the original keypad composition are retained. The summary uses slightly larger LCD type for readability. Entered arithmetic stays in its original sequence without automatically inserted grouping parentheses; explicit user parentheses remain. Basic mode still evaluates sequentially, whereas scientific mode applies precedence.

Historical references:

- [Apple iPhone User Guide for iOS 6, Calculator chapter, printed page 103](https://cdsassets.apple.com/live/6GJYWVAV/user/ma1658_iphone_ios6_user_guide.pdf): portrait layout, memory indication, and rotation to scientific mode.
- [Apple's earlier iPhone User Guide, scientific calculator table, printed pages 136–138](https://cdsassets.apple.com/live/6GJYWVAV/user/ma616_iphone_ios3_1_user_guide.pdf): the classic scientific key families and 2nd behavior.
- [Contemporary portrait and landscape reference](https://www.core77.com/posts/24935/Braun-Re-issuing-Classic-ET66-Calculator): glossy materials, key placement, and tall equals.

Reference screenshots are not bundled into the app. The interface materials are newly drawn, and the icon is a reference-guided redraw produced with the built-in imagegen tool. This is an independent recreation, not Apple's original binary, and it runs on modern iOS rather than iOS 6. See [verification](docs/verification.md) for actual tested scope.

## Simulator in Codex

After building and running on a specific simulator:

```sh
npm_config_cache=/private/tmp/calculator-six-npm-cache \
  scripts/serve_sim.sh <simulator-udid>
```

Open the exact URL printed by serve-sim in Codex's in-app browser. Keep the terminal running while using the mirror. The script installs an exit trap and cleans up only the helper for the supplied simulator. Stop that terminal to close the mirror; this does not uninstall the calculator or shut down the simulator.
