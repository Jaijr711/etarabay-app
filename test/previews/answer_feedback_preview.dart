import 'dart:io';

import 'package:e_tarabay/widgets/answer_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Right and wrong, in English and in Filipino — the app writes the word on
/// the cloud the same way for both. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/answer_feedback_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    // The word on the cloud is in the bundled Fredoka.
    final fredoka = File('assets/fonts/Fredoka.ttf').readAsBytesSync();
    await (FontLoader('Fredoka')
          ..addFont(Future.value(ByteData.view(fredoka.buffer))))
        .load();
  });

  testWidgets('answer feedback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(4 * 320, 380));
    Widget cell(Widget child) =>
        SizedBox(width: 320, height: 380, child: child);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Material(
        color: Colors.white,
        child: Row(children: [
          cell(AnswerFeedback.correct(message: 'Correct!')),
          cell(AnswerFeedback.wrong(message: 'Wrong')),
          cell(AnswerFeedback.correct(message: 'Tama!')),
          cell(AnswerFeedback.wrong(message: 'Mali')),
        ]),
      ),
    ));
    await tester.runAsync(() async {
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('answer_feedback.png'));
  });
}
