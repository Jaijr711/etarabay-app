import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_tarabay/services/auth_service.dart';
import 'package:e_tarabay/services/parent_pin.dart';

/// One code for the parent, whichever of their children is signed in.
///
/// It was kept per child — `parent_pin_<studentId>` — so a parent with two
/// children had two codes, and taking one child off the device deleted the way
/// into the other one's report.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new device has no code', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(await ParentPin.isSet(prefs), isFalse);
    expect(await ParentPin.read(prefs), isNull);
  });

  test('a code that is set is the code that matches', () async {
    final prefs = await SharedPreferences.getInstance();
    await ParentPin.write(prefs, '4271');
    expect(await ParentPin.isSet(prefs), isTrue);
    expect(await ParentPin.matches(prefs, '4271'), isTrue);
    expect(await ParentPin.matches(prefs, '1234'), isFalse);
  });

  test('it is never stored in the clear', () async {
    final prefs = await SharedPreferences.getInstance();
    await ParentPin.write(prefs, '4271');
    expect(await ParentPin.read(prefs), isNot('4271'));
    expect(await ParentPin.read(prefs), AuthService.hashLrn('4271'));
  });

  test('an old per-child code is adopted, not lost', () async {
    // A parent who set a code under the old scheme must not be locked out or
    // asked to make a new one.
    SharedPreferences.setMockInitialValues(
        {'parent_pin_abc123': AuthService.hashLrn('4271')});
    final prefs = await SharedPreferences.getInstance();

    expect(await ParentPin.matches(prefs, '4271'), isTrue);
    expect(prefs.getString('parent_pin'), AuthService.hashLrn('4271'));
  });

  test('adopting clears the per-child copies', () async {
    // Two schemes that can disagree later is worse than either one.
    SharedPreferences.setMockInitialValues({
      'parent_pin_abc123': AuthService.hashLrn('4271'),
      'parent_pin_def456': AuthService.hashLrn('9999'),
    });
    final prefs = await SharedPreferences.getInstance();
    await ParentPin.read(prefs);

    expect(prefs.getString('parent_pin_abc123'), isNull);
    expect(prefs.getString('parent_pin_def456'), isNull);
  });

  test('the second child does not get asked for a new code', () async {
    // The whole point: one parent, one code, two children.
    final prefs = await SharedPreferences.getInstance();
    await ParentPin.write(prefs, '4271');

    // Signing a sibling in changes nothing about the parent's code.
    await prefs.setString('session_student_id', 'the-other-child');
    expect(await ParentPin.isSet(prefs), isTrue);
    expect(await ParentPin.matches(prefs, '4271'), isTrue);
  });
}
