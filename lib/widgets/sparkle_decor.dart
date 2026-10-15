import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The little things the team's designs scatter round their cards: four-point
/// sparkles, small outlined stars, pink flowers and green leaves. Drawn, so
/// they stay sharp at any size and cost no pictures.
class SparkleDecor {
  SparkleDecor._();

  /// A four-point sparkle, [r] from the middle to a point.
  static void sparkle(Canvas canvas, Offset c, double r, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  /// A five-point star with a soft brown outline.
  static void star(Canvas canvas, Offset c, double r, Color color) {
    final p = Path();
    for (int i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.48;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF9A5A1E).withOpacity(0.6));
  }

  /// A five-petal flower, pink by default, with a yellow middle.
  static void flower(Canvas canvas, Offset c, double r,
      {Color petals = const Color(0xFFF7708A),
      Color edge = const Color(0xFFB8364F)}) {
    final petal = Paint()..color = petals;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = edge;
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final pc = c + Offset(math.cos(a), math.sin(a)) * r * 0.62;
      canvas.drawCircle(pc, r * 0.5, petal);
      canvas.drawCircle(pc, r * 0.5, line);
    }
    canvas.drawCircle(c, r * 0.36, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.2, Paint()..color = const Color(0xFFFFD45A));
  }

  /// A leaf [length] long, from [base] pointing at [angle] (radians).
  static void leaf(Canvas canvas, Offset base, double length, double angle) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final w = length * 0.42;
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -w, length, 0)
      ..quadraticBezierTo(length * 0.5, w, 0, 0)
      ..close();
    canvas.drawPath(
        p,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF7BCB55), Color(0xFF3E9A3A)])
              .createShader(Rect.fromLTWH(0, -w, length, 2 * w)));
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = const Color(0xFF2E6B2A));
    canvas.drawLine(
        Offset.zero,
        Offset(length * 0.8, 0),
        Paint()
          ..strokeWidth = 1.1
          ..color = const Color(0xFF2E6B2A).withOpacity(0.7));
    canvas.restore();
  }
}

/// One mark at a place given as fractions of the box it is painted in.
class DecorMark {
  final double x, y, size;
  final Color color;
  final DecorKind kind;
  const DecorMark.sparkle(this.x, this.y, this.size, this.color)
      : kind = DecorKind.sparkle;
  const DecorMark.star(this.x, this.y, this.size, this.color)
      : kind = DecorKind.star;
  const DecorMark.flower(this.x, this.y, this.size)
      : kind = DecorKind.flower,
        color = const Color(0xFFF7708A);
  const DecorMark.yellowFlower(this.x, this.y, this.size)
      : kind = DecorKind.yellowFlower,
        color = const Color(0xFFFFC93C);
}

enum DecorKind { sparkle, star, flower, yellowFlower }

/// Paints a list of [DecorMark]s.
class DecorPainter extends CustomPainter {
  final List<DecorMark> marks;
  const DecorPainter(this.marks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in marks) {
      final at = Offset(m.x * size.width, m.y * size.height);
      switch (m.kind) {
        case DecorKind.sparkle:
          SparkleDecor.sparkle(canvas, at, m.size, m.color);
        case DecorKind.star:
          SparkleDecor.star(canvas, at, m.size, m.color);
        case DecorKind.flower:
          SparkleDecor.flower(canvas, at, m.size);
        case DecorKind.yellowFlower:
          SparkleDecor.flower(canvas, at, m.size,
              petals: const Color(0xFFFFC93C), edge: const Color(0xFFC98A10));
      }
    }
  }

  @override
  bool shouldRepaint(DecorPainter oldDelegate) => oldDelegate.marks != marks;
}
