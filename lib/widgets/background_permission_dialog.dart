import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

/// Shown once, right after a parent turns "Notifications" on in Settings.
///
/// Several common phone brands (Oppo, Vivo, Realme, Xiaomi and others) kill
/// a closed app's scheduled reminders outright unless the app is manually
/// whitelisted in that phone's own Battery/Autostart settings — no error,
/// nothing in this app's control, the notification just never arrives. Since
/// it is the child, as often as the parent, who is holding the phone right
/// after switching the setting on, the wording here is simple enough for
/// either of them to read and pass along, rather than assuming a parent is
/// the one looking at the screen.
Future<void> showBackgroundPermissionDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(loc.bgPermissionTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Text(loc.bgPermissionBody),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(loc.gotIt),
        ),
      ],
    ),
  );
}
