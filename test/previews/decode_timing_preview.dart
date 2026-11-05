import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// How long a coloring picture takes to decode: in Dart (how Color Fun used
/// to open a page) against the platform's own decoder (how it does now).
/// Not part of the suite — run by hand:
///
///   flutter test test/previews/decode_timing_preview.dart
void main() {
  testWidgets('decode timing', (tester) async {
    await tester.runAsync(() async {
      for (final name in [
        'paint1.png',
        'paint8.png',
        'paint_elephant.webp',
        'paint_daisy.webp'
      ]) {
        final bytes = File('assets/images/$name').readAsBytesSync();
        var sw = Stopwatch()..start();
        for (int i = 0; i < 5; i++) {
          img.decodeImage(bytes);
        }
        final dart = sw.elapsedMilliseconds / 5;

        sw = Stopwatch()..start();
        for (int i = 0; i < 5; i++) {
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          await frame.image
              .toByteData(format: ui.ImageByteFormat.rawStraightRgba);
          frame.image.dispose();
          codec.dispose();
        }
        final native = sw.elapsedMilliseconds / 5;
        // ignore: avoid_print
        print('TIMING $name: Dart ${dart.toStringAsFixed(1)} ms, '
            'native ${native.toStringAsFixed(1)} ms');
      }
    });
  });
}
