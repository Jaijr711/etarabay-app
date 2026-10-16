import 'package:flutter/material.dart';
import 'fun_dialog.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';

/// The one prompt a sideloaded install gets in place of a store's own
/// "update available" banner. Shown once per app open at most — see the
/// call site — never blocking: "Later" leaves the current version exactly
/// as usable as it already was.
Future<void> showUpdateAvailableDialog(
    BuildContext context, UpdateInfo update) {
  final loc = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => FunDialog(
      child: FunMessage(
        picture: const FunCoin(
            icon: Icons.system_update_rounded, tone: Color(0xFF2F7FD6)),
        title: loc.updateAvailableTitle,
        message: loc.updateAvailableBody(update.versionName),
        body: update.notes == null || update.notes!.trim().isEmpty
            ? null
            // Release notes can run long; they scroll inside the card.
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(update.notes!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ),
                ),
              ),
        buttons: [
          FunPillButton(
            label: loc.updateLater,
            colors: FunColors.grey,
            onTap: () => Navigator.pop(dialogContext),
          ),
          FunPillButton(
            label: loc.updateDownloadNow,
            icon: Icons.download_rounded,
            colors: FunColors.green,
            onTap: () {
              Navigator.pop(dialogContext);
              UpdateChecker.instance.openDownload(update.apkUrl);
            },
          ),
        ],
      ),
    ),
  );
}
