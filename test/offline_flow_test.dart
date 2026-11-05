import 'dart:io';

import 'package:e_tarabay/models/user_model.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a child does offline, and what months of use do: nothing they
/// finished is lost or moved when the phone is handed to another child,
/// medals claimed offline stay claimed, and the song list is not migrated
/// twice.
void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('offline_flow').path);
  });

  Future<UserProvider> device({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    for (final name in ['userProfile', 'userProgress', 'stashedWork']) {
      await (await Hive.openBox(name)).clear();
    }
    await Hive.box('userProfile').put('currentUser', {
      'name': 'Ana',
      'gender': 'Female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 5,
    });
    return loaded(UserProvider());
  }

  /// Signs [id] in. The cloud listener it starts has no Firebase in a test;
  /// everything this file checks happens before that.
  Future<void> signIn(UserProvider p, String id) async {
    try {
      await p.startStudentSession(id);
    } catch (_) {}
  }

  group('another child signs in on the same phone', () {
    test("the first child's unsent work is kept, and comes back with them",
        () async {
      final p = await device(prefs: {
        'local_progress_owner': 'child-a',
        'local_unpushed': true,
        'kulay_page_Animals_0': true,
        'traceit_letter_0': true,
      });
      await signIn(p, 'child-b');
      final prefs = await SharedPreferences.getInstance();
      // Child B starts clean...
      expect(prefs.getBool('kulay_page_Animals_0'), isNot(true));
      expect(prefs.getBool('traceit_letter_0'), isNot(true));

      // ...and child A finds their work again.
      await signIn(p, 'child-a');
      expect(prefs.getBool('kulay_page_Animals_0'), isTrue);
      expect(prefs.getBool('traceit_letter_0'), isTrue);
      // Still to be sent, so it is kept again if handed over before then.
      expect(prefs.getBool('local_unpushed'), isTrue);
    });

    test('work already sent is not kept aside', () async {
      final p = await device(prefs: {
        'local_progress_owner': 'child-a',
        'local_unpushed': false,
        'kulay_page_Animals_0': true,
      });
      await signIn(p, 'child-b');
      expect(Hive.box('stashedWork').get('child-a'), isNull);
    });
  });

  test('clearing the phone keeps the song list from being migrated again',
      () async {
    final p = await device();
    await p.clearLocalData();
    // The cloud's copy arrives, already in the new nine-slot layout.
    final prefs = await SharedPreferences.getInstance();
    final restored = [
      true,
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      true
    ];
    for (int i = 0; i < restored.length; i++) {
      await prefs.setBool('kanta_activity_$i', restored[i]);
      await Hive.box('userProgress').put('magbasa_kanta_$i', restored[i]);
    }
    // The next launch.
    await loaded(UserProvider());
    for (int i = 0; i < restored.length; i++) {
      expect(prefs.getBool('kanta_activity_$i'), restored[i],
          reason: 'song $i');
    }
  });

  group('medals claimed offline', () {
    UserProfile profile({
      Map<String, int> tiers = const {},
      List<String> claimed = const [],
      List<String> certificates = const [],
    }) =>
        UserProfile.fromJson({
          'name': 'Ana',
          'gender': 'Female',
          'avatar': 'animal_bunny',
          'stars': 0,
          'achievements': tiers,
          'claimedBadges': claimed,
          'certificates': certificates,
        });

    test('stay when an older copy arrives from the cloud', () {
      final local = profile(
          tiers: {'numbers': 2, 'colors': 1},
          claimed: ['numbers', 'colors'],
          certificates: ['graduate']);
      final cloud = profile(tiers: {'numbers': 1}, claimed: ['numbers']);
      UserProvider.keepLocalClaims(cloud, local);
      expect(cloud.achievements, {'numbers': 2, 'colors': 1});
      expect(cloud.claimedBadges.toSet(), {'numbers', 'colors'});
      expect(cloud.certificates, ['graduate']);
    });

    test("never lower what the cloud already has", () {
      final local = profile(tiers: {'numbers': 1});
      final cloud = profile(tiers: {'numbers': 3, 'shapes': 1});
      UserProvider.keepLocalClaims(cloud, local);
      expect(cloud.achievements, {'numbers': 3, 'shapes': 1});
    });
  });

  group('an unchanged value is not written again', () {
    test('same lists and maps, however they are typed', () {
      expect(
          UserProvider.sameStoredValue(
              [true, false, 3], <dynamic>[true, false, 3]),
          isTrue);
      expect(
          UserProvider.sameStoredValue({
            'a': 1,
            'b': [true]
          }, <dynamic, dynamic>{
            'a': 1,
            'b': [true]
          }),
          isTrue);
    });

    test('a change is still a change', () {
      expect(
          UserProvider.sameStoredValue([true, false], [true, true]), isFalse);
      expect(UserProvider.sameStoredValue({'a': 1}, {'a': 2}), isFalse);
      expect(UserProvider.sameStoredValue(null, false), isFalse);
    });
  });
}

Future<UserProvider> loaded(UserProvider p) async {
  // It loads itself in the background; the cloud part fails in a test,
  // after the boxes and the profile are in.
  for (int i = 0; i < 1000 && p.userProfile == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return p;
}
