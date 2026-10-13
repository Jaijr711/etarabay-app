import 'package:flutter/material.dart';

import 'illustration_slot.dart';

/// One number the child has collected, with its picture and its word.
class HeaderStat {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const HeaderStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
}

/// The greeting card at the top of the dashboard.
///
/// Avatar, the child's name, and the three counts they care about, with the
/// mascot waving from the corner.
class ProfileHeader extends StatelessWidget {
  final String name;
  final String greeting;
  final String subtitle;
  final List<HeaderStat> stats;

  /// Swap in a real photo or avatar PNG later; a letter tile stands in.
  final String? avatarAssetPath;
  final String? mascotAssetPath;

  final VoidCallback? onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.greeting,
    required this.subtitle,
    required this.stats,
    this.avatarAssetPath,
    this.mascotAssetPath,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // The mascot is the first thing to go on a narrow phone: it is
        // decoration, and the counts underneath are not.
        final showMascot = box.maxWidth > 340;
        final avatar = box.maxWidth < 360 ? 56.0 : 64.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C7BE5).withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    name: name,
                    size: avatar,
                    assetPath: avatarAssetPath,
                    onTap: onAvatarTap,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$greeting 👋',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF11397A),
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A8699),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showMascot) ...[
                    const SizedBox(width: 8),
                    MascotSlot(size: 62, assetPath: mascotAssetPath),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _StatStrip(stats: stats),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String? assetPath;
  final VoidCallback? onTap;

  const _Avatar({
    required this.name,
    required this.size,
    this.assetPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEAF4FF),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C7BE5).withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: assetPath != null
              ? Image.asset(assetPath!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _letter(initial))
              : _letter(initial),
        ),
      ),
    );
  }

  Widget _letter(String initial) => Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C7BE5),
          ),
        ),
      );
}

/// Stars, badges and lessons, side by side with hairline dividers.
class _StatStrip extends StatelessWidget {
  final List<HeaderStat> stats;

  const _StatStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECF8), width: 2),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(width: 1.5, height: 34, color: const Color(0xFFE3ECF8)),
            Expanded(child: _Stat(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final HeaderStat stat;

  const _Stat({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(stat.icon, color: stat.color, size: 22),
            const SizedBox(width: 6),
            // Numbers line up whatever their width, and never wrap.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stat.value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11397A),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A8699),
          ),
        ),
      ],
    );
  }
}
