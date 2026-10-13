import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The award medal, drawn.
///
/// Every badge used to be an emoji in a pale circle, which made the Awards
/// wall look like a keyboard picker rather than a shelf of prizes — and an
/// emoji renders differently on every device, so the one thing a child is
/// meant to feel proud of could not even be relied on to look the same twice.
///
/// This is a real medal instead: a scalloped rim, a gradient disc, a rim of
/// light across the top and the award's own symbol cut out of it in white.
/// One shape for all thirteen, so they read as a set, with the colour and the
/// symbol carrying what each one is for.
class BadgeEmblem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  /// Not earned yet: the same medal in grey, so its shape is already familiar
  /// by the time the child wins it.
  final bool locked;

  /// 0 not earned, then 1/2/3 stars — three bright ring colours rather than
  /// a metal-medal bronze/silver/gold, which means nothing to a toddler who
  /// has never seen a medal podium. Gold stays at the top tier because gold
  /// is what a star already is everywhere else in this app.
  ///
  /// Drawn as a ring around the rim rather than as the medal's colour. The
  /// colour is how a child who cannot read tells one badge from another —
  /// "the letters one is blue" — so the tier must not repaint it.
  final int tier;

  const BadgeEmblem({
    super.key,
    required this.icon,
    required this.color,
    this.size = 64,
    this.locked = false,
    this.tier = 0,
  });

  // Coral, then sky blue, then the same gold every star in the app already
  // uses — a colour a three-year-old can name, in place of dull bronze and
  // silver that only mean something once you already know medal ranking.
  static const Color _oneStar = Color(0xFFFF8FA3);
  static const Color _twoStars = Color(0xFF4FC3E8);
  static const Color _threeStars = Color(0xFFFFD700);

  static Color? ringFor(int tier) => switch (tier) {
        1 => _oneStar,
        2 => _twoStars,
        3 => _threeStars,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final base = locked ? const Color(0xFFB9BFC7) : color;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedalPainter(base, locked ? null : ringFor(tier)),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.38,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final Color color;

  /// The 1/2/3-star ring colour around the rim; null while unearned.
  final Color? ring;

  _MedalPainter(this.color, this.ring);

  /// A lighter and a darker relative of the badge's colour, so one hex value
  /// in the catalog is enough to build the whole medal.
  Color _shift(double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.08, 0.94))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Scalloped rim — twelve rounded bumps, the shape of a struck medal.
    final rim = Path();
    const points = 12;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.90;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        rim.moveTo(p.dx, p.dy);
      } else {
        rim.lineTo(p.dx, p.dy);
      }
    }
    rim.close();
    canvas.drawPath(rim, Paint()..color = _shift(-0.16));

    // The face of the medal.
    canvas.drawCircle(
      center,
      r * 0.80,
      Paint()
        ..shader = LinearGradient(
          colors: [_shift(0.14), _shift(-0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.80)),
    );

    // A thin ring, and a crescent of light along the top-left of it, which is
    // what makes a flat circle read as metal.
    canvas.drawCircle(
      center,
      r * 0.80,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.055,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.66),
      math.pi * 0.85,
      math.pi * 0.75,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.10
        ..strokeCap = StrokeCap.round,
    );
    _drawRing(canvas, center, r);
  }

  /// The tier ring, struck around the outside of the rim.
  void _drawRing(Canvas canvas, Offset center, double r) {
    final tone = ring;
    if (tone == null) return;
    final width = r * 0.13;
    canvas.drawCircle(
      center,
      r - width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = SweepGradient(
          colors: [tone, _lighten(tone), tone, _lighten(tone), tone],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  static Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.color != color || old.ring != ring;
}
