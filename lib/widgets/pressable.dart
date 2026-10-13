import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Something a child taps, that answers the finger straight away.
///
/// The app had sixty-one tappable things and not one of them moved while a
/// finger was on it: every tile waited for the tap to finish, and then showed
/// a verdict. For a three-year-old that gap is the whole question — *did it
/// hear me?* — and the usual answer is to press harder, or press again, which
/// is how a child ends up answering twice.
///
/// So the tile sinks under the finger and comes back when it is let go. It is
/// the smallest animation in the app and the one that gets used the most.
///
/// The press is deliberately faster going down (70ms) than coming back
/// (160ms, with a little overshoot): the first has to feel instant, and the
/// second is what makes it feel springy rather than mechanical.
class Pressable extends StatefulWidget {
  final Widget child;

  /// Null disables the whole thing — a tile that cannot be tapped must not
  /// pretend it can.
  final VoidCallback? onTap;

  /// How far it sinks. Small tiles need proportionally more than big ones to
  /// read as movement at all.
  final double scale;

  /// A light tap on the phone as the finger lands, not when it lifts. Off for
  /// anything that already buzzes for its own reasons.
  final bool haptic;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.haptic = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down == down || !mounted) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled
          ? (_) {
              _set(true);
              if (widget.haptic) HapticFeedback.selectionClick();
            }
          : null,
      // Both of these matter: a child's finger slides, and a tap that is
      // dragged off the tile has to let it come back up rather than leaving
      // it stuck down.
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              _set(false);
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Duration(milliseconds: _down ? 70 : 160),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
