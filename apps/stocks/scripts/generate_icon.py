#!/usr/bin/env python3
"""Draw an original blue-glass chart icon without embedding historical artwork."""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent / "StocksSix" / "Assets.xcassets"
size = 1024
image = Image.new("RGB", (size, size))
pixels = image.load()
for y in range(size):
    t = y / size
    for x in range(size):
        glow = max(0, 1 - math.hypot((x - 390) / 1100, (y - 30) / 1000))
        pixels[x, y] = (int(25 + 35 * (1 - t) + 28 * glow), int(71 + 85 * t + 32 * glow), int(146 + 53 * t + 34 * glow))
draw = ImageDraw.Draw(image)
for x in range(75, size, 145):
    draw.line((x, 0, x, size), fill=(157, 200, 238), width=3)
for y in range(175, size, 145):
    draw.line((0, y, size, y), fill=(96, 164, 216), width=2)
points = [(0, 675), (70, 710), (120, 665), (173, 560), (220, 595), (270, 520), (320, 630), (373, 570), (425, 590), (485, 420), (520, 460), (555, 280), (600, 420), (650, 382), (700, 500), (745, 350), (790, 390), (835, 238), (890, 325), (944, 270), (1024, 320)]
shadow = Image.new("RGBA", (size, size)); sd = ImageDraw.Draw(shadow)
sd.line([(x,y+6) for x,y in points], fill=(0,25,70,210), width=23, joint="curve")
image = Image.alpha_composite(image.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(6)))
draw = ImageDraw.Draw(image)
draw.line(points, fill=(238,249,255,255), width=13, joint="curve")
gloss = Image.new("RGBA", (size, size)); gd = ImageDraw.Draw(gloss)
gd.polygon([(0,0),(1024,0),(1024,260),(0,560)], fill=(255,255,255,22))
image = Image.alpha_composite(image, gloss).convert("RGB")
folder = ROOT / "AppIcon.appiconset"; folder.mkdir(parents=True, exist_ok=True)
image.save(folder / "AppIcon.png")
(folder / "Contents.json").write_text(json.dumps({"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}, indent=2)+"\n")
(ROOT / "Contents.json").write_text('{"info":{"author":"xcode","version":1}}\n')
