import 'package:flutter/material.dart';

/// Lays a page's content out at the width it was designed at, then enlarges
/// it to fill a wider phone, so it keeps the proportions of its preview.
///
/// The redesigned kid pages and module pickers were drawn and approved on a
/// phone 320 across. On a real 360 or 412 phone the same cards came out at
/// the same pixel size, so the pictures and words looked small in a lot of
/// empty space — "masyadong maliit". Here the content is laid out 320 wide
/// and scaled up to the real width: a 360 phone shows it ×1.125, a 412 phone
/// ×1.29, a 320 phone exactly as designed. Never more than [maxScale], so a
/// tablet (already enlarged by TabletScale) does not double up.
///
/// The page's own app bar or header stays outside, at its usual size.
class DesignScale extends StatelessWidget {
  final Widget child;

  const DesignScale({super.key, required this.child});

  static const double designWidth = 320;
  static const double maxScale = 1.3;

  /// How much a screen [width] across is enlarged.
  static double scaleFor(double width) =>
      width.isFinite ? (width / designWidth).clamp(1.0, maxScale) : 1.0;

  /// The width the content is laid out at on a screen [width] across. For
  /// code that measures the screen from outside the scaled part.
  static double layoutWidth(double width) => width / scaleFor(width);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      final height = box.maxHeight;
      if (!width.isFinite || !height.isFinite || width <= designWidth) {
        return child;
      }
      final scale = scaleFor(width);
      final mq = MediaQuery.of(context);
      return SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width / scale,
            height: height / scale,
            child: MediaQuery(
              data: mq.copyWith(
                size: mq.size / scale,
                padding: mq.padding / scale,
                viewPadding: mq.viewPadding / scale,
                viewInsets: mq.viewInsets / scale,
                // Pictures pick their resolution from this; scaled with the
                // layout so an enlarged picture stays sharp.
                devicePixelRatio: mq.devicePixelRatio * scale,
              ),
              child: child,
            ),
          ),
        ),
      );
    });
  }
}
