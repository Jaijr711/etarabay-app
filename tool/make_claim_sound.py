# -*- coding: utf-8 -*-
"""Synthesise the sound of a medal being claimed on the awards shelf.

    python tool/make_claim_sound.py

It follows the animation (lib/widgets/badge_claim_celebration.dart):

    0.0 - 1.3 s   the gold light grows behind the locked medal: small
                  bells climbing, faster and louder, over a soft swell
    1.3 s         the lock opens: one bright chord, struck, left to ring
    1.3 - 2.8 s   the chord rings out while the sparkles fall

Written rather than downloaded, like tool/make_star_sounds.py, so it ships in
the bundle and works with no connection.
"""
import math
import os
import struct
import wave

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio", "sfx", "claim.wav")
UNLOCK = 1.30

# Pentatonic around G: no two neighbours clash, so a quick run is a shimmer.
RUN = [783.99, 880.00, 987.77, 1174.66, 1318.51, 1567.98, 1760.00, 1975.53,
       2349.32, 2637.02]
C5, E5, G5, C6, E6, G6, C7 = (523.25, 659.25, 783.99, 1046.50, 1318.51,
                              1567.98, 2093.00)

# A struck bell: overtones that fade faster than the body.
PARTIALS = [(1.00, 1.00, 0.85), (2.00, 0.42, 0.55), (3.00, 0.20, 0.38),
            (4.20, 0.11, 0.26), (6.00, 0.06, 0.20)]


def chime(freq, seconds, ring=1.0, gain=1.0):
    n = int(SR * seconds)
    out = [0.0] * n
    for ratio, amp, tau in PARTIALS:
        w = 2 * math.pi * freq * ratio / SR
        k = 1.0 / (tau * ring * SR)
        for i in range(n):
            out[i] += amp * math.sin(w * i) * math.exp(-i * k)
    attack = int(SR * 0.004)  # no click at the start
    for i in range(min(attack, n)):
        out[i] *= i / attack
    return [v * gain for v in out]


def swell(freq, start, end, gain):
    """A soft held tone that grows towards the unlock, then lets go."""
    n = int(SR * (end - start))
    out = []
    for i in range(n):
        t = i / n
        env = (t ** 2) * (1 - max(0.0, (t - 0.9) / 0.1))
        out.append(gain * env * (math.sin(2 * math.pi * freq * i / SR) +
                                 0.3 * math.sin(4 * math.pi * freq * i / SR)))
    return out


def mix(base, samples, at):
    s = int(SR * at)
    for i, v in enumerate(samples):
        if s + i < len(base):
            base[s + i] += v


def main():
    total = 2.9
    out = [0.0] * int(SR * total)

    # The light growing: the bells come closer together and louder.
    t = 0.05
    for i, f in enumerate(RUN):
        p = i / (len(RUN) - 1)
        mix(out, chime(f, 0.9, ring=0.45, gain=0.10 + 0.22 * p), t)
        t += 0.16 - 0.09 * p
    mix(out, swell(G5 / 2, 0.15, UNLOCK, 0.10), 0.15)

    # The unlock: the chord, with a high bell on top for the flash.
    for f, g, ring in [(C5, 0.55, 1.8), (E5, 0.40, 1.8), (G5, 0.38, 1.8),
                       (C6, 0.60, 1.6), (E6, 0.38, 1.4), (G6, 0.30, 1.2),
                       (C7, 0.26, 0.9)]:
        mix(out, chime(f, total - UNLOCK, ring=ring, gain=g), UNLOCK)
    # A sparkle falling after it, as the confetti does.
    for i, f in enumerate([2637.02, 2349.32, 1975.53, 2349.32, 1760.00]):
        mix(out, chime(f, 0.6, ring=0.35, gain=0.10), UNLOCK + 0.18 + i * 0.12)

    fade = int(SR * 0.4)
    for i in range(fade):
        out[len(out) - 1 - i] *= i / fade
    peak = max(abs(v) for v in out) or 1.0
    out = [v * 0.85 / peak for v in out]

    with wave.open(OUT, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32768, min(32767, int(v * 32767))))
            for v in out))
    print("wrote %s (%.1f s, %d KB)" % (OUT, total, os.path.getsize(OUT) // 1024))


if __name__ == "__main__":
    main()
