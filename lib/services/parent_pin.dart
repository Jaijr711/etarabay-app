import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// The parent's own code, kept once for the device.
///
/// It used to be kept per child — `parent_pin_<studentId>` — which meant a
/// parent with two children had two codes to remember, one of which they only
/// ever needed when they happened to be looking at the younger one. The code
/// belongs to the parent, not to a child, so there is one.
///
/// Because of that, removing a child from the device must not remove it, and
/// switching between children inside the report must not ask for it again.
class ParentPin {
  ParentPin._();

  static const String _key = 'parent_pin';

  /// The old per-child prefix, still read once so nobody is locked out.
  static const String _legacyPrefix = 'parent_pin_';

  /// The stored code, adopting an older per-child one if that is all there is.
  ///
  /// A parent who set a code under the old scheme keeps it: theirs is simply
  /// promoted to the device's, and the per-child copies are cleared so the two
  /// schemes cannot disagree later.
  static Future<String?> read(SharedPreferences prefs) async {
    final current = prefs.getString(_key);
    if (current != null && current.isNotEmpty) return current;

    final legacy = prefs
        .getKeys()
        .where((k) => k.startsWith(_legacyPrefix) && k != _key)
        .toList()
      ..sort();
    for (final k in legacy) {
      final value = prefs.getString(k);
      if (value != null && value.isNotEmpty) {
        await prefs.setString(_key, value);
        for (final old in legacy) {
          await prefs.remove(old);
        }
        return value;
      }
    }
    // Nothing to adopt, but clear any empty leftovers so this runs once.
    for (final old in legacy) {
      await prefs.remove(old);
    }
    return null;
  }

  /// Whether the parent has made a code yet.
  static Future<bool> isSet(SharedPreferences prefs) async =>
      (await read(prefs))?.isNotEmpty ?? false;

  /// Stores a code, hashed with the same pepper the LRN uses.
  static Future<void> write(SharedPreferences prefs, String pin) async {
    await prefs.setString(_key, AuthService.hashLrn(pin.trim()));
  }

  /// Whether [pin] is the stored code.
  static Future<bool> matches(SharedPreferences prefs, String pin) async {
    final stored = await read(prefs);
    if (stored == null || stored.isEmpty) return false;
    return stored == AuthService.hashLrn(pin.trim());
  }
}
