import 'dart:io';

import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:e_tarabay/widgets/object_picture.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks on things the reviews found wrong, each once easy to get wrong
/// again without noticing.
void main() {
  group('About Me and My Family read the same in every language', () {
    final levels = <String, List<Map<String, dynamic>> Function(String)>{
      'routines': PamilyaContent.getSariliLevel3Games,
      'family members': PamilyaContent.getPamilyaLevel1Games,
      'activities': PamilyaContent.getPamilyaLevel3Games,
      'family tree': PamilyaContent.getPamilyaLevel4Games,
      'our home': PamilyaContent.getPamilyaLevel5Games,
    };
    levels.forEach((name, games) {
      test('$name: same questions, same right answer', () {
        final en = games('en'), fil = games('fil'), ilo = games('ilo');
        expect(fil, hasLength(en.length));
        expect(ilo, hasLength(en.length));
        for (int i = 0; i < en.length; i++) {
          for (final other in [fil[i], ilo[i]]) {
            expect(other['correct'], en[i]['correct'],
                reason: '$name #$i (${en[i]['id']})');
            expect((other['choices'] as List?)?.length,
                (en[i]['choices'] as List?)?.length,
                reason: '$name #$i (${en[i]['id']})');
          }
        }
      });
    });

    test('only one activity still answers "All of the above"', () {
      for (final lang in ['en', 'fil', 'ilo']) {
        final all = PamilyaContent.getPamilyaLevel3Games(lang).where((g) {
          final c = (g['choices'] as List).cast<String>();
          return const {
            'All of the above',
            'Lahat ng nabanggit',
            'Amin kadagitoy'
          }.contains(
              AnswerTile.withoutLeadingEmoji(c[g['correct'] as int]));
        });
        expect(all, hasLength(1), reason: lang);
      }
    });

    // The quiz answers in Ang Aking Sarili were once words only, which a
    // child of three cannot read; each now leads with its picture, and a new
    // or translated answer must too.
    test('every quiz answer in Ang Aking Sarili starts with a picture', () {
      final levels = [
        PamilyaContent.getPamilyaLevel2Games,
        PamilyaContent.getPamilyaLevel3Games,
        PamilyaContent.getPamilyaLevel4Games,
        PamilyaContent.getPamilyaLevel5Games,
      ];
      for (final lang in ['en', 'fil', 'ilo']) {
        for (final games in levels) {
          for (final g in games(lang)) {
            final choices = (g['choices'] as List?)?.cast<String>();
            if (choices == null) continue;
            for (final c in choices) {
              expect(AnswerTile.leadingEmoji(c), isNotNull,
                  reason: '$lang ${g['id']}: "$c"');
            }
          }
        }
      }
    });

    test('every picture an answer leads with has artwork', () {
      for (final lang in ['en', 'fil', 'ilo']) {
        for (final games in [
          PamilyaContent.getPamilyaLevel2Games,
          PamilyaContent.getPamilyaLevel3Games,
          PamilyaContent.getPamilyaLevel4Games,
          PamilyaContent.getPamilyaLevel5Games,
        ]) {
          for (final g in games(lang)) {
            for (final c in (g['choices'] as List?)?.cast<String>() ?? []) {
              final emoji = AnswerTile.leadingEmoji(c);
              if (emoji == null) continue;
              final path = ObjectPicture.assetFor(emoji);
              expect(path, isNotNull, reason: '$lang ${g['id']}: "$c"');
              expect(File(path!).existsSync(), isTrue, reason: path);
            }
          }
        }
      }
    });

    test('the level count the Lessons card divides by is every level', () {
      for (final lang in ['en', 'fil', 'ilo']) {
        final titles = PamilyaContent.getCategoryLevelTitles(lang);
        expect(titles.fold<int>(0, (n, c) => n + c.length),
            UserProvider.pamilyaLevelCount,
            reason: lang);
      }
    });
  });

  group('the language setting', () {
    test('a code the app knows is kept', () {
      for (final code in ['en', 'fil', 'ilo']) {
        expect(LanguageProvider.validCode(code), code);
      }
    });

    test('anything else falls back to English', () {
      for (final code in [null, '', 'tl', 'il', 'English']) {
        expect(LanguageProvider.validCode(code), 'en', reason: '$code');
      }
      expect(LanguageProvider('tl').currentLanguageCode, 'en');
    });
  });

  group("claims from the child's other phone are joined, not dropped", () {
    test("this phone's claims stay, the other phone's are added", () {
      expect(UserProvider.unionIds(['a', 'b'], ['b', 'c']), ['a', 'b', 'c']);
      expect(UserProvider.unionIds([], ['c']), ['c']);
    });

    test("this phone's time wins where both claimed", () {
      expect(UserProvider.unionTimes({'a': 1}, {'a': 9, 'c': 3}),
          {'a': 1, 'c': 3});
    });
  });
}
