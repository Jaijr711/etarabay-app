import 'package:flutter_test/flutter_test.dart';
import 'package:e_tarabay/services/auth_service.dart';

/// The Student Number identifies the child. The password opens the app.
///
/// They used to be one field, so a parent changing their password renamed the
/// child: the number on the teacher's roster became whatever the parent last
/// typed, and the format rule enrolment enforces was bypassed entirely.
void main() {
  group('the two are not the same thing', () {
    test('a parent may choose a password the Student Number rule refuses', () {
      // This is the point of letting them change it. The number keeps its
      // shape; the password does not have to.
      const chosen = 'bahaykubo';
      expect(AuthService.validateDcPasswordFormat(chosen)['isValid'], isFalse);
      expect(chosen.length,
          greaterThanOrEqualTo(AuthService.minPasswordLength));
    });

    test('a Student Number still has to look like one', () {
      expect(AuthService.validateDcPasswordFormat('bahaykubo')['code'],
          'numberFormat');
      expect(AuthService.validateDcPasswordFormat('DC-2026-4271')['isValid'],
          isTrue);
    });

    test('four characters is the floor for a password', () {
      // Short enough to be memorable, long enough not to be guessed by the
      // child's classmate looking over their shoulder.
      expect(AuthService.minPasswordLength, 4);
    });
  });
}
