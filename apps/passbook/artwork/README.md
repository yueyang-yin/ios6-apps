# Passbook artwork

## App icon

`passbook-icon-master.png` is the approved generated master. `scripts/generate_artwork.py` resizes it to the 1024 x 1024 opaque RGB asset in `PassbookSix/Assets.xcassets/AppIcon.appiconset`. Regeneration retains this artwork rather than returning to the retired four-stripe placeholder.

The reference is the iOS 6 Passbook icon: a black leather holder with an upward-sweeping diagonal front pocket and three fanned tickets. The rear green coffee ticket, middle golden boarding pass, and front blue cinema ticket have darker printed symbols. Leather grain, pocket edging, paper notches, bevels, and contact shadows provide the period-specific depth.

Created with the built-in imagegen tool, using the historical icon as a composition reference. This is newly generated artwork; the reference screenshots are not bundled or cropped into the app asset. The modern system applies the outer icon mask.

References:

- [Historical iOS 6 icon and dimensions](https://bokechans.net/ios6/themes/std_icon.html)
- [Historical Wallet icon comparison](https://vectorified.com/apple-wallet-icon)
- [Passbook icon history](https://logos.fandom.com/wiki/Apple_Wallet_(iOS))

## Generation prompt

Use case: historical icon recreation. Produce one opaque full-bleed square app icon for an iOS 6 Passbook recreation, matching only the original 2012 icon in the references. Show a black fine-grain leather ticket wallet with a curved diagonal front-pocket lip rising from the lower left to the upper right. Insert exactly three slightly fanned paper tickets: rear green coffee ticket tilted counterclockwise, middle golden-yellow boarding ticket, front cyan-blue cinema ticket tilted clockwise. Use a dark green cup, dark ochre left-facing airplane, and dark blue two-reel movie camera on a tripod. Preserve paper notches, subtle bevels, restrained leather edge highlights, and contact shadows. Fill the image with the leather-backed artwork, allowing the OS to supply the outer rounded mask. No surrounding background, text, orange card, barcode stripe, credit card, extra objects, flat modern Wallet styling, or inset tile.

## Pass strips

`scripts/generate_artwork.py` draws the original coffee-shop, cinema, and hotel strips. These are separate from the generated icon master.
