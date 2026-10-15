import 'dart:io';

import 'package:e_tarabay/widgets/question_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The question cloud with the longest questions the app asks, in every
/// language, at a narrow and a wide phone's width — to see that nothing in
/// the cloud runs into anything else. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/cloud_stress_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  const questions = [
    'Arrange the numbers in the correct order/Sequence: 1 → 2 → 3',
    'Putukin ang lahat ng lobo na may bilang na 3',
    'Sino ang nag-aalaga sa iyo, nagluluto ng pagkain at nagpaparamdam ng pagmamahal?',
    'Bittaken amin a balloon a addaan 3',
    'Which side have lesser, left or right?',
    'Same number?',
  ];

  for (final width in [328.0, 400.0]) {
    testWidgets('clouds at $width', (tester) async {
      final h = width * 0.50;
      await tester.binding
          .setSurfaceSize(Size(width + 20, (h + 16) * questions.length + 20));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Material(
          color: const Color(0xFFEFF2F8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              for (final q in questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                      width: width, height: h, child: QuestionCloud(q)),
                ),
            ]),
          ),
        ),
      ));
      await tester.runAsync(() async {
        for (final e in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(e.image, tester.element(find.byWidget(e)));
        }
      });
      await tester.pump();
      await expectLater(find.byType(Material).first,
          matchesGoldenFile('../../docs/previews/cloud_${width.toInt()}.png'));
    });
  }
}
