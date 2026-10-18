#!/usr/bin/env python3
"""Draw original ticket strips and prepare the approved leather-pocket app icon."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
import math

ROOT = Path(__file__).resolve().parent.parent / "PassbookSix/Assets.xcassets"
ROOT.mkdir(parents=True, exist_ok=True)
(ROOT / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}))
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"


def save_asset(name, image, icon=False):
    directory = ROOT / (name + (".appiconset" if icon else ".imageset"))
    directory.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(directory / f"{name}.png")
    entry = {"filename": f"{name}.png", "idiom": "universal"}
    if icon: entry.update({"platform": "ios", "size": "1024x1024"})
    else: entry["scale"] = "2x"
    (directory / "Contents.json").write_text(json.dumps({"images": [entry], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def gradient(width, height, top, bottom):
    image = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        ratio = y / max(height - 1, 1)
        color = tuple(round(a * (1 - ratio) + b * ratio) for a, b in zip(top, bottom))
        draw.line((0, y, width, y), fill=color)
    return image


image = gradient(900, 320, (31, 58, 56), (92, 125, 107))
d = ImageDraw.Draw(image)
d.rectangle((135, 80, 760, 320), fill="#152C2B")
for x in range(160, 730, 110):
    d.rectangle((x, 100, x + 80, 260), fill="#DAC477")
    d.rectangle((x + 4, 104, x + 76, 230), fill="#B9B48C")
    d.rectangle((x + 36, 104, x + 42, 260), fill="#3E5446")
d.polygon([(90, 93), (800, 93), (746, 25), (148, 25)], fill="#D2C5A3")
d.rectangle((90, 84, 800, 102), fill="#31594C")
d.text((270, 39), "STARBUCKS COFFEE", font=ImageFont.truetype(FONT, 32), fill="#274739")
for x in [55, 810]:
    d.rectangle((x + 20, 110, x + 28, 320), fill="#4E3F2F")
    for k in range(7):
        radius = 42 - abs(k - 3) * 3
        d.ellipse((x - radius + 25, 28 + k * 18, x + radius + 25, 95 + k * 18), fill="#294E3F")
d.ellipse((320, 277, 450, 295), fill="#1D3431")
d.rectangle((378, 275, 385, 320), fill="#1D3431")
save_asset("CoffeeStrip", image)

image = gradient(900, 320, (45, 24, 38), (13, 21, 32))
d = ImageDraw.Draw(image)
for x in range(0, 900, 60):
    d.polygon([(x, 0), (x + 25, 0), (450 + (x - 450) * 0.4, 320)], fill="#572D3D")
d.rounded_rectangle((180, 60, 720, 270), radius=9, fill="#B99E66", outline="#EFD89B", width=6)
d.rounded_rectangle((195, 75, 705, 255), radius=4, fill="#29394D")
d.text((253, 112), "CINEMA GRAND", font=ImageFont.truetype(FONT, 50), fill="#E8D69E")
d.text((325, 184), "FEATURE PRESENTATION", font=ImageFont.truetype(FONT, 19), fill="#DCCB9E")
for x in range(205, 706, 28):
    for y in [67, 262]: d.ellipse((x, y, x + 7, y + 7), fill="#FFF4D1")
save_asset("CinemaStrip", image)

image = gradient(900, 320, (91, 109, 122), (171, 150, 119))
d = ImageDraw.Draw(image)
d.rectangle((210, 15, 695, 320), fill="#D4C8B6")
for x in range(245, 680, 65):
    for y in range(35, 300, 64):
        d.rectangle((x, y, x + 24, y + 42), fill="#536471")
        d.line((x + 12, y, x + 12, y + 42), fill="#A8B4B5", width=2)
d.rectangle((365, 215, 550, 320), fill="#544E49")
d.polygon([(325, 215), (590, 215), (550, 184), (365, 184)], fill="#8A624B")
d.text((362, 156), "THE GRAND", font=ImageFont.truetype(FONT, 25), fill="#675347")
save_asset("HotelStrip", image)

# Keep the approved generated master as the source of truth for icon regeneration.
master = Path(__file__).resolve().parent.parent / "artwork/passbook-icon-master.png"
icon = Image.open(master).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
save_asset("AppIcon", icon, icon=True)
print("Generated three original pass strips and installed the approved leather-pocket icon")
