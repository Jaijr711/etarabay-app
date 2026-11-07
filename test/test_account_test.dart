import 'dart:io';

import 'package:e_tarabay/data/badge_catalog.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/services/test_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The developer's "Tapusin lahat (pang-test)": the child's phone takes the
/// finished work in, and what is left is claiming — every badge, then the
/// certificate.
void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('test_account').path);
  });

  Future<UserProvider> freshChild() async {
    SharedPreferences.setMockInitialValues({});
    final profile = await Hive.openBox('userProfile');
    final progress = await Hive.openBox('userProgress');
    await profile.clear();
    await progress.clear();
    await profile.put('currentUser', {
      'name': 'Test Bata',
      'gender': 'Female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 11, 7).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 0,
    });
    final provider = UserProvider();
    // It loads itself in the background; the cloud part fails in a test,
    // after the boxes and the profile are in.
    for (int i = 0; i < 200 && provider.userProfile == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(provider.userProfile, isNotNull);
    return provider;
  }

  test('every key is one a module reset takes back', () {
    final prefixes = UserProvider.moduleKeyPrefixes.values.expand((p) => p);
    for (final key in TestAccount.fullProgress().keys) {
      expect(prefixes.any(key.startsWith), isTrue, reason: key);
      expect(key.contains('.'), isFalse, reason: key);
    }
  });

  test('every lesson finished, every star, every badge waiting to be claimed',
      () async {
    final child = await freshChild();
    await child.debugTakeCloudProgress(
        {'rawProgress': TestAccount.fullProgress()});

    expect(child.moduleCompletion.values, everyElement(isTrue),
        reason: '${child.moduleCompletion}');
    expect(child.recountStarsFromProgress(), UserProvider.totalPossibleStars);
    expect(child.userProfile!.stars, UserProvider.totalPossibleStars);

    final achievements = child.userProfile!.achievements;
    for (final id in UserProvider.graduateBadgeIds) {
      expect(badgeCatalog.any((b) => b.id == id), isTrue, reason: id);
      // At the top: a badge's last star is all its area had.
      expect(achievements[id], 3, reason: id);
    }
    expect(child.userProfile!.claimedBadges, isEmpty);
    expect(child.userProfile!.certificates, isEmpty);
  });

  test('claiming the twelve badges brings the certificate', () async {
    final child = await freshChild();
    await child.debugTakeCloudProgress(
        {'rawProgress': TestAccount.fullProgress()});
    for (final id in UserProvider.graduateBadgeIds) {
      await child.claimBadge(id);
    }
    expect(child.graduateBadgesClaimed, UserProvider.graduateBadgeIds.length);
    expect(child.userProfile!.certificates, isNotEmpty);
  });

  test('what the child had already done is kept, not lowered', () async {
    final child = await freshChild();
    await child.debugTakeCloudProgress({
      'rawProgress': {'mat_level_0_stars': 3, 'mat_level_0_score': 70}
    });
    await child.debugTakeCloudProgress(
        {'rawProgress': TestAccount.fullProgress()});
    expect(child.matematikaLevelScore(0), 70);
  });
}
