import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/sfx.dart';
import 'badge_emblem.dart';
import 'fun_dialog.dart';

/// A medal being claimed: it arrives still locked, a gold light grows
/// behind it and a shine runs across it, the lock opens (the phone gives a
/// little knock), the medal bursts into its colours under falling gold, and
/// then it flies down into its place on the shelf. One tap on the shelf
/// brings it; it leaves by itself, or at a tap.
///
/// Claiming used to take three taps — the medal, a "Claim" card, then a
/// card to close — and made no sound.
class BadgeClaimCelebration extends StatefulWidget {
  const BadgeClaimCelebration({
    super.key,
    required this.icon,
    required this.image,
    required this.color,
    required this.tier,
    required this.title,
    this.target,
    this.autoClose = true,
    @visibleForTesting this.debugSeconds,
  });

  final IconData icon;
  final String? image;
  final Color color;
  final int tier;
  final String title;

  /// Where the medal sits on the shelf, on screen: it flies there at the
  /// end. Without one it simply fades.
  final Rect? target;
  final bool autoClose;

  /// For previews: the moment to show, in seconds.
  final double? debugSeconds;

  /// Seconds into the animation. The sound (tool/make_claim_sound.py)
  /// strikes its chord at [unlock], so the two must move together.
  static const double unlock = 1.3;
  static const double flyStart = 2.75;
  static const double end = 3.45;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String? image,
    required Color color,
    required int tier,
    required String title,
    Rect? target,
  }) {
    Sfx.play(Sfx.claim);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      // Drawn by the page itself, so it can lift as the medal flies home.
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => BadgeClaimCelebration(
        icon: icon,
        image: image,
        color: color,
        tier: tier,
        title: title,
        target: target,
      ),
    );
  }

  @override
  State<BadgeClaimCelebration> createState() => _BadgeClaimCelebrationState();
}

class _BadgeClaimCelebrationState extends State<BadgeClaimCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: (BadgeClaimCelebration.end * 1000).round()));
  // The rays keep turning, slowly, for as long as the card is up.
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));
  final _medalKey = GlobalKey();
  Rect? _from;
  bool _knocked = false;
  bool _closing = false;

  double get _seconds =>
      widget.debugSeconds ?? _c.value * BadgeClaimCelebration.end;

  @override
  void initState() {
    super.initState();
    if (widget.debugSeconds != null) {
      _c.value = widget.debugSeconds! / BadgeClaimCelebration.end;
      return;
    }
    _spin.repeat();
    _c.addListener(() {
      final s = _seconds;
      if (!_knocked && s >= BadgeClaimCelebration.unlock) {
        _knocked = true;
        HapticFeedback.mediumImpact();
      }
    });
    _c.forward().then((_) {
      if (widget.autoClose) _close();
    });
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _c.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// 0..1 across the seconds between [a] and [b].
  double _part(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// Where the medal is drawn now, on screen: read once, as it starts to
  /// fly.
  Rect? _medalRect() {
    final box = _medalKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final medal = math.min(MediaQuery.of(context).size.width * 0.46, 190.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _spin]),
          builder: (context, _) {
            final t = _seconds;
            const u = BadgeClaimCelebration.unlock;
            const fly = BadgeClaimCelebration.flyStart;
            const end = BadgeClaimCelebration.end;
            final arrive = Curves.easeOutBack.transform(_part(t, 0, 0.45));
            final light = Curves.easeIn.transform(_part(t, 0.3, u));
            final shine = _part(t, 0.55, u - 0.05);
            final after = _part(t, u, u + 1.3);
            final pop = Curves.elasticOut.transform(_part(t, u, u + 0.95));
            final flash = t < u ? 0.0 : (1 - _part(t, u, u + 0.4));
            final unlocked = t >= u;
            final lockLift = _part(t, u, u + 0.55);
            final words = Curves.easeOut.transform(_part(t, 1.6, 2.1));
            final leaving = Curves.easeInOutCubic.transform(_part(t, fly, end));
            // A last shake of the lock before it gives.
            final shake = t > u - 0.35 && t < u
                ? math.sin((t - (u - 0.35)) * 60) * 0.08
                : 0.0;
            final glow = (unlocked ? 1.0 : light) * (1 - leaving);
            final scale = unlocked ? 0.9 + 0.25 * pop : 0.6 + 0.3 * arrive;
            final spin = _spin.value * 2 * math.pi;

            final target = widget.target;
            if (t >= fly && _from == null && target != null) {
              _from = _medalRect();
            }
            final flying = t >= fly && target != null && _from != null;

            final center = Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: medal * 2.2,
                height: medal * 2.2,
                child: Stack(alignment: Alignment.center, children: [
                  // The gold light: rays turning, a glow under them.
                  CustomPaint(
                    size: Size.square(medal * 2.2),
                    painter:
                        _GoldLight(strength: glow, turn: spin, burst: after),
                  ),
                  Opacity(
                    opacity: flying ? 0 : 1 - (target == null ? leaving : 0),
                    child: Transform.rotate(
                      angle: shake,
                      child: Transform.scale(
                        scale: scale,
                        child: Stack(
                            key: _medalKey,
                            alignment: Alignment.center,
                            children: [
                              BadgeEmblem(
                                icon: widget.icon,
                                image: widget.image,
                                color: widget.color,
                                size: medal,
                                locked: !unlocked,
                                tier: unlocked ? widget.tier : 0,
                                sparkle: unlocked,
                              ),
                              // The shine running across the locked medal.
                              if (!unlocked && shine > 0 && shine < 1)
                                IgnorePointer(
                                  child: ClipOval(
                                    child: SizedBox.square(
                                      dimension: medal,
                                      child:
                                          CustomPaint(painter: _Sheen(shine)),
                                    ),
                                  ),
                                ),
                              // The flash as it opens.
                              if (flash > 0)
                                IgnorePointer(
                                  child: Container(
                                    width: medal * 1.1,
                                    height: medal * 1.1,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withOpacity(0.85 * flash),
                                    ),
                                  ),
                                ),
                            ]),
                      ),
                    ),
                  ),
                  // Gold sparkles bursting out as it opens.
                  if (after > 0 && after < 1)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.square(medal * 2.2),
                        painter: _Sparkles(after, widget.color),
                      ),
                    ),
                  // The lock, opening and floating away.
                  if (lockLift > 0 && lockLift < 1)
                    Transform.translate(
                      offset: Offset(0, -medal * 0.55 - 40 * lockLift),
                      child: Opacity(
                        opacity: 1 - lockLift,
                        child: Icon(Icons.lock_open_rounded,
                            size: medal * 0.32, color: const Color(0xFFFFE082)),
                      ),
                    ),
                ]),
              ),
              Opacity(
                opacity: words * (1 - leaving),
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - words)),
                  child: Column(children: [
                    Transform.scale(
                      scale: 0.7 +
                          0.3 * Curves.elasticOut.transform(_part(t, 1.6, 2.4)),
                      child: FunTitle(loc.claimYouGotIt,
                          size: 34, color: const Color(0xFFFFC928)),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 22,
                          fontVariations: [FontVariation('wght', 600)],
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]);

            return Stack(children: [
              Positioned.fill(
                child: ColoredBox(
                    color: Colors.black.withOpacity(0.78 * (1 - leaving))),
              ),
              Center(child: center),
              // Home to the shelf: smaller and smaller, into its place.
              if (flying)
                Positioned.fromRect(
                  rect: Rect.lerp(_from, target, leaving)!,
                  child: FittedBox(
                    child: BadgeEmblem(
                      icon: widget.icon,
                      image: widget.image,
                      color: widget.color,
                      size: medal,
                      tier: widget.tier,
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

/// Gold rays turning behind the medal, with a soft glow under them.
class _GoldLight extends CustomPainter {
  _GoldLight({required this.strength, required this.turn, required this.burst});

  final double strength;
  final double turn;

  /// 0..1 after the unlock: the rays reach further for a moment.
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFE27A).withOpacity(0.85 * strength),
        const Color(0xFFFFB300).withOpacity(0.35 * strength),
        const Color(0x00FFB300),
      ], stops: const [
        0.0,
        0.45,
        1.0
      ]).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, glow);

    const rays = 14;
    final reach =
        r * (0.75 + 0.25 * strength + 0.12 * math.sin(burst * math.pi));
    final ray = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFF3B0).withOpacity(0.9 * strength),
        const Color(0x00FFD54F),
      ]).createShader(Rect.fromCircle(center: c, radius: reach));
    for (var i = 0; i < rays; i++) {
      final a = turn + i * 2 * math.pi / rays;
      const half = math.pi / rays * 0.42;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + reach * math.cos(a - half),
            c.dy + reach * math.sin(a - half))
        ..lineTo(c.dx + reach * math.cos(a + half),
            c.dy + reach * math.sin(a + half))
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(_GoldLight old) =>
      old.strength != strength || old.turn != turn || old.burst != burst;
}

/// A band of gold light passing across the medal, left to right.
class _Sheen extends CustomPainter {
  _Sheen(this.at);
  final double at;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.6 + size.width * 2.2 * at;
    final band =
        Rect.fromLTWH(x - size.width * 0.3, 0, size.width * 0.6, size.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.5);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(
      band.inflate(size.height * 0.3),
      Paint()
        ..shader = const LinearGradient(colors: [
          Color(0x00FFF8DC),
          Color(0xF2FFF6C8),
          Color(0x00FFF8DC),
        ]).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Sheen old) => old.at != at;
}

/// Gold sparkles thrown out from the medal as the lock opens: four-pointed
/// stars and little dots, flying out, slowing, falling a little, fading.
class _Sparkles extends CustomPainter {
  _Sparkles(this.t, this.color);

  /// 0..1 since the unlock.
  final double t;
  final Color color;

  static final _seeds = List.generate(30, (i) {
    final r = math.Random(i * 7919 + 13);
    return (
      angle: i * 2 * math.pi / 30 + r.nextDouble() * 0.3,
      speed: 0.45 + r.nextDouble() * 0.55,
      size: 0.035 + r.nextDouble() * 0.045,
      star: i % 3 != 2,
      spin: r.nextDouble() * 2 - 1,
      tint: i % 5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final reach = size.width * 0.5;
    final eased = Curves.easeOutCubic.transform(t);
    final fade = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    for (final s in _seeds) {
      final d = reach * s.speed * eased;
      final p = c +
          Offset(math.cos(s.angle) * d,
              math.sin(s.angle) * d + reach * 0.25 * t * t);
      final r = size.width * s.size * (1 - 0.4 * t);
      final colour = switch (s.tint) {
        0 => Colors.white,
        1 => color,
        2 => const Color(0xFFFFB300),
        _ => const Color(0xFFFFD700),
      };
      final paint = Paint()..color = colour.withOpacity(fade.clamp(0, 1));
      if (s.star) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(s.spin * t * math.pi);
        final path = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..quadraticBezierTo(0, 0, 0, r)
          ..quadraticBezierTo(0, 0, -r, 0)
          ..quadraticBezierTo(0, 0, 0, -r)
          ..close();
        canvas.drawPath(path, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(p, r * 0.45, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Sparkles old) => old.t != t;
}
