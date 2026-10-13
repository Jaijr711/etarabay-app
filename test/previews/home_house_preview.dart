import 'dart:io';

import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/widgets/home_house.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the My Home house at the size the board gives it on a phone, empty
/// and with a few items placed. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/home_house_preview.dart
///
/// Emoji have no font here and draw as boxes; the room pictures are real.
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  Future<void> shoot(WidgetTester tester, String name, Size size,
      Map<int, List<String>> placed) async {
    await tester.binding
        .setSurfaceSize(Size(size.width * 2 + 36, size.height + 24));
    final rooms = PamilyaContent.getHomeRooms('en');
    Widget board(Map<int, List<String>> p) => Container(
          width: size.width,
          height: size.height,
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: HomeHouse(rooms: rooms, placed: p, onRoomTap: (_) {}),
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
              board(const {}),
              const SizedBox(width: 12),
              board(placed),
            ]),
          ),
        ),
      ));
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
  }

  testWidgets('house on a phone', (tester) async {
    await shoot(tester, 'home_house_phone.png', const Size(330, 470), {
      0: ['📺'],
      2: ['🛏️'],
      4: ['🌷'],
    });
  });

  testWidgets('house on a small phone', (tester) async {
    await shoot(tester, 'home_house_small.png', const Size(300, 380), {
      1: ['🍳'],
    });
  });
}
