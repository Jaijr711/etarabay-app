import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profilePushFields', () {
    final fields = UserProvider.profilePushFields({
      'name': 'Old Name',
      'middleName': 'Old',
      'gender': 'Male',
      'birthday': '2021-01-01',
      'parentName': 'Old Parent',
      'parentContact': '09000000000',
      'avatar': 'boy1',
      'lrn': 'DC-2026-0001',
      'stars': 12,
      'achievements': {'a': 1},
      'certificates': ['c1'],
    });

    test("the phone's own fields go up, each on its own path", () {
      expect(fields[FieldPath(const ['profile', 'stars'])], 12);
      expect(fields[FieldPath(const ['profile', 'achievements'])], {'a': 1});
      expect(fields[FieldPath(const ['profile', 'certificates'])], ['c1']);
    });

    test("the teacher's fields stay as the server has them", () {
      for (final k in [
        'name',
        'middleName',
        'gender',
        'birthday',
        'parentName',
        'parentContact',
        'avatar',
        'lrn',
      ]) {
        expect(fields.containsKey(FieldPath(['profile', k])), isFalse,
            reason: k);
      }
      expect(fields.length, 3);
    });
  });

  group('starsAfterModuleReset', () {
    final record = {
      'profile': {'stars': 20},
      'progress': {
        'kulay': {'stars': 5},
        'matematika': {'earnedStars': 7, 'totalStars': 99},
      },
    };

    test('each reset module takes its own stars with it', () {
      expect(AuthService.starsAfterModuleReset(record, ['kulay', 'matematika']),
          8);
      expect(AuthService.starsAfterModuleReset(record, ['kulay']), 15);
    });

    test('a module with nothing recorded leaves the total', () {
      expect(AuthService.starsAfterModuleReset(record, ['pamilya']), 20);
      expect(AuthService.starsAfterModuleReset(null, ['kulay']), 0);
    });

    test('never below zero', () {
      expect(
          AuthService.starsAfterModuleReset({
            'profile': {'stars': 3},
            'progress': {
              'kulay': {'stars': 5}
            },
          }, [
            'kulay'
          ]),
          0);
    });
  });

  group('keptMiddleName', () {
    test('kept while the edited name still holds it', () {
      expect(AuthService.keptMiddleName('Santos', 'Ana Santos Cruz'),
          'Santos');
    });

    test('dropped once the teacher takes it out of the name', () {
      // Kept, the home screen showed "Ana S. Cruz" for "Ana Cruz".
      expect(AuthService.keptMiddleName('Santos', 'Ana Cruz'), '');
    });

    test('case does not matter', () {
      expect(AuthService.keptMiddleName('santos', 'ANA SANTOS CRUZ'),
          'santos');
    });

    test('no middle name stays none', () {
      expect(AuthService.keptMiddleName('', 'Ana Cruz'), '');
      expect(AuthService.keptMiddleName('  ', 'Ana Cruz'), '');
    });
  });

  group('usernameVariants', () {
    test('a capital first letter still finds the lowercase username', () {
      expect(AuthService.usernameVariants('Ana1234'), ['Ana1234', 'ana1234']);
    });

    test('lowercase as typed, and the capitalised spelling', () {
      expect(AuthService.usernameVariants('ana1234'), ['ana1234', 'Ana1234']);
    });

    test('all capitals covers both other spellings', () {
      expect(AuthService.usernameVariants('ANA'), ['ANA', 'ana', 'Ana']);
    });

    test('spaces around are trimmed, and nothing repeats', () {
      final v = AuthService.usernameVariants('  ana  ');
      expect(v, ['ana', 'Ana']);
      expect(v.toSet().length, v.length);
    });
  });
}
