import 'package:e_tarabay/data/badge_catalog.dart';
import 'package:e_tarabay/data/matematika_content.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three newest Matematika levels, checked as arithmetic rather than as
/// pictures.
///
/// A pattern that does not repeat, a sum that does not add up, or a right
/// answer missing from its own three choices are all invisible in review —
/// the board renders perfectly and the child is simply marked wrong for
/// answering correctly. Every one of those is a line in here.
void main() {
  group('Ano ang kasunod', () {
    test('the answer is one of the choices offered', () {
      for (final q in patternQuestions) {
        expect(q.answer, inInclusiveRange(0, q.choices.length - 1),
            reason: 'no choice at index ${q.answer}');
      }
    });

    test('three choices, no duplicates', () {
      for (final q in patternQuestions) {
        expect(q.choices.length, 3);
        expect(q.choices.toSet().length, 3,
            reason: 'the same picture twice: ${q.choices}');
      }
    });

    test('the run repeats before the child is asked to continue it', () {
      // A pattern nobody could see is a guess. Every one has to show its
      // unit at least twice over before the empty place.
      for (final q in patternQuestions) {
        final whole = q.complete;
        final unit = _period(whole);
        expect(unit, lessThan(whole.length),
            reason: '${q.shown} does not repeat at all');
        expect(whole.length / unit, greaterThanOrEqualTo(2),
            reason: '${q.shown} shows its unit only once');
      }
    });

    test('the other two choices really would break the pattern', () {
      for (final q in patternQuestions) {
        final unit = _period(q.complete);
        for (int i = 0; i < q.choices.length; i++) {
          if (i == q.answer) continue;
          final wrong = [...q.shown, q.choices[i]];
          expect(_isPeriodic(wrong, unit), isFalse,
              reason: '${q.choices[i]} continues ${q.shown} just as well');
        }
      }
    });

    test('the run fits across a phone', () {
      // Six pictures and the empty place is as much as a small screen holds
      // before each one is too small to make out.
      for (final q in patternQuestions) {
        expect(q.shown.length, lessThanOrEqualTo(6));
      }
    });
  });

  group('Pagsamahin', () {
    test('the total is among the choices', () {
      for (final q in joinQuestions) {
        expect(q.choices, contains(q.total),
            reason: '${q.left} + ${q.right} = ${q.total}, choices ${q.choices}');
      }
    });

    test('both groups have something in them', () {
      for (final q in joinQuestions) {
        expect(q.left, greaterThan(0));
        expect(q.right, greaterThan(0));
      }
    });

    test('nothing goes past five', () {
      // As far as a daycare child counts with any confidence.
      for (final q in joinQuestions) {
        expect(q.total, lessThanOrEqualTo(5));
      }
    });

    test('three choices, and only one of them right', () {
      for (final q in joinQuestions) {
        expect(q.choices.length, 3);
        expect(q.choices.where((c) => c == q.total).length, 1);
      }
    });
  });

  group('Bawasan', () {
    test('what is left is among the choices', () {
      for (final q in takeAwayQuestions) {
        expect(q.choices, contains(q.left),
            reason: '${q.from} - ${q.taken} = ${q.left}, choices ${q.choices}');
      }
    });

    test('never takes everything', () {
      // A child left with nothing has nothing to count, and zero is a harder
      // idea than any number above it.
      for (final q in takeAwayQuestions) {
        expect(q.taken, lessThan(q.from));
        expect(q.left, greaterThan(0));
      }
    });

    test('nothing starts above five', () {
      for (final q in takeAwayQuestions) {
        expect(q.from, lessThanOrEqualTo(5));
      }
    });

    test('three choices, and only one of them right', () {
      for (final q in takeAwayQuestions) {
        expect(q.choices.length, 3);
        expect(q.choices.where((c) => c == q.left).length, 1);
      }
    });
  });

  group('the module knows how big it now is', () {
    test('every level has its length written down', () {
      // A level missing from this table is a level whose questions are never
      // counted as finished, however many times the child plays it.
      expect(UserProvider.matematikaGamesPerLevel.length,
          UserProvider.matematikaLevelCount);
    });

    test('the star ceiling is three per level', () {
      expect(UserProvider.matematikaStarCeiling,
          UserProvider.matematikaLevelCount * 3);
    });

    test('the perfect-Matematika badge asks for the whole module', () {
      // The badge target is written in badge_catalog, which is deliberately
      // free of the provider — so nothing but this test keeps the two
      // numbers together. It read 21 while the module was worth 30.
      final mathWhiz = badgeCatalog.firstWhere((b) => b.id == 'mathWhiz');
      final progress = mathWhiz.rule({
        'matematika': {'earnedStars': 0}
      });
      expect(progress.target, UserProvider.matematikaStarCeiling);
    });
  });
}

/// The length of the shortest unit [xs] is a repetition of.
int _period(List<String> xs) {
  for (int p = 1; p <= xs.length; p++) {
    if (_isPeriodic(xs, p)) return p;
  }
  return xs.length;
}

bool _isPeriodic(List<String> xs, int p) {
  for (int i = 0; i < xs.length; i++) {
    if (xs[i] != xs[i % p]) return false;
  }
  return true;
}
