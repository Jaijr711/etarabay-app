import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'illustration_slot.dart';

/// One thing the child can go and do.
///
/// A picture panel floating inside a white card, then the name, a few words
/// about it, and a round arrow. The whole card is the tap target — the arrow
/// is there to say "this goes somewhere", not to be aimed at, because a small
/// child does not aim well and a card that only responded to its arrow would
/// feel broken.
///
/// The coloured panel is inset rather than bled to the card's edges. Flush to
/// the edge the tint reads as the card itself, and six cards in a grid become
/// six blocks of colour; inset, each one reads as a picture sitting on a card,
/// and the white around it gives the eye somewhere to rest between them.
class LearningCard extends StatelessWidget {
  final String title;
  final String subtitle;

  /// The tinted ground behind the picture.
  final Color tint;

  /// Used for the title and the arrow button.
  final Color accent;

  final IconData icon;
  final String? assetPath;
  final VoidCallback onTap;

  const LearningCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            // The pale outline each card carries in the reference. It is the
            // module's own tint, already pale enough to sit as a border
            // without boxing the card in.
            border: Border.all(color: tint, width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (context, box) {
                // The panel takes 64% of the card's height and is inset
                // on three sides; the words and the arrow share what is left.
                final inset = box.maxWidth * 0.045;
                final panel = box.maxHeight * 0.64;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
                      child: SizedBox(
                        height: panel,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // A few faint stars in the corners. They sit
                              // behind the picture at low contrast, so they
                              // read as texture on the panel rather than as
                              // anything the child could mistake for part of
                              // the illustration.
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PanelStars(accent: accent),
                                ),
                              ),
                              Center(
                                child: IllustrationSlot(
                                  icon: icon,
                                  color: accent,
                                  // Filling the panel, as the reference does.
                                  // The picture is the card's whole point, and
                                  // a small one adrift in a coloured box is
                                  // what the old card looked like.
                                  size: panel * 0.78,
                                  assetPath: assetPath,
                                  plate: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            inset + 4, 0, inset + 2, inset * 0.6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: box.maxHeight * 0.087,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: box.maxHeight * 0.062,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7688),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Builder(builder: (_) {
                              final dot = box.maxWidth * 0.16;
                              return Container(
                                width: dot,
                                height: dot,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.chevron_right_rounded,
                                    color: Colors.white, size: dot * 0.72),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The scattering of faint stars on a card's picture panel.
///
/// Drawn rather than placed as icons so they cost nothing per card and keep
/// their positions in proportion however wide the panel ends up. Kept very
/// low contrast on purpose: this is the texture of the panel, and anything
/// brighter would compete with the picture it sits behind.
class _PanelStars extends CustomPainter {
  final Color accent;

  const _PanelStars({required this.accent});

  /// x, y and radius, all as fractions of the panel.
  static const List<List<double>> _spots = [
    [0.12, 0.16, 0.055],
    [0.86, 0.13, 0.075],
    [0.90, 0.78, 0.048],
    [0.16, 0.84, 0.040],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.55);
    final unit = size.shortestSide;

    for (final s in _spots) {
      _star(canvas, paint, Offset(size.width * s[0], size.height * s[1]),
          unit * s[2]);
    }
  }

  void _star(Canvas canvas, Paint paint, Offset centre, double r) {
    // A five-pointed star, inner radius a little under half the outer so the
    // points stay plump rather than spidery at this size.
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * 0.46;
      // Quarter turn back, so a point sits at the top.
      final angle = -math.pi / 2 + i * math.pi / points;
      final p = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PanelStars old) => old.accent != accent;
}
