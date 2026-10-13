import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A certificate, drawn as a certificate.
///
/// The screen is called "My Certificates", but it was showing a trophy in its
/// header, a rosette on the button that opens it, and a 🎓 emoji on the card —
/// three symbols, none of them a certificate, and two of them the ones the
/// Awards screen already uses for its medals. A child who cannot read the
/// heading had no way to tell the two screens apart.
///
/// A certificate is a piece of paper with a seal on it. That is what this
/// draws: a sheet, two ruled lines, the award's own mark in the middle, and a
/// ribboned seal in the corner. Nothing in Awards looks like it.
class CertificateEmblem extends StatelessWidget {
  /// The mark in the middle of the sheet — the certificate's own icon.
  final IconData? icon;

  /// Ink and seal colour.
  final Color color;

  final double size;

  /// Not yet earned: the same sheet in grey, so its shape is familiar before
  /// the child ever wins one.
  final bool locked;

  const CertificateEmblem({
    super.key,
    required this.color,
    this.icon,
    this.size = 64,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = locked ? const Color(0xFFB9BFC7) : color;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CertificatePainter(base),
        child: icon == null
            ? null
            : Padding(
                // Sits above the ruled lines and clear of the seal.
                padding: EdgeInsets.only(bottom: size * 0.26),
                child: Center(
                  child: Icon(icon, size: size * 0.26, color: base),
                ),
              ),
      ),
    );
  }
}

class _CertificatePainter extends CustomPainter {
  final Color color;

  _CertificatePainter(this.color);

  Color _shift(double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.08, 0.94))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The sheet, a little taller than it is wide, centred.
    final sheet = Rect.fromLTWH(w * 0.14, h * 0.08, w * 0.72, h * 0.74);
    final rrect = RRect.fromRectAndRadius(sheet, Radius.circular(w * 0.055));

    canvas.drawRRect(
      rrect.shift(Offset(0, h * 0.02)),
      Paint()
        ..color = Colors.black.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _shift(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );

    // Two ruled lines — writing, without pretending to be readable text.
    final rule = Paint()
      ..color = _shift(0.30)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.045;
    canvas.drawLine(
        Offset(w * 0.28, h * 0.56), Offset(w * 0.72, h * 0.56), rule);
    canvas.drawLine(
        Offset(w * 0.34, h * 0.67), Offset(w * 0.66, h * 0.67), rule);

    // The seal, low and to the right, with two ribbon tails under it.
    final sealCenter = Offset(w * 0.70, h * 0.78);
    final sealR = w * 0.15;

    final ribbon = Paint()..color = _shift(-0.18);
    for (final dx in [-0.055, 0.055]) {
      canvas.drawPath(
        Path()
          ..moveTo(sealCenter.dx + w * dx - w * 0.05, sealCenter.dy)
          ..lineTo(sealCenter.dx + w * dx - w * 0.02, h * 0.99)
          ..lineTo(sealCenter.dx + w * dx + w * 0.055, h * 0.93)
          ..close(),
        ribbon,
      );
    }

    // A scalloped seal, so it reads as stamped rather than as a sticker.
    final seal = Path();
    const points = 10;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
      final r = i.isEven ? sealR : sealR * 0.84;
      final p = sealCenter + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        seal.moveTo(p.dx, p.dy);
      } else {
        seal.lineTo(p.dx, p.dy);
      }
    }
    seal.close();
    canvas.drawPath(seal, Paint()..color = color);
    canvas.drawCircle(
      sealCenter,
      sealR * 0.55,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sealR * 0.18,
    );
  }

  @override
  bool shouldRepaint(_CertificatePainter old) => old.color != color;
}
