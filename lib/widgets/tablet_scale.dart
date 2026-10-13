import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shows the phone layout, enlarged, on tablets and other big screens.
///
/// Every screen in the app is laid out for a phone held upright — about 400
/// logical pixels across. On an iPad (820 across) that layout simply
/// stretched: cards twice as wide as they are tall, text and buttons at phone
/// size in the middle of a lot of empty space. Redrawing all 23 screens for a
/// second form factor would be a second app to keep in step with the first.
///
/// Instead, on a big screen the whole app is laid out at a phone-like size
/// and then scaled up to fill the display, so a tablet shows exactly the
/// design a phone does — just larger, which is also what small hands on a
/// big screen need. When the screen is wider than a phone layout should ever
/// be (a tablet on its side, a desktop browser), the layout stops at
/// [_maxLayoutWidth] and sits centred, with the margins painted rather than
/// left as black bars.
///
/// Phones (shortest side under [_tabletShortestSide]) are passed through
/// untouched.
class TabletScale extends StatelessWidget {
  final Widget child;

  const TabletScale({super.key, required this.child});

  /// Material's own phone/tablet line.
  static const double _tabletShortestSide = 600;

  /// The width the phone design is drawn at before scaling: a large phone.
  static const double _designWidth = 430;

  /// The least height the layout is given. Game boards need roughly this much
  /// standing up (see the orientation note in main.dart), and a tablet is
  /// squarer than a phone, so scaling by width alone would leave them short.
  static const double _minLayoutHeight = 720;

  /// The widest the phone design is ever laid out.
  static const double _maxLayoutWidth = 560;

  /// Never enlarge more than this, however big the screen.
  static const double _maxScale = 2.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    if (size.shortestSide < _tabletShortestSide || size.isEmpty) return child;

    final scale = math
        .min(size.width / _designWidth, size.height / _minLayoutHeight)
        .clamp(1.0, _maxScale);
    final layoutHeight = size.height / scale;
    final layoutWidth = math.min(size.width / scale, _maxLayoutWidth);

    return ColoredBox(
      // The app's own background tint, so the margins on a wide screen read
      // as part of the app rather than as letterboxing.
      color: const Color(0xFFE8ECFB),
      child: Center(
        child: SizedBox(
          width: layoutWidth * scale,
          height: size.height,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: layoutWidth,
              height: layoutHeight,
              child: MediaQuery(
                data: mq.copyWith(
                  size: Size(layoutWidth, layoutHeight),
                  padding: mq.padding / scale,
                  viewPadding: mq.viewPadding / scale,
                  viewInsets: mq.viewInsets / scale,
                  systemGestureInsets: mq.systemGestureInsets / scale,
                  // Pictures pick their resolution from this; scaled with the
                  // layout so an enlarged image is not a blurry small one.
                  devicePixelRatio: mq.devicePixelRatio * scale,
                ),
                child: ClipRect(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
