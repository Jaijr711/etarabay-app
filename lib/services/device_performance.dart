import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

/// Whether this phone gets the app's lighter drawing.
///
/// The app runs on whatever a family has, down to old 32-bit phones with a
/// gigabyte or two. On those, the live blur behind the main screens, the
/// soft shadows under pictures and the little entrance animations on every
/// card cost more than the phone can draw in a frame, and the whole app
/// stutters. Rather than ask a parent to find a setting, the app decides:
///
/// * a phone Android calls low-RAM, or with under 3 GB or at most 4 cores,
///   is light from the start;
/// * any other phone is watched for its first two minutes, and one that
///   keeps missing frames turns light — and stays so on later launches.
///
/// Light means: no live blur or blurred shadows, a smaller picture cache,
/// and animations off (the same switch as the phone's own "remove
/// animations" setting, so every screen that honours one honours both).
/// A capable phone looks exactly as it did.
class DevicePerformance {
  DevicePerformance._();

  /// True on a phone that gets the lighter drawing.
  static final ValueNotifier<bool> lite = ValueNotifier<bool>(false);

  static const String _slowKey = 'perf_lite_v1';
  static const MethodChannel _channel = MethodChannel('etarabay/device');

  /// Reads what the phone is, before the first frame. Never waits long:
  /// a phone that does not answer quickly is treated as a capable one, and
  /// the frame watch below still catches it if it is not.
  static Future<void> init(SharedPreferences prefs) async {
    bool weak = prefs.getBool(_slowKey) ?? false;
    if (!weak && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final p = await _channel
            .invokeMapMethod<String, dynamic>('profile')
            .timeout(const Duration(milliseconds: 300));
        if (p != null) {
          weak = isWeakDevice(
            lowRam: p['lowRam'] == true,
            totalMemMb: (p['totalMemMb'] as num?)?.toInt() ?? 4096,
            cores: (p['cores'] as num?)?.toInt() ?? 8,
          );
        }
      } catch (e) {
        debugPrint('Device profile unavailable: $e');
      }
    }
    _apply(weak);
    if (!weak) _watchFrames(prefs);
  }

  /// Whether animations are off right now, for code that runs before it
  /// has a BuildContext to ask: the phone's own setting, or a weak phone.
  static bool get animationsOff =>
      lite.value ||
      WidgetsBinding
          .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  /// Whether the phone's own numbers say it is a weak one.
  @visibleForTesting
  static bool isWeakDevice({
    required bool lowRam,
    required int totalMemMb,
    required int cores,
  }) =>
      lowRam || totalMemMb < 3072 || cores <= 4;

  /// Whether a run of frames shows a phone that cannot keep up: a quarter
  /// or more of them took over one and a half frames' time. One slow frame
  /// now and then — a picture decoding, a page opening — is not that.
  @visibleForTesting
  static bool framesAreSlow(List<int> frameMicros, int budgetMicros) {
    if (frameMicros.length < 120) return false;
    final slow = frameMicros.where((m) => m > budgetMicros * 1.5).length;
    return slow * 4 >= frameMicros.length;
  }

  static void _apply(bool weak) {
    lite.value = weak;
    if (weak) {
      // Half of the default: on a phone with little memory a full cache of
      // decoded pictures pushes the app out of memory, and that is the
      // longest stutter of all.
      PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;
    }
  }

  /// Watches the first two minutes of drawing; a phone that keeps missing
  /// frames is moved to the lighter drawing, now and on later launches.
  static void _watchFrames(SharedPreferences prefs) {
    final frames = <int>[];
    late final TimingsCallback watch;
    Timer? stop;
    void done() {
      SchedulerBinding.instance.removeTimingsCallback(watch);
      stop?.cancel();
    }

    watch = (List<FrameTiming> timings) {
      for (final t in timings) {
        // Building and drawing together: the work one frame took.
        frames.add(
            t.buildDuration.inMicroseconds + t.rasterDuration.inMicroseconds);
      }
      if (frames.length < 180) return;
      final recent = frames.sublist(frames.length - 180);
      if (framesAreSlow(recent, 16667)) {
        done();
        _apply(true);
        unawaited(prefs.setBool(_slowKey, true));
      } else if (frames.length > 3600) {
        done();
      }
    };
    SchedulerBinding.instance.addTimingsCallback(watch);
    stop = Timer(const Duration(minutes: 2), done);
  }
}
