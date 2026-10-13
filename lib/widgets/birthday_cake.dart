import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A drawn birthday cake with lit candles, for the top of the birthday card.
///
/// It used to be the 🎂 emoji, bouncing. An emoji is a different picture on
/// every phone — Android draws it one way, iOS another — and none of them
/// belong to this card the way the balloons and the confetti do, which are
/// drawn in the app's own hand. This is the same cake wherever it is opened,
/// and it can do the one thing the emoji cannot: burn.
///
/// The candles are the point. Each one flickers on its own clock — a
/// different frequency and starting phase — so four candles never move in
/// lockstep. A flame that pulses in perfect unison with its neighbours reads
/// as one animation playing four times; four flames each doing their own
/// small, uneven thing reads as fire.
class BirthdayCake extends StatefulWidget {
  /// Width of the cake. Everything else — tiers, candles, flames — is
  /// measured from this one number.
  final double size;

  final int candles;

  const BirthdayCake({super.key, this.size = 150, this.candles = 4});

  @override
  State<BirthdayCake> createState() => _BirthdayCakeState();
}

class _BirthdayCakeState extends State<BirthdayCake>
    with SingleTickerProviderStateMixin {
  // A long loop rather than a short one: at 4 seconds, with each candle
  // running at its own non-integer multiple of that cycle (see [_CakePainter
  // .paint]), the combined flicker does not visibly repeat within the few
  // seconds this card is actually looked at.
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  /// Sprinkle positions and colours, fixed once rather than redrawn every
  /// frame — the flames move, the cake underneath them does not.
  late final List<_Sprinkle> _sprinkles = _scatterSprinkles(widget.candles);

  static List<_Sprinkle> _scatterSprinkles(int seed) {
    final rnd = math.Random(seed * 97 + 11);
    return List.generate(14, (i) {
      final onTopTier = i < 6;
      return _Sprinkle(
        // Fractions of each tier's own box, not the whole cake — so the
        // scatter still looks even however wide the tiers end up being.
        dx: rnd.nextDouble(),
        dy: rnd.nextDouble(),
        onTopTier: onTopTier,
        color:
            _BirthdayPalette.sprinkles[i % _BirthdayPalette.sprinkles.length],
        angle: rnd.nextDouble() * math.pi,
      );
    });
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 1.05,
      child: AnimatedBuilder(
        animation: _flicker,
        builder: (_, __) => CustomPaint(
          size: Size(widget.size, widget.size * 1.05),
          painter: _CakePainter(
            t: _flicker.value,
            candles: widget.candles,
            sprinkles: _sprinkles,
          ),
        ),
      ),
    );
  }
}

class _Sprinkle {
  final double dx, dy, angle;
  final bool onTopTier;
  final Color color;
  const _Sprinkle({
    required this.dx,
    required this.dy,
    required this.onTopTier,
    required this.color,
    required this.angle,
  });
}

/// The card's own palette, so the cake reads as part of it rather than a
/// sticker dropped on top. The sprinkles and candles are drawn from the same
/// six colours the balloons already use.
class _BirthdayPalette {
  static const cream = Color(0xFFFFF3E6);
  static const creamShadow = Color(0xFFF2DFC8);
  static const icing = Color(0xFFFFFBF7);
  static const icingShadow = Color(0xFFFFE3EE);
  static const drip = Color(0xFFFF6584);
  static const ribbon = Color(0xFF6C63FF);
  static const plate = Color(0xFFFFE3EE);

  static const sprinkles = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFB347),
    Color(0xFF6C63FF),
    Color(0xFFFF99C8),
    Color(0xFF95D9C3),
  ];

  static const candleSticks = [
    Color(0xFFFF6B6B),
    Color(0xFF6C63FF),
    Color(0xFF4ECDC4),
    Color(0xFFFF99C8),
  ];
}

class _CakePainter extends CustomPainter {
  final double t;
  final int candles;
  final List<_Sprinkle> sprinkles;

  _CakePainter(
      {required this.t, required this.candles, required this.sprinkles});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── The plate, and the shadow it casts ──────────────────────────────
    final plateY = h * 0.97;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, plateY), width: w * 0.86, height: w * 0.10),
      Paint()..color = Colors.black.withOpacity(0.10),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, plateY - 3), width: w * 0.82, height: w * 0.09),
      Paint()..color = _BirthdayPalette.plate,
    );

    // ── Tier 1: the base ─────────────────────────────────────────────────
    final tier1 = Rect.fromLTWH(w * 0.10, h * 0.56, w * 0.80, h * 0.34);
    _drawTier(canvas, tier1, scallops: 7);

    // ── Tier 2: sits on the first, narrower ─────────────────────────────
    final tier2 = Rect.fromLTWH(w * 0.26, h * 0.30, w * 0.48, h * 0.30);
    _drawTier(canvas, tier2, scallops: 5);

    // ── Sprinkles, scattered on the sponge below each icing line ────────
    //
    // Short, fat capsules rather than thin slivers: at cake-on-a-card size a
    // thin rotated rectangle anti-aliases into a sliver so narrow it reads
    // as a tick or an arrowhead, not a piece of candy. Fat enough for its
    // rounded ends to still be visibly round is what keeps it a sprinkle.
    for (final s in sprinkles) {
      final tier = s.onTopTier ? tier2 : tier1;
      // Kept out of the top sixth of each tier, which is icing, not sponge.
      final area = Rect.fromLTWH(tier.left + tier.width * 0.10,
          tier.top + tier.height * 0.34, tier.width * 0.80, tier.height * 0.58);
      final center =
          Offset(area.left + area.width * s.dx, area.top + area.height * s.dy);
      final len = w * 0.034;
      final thick = w * 0.016;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // A gentle tilt, not a full spin — a sprinkle lying nearly flat reads
      // as a sprinkle; one standing on end at a random angle reads as a mark.
      canvas.rotate((s.angle - math.pi / 2) * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: len, height: thick),
            Radius.circular(thick / 2)),
        Paint()..color = s.color,
      );
      canvas.restore();
    }

    // ── The ribbon around the base ───────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(
          tier1.left, tier1.top + tier1.height * 0.62, tier1.width, h * 0.028),
      Paint()..color = _BirthdayPalette.ribbon.withOpacity(0.85),
    );

    // ── Candles, evenly set along the top tier's icing ───────────────────
    final candleTop = tier2.top;
    final margin = tier2.width * 0.16;
    for (int i = 0; i < candles; i++) {
      final fx = candles == 1
          ? 0.5
          : margin / tier2.width +
              (i / (candles - 1)) * (1 - 2 * margin / tier2.width);
      final cx = tier2.left + tier2.width * fx;
      _drawCandle(canvas, Offset(cx, candleTop), w, i);
    }
  }

  void _drawTier(Canvas canvas, Rect r, {required int scallops}) {
    final body = RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(r.width * 0.06),
      topRight: Radius.circular(r.width * 0.06),
      bottomLeft: Radius.circular(r.width * 0.10),
      bottomRight: Radius.circular(r.width * 0.10),
    );

    canvas.drawRRect(
      body.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withOpacity(0.08),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_BirthdayPalette.cream, _BirthdayPalette.creamShadow],
        ).createShader(r),
    );

    // The icing cap: a flat top, and a row of rounded lobes along the
    // bottom edge — each one a single quadratic bump — so it reads as icing
    // poured over the tier rather than a second, thinner tier stacked on it.
    //
    // This used to be built from arcToPoint calls chained tip-to-tip, which
    // needs every arc's start and end to land exactly where the one before
    // it stopped. They did not: the chain came out as a row of pointed
    // wedges, not the rounded scallops the name promised.
    final baseline = r.top + r.height * 0.34;
    final bumpW = r.width / scallops;
    final bumpDepth = bumpW * 0.42;

    final path = Path()..moveTo(r.left, r.top);
    path.lineTo(r.right, r.top);
    path.lineTo(r.right, baseline);
    for (int i = scallops - 1; i >= 0; i--) {
      final left = r.left + bumpW * i;
      final mid = left + bumpW / 2;
      path.quadraticBezierTo(mid, baseline + bumpDepth, left, baseline);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_BirthdayPalette.icing, _BirthdayPalette.icingShadow],
        ).createShader(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.34)),
    );

    // One extra drip, longer than its neighbours, hanging from the middle
    // bump — the detail that makes icing read as poured rather than painted
    // on flat.
    final dripX = r.left + r.width * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(dripX - bumpW * 0.22, baseline + bumpDepth * 0.75)
        ..quadraticBezierTo(dripX - bumpW * 0.22, baseline + bumpDepth * 1.7,
            dripX, baseline + bumpDepth * 1.85)
        ..quadraticBezierTo(dripX + bumpW * 0.22, baseline + bumpDepth * 1.7,
            dripX + bumpW * 0.22, baseline + bumpDepth * 0.75)
        ..close(),
      Paint()..color = _BirthdayPalette.drip.withOpacity(0.6),
    );
  }

  void _drawCandle(Canvas canvas, Offset base, double w, int index) {
    final stickW = w * 0.028;
    final stickH = w * 0.20;
    final color = _BirthdayPalette
        .candleSticks[index % _BirthdayPalette.candleSticks.length];

    final stick = Rect.fromCenter(
        center: Offset(base.dx, base.dy - stickH / 2),
        width: stickW,
        height: stickH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stick, Radius.circular(stickW * 0.4)),
      Paint()..color = color,
    );
    // The diagonal stripe that says "birthday candle" rather than "crayon".
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(stick, Radius.circular(stickW * 0.4)));
    for (double y = stick.top - stickW; y < stick.bottom; y += stickW * 1.6) {
      canvas.drawLine(
        Offset(stick.left - 2, y),
        Offset(stick.right + 2, y + stickW),
        Paint()
          ..color = Colors.white.withOpacity(0.65)
          ..strokeWidth = stickW * 0.4,
      );
    }
    canvas.restore();

    // ── The flame: its own frequency and phase per candle ────────────────
    final freq = 2.3 + index * 0.71; // cycles per loop — deliberately uneven
    final phase = index * 1.7;
    final flicker = math.sin(t * 2 * math.pi * freq + phase);
    final flicker2 = math.sin(t * 2 * math.pi * (freq * 1.7) + phase + 1.1);

    final tipY = stick.top - w * 0.005;
    final flameH = w * (0.075 + 0.014 * flicker);
    final flameW = w * (0.040 + 0.006 * flicker2);
    final sway = 0.12 * flicker2; // radians

    canvas.save();
    canvas.translate(base.dx, tipY);
    canvas.rotate(sway);

    // A soft glow behind the flame — what separates a drawn flame from a
    // coloured teardrop.
    canvas.drawCircle(
      Offset(0, -flameH * 0.35),
      flameH * 0.9,
      Paint()
        ..color = const Color(0xFFFFC107).withOpacity(0.28 + 0.10 * flicker)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, flameH * 0.35),
    );

    final flamePath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(flameW, -flameH * 0.45, 0, -flameH)
      ..quadraticBezierTo(-flameW, -flameH * 0.45, 0, 0)
      ..close();
    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.6),
          radius: 1.1,
          colors: [
            Color(0xFFFFF59D),
            Color(0xFFFFB300),
            Color(0xFFE65100),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCenter(
            center: Offset(0, -flameH / 2), width: flameW * 2, height: flameH)),
    );
    // The pale core, the hottest part of the flame and the brightest pixel
    // on the whole cake — what pulls the eye there first.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, -flameH * 0.30),
          width: flameW * 0.55,
          height: flameH * 0.42),
      Paint()..color = Colors.white.withOpacity(0.85),
    );
    canvas.restore();

    // The wick: a hair's width of dark under the flame, so the flame reads
    // as sitting on something rather than floating.
    canvas.drawLine(
      Offset(base.dx, tipY + 1),
      Offset(base.dx, tipY - w * 0.012),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = stickW * 0.28,
    );
  }

  @override
  bool shouldRepaint(covariant _CakePainter old) => old.t != t;
}
