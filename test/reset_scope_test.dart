import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a teacher's reset is allowed to take.
///
/// Two faults sat in here and neither announced itself — a reset either looks
/// like it worked, or looks like the child simply had less than you thought.
///
///   * One marker key was shared by every child on the phone. Child A's reset
///     marker was still in the slot when child B signed in, B's own marker did
///     not match it, and B's progress was wiped for a reset that was never
///     theirs. Switching back wiped A for the same reason, and it never
///     settled: on a phone with two children they erased each other on every
///     switch. Nothing cleared the key either — it matches none of the
///     progress prefixes — so it survived account switches and full wipes.
///
///   * A reset of one module ran the *whole* local wipe, which zeroes stars,
///     badges and certificates. None of those were reset in the cloud, so
///     nothing brought them back. A teacher clearing Matematika took the
///     child's certificate with it.
void main() {
  group('one marker per child', () {
    test('two children on one phone do not share a slot', () {
      expect(UserProvider.appliedResetKeyFor('child-a'),
          isNot(UserProvider.appliedResetKeyFor('child-b')));
    });

    test('the same child always gets the same slot', () {
      expect(UserProvider.appliedResetKeyFor('child-a'),
          UserProvider.appliedResetKeyFor('child-a'));
    });

    test('the id is in the key, not just appended to a shared name', () {
      // A key that ignored its argument would pass the first test only by
      // accident; this one fails outright.
      expect(UserProvider.appliedResetKeyFor('child-a'), contains('child-a'));
    });

    test('a signed-out device still has a usable key', () {
      expect(UserProvider.appliedResetKeyFor(null), isNotEmpty);
    });
  });

  group('every resettable module knows where its progress lives', () {
    // The six the teacher is offered in the reset dialog. A module added to
    // that list without an entry here would clear nothing at all, silently:
    // the teacher would see the confirmation and the child would keep every
    // star.
    const offered = [
      'matematika',
      'pamilya',
      'traceit',
      'magbasa',
      'tandaan',
      'kulay',
    ];

    test('the table covers exactly what the teacher can choose', () {
      expect(UserProvider.moduleKeyPrefixes.keys.toSet(), offered.toSet());
    });

    test('none of them resolves to an empty list', () {
      for (final module in offered) {
        expect(UserProvider.moduleKeyPrefixes[module], isNotEmpty,
            reason: '$module would clear nothing');
      }
    });

    test('a prefix belongs to one module only', () {
      // Overlapping prefixes would make one reset take another module's work.
      final seen = <String, String>{};
      UserProvider.moduleKeyPrefixes.forEach((module, prefixes) {
        for (final p in prefixes) {
          expect(seen.containsKey(p), isFalse,
              reason: '"$p" is claimed by both ${seen[p]} and $module');
          seen[p] = module;
        }
      });
    });

    test('every prefix ends with the separator', () {
      // "mat" without the underscore would also match "matematika_", and
      // worse, any future key that merely starts with those letters.
      for (final prefixes in UserProvider.moduleKeyPrefixes.values) {
        for (final p in prefixes) {
          expect(p.endsWith('_'), isTrue, reason: '"$p" is not a prefix');
        }
      }
    });
  });
}
