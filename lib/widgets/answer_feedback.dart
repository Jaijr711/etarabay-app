import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen answer feedback for the learning games.
///
/// Daycare children read faces and colors long before they read words, so the
/// two states are deliberately different in feel:
///
/// * [AnswerFeedback.correct] — celebratory. Bouncy badge, radiating rays and
///   floating stars.
/// * [AnswerFeedback.wrong] — states plainly that the answer was wrong (the
///   games move on to the next question rather than re-asking, so promising a
///   retry here would be misleading), with a gentle wobble instead of a hard
///   shake, so getting one wrong stays safe.
///
/// Right and wrong are the team's pictures: the mascot cheering in a green
/// circle, or crying in a red one, over a cloud with the word.
///
/// There was a third, "Time's Up", for a countdown — but no game runs one
/// (every timer is switched off for this age), so it was never seen and has
/// been removed.
enum _FeedbackKind { correct, wrong }

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

  @override
  State<AnswerFeedback> createState() => _AnswerFeedbackState();
}

class _AnswerFeedbackState extends State<AnswerFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Badge pops in with an elastic overshoot, then holds.
          final pop = Curves.elasticOut.transform(math.min(t / 0.45, 1.0));
          // Only a wrong answer wobbles.
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
                        width: 300,
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isCorrect)
                              CustomPaint(
                                size: const Size(300, 300),
                                painter: _CelebrationPainter(progress: t),
                              ),
                            _pictureBadge(t),
                          ],
                        ),
                      ),
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

  /// Right and wrong as the team drew them: the mascot cheering in a green
  /// circle, or crying in a red one, over a cloud with the word on it.
  ///
  /// The word is written by the app, not the picture: the pictures' own
  /// "Correct!" and "Wrong" were erased, so "Tama!", "Kusto!" or "Mali" look
  /// exactly like the English instead of a patch laid over a picture.
  Widget _pictureBadge(double t) {
    final correct = _isCorrect;
    final asset = correct
        ? 'assets/images/feedback_correct.webp'
        : 'assets/images/feedback_wrong.webp';
    final message = widget.message
        .replaceAll(RegExp(r'[^\p{L}\p{N}!? ]', unicode: true), '')
        .trim();
    // Where the words sit on the cloud, as fractions of the picture.
    final label = correct
        ? const Rect.fromLTRB(0.13, 0.77, 0.87, 0.935)
        : const Rect.fromLTRB(0.20, 0.775, 0.80, 0.94);
    // Soft heartbeat once the badge has landed.
    final beat = 1 + math.sin(t * math.pi * 4) * 0.03;

    return Transform.scale(
      scale: beat,
      child: AspectRatio(
        aspectRatio: correct ? 420 / 442 : 420 / 479,
        child: LayoutBuilder(builder: (_, box) {
          final w = box.maxWidth, h = box.maxHeight;
          return Stack(children: [
            Positioned.fill(child: Image.asset(asset, fit: BoxFit.contain)),
            if (message.isNotEmpty)
              Positioned(
                left: label.left * w,
                top: label.top * h,
                width: label.width * w,
                height: label.height * h,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      message,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: correct
                            ? const Color(0xFF1F4D1A)
                            : const Color(0xFF5E0E14),
                      ),
                    ),
                  ),
                ),
              ),
          ]);
        }),
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
