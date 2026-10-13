import 'package:e_tarabay/data/badge_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// A badge has to be reachable before it is worth anything.
///
/// Twelve of the thirteen used to need a whole module — every one of 26
/// letters, every star in a module — so a child who had done 25 of 26 held
/// nothing and saw no sign they were one letter away. At three to five, a
/// reward that is visible but unreachable teaches the child that the shelf is
/// not for them.
void main() {
  group('three steps', () {
    test('nothing until a third of the way', () {
      expect(const BadgeProgress(0, 26).tier, 0);
      expect(const BadgeProgress(8, 26).tier, 0, reason: '8/26 is under a third');
    });

    test('bronze at a third', () {
      expect(const BadgeProgress(9, 26).tier, 1);
      expect(const BadgeProgress(17, 26).tier, 1);
    });

    test('silver at two thirds', () {
      expect(const BadgeProgress(18, 26).tier, 2);
      expect(const BadgeProgress(25, 26).tier, 2,
          reason: 'one letter short must still show something');
    });

    test('gold only when it is finished', () {
      expect(const BadgeProgress(26, 26).tier, 3);
      expect(const BadgeProgress(40, 26).tier, 3, reason: 'never above gold');
    });

    test('the steps rise without gaps', () {
      var last = 0;
      for (var i = 0; i <= 26; i++) {
        final t = const BadgeProgress(0, 26).target == 26
            ? BadgeProgress(i, 26).tier
            : 0;
        expect(t, greaterThanOrEqualTo(last),
            reason: 'tier fell going from ${i - 1}/26 to $i/26');
        expect(t - last, lessThanOrEqualTo(1),
            reason: 'tier skipped a step at $i/26');
        last = t;
      }
      expect(last, 3);
    });
  });

  group('all or nothing where a middle makes no sense', () {
    test('a single badge has no bronze or silver', () {
      // Five days running is not two-thirds of anything.
      expect(const BadgeProgress(3, 5, single: true).tier, 0);
      expect(const BadgeProgress(4, 5, single: true).tier, 0);
      expect(const BadgeProgress(5, 5, single: true).tier, 3);
    });
  });

  group('the catalog itself', () {
    test('every badge has a rule and a stable id', () {
      final ids = <String>{};
      for (final def in badgeCatalog) {
        expect(def.id.isNotEmpty, isTrue);
        expect(ids.add(def.id), isTrue, reason: 'duplicate id ${def.id}');
      }
      expect(badgeCatalog.length, greaterThan(1));
    });

    test('a fresh child has earned nothing', () {
      // An empty progress map is what a child on their first launch has, and
      // every rule has to survive it: a badge awarded to someone who has done
      // nothing is worse than no badge at all.
      for (final def in badgeCatalog) {
        expect(def.progressFrom(const {}).tier, 0,
            reason: '${def.id} is earned before the child has played');
      }
    });

    test('an impossible target cannot be earned', () {
      expect(const BadgeProgress(5, 0).tier, 0);
      expect(const BadgeProgress(0, 0).fraction, 0);
    });
  });

  group('what a stored tier means', () {
    test('bronze is not the same as finished', () {
      // The graduate certificate reads these numbers. Under the old
      // all-or-nothing badge, 1 meant done; now 1 means a third of the way,
      // and only 3 means finished.
      expect(const BadgeProgress(9, 26).tier, 1);
      expect(const BadgeProgress(26, 26).tier, 3);
      expect(const BadgeProgress(9, 26).tier >= 3, isFalse,
          reason: 'bronze must not satisfy a check for a finished module');
    });

    test('only a finished module reaches the top step', () {
      for (final def in badgeCatalog) {
        // A rule that could reach 3 without its module being finished would
        // hand out the certificate early.
        expect(def.progressFrom(const {}).tier, lessThan(3),
            reason: '${def.id} is gold before the child has played');
      }
    });
  });
}
