import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // PIN specific keys
  static const String _keyUserPin = 'user_pin';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  /// Saves the PIN securely in the phone's Keystore/Keychain.
  Future<void> savePin(String pin) async {
    await _storage.write(key: _keyUserPin, value: pin);
  }

  /// Retrieves the securely stored PIN.
  Future<String?> getPin() async {
    return await _storage.read(key: _keyUserPin);
  }

  /// Saves the user email associated with the PIN.
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Retrieves the stored email.
  Future<String?> getEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Saves the user name associated with the account.
  Future<void> saveName(String name) async {
    await _storage.write(key: _keyUserName, value: name);
  }

  /// Retrieves the stored name.
  Future<String?> getName() async {
    return await _storage.read(key: _keyUserName);
  }

  /// Clears local PIN, email, and name (e.g., on logout or reset).
  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyUserPin);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserName);
  }

  /// Checks if a PIN exists on this device.
  Future<bool> hasPin() async {
    String? pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }
}
