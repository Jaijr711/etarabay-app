{{flutter_js}}
{{flutter_build_config}}

// E-Tarabay loads itself without Flutter's service worker. That worker
// unregisters itself on activation, and while it is registered it replaces
// ours (web/sw.js, registered from index.html), which is what holds the app
// for a child with no connection. CanvasKit comes from this site, not from
// gstatic, so it is held offline with the rest of the app.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
