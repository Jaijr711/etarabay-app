import 'dart:async';

import 'package:flutter/material.dart';

class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final int delayMs;
  final int durationMs;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayMs = 80,
    this.durationMs = 600,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMs),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // A timer that leaving the screen cancels, rather than a delay that
    // fired anyway, after the item was gone.
    _start = Timer(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Animations off — the phone's own setting, or a phone too weak to draw
    // them smoothly (see DevicePerformance): the item is simply there.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    // The transitions listen to the controller themselves; wrapping them in
    // a builder too rebuilt this whole item on every frame of its entrance.
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
