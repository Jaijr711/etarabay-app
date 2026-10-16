import 'package:flutter/material.dart';
import 'fun_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/app_localizations.dart';

/// The centered card shown when a child taps a module the developer
/// dashboard has locked. Replaces a plain SnackBar — a locked module is a
/// dead-end for the child, not a passing toast, so it gets the same
/// designed, must-acknowledge treatment as an admin message.
Future<void> showLockedModuleDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => FunDialog(
      child: FunMessage(
        picture: const FunCoin(icon: LucideIcons.lock, tone: Color(0xFFE5484D)),
        message: loc.moduleLocked,
        buttons: [
          FunPillButton(
            label: loc.okButton,
            colors: FunColors.purple,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    ),
  );
}
