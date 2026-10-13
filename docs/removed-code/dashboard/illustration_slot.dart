import 'package:flutter/material.dart';

/// A stand-in for artwork that has not been drawn yet.
///
/// Every illustration on the dashboard goes through this one widget, so the
/// screen runs today with nothing but Flutter's own icons and takes real
/// artwork later without any layout being touched: give it an [assetPath] and
/// it draws the PNG instead of the icon, at the same size, in the same place.
///
/// It deliberately does not fall back to a broken-image box. If an asset is
/// named but missing, the icon comes back — a child should never be shown a
/// grey placeholder square.
class IllustrationSlot extends StatelessWidget {
  /// Drawn until [assetPath] is supplied.
  final IconData icon;

  /// Tint for the icon and its soft backing circle.
  final Color color;

  /// The width and height the illustration is drawn into.
  final double size;

  /// Drop a PNG here later, e.g. 'assets/images/dashboard/numbers.png'.
  final String? assetPath;

  /// A round tinted plate behind the icon. Off for artwork that carries its
  /// own background.
  final bool plate;

  const IllustrationSlot({
    super.key,
    required this.icon,
    required this.color,
    this.size = 64,
    this.assetPath,
    this.plate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _icon(),
      );
    }
    return _icon();
  }

  Widget _icon() {
    final glyph = Icon(icon, size: size * 0.58, color: color);
    if (!plate) {
      return SizedBox(width: size, height: size, child: Center(child: glyph));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Center(child: glyph),
    );
  }
}

/// The friendly character that waves from the corner of the header.
///
/// Same idea as [IllustrationSlot] — a shape today, a mascot PNG later.
class MascotSlot extends StatelessWidget {
  final double size;
  final String? assetPath;

  const MascotSlot({super.key, this.size = 84, this.assetPath});

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _drawn(),
      );
    }
    return _drawn();
  }

  Widget _drawn() {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6FD8C2), Color(0xFF3EB59B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Icon(Icons.sentiment_very_satisfied_rounded,
              size: size * 0.6, color: Colors.white),
        ],
      ),
    );
  }
}
