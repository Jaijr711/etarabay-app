import 'package:flutter/material.dart';

/// One key of a PIN keypad: a rounded square, large enough for a thumb.
///
/// Shared by the parents' door and the teacher's lock. Both used an InkWell,
/// whose Material 3 sparkle and grey highlight washed over the whole key on
/// every tap, and both dimmed every key while the fourth digit was being
/// checked — so the keypad blinked on each press and again at the end. A
/// press here only darkens and slightly shrinks the key under the thumb, the
/// way a phone's own keypad does.
class PinKey extends StatefulWidget {
  const PinKey({
    super.key,
    this.width,
    required this.height,
    required this.label,
    required this.onTap,
    required this.background,
    required this.pressedColor,
    required this.child,
    this.dimmed = false,
  });

  /// Null to fill the width it is given.
  final double? width;
  final double height;
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color pressedColor;
  final Widget child;

  /// Faded, for a keypad that is locked for a while — not for the moment a
  /// code is being checked: the screen ignores taps then, quietly.
  final bool dimmed;

  @override
  State<PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<PinKey> {
  bool _down = false;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final down = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: widget.dimmed ? 0.4 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _press(true) : null,
          onTapUp: enabled ? (_) => _press(false) : null,
          onTapCancel: () => _press(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: down ? 0.94 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: widget.width,
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: down ? widget.pressedColor : widget.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
