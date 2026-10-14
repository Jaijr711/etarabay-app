import 'package:flutter/material.dart';

/// The tip after an answer, as the team drew it: a white cloud with a blue
/// rim, a light bulb on its top, the words in bold navy with the opening
/// "Correct!" in red, and the mascot waving at its bottom-right corner.
///
/// It replaces a plain rounded card with a small bulb icon in a circle.
class TipCloud extends StatelessWidget {
  final String tip;

  const TipCloud(this.tip, {super.key});

  static const bulb = 'assets/images/tip_bulb.webp';
  static const mascot = 'assets/images/mascot_wave.webp';

  static const _navy = Color(0xFF14204A);
  static const _red = Color(0xFFE5261F);

  /// The opening exclamation — "Correct!", "Tama!", "Wen!" — when the tip
  /// starts with one, so it can be set apart in red.
  static ({String opening, String rest}) split(String tip) {
    final m = RegExp(r'^\s*(\S{1,14}!)\s+').firstMatch(tip);
    if (m == null) return (opening: '', rest: tip.trim());
    return (opening: m.group(1)!, rest: tip.substring(m.end).trim());
  }

  @override
  Widget build(BuildContext context) {
    final parts = split(tip);
    return Padding(
      // Room for the bulb above and the mascot below the right corner.
      padding: const EdgeInsets.only(top: 34, bottom: 46, right: 18),
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            CustomPaint(
              painter: _TipCloudPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 66, 28, 46),
                child: Text.rich(
                  TextSpan(children: [
                    if (parts.opening.isNotEmpty)
                      TextSpan(
                        text: '${parts.opening} ',
                        style: const TextStyle(color: _red, fontSize: 26),
                      ),
                    TextSpan(text: parts.rest),
                  ]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.28,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              child: Image.asset(bulb, height: 84),
            ),
            Positioned(
              right: -34,
              bottom: -52,
              child: Image.asset(mascot, height: 104),
            ),
          ]),
    );
  }
}

/// A cloud: a big rounded body with a bump in the middle of its top, a
/// rim that runs from pale sky blue at the top to deep blue-violet at the
/// bottom, a pale inner rim, and a few sparkles on the rim.
class _TipCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const bump = 30.0;

    var cloud = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(0, bump, w, h), const Radius.circular(56)));
    cloud = Path.combine(
      PathOperation.union,
      cloud,
      Path()
        ..addOval(Rect.fromCenter(
            center: Offset(w / 2, bump + 26), width: w * 0.46, height: 104)),
    );
    // Shoulders either side of the bump, so the top reads as a cloud.
    for (final x in [0.22, 0.78]) {
      cloud = Path.combine(
        PathOperation.union,
        cloud,
        Path()
          ..addOval(Rect.fromCenter(
              center: Offset(w * x, bump + 34), width: w * 0.42, height: 76)),
      );
    }

    final bounds = Offset.zero & size;
    canvas.drawPath(
      cloud.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0xFF3A57C4).withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(cloud, Paint()..color = Colors.white);
    // Pale inner rim.
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = const Color(0xFFDDF2FB),
    );
    // The rim itself.
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FD3F4), Color(0xFF3D7BE0), Color(0xFF6A5CD8)],
        ).createShader(bounds),
    );
    // Sparkles on the rim.
    final sparkle = Paint()..color = Colors.white;
    for (final p in [
      Offset(w * 0.09, bump + 46),
      Offset(w * 0.93, bump + 40),
      Offset(w * 0.04, h * 0.62),
      Offset(w * 0.2, h - 8),
      Offset(w * 0.97, h * 0.7),
    ]) {
      _star(canvas, p, 6, sparkle);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final w = r * 0.25;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TipCloudPainter oldDelegate) => false;
}
