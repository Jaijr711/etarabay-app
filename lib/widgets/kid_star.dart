import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// A star a child can count: gold when earned, and when not yet a pale
/// star with a dashed gold edge, so the ones still to win are as easy to
/// see as the ones won. The grey star it replaces nearly vanished on a
/// white tile.
///
/// The shape and colours are the approved preview's (a 24-unit star).
class KidStar extends StatelessWidget {
  final bool earned;
  final double size;

  const KidStar({super.key, required this.earned, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KidStarPainter(earned)),
    );
  }
}

/// A row of [total] stars, the first [count] earned.
class KidStarRow extends StatelessWidget {
  final int count;
  final int total;
  final double size;
  final double gap;

  const KidStarRow(
      {super.key,
      required this.count,
      this.total = 3,
      this.size = 24,
      this.gap = 2});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: gap),
          KidStar(earned: i < count, size: size),
        ],
      ],
    );
  }
}

class _KidStarPainter extends CustomPainter {
  final bool earned;

  _KidStarPainter(this.earned);

  static const _points = <Offset>[
    Offset(12, 2.6),
    Offset(14.9, 8.5),
    Offset(21.4, 9.4),
    Offset(16.7, 14.0),
    Offset(17.8, 20.5),
    Offset(12, 17.4),
    Offset(6.2, 20.5),
    Offset(7.3, 14.0),
    Offset(2.6, 9.4),
    Offset(9.1, 8.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()..moveTo(_points[0].dx * s, _points[0].dy * s);
    for (final p in _points.skip(1)) {
      path.lineTo(p.dx * s, p.dy * s);
    }
    path.close();

    canvas.drawPath(
        path,
        Paint()
          ..color = earned ? const Color(0xFFFFC21A) : const Color(0xFFFFF6D6));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (earned ? 1.4 : 1.8) * s
      ..color = earned ? const Color(0xFFE59A00) : const Color(0xFFF0B429);
    if (earned) {
      canvas.drawPath(path, edge);
      return;
    }
    // Dashed: 3 on, 2 off, as in the preview.
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 3 * s), edge);
        d += 5 * s;
      }
    }
  }

  @override
  bool shouldRepaint(_KidStarPainter old) => old.earned != earned;
}
