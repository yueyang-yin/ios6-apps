#!/usr/bin/env python3
"""Prepare the reviewed historical-style artwork as an opaque iOS app icon."""

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / 'artwork/calculator-icon-master.png'
ICON_FOLDER = ROOT / 'CalculatorSix/Assets.xcassets/AppIcon.appiconset'


def main():
    ICON_FOLDER.mkdir(parents=True, exist_ok=True)
    with Image.open(MASTER) as image:
        if image.width != image.height:
            raise ValueError('The reviewed icon artwork must be square.')
        image.convert('RGB').resize((1024, 1024), Image.Resampling.LANCZOS).save(
            ICON_FOLDER / 'AppIcon.png', optimize=True
        )
    contents = {
        'images': [
            {
                'filename': 'AppIcon.png',
                'idiom': 'universal',
                'platform': 'ios',
                'size': '1024x1024',
            }
        ],
        'info': {'author': 'xcode', 'version': 1},
    }
    (ICON_FOLDER / 'Contents.json').write_text(json.dumps(contents) + '\n')
    print(ICON_FOLDER / 'AppIcon.png')


if __name__ == '__main__':
    main()
