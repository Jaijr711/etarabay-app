import 'package:e_tarabay/widgets/custom_back_button.dart';
import 'package:e_tarabay/widgets/kid_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, Size size,
      {bool showBack = false,
      String title = 'Mga Aralin',
      String subtitle = 'Bituin: 3 sa 5'}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: KidPageHeader(
          title: title,
          subtitle: subtitle,
          bubble: 'Tara, mag-aral tayo!',
          color: const Color(0xFF2E9E5B),
          showBack: showBack,
        ),
        body: const SizedBox.expand(),
      ),
    ));
    await tester.pump();
  }

  double height(WidgetTester tester) =>
      tester.getSize(find.byType(KidPageHeader)).height;

  /// Tarabay's feet stay on the band.
  void mascotInside(WidgetTester tester) {
    final band = tester.getRect(find.byType(KidPageHeader));
    final mascot = tester.getRect(find.byType(Image));
    expect(mascot.bottom, lessThanOrEqualTo(band.bottom));
    expect(mascot.right, lessThanOrEqualTo(band.right));
  }

  testWidgets('a phone with room shows the line and the bubble',
      (tester) async {
    await show(tester, const Size(412, 915));
    expect(find.text('Mga Aralin'), findsOneWidget);
    expect(find.text('Bituin: 3 sa 5'), findsOneWidget);
    expect(find.text('Tara, mag-aral tayo!'), findsOneWidget);
    expect(find.byType(CustomBackButton), findsNothing);
    mascotInside(tester);
  });

  for (final size in const [Size(412, 915), Size(320, 568)]) {
    testWidgets('every page is the same height on $size', (tester) async {
      await show(tester, size);
      final tab = height(tester);
      // A back button and a different line: Profile next to Settings.
      await show(tester, size,
          showBack: true, title: 'Aking Profile', subtitle: '');
      expect(height(tester), tab);
      mascotInside(tester);
    });
  }

  testWidgets('a small phone folds it to one row about as tall as before',
      (tester) async {
    await show(tester, const Size(320, 568), showBack: true);
    // Tarabay's words stay; the line gives way.
    expect(find.text('Tara, mag-aral tayo!'), findsOneWidget);
    expect(find.text('Bituin: 3 sa 5'), findsNothing);
    expect(find.byType(CustomBackButton), findsOneWidget);
    expect(height(tester), lessThanOrEqualTo(100));
  });

  // It was squeezed to about 40 x 28 on a taller phone: its 8 of margin all
  // round needed 56 high in a 44-high title row.
  for (final size in const [Size(412, 915), Size(360, 640)]) {
    testWidgets('the back button is a full square on $size', (tester) async {
      await show(tester, size, showBack: true);
      final box = find.descendant(
          of: find.byType(CustomBackButton), matching: find.byType(Container));
      expect(tester.getSize(box), const Size(40, 40));
      final band = tester.getRect(find.byType(KidPageHeader));
      final button = tester.getRect(box);
      expect(band.contains(button.topLeft) && band.contains(button.bottomRight),
          isTrue);
    });
  }

  testWidgets('a long Ilocano title fits a small phone', (tester) async {
    await show(tester, const Size(320, 568),
        showBack: true, title: 'Ti Bukodko a Sertipiko ti Panagturpos');
    expect(tester.takeException(), isNull);
  });
}
