import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

/// The centered card shown when a child taps a module the developer
/// dashboard has locked. Replaces a plain SnackBar — a locked module is a
/// dead-end for the child, not a passing toast, so it gets the same
/// designed, must-acknowledge treatment as an admin message.
Future<void> showLockedModuleDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.lock,
                  color: AppColors.secondary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              loc.moduleLocked,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(loc.okButton),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
