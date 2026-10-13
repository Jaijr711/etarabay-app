import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single firework: a bright launch flash that blooms into a ring of
/// sparks and fades, looping forever. Drawn rather than loaded from an
/// image so it costs nothing over the wire and reads crisp at any size —
/// see the offline-first rule the rest of the app is held to.
class Firework extends StatelessWidget {
  final Color color;
  final double size;

  /// How long one launch-bloom-fade cycle takes before it repeats.
  final Duration period;

  /// How far into the loop this instance starts — lets several fireworks
  /// share one screen without all popping in lockstep.
  final Duration delay;

  const Firework({
    super.key,
    required this.color,
    this.size = 140,
    this.period = const Duration(milliseconds: 1800),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size)
        .animate(onPlay: (c) => c.repeat())
        .custom(
          delay: delay,
          duration: period,
          curve: Curves.linear,
          builder: (context, t, child) => CustomPaint(
            size: Size(size, size),
            painter: FireworkPainter(color: color, t: t),
          ),
        );
  }
}

/// Paints one firework at progress [t] from 0 (unlit) to 1 (gone), on a
/// loop: a launch flash first, then a ring of sparks blooming outward with
/// a touch of gravity on the way, fading as they go.
class FireworkPainter extends CustomPainter {
  final Color color;
  final double t;

  FireworkPainter({required this.color, required this.t});

  static const double _flashUntil = 0.12;
  static const int _sparkCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    if (t < _flashUntil) {
      final ft = t / _flashUntil;
      // Tinted by the firework's own colour, not plain white — a white
      // flash against this card's pale pink background was all but
      // invisible for the first eighth of every cycle.
      final flashColor = Color.lerp(color, Colors.white, 0.55)!;
      canvas.drawCircle(
        center,
        maxR * 0.24 * ft,
        Paint()
          ..color = flashColor.withOpacity((1 - ft) * 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      return;
    }

    final bloom = ((t - _flashUntil) / (1 - _flashUntil)).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - bloom, 2).toDouble();
    final fade = math.pow(1 - bloom, 1.4).toDouble();
    if (fade <= 0) return;

    // Seeded from the colour so a given firework's spark pattern holds
    // still frame to frame instead of shimmering.
    final rnd = math.Random(color.value);
    for (int i = 0; i < _sparkCount; i++) {
      final angle = (i / _sparkCount) * math.pi * 2 + rnd.nextDouble() * 0.25;
      final reach = maxR * (0.55 + rnd.nextDouble() * 0.45) * ease;
      final dx = math.cos(angle) * reach;
      // A little droop, so the sparks fall rather than hang in place —
      // what makes it read as a firework instead of a starburst sticker.
      final dy = math.sin(angle) * reach + maxR * 0.3 * bloom * bloom;
      final sparkPos = center + Offset(dx, dy);
      final sparkColor =
          (i.isEven ? color : Color.lerp(color, Colors.white, 0.5)!)
              .withOpacity(fade);

      canvas.drawLine(
        center + Offset(dx * 0.55, dy * 0.55),
        sparkPos,
        Paint()
          ..color = sparkColor.withOpacity(fade * 0.6)
          ..strokeWidth = maxR * 0.025
          ..strokeCap = StrokeCap.round,
      );
      // A soft glow under each spark — a plain dot this small got lost
      // against a busy pastel card; the blur gives it a halo that reads
      // from across the card instead of disappearing into the gradient.
      canvas.drawCircle(
        sparkPos,
        maxR * 0.09 * (1 - bloom * 0.4),
        Paint()
          ..color = sparkColor.withOpacity(fade * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        sparkPos,
        maxR * 0.055 * (1 - bloom * 0.4),
        Paint()..color = sparkColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FireworkPainter old) =>
      old.t != t || old.color != color;
}
