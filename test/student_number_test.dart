import 'package:flutter_test/flutter_test.dart';
import 'package:e_tarabay/services/auth_service.dart';

/// The generator and the rule that judges it have to agree.
///
/// They did not. The dashboard minted `DC-YYYY-NNNN` from a plain random draw
/// and `validateDcPasswordFormat` refuses four identical digits, so roughly
/// one enrolment in a thousand died on the final button. Nothing checked the
/// number was free either, and the number is also the child's password.
void main() {
  group('mintStudentNumber', () {
    test('never mints a number its own validator refuses', () {
      // 1111 … 9999 are 9 of the 9,000 draws; at 4,000 mints the chance of
      // this passing by luck alone is about one in fifty.
      for (var i = 0; i < 4000; i++) {
        final id = AuthService.mintStudentNumber(<String>{}, year: 2026);
        expect(AuthService.validateDcPasswordFormat(id)['isValid'], isTrue,
            reason: 'minted $id, which the validator refuses');
      }
    });

    test('never mints a number already held', () {
      // Every number but one is taken, so there is exactly one right answer.
      final taken = <String>{
        for (var n = 1000; n <= 9999; n++)
          if (n != 4271) 'DC-2026-$n'
      };
      for (var i = 0; i < 20; i++) {
        expect(AuthService.mintStudentNumber(taken, year: 2026),
            'DC-2026-4271');
      }
    });

    test('mints in the year asked for', () {
      expect(AuthService.mintStudentNumber(<String>{}, year: 2031),
          startsWith('DC-2031-'));
    });

    test('gives a distinct number to each child in a full class', () {
      // Thirty children, minted one after another as a teacher would. With no
      // taken-set the birthday paradox put a clash at roughly one class in
      // twenty.
      final issued = <String>{};
      for (var i = 0; i < 30; i++) {
        issued.add(AuthService.mintStudentNumber(issued, year: 2026));
      }
      expect(issued.length, 30);
    });
  });
}
