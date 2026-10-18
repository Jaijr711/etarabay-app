import 'package:flutter/material.dart';

/// Keeps every screen clear of the phone's own navigation bar — the home,
/// back and recent-apps buttons, or the gesture handle.
///
/// The app targets Android 15+, which draws every app edge to edge: the
/// navigation bar sits on top of the app's own bottom edge. Most screens
/// here were laid out before that and put buttons at the very bottom (the
/// answers in Numbers, the tools in Color Fun), where the phone's buttons
/// covered them, and lists ran their last item under the bar. Rather than
/// trust every screen, dialog and sheet to remember a SafeArea, the whole
/// app is lifted above the bar here, once.
///
/// [MediaQueryData.padding] rather than viewPadding: it drops to zero while
/// the keyboard is up (the keyboard already covers the bar), so a screen
/// with a text field does not get the bar's height added twice.
///
/// The status bar at the top is left to each screen's own header, which
/// already pads for it.
class SystemBarsGuard extends StatelessWidget {
  final Widget child;

  /// The strip under the app, behind the phone's buttons.
  final Color color;

  const SystemBarsGuard({
    super.key,
    required this.child,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom;
    if (bottom <= 0) return child;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: MediaQuery(
          // Screens below see no bar at all, so one with its own SafeArea
          // does not lift itself a second time.
          data: mq.copyWith(
            padding: mq.padding.copyWith(bottom: 0),
            viewPadding: mq.viewPadding.copyWith(bottom: 0),
          ),
          child: child,
        ),
      ),
    );
  }
}
