import 'dart:io';

import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:e_tarabay/widgets/question_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// An About Me board in the new design — the question in the mascot's speech
/// cloud, coloured 3D answer tiles, doodles behind — at a phone's size, with
/// a long Filipino question answered right and wrong beside it. Not part of
/// the suite — run by hand:
///
///   flutter test --update-goldens test/previews/question_board_preview.dart
///
/// Icons and emoji have no font here and draw as boxes.
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  Widget board(String question, List<String> labels,
      {int? picked, bool? right, int cols = 2}) {
    return SizedBox(
      width: 340,
      height: 600,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Stack(children: [
          const Positioned.fill(child: DoodleBackground()),
          Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (_, box) => Column(children: [
                SizedBox(
                    height: box.maxHeight * 0.42,
                    child: QuestionCloud(question)),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(builder: (_, inner) {
                    const gap = 10.0;
                    final cellW = (inner.maxWidth - gap * (cols - 1)) / cols;
                    final cellH = cols == 2 ? 132.0 : 108.0;
                    return Center(
                      child: AnswerTileGroup(
                        labels: labels,
                        fontSize: AnswerTile.fitFontSize(labels,
                            cellW: cellW, cellH: cellH, fontFamily: 'Roboto'),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: cols,
                          childAspectRatio: cellW / cellH,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          children: [
                            for (int i = 0; i < labels.length; i++)
                              AnswerTile(
                                label: labels[i],
                                selected: picked == i,
                                correct: picked == i ? right : null,
                                onTap: () {},
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  testWidgets('question board', (tester) async {
    await tester.binding.setSurfaceSize(const Size(340 * 4 + 84, 624));
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Material(
          color: const Color(0xFFF3F1FA),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              board('What is your name?', const ['Ina', 'Rosa', 'Jay']),
              const SizedBox(width: 20),
              board('Ano ang ginagawa ng pamilya sa sala tuwing gabi?',
                  const ['Nanonood', 'Naglalaba', 'Nagluluto', 'Natutulog'],
                  picked: 0, right: true),
              const SizedBox(width: 20),
              board('Sino ang nanay ng tatay mo?',
                  const ['Lola', 'Ate', 'Tita', 'Pinsan'],
                  picked: 2, right: false),
              const SizedBox(width: 20),
              // Sentences, one per row: the picture goes beside the words.
              board(
                  'What is the first thing you do in the MORNING after '
                  'waking up?',
                  const [
                    '🛏️ Wake up and get out of bed',
                    '🍳 Eat breakfast',
                    '📺 Watch TV'
                  ],
                  cols: 1),
            ]),
          ),
        ),
      ));
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('question_board.png'));
  });
}
