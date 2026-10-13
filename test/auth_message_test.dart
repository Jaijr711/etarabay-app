import 'package:flutter_test/flutter_test.dart';
import 'package:e_tarabay/services/auth_service.dart';

/// Every result this service returns has to carry a code.
///
/// Without one the screens fall back to the English sentence, which is what
/// the whole change was for: a fully translated app that said "Password must
/// follow format: DC-2026-0001" to a teacher working in Filipino.
void main() {
  group('validateDcPasswordFormat codes', () {
    test('an empty number is named, not described', () {
      final r = AuthService.validateDcPasswordFormat('');
      expect(r['isValid'], isFalse);
      expect(r['code'], 'numberEmpty');
    });

    test('a badly shaped number is named', () {
      final r = AuthService.validateDcPasswordFormat('123456789012');
      expect(r['isValid'], isFalse);
      expect(r['code'], 'numberFormat');
    });

    test('four identical digits are named separately', () {
      // Its own code because it is its own fix: the teacher has to change the
      // digits, not the shape.
      final r = AuthService.validateDcPasswordFormat('DC-2026-1111');
      expect(r['isValid'], isFalse);
      expect(r['code'], 'numberRepeated');
    });

    test('a good number carries no complaint', () {
      final r = AuthService.validateDcPasswordFormat('DC-2026-4271');
      expect(r['isValid'], isTrue);
      expect(r['code'], isNull);
    });

    test('every number the minter hands out is accepted', () {
      // The generator and this validator used to disagree; they live beside
      // each other now so they cannot drift apart unnoticed.
      for (var i = 0; i < 500; i++) {
        final id = AuthService.mintStudentNumber(<String>{}, year: 2026);
        expect(AuthService.validateDcPasswordFormat(id)['code'], isNull);
      }
    });
  });
}
