import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
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
          }.contains(c[g['correct'] as int]);
        });
        expect(all, hasLength(1), reason: lang);
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
