import 'package:flutter/material.dart';

/// The basket the child drops their answer into, in Matematika's
/// "Drag the Number".
///
/// A picture rather than a dashed rectangle and an arrow: a three-year-old
/// understands "put it in the basket" from the picture alone, without being
/// able to read a word of the instruction above it. It is the team's
/// drawing — a woven basket with a round handle — cut out of its background.
class BasketPicture extends StatelessWidget {
  static const asset = 'assets/images/drop_basket.webp';

  /// The picture's own proportions (267 × 239).
  static const double aspect = 267 / 239;

  final double size;

  /// Swells and glows while a number is being held over it, so the child can
  /// see the basket is ready to receive the drop.
  final bool highlighted;

  /// The number now sitting in the basket, drawn inside it once the answer
  /// has been accepted.
  final int? holding;

  const BasketPicture({
    super.key,
    this.size = 150,
    this.highlighted = false,
    this.holding,
  });

  @override
  Widget build(BuildContext context) {
    final height = size / aspect;
    return AnimatedScale(
      scale: highlighted ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: size,
        height: height,
        child: Stack(clipBehavior: Clip.none, children: [
          // A warm glow behind it while a number hovers over it.
          if (highlighted)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC542).withOpacity(0.55),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          Positioned.fill(
            child: Image.asset(asset,
                fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
          // The number, in the woven body below the rim.
          if (holding != null)
            Positioned(
              left: 0,
              right: 0,
              top: height * 0.50,
              bottom: height * 0.06,
              child: Center(
                child: FittedBox(
                  child: Text(
                    '$holding',
                    style: TextStyle(
                      fontSize: size * 0.30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                            color: Color(0xFF5A3410),
                            blurRadius: 0,
                            offset: Offset(0, 2.5)),
                        Shadow(color: Colors.black38, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
