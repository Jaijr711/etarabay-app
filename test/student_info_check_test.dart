import 'package:e_tarabay/utils/student_info_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 15);

  Map<StudentField, StudentFieldProblem> child({
    String first = 'Juan',
    String last = 'Dela Cruz',
    String middle = '',
    String? gender = 'Male',
    DateTime? birthday,
    bool noBirthday = false,
  }) =>
      StudentInfoCheck.child(
        firstName: first,
        lastName: last,
        middleName: middle,
        gender: gender,
        birthday: noBirthday ? null : (birthday ?? DateTime(2022, 3, 1)),
        today: today,
      );

  test('a complete child passes', () {
    expect(child(), isEmpty);
    expect(child(first: 'Ma. Cristina', last: "D'Angelo-Santos", middle: 'Peña'),
        isEmpty);
  });

  test('no birthday is missing', () {
    expect(child(noBirthday: true),
        {StudentField.birthday: StudentFieldProblem.missing});
  });

  test('an age outside 2 to 7 is a typing mistake', () {
    expect(child(birthday: DateTime(2025, 1, 1)),
        {StudentField.birthday: StudentFieldProblem.invalid}); // 1 year old
    expect(child(birthday: DateTime(2017, 1, 1)),
        {StudentField.birthday: StudentFieldProblem.invalid}); // 9 years old
    expect(child(birthday: DateTime(2024, 11, 15)), isEmpty); // 2 today
    expect(child(birthday: DateTime(2018, 11, 16)), isEmpty); // 7, not yet 8
  });

  test('a gender nobody chose is missing', () {
    expect(child(gender: null),
        {StudentField.gender: StudentFieldProblem.missing});
  });

  test('names need letters, at least two', () {
    expect(child(first: 'a')[StudentField.firstName],
        StudentFieldProblem.invalid);
    expect(child(first: 'J0hn')[StudentField.firstName],
        StudentFieldProblem.invalid);
    expect(child(last: '')[StudentField.lastName], StudentFieldProblem.missing);
    // The middle name may be left out, but not filled with junk.
    expect(child(middle: '')[StudentField.middleName], isNull);
    expect(child(middle: '1')[StudentField.middleName],
        StudentFieldProblem.invalid);
  });

  test('the parent needs a name and an 09 number', () {
    expect(
        StudentInfoCheck.parent(
            parentName: 'Maria Santos', parentContact: '09171234567'),
        isEmpty);
    expect(
        StudentInfoCheck.parent(parentName: '', parentContact: '08123456789'),
        {
          StudentField.parentName: StudentFieldProblem.missing,
          StudentField.parentContact: StudentFieldProblem.invalid,
        });
    expect(
        StudentInfoCheck.parent(
            parentName: 'Maria', parentContact: '0917123')[StudentField.parentContact],
        StudentFieldProblem.invalid);
  });

  test('a saved record says what it lacks', () {
    expect(
        StudentInfoCheck.missingInRecord({
          'birthday': null,
          'gender': 'Female',
          'parentName': 'Maria',
          'parentContact': '09171234567',
        }),
        [StudentField.birthday]);
    expect(
        StudentInfoCheck.missingInRecord({
          'birthday': '2022-03-01T00:00:00.000',
          'gender': 'Male',
          'parentName': 'Maria',
          'parentContact': '09171234567',
        }),
        isEmpty);
  });
}
