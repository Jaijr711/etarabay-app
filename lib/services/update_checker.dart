import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version.dart';

/// Checks for a newer build outside the Play Store — GitHub's own "latest
/// release" API, read against the repo the APK is published to.
///
/// This is the whole "update" story for a sideloaded install: there is no
/// store to push through, so the app has to ask on its own. A release is
/// offered as an update when its tag names a version newer than the one
/// installed — publishing a release tagged `vX.Y.Z` (matching
/// `pubspec.yaml`'s `version: X.Y.Z+<build>`) with the APK attached is the
/// whole publishing step; nothing else needs configuring here. The update
/// itself is installed from the download website, never from the app.
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker instance = UpdateChecker._();

  /// The repo releases are published to. Public, so this needs no token —
  /// the same reason the download website links here directly instead of
  /// Google Drive, which gates a large file behind a scan page first.
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/Jaijr711/etarabay-releases/releases/latest';

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
      final res = await http.get(Uri.parse(_latestReleaseUrl), headers: const {
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

      return UpdateInfo(
        versionName: remoteVersion,
        pageUrl: updatePageUrl(info.version),
        notes: (notes != null && notes.trim().isNotEmpty) ? notes : null,
      );
    } catch (e) {
      debugPrint('UpdateChecker: $e');
      return null;
    }
  }

  /// Opens the download website for [update] in the device's own browser.
  /// Updates are installed only from there — the app never fetches the
  /// APK itself, not even when the page will not open. False then, so the
  /// caller can show the address to type in by hand.
  Future<bool> openUpdatePage(UpdateInfo update) async {
    try {
      return await launchUrl(Uri.parse(update.pageUrl),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UpdateChecker: page not opened: $e');
      return false;
    }
  }
}

class UpdateInfo {
  final String versionName;

  /// The download website, told which version is installed.
  final String pageUrl;
  final String? notes;

  const UpdateInfo({
    required this.versionName,
    required this.pageUrl,
    this.notes,
  });
}
