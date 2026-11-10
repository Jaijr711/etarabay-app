import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'apk_patch.dart';
import 'app_version.dart';

/// Checks for a newer build outside the Play Store — GitHub's own "latest
/// release" API, read against the repo the APK is published to.
///
/// This is the whole "update" story for a sideloaded install: there is no
/// store to push through, so the app has to ask on its own. A release is
/// offered as an update when its tag names a version newer than the one
/// installed — publishing a release tagged `vX.Y.Z` (matching
/// `pubspec.yaml`'s `version: X.Y.Z+<build>`) with the APK attached is the
/// whole publishing step; nothing else needs configuring here.
///
/// The update is downloaded by the app itself, into its own cache, and
/// handed to Android's installer; the file is deleted on the next start.
/// It used to be fetched by the browser from the download website, and
/// every update left another 117 MB `E-Tarabay (n).apk` in Downloads that
/// nothing ever deleted. The website stays as the fallback.
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker instance = UpdateChecker._();

  /// The repo releases are published to. Public, so this needs no token —
  /// the same reason the download website links here directly instead of
  /// Google Drive, which gates a large file behind a scan page first.
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/Jaijr711/etarabay-releases/releases/latest';

  /// A test build can be pointed at one pre-release instead
  /// (`--dart-define=UPDATE_RELEASE=v1.2.61-test`), which "latest" never
  /// shows, so an update can be tried on a phone before it is released.
  static const String _testRelease = String.fromEnvironment('UPDATE_RELEASE');
  static String get _releaseUrl => _testRelease.isEmpty
      ? _latestReleaseUrl
      : 'https://api.github.com/repos/Jaijr711/etarabay-releases/releases/tags/'
          '$_testRelease';

  /// The download website (site/index.html, published from the releases
  /// repo). The update button opens it rather than the bare APK: the parent
  /// sees what is new and the install steps, and taps Update there — the
  /// same page they first installed from.
  static const String downloadPageUrl =
      'https://jaijr711.github.io/etarabay-releases/';

  /// The website for someone on [installedVersion]: with it, the page says
  /// an update is waiting and its button reads Update.
  static String updatePageUrl(String installedVersion) =>
      '$downloadPageUrl?v=${Uri.encodeQueryComponent(installedVersion)}';

  /// Null on web (there is nothing to sideload there), on any network or
  /// parsing failure, or when the installed build is already current —
  /// callers do not need to tell "no update" apart from "couldn't check".
  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      final res = await http.get(Uri.parse(_releaseUrl), headers: const {
        'Accept': 'application/vnd.github+json'
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = '${json['tag_name'] ?? ''}';
      final remoteVersion = tag.startsWith('v') ? tag.substring(1) : tag;
      if (remoteVersion.isEmpty) return null;

      final info = await PackageInfo.fromPlatform();
      if (AppVersion.compare(remoteVersion, info.version) <= 0) return null;

      final notes = json['body'] as String?;
      final apk = pickApk(json['assets']);

      return UpdateInfo(
        versionName: remoteVersion,
        pageUrl: updatePageUrl(info.version),
        notes: (notes != null && notes.trim().isNotEmpty) ? notes : null,
        apkUrl: apk?.url,
        apkSize: apk?.size ?? 0,
        patch:
            apk == null ? null : await _patchFor(json['assets'], info.version),
      );
    } catch (e) {
      debugPrint('UpdateChecker: $e');
      return null;
    }
  }

  /// Opens the download website for [update] in the device's own browser:
  /// the fallback when the in-app download fails. False when the page will
  /// not open, so the caller can show the address to type in by hand.
  Future<bool> openUpdatePage(UpdateInfo update) async {
    try {
      return await launchUrl(Uri.parse(update.pageUrl),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UpdateChecker: page not opened: $e');
      return false;
    }
  }

  /// The APK a release offers: `E-Tarabay.apk` (the website's choice too),
  /// otherwise the first `.apk`. Null when there is none.
  static ({String url, int size})? pickApk(Object? assets) {
    if (assets is! List) return null;
    final apks = [
      for (final a in assets)
        if (a is Map && '${a['name']}'.toLowerCase().endsWith('.apk')) a
    ];
    if (apks.isEmpty) return null;
    final a = apks.firstWhere((a) => a['name'] == 'E-Tarabay.apk',
        orElse: () => apks.first);
    final url = '${a['browser_download_url'] ?? ''}';
    if (url.isEmpty) return null;
    return (url: url, size: (a['size'] as num?)?.toInt() ?? 0);
  }

  /// Where updates are downloaded: the app's own cache, which only the app
  /// sees and Android may clear. Never Downloads.
  static Future<Directory> downloadsFolder() async =>
      Directory('${(await getTemporaryDirectory()).path}/update');

  /// Deletes the downloaded updates this phone no longer needs: those for
  /// the installed version or older. Run at each start. One for a newer
  /// version stays — it is still waiting at the installer, and the next
  /// tap of Update uses it instead of downloading 117 MB again.
  static Future<void> cleanUpDownloads(
      {Directory? folder, String? installedVersion}) async {
    if (kIsWeb) return;
    try {
      final dir = folder ?? await downloadsFolder();
      if (!await dir.exists()) return;
      final installed =
          installedVersion ?? (await PackageInfo.fromPlatform()).version;
      var kept = 0;
      await for (final f in dir.list()) {
        final v =
            RegExp(r'E-Tarabay-([^/\\]+)\.apk$').firstMatch(f.path)?.group(1);
        if (f is File && v != null && AppVersion.compare(v, installed) > 0) {
          kept++;
        } else {
          await f.delete(recursive: true);
        }
      }
      if (kept == 0) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('UpdateChecker: clean up: $e');
    }
  }

  /// The patch from [installed] to the release, from the release's
  /// `patches.json` (made by tool/make_patches.py). Null when there is none
  /// for this version, or it cannot be read: the whole APK is used then.
  Future<PatchInfo?> _patchFor(Object? assets, String installed) async {
    try {
      if (assets is! List) return null;
      String? urlOf(String name) {
        for (final a in assets) {
          if (a is Map && a['name'] == name) {
            return '${a['browser_download_url'] ?? ''}';
          }
        }
        return null;
      }

      final listUrl = urlOf('patches.json');
      if (listUrl == null || listUrl.isEmpty) return null;
      final res = await http
          .get(Uri.parse(listUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return pickPatch(jsonDecode(res.body), installed, urlOf);
    } catch (e) {
      debugPrint('UpdateChecker: patches: $e');
      return null;
    }
  }

  /// The entry in a `patches.json` for [installed], with its download
  /// address from [urlOf] (the release's assets by name).
  static PatchInfo? pickPatch(
      Object? list, String installed, String? Function(String name) urlOf) {
    if (list is! Map || list['patches'] is! List) return null;
    for (final p in list['patches'] as List) {
      if (p is! Map || p['from'] != installed) continue;
      final url = urlOf('${p['patch']}');
      if (url == null || url.isEmpty) return null;
      return PatchInfo(
        url: url,
        size: (p['patchSize'] as num?)?.toInt() ?? 0,
        fromSha256: '${p['fromSha256']}',
        toSha256: '${p['toSha256']}',
        toSize: (p['toSize'] as num?)?.toInt() ?? 0,
      );
    }
    return null;
  }

  /// Downloads [update]'s APK into [downloadsFolder], reporting the bytes
  /// received. Completes with the file, or throws: on a failed request, on
  /// [cancel] completing, or when the file is not the size the release
  /// says (a download cut short is never handed to the installer).
  Future<File> downloadApk(
    UpdateInfo update, {
    required void Function(int received, int total) onProgress,
    Future<void>? cancel,
    http.Client? client,
    Directory? folder,
  }) async {
    final url = update.apkUrl;
    if (url == null) throw StateError('no apk in the release');
    final dir = folder ?? await downloadsFolder();
    final file = File('${dir.path}/E-Tarabay-${update.versionName}.apk');
    // Already here whole, from a try that stopped at the installer (the
    // parent closed it, or the app was restarted): not downloaded again.
    if (update.apkSize > 0 &&
        await file.exists() &&
        await file.length() == update.apkSize) {
      onProgress(update.apkSize, update.apkSize);
      return file;
    }
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    await _fetch(url, file, update.apkSize,
        onProgress: onProgress, cancel: cancel, client: client);
    return file;
  }

  /// The update built from the installed APK at [installedApk] and the
  /// release's small patch: a few MB downloaded instead of 117. Throws when
  /// anything does not match (the installed APK is not the one the patch
  /// was made from, or the result is not the release's APK byte for byte),
  /// and the caller downloads the whole APK instead.
  Future<File> buildFromPatch(
    UpdateInfo update,
    String installedApk, {
    required void Function(int received, int total) onProgress,
    required void Function() onPreparing,
    Future<void>? cancel,
    http.Client? client,
    Directory? folder,
  }) async {
    final patch = update.patch;
    if (patch == null) throw StateError('no patch for this version');
    final dir = folder ?? await downloadsFolder();
    final apk = File('${dir.path}/E-Tarabay-${update.versionName}.apk');
    if (patch.toSize > 0 &&
        await apk.exists() &&
        await apk.length() == patch.toSize) {
      onProgress(patch.size, patch.size);
      return apk;
    }
    if (await ApkPatch.sha256Of(installedApk) != patch.fromSha256) {
      throw StateError('the installed APK is not the one patched from');
    }
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final patchFile = File('${dir.path}/E-Tarabay-${update.versionName}.patch');
    final building = File('${apk.path}.part');
    try {
      await _fetch(patch.url, patchFile, patch.size,
          onProgress: onProgress, cancel: cancel, client: client);
      onPreparing();
      final from = installedApk, p = patchFile.path, out = building.path;
      // Its own isolate: the app stays smooth while 117 MB is written.
      await Isolate.run(() => ApkPatch.apply(from, p, out));
      if (await building.length() != patch.toSize ||
          await ApkPatch.sha256Of(building.path) != patch.toSha256) {
        throw StateError('the built APK is not the release');
      }
      await building.rename(apk.path);
      return apk;
    } catch (e) {
      if (await building.exists()) await building.delete();
      rethrow;
    } finally {
      if (await patchFile.exists()) await patchFile.delete();
    }
  }

  /// Downloads [url] into [file], reporting progress; see [downloadApk].
  Future<void> _fetch(
    String url,
    File file,
    int expectedSize, {
    required void Function(int received, int total) onProgress,
    Future<void>? cancel,
    http.Client? client,
  }) async {
    final http.Client c = client ?? http.Client();
    var cancelled = false;
    StreamSubscription<List<int>>? sub;
    IOSink? sink;
    try {
      final response = await c
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final total = response.contentLength ?? expectedSize;
      sink = file.openWrite();
      var received = 0;
      final done = Completer<void>();
      unawaited(cancel?.then((_) {
        cancelled = true;
        sub?.cancel();
        if (!done.isCompleted) done.completeError(StateError('cancelled'));
      }));
      sub = response.stream
          // A stalled connection: nothing for 30 seconds.
          .timeout(const Duration(seconds: 30))
          .listen((chunk) {
        sink!.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }, onError: (Object e) {
        if (!done.isCompleted) done.completeError(e);
      }, onDone: () {
        if (!done.isCompleted) done.complete();
      }, cancelOnError: true);
      await done.future;
      await sink.flush();
      await sink.close();
      sink = null;
      final expected = expectedSize > 0 ? expectedSize : total;
      if (expected > 0 && await file.length() != expected) {
        throw const HttpException('incomplete download');
      }
    } catch (e) {
      await sink?.close();
      if (await file.exists()) await file.delete();
      if (cancelled) throw StateError('cancelled');
      rethrow;
    } finally {
      if (client == null) c.close();
    }
  }
}

class UpdateInfo {
  final String versionName;

  /// The download website, told which version is installed.
  final String pageUrl;
  final String? notes;

  /// The release's APK and its size in bytes, for the in-app download.
  /// Null and 0 when the release has none.
  final String? apkUrl;
  final int apkSize;

  /// The small patch from the installed version, when the release has one.
  final PatchInfo? patch;

  const UpdateInfo({
    required this.versionName,
    required this.pageUrl,
    this.notes,
    this.apkUrl,
    this.apkSize = 0,
    this.patch,
  });

  /// What the parent will download: the patch when there is one.
  int get downloadSize => patch?.size ?? apkSize;
}

/// One patch from `patches.json`: from the installed APK to the release's.
class PatchInfo {
  const PatchInfo({
    required this.url,
    required this.size,
    required this.fromSha256,
    required this.toSha256,
    required this.toSize,
  });

  final String url;
  final int size;
  final String fromSha256;
  final String toSha256;
  final int toSize;
}
