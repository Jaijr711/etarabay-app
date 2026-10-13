import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The basket the child drops their answer into, in Matematika's
/// "Drag the Number".
///
/// Drawn rather than assembled from a dashed rectangle and an arrow: a
/// three-year-old understands "put it in the basket" from the picture alone,
/// without being able to read a word of the instruction above it.
class BasketPicture extends StatelessWidget {
  final double size;

  /// Darkens the cane while a number is being held over it, so the child can
  /// see the basket is ready to receive the drop.
  final bool highlighted;

  /// The number now sitting in the basket, drawn inside it once the answer
  /// has been accepted.
  final int? holding;

  const BasketPicture({
    super.key,
    this.size = 150,
    this.highlighted = false,
    this.holding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.82,
      child: CustomPaint(
        painter: _BasketPainter(highlighted: highlighted),
        child: holding == null
            ? null
            : Center(
                child: Padding(
                  padding: EdgeInsets.only(top: size * 0.16),
                  child: Text(
                    '$holding',
                    style: TextStyle(
                      fontSize: size * 0.30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BasketPainter extends CustomPainter {
  final bool highlighted;

  _BasketPainter({required this.highlighted});

  @override
  void paint(Canvas canvas, Size size) {
    // Authored against a 100×82 box and scaled, so one set of coordinates
    // works at every size.
    canvas.save();
    canvas.scale(size.width / 100, size.height / 82);

    final cane = highlighted ? const Color(0xFFB4711F) : const Color(0xFFC98A3C);
    final caneDark =
        highlighted ? const Color(0xFF8A5314) : const Color(0xFFA96F26);

    Paint f(Color c) => Paint()
      ..color = c
      ..isAntiAlias = true;
    Paint l(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Handle, drawn first so the body covers where it meets the rim.
    canvas.drawArc(const Rect.fromLTWH(24, 2, 52, 52), math.pi, math.pi, false,
        l(caneDark, 7));

    final body = Path()
      ..moveTo(10, 32)
      ..lineTo(90, 32)
      ..lineTo(78, 78)
      ..quadraticBezierTo(50, 84, 22, 78)
      ..close();
    canvas.drawPath(body, f(cane));

    // Weave, clipped to the body so it never spills past the edge.
    canvas.save();
    canvas.clipPath(body);
    for (double y = 40; y < 78; y += 10) {
      canvas.drawLine(Offset(8, y), Offset(92, y), l(caneDark, 3));
    }
    for (double x = 18; x < 90; x += 12) {
      canvas.drawLine(Offset(x, 32), Offset(x - 6, 84), l(caneDark, 2.5));
    }
    canvas.restore();

    // Rim last, sitting on top of the weave.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 26, 88, 13), const Radius.circular(7)),
      f(caneDark),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BasketPainter old) => old.highlighted != highlighted;
}
