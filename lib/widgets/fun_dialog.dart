import 'package:flutter/material.dart';

import 'sparkle_decor.dart';

/// The frames the team's dialogs come in.
enum FunFrame {
  /// Coral at the top running to blue (Delete Artwork).
  coral,

  /// Purple running to pink (Rate Artwork, start over).
  purple,

  /// A rainbow edge (a saved picture's viewer).
  rainbow,
}

/// A dialog card as the team draws them: a thick gradient frame, a white
/// rim inside it and a pale face, with a few sparkles round the edge.
class FunDialogCard extends StatelessWidget {
  final FunFrame frame;
  final Widget child;
  final EdgeInsets padding;
  final bool sparkles;

  const FunDialogCard({
    super.key,
    required this.frame,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
    this.sparkles = true,
  });

  Gradient get _frameGradient => switch (frame) {
        FunFrame.coral => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B78), Color(0xFFF2617E), Color(0xFF7FA2E4)],
            stops: [0, 0.6, 1],
          ),
        FunFrame.purple => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7E8CE8), Color(0xFFA77BE0), Color(0xFFE48AB2)],
          ),
        FunFrame.rainbow => const SweepGradient(
            colors: [
              Color(0xFF6EC6F5),
              Color(0xFFB58BF0),
              Color(0xFFFF8FC0),
              Color(0xFFFFB86B),
              Color(0xFF7FE0B5),
              Color(0xFF6EC6F5),
            ],
          ),
      };

  Color get _face => switch (frame) {
        FunFrame.coral => const Color(0xFFFFF1F4),
        FunFrame.purple => const Color(0xFFF0EDFC),
        FunFrame.rainbow => const Color(0xFFFDF0F7),
      };

  static const _decor = DecorPainter([
    DecorMark.sparkle(0.06, 0.06, 7, Colors.white),
    DecorMark.sparkle(0.94, 0.05, 6, Colors.white),
    DecorMark.sparkle(0.04, 0.9, 5, Colors.white),
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: _frameGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _face,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: child,
        ),
      ),
      if (sparkles)
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _decor)),
        ),
    ]);
  }
}

/// A dialog that holds a [FunDialogCard] at a phone-friendly width and pops
/// in with a small bounce.
class FunDialog extends StatelessWidget {
  final Widget child;
  const FunDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.88, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (_, s, c) => Transform.scale(scale: s, child: c),
          child: child,
        ),
      ),
    );
  }
}

/// Chunky round title letters with a white rim and a soft shadow.
class FunTitle extends StatelessWidget {
  final String text;
  final double size;
  final Color color;

  const FunTitle(
    this.text, {
    super.key,
    this.size = 30,
    this.color = const Color(0xFF3550C8),
  });

  @override
  Widget build(BuildContext context) {
    TextStyle style([Paint? stroke]) => TextStyle(
          fontFamily: 'Fredoka',
          fontSize: size,
          fontVariations: const [FontVariation('wght', 700)],
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: stroke == null ? color : null,
          foreground: stroke,
        );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(children: [
        Transform.translate(
          offset: const Offset(0, 3),
          child: Text(text,
              maxLines: 1,
              style: style(Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.26
                ..strokeJoin = StrokeJoin.round
                ..color = color.withOpacity(0.25))),
        ),
        Text(text,
            maxLines: 1,
            style: style(Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.22
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white)),
        Text(text, maxLines: 1, style: style()),
      ]),
    );
  }
}

/// The colours of a [FunPillButton].
class FunColors {
  final Color top, bottom, edge;
  const FunColors(this.top, this.bottom, this.edge);

  static const red =
      FunColors(Color(0xFFFF7A6E), Color(0xFFE3342B), Color(0xFFA7231C));
  static const green =
      FunColors(Color(0xFF6DD978), Color(0xFF2E9E3E), Color(0xFF1F6B28));
  static const purple =
      FunColors(Color(0xFF8E80FF), Color(0xFF5B49D8), Color(0xFF3B2DA3));
  static const grey =
      FunColors(Color(0xFFD3D5DD), Color(0xFF9296A3), Color(0xFF6B6F7C));
}

/// A glossy 3D pill button: a gradient face, a solid edge under it and a
/// shine across the top. Sinks a little when pressed.
class FunPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final FunColors colors;
  final VoidCallback onTap;
  final double height;

  const FunPillButton({
    super.key,
    required this.label,
    required this.colors,
    required this.onTap,
    this.icon,
    this.height = 56,
  });

  @override
  State<FunPillButton> createState() => _FunPillButtonState();
}

class _FunPillButtonState extends State<FunPillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final h = widget.height;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 80),
        offset: Offset(0, _down ? 0.05 : 0),
        child: Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.top, c.bottom],
            ),
            border: Border.all(color: c.edge, width: 1.5),
            boxShadow: [
              BoxShadow(color: c.edge, offset: Offset(0, _down ? 2 : 5)),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(children: [
            Positioned(
              left: h * 0.35,
              right: h * 0.35,
              top: 4,
              height: h * 0.22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(h),
                  color: Colors.white.withOpacity(0.38),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: h * 0.42),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: h * 0.42,
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: c.edge, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A round grey close button with an X.
class FunCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const FunCloseButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            const BoxShadow(color: Color(0xFF8A7E90), offset: Offset(0, 3)),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE6DCE6), Color(0xFFB8AEBB)],
            ),
          ),
          child: const Icon(Icons.close_rounded,
              color: Color(0xFF5E5262), size: 28),
        ),
      ),
    );
  }
}
