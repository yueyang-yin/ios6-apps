#!/usr/bin/env python3
"""Check bilingual resources, placeholders, icon metadata, and workspace registration."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parent.parent

def strings(language):
    text = (ROOT / "StocksSix" / f"{language}.lproj/Localizable.strings").read_text()
    return {json.loads(a): json.loads(b) for a, b in re.findall(r'("(?:[^"\\]|\\.)*")\s*=\s*("(?:[^"\\]|\\.)*");', text)}
en, zh = strings("en"), strings("zh-Hans")
assert set(en) == set(zh)
for key in en:
    assert re.findall(r'%[@df]', en[key]) == re.findall(r'%[@df]', zh[key]), key
for source in (ROOT / "StocksSix").rglob("*.swift"):
    for key in re.findall(r'L10n\.(?:text|format)\("([^"\\]*)"', source.read_text()):
        assert key in en, (source.name, key)
icon = ROOT / "StocksSix/Assets.xcassets/AppIcon.appiconset"
assert (icon / "AppIcon.png").is_file()
assert json.loads((icon / "Contents.json").read_text())["images"][0]["filename"] == "AppIcon.png"
assert "apps/stocks/StocksSix.xcodeproj" in (ROOT.parent.parent / "iOS6Apps.xcworkspace/contents.xcworkspacedata").read_text()
print(f"PASS: {len(en)} bilingual keys, placeholders, static keys, app icon, workspace reference")
