import 'package:e_tarabay/data/badge_catalog.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Numbers module's size, written in three places that must agree: the
/// provider's per-level table, its star ceiling, and the perfect-Numbers
/// badge's target.
void main() {
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
