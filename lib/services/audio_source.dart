import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where a bundled recording lives, in a way this platform can fetch twice.
///
/// A workaround for audioplayers 6.6.0, kept in one place so it can be
/// removed in one place when the package is fixed.
///
/// `AssetSource` resolves through `AudioCache`, which re-checks whether the
/// cached file still exists on disk whenever an asset has been loaded before:
///
///     if (!needsFetch &&
///         defaultTargetPlatform == TargetPlatform.android &&
///         !await fileSystem.file(loadedFiles[fileName]).exists()) {
///
/// `fileSystem.file` is `dart:io`, and the only guard in front of it is
/// `defaultTargetPlatform`, which on Flutter web reports the *host*. On an
/// Android phone in Chrome the guard passes and `dart:io` is reached inside a
/// browser: `Unsupported operation: _Namespace`.
///
/// It is only reached once the asset is in the cache, so the first play of a
/// recording works and every play after it throws in under a millisecond.
/// That is one sound per file per session — a poem that plays once and then
/// never again, and background music that stops the moment a module hands it
/// back.
///
/// On web the asset is served at a plain URL, so it is asked for directly and
/// the cache is never consulted. Everywhere else keeps `AssetSource` and the
/// Android check it was written for.
Source audioSourceFor(String assetPath) =>
    kIsWeb ? UrlSource('assets/assets/$assetPath') : AssetSource(assetPath);

/// Whether [assetPath] (as passed to [audioSourceFor]) was actually bundled.
///
/// Some recordings are named in the content before they exist — the family
/// voices are still to be recorded (see assets/audio/family/README.txt).
/// Asking for one anyway put a 404 in the console on every answer and, on a
/// phone, an error from the player; checking the app's own list of assets
/// first lets a missing recording simply stay silent.
Future<bool> audioAssetBundled(String assetPath) async {
  _bundled ??= AssetManifest.loadFromAssetBundle(rootBundle)
      .then((m) => m.listAssets().toSet(), onError: (_) => <String>{});
  final all = await _bundled!;
  // An empty list means the manifest could not be read: play and see.
  return all.isEmpty || all.contains('assets/$assetPath');
}

Future<Set<String>>? _bundled;
