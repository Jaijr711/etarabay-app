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
//            change and must never be downloaded twice. Survives a rebuild —
//            except a file whose content changed under the same name (a
//            coloring page redrawn as paint4.png kept showing the old
//            picture), which is dropped on activation by its content hash.
//
//  The lines below are rewritten by tool/build_web.py after every build.
//  Unstamped, the worker deliberately falls back to network-first, so an
//  unstamped build can never serve stale code from a previous one.
// ─────────────────────────────────────────────────────────────────────────────

const BUILD = 'dev';
const WARM = [];
const SHELL_EXTRA = [];
const ASSET_HASHES = {};

const STAMPED = BUILD !== 'dev';
const SHELL = 'etarabay-shell-' + BUILD;
// v2: v1 caches were filled before hashes were recorded, so nothing in them
// can be told apart from a stale copy. Renaming drops them once.
const ASSETS = 'etarabay-assets-v2';

/// Where the hashes of what the assets cache holds are kept between workers.
const HASHES_KEY = '__asset_hashes__';

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
      if (STAMPED) await dropChangedAssets();
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

/// Removes every held picture or recording whose content this build changed
/// (or no longer ships), then records this build's hashes for the next one.
async function dropChangedAssets() {
  const cache = await caches.open(ASSETS);
  let held = {};
  try {
    const saved = await cache.match(HASHES_KEY);
    if (saved) held = await saved.json();
  } catch (e) {
    held = {};
  }
  for (const path of Object.keys(held)) {
    if (held[path] !== ASSET_HASHES[path]) {
      await cache.delete(path, { ignoreSearch: true });
    }
  }
  // Anything held without a recorded hash cannot be trusted either.
  for (const req of await cache.keys()) {
    const path = new URL(req.url).pathname.replace(/^\//, '');
    if (path !== HASHES_KEY && !(path in held && path in ASSET_HASHES)) {
      await cache.delete(req);
    }
  }
  await cache.put(
    HASHES_KEY,
    new Response(JSON.stringify(ASSET_HASHES), {
      headers: { 'Content-Type': 'application/json' },
    }),
  );
}

/// Never fetched twice. A picture changed under the same name is dropped on
/// activation by dropChangedAssets, so the cached copy is otherwise right.
async function cacheFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  const hit = await cache.match(req, { ignoreSearch: true });
  if (hit) return hit;
  try {
    // Past the browser's own HTTP cache too: it would happily hand back the
    // old picture the worker just dropped.
    const res = await fetch(req, { cache: 'no-cache' });
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
