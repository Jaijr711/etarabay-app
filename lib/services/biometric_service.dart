import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles device biometric (fingerprint / face) authentication and the
/// encrypted storage of login credentials so users can skip typing their
/// password on trusted devices.
///
/// IMPORTANT: biometric here is a *convenience unlock* — the phone only
/// confirms the owner is present, then we release the credential that was
/// saved (encrypted) after a successful real login. Credentials live only in
/// the OS-backed secure store (Android Keystore / iOS Keychain), never in
/// plain prefs, and never leave the device.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Credential slots. Only one teacher and one student can be remembered per
  // device at a time (re-enabling simply overwrites the slot).
  static const String teacherKey = 'teacher';
  static String studentKey = 'student';

  // ── Availability ──────────────────────────────────────────────────────────

  /// True only if the device supports biometrics AND the user has at least one
  /// fingerprint/face enrolled. If false, the biometric toggle should be hidden
  /// or disabled and the user falls back to password login.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric sheet. Returns true on success. Never throws —
  /// any failure (cancel, no hardware, too many attempts) resolves to false so
  /// callers can cleanly fall back to password entry.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Allow device PIN/pattern as a fallback so a failed scan never
          // locks anyone out completely.
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Credential storage ──────────────────────────────────────────────────────

  /// Save credentials for a slot after a verified login, marking biometric as
  /// enabled for that slot. [extra] holds optional display info (e.g. name).
  static Future<void> saveCredentials({
    required String slot,
    required String username,
    required String password,
    Map<String, String> extra = const {},
  }) async {
    await _storage.write(key: '${slot}_bio_user', value: username);
    await _storage.write(key: '${slot}_bio_pass', value: password);
    for (final e in extra.entries) {
      await _storage.write(key: '${slot}_bio_${e.key}', value: e.value);
    }
  }

  /// Returns {username, password, ...extra} for a slot, or null if none saved.
  static Future<Map<String, String>?> getCredentials(String slot) async {
    final username = await _storage.read(key: '${slot}_bio_user');
    final password = await _storage.read(key: '${slot}_bio_pass');
    if (username == null || password == null) return null;
    final result = <String, String>{
      'username': username,
      'password': password,
    };
    final name = await _storage.read(key: '${slot}_bio_name');
    if (name != null) result['name'] = name;
    return result;
  }

  /// True if this slot currently has remembered credentials.
  static Future<bool> isEnabled(String slot) async {
    return (await _storage.read(key: '${slot}_bio_pass')) != null;
  }

  /// Remove remembered credentials for a slot (disable biometric login).
  static Future<void> clearCredentials(String slot) async {
    await _storage.delete(key: '${slot}_bio_user');
    await _storage.delete(key: '${slot}_bio_pass');
    await _storage.delete(key: '${slot}_bio_name');
  }
}
