import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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
