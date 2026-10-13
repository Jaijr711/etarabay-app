import 'dart:io';

import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/widgets/family_tree_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the family tree board at a phone's size, in English and in
/// Filipino (names laid over the picture's English ones) with the father
/// tapped. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/family_tree_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('family tree on a phone', (tester) async {
    const size = Size(310, 470);
    await tester.binding
        .setSurfaceSize(Size(size.width * 2 + 36, size.height + 24));
    Widget board(String lang) => Container(
          width: size.width,
          height: size.height,
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: FamilyTreePicture(
            key: ValueKey(lang),
            generations:
                PamilyaContent.getFamilyTreeData(lang)['generations'] as List,
            onMemberTap: (_) {},
            ownLabels: lang != 'en',
          ),
        );
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Material(
          color: const Color(0xFFF3F1FA),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              board('en'),
              const SizedBox(width: 12),
              board('fil'),
            ]),
          ),
        ),
      ));
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    // Tap the father on the Filipino board, so the ring shows.
    final fil = tester.getRect(find.byType(AspectRatio).last);
    await tester.tapAt(
        fil.topLeft + Offset(233 / 900 * fil.width, 625 / 1574 * fil.height));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('family_tree_phone.png'));
  });
}
