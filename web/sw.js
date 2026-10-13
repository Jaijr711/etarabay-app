'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  E-Tarabay offline cache
//
//  The app is for daycare children who may have no connection at all, and it
//  had none of this: the service worker Flutter generates unregisters itself
//  on activation, so nothing was ever held. Firestore's own persistence kept
//  the child's *progress* offline, which hid the gap — the data survived, the
//  app it belonged to would not open.
//
//  Two caches, because they go stale for different reasons:
//
//    shell   the code — index.html, main.dart.js, CanvasKit. Replaced whole
//            on every build, so its name carries the build stamp and the old
//            one is deleted the moment a new worker takes over. This is what
//            stops "the phone is still showing the old build".
//
//    assets  the pictures and the recordings — 50 MB that almost never
//            change and must never be downloaded twice. Survives a rebuild.
//
//  Both lines below are rewritten by tool/build_web.py after every build.
//  Unstamped, the worker deliberately falls back to network-first, so an
//  unstamped build can never serve stale code from a previous one.
// ─────────────────────────────────────────────────────────────────────────────

const BUILD = 'dev';
const WARM = [];
const SHELL_EXTRA = [];

const STAMPED = BUILD !== 'dev';
const SHELL = 'etarabay-shell-' + BUILD;
const ASSETS = 'etarabay-assets-v1';

/// Both CanvasKit builds, because guessing which one is wrong.
///
/// The loader picks the chromium variant when the browser has ImageDecoder
/// and the Chromium break iterators, and the full one otherwise. This worker
/// first ran that same test on itself — and a service worker is not a page:
/// `ImageDecoder` is not defined in its scope, so it decided "not chromium",
/// held the 6.9 MB full build, and the page then asked for the chromium one.
/// With the connection gone the app got as far as loading its own code and
/// then died fetching the renderer, which is a worse failure than not
/// caching at all: everything looked cached.
///
/// The page's request could not be cached on the way past either — on a first
/// visit the renderer is fetched before the worker has claimed the page.
///
/// So both are held. It costs about 7 MB once, and it cannot be wrong.
const CANVASKIT = [
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
];

const SHELL_FILES = [
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
].concat(SHELL_EXTRA).concat(CANVASKIT);

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(SHELL);
      // Each file on its own. `cache.addAll` rejects the whole batch if one
      // entry 404s, and a single missing file would leave the child with no
      // worker at all rather than an incomplete one.
      for (const file of SHELL_FILES) {
        try {
          await cache.add(new Request(file, { cache: 'reload' }));
        } catch (e) {
          console.warn('shell: could not cache', file, e);
        }
      }
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keep = new Set([SHELL, ASSETS]);
      for (const name of await caches.keys()) {
        if (!keep.has(name)) await caches.delete(name);
      }
      await self.clients.claim();
      // Not awaited. Activation must not sit behind 50 MB of downloads.
      warmAssets();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  // Firestore and Firebase Auth are left alone entirely. Their answers are
  // per-child and change constantly; Firestore keeps its own offline copy and
  // a cached reply here would hand a child someone else's stale progress.
  if (url.origin !== self.location.origin) return;

  if (req.mode === 'navigate') {
    event.respondWith(networkFirst(req));
    return;
  }
  if (url.pathname.includes('/assets/')) {
    event.respondWith(cacheFirst(req, ASSETS));
    return;
  }
  event.respondWith(STAMPED ? cacheFirst(req, SHELL) : networkFirst(req));
});

/// Never fetched twice. For a recording or a picture the cached copy is the
/// right answer forever — the path changes when the file does.
async function cacheFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  const hit = await cache.match(req, { ignoreSearch: true });
  if (hit) return hit;
  try {
    const res = await fetch(req);
    if (res && res.ok) await cache.put(req, res.clone());
    return res;
  } catch (e) {
    const any = await caches.match(req, { ignoreSearch: true });
    if (any) return any;
    throw e;
  }
}

/// The newest build wins whenever there is a connection; the cached one is
/// what the child gets when there is not.
async function networkFirst(req) {
  try {
    const res = await fetch(req);
    if (res && res.ok) {
      const cache = await caches.open(SHELL);
      await cache.put(req, res.clone());
    }
    return res;
  } catch (e) {
    const hit = await caches.match(req, { ignoreSearch: true });
    if (hit) return hit;
    if (req.mode === 'navigate') {
      const index = await caches.match('index.html', { ignoreSearch: true });
      if (index) return index;
    }
    throw e;
  }
}

/// Fetches every picture and recording in the background, once.
///
/// Caching on first use would only make a module work offline *after* the
/// child had already done it online, which is not the promise. The list is
/// written in by the build, so a module the child has never opened still
/// works with the connection gone.
///
/// One file at a time, on purpose: this runs while the child is using the
/// app, and it must not take the connection away from what they are doing.
async function warmAssets() {
  const cache = await caches.open(ASSETS);
  for (const path of WARM) {
    try {
      if (await cache.match(path, { ignoreSearch: true })) continue;
      await cache.add(new Request(path, { cache: 'reload' }));
    } catch (e) {
      // A file that will not download is not worth stopping the rest for.
    }
  }
}
