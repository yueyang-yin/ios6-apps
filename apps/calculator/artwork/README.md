# Calculator icon artwork

The reviewed master is `calculator-icon-master.png`. The production asset is `../CalculatorSix/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, an opaque RGB PNG at 1024 × 1024. Run `python3 scripts/generate_icon.py` from the app directory, or run `python3 apps/calculator/scripts/generate_icon.py` from the repository root, to prepare it again.

The icon follows the historical four-key structure: a silver perimeter, black pebbled leather, three warm gray/taupe buttons, and an amber orange equals button at bottom right. The plus, minus, multiply, and equals symbols are white and centered. There is no number display.

## Reference and production

The historical reference was viewed from the [old iPhone calculator icon reference](https://www.pinterest.com/pin/818810776037468658/), using its [image](https://i.pinimg.com/736x/06/c8/66/06c866e7143dd9bc11813ef46e405ced.jpg) as visual input. [Calculator icon history](https://logos.fandom.com/wiki/Calculator_%28iOS%29) identifies the iOS 4–6 era. The downloaded reference is not bundled as an app asset.

The current master was refined with the built-in imagegen tool in two precise-object-edit passes. The first pass starts from the previous detailed four-key master; the second uses that pass as the edit target and its installed, magnified Home Screen capture as diagnostic reference. Pillow only converts and resizes the reviewed master to the standard AppIcon PNG.

Silver material extends to every square canvas edge and corner. The peripheral leather opening and narrow inner bevel were revised to give the silver band smoother corner transitions, with less pinched highlight detail. iOS supplies the outer silhouette. There is no black exterior margin or second outer rounded tile. The original large key proportions, glossy caps, embossed symbols, and defined leather grain are retained. This follows the [Apple app-icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons/) to supply square artwork for the system mask.

The installed result was inspected on iPhone Air/iOS 26.2 in the native Home Screen capture and the live serve-sim browser. See [verification](../docs/verification.md) for the final asset hash and captures.

## Corner refinement prompts and retained sources

Both edits used built-in imagegen with an opaque background. The exact [first-pass prompt](corner-first-pass-prompt.txt) and [final prompt](corner-refinement-prompt.txt) are stored beside the master. The final prompt restricts changes to the outer silver bezel and adjoining leather corners, retains the four keys, and uses the installed screenshot to repair narrowed highlight turns.

The previous master is retained as `versions/calculator-icon-before-contour-fix.png`; the first pass is retained as `versions/calculator-icon-contour-first-pass.png`. The current reviewed master remains `calculator-icon-master.png` and produces the 1024-pixel AppIcon asset. The native zoom and original-resolution screenshots in the verification record document the final installed result rather than a simulated icon mask.
