import 'package:flutter/material.dart';
import 'fun_dialog.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';
import 'update_flow.dart';

/// The one prompt a sideloaded install gets in place of a store's own
/// "update available" banner. Shown once per app open at most — see the
/// call site — never blocking: "Later" leaves the current version exactly
/// as usable as it already was.
Future<void> showUpdateAvailableDialog(
    BuildContext context, UpdateInfo update) {
  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => FunDialog(
      child: FunMessage(
        picture: const FunCoin(
            icon: Icons.system_update_rounded, tone: Color(0xFF2F7FD6)),
        title: loc.updateAvailableTitle,
        message: loc.updateAvailableBody(update.versionName),
        body: Column(mainAxisSize: MainAxisSize.min, children: [
          // How big it is, before a parent on mobile data says yes.
          if (update.downloadSize > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                loc.updateSizeNote(megabytes(update.downloadSize)),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          if (update.notes != null && update.notes!.trim().isNotEmpty)
            // Release notes can run long; they scroll inside the card.
            ConstrainedBox(
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
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ),
              ),
            ),
        ]),
        buttons: [
          FunPillButton(
            label: loc.updateLater,
            colors: FunColors.grey,
            onTap: () => Navigator.pop(dialogContext),
          ),
          FunPillButton(
            label: loc.updateDownloadNow,
            icon: Icons.system_update_rounded,
            colors: FunColors.green,
            onTap: () async {
              Navigator.pop(dialogContext);
              // Downloaded and installed by the app itself, so no copy is
              // left in Downloads; the website only where that cannot be.
              if (UpdateFlow.supported && update.apkUrl != null) {
                if (context.mounted) await UpdateFlow.start(context, update);
                return;
              }
              final opened =
                  await UpdateChecker.instance.openUpdatePage(update);
              // Updates come only from the website, so when the browser
              // will not open it the address is shown to type in.
              if (!opened) {
                messenger?.showSnackBar(SnackBar(
                  content: Text(
                      loc.updateOpenWebsite(UpdateChecker.downloadPageUrl)),
                  duration: const Duration(seconds: 10),
                ));
              }
            },
          ),
        ],
      ),
    ),
  );
}
