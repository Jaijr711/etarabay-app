# -*- coding: utf-8 -*-
"""Synthesise the balloon pop, and draw what was made.

    python tool/make_pop_sound.py

Writes assets/audio/pop.wav, and beside the balloon sheet a picture of
the waveform so the shape of the sound can be looked at. Pillow is
needed for the picture only.

A pop is three things happening at once: the crack of the rubber letting go,
a short burst of air, and the low thump of the balloon's own volume
collapsing. Written rather than downloaded so it ships in the bundle and works
with no connection, which is the rule the whole app is built on.
"""
import math
import os
import random
import struct
import wave

from PIL import Image, ImageDraw

SR = 44100
DUR = 0.20
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_WAV = os.path.join(ROOT, "assets", "audio", "sfx", "pop.wav")
OUT_PNG = os.path.join(ROOT, "docs", "previews", "pop_wave.png")

n = int(SR * DUR)
random.seed(4)
noise = [random.uniform(-1, 1) for _ in range(n)]


def lowpass(xs, fc):
    rc = 1.0 / (2 * math.pi * fc)
    a = (1.0 / SR) / (rc + 1.0 / SR)
    y, out = 0.0, []
    for x in xs:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(xs, fc):
    rc = 1.0 / (2 * math.pi * fc)
    a = rc / (rc + 1.0 / SR)
    y, prev, out = 0.0, 0.0, []
    for x in xs:
        y = a * (y + x - prev)
        prev = x
        out.append(y)
    return out


def env(t, tau):
    return math.exp(-t / tau)


# The crack: broadband, gone in a few milliseconds. Rolled off at the top so
# it is a pop and not a hiss — this plays a foot from a three-year-old's ear.
crack = lowpass(noise, 6500)
crack_peak = max(abs(v) for v in crack) or 1.0
crack = [v / crack_peak for v in crack]

# The air leaving: darker, and it lasts a little longer than the crack.
air = lowpass(noise, 2400)
air_peak = max(abs(v) for v in air) or 1.0
air = [v / air_peak for v in air]

# The room the pop happened in.
tail = lowpass(noise, 700)
tail_peak = max(abs(v) for v in tail) or 1.0
tail = [v / tail_peak for v in tail]

mix = []
phase = 0.0
for i in range(n):
    t = i / SR
    # The thump: the balloon's own volume collapsing, pitched down as it goes.
    freq = 185 * math.exp(-t / 0.05) + 58
    phase += 2 * math.pi * freq / SR
    thump = math.sin(phase) * env(t, 0.045)

    s = (1.00 * crack[i] * env(t, 0.0055) +
         0.62 * air[i] * env(t, 0.048) +
         0.50 * thump +
         0.13 * tail[i] * env(t, 0.085))
    mix.append(s)

# Keep the smallest speakers out of trouble, and start from silence so the
# first sample is not a click of its own.
mix = highpass(mix, 95)
fade_in = int(SR * 0.0006)
for i in range(fade_in):
    mix[i] *= i / fade_in
fade_out = int(SR * 0.02)
for i in range(fade_out):
    mix[n - 1 - i] *= i / fade_out

peak = max(abs(v) for v in mix) or 1.0
mix = [v * 0.9 / peak for v in mix]

os.makedirs(os.path.dirname(OUT_WAV), exist_ok=True)
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
with wave.open(OUT_WAV, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(
        struct.pack("<h", max(-32768, min(32767, int(v * 32767)))) for v in mix))

# Draw it, so the shape of the sound can be looked at rather than assumed.
W, H = 900, 260
img = Image.new("RGB", (W, H), (246, 244, 255))
d = ImageDraw.Draw(img)
d.line([(0, H // 2), (W, H // 2)], fill=(210, 205, 230))
step = n / W
for x in range(W):
    lo = min(mix[int(x * step):int((x + 1) * step)] or [0])
    hi = max(mix[int(x * step):int((x + 1) * step)] or [0])
    d.line([(x, H // 2 - hi * (H // 2 - 8)), (x, H // 2 - lo * (H // 2 - 8))],
           fill=(66, 133, 244))
for ms in (25, 50, 100, 150, 200):
    x = int((ms / 1000) * SR / step)
    d.line([(x, 0), (x, H)], fill=(230, 226, 245))
    d.text((x + 3, 4), "%dms" % ms, fill=(120, 116, 140))
img.save(OUT_PNG)

print("wrote %s  (%.0f ms, %d KB)" % (
    OUT_WAV, DUR * 1000, os.path.getsize(OUT_WAV) / 1024))
print("wrote %s" % OUT_PNG)
