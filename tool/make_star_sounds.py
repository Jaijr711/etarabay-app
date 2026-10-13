# -*- coding: utf-8 -*-
"""Synthesise the three star sounds, and draw what was made.

    python tool/make_star_sounds.py

One sound per star, and they are not three of the same thing:

    one star     C, rung once and left to ring
    two stars    C then E — consonant, so two is never heard as a mistake
    three stars  G, and then the run keeps climbing: C E G C above it,
                 landing on a chord that rings for two and a half seconds

That last one is the point of the whole file. A child of four is not reading
the sentence on the card, so the difference between "you finished it" and "you
got everything right" has to arrive through their ears — and it has to last
long enough to feel like something happened.

Written rather than downloaded so it ships in the bundle and works with no
connection, which is the rule the whole app is built on. Pillow is needed for
the picture only.
"""
import math
import os
import struct
import wave

from PIL import Image, ImageDraw

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
OUT_PNG = os.path.join(ROOT, "docs", "previews", "star_waves.png")

C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98

# (ratio to the fundamental, how loud, how fast it dies)
# A struck bell's overtones fade faster than its body, which is most of what
# separates a chime from an organ.
PARTIALS = [
    (1.00, 1.00, 0.85),
    (2.00, 0.42, 0.55),
    (3.00, 0.20, 0.38),
    (4.20, 0.11, 0.26),
    (6.00, 0.06, 0.20),
]


def chime(freq, seconds, ring=1.0, gain=1.0):
    """One struck bell, left to ring for [seconds]."""
    n = int(SR * seconds)
    out = []
    for i in range(n):
        t = i / SR
        s = 0.0
        for ratio, amp, tau in PARTIALS:
            s += amp * math.sin(2 * math.pi * freq * ratio * t) * math.exp(
                -t / (tau * ring))
        out.append(s * gain)

    # 4ms of attack. Starting at full amplitude is a click, and a click on
    # top of a chime is what makes a cheap app sound cheap.
    attack = int(SR * 0.004)
    for i in range(attack):
        out[i] *= i / attack
    return out


def bed(seconds):
    return [0.0] * int(SR * seconds)


def mix_into(base, samples, at_seconds):
    start = int(SR * at_seconds)
    for i, v in enumerate(samples):
        j = start + i
        if j < len(base):
            base[j] += v
    return base


def finish(samples, fade_seconds=0.25):
    """Glide the tail out and bring the peak to a safe height."""
    n = len(samples)
    fade = int(SR * fade_seconds)
    for i in range(fade):
        samples[n - 1 - i] *= i / fade
    peak = max(abs(v) for v in samples) or 1.0
    return [v * 0.85 / peak for v in samples]


def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32768, min(32767, int(v * 32767))))
            for v in samples))


def one_note(freq, seconds=1.60):
    return finish(chime(freq, seconds, ring=1.25))


def flourish():
    """The third star: a run up, then a chord left ringing."""
    total = 2.80
    out = bed(total)

    # The star's own note, struck with the star.
    mix_into(out, chime(G5, 2.60, ring=1.6), 0.00)

    # Then the climb, quick enough to be one gesture rather than four events.
    for i, freq in enumerate([C6, E6, G6]):
        mix_into(out, chime(freq, 2.40 - i * 0.2, ring=1.5, gain=0.72 - i * 0.1),
                 0.13 + i * 0.13)

    # And the chord it lands on, quietly underneath, so the ringing has a
    # floor to sit on instead of thinning out to a single sine.
    for freq, gain in [(C5, 0.5), (E5, 0.34), (G5, 0.3)]:
        mix_into(out, chime(freq, 2.20, ring=1.8, gain=gain), 0.52)

    return finish(out, fade_seconds=0.45)


os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)

made = []
for i, samples in enumerate([one_note(C5), one_note(E5), flourish()]):
    path = os.path.join(OUT_DIR, "star_%d.wav" % (i + 1))
    write_wav(path, samples)
    made.append((path, samples))
    print("wrote %s  (%.0f ms, %d KB)" % (
        path, len(samples) / SR * 1000, os.path.getsize(path) / 1024))

# Draw the three, so the shape of each can be looked at rather than assumed.
W, H = 900, 300
img = Image.new("RGB", (W, H), (246, 244, 255))
d = ImageDraw.Draw(img)
band = H // 3
longest = max(len(s) for _, s in made)
for row, (path, samples) in enumerate(made):
    mid = band * row + band // 2
    d.line([(0, mid), (W, mid)], fill=(214, 209, 234))
    # All three on the same time axis, so their lengths can be compared.
    step = longest / W
    for x in range(W):
        chunk = samples[int(x * step):int((x + 1) * step)] or [0]
        hi, lo = max(chunk), min(chunk)
        d.line(
            [(x, mid - hi * (band // 2 - 6)), (x, mid - lo * (band // 2 - 6))],
            fill=(255, 184, 0) if row == 2 else (99, 102, 241))
    d.text((8, band * row + 6), os.path.basename(path), fill=(90, 88, 110))
img.save(OUT_PNG)
print("wrote %s" % OUT_PNG)
