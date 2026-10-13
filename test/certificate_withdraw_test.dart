import 'package:flutter_test/flutter_test.dart';

/// A certificate says what is true now, not the best it ever was.
///
/// `checkAndAwardCertificates` only ever added. The badges beside it already
/// step down and disappear when the progress behind them drops — so a teacher
/// resetting a child to zero saw the twelve gold badges vanish correctly and
/// "E-Tarabay Graduate" stay on a profile with no progress at all.
///
/// Mirrors the rule in the provider, which needs Hive and Firebase to run.
/// Two things about that rule are easy to get wrong from memory, so they are
/// written out here:
///
///   * The bar is **claimed**, not three stars. Any tier counts once the
///     child has tapped "claim", the same bar every individual badge uses.
///   * Twelve badges are not enough on their own. Every lesson has to be
///     finished too — played to the end, which is what the Lessons screen
///     means by "Tapos na!", not every star won.
Set<String> settleCertificates({
  required Set<String> claimedBadges,
  required Map<String, bool> moduleCompletion,
  required Set<String> held,
}) {
  const badgeIds = [
    'firstSteps', 'alphabet', 'numbers', 'colors', 'shapes', 'animals',
    'bookworm', 'starStudent', 'mathWhiz', 'familyHero', 'writingStar',
    'songbird',
  ];
  final allBadges = badgeIds.every(claimedBadges.contains);
  final allModules = moduleCompletion.values.every((done) => done);

  final out = Set<String>.from(held);
  if (allBadges && allModules) {
    out.add('e_tarabay_graduate');
  } else {
    out.remove('e_tarabay_graduate');
  }
  return out;
}

/// The six modules on the Lessons screen.
const _modules = [
  'matematika',
  'pamilya',
  'kulay',
  'traceit',
  'magbasa',
  'tandaan',
];

Set<String> _allClaimed() => {
      'firstSteps', 'alphabet', 'numbers', 'colors', 'shapes', 'animals',
      'bookworm', 'starStudent', 'mathWhiz', 'familyHero', 'writingStar',
      'songbird',
    };

Map<String, bool> _allModulesDone() => {for (final m in _modules) m: true};

void main() {
  group('the certificate follows the work', () {
    test('every badge claimed and every lesson finished earns it', () {
      expect(
        settleCertificates(
          claimedBadges: _allClaimed(),
          moduleCompletion: _allModulesDone(),
          held: {},
        ),
        contains('e_tarabay_graduate'),
      );
    });

    test('a reset to nothing takes it back', () {
      // The reported bug: reset the child, badges go, certificate stays.
      expect(
        settleCertificates(
          claimedBadges: {},
          moduleCompletion: {for (final m in _modules) m: false},
          held: {'e_tarabay_graduate'},
        ),
        isEmpty,
      );
    });

    test('one badge un-claimed takes it back', () {
      // Replaying a level weakly steps a medal down, and stepping down
      // un-claims it — the certificate claims all twelve are held.
      final almost = _allClaimed()..remove('songbird');
      expect(
        settleCertificates(
          claimedBadges: almost,
          moduleCompletion: _allModulesDone(),
          held: {'e_tarabay_graduate'},
        ),
        isEmpty,
      );
    });

    test('eleven of twelve is not a graduate', () {
      final missing = _allClaimed()..remove('mathWhiz');
      expect(
        settleCertificates(
          claimedBadges: missing,
          moduleCompletion: _allModulesDone(),
          held: {},
        ),
        isEmpty,
      );
    });

    test('holding it while it is still true changes nothing', () {
      expect(
        settleCertificates(
          claimedBadges: _allClaimed(),
          moduleCompletion: _allModulesDone(),
          held: {'e_tarabay_graduate'},
        ),
        {'e_tarabay_graduate'},
      );
    });
  });

  group('the lessons half of the rule', () {
    test('twelve badges with a lesson still open is not enough', () {
      // The whole point of the second condition: a child can hold all twelve
      // badges — each of which only needs a third of its area — while a
      // module sits unopened.
      final oneOpen = _allModulesDone()..['tandaan'] = false;
      expect(
        settleCertificates(
          claimedBadges: _allClaimed(),
          moduleCompletion: oneOpen,
          held: {},
        ),
        isEmpty,
      );
    });

    test('a lesson re-opening takes an already-held certificate back', () {
      final oneOpen = _allModulesDone()..['traceit'] = false;
      expect(
        settleCertificates(
          claimedBadges: _allClaimed(),
          moduleCompletion: oneOpen,
          held: {'e_tarabay_graduate'},
        ),
        isEmpty,
      );
    });

    test('every lesson finished but a badge unclaimed is not enough', () {
      expect(
        settleCertificates(
          claimedBadges: _allClaimed()..remove('firstSteps'),
          moduleCompletion: _allModulesDone(),
          held: {},
        ),
        isEmpty,
      );
    });
  });
}
