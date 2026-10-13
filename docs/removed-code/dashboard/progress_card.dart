import 'package:flutter/material.dart';

import 'illustration_slot.dart';

/// One count on the progress card.
class ProgressStat {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const ProgressStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
}

/// "My Progress Today" — a few counts, and a path with stars on it.
///
/// The path is the part a three-year-old reads: they cannot yet read "2 of 3
/// lessons", but they can see how far along the walker is and how many stars
/// are still ahead.
class ProgressCard extends StatelessWidget {
  final String title;
  final List<ProgressStat> stats;

  /// How many steps on the path, and how many are already won.
  final int totalSteps;
  final int completedSteps;

  final String? walkerAssetPath;

  const ProgressCard({
    super.key,
    required this.title,
    required this.stats,
    required this.totalSteps,
    required this.completedSteps,
    this.walkerAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6DC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3E4B4), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A227).withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B4B12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                if (i > 0)
                  Container(
                      width: 1.5, height: 36, color: const Color(0xFFEEDFB4)),
                Expanded(child: _Stat(stat: stats[i])),
              ],
            ],
          ),
          const SizedBox(height: 14),
          LearningPath(
            totalSteps: totalSteps,
            completedSteps: completedSteps,
            walkerAssetPath: walkerAssetPath,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final ProgressStat stat;

  const _Stat({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: stat.color,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(stat.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stat.value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B4310),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8C7434),
          ),
        ),
      ],
    );
  }
}

/// A green hill with stars along it and a walker part way up.
///
/// Drawn rather than assembled from images so it works on any width, and so
/// the number of stars follows the data instead of being baked into a picture.
class LearningPath extends StatelessWidget {
  final int totalSteps;
  final int completedSteps;
  final String? walkerAssetPath;

  const LearningPath({
    super.key,
    required this.totalSteps,
    required this.completedSteps,
    this.walkerAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final steps = totalSteps < 1 ? 1 : totalSteps;
    final done = completedSteps.clamp(0, steps);

    return SizedBox(
      height: 96,
      child: LayoutBuilder(
        builder: (context, box) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _HillPainter()),
              ),
              // The walker stands at the left, where the path begins.
              Positioned(
                left: 6,
                bottom: 10,
                child: IllustrationSlot(
                  icon: Icons.directions_walk_rounded,
                  color: const Color(0xFF2C7BE5),
                  size: 46,
                  assetPath: walkerAssetPath,
                ),
              ),
              // Stars spread along the right of the hill.
              Positioned(
                left: box.maxWidth * 0.34,
                right: 8,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(steps, (i) {
                    final won = i < done;
                    // A gentle arc, so the stars sit on the hill rather than
                    // in a straight line across it.
                    final lift = (i.isEven ? 6.0 : -4.0) - i * 2.0;
                    return Transform.translate(
                      offset: Offset(0, lift),
                      child: _PathStar(won: won),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PathStar extends StatelessWidget {
  final bool won;

  const _PathStar({required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        won ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 24,
        color: won ? const Color(0xFFFFB800) : const Color(0xFFD8DEE7),
      ),
    );
  }
}

class _HillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.42, h * 0.30, w, h * 0.44)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      hill,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB7E88F), Color(0xFF83CF62)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // The dotted trail the walker follows.
    final trail = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(w * 0.10, h * 0.86)
      ..quadraticBezierTo(w * 0.45, h * 0.52, w * 0.94, h * 0.62);

    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + 7).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), trail);
        d += 15;
      }
    }

    // A flag at the top of the climb.
    final poleX = w * 0.95;
    final poleTop = h * 0.24;
    canvas.drawLine(
      Offset(poleX, poleTop),
      Offset(poleX, h * 0.60),
      Paint()
        ..color = const Color(0xFF7A5C3A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(poleX, poleTop)
        ..lineTo(poleX - 20, poleTop + 8)
        ..lineTo(poleX, poleTop + 16)
        ..close(),
      Paint()..color = const Color(0xFFF05A5A),
    );
  }

  @override
  bool shouldRepaint(_HillPainter oldDelegate) => false;
}
