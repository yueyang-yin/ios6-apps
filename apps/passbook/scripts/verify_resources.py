#!/usr/bin/env python3
"""Validate paired localizations, static keys, placeholders, icon, and registration."""
from pathlib import Path
import json
import plistlib
import re
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def strings(language):
    source = (ROOT / "PassbookSix" / f"{language}.lproj/Localizable.strings").read_text()
    return {json.loads(a): json.loads(b) for a, b in re.findall(r'("(?:[^"\\]|\\.)*")\s*=\s*("(?:[^"\\]|\\.)*");', source)}


en, zh = strings("en"), strings("zh-Hans")
assert set(en) == set(zh)
for key in en:
    assert re.findall(r'%[\d$]*l?[d@fs]', en[key]) == re.findall(r'%[\d$]*l?[d@fs]', zh[key]), key
for source in (ROOT / "PassbookSix").rglob("*.swift"):
    for key in re.findall(r'L10n\.(?:text|format)\("([^"\\]*)"', source.read_text()):
        assert key in en, (source.name, key)
for name in ["AppIcon", "CoffeeStrip", "CinemaStrip", "HotelStrip"]:
    directory = ROOT / "PassbookSix/Assets.xcassets" / (name + (".appiconset" if name == "AppIcon" else ".imageset"))
    metadata = json.loads((directory / "Contents.json").read_text())
    image = Image.open(directory / metadata["images"][0]["filename"])
    assert image.mode == "RGB"
    assert image.size == ((1024, 1024) if name == "AppIcon" else (900, 320))
info = plistlib.loads((ROOT / "PassbookSix/Info.plist").read_bytes())
assert info["CFBundleDocumentTypes"][0]["LSItemContentTypes"] == ["com.apple.pkpass"]
assert "apps/passbook/PassbookSix.xcodeproj" in (ROOT.parent.parent / "iOS6Apps.xcworkspace/contents.xcworkspacedata").read_text()
print(f"PASS: {len(en)} paired strings, placeholders, static keys, four assets, document type, workspace")
