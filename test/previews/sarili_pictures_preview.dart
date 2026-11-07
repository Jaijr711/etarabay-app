import 'dart:io';

import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:e_tarabay/widgets/question_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ang Aking Sarili's word-only answers, as they are and with a picture in
/// front of each, side by side on the real board. Not part of the suite —
/// run by hand:
///
///   flutter test --update-goldens test/previews/sarili_pictures_preview.dart
///
/// Writes build/sarili_pictures/<id>.png.

/// The picture each answer would get, in the order the content lists them.
const pictures = <String, List<String>>{
  'role_cook': ['👩', '👨', '👵', '👨‍👩‍👧'],
  'role_work': ['👨', '👩', '👴', '👨‍👩‍👧'],
  'role_story': ['🧑', '👧', '🧓', '👨'],
  'role_care': ['👩', '👨', '👵', '👨‍👩‍👧'],
  'role_play': ['🧑', '👧', '👶', '👫'],
  'activity_dinner': ['🍲', '📺', '😴', '📱'],
  'activity_weekend': ['🏞️', '🛒', '🧹', '👨‍👩‍👧'],
  'activity_celebration': ['🎂', '😴', '📼', '🚪'],
  'activity_help': ['🧺', '🧱', '💦', '🙈'],
  'tree_1': ['🧓', '🧔', '👫', '🧒'],
  'tree_2': ['🧑', '👧', '👶', '👵'],
  'tree_3': ['👧', '🧑', '👶', '👴'],
  'tree_4': ['🧑', '👧', '👶', '👵'],
  'tree_5': ['👨‍👩‍👧', '🏘️', '👥', '🐶'],
  'tree_6': ['🌳', '📝', '📅', '⛅'],
  'tree_7': ['💕', '🤼', '🙄', '😡'],
  'home_1': ['🥘', '🛌', '🛁', '🚙'],
  'home_2': ['🛌', '🥘', '🌻', '🍽️'],
  'home_3': ['🖼️', '🛁', '📦', '🥘'],
  'home_4': ['🛁', '🖼️', '🌻', '🛌'],
  'home_5': ['🌻', '🛣️', '🔥', '🛖'],
  'home_6': ['🏡', '🏪', '📢', '🤷'],
  'home_7': ['🧹', '🗑️', '💥', '🧱'],
};

void main() {
  setUpAll(() async {
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-medium.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf',
        ]
      ),
      ('Emoji', [r'C:\Windows\Fonts\seguiemj.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        final f = File(file);
        if (!f.existsSync()) continue;
        loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      }
      await loader.load();
    }
  });

  Map<String, dynamic> game(String lang, String id) => [
        ...PamilyaContent.getPamilyaLevel2Games(lang),
        ...PamilyaContent.getPamilyaLevel3Games(lang),
        ...PamilyaContent.getPamilyaLevel4Games(lang),
        ...PamilyaContent.getPamilyaLevel5Games(lang),
      ].firstWhere((g) => g['id'] == id);

  // The board as Ang Aking Sarili lays it out (PamilyaScreen._gameBoard).
  Widget board(String title, String question, List<String> labels) {
    // Measured on the words alone: the picture in front is not more to read.
    final short =
        labels.every((l) => AnswerTile.withoutLeadingEmoji(l).length <= 16);
    final pictured =
        !short && labels.every((l) => AnswerTile.leadingEmoji(l) != null);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF26215C))),
      const SizedBox(height: 10),
      Container(
        width: 380,
        height: 620,
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
                    (double, double) cell(int cols, double cap) {
                      final rows = (labels.length / cols).ceil();
                      final available =
                          (inner.maxHeight - gap * (rows - 1)) / rows;
                      return (
                        (inner.maxWidth - gap * (cols - 1)) / cols,
                        available < cap ? available : cap,
                      );
                    }

                    double fontFor(double w, double h) =>
                        AnswerTile.fitFontSize(labels,
                            cellW: w, cellH: h, fontFamily: 'Roboto');
                    var cols = short ? 2 : 1;
                    var (cellW, cellH) = cell(cols, short ? 132.0 : 108.0);
                    if (pictured) {
                      final (w, h) = cell(2, 170.0);
                      if (fontFor(w, h) >= 15) {
                        cols = 2;
                        (cellW, cellH) = (w, h);
                      }
                    }
                    return Center(
                      child: AnswerTileGroup(
                        labels: labels,
                        fontSize: fontFor(cellW, cellH),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: cols,
                          childAspectRatio: cellW / cellH,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          children: [
                            for (final l in labels)
                              AnswerTile(
                                  label: l,
                                  selected: false,
                                  correct: null,
                                  onTap: () {}),
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
    ]);
  }

  for (final lang in ['fil', 'en', 'ilo']) {
    for (final id in pictures.keys) {
      // Filipino under its own id, the board shown to the user; the other two
      // beside it to check that their longer words fit.
      final file = lang == 'fil' ? id : '${lang}_$id';
      testWidgets(file, (tester) async {
        final g = game(lang, id);
        final next = (g['choices'] as List).cast<String>();
        await tester.binding.setSurfaceSize(const Size(380 + 32, 720));
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']),
            home: Material(
              color: const Color(0xFFF3F1FA),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: board(file, g['question'] as String, next),
              ),
            ),
          ));
          for (final e in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(e.image, tester.element(find.byWidget(e)));
          }
        });
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../build/sarili_pictures/$file.png'));
      });
    }
  }
}
