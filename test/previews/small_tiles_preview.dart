import 'dart:io';

import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answer tiles at a small phone's size, with words that used to be broken
/// mid-word ("Bedroo" / "m"). Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/small_tiles_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('small tiles', (tester) async {
    const cell = Size(125, 118);
    const boards = [
      ['Kitchen', 'Bedroom', 'Bathroom', 'Garage'],
      ['Kusina', 'Silid-tulugan', 'Banyo', 'Garahe'],
      [
        'Grandfather and Grandmother',
        'Uncles and Aunts',
        'Siblings',
        'Cousins'
      ],
    ];
    await tester.binding.setSurfaceSize(Size(
        cell.width * 2 * boards.length + 30.0 * boards.length + 40,
        cell.height * 2 + 36));
    Widget board(List<String> choices) => AnswerTileGroup(
          fontSize: AnswerTile.fitFontSize(choices,
              cellW: cell.width, cellH: cell.height, fontFamily: 'Roboto'),
          child: SizedBox(
            width: cell.width * 2 + 8,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in choices)
                SizedBox(
                  width: cell.width,
                  height: cell.height,
                  child: AnswerTile(
                      label: c, selected: false, correct: null, onTap: () {}),
                ),
            ]),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Material(
        color: const Color(0xFFF3F1FA),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            for (final b in boards) ...[board(b), const SizedBox(width: 16)],
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('small_tiles.png'));
  });
}
