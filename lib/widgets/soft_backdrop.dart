import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../services/device_performance.dart';

/// The soft layer over a screen's background picture.
///
/// A live blur on a phone that can draw one. On a phone that cannot (see
/// [DevicePerformance]) a plain light wash instead: the blur is redrawn over
/// the whole screen on every frame anything above it moves — scrolling, a
/// card coming in, the bar at the bottom — and that alone stuttered weak
/// phones. The pictures under it are small and stretched, so the wash reads
/// almost the same.
class SoftBackdrop extends StatelessWidget {
  const SoftBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DevicePerformance.lite,
      builder: (context, lite, _) => lite
          ? Container(color: Colors.white.withOpacity(0.25))
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.08)),
            ),
    );
  }
}
