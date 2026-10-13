import 'package:flutter/material.dart';

/// One crayon in Kulay Saya's colour picker — drawn as a crayon rather than
/// a flat circle, so the shape itself already says "this is what you draw
/// with" before a child reads a word. The colour's name sits printed on the
/// paper wrapper, centred, the way a real crayon's label actually sits.
///
/// Sized by its parent rather than a fixed constant: eight of these have to
/// share a row with nothing left over to scroll to, so the row hands each
/// one its share of the width and this scales to fill it.
class CrayonSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CrayonSwatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Capped rather than let run free — on a tablet-width row eight
            // shares of the row would otherwise inflate into something
            // closer to a table leg than a crayon.
            final width = constraints.maxWidth.clamp(0.0, 76.0);
            return Center(
              child: SizedBox(
                width: width,
                height: width * 1.75,
                child: CustomPaint(
                  painter: _CrayonPainter(
                    color: color,
                    label: label,
                    selected: selected,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CrayonPainter extends CustomPainter {
  final Color color;
  final String label;
  final bool selected;

  _CrayonPainter({
    required this.color,
    required this.label,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Chunkier than the first pass — a real crayon's barrel is most of its
    // width, not two thin bars either side of empty space.
    final left = w * 0.10;
    final right = w * 0.90;
    final tipY = h * 0.17;
    final wrapperTop = h * 0.40;
    final wrapperBottom = h * 0.70;
    final bottom = h * 0.99;
    final corner = w * 0.10;

    final dark = Color.lerp(color, Colors.black, 0.30)!;
    final light = Color.lerp(color, Colors.white, 0.35)!;

    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left - 8, -4, right + 8, bottom + 6),
          const Radius.circular(18),
        ),
        Paint()
          ..color = color.withOpacity(0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // The barrel: a moulded hexagon like a real crayon's, rounded at the
    // bottom rather than a sharp-cornered box.
    final barrel = Path()
      ..moveTo(left, tipY)
      ..lineTo(right, tipY)
      ..lineTo(right, bottom - corner)
      ..quadraticBezierTo(right, bottom, right - corner, bottom)
      ..lineTo(left + corner, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - corner)
      ..close();

    canvas.drawShadow(barrel, Colors.black.withOpacity(0.35), 3, false);
    canvas.drawPath(
      barrel,
      Paint()
        ..shader = LinearGradient(
          colors: [dark, color, light, color],
          stops: const [0.0, 0.32, 0.52, 1.0],
        ).createShader(Rect.fromLTRB(left, tipY, right, bottom)),
    );

    // The tip — mostly a real taper to a point, the way a crayon is
    // actually moulded, with just the apex itself softened. Pulling the
    // whole edge into one shallow curve (the first version of this) read
    // as a rounded dome instead of a point at all; only the last stretch
    // near the very top needs to be a curve.
    final apex = Offset(w / 2, 0);
    final leftBase = Offset(left, tipY);
    final rightBase = Offset(right, tipY);
    final nearLeft = Offset.lerp(apex, leftBase, 0.22)!;
    final nearRight = Offset.lerp(apex, rightBase, 0.22)!;
    final tip = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(nearLeft.dx, nearLeft.dy)
      ..quadraticBezierTo(apex.dx, apex.dy, nearRight.dx, nearRight.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..close();
    canvas.drawPath(tip, Paint()..color = dark);
    canvas.drawPath(
      tip,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, dark],
        ).createShader(Rect.fromLTRB(left, 0, right, tipY)),
    );

    // A glossy diagonal streak, the highlight an emoji crayon's flat
    // colour fill always carries — without it the barrel reads as a
    // painted tube instead of a waxy, slightly shiny one.
    canvas.save();
    canvas.clipPath(barrel);
    final glossPath = Path()
      ..moveTo(left - 4, tipY + (bottom - tipY) * 0.05)
      ..lineTo(left + (right - left) * 0.30, tipY)
      ..lineTo(left + (right - left) * 0.12, bottom + 4)
      ..lineTo(left - 4, bottom + 4)
      ..close();
    canvas.drawPath(
      glossPath,
      Paint()..color = Colors.white.withOpacity(0.30),
    );
    canvas.restore();

    // The paper wrapper band, and the colour's name printed on it, sized
    // down until it fits rather than a fixed size that would overflow on
    // "Orange" or "Purple".
    final wrapperRect = Rect.fromLTRB(left, wrapperTop, right, wrapperBottom);
    canvas.drawRect(
        wrapperRect, Paint()..color = Colors.white.withOpacity(0.92));
    final rule = Paint()
      ..color = dark.withOpacity(0.75)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, wrapperTop), Offset(right, wrapperTop), rule);
    canvas.drawLine(
        Offset(left, wrapperBottom), Offset(right, wrapperBottom), rule);

    final maxTextWidth = (right - left) * 0.86;
    double fontSize = h * 0.11;
    late TextPainter tp;
    while (true) {
      tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: dark,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width <= maxTextWidth || fontSize <= 6) break;
      fontSize -= 0.5;
    }
    tp.paint(
      canvas,
      Offset(
        left + (right - left - tp.width) / 2,
        wrapperTop + (wrapperBottom - wrapperTop - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CrayonPainter old) =>
      old.color != color || old.selected != selected || old.label != label;
}
