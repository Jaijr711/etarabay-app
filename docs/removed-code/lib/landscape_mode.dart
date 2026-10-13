import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Turns a screen sideways while it is open, and puts the phone back on the
/// way out.
///
/// The app is locked to portrait in `main()` because every board was budgeted
/// against the height a phone has standing up. The four playing modules are
/// the exception: a wide, short window suits them better, because what a child
/// counts, traces or colours wants room across rather than room down.
///
/// Mixed into a screen's [State]:
///
/// ```dart
/// class _MyScreenState extends State<MyScreen> with LandscapeMode { ... }
/// ```
///
/// Nothing else to call: it locks on the way in and restores on the way out,
/// including when the child leaves with the system back gesture.
mixin LandscapeMode<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restored here rather than by whoever pushed this screen, so it happens
    // however the child leaves — the button, the gesture, or a route that
    // replaced this one.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}

/// The sizes a board should use, worked out from the window it actually has.
///
/// Phones vary more than they look: the short side of a small Android in
/// landscape is around 320 logical pixels and a large one is over 430. Fixed
/// numbers that fit one leave the other either cramped or half empty, which is
/// how the portrait boards ended up needing so much repair. Everything here is
/// derived, so one set of rules covers every phone.
class BoardMetrics {
  /// The whole play area, chrome excluded.
  final Size size;

  const BoardMetrics(this.size);

  factory BoardMetrics.of(BoxConstraints box) =>
      BoardMetrics(Size(box.maxWidth, box.maxHeight));

  bool get isLandscape => size.width > size.height;

  /// Short phones get slimmer chrome; there is nothing to spare on them.
  bool get isShort => size.height < 360;

  /// Title and heading text.
  double get titleSize => _scaled(isShort ? 17 : 20, 16, 24);

  /// The question a child has to read. The largest text on any board.
  double get questionSize => _scaled(isShort ? 22 : 26, 18, 34);

  /// Labels under a picture, and answer captions.
  double get labelSize => _scaled(isShort ? 13 : 15, 12, 19);

  /// A tap target: never below the 44 that a small finger needs.
  double get touchTarget => _scaled(isShort ? 52 : 60, 44, 76);

  /// Gap between the things on a board.
  double get gap => _scaled(isShort ? 8 : 12, 6, 18);

  /// Padding around the whole board.
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: _scaled(14, 10, 22),
        vertical: _scaled(isShort ? 6 : 10, 4, 16),
      );

  /// Scales a base size by how much window there is, then holds it between
  /// [min] and [max] so nothing ever collapses or runs away.
  double _scaled(double base, double min, double max) {
    // Measured against 360, the short side of a typical phone in landscape.
    final factor = (size.height / 360).clamp(0.80, 1.35);
    final value = base * factor;
    return value < min ? min : (value > max ? max : value);
  }
}
