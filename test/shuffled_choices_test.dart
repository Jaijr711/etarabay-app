import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/utils/shuffled_choices.dart';
import 'package:flutter_test/flutter_test.dart';

/// About Me and My Family wrote the right answer in the same place in nearly
/// every question, and nothing moved it: tapping the first answer passed a
/// level. These hold the shuffle to what it promises.
void main() {
  group('the answers are mixed, the right one still known', () {
    const choices = ['🚿 Take a bath', '🍚 Eat', '📺 Watch TV', '💧 Drink'];

    test('the marked answer is still the right one', () {
      for (final seed in ['a', 'b', 'c', 'd', 'e']) {
        final (out, answer) = shuffledChoices(choices, 0, seed: seed);
        expect(out[answer], choices[0], reason: seed);
        expect(out.toSet(), choices.toSet());
      }
    });

    test('the same question and child give the same order', () {
      final a = shuffledChoices(choices, 0, seed: 'routine_hygiene|Ana');
      final b = shuffledChoices(choices, 0, seed: 'routine_hygiene|Ana');
      expect(a.$1, b.$1);
      expect(a.$2, b.$2);
    });

    test('the right answer does not always land first', () {
      final firsts = {
        for (int i = 0; i < 20; i++)
          shuffledChoices(choices, 0, seed: 'q$i|Ana').$2
      };
      expect(firsts.length, greaterThan(1));
    });

    test('"All of the above" stays last, in every language', () {
      for (final all in [
        'All of the above',
        'Lahat ng nabanggit',
        'Amin kadagitoy'
      ]) {
        final (out, answer) =
            shuffledChoices(['A', 'B', 'C', all], 3, seed: 'x');
        expect(out.last, all);
        expect(answer, 3);
      }
    });
  });

  group('every quiz question is there to be asked', () {
    // The interactive tree and house now have their own place after the
    // quiz; the seventh question used to be replaced by them.
    for (final lang in ['en', 'fil', 'ilo']) {
      test('Family Tree and Our Home keep seven questions, $lang', () {
        expect(PamilyaContent.getPamilyaLevel4Games(lang), hasLength(7));
        expect(PamilyaContent.getPamilyaLevel5Games(lang), hasLength(7));
      });
    }
  });

  group('every board, each child their own order', () {
    test('a list keeps every item, in a fixed order for one seed', () {
      const items = [1, 2, 3, 4, 5];
      final a = shuffledList(items, seed: 'mat|0|1|answers|Ana');
      expect(a.toSet(), items.toSet());
      expect(shuffledList(items, seed: 'mat|0|1|answers|Ana'), a);
    });

    test('children see the same question in different orders', () {
      const items = [1, 2, 3];
      final orders = {
        for (final name in ['Ana', 'Ben', 'Cara', 'Dina', 'Ella', 'Juan'])
          shuffledList(items, seed: 'mat|0|1|answers|$name').join()
      };
      expect(orders.length, greaterThan(1));
    });

    test('keepLast stays at the end', () {
      for (final seed in ['a', 'b', 'c', 'd']) {
        expect(shuffledOrder(4, seed: seed, keepLast: 3).last, 3);
      }
    });

    test('a catch-all answer moves when asked to', () {
      final ends = {
        for (int i = 0; i < 20; i++)
          shuffledChoices(['A', 'B', 'C', 'Lahat ng nabanggit'], 3,
                  seed: 'role|$i', keepAllOfTheAboveLast: false)
              .$2
      };
      expect(ends.length, greaterThan(1));
    });

    test('the Number Puzzle never starts solved', () {
      for (final tray in const [
        [3, 1, 2],
        [4, 2, 3],
        [5, 3, 4],
      ]) {
        for (var n = 0; n < 50; n++) {
          final out = unsolvedTray(tray, seed: 'tray|$n');
          final sorted = [...tray]..sort();
          expect(out.toSet(), tray.toSet());
          expect(out.join(), isNot(sorted.join()), reason: 'tray|$n');
        }
      }
    });
  });
}
