import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What happened when a PIN was tried.
enum PinCheck { ok, wrong, blocked }

/// The teacher's 4-digit PIN that opens the dashboard on this phone.
///
/// Kept on the phone only, salted and hashed in the OS secure store (Android
/// Keystore / iOS Keychain), never in Firestore. In a browser the secure
/// store only works on an https page, and the app is served over plain http
/// on the school's network, so there the salted hash goes to the browser's
/// own storage instead. Five wrong tries in a row
/// stop the PIN working: then only the teacher's account password opens the
/// dashboard, and a new PIN is made. The count of wrong tries is kept too,
/// so closing the app does not give five more.
class TeacherPin {
  TeacherPin._();

  static const int length = 4;
  static const int maxTries = 5;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _hashKey = 'teacher_pin_hash';
  static const _saltKey = 'teacher_pin_salt';
  static const _triesKey = 'teacher_pin_tries';

  /// Whether the OS secure store is used. False in a browser, and from the
  /// first time the store fails on a phone, so a PIN never gets stuck.
  @visibleForTesting
  static bool useSecureStorage = !kIsWeb;

  static Future<String?> _read(String key) async {
    if (useSecureStorage) {
      try {
        final value = await _storage.read(key: key);
        if (value != null) return value;
      } catch (e) {
        debugPrint('Secure storage unavailable, using app storage: $e');
        useSecureStorage = false;
      }
    }
    return (await SharedPreferences.getInstance()).getString(key);
  }

  static Future<void> _write(String key, String value) async {
    if (useSecureStorage) {
      try {
        await _storage.write(key: key, value: value);
        return;
      } catch (e) {
        debugPrint('Secure storage unavailable, using app storage: $e');
        useSecureStorage = false;
      }
    }
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  static Future<void> _delete(String key) async {
    try {
      if (useSecureStorage) await _storage.delete(key: key);
    } catch (_) {}
    await (await SharedPreferences.getInstance()).remove(key);
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  /// Whether a PIN has been made on this phone.
  static Future<bool> isSet() async =>
      (await _read(_hashKey))?.isNotEmpty ?? false;

  /// Wrong tries since the last right one.
  static Future<int> tries() async =>
      int.tryParse(await _read(_triesKey) ?? '') ?? 0;

  /// Whether too many wrong tries have stopped the PIN working.
  static Future<bool> isBlocked() async => await tries() >= maxTries;

  /// Makes [pin] the PIN, and forgets any wrong tries.
  static Future<void> save(String pin) async {
    final random = Random.secure();
    final salt =
        base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
    await _write(_saltKey, salt);
    await _write(_hashKey, _hash(salt, pin));
    await _write(_triesKey, '0');
  }

  /// Tries [pin], counting a wrong one.
  static Future<PinCheck> check(String pin) async {
    if (await isBlocked()) return PinCheck.blocked;
    final salt = await _read(_saltKey) ?? '';
    final stored = await _read(_hashKey) ?? '';
    if (stored.isNotEmpty && stored == _hash(salt, pin)) {
      await _write(_triesKey, '0');
      return PinCheck.ok;
    }
    final now = await tries() + 1;
    await _write(_triesKey, '$now');
    return now >= maxTries ? PinCheck.blocked : PinCheck.wrong;
  }

  /// Forgets the PIN on this phone, so a new one has to be made.
  static Future<void> clear() async {
    await _delete(_hashKey);
    await _delete(_saltKey);
    await _delete(_triesKey);
  }
}
