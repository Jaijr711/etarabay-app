import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/word_fit.dart';

/// The question on an About Me / My Family board: a coral speech cloud with
/// sparkles, the words in bold red with a white rim, and the dino mascot
/// calling it out through a megaphone.
///
/// It replaces a pale rounded box with the question printed in it. The
/// cloud and the mascot make the question look said, which is what it is for
/// a child who cannot read it yet.
class QuestionCloud extends StatelessWidget {
  final String question;

  const QuestionCloud(this.question, {super.key});

  static const mascot = 'assets/images/mascot_dino.webp';
  static const _ink = Color(0xFFE2412E);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final w = box.maxWidth;
      final h = box.maxHeight.isFinite ? box.maxHeight : w * 0.6;
      // The cloud takes the top of the box; the mascot stands at the bottom
      // right, overlapping its lower edge, where the tail points.
      final cloudH = h * 0.82;
      final mascotH = (h * 0.40).clamp(40.0, 120.0);
      // The words stop where the mascot's head begins, so the megaphone
      // never covers the end of the question.
      final wordsTop = cloudH * 0.16;
      final wordsBottom = min(cloudH * 0.78, h - mascotH);

      return SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 0,
            top: 0,
            width: w,
            height: cloudH,
            child: CustomPaint(painter: _CloudPainter()),
          ),
          // The words, inside the cloud's body and clear of its bumps.
          Positioned(
            left: w * 0.11,
            right: w * 0.11,
            top: wordsTop,
            height: max(0.0, wordsBottom - wordsTop),
            child: _OutlinedQuestion(question, ink: _ink),
          ),
          // Sparkles on the cloud.
          for (final s in const [
            (0.80, 0.10, 0.10),
            (0.88, 0.22, 0.06),
            (0.08, 0.50, 0.08),
          ])
            Positioned(
              left: w * s.$1,
              top: cloudH * s.$2,
              child: Icon(Icons.auto_awesome,
                  size: max(10.0, cloudH * s.$3), color: Colors.white),
            ),
          Positioned(
            right: -w * 0.01,
            bottom: 0,
            height: mascotH,
            child: Image.asset(mascot,
                fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
        ]),
      );
    });
  }
}

/// Bold text with a white rim, sized up to [base] and down to whatever fits.
class _OutlinedQuestion extends StatelessWidget {
  final String text;
  final Color ink;
  const _OutlinedQuestion(this.text, {required this.ink});

  static const _base = 40.0;

  TextStyle _style(double size) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1.1);

  /// The largest size, up to [_base], at which the question wraps between
  /// words into [box] — measured, rather than wrapped at 40 and shrunk, which
  /// turned a long question into a narrow column of one word per line.
  double _fit(BuildContext context, Size box) {
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    for (var size = _base; size > 10; size -= 1) {
      final style = base.merge(_style(size));
      if (widestWordWidth(text, style, textScaler: scaler) > box.width) {
        continue;
      }
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: box.width);
      final fits = painter.height <= box.height;
      painter.dispose();
      if (fits) return size;
    }
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final size = _fit(context, box.biggest);
      Text layer(Paint? stroke) => Text(
            text,
            textAlign: TextAlign.center,
            style: _style(size).copyWith(
              color: stroke == null ? ink : null,
              foreground: stroke,
            ),
          );
      // A white rim around bold red letters, as in the design.
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3.0, size * 0.18)
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white;
      return Center(
        child: Stack(alignment: Alignment.center, children: [
          layer(rim),
          layer(null),
        ]),
      );
    });
  }
}

/// A puffy cloud with a tail at the bottom right.
class _CloudPainter extends CustomPainter {
  static const _top = Color(0xFFFFA597);
  static const _bottom = Color(0xFFF7796C);
  static const _edge = Color(0xFFE0574C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    var cloud = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.03, h * 0.14, w * 0.97, h * 0.80),
          Radius.circular(h * 0.22)));
    void bump(double x, double y, double r) {
      cloud = Path.combine(
          PathOperation.union,
          cloud,
          Path()
            ..addOval(
                Rect.fromCircle(center: Offset(x * w, y * h), radius: r * h)));
    }

    // Bumps along the top and bottom edges.
    bump(0.22, 0.20, 0.17);
    bump(0.42, 0.13, 0.19);
    bump(0.63, 0.15, 0.17);
    bump(0.82, 0.23, 0.15);
    bump(0.10, 0.48, 0.18);
    bump(0.90, 0.50, 0.18);
    bump(0.20, 0.76, 0.14);
    bump(0.42, 0.80, 0.14);
    // The tail, pointing down to the mascot at the bottom right.
    final tail = Path()
      ..moveTo(w * 0.60, h * 0.74)
      ..quadraticBezierTo(w * 0.70, h * 0.92, w * 0.80, h * 1.0)
      ..quadraticBezierTo(w * 0.76, h * 0.86, w * 0.76, h * 0.74)
      ..close();
    cloud = Path.combine(PathOperation.union, cloud, tail);

    final bounds = Offset.zero & size;
    canvas.drawPath(
      cloud.shift(const Offset(0, 4)),
      Paint()..color = Colors.black.withOpacity(0.10),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_top, _bottom],
        ).createShader(bounds),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _edge,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}

/// Faint doodles — stars, hearts, clouds, suns — scattered behind a board,
/// as on a page of a child's notebook.
class DoodleBackground extends StatelessWidget {
  const DoodleBackground({super.key});

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: CustomPaint(painter: _DoodlePainter()));
}

class _DoodlePainter extends CustomPainter {
  static const _icons = [
    Icons.star_border_rounded,
    Icons.favorite_border_rounded,
    Icons.cloud_queue_rounded,
    Icons.wb_sunny_outlined,
    Icons.auto_awesome_outlined,
  ];
  static const _colors = [
    Color(0xFFF7C66B),
    Color(0xFFF59AB5),
    Color(0xFF8EC9F0),
    Color(0xFFB9A3EE),
    Color(0xFF9ADBB0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // The same pattern every time: a fixed seed, and a loose grid so the
    // doodles spread out instead of clumping.
    final random = Random(7);
    const cell = 64.0;
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final icon = _icons[random.nextInt(_icons.length)];
        final color = _colors[random.nextInt(_colors.length)];
        final iconSize = 18 + random.nextDouble() * 14;
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: iconSize,
              color: color.withOpacity(0.38),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final dx = x + random.nextDouble() * (cell - iconSize);
        final dy = y + random.nextDouble() * (cell - iconSize);
        canvas.save();
        canvas.translate(dx + iconSize / 2, dy + iconSize / 2);
        canvas.rotate((random.nextDouble() - 0.5) * 0.8);
        painter.paint(canvas, Offset(-iconSize / 2, -iconSize / 2));
        canvas.restore();
        painter.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) => false;
}
