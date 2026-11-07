import '../providers/user_provider.dart';

/// A test account the developer finished in one go, so that what is left is
/// only claiming: every lesson done at the top rating, every badge waiting
/// for its "Kunin", and the certificate after them.
///
/// Written as the `rawProgress` a phone would have pushed had the child
/// played it all, in the same keys the modules themselves write. The child's
/// phone merges it in like progress from a second phone ("finished beats
/// unfinished"), counts the stars from it, and raises the badges.
///
/// The record is marked `testAccount`, which the teacher's list shows, so
/// nobody takes it for a child's real work. A full reset takes the mark away.
class TestAccount {
  const TestAccount._();

  /// The record field that marks a test account.
  static const String field = 'testAccount';

  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _kulayPages = {'Animals': 3, 'Flowers': 2, 'Fruits': 2, 'Toys': 2};

  /// Every module, finished. Keys as each module writes them on the phone.
  static Map<String, Object> fullProgress() {
    final raw = <String, Object>{};

    // Matematika: every question of every level, three stars, a clean run.
    const perLevel = UserProvider.matematikaGamesPerLevel;
    var mathScore = 0;
    final mathGames = <String, bool>{};
    for (var lvl = 0; lvl < perLevel.length; lvl++) {
      for (var g = 0; g < perLevel[lvl]; g++) {
        raw['mat_level_${lvl}_game_$g'] = true;
        raw['matematika_game_${lvl}_$g'] = true;
        mathGames['level${lvl}_game$g'] = true;
      }
      final score = perLevel[lvl] * 10;
      mathScore += score;
      raw['mat_level_complete_$lvl'] = true;
      raw['mat_level_${lvl}_stars'] = 3;
      raw['mat_level_${lvl}_score'] = score;
    }
    raw['matematika_levels'] =
        List.filled(UserProvider.matematikaLevelCount, true);
    raw['matematika_games'] = mathGames;
    raw['matematika_stars'] = UserProvider.matematikaStarCeiling;
    raw['mat_total_stars'] = UserProvider.matematikaStarCeiling;
    raw['matematika_total'] = mathScore;
    raw['mat_total_score'] = mathScore;

    // Ang Aking Sarili (4 levels) and the family (5), three stars each.
    for (var global = 0; global < UserProvider.pamilyaLevelCount; global++) {
      final cat = global < 4 ? 0 : 1;
      final level = global < 4 ? global : global - 4;
      raw['pamilya_level_$global'] = true;
      raw['pamilya_cat_${cat}_level_$level'] = true;
      raw['pamilya_level_${global}_stars'] = 3;
    }
    raw['pamilya_levels'] = List.filled(UserProvider.pamilyaLevelCount, true);
    raw['pamilya_stars'] =
        UserProvider.sariliStarCeiling + UserProvider.familyStarCeiling;

    // Magbasa: every poem, story and song.
    const magbasa = {'tula': 5, 'kwento': 5, 'kanta': 9};
    magbasa.forEach((category, count) {
      final done = <String, bool>{};
      for (var i = 0; i < count; i++) {
        raw['${category}_activity_$i'] = true;
        raw['magbasa_${category}_$i'] = true;
        done['$i'] = true;
      }
      raw['magbasa_$category'] = done;
    });
    raw['magbasa_total'] = UserProvider.magbasaStarCeiling;

    // Kulay-Saya: every page coloured, and its star already paid.
    _kulayPages.forEach((category, count) {
      for (var i = 0; i < count; i++) {
        raw['kulay_page_${category}_$i'] = true;
        raw[UserProvider.kulayStarredKey(category, i)] = true;
      }
    });
    raw['kulay_starred_v1'] = true;
    raw['kulay_total'] = UserProvider.kulayStarCeiling;

    // Sundan Mo: every capital, small letter and number.
    for (var i = 0; i < _upper.length; i++) {
      final letter = _upper[i];
      raw['traceit_upper_$letter'] = true;
      raw['traceit_lower_${letter.toLowerCase()}'] = true;
      raw['traceit_uppercase_$i'] = true;
      raw['traceit_lowercase_$i'] = true;
    }
    for (var n = 1; n <= 10; n++) {
      raw['traceit_num_$n'] = true;
      raw['traceit_numbers_${n - 1}'] = true;
    }
    raw['traceit_uppercase'] = List.filled(26, true);
    raw['traceit_lowercase'] = List.filled(26, true);
    raw['traceit_numbers'] = List.filled(10, true);
    raw['traceit_total'] = UserProvider.traceitStarCeiling;

    // Tandaan: every round of every category, three stars a category.
    for (var cat = 0; cat < 4; cat++) {
      for (var round = 0; round < 3; round++) {
        raw['tandaan_cat_${cat}_round_$round'] = true;
        raw['tandaan_cat_${cat}_round_${round}_stars'] = 3;
      }
      raw['tandaan_cat_${cat}_stars'] = 3;
    }
    raw['tandaan_total_stars'] = UserProvider.tandaanStarCeiling;

    return raw;
  }
}
