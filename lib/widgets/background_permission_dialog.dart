import 'package:flutter/material.dart';
import 'fun_dialog.dart';

import '../l10n/app_localizations.dart';

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
    builder: (dialogContext) => FunDialog(
      child: FunMessage(
        picture: const FunCoin(
            icon: Icons.notifications_active_rounded, tone: Color(0xFF2F7FD6)),
        title: loc.bgPermissionTitle,
        message: loc.bgPermissionBody,
        buttons: [
          FunPillButton(
            label: loc.gotIt,
            colors: FunColors.purple,
            onTap: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}
