# -*- coding: utf-8 -*-
"""Makes the small update patches for a release.

A phone with an older version downloads only the patch (a few MB) and
builds the new APK from the one it has installed, instead of the whole
117 MB. See lib/services/apk_patch.dart, which applies them.

    python tool/make_patches.py <new.apk> <new-version> <old.apk>:<old-version> ...

Writes next to <new.apk>:
    E-Tarabay-<old>-to-<new>.patch   one per old APK
    patches.json                     what the app reads to choose one

Needs bsdiff4 (pip install bsdiff4), best in a venv:
    python -m venv .venv && .venv/Scripts/pip install bsdiff4

The patch format (ETPATCH1) is bsdiff's, with the three blocks
compressed by zlib instead of bzip2, which Dart reads with no package:
    "ETPATCH1"  ctrl_len (8)  diff_len (8)  new_size (8)    little-endian
    zlib(ctrl)  zlib(diff)  zlib(extra)
ctrl_len and diff_len are the compressed sizes. Each ctrl entry is three
8-byte numbers in bsdiff's sign-and-magnitude form: bytes to add from
diff, bytes to copy from extra, and how far to move in the old file.
"""
import bz2
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

import bsdiff4


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def make_patch(old: bytes, new: bytes) -> bytes:
    p = bsdiff4.diff(old, new)
    assert p[:8] == b'BSDIFF40'
    ctrl_len, diff_len, new_size = struct.unpack('<qqq', p[8:32])
    ctrl = bz2.decompress(p[32:32 + ctrl_len])
    diff = bz2.decompress(p[32 + ctrl_len:32 + ctrl_len + diff_len])
    extra = bz2.decompress(p[32 + ctrl_len + diff_len:])
    c, d, e = (zlib.compress(b, 9) for b in (ctrl, diff, extra))
    return b'ETPATCH1' + struct.pack('<qqq', len(c), len(d), new_size) + c + d + e


def offtin(b):
    y = int.from_bytes(b[:7] + bytes([b[7] & 0x7F]), 'little')
    return -y if b[7] & 0x80 else y


def apply_patch(old: bytes, patch: bytes) -> bytes:
    """The same as the app does, to check each patch before it ships."""
    assert patch[:8] == b'ETPATCH1'
    ctrl_len, diff_len, new_size = struct.unpack('<qqq', patch[8:32])
    ctrl = zlib.decompress(patch[32:32 + ctrl_len])
    diff = zlib.decompress(patch[32 + ctrl_len:32 + ctrl_len + diff_len])
    extra = zlib.decompress(patch[32 + ctrl_len + diff_len:])
    out = bytearray()
    op = cp = dp = ep = 0
    while len(out) < new_size:
        x, y, z = (offtin(ctrl[cp + 8 * i:cp + 8 * i + 8]) for i in range(3))
        cp += 24
        chunk = bytearray(diff[dp:dp + x])
        for i in range(x):
            if 0 <= op + i < len(old):
                chunk[i] = (chunk[i] + old[op + i]) & 0xFF
        out += chunk
        dp += x
        op += x
        out += extra[ep:ep + y]
        ep += y
        op += z
    return bytes(out)


def main():
    new_apk, new_version, olds = Path(sys.argv[1]), sys.argv[2], sys.argv[3:]
    new = new_apk.read_bytes()
    entries = []
    for spec in olds:
        path, version = spec.rsplit(':', 1)
        old = Path(path).read_bytes()
        patch = make_patch(old, new)
        if apply_patch(old, patch) != new:
            sys.exit(f'patch from {version} does not rebuild the new APK')
        name = f'E-Tarabay-{version}-to-{new_version}.patch'
        out = new_apk.parent / name
        out.write_bytes(patch)
        entries.append({
            'from': version,
            'fromSha256': hashlib.sha256(old).hexdigest(),
            'patch': name,
            'patchSize': len(patch),
            'patchSha256': hashlib.sha256(patch).hexdigest(),
            'toSha256': hashlib.sha256(new).hexdigest(),
            'toSize': len(new),
        })
        print(f'{name}: {len(patch) / 1048576:.1f} MB')
    (new_apk.parent / 'patches.json').write_text(
        json.dumps({'version': new_version, 'patches': entries}, indent=1))


if __name__ == '__main__':
    main()
