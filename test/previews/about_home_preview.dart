import 'dart:io';

import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// About Me's "Who do you live with?" answers in each language, the family
/// drawn as a picture like the dog and the bear beside it. Not part of the
/// suite — run by hand:
///
///   flutter test --update-goldens test/previews/about_home_preview.dart
void main() {
  setUpAll(() async {
    final f = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (f.existsSync()) {
      await (FontLoader('Roboto')
            ..addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer))))
          .load();
    }
  });

  for (final lang in ['ilo', 'fil', 'en']) {
    testWidgets('who do you live with, $lang', (tester) async {
      final game = PamilyaContent.getSariliLevel1Games(lang)
          .firstWhere((g) => g['id'] == 'about_home');
      final options = (game['options'] as List).cast<String>();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(400, 560) * 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(game['question'] as String,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE5484D))),
              const SizedBox(height: 18),
              for (final o in options) ...[
                // The board gives each answer its row's height.
                SizedBox(
                  height: 120,
                  child: AnswerTile(
                      label: o,
                      selected: false,
                      correct: null,
                      onTap: () {},
                      minHeight: 110),
                ),
                const SizedBox(height: 12),
              ],
            ]),
          ),
        ),
      ));
      await tester.runAsync(() async {
        for (final img in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(
              img.image, tester.element(find.byWidget(img).first));
        }
      });
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../build/size_audit/about_home_$lang.png'));
    });
  }
}
