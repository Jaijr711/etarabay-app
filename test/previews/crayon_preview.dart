import 'package:e_tarabay/widgets/crayon_swatch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/crayon_preview.dart
void main() {
  testWidgets('six crayons, one selected', (tester) async {
    const colors = [
      Color(0xFFFF3B30),
      Color(0xFFFF9500),
      Color(0xFFFFCC00),
      Color(0xFF007AFF),
      Color(0xFF34C759),
      Color(0xFFAF52DE),
    ];
    const labels = ['Red', 'Orange', 'Yellow', 'Blue', 'Green', 'Purple'];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            key: const Key('previewBox'),
            width: 380,
            height: 110,
            child: Row(
              children: List.generate(colors.length, (i) {
                return Expanded(
                  child: CrayonSwatch(
                    color: colors[i],
                    label: labels[i],
                    selected: i == 3,
                    onTap: () {},
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ));

    await expectLater(find.byKey(const Key('previewBox')),
        matchesGoldenFile('../../docs/previews/crayon_swatches.png'));
  });
}
