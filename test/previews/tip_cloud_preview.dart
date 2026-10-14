import 'dart:io';

import 'package:e_tarabay/widgets/tip_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tip pop-up after an answer, at a phone's width, with a long English
/// tip and a short Filipino one. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/tip_cloud_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('tip cloud', (tester) async {
    await tester.binding.setSurfaceSize(const Size(380 * 2 + 20, 560));
    Widget tip(String text) => SizedBox(
          width: 380,
          child: Container(
            color: const Color(0xFFDCDCE4),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: TipCloud(text),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Material(
        child: Row(children: [
          tip('Correct! We are happy when good things happen like receiving '
              'gifts or celebrating. Smile and share your happiness with your '
              'family!'),
          const SizedBox(width: 20),
          tip('Tama! Ang Lola ay nanay ng iyong tatay o nanay.'),
        ]),
      ),
    ));
    await tester.runAsync(() async {
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('tip_cloud.png'));
  });
}
