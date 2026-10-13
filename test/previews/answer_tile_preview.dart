import 'dart:io';

import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the answer tiles at the sizes the board actually gives them, so
/// the design can be looked at instead of guessed at. Not part of the suite —
/// run by hand:
///
///   flutter test --update-goldens test/answer_tile_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  Widget cell(String label,
          {bool selected = false, bool? correct, double h = 130}) =>
      SizedBox(
        height: h,
        child: AnswerTile(
          label: label,
          selected: selected,
          correct: correct,
          onTap: () {},
        ),
      );

  testWidgets('answer tiles', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 960));
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        color: const Color(0xFFF3F1FA),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Two short answers side by side, the common case.
            Row(
              children: [
                Expanded(child: cell('👧 Babae')),
                const SizedBox(width: 12),
                Expanded(
                    child: cell('👦 Lalaki', selected: true, correct: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: cell('👵 Lola', selected: true, correct: false)),
                const SizedBox(width: 12),
                Expanded(child: cell('👨 Tatay')),
              ],
            ),
            const SizedBox(height: 12),
            // A sentence, one per row, at the height the board gives it.
            cell('Naglalaro kami ng basketball sa labas', h: 104),
            const SizedBox(height: 12),
            // The longest answer in the module, from "Bakit napakahalaga sa
            // atin ng ating tahanan?". Unbounded, this laid out as one line
            // and the FittedBox shrank it to about nine pixels tall while
            // "Maingay ito" in the next tile sat at twenty-eight.
            cell(
                'Pinoprotektahan at inaalagaan nito ang aming pamilya '
                'nang may pagmamahal',
                h: 104),
            const SizedBox(height: 12),
            cell('Maingay ito', h: 76),
            const SizedBox(height: 12),
            // A short tile: picture beside the word, not above it.
            cell('🍚 Kanin', h: 76),
            const SizedBox(height: 12),
            // No picture at all.
            cell('Oo', h: 76),
          ],
        ),
      ),
    ));
    // The pictures are real files: without a real event loop to decode them
    // the tiles render empty and the preview shows nothing worth judging.
    await tester.runAsync(() async {
      for (final name in ['girl', 'boy', 'lola', 'tatay', 'kanin']) {
        await precacheImage(AssetImage('assets/images/$name.png'),
            tester.element(find.byType(Column).first));
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Column).first,
        matchesGoldenFile('../../docs/previews/answer_tiles.png'));
  });
}
