import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Whether this phone's parent has read the privacy notice, and when.
class PrivacyNotice {
  PrivacyNotice._();

  static const _key = 'privacy_notice_ack_v1';

  static Future<bool> isAcknowledged(SharedPreferences prefs) async =>
      (prefs.getString(_key) ?? '').isNotEmpty;

  static Future<void> acknowledge(SharedPreferences prefs) =>
      prefs.setString(_key, DateTime.now().toIso8601String());
}

/// What the app keeps about a child, why, who sees it, for how long, and
/// what a parent can ask for — said plainly, as the Data Privacy Act asks.
///
/// Shown once to the parent at the child's first sign-in, before they make
/// their code ([requireAcknowledge]: no way back, one button that records
/// it), and readable again from the parents' account screen and the
/// teacher's privacy agreement.
class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key, this.requireAcknowledge = false});

  final bool requireAcknowledge;

  Future<void> _acknowledge(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await PrivacyNotice.acknowledge(prefs);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).padding.bottom;
    final items = [
      (
        LucideIcons.clipboard_list,
        AppColors.primary,
        loc.pnCollectTitle,
        loc.pnCollectBody
      ),
      (
        LucideIcons.target,
        const Color(0xFF22A6A4),
        loc.pnWhyTitle,
        loc.pnWhyBody
      ),
      (LucideIcons.eye, AppColors.secondary, loc.pnWhoTitle, loc.pnWhoBody),
      (
        LucideIcons.clock,
        const Color(0xFFE08A00),
        loc.pnKeepTitle,
        loc.pnKeepBody
      ),
      (
        LucideIcons.scale,
        const Color(0xFF2E9E5B),
        loc.pnRightsTitle,
        loc.pnRightsBody
      ),
      (
        LucideIcons.circle_alert,
        const Color(0xFFC2334D),
        loc.pnProblemTitle,
        loc.pnProblemBody
      ),
    ];

    return PopScope(
      canPop: !requireAcknowledge,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _band(context, loc),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      children: [
                        for (final item in items) ...[
                          _item(item.$1, item.$2, item.$3, item.$4),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (requireAcknowledge)
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottom),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEF0F5))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _acknowledge(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(LucideIcons.check, size: 20),
                    label: Text(loc.pnAcknowledge),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _band(BuildContext context, AppLocalizations loc) {
    Widget circle(double size) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x14FFFFFF),
          ),
        );
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -30, child: circle(150)),
          Positioned(right: 60, bottom: -50, child: circle(100)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.shield_check,
                            color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      if (!requireAcknowledge)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          icon: const Icon(LucideIcons.x, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc.privacyNoticeTitle,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.privacyNoticeSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x55FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scale,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          loc.lawPill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, Color color, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
