import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';
import '../utils/constants.dart';

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
            child: const Icon(Icons.system_update_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(loc.updateAvailableTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.updateAvailableBody(update.versionName)),
          if (update.notes != null && update.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(update.notes!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(loc.updateLater),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.pop(dialogContext);
            UpdateChecker.instance.openDownload(update.apkUrl);
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(loc.updateDownloadNow),
        ),
      ],
    ),
  );
}
