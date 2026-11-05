import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../utils/constants.dart';

/// One of the six modules as the report shows it: the key its progress and
/// resets are stored under, its name, colour and sign.
typedef ReportModule = ({
  String key,
  String name,
  Color colour,
  IconData icon,
});

/// The six modules, in the order the child meets them at home, each in the
/// colour it uses everywhere else in the app.
List<ReportModule> reportModules(AppLocalizations loc) => [
      (
        key: 'matematika',
        name: loc.matematika,
        colour: const Color(0xFF2C7BE5),
        icon: LucideIcons.calculator,
      ),
      (
        key: 'pamilya',
        name: loc.angAkingSarili.replaceAll('\n', ' '),
        colour: const Color(0xFF2E9E5B),
        icon: LucideIcons.user,
      ),
      (
        key: 'kulay',
        name: loc.kulaySaya,
        colour: const Color(0xFFEC4899),
        icon: LucideIcons.palette,
      ),
      (
        key: 'traceit',
        name: loc.traceItTitle,
        colour: const Color(0xFFE08A00),
        icon: LucideIcons.pencil,
      ),
      (
        key: 'magbasa',
        name: loc.magbasaTitle,
        colour: const Color(0xFF7C3AED),
        icon: LucideIcons.book_open,
      ),
      (
        key: 'tandaan',
        name: loc.tandaanTitle,
        colour: const Color(0xFF1E88C7),
        icon: LucideIcons.brain,
      ),
    ];

/// A section title on the report: a violet sign, the words, and how many
/// there are when that helps.
class ReportSectionHeader extends StatelessWidget {
  const ReportSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.count,
  });

  final String title;
  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (count != null)
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }
}

/// A module's sign on a soft square of its own colour.
class ReportModuleIcon extends StatelessWidget {
  const ReportModuleIcon({
    super.key,
    required this.icon,
    required this.colour,
    this.size = 40,
  });

  final IconData icon;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colour.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.52, color: colour),
    );
  }
}

/// The white card every list on the report sits in.
BoxDecoration reportCardDecoration({double radius = 18, Color? border}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? const Color(0xFFE6E8EF)),
    );
