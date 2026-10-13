import 'dart:io';

import 'package:e_tarabay/widgets/pop_balloon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the balloon and its burst to a sheet so the drawing can be looked
/// at instead of guessed at. Not part of the suite's job — run by hand:
///
///   flutter test --update-goldens test/balloon_preview_test.dart
void main() {
  const colors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFFEC407A),
    Color(0xFF26C6DA),
  ];

  Widget frame(double pop, Color c, int value) => SizedBox(
        width: 72 * PopBalloon.tileWidthRatio,
        height: 72 * PopBalloon.tileHeightRatio,
        child: CustomPaint(
          painter: BalloonPainter(
            value: value,
            color: c,
            body: 72,
            pop: pop,
          ),
        ),
      );

  setUpAll(() async {
    // The test engine draws every glyph as a box, and the digit is half of
    // what this sheet is for. Borrow a real one from the machine.
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('balloon sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 460));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          color: const Color(0xFFF6F4FF),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < colors.length; i++)
                    frame(0, colors[i], i + 1),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final t in [0.0, 0.12, 0.18, 0.3, 0.45, 0.65, 0.9])
                    frame(t, colors[1], 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('../../docs/previews/pop_sheet.png'),
    );
  });
}
