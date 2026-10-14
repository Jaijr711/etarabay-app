import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/utils/word_fit.dart';
import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// No answer tile breaks a word in the middle, on any board, in any of the
/// three languages, down to the smallest tiles a phone gives them.
///
/// On a small phone "Bedroom" came out as "Bedroo" over "m". The check that
/// was meant to stop it looked at the laid-out lines, and once a word has
/// been broken every piece fits its line, so it never fired.
void main() {
  test('wordSafeFontSize shrinks only when a word does not fit', () {
    const style = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
    expect(wordSafeFontSize('Bedroom', style, 1000), 26);
    final small = wordSafeFontSize('Bedroom', style, 60);
    expect(small, lessThan(26));
    expect(widestWordWidth('Bedroom', style.copyWith(fontSize: small)),
        lessThanOrEqualTo(60));
  });

  /// Every board's choices, per language.
  List<List<String>> boards(String lang) {
    final levels = [
      PamilyaContent.getSariliLevel1Games(lang),
      PamilyaContent.getSariliLevel2Games(lang),
      PamilyaContent.getSariliLevel3Games(lang),
      PamilyaContent.getSariliLevel4Games(lang),
      PamilyaContent.getPamilyaLevel1Games(lang),
      PamilyaContent.getPamilyaLevel2Games(lang),
      PamilyaContent.getPamilyaLevel3Games(lang),
      PamilyaContent.getPamilyaLevel4Games(lang),
      PamilyaContent.getPamilyaLevel5Games(lang),
    ];
    return [
      for (final level in levels)
        for (final game in level)
          if (game['choices'] is List)
            (game['choices'] as List).map((c) => '$c').toList(),
    ];
  }

  // One grid cell on a small phone (two columns on a 320-wide screen), and
  // on a very small one.
  // A wide one-per-row tile too, where the picture sits beside the words.
  const cells = [Size(130, 110), Size(112, 92), Size(300, 108)];

  for (final lang in const ['en', 'fil', 'ilo']) {
    testWidgets('no broken words ($lang)', (tester) async {
      var checked = 0;
      for (final cell in cells) {
        for (final choices in boards(lang)) {
          final size = AnswerTile.fitFontSize(choices,
              cellW: cell.width, cellH: cell.height);
          await tester.pumpWidget(MaterialApp(
            home: Material(
              child: AnswerTileGroup(
                // Coloured tiles, as the boards draw them: the heaviest text.
                labels: choices,
                fontSize: size,
                child: Wrap(children: [
                  for (final c in choices)
                    SizedBox(
                      width: cell.width,
                      height: cell.height,
                      // Selected: bold, the wider of the two weights.
                      child: AnswerTile(
                          label: c,
                          selected: true,
                          correct: null,
                          onTap: () {}),
                    ),
                ]),
              ),
            ),
          ));

          for (final c in choices) {
            final words = AnswerTile.withoutLeadingEmoji(c);
            final finder = find.text(words);
            if (finder.evaluate().isEmpty) continue;
            final text = tester.widget<Text>(finder.first);
            final paragraph = tester.renderObject<RenderParagraph>(find
                .descendant(of: finder.first, matching: find.byType(RichText)));
            final widest = widestWordWidth(words, text.style!);
            expect(widest, lessThanOrEqualTo(paragraph.size.width + 0.5),
                reason: '"$words" in a ${cell.width}x${cell.height} tile '
                    'at ${text.style!.fontSize}');
            checked++;
          }
        }
      }
      expect(checked, greaterThan(50));
    });
  }
}
