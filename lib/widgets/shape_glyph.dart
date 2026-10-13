import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The plain shapes and colours, drawn rather than typed.
///
/// A circle, a square, a triangle, a heart, a diamond and a cross are the only
/// things in the app that are *pure shape*: there is nothing to illustrate,
/// because the shape is the whole content. Left as emoji they were the one
/// place a child's answer changed with the phone — Android draws 🔺 as a
/// narrow red wedge, some fonts as a wide orange one, and the memory game asks
/// the child to match two of them exactly.
///
/// Drawn here they are identical on every device, they scale to any size
/// without blurring, and they need no file — which matters because artwork for
/// these was never going to arrive: nobody draws a square.
///
/// [ShapeGlyph.forEmoji] returns null for anything that is not one of them, so
/// the caller falls back to its normal picture-or-emoji path.
class ShapeGlyph extends StatelessWidget {
  final _Shape _shape;
  final Color color;
  final double size;

  const ShapeGlyph._({
    required _Shape shape,
    required this.color,
    required this.size,
  }) : _shape = shape;

  /// The drawn version of [emoji], or null if it is not a plain shape.
  static ShapeGlyph? forEmoji(String emoji, {required double size}) {
    // Variation selectors make the same shape two different strings.
    final key = emoji.trim().replaceAll('️', '').replaceAll('︎', '');
    final entry = _byEmoji[key];
    if (entry == null) return null;
    return ShapeGlyph._(shape: entry.$1, color: entry.$2, size: size);
  }

  /// Whether [emoji] is one of the shapes this can draw.
  static bool handles(String emoji) => _byEmoji
      .containsKey(emoji.trim().replaceAll('️', '').replaceAll('︎', ''));

  /// Only the shapes that have no artwork and never will.
  ///
  /// The four colour circles and the star are deliberately absent: those have
  /// uploaded pictures, and drawing them here would replace real artwork with
  /// a flat vector. Plain '🔴' is one of those four (it means the colour red
  /// in Ang Aking Sarili's colours pairs), so the shape "circle" is keyed on
  /// '⚪' instead — a character nothing else in the app's game data uses —
  /// rather than reusing '🔴' and having ObjectPicture draw a bucket of red
  /// paint where a plain circle belongs.
  static const Map<String, (_Shape, Color)> _byEmoji = {
    '⚪': (_Shape.circle, Color(0xFFF5A623)),
    '🟦': (_Shape.square, Color(0xFF2C7BE5)),
    '🔺': (_Shape.triangle, Color(0xFFE5484D)),
    '❤': (_Shape.heart, Color(0xFFE5484D)),
    '🔷': (_Shape.diamond, Color(0xFF2C7BE5)),
    '✕': (_Shape.cross, Color(0xFF5C6470)),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShapePainter(_shape, color)),
    );
  }
}

enum _Shape { circle, square, triangle, heart, diamond, cross, star }

class _ShapePainter extends CustomPainter {
  final _Shape shape;
  final Color color;

  const _ShapePainter(this.shape, this.color);

  /// A darker relative of the fill, for the outline.
  ///
  /// Every shape gets one. Two shapes of similar colour on a pale card are
  /// hard to tell apart at a glance without an edge, and telling them apart is
  /// the entire task in the memory game.
  Color get _edge {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // A little inset so the outline is not clipped by the box.
    final r = size.shortestSide / 2 * 0.92;
    final c = Offset(size.width / 2, size.height / 2);

    final fill = Paint()..color = color;
    final edge = Paint()
      ..color = _edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (shape) {
      case _Shape.circle:
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, edge);
      case _Shape.square:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: r * 1.72, height: r * 1.72),
          Radius.circular(r * 0.16),
        );
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, edge);
      case _Shape.triangle:
        canvas.drawPath(_triangle(c, r), fill);
        canvas.drawPath(_triangle(c, r), edge);
      case _Shape.diamond:
        canvas.drawPath(_diamond(c, r), fill);
        canvas.drawPath(_diamond(c, r), edge);
      case _Shape.heart:
        canvas.drawPath(_heart(c, r), fill);
        canvas.drawPath(_heart(c, r), edge);
      case _Shape.star:
        canvas.drawPath(_star(c, r), fill);
        canvas.drawPath(_star(c, r), edge);
      case _Shape.cross:
        // No fill — a cross is two strokes, and drawing it as a filled shape
        // would make it read as a thick plus sign.
        final arm = r * 0.66;
        final pen = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.30
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c + Offset(-arm, -arm), c + Offset(arm, arm), pen);
        canvas.drawLine(c + Offset(arm, -arm), c + Offset(-arm, arm), pen);
    }
  }

  /// Point up, sitting on a flat base, with the corners rounded off — the way
  /// a triangle is drawn in a picture book rather than in geometry.
  Path _triangle(Offset c, double r) {
    final pts = [
      Offset(c.dx, c.dy - r * 0.94),
      Offset(c.dx + r * 0.92, c.dy + r * 0.72),
      Offset(c.dx - r * 0.92, c.dy + r * 0.72),
    ];
    return _rounded(pts, r * 0.16);
  }

  Path _diamond(Offset c, double r) => _rounded([
        Offset(c.dx, c.dy - r),
        Offset(c.dx + r * 0.78, c.dy),
        Offset(c.dx, c.dy + r),
        Offset(c.dx - r * 0.78, c.dy),
      ], r * 0.12);

  Path _star(Offset c, double r) {
    const points = 5;
    final pts = <Offset>[
      for (int i = 0; i < points * 2; i++)
        () {
          final radius = i.isEven ? r : r * 0.45;
          final a = -math.pi / 2 + i * math.pi / points;
          return Offset(
              c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
        }()
    ];
    return _rounded(pts, r * 0.08);
  }

  /// Two lobes and a point, from four curves.
  Path _heart(Offset c, double r) {
    final p = Path();
    final top = c.dy - r * 0.42;
    final bottom = c.dy + r * 0.92;
    p.moveTo(c.dx, bottom);
    p.cubicTo(c.dx - r * 1.5, c.dy + r * 0.05, c.dx - r * 0.86, top - r * 0.62,
        c.dx, top);
    p.cubicTo(c.dx + r * 0.86, top - r * 0.62, c.dx + r * 1.5, c.dy + r * 0.05,
        c.dx, bottom);
    p.close();
    return p;
  }

  /// A polygon with its corners eased off.
  ///
  /// A sharp point at this size reads as a spike and catches the eye more than
  /// the shape does; rounding each corner by [radius] keeps the silhouette a
  /// child recognises while letting the outline sit evenly around it.
  Path _rounded(List<Offset> pts, double radius) {
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final prev = pts[(i - 1 + pts.length) % pts.length];
      final cur = pts[i];
      final next = pts[(i + 1) % pts.length];

      final toPrev = _towards(cur, prev, radius);
      final toNext = _towards(cur, next, radius);

      if (i == 0) {
        path.moveTo(toPrev.dx, toPrev.dy);
      } else {
        path.lineTo(toPrev.dx, toPrev.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, toNext.dx, toNext.dy);
    }
    path.close();
    return path;
  }

  Offset _towards(Offset from, Offset to, double distance) {
    final d = to - from;
    final len = d.distance;
    if (len == 0) return from;
    final t = (distance / len).clamp(0.0, 0.5);
    return from + d * t;
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
}
