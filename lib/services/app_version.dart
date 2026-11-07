import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The version this copy of the app is, and how two versions compare — for
/// the update popup, for the version each phone reports to the developer
/// dashboard, and for the minimum version the dashboard can require.
class AppVersion {
  AppVersion._();

  static Future<PackageInfo?>? _info;

  /// The installed package, read once. Null when the platform cannot say.
  static Future<PackageInfo?> _read() => _info ??= PackageInfo.fromPlatform()
          .then<PackageInfo?>((info) => info)
          .catchError((Object e) {
        debugPrint('AppVersion: $e');
        return null;
      });

  /// "1.2.57", or null when the platform cannot say.
  static Future<String?> current() async => (await _read())?.version;

  /// "70", or null.
  static Future<String?> build() async => (await _read())?.buildNumber;

  /// Forgets the version read, for a test that mocks a new one.
  @visibleForTesting
  static void reset() => _info = null;

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
  static int compare(String a, String b) {
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
  static int _leadingInt(String part) {
    final match = RegExp(r'^\d+').firstMatch(part);
    return match == null ? 0 : int.parse(match.group(0)!);
  }
}
