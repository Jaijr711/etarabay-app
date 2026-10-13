import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Full-screen answer feedback for the learning games.
///
/// Daycare children read faces and colors long before they read words, so the
/// two states are deliberately different in feel:
///
/// * [AnswerFeedback.correct] — celebratory. Bouncy badge, radiating rays and
///   floating stars.
/// * [AnswerFeedback.wrong] — states plainly that the answer was wrong (the
///   games move on to the next question rather than re-asking, so promising a
///   retry here would be misleading), but softens the delivery: warm amber
///   instead of alarm-red and a gentle wobble instead of a hard shake, so
///   getting one wrong stays safe.
/// * [AnswerFeedback.timeUp] — the clock ran out. Deliberately neither of the
///   above: a calm blue clock that neither celebrates nor scolds. Running out
///   of time says nothing about whether the child knew the answer, so it must
///   not borrow the colour, the icon or the wobble that mean "wrong".
enum _FeedbackKind { correct, wrong, timeUp }

class AnswerFeedback extends StatefulWidget {
  final _FeedbackKind _kind;
  final String message;

  const AnswerFeedback._({
    required _FeedbackKind kind,
    required this.message,
  }) : _kind = kind;

  factory AnswerFeedback.correct({required String message}) =>
      AnswerFeedback._(kind: _FeedbackKind.correct, message: message);

  factory AnswerFeedback.wrong({required String message}) =>
      AnswerFeedback._(kind: _FeedbackKind.wrong, message: message);

  factory AnswerFeedback.timeUp({required String message}) =>
      AnswerFeedback._(kind: _FeedbackKind.timeUp, message: message);

  @override
  State<AnswerFeedback> createState() => _AnswerFeedbackState();
}

class _AnswerFeedbackState extends State<AnswerFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _correctColors = [Color(0xFF34D399), Color(0xFF059669)];
  static const _tryAgainColors = [Color(0xFFFBBF24), Color(0xFFF59E0B)];
  // Calm slate blue: not the green of success, not the amber of a mistake.
  static const _timeUpColors = [Color(0xFF7DA3D9), Color(0xFF4A6FA5)];

  bool get _isCorrect => widget._kind == _FeedbackKind.correct;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = switch (widget._kind) {
      _FeedbackKind.correct => _correctColors,
      _FeedbackKind.wrong => _tryAgainColors,
      _FeedbackKind.timeUp => _timeUpColors,
    };

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Badge pops in with an elastic overshoot, then holds.
          final pop = Curves.elasticOut.transform(math.min(t / 0.45, 1.0));
          // Only a wrong answer wobbles. Time running out is not a mistake,
          // so it holds still.
          final wobble = widget._kind == _FeedbackKind.wrong
              ? math.sin(t * math.pi * 6) * (1 - t) * 0.06
              : 0.0;

          return Container(
            color: Colors.black.withOpacity(0.18 * math.min(t * 4, 1.0)),
            child: Center(
              child: Transform.rotate(
                angle: wobble,
                child: Transform.scale(
                  scale: pop,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isCorrect)
                              CustomPaint(
                                size: const Size(240, 240),
                                painter: _CelebrationPainter(progress: t),
                              ),
                            _badge(colors, t),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _messagePill(colors),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _badge(List<Color> colors, double t) {
    // Soft heartbeat once the badge has landed.
    final beat = 1 + math.sin(t * math.pi * 4) * 0.03;

    return Transform.scale(
      scale: beat,
      child: Container(
        width: 156,
        height: 156,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.45),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            switch (widget._kind) {
              _FeedbackKind.correct => LucideIcons.check,
              _FeedbackKind.wrong => LucideIcons.x,
              _FeedbackKind.timeUp => LucideIcons.clock,
            },
            color: Colors.white,
            size: 78,
          ),
        ),
      ),
    );
  }

  Widget _messagePill(List<Color> colors) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        widget.message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: colors.last,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Rays and stars radiating out from a correct answer.
class _CelebrationPainter extends CustomPainter {
  final double progress;

  _CelebrationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final burst = Curves.easeOutCubic.transform(math.min(progress / 0.7, 1.0));
    final fade = (1 - progress).clamp(0.0, 1.0);

    // Sun rays sweeping outward.
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(0.75 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (66 + 26 * burst),
        center + dir * (86 + 34 * burst),
        rayPaint,
      );
    }

    // Stars drifting out and settling.
    final starPaint = Paint()..color = const Color(0xFFFBBF24);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + 0.4;
      final dist = 74 + 44 * burst;
      final at = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      starPaint.color = const Color(0xFFFBBF24).withOpacity(fade);
      _drawStar(canvas, at, 9 * (0.5 + burst * 0.5), starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i / 10) * math.pi * 2 - math.pi / 2;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => old.progress != progress;
}
