"""Builds the download website's pictures into site/assets.

The screenshots are the phone-size renders the preview tests leave in
build/size_audit (run them first). Every one goes out at the same height so
the strip on the page lines up, as JPEG to keep the page light on mobile data.

    python tool/make_site_assets.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
AUDIT = ROOT / 'build' / 'size_audit'
OUT = ROOT / 'site' / 'assets'
HEIGHT = 1280  # twice the 640 phone renders, for sharp screens

# (file in build/size_audit, name on the site, crop box or None)
SHOTS = [
    ('fil_lessons__b_phone.png', 'shot1', None),
    ('fil_pick_bilang__b_phone.png', 'shot2', None),
    ('about_home_fil.png', 'shot3', None),
    ('fil_pick_kulay__b_phone.png', 'shot4', None),
    # The medal wall is one long scroll; the top of it, at phone shape.
    ('awards_medals_fil.png', 'shot5', (0, 0, 760, 1351)),
    ('fil_dashboard__b_phone.png', 'shot6', None),
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for src, name, box in SHOTS:
        im = Image.open(AUDIT / src).convert('RGB')
        if box:
            im = im.crop(box)
        w = round(im.width * HEIGHT / im.height)
        im = im.resize((w, HEIGHT), Image.LANCZOS)
        im.save(OUT / f'{name}.jpg', quality=82, optimize=True, progressive=True)

    logo = Image.open(ROOT / 'assets/images/app_logo.jpg').convert('RGB')
    logo.resize((192, 192), Image.LANCZOS).save(OUT / 'icon-192.png')
    logo.resize((512, 512), Image.LANCZOS).save(OUT / 'icon-512.png')
    logo.resize((48, 48), Image.LANCZOS).save(OUT / 'favicon.png')

    # The card a chat app shows for the link.
    card = Image.new('RGB', (1200, 630), '#5C52E5')
    draw = ImageDraw.Draw(card)
    mask = Image.new('L', (300, 300), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 300, 300), 66, fill=255)
    card.paste(logo.resize((300, 300), Image.LANCZOS), (110, 165), mask)
    title = ImageFont.truetype(str(ROOT / 'assets/fonts/Roboto-black.ttf'), 100)
    body = ImageFont.truetype(str(ROOT / 'assets/fonts/Roboto-medium.ttf'), 40)
    draw.text((470, 190), 'E-Tarabay', font=title, fill='white')
    draw.text((474, 330), 'Ilocano · Filipino · English', font=body,
              fill='#E6E3FF')
    draw.text((474, 390), 'Para sa daycare, edad 3–5', font=body,
              fill='#E6E3FF')
    draw.rounded_rectangle((474, 462, 790, 530), 34, fill='#1A8F5A')
    draw.text((632, 496), 'I-download', font=body, fill='white', anchor='mm')
    card.save(OUT / 'share.jpg', quality=88, optimize=True)

    for f in sorted(OUT.iterdir()):
        print(f'{f.name:16} {f.stat().st_size // 1024:5} KB')


if __name__ == '__main__':
    main()
