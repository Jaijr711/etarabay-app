import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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

  /// A 3D picture of what the award is for (Microsoft Fluent Emoji 3D, MIT).
  ///
  /// With one, the medal is a gold coin: a sunburst in the award's colour,
  /// the picture standing on it, and the 1/2/3 stars on a ribbon underneath
  /// where a child can count them. Without one — the trophy and gift beside
  /// the count — it stays the scalloped medal with [icon] cut into it.
  final String? image;

  /// Gold twinkles around the coin: won, and waiting to be taken.
  final bool sparkle;

  const BadgeEmblem({
    super.key,
    required this.icon,
    required this.color,
    this.size = 64,
    this.locked = false,
    this.tier = 0,
    this.image,
    this.sparkle = false,
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
    if (image != null) return _coin(image!);
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

  /// The coin is drawn in a 140 x 146 box, a little taller than wide, so the
  /// ribbon hangs below the coin instead of being squeezed against it.
  static const double coinAspect = 146 / 140;

  Widget _coin(String asset) {
    final s = size / 140;
    final picture = Image.asset(
      asset,
      width: 74 * s,
      height: 74 * s,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) =>
          Icon(icon, size: 50 * s, color: Colors.white),
    );
    final coin = CustomPaint(painter: _CoinPainter(color, locked ? 0 : tier));
    return SizedBox(
      width: size,
      height: size * coinAspect,
      child: Stack(
        children: [
          Positioned.fill(
            child: locked
                ? ColorFiltered(colorFilter: _greyscale, child: coin)
                : coin,
          ),
          Positioned(
            left: 33 * s,
            top: 25 * s,
            child: locked
                // Only the picture's outline: the child sees what is coming
                // without the prize being given away in colour.
                ? ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF8D96A8), BlendMode.srcIn),
                    child: picture,
                  )
                : Stack(
                    children: [
                      // The picture's own shadow, so it stands off the coin.
                      Transform.translate(
                        offset: Offset(0, 3 * s),
                        child: ImageFiltered(
                          imageFilter:
                              ImageFilter.blur(sigmaX: 2.4 * s, sigmaY: 2.4 * s),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                                Color(0x4D000000), BlendMode.srcIn),
                            child: picture,
                          ),
                        ),
                      ),
                      picture,
                    ],
                  ),
          ),
          if (locked || sparkle)
            Positioned.fill(
              child: CustomPaint(
                painter: _CoinMarksPainter(lock: locked, sparkle: sparkle),
              ),
            ),
        ],
      ),
    );
  }

  // Grey with the contrast lifted, the same as the preview's locked medal.
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.1063, 0.3576, 0.0361, 0, 107, //
    0.1063, 0.3576, 0.0361, 0, 107,
    0.1063, 0.3576, 0.0361, 0, 115,
    0, 0, 0, 1, 0,
  ]);
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

/// The gold coin behind a 3D picture: a gold rim, a sunburst in the award's
/// colour, and a ribbon carrying the 1/2/3 stars. Drawn in the 140 x 146 box
/// of the design the user picked, then scaled to the widget.
class _CoinPainter extends CustomPainter {
  final Color color;
  final int tier;

  _CoinPainter(this.color, this.tier);

  static const _goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF1A6), Color(0xFFFFC531), Color(0xFFD88A00)],
    stops: [0, 0.45, 1],
  );
  static const _goldEdge = Color(0xFFB46F00);

  /// Darker by scaling toward black, lighter by mixing toward white.
  static Color _shade(Color c, double t) {
    int f(int v) => (t < 0 ? v * (1 + t) : v + (255 - v) * t)
        .round()
        .clamp(0, 255)
        .toInt();
    return Color.fromARGB(255, f(c.red), f(c.green), f(c.blue));
  }

  static Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140);
    const center = Offset(70, 64);

    // Shadow on the ground.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(70, 134), width: 80, height: 12),
      Paint()..color = Colors.black.withOpacity(0.12),
    );

    // Gold rim, and the struck dashes running round it.
    canvas.drawCircle(
      center,
      57,
      Paint()
        ..shader = _goldGradient
            .createShader(Rect.fromCircle(center: center, radius: 57)),
    );
    canvas.drawCircle(center, 57, _stroke(_goldEdge, 2.5));
    final dashes = _stroke(const Color(0xFFFFF3B0).withOpacity(0.9), 2);
    const step = 7 / 51, dash = 2 / 51;
    for (var a = 0.0; a + dash < math.pi * 2; a += step) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: 51), a, dash,
          false, dashes);
    }

    // The face, in the award's own colour, with a sunburst.
    final faceRect = Rect.fromCircle(center: center, radius: 45);
    canvas.drawCircle(
      center,
      45,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.24),
          radius: 0.7,
          colors: [_shade(color, 0.55), color, _shade(color, -0.35)],
          stops: const [0, 0.7, 1],
        ).createShader(faceRect),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    final ray = Paint()..color = Colors.white.withOpacity(0.14);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + 60 * math.cos(a - 0.12),
              center.dy + 60 * math.sin(a - 0.12))
          ..lineTo(center.dx + 60 * math.cos(a + 0.12),
              center.dy + 60 * math.sin(a + 0.12))
          ..close(),
        ray,
      );
    }
    canvas.restore();
    canvas.drawCircle(center, 45, _stroke(_goldEdge, 2));
    // A crescent of light along the top-left, which makes it read as metal.
    canvas.drawPath(
      Path()
        ..moveTo(36, 44)
        ..arcToPoint(const Offset(82, 23), radius: const Radius.circular(40)),
      _stroke(Colors.white.withOpacity(0.35), 5)..strokeCap = StrokeCap.round,
    );

    // The ribbon, curved like a smile, with folded tails.
    final ribbon = _shade(color, -0.2);
    canvas.drawPath(
      Path()
        ..moveTo(22, 112)
        ..quadraticBezierTo(70, 128, 118, 112)
        ..lineTo(114, 126)
        ..quadraticBezierTo(70, 142, 26, 126)
        ..close(),
      Paint()..color = ribbon,
    );
    canvas.drawPath(
      Path()
        ..addPolygon(const [
          Offset(22, 112),
          Offset(10, 108),
          Offset(16, 118),
          Offset(10, 128),
          Offset(26, 126),
        ], true)
        ..addPolygon(const [
          Offset(118, 112),
          Offset(130, 108),
          Offset(124, 118),
          Offset(130, 128),
          Offset(114, 126),
        ], true),
      Paint()..color = _shade(ribbon, -0.25),
    );

    // Three stars on the ribbon: gold for each one earned.
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(52 + i * 18.0, i == 1 ? 128 : 131);
      canvas.scale(0.78);
      _star(canvas, i < tier);
      canvas.restore();
    }
    canvas.restore();
  }

  static final Path _starPath = Path()
    ..addPolygon(const [
      Offset(0, -10),
      Offset(2.9, -3.1),
      Offset(10.5, -3.1),
      Offset(4.3, 1.6),
      Offset(6.6, 9),
      Offset(0, 4.6),
      Offset(-6.6, 9),
      Offset(-4.3, 1.6),
      Offset(-10.5, -3.1),
      Offset(-2.9, -3.1),
    ], true);

  void _star(Canvas canvas, bool on) {
    if (!on) {
      canvas.drawPath(
          _starPath, Paint()..color = Colors.white.withOpacity(0.45));
      return;
    }
    canvas.drawPath(
      _starPath,
      Paint()
        ..shader = _goldGradient.createShader(
            const Rect.fromLTRB(-10.5, -10, 10.5, 9)),
    );
    canvas.drawPath(
        _starPath, _stroke(_goldEdge, 1.6)..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.color != color || old.tier != tier;
}

/// What sits on top of the coin and its picture: the lock on one not yet won,
/// and the sparkles on one waiting to be taken.
class _CoinMarksPainter extends CustomPainter {
  final bool lock;
  final bool sparkle;

  _CoinMarksPainter({required this.lock, required this.sparkle});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140);
    if (lock) {
      canvas.save();
      canvas.translate(70, 64);
      canvas.drawCircle(Offset.zero, 15, Paint()..color = Colors.white);
      canvas.drawCircle(
          Offset.zero,
          15,
          Paint()
            ..color = const Color(0xFFAEB6C4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      const metal = Color(0xFF6E7891);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-7, -2, 14, 11), const Radius.circular(2.5)),
        Paint()..color = metal,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-4.5, -2)
          ..lineTo(-4.5, -6)
          ..arcToPoint(const Offset(4.5, -6),
              radius: const Radius.circular(4.5))
          ..lineTo(4.5, -2),
        Paint()
          ..color = metal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
      canvas.restore();
    }
    if (sparkle) {
      final gold = Paint()..color = const Color(0xFFFFE46B);
      canvas.drawPath(_twinkle(122, 18, 2.8, 6.6), gold);
      canvas.drawPath(_twinkle(16, 26, 2, 4.6), gold);
      canvas.drawCircle(const Offset(118, 104), 3, gold);
    }
    canvas.restore();
  }

  /// A four-point twinkle whose top point is at (x, y).
  static Path _twinkle(double x, double y, double a, double b) =>
      Path()
        ..addPolygon([
          Offset(x, y),
          Offset(x + a, y + b),
          Offset(x + a + b, y + b + a),
          Offset(x + a, y + b + 2 * a),
          Offset(x, y + 2 * b + 2 * a),
          Offset(x - a, y + b + 2 * a),
          Offset(x - a - b, y + b + a),
          Offset(x - a, y + b),
        ], true);

  @override
  bool shouldRepaint(_CoinMarksPainter old) =>
      old.lock != lock || old.sparkle != sparkle;
}
