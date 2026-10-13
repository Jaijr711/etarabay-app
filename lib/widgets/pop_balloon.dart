import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The balloon the child pops in Matematika's "Pop the Balloon".
///
/// It used to be a rounded rectangle with a straight grey line under it, and
/// popping it faded the rectangle out. A three-year-old knows what a balloon
/// is long before they know what a number is: the picture has to be a balloon
/// for the instruction above it to be readable at all, and the burst is the
/// reward for having answered correctly — a fade hands back nothing.
///
/// Drawn rather than an image so it can take any colour and any size, and so
/// it can come apart on the screen.
class PopBalloon extends StatefulWidget {
  /// The number written on the balloon, or null for a plain floating one —
  /// the birthday card's, which has nothing to count and nothing to be
  /// right or wrong about.
  final int? value;

  /// The rubber's colour. A wrong tap recolours it — see [wrong].
  final Color color;

  /// True once the child has popped this one. The burst plays on the change,
  /// and going back to false — a new round — makes the balloon whole again.
  final bool popped;

  /// True while a wrong answer is being shown on this balloon.
  final bool wrong;

  /// Width of the balloon body. Everything else is measured from it.
  final double size;

  const PopBalloon({
    super.key,
    this.value,
    required this.color,
    this.popped = false,
    this.wrong = false,
    this.size = 72,
  });

  /// The tile is barely wider than the balloon, so the balloon still fills as
  /// much of its grid cell as the old rectangle did. The shreds fly beyond
  /// these bounds on purpose — `FittedBox` does not clip — because a burst
  /// that stops at a tidy edge does not look like a burst.
  static const double tileWidthRatio = 1.12;
  static const double tileHeightRatio = 1.62;

  @override
  State<PopBalloon> createState() => _PopBalloonState();
}

class _PopBalloonState extends State<PopBalloon>
    with SingleTickerProviderStateMixin {
  /// Shorter than the 350ms the board waits before grading, so the last
  /// balloon has finished coming apart by the time the verdict arrives.
  static const Duration _popDuration = Duration(milliseconds: 320);

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: _popDuration,
  )..value = widget.popped ? 1.0 : 0.0;

  @override
  void didUpdateWidget(covariant PopBalloon old) {
    super.didUpdateWidget(old);
    if (widget.popped && !old.popped) {
      _pop.forward(from: 0);
    } else if (!widget.popped && old.popped) {
      // A new round hands back the same tile with a different number on it.
      _pop.value = 0;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * PopBalloon.tileWidthRatio,
      height: widget.size * PopBalloon.tileHeightRatio,
      child: AnimatedScale(
        // The nudge that says "not that one" — the balloon leans out at the
        // child rather than only turning red.
        scale: widget.wrong ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: AnimatedBuilder(
          animation: _pop,
          builder: (_, __) => CustomPaint(
            painter: BalloonPainter(
              value: widget.value,
              color: widget.wrong ? const Color(0xFFE53935) : widget.color,
              body: widget.size,
              pop: _pop.value,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the balloon at any point between whole and gone.
///
/// Public only so a golden test can render the burst frame by frame; nothing
/// else should need it.
class BalloonPainter extends CustomPainter {
  /// The number printed on it, or null for a plain floating balloon — the
  /// birthday card's, which has nothing to count and nothing to be right or
  /// wrong about.
  final int? value;
  final Color color;

  /// Width of the balloon body in logical pixels.
  final double body;

  /// 0 is whole, 1 is gone. The first sixth is the balloon stretching under
  /// the finger: rubber gives before it tears, and without that beat the
  /// balloon simply vanishes and the burst looks like it belongs to something
  /// else that happened nearby.
  final double pop;

  BalloonPainter({
    this.value,
    required this.color,
    required this.body,
    required this.pop,
  });

  static const double _stretchUntil = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final bw = body;
    final bh = body * 1.18;
    final cx = size.width / 2;
    final top = size.height * 0.02;
    final centre = Offset(cx, top + bh * 0.45);

    if (pop <= _stretchUntil) {
      // Rubber under pressure widens more than it lengthens, so the two axes
      // are not stretched by the same amount.
      final s = pop / _stretchUntil;
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.scale(1 + s * 0.24, 1 + s * 0.13);
      canvas.translate(-centre.dx, -centre.dy);
      _paintString(canvas, cx, top + bh, bw);
      _paintBody(canvas, cx, top, bw, bh);
      _paintNumber(canvas, centre, bh * 0.34, 1.0, 1.0);
      canvas.restore();
      return;
    }

    final burst = ((pop - _stretchUntil) / (1 - _stretchUntil)).clamp(0.0, 1.0);
    _paintRemnant(canvas, cx, top + bh, bw, burst);
    _paintBurst(canvas, centre, bw, burst);
    // The number was inside the balloon; it leaves with the rest of it.
    _paintNumber(canvas, centre, bh * 0.34, 1 + burst * 0.35, 1 - burst);
  }

  /// The body: an egg that is widest above its middle, which is what makes a
  /// balloon read as a balloon instead of as a circle on a string.
  Path _bodyPath(double cx, double top, double bw, double bh) {
    return Path()
      ..moveTo(cx, top)
      ..cubicTo(cx + bw * 0.60, top + bh * 0.02, cx + bw * 0.53,
          top + bh * 0.64, cx + bw * 0.12, top + bh * 0.96)
      ..quadraticBezierTo(cx, top + bh, cx - bw * 0.12, top + bh * 0.96)
      ..cubicTo(cx - bw * 0.53, top + bh * 0.64, cx - bw * 0.60,
          top + bh * 0.02, cx, top)
      ..close();
  }

  void _paintBody(Canvas canvas, double cx, double top, double bw, double bh) {
    final path = _bodyPath(cx, top, bw, bh);
    final light = Color.lerp(color, Colors.white, 0.42)!;
    final dark = Color.lerp(color, Colors.black, 0.22)!;

    canvas.drawShadow(path, Colors.black.withOpacity(0.35), 6, true);

    // Inflated rubber is lit from one side and darkest at the far rim.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.05,
          colors: [light, color, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(cx - bw / 2, top, bw, bh)),
    );

    // The knot, and the pleats gathering into it.
    final knotTop = top + bh * 0.97;
    canvas.drawPath(
      Path()
        ..moveTo(cx - bw * 0.075, knotTop)
        ..lineTo(cx + bw * 0.075, knotTop)
        ..lineTo(cx, knotTop + bh * 0.075)
        ..close(),
      Paint()..color = dark,
    );
    final pleat = Paint()
      ..color = dark.withOpacity(0.35)
      ..strokeWidth = bw * 0.02
      ..style = PaintingStyle.stroke;
    for (final dx in [-0.05, 0.0, 0.05]) {
      canvas.drawLine(Offset(cx + bw * dx * 1.4, knotTop - bh * 0.06),
          Offset(cx + bw * dx * 0.3, knotTop), pleat);
    }

    // The window: the one highlight that says the surface is shiny and
    // curved. Angled, because a straight one reads as a printed sticker.
    canvas.save();
    canvas.translate(cx - bw * 0.19, top + bh * 0.23);
    canvas.rotate(-0.42);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: bw * 0.17, height: bh * 0.24),
      Paint()..color = Colors.white.withOpacity(0.55),
    );
    canvas.restore();
    canvas.drawCircle(Offset(cx - bw * 0.05, top + bh * 0.13), bw * 0.035,
        Paint()..color = Colors.white.withOpacity(0.45));
  }

  /// The string, curling. A straight line reads as a stick.
  void _paintString(Canvas canvas, double cx, double bottom, double bw) {
    final start = Offset(cx, bottom + bw * 0.08);
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + bw * 0.20,
          start.dy + bw * 0.12,
          start.dx - bw * 0.20,
          start.dy + bw * 0.24,
          start.dx + bw * 0.09,
          start.dy + bw * 0.40,
        ),
      Paint()
        ..color = Colors.blueGrey.shade400
        ..strokeWidth = bw * 0.025
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// The knot and its string, dropping away now that nothing is holding
  /// them up. Without this the string vanishes in the same frame as the
  /// rubber, and a burst that leaves nothing behind looks like the balloon
  /// was simply deleted.
  void _paintRemnant(
      Canvas canvas, double cx, double bottom, double bw, double t) {
    final fade = math.pow(1 - t, 1.2).toDouble();
    if (fade <= 0) return;
    canvas.save();
    canvas.translate(0, bw * 0.75 * t * t);
    canvas.saveLayer(null, Paint()..color = Colors.white.withOpacity(fade));
    canvas.drawPath(
      Path()
        ..moveTo(cx - bw * 0.075, bottom - bw * 0.02)
        ..lineTo(cx + bw * 0.075, bottom - bw * 0.02)
        ..lineTo(cx, bottom + bw * 0.07)
        ..close(),
      Paint()..color = Color.lerp(color, Colors.black, 0.25)!,
    );
    _paintString(canvas, cx, bottom, bw);
    canvas.restore();
    canvas.restore();
  }

  /// What is left a moment after a balloon goes: the air leaving as a ring,
  /// and the rubber itself in pieces.
  void _paintBurst(Canvas canvas, Offset centre, double bw, double t) {
    final ease = 1 - math.pow(1 - t, 3).toDouble();
    final dark = Color.lerp(color, Colors.black, 0.25)!;

    // The air leaving, as one ring close to the balloon rather than a wide
    // thin circle: a ring that travels far reads as a ripple in water, and
    // ends up drawn over the balloons either side of this one.
    final ringFade = math.pow(1 - t / 0.7, 1.5).toDouble();
    if (ringFade > 0) {
      canvas.drawCircle(
        centre,
        bw * (0.34 + 0.42 * ease),
        Paint()
          ..color = color.withOpacity(ringFade * 0.85)
          ..strokeWidth = bw * 0.11 * (1 - t)
          ..style = PaintingStyle.stroke,
      );
    }
    if (t < 0.3) {
      // The flash at the instant it lets go.
      canvas.drawCircle(
        centre,
        bw * (0.2 + 0.42 * t),
        Paint()..color = Colors.white.withOpacity((1 - t / 0.3) * 0.8),
      );
    }

    // Seven shreds of rubber — big enough to be seen as pieces of the
    // balloon that was there a moment ago. Seeded from the number, so one
    // bursts the same way every time it is drawn rather than shimmering
    // between frames.
    final rnd = math.Random((value ?? body.round()) * 31 + 7);
    for (int i = 0; i < 7; i++) {
      final angle = (i / 7) * math.pi * 2 + rnd.nextDouble() * 0.6;
      final reach = bw * (0.38 + rnd.nextDouble() * 0.34);
      final drift = Offset(
        math.cos(angle) * reach * ease,
        math.sin(angle) * reach * ease + bw * 0.55 * t * t,
      );
      final piece = bw * (0.26 + rnd.nextDouble() * 0.10) * (1 - t * 0.25);
      final fade = math.pow(1 - t, 1.4).toDouble();
      if (fade <= 0) continue;

      canvas.save();
      canvas.translate(centre.dx + drift.dx, centre.dy + drift.dy);
      canvas.rotate(angle + t * 3.2 * (i.isEven ? 1 : -1));
      // A torn sliver, not a confetti square: one long curved edge, one
      // ragged one, the way rubber tears.
      canvas.drawPath(
        Path()
          ..moveTo(-piece, piece * 0.1)
          ..quadraticBezierTo(-piece * 0.1, -piece * 0.72, piece, -piece * 0.2)
          ..quadraticBezierTo(
              piece * 0.25, piece * 0.12, piece * 0.35, piece * 0.42)
          ..quadraticBezierTo(-piece * 0.35, piece * 0.30, -piece, piece * 0.1)
          ..close(),
        Paint()..color = (i.isEven ? color : dark).withOpacity(fade),
      );
      canvas.restore();
    }
  }

  void _paintNumber(Canvas canvas, Offset centre, double fontSize, double scale,
      double fade) {
    if (fade <= 0 || value == null) return;
    final tp = TextPainter(
      text: TextSpan(
        text: '$value',
        style: TextStyle(
          fontSize: fontSize * scale,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(fade),
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.25 * fade), blurRadius: 3)
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BalloonPainter old) =>
      old.pop != pop ||
      old.color != color ||
      old.value != value ||
      old.body != body;
}
