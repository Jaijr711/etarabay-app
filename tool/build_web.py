# -*- coding: utf-8 -*-
"""Build the web release and stamp the service worker.

`flutter build web` copies `web/sw.js` into the build untouched, and an
untouched service worker is a broken one for two reasons:

  * It has no build stamp, so its shell cache is named the same after every
    build. The browser would keep serving the previous `main.dart.js` and the
    phone would show the old app — the exact fault the no-cache dev server
    exists to prevent.

  * It has no list of what to download, so a picture or a recording would
    only be held after the child had already opened that module online. A
    module they have never opened would still need a connection, which is
    the whole thing the cache is for.

Both are filled in here, from the build that was actually produced. The stamp
is a hash of the code and of the asset list, so it changes when — and only
when — something the browser must re-fetch has changed. That the file's own
bytes change is what makes the browser install the new worker at all.

    python tool/build_web.py [extra flutter build args]
"""
import hashlib
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'build', 'web')

# Audio last. The warm-up runs while a child is using the app, and 27 MB of
# background music must not stand in front of the pictures they are looking at.
LAST = ('.mp3', '.wav', '.m4a', '.ogg')


def run_build(extra):
    cmd = ['flutter', 'build', 'web', '--release'] + extra
    print('$ ' + ' '.join(cmd), flush=True)
    if subprocess.call(cmd, cwd=ROOT, shell=(os.name == 'nt')) != 0:
        sys.exit('build failed — service worker not stamped')


def warm_list():
    """Every picture and recording the build shipped, as served paths."""
    base = os.path.join(OUT, 'assets')
    if not os.path.isdir(base):
        sys.exit('no assets in the build — nothing to stamp')
    early, late = [], []
    for dirpath, _, names in os.walk(base):
        for n in sorted(names):
            full = os.path.join(dirpath, n)
            rel = os.path.relpath(full, OUT).replace(os.sep, '/')
            (late if n.lower().endswith(LAST) else early).append(rel)
    return sorted(early) + sorted(late)


# Never worth holding: debug symbol maps that only a developer reads, the
# CanvasKit folder (the worker picks its own variant at install), and the
# deprecated Flutter worker we no longer register.
SKIP_DIRS = ('assets', 'canvaskit')
SKIP_FILES = ('sw.js', 'flutter_service_worker.js', 'version.json')
SKIP_EXT = ('.map', '.symbols')


def shell_extra():
    """The rest of the shell: the splash pictures, the icons, the bootstrap.

    Written by hand at first, and the splash was left out — with the server
    down the app opened to a blank white page instead of its own logo. Reading
    it off the build cannot forget a file the build produced.
    """
    out = []
    for dirpath, dirs, names in os.walk(OUT):
        rel_dir = os.path.relpath(dirpath, OUT).replace(os.sep, '/')
        if rel_dir == '.':
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for n in sorted(names):
            # Dotfiles are the build tool's own bookkeeping (`.last_build_id`),
            # never fetched by the page.
            if (n.startswith('.') or n in SKIP_FILES
                    or n.lower().endswith(SKIP_EXT)):
                continue
            rel = os.path.relpath(os.path.join(dirpath, n), OUT)
            out.append(rel.replace(os.sep, '/'))
    return sorted(out)


def asset_hashes(paths):
    """A short content hash of every held picture and recording.

    The worker keeps these between builds and drops any cached file whose
    hash changed. Without them a picture redrawn under the same name (the
    Kulay Saya daisy in paint4.png) stayed the old one on every phone that
    had already opened the page.
    """
    out = {}
    for rel in paths:
        h = hashlib.sha1()
        with open(os.path.join(OUT, rel), 'rb') as f:
            for chunk in iter(lambda: f.read(1 << 20), b''):
                h.update(chunk)
        out[rel] = h.hexdigest()[:12]
    return out


def stamp(paths, hashes):
    """Changes when the code, the file list, or the worker itself changes.

    The worker was left out at first, and changing how it caches left the
    stamp — and so the cache name — untouched: a fixed worker would have
    gone on reading the cache the broken one filled. `sw.js` has not been
    stamped yet at this point, so this hashes the source as written.
    """
    h = hashlib.sha1()
    for name in ('main.dart.js', 'sw.js'):
        with open(os.path.join(OUT, name), 'rb') as f:
            for chunk in iter(lambda: f.read(1 << 20), b''):
                h.update(chunk)
    h.update('\n'.join(paths).encode('utf-8'))
    h.update(json.dumps(hashes, sort_keys=True).encode('utf-8'))
    return h.hexdigest()[:12]


def write_sw(build_id, paths, extra, hashes):
    p = os.path.join(OUT, 'sw.js')
    with open(p, encoding='utf-8') as f:
        s = f.read()
    for old, new in (
        ("const BUILD = 'dev';", "const BUILD = '%s';" % build_id),
        ('const WARM = [];', 'const WARM = %s;' % json.dumps(paths)),
        ('const SHELL_EXTRA = [];',
         'const SHELL_EXTRA = %s;' % json.dumps(extra)),
        ('const ASSET_HASHES = {};',
         'const ASSET_HASHES = %s;' % json.dumps(hashes, sort_keys=True)),
    ):
        if s.count(old) != 1:
            sys.exit('sw.js: %d matches for %r — not stamped' % (s.count(old), old))
        s = s.replace(old, new, 1)
    with open(p, 'w', encoding='utf-8', newline='') as f:
        f.write(s)


if __name__ == '__main__':
    run_build(sys.argv[1:])
    paths = warm_list()
    extra = shell_extra()
    hashes = asset_hashes(paths)
    build_id = stamp(paths + extra, hashes)
    write_sw(build_id, paths, extra, hashes)
    total = sum(os.path.getsize(os.path.join(OUT, p)) for p in paths + extra)
    print('stamped sw.js  build %s  %d shell + %d assets  %.1f MB held offline'
          % (build_id, len(extra), len(paths), total / 1048576.0))
