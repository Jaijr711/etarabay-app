import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/biometric_service.dart';
import '../utils/constants.dart';

/// Turning fingerprint login on or off, once.
///
/// The teacher's settings and the parent's account each had their own copy of
/// this: the same confirm dialog, the same verify-then-scan-then-save order,
/// the same four messages. A third of `parent_account_screen.dart` was
/// line-for-line the teacher's file, and the halves had already begun to
/// drift — the parent's asked for the Student Number in a numeric field, the
/// teacher's did not, and only one of them said so in the label.
///
/// What actually differs between the two is small and is passed in: which
/// slot the credentials are saved under, what the password is called, how it
/// is checked, and what is stored alongside it.
///
/// Returns whether biometric login is on when it finishes, so the caller can
/// set its switch from the answer rather than guessing.
Future<bool> setBiometricEnabled({
  required BuildContext context,
  required bool enable,
  required String slot,

  /// What to call the password in the confirm dialog — the teacher's own
  /// password, or the child's Student Number.
  required String passwordLabel,

  /// Student Numbers are digits; a teacher password is not.
  required bool numericPassword,

  /// Checks the typed password. Returning false shows [wrongPasswordMessage]
  /// and stops.
  required Future<bool> Function(String password) verify,
  required String wrongPasswordMessage,

  /// What to store once the password is confirmed.
  required Future<Map<String, dynamic>> Function(String password) credentials,

  /// How this screen shows a message.
  required void Function(String message, IconData icon, Color colour) notify,
}) async {
  final loc = AppLocalizations.of(context)!;

  if (!enable) {
    await BiometricService.clearCredentials(slot);
    notify(loc.biometricDisabled, LucideIcons.fingerprint_pattern,
        AppColors.primary);
    return false;
  }

  // Confirm the password first. A fingerprint that unlocks an account has to
  // be registered by someone who could already get in without it.
  final passCtrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(loc.enableBiometric, style: const TextStyle(fontSize: 18)),
      content: TextField(
        controller: passCtrl,
        obscureText: true,
        keyboardType: numericPassword ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: passwordLabel,
          prefixIcon: Icon(
              numericPassword ? LucideIcons.key_round : LucideIcons.lock,
              size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: Text(loc.continueLabel),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  final password = passCtrl.text.trim();
  if (!await verify(password)) {
    notify(wrongPasswordMessage, LucideIcons.circle_alert, Colors.red);
    return false;
  }

  if (!await BiometricService.authenticate(loc.scanToEnableBiometric)) {
    notify(loc.biometricNotConfirmed, LucideIcons.circle_alert, Colors.red);
    return false;
  }

  final creds = await credentials(password);
  await BiometricService.saveCredentials(
    slot: slot,
    username: (creds['username'] ?? '').toString(),
    password: password,
    extra: (creds['extra'] as Map<String, String>?) ?? const {},
  );
  notify(loc.biometricEnabled, LucideIcons.circle_check, AppColors.success);
  return true;
}
