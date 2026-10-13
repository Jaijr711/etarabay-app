# -*- coding: utf-8 -*-
"""Cut a comic sheet into one picture per line of the story.

    python tool/cut_story_panels.py <sheet.png>                  # look only
    python tool/cut_story_panels.py <sheet.png> --write milio --expect 7

A story that has `linePictures` shows the panel for the line being read, so a
child who cannot read follows the story in pictures while the voice reads it
to them. The panels have to be cut out of the sheet the artist delivers, and
cut cleanly: a sliver of the neighbouring panel down one edge is the first
thing anyone notices.

**The panels are found, not assumed.** Ni Marti's sheet is four across and two
down, Ni Didi's is four on top and five underneath, and the next one will be
something else again — any fixed division cuts through the middle of a
picture. What every sheet does have is a flat background in the gutters, so a
row that is background all the way across is a gap, and so is a column.

**Every panel comes out the same size.** A sheet with four panels on one row
and three on the next has a wider panel on the short row, and left alone the
story would show a different sized picture on different pages. Each panel is
centred on a background-coloured box as big as the largest one, so every page
of the story presents the picture in the same place. Pass --no-uniform to keep
the raw crops.

Nothing is written without --write, and with --expect it refuses to write at
all unless it found exactly the number of panels the story has lines for — a
detection that quietly finds six panels for a seven-line story is worse than
one that fails.
"""
import argparse
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, 'assets', 'images')


def near(c, ref, tol=26):
    return (abs(c[0] - ref[0]) <= tol and abs(c[1] - ref[1]) <= tol
            and abs(c[2] - ref[2]) <= tol)


def runs(flags, min_len):
    """Start and end of each run of True, at least min_len long."""
    out, start = [], None
    for i, f in enumerate(flags + [False]):
        if f and start is None:
            start = i
        elif not f and start is not None:
            if i - start >= min_len:
                out.append((start, i))
            start = None
    return out


def slices(flags, total, min_gap, min_piece):
    """The pieces between the gaps."""
    pieces, prev = [], 0
    for a, b in runs(flags, min_gap):
        if a - prev > min_piece:
            pieces.append((prev, a))
        prev = b
    if total - prev > min_piece:
        pieces.append((prev, total))
    return pieces


def find_panels(im):
    """Every panel on the sheet, in reading order."""
    W, H = im.size
    px = im.load()
    # The corner is gutter on every sheet we have been given.
    bg = px[2, 2]

    row_bg = [
        sum(1 for x in range(0, W, 7) if near(px[x, y], bg)) >= (W // 7) * 0.97
        for y in range(H)
    ]
    # Every strip is kept at this stage, even a short one: a caption box is
    # short, and it has to survive the pass so join_captions can put it back
    # with its picture.
    bands = slices(row_bg, H, max(6, H // 120), 8)
    bands = join_captions(bands)
    bands = grow_to_border(px, W, H, bg, bands)

    found = []
    for top, bot in bands:
        col_bg = [
            sum(1 for y in range(top, bot, 7) if near(px[x, y], bg)) >=
            ((bot - top) // 7) * 0.97 for x in range(W)
        ]
        cols = slices(col_bg, W, max(4, W // 200), int(W * 0.06))
        found.append([(a, top, b, bot) for a, b in cols])
    return bg, found


def grow_to_border(px, W, H, bg, bands):
    """Take in the frame the caption box is drawn with.

    Ni Neneng's caption boxes are filled with almost exactly the sheet
    background — 253,248,238 against 253,249,241 — so the box reads as gutter
    and the band stops at the last line of text inside it. The only part of
    the box that is not background is the thin gold line around it, three
    pixels below where the band ended, and cutting there sliced the last line
    of every caption in the bottom row.

    So each band grows downwards to the last row that still has something
    drawn on it before the next band begins.
    """
    out = []
    for i, (top, bot) in enumerate(bands):
        limit = bands[i + 1][0] if i + 1 < len(bands) else H
        last = bot
        for y in range(bot, limit):
            n = sum(1 for x in range(0, W, 5) if not near(px[x, y], bg, 18))
            if n >= 8:
                last = y
        out.append((top, min(last + 2, limit)))
    return out


def join_captions(bands):
    """Put a caption back with the picture it belongs to.

    Ni Milio and Ni Kikay have the caption drawn inside the panel. Ni Neneng
    has it in a box *underneath*, on the sheet background — so the strip of
    background between the picture and its own caption reads as a gutter, and
    the sheet comes apart into six bands instead of two: picture, caption,
    picture, caption. Cutting there would have dropped every caption in the
    story.

    A caption strip is far shorter than a row of pictures, and that is the
    thing to test: any band under a third of the tallest one is not a row of
    its own, it is the tail of the row above it.
    """
    if len(bands) < 2:
        return bands
    tallest = max(b - a for a, b in bands)
    out, pending = [], None
    for a, b in bands:
        if (b - a) < tallest * 0.35:
            if out:
                out[-1] = (out[-1][0], b)      # a caption: goes with the row above
            else:
                pending = (a if pending is None else pending[0], b)
            continue
        if pending is not None:
            a = pending[0]                      # anything above the first row
            pending = None
        out.append((a, b))
    return out


def light(c, cut=232):
    return c[0] >= cut and c[1] >= cut and c[2] >= cut


def light_runs(flags, min_len=3):
    return runs(flags, min_len)


def find_panels_by_seams(im, expect):
    """For sheets whose panels sit flush against each other.

    Ni Milio's panels stand on a cream background, so the gutters are simply
    that background and can be found by colour. Ni Kikay's touch: the only
    thing between two panels is a seam three pixels wide, and it is not pure
    white either — the caption boxes are a pale lilac and they cross it.

    So the seam is looked for as a column that is *light* nearly all the way
    down, and the threshold is relaxed a step at a time until the sheet comes
    apart into the number of panels the story has lines for. It stops at the
    first threshold that fits, which is the loosest reading that still agrees
    with the story — and if none fits, it says so rather than guessing.

    The two rows are read separately on purpose: on Ni Kikay's sheet the seams
    of the top row do not line up with the bottom row's at all.
    """
    W, H = im.size
    px = im.load()

    row_light = [
        sum(1 for x in range(0, W, 4) if light(px[x, y])) / len(range(0, W, 4))
        for y in range(H)
    ]
    bands = slices([f > 0.9 for f in row_light], H, 4, int(H * 0.12))
    if not bands:
        return None

    for thr in (0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65):
        found, total = [], 0
        for top, bot in bands:
            ys = range(top, bot, 3)
            col_light = [
                sum(1 for y in ys if light(px[x, y])) / len(ys)
                for x in range(W)
            ]
            cols = slices([f > thr for f in col_light], W, 3, int(W * 0.06))
            found.append([(a, top, b, bot) for a, b in cols])
            total += len(cols)
        if total == expect:
            print('seams found at a threshold of %.2f' % thr)
            return found
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('sheet')
    ap.add_argument('--write', metavar='SLUG',
                    help='save as assets/images/story_SLUG_N.png')
    ap.add_argument('--expect', type=int,
                    help='how many panels the story has lines for')
    ap.add_argument('--no-uniform', action='store_true',
                    help='keep the raw crops instead of one common size')
    ap.add_argument('--nudge', action='append', default=[],
                    metavar='N:SIDE:PIXELS',
                    help='move one panel edge in, e.g. 5:left:17 — for art '
                         'that overlaps its own frame')
    args = ap.parse_args()

    im = Image.open(args.sheet).convert('RGB')
    print('sheet: %dx%d' % im.size)
    bg, bands = find_panels(im)
    print('background: %s' % (bg,))

    # Two kinds of sheet arrive. One stands its panels on a background, and
    # the gutters can be found by colour. The other packs them edge to edge
    # with a hairline seam between. Try the first; if it does not produce the
    # number of panels the story has lines for, try the second.
    if args.expect is not None:
        total = sum(len(b) for b in bands)
        if total != args.expect:
            print('the gutters gave %d, not %d — looking for seams instead'
                  % (total, args.expect))
            seams = find_panels_by_seams(im, args.expect)
            if seams is not None:
                bands = seams

    panels = []
    for i, band in enumerate(bands, 1):
        print('row %d holds %d panels:' % (i, len(band)))
        for (x0, y0, x1, y1) in band:
            print('    x %4d..%-4d  y %4d..%-4d   %dx%d'
                  % (x0, x1, y0, y1, x1 - x0, y1 - y0))
            panels.append((x0, y0, x1, y1))

    # A drawing that pokes out of its own frame lands in the neighbour when
    # the sheet is cut along the seam. The seam is still the right place to
    # cut, so the fix is to pull that one edge in — recorded in the command
    # rather than done by hand afterwards, so cutting the sheet again gives
    # the same panels.
    for spec in args.nudge:
        try:
            n, side, amount = spec.split(':')
            n, amount = int(n), int(amount)
            x0, y0, x1, y1 = panels[n - 1]
            if side == 'left':
                x0 += amount
            elif side == 'right':
                x1 -= amount
            elif side == 'top':
                y0 += amount
            elif side == 'bottom':
                y1 -= amount
            else:
                sys.exit('nudge side must be left, right, top or bottom')
            panels[n - 1] = (x0, y0, x1, y1)
            print('panel %d: %s edge pulled in %d' % (n, side, amount))
        except (ValueError, IndexError):
            sys.exit('could not read --nudge %s (want N:SIDE:PIXELS)' % spec)

    print('%d panels in all' % len(panels))
    if args.expect is not None and len(panels) != args.expect:
        sys.exit('expected %d — nothing written. Look at the rows above: a '
                 'panel whose gutter is not quite background merges with its '
                 'neighbour, and the tolerance in near() is what to widen.'
                 % args.expect)
    if not args.write:
        print('nothing written (pass --write SLUG)')
        return

    box = None
    if not args.no_uniform:
        w = max(x1 - x0 for x0, _, x1, _ in panels)
        h = max(y1 - y0 for _, y0, _, y1 in panels)
        box = (w, h)
        print('every panel centred in %dx%d' % box)

    os.makedirs(OUT_DIR, exist_ok=True)
    for n, (x0, y0, x1, y1) in enumerate(panels, 1):
        crop = im.crop((x0, y0, x1, y1))
        if box is not None:
            canvas = Image.new('RGB', box, bg)
            canvas.paste(crop, ((box[0] - crop.width) // 2,
                                (box[1] - crop.height) // 2))
            crop = canvas
        path = os.path.join(OUT_DIR, 'story_%s_%d.png' % (args.write, n))
        crop.save(path)
        print('wrote %s  %dx%d' % (os.path.relpath(path, ROOT), *crop.size))

    print('\nNow add them to the story in lib/data/magbasa_content.dart:')
    print("      'linePictures': [")
    for n in range(1, len(panels) + 1):
        print("        'assets/images/story_%s_%d.png'," % (args.write, n))
    print('      ],')


if __name__ == '__main__':
    main()
