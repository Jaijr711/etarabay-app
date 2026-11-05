import 'dart:io';

import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Color Fun's way through: a finished picture leads on to the next one not
/// colored yet, and the star a picture gives is the child's for good —
/// clearing the picture does not take it back, and finishing it again does
/// not give a second one.
void main() {
  group('the next picture', () {
    const next = kulayNextUnfinished;

    test('is the first one after this that is not finished', () {
      expect(next([true, true, false, false], 0), 2);
    });

    test('goes on into the next category', () {
      // Animals (3) finished, the first flower not.
      expect(next([true, true, true, false, false], 2), 3);
    });

    test('wraps round to the start of the book', () {
      expect(next([false, true, true, true], 3), 0);
    });

    test('is none when every picture is finished', () {
      expect(next([true, true, true], 1), isNull);
    });
  });

  group('a picture gives its star once', () {
    setUpAll(() {
      Hive.init(Directory.systemTemp.createTempSync('kulay_flow').path);
    });

    Future<UserProvider> child(
        {Map<String, Object> prefs = const {},
        int stars = 0,
        int total = 0}) async {
      SharedPreferences.setMockInitialValues(prefs);
      final profile = await Hive.openBox('userProfile');
      final progress = await Hive.openBox('userProgress');
      await profile.clear();
      await progress.clear();
      await profile.put('currentUser', {
        'name': 'Ana',
        'gender': 'Female',
        'birthday': DateTime(2021, 5, 3).toIso8601String(),
        'createdAt': DateTime(2026, 9, 6).toIso8601String(),
        'avatar': 'animal_bunny',
        'stars': stars,
      });
      await progress.put('kulay_total', total);
      for (final e in prefs.entries) {
        if (e.key.startsWith('kulay_page_')) await progress.put(e.key, e.value);
      }
      final provider = UserProvider();
      // The provider loads itself in the background; the cloud part of that
      // fails in a test, after the boxes and the profile are in.
      for (int i = 0; i < 200 && provider.userProfile == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await provider.updateKulayProgress('warmup', false);
      return provider;
    }

    Future<void> finish(UserProvider p, String cat, int i,
            {bool done = true}) =>
        p.updateKulayProgress('coloring', done, category: cat, index: i);

    test('finishing gives one star; clearing keeps it; again gives none',
        () async {
      final p = await child();
      await finish(p, 'Animals', 0);
      expect(p.userProfile!.stars, 1);

      await finish(p, 'Animals', 0, done: false); // Cleared.
      expect(p.userProfile!.stars, 1);
      expect(p.getKulayProgress()['stars'], 1);
      expect(p.isKulayPageCompleted('Animals', 0), isFalse);

      await finish(p, 'Animals', 0); // Colored and finished again.
      expect(p.userProfile!.stars, 1);

      await finish(p, 'Fruits', 1); // A new picture still earns.
      expect(p.userProfile!.stars, 2);
      expect(p.getKulayProgress()['stars'], 2);
    });

    test('pictures finished before this are not paid for twice', () async {
      final p = await child(
        prefs: {'kulay_page_Animals_0': true, 'kulay_page_Animals_1': true},
        stars: 2,
        total: 2,
      );
      // The warm-up flagged the two without paying for them again.
      expect(p.userProfile!.stars, 2);

      await finish(p, 'Toys', 0);
      expect(p.userProfile!.stars, 3);

      await finish(p, 'Animals', 1, done: false);
      await finish(p, 'Animals', 1);
      expect(p.userProfile!.stars, 3);
    });
  });
}
