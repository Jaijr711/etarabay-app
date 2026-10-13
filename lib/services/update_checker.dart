import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks for a newer build outside the Play Store — GitHub's own "latest
/// release" API, read against the repo the APK is published to.
///
/// This is the whole "update" story for a sideloaded install: there is no
/// store to push through, so the app has to ask on its own. A release is
/// offered as an update when its tag names a version newer than the one
/// installed — publishing a release tagged `vX.Y.Z` (matching
/// `pubspec.yaml`'s `version: X.Y.Z+<build>`) with the APK attached as its
/// one asset is the whole publishing step; nothing else needs configuring
/// here.
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker instance = UpdateChecker._();

  /// The repo releases are published to. Public, so this needs no token —
  /// the same reason the download website links here directly instead of
  /// Google Drive, which gates a large file behind a scan page first.
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/Jaijr711/etarabay-releases/releases/latest';

  /// Null on web (there is nothing to sideload there), on any network or
  /// parsing failure, or when the installed build is already current —
  /// callers do not need to tell "no update" apart from "couldn't check".
  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      final res = await http.get(Uri.parse(_latestReleaseUrl), headers: const {
        'Accept': 'application/vnd.github+json'
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = '${json['tag_name'] ?? ''}';
      final remoteVersion = tag.startsWith('v') ? tag.substring(1) : tag;
      if (remoteVersion.isEmpty) return null;

      final info = await PackageInfo.fromPlatform();
      if (_compareVersions(remoteVersion, info.version) <= 0) return null;

      final assets = json['assets'] as List<dynamic>? ?? [];
      if (assets.isEmpty) return null;
      final apkUrl = (assets.first
          as Map<String, dynamic>)['browser_download_url'] as String?;
      if (apkUrl == null || apkUrl.isEmpty) return null;

      final notes = json['body'] as String?;

      return UpdateInfo(
        versionName: remoteVersion,
        apkUrl: apkUrl,
        notes: (notes != null && notes.trim().isNotEmpty) ? notes : null,
      );
    } catch (e) {
      debugPrint('UpdateChecker: $e');
      return null;
    }
  }

  /// -1, 0 or 1 the way [Comparable] expects. Each side is compared
  /// part-by-part with the shorter one padded with zeros, so "1.2" and
  /// "1.2.0" compare equal instead of one side running out of parts —
  /// a plain string compare would also get "1.10.0" wrong against "1.9.0".
  ///
  /// Each part is read by its leading digits, not parsed whole — a release
  /// tag left over from testing (say "v1.2.17-g") once silently fell back
  /// to 0 on its last part, and that made the app think the newest real
  /// release was older than everything already installed, so nobody was
  /// ever offered an update at all.
  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(_leadingInt).toList();
    final partsB = b.split('.').map(_leadingInt).toList();
    final len = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (var i = 0; i < len; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  /// The digits a version part starts with, as a number — "17-g" reads as
  /// 17, "17" reads as 17, "-g" (nothing before the suffix) reads as 0.
  int _leadingInt(String part) {
    final match = RegExp(r'^\d+').firstMatch(part);
    return match == null ? 0 : int.parse(match.group(0)!);
  }

  /// Hands the download to the device's own browser rather than fetching
  /// the APK here and installing it directly. Android takes it from
  /// there: downloads the file, then offers its own "install unknown app"
  /// flow — the same one every sideloaded app already goes through, well
  /// tested and already familiar to anyone who has installed one before.
  /// Fetching the bytes and driving a FileProvider/install-intent by hand
  /// would need its own storage and install permissions for no real gain
  /// over a flow Android already owns end to end.
  Future<void> openDownload(String apkUrl) {
    return launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication);
  }
}

class UpdateInfo {
  final String versionName;
  final String apkUrl;
  final String? notes;

  const UpdateInfo({
    required this.versionName,
    required this.apkUrl,
    this.notes,
  });
}
