/// What a child's record still lacks before it can be saved.
///
/// One rule for every place a teacher fills a child in: the enrol sheet, the
/// edit sheet, and the roster's "info incomplete" mark. Enrolment used to ask
/// for a first and a last name only, so a child could be saved with no
/// birthday, a gender nobody chose (it defaulted to boy), or "a" for a name.
library;

enum StudentField {
  firstName,
  lastName,
  middleName,
  gender,
  birthday,
  parentName,
  parentContact,
}

/// Why a field is not good yet: empty, or filled but wrong.
enum StudentFieldProblem { missing, invalid }

class StudentInfoCheck {
  StudentInfoCheck._();

  /// Youngest and oldest a daycare child can plausibly be. Outside this, the
  /// year was most likely mistyped (this year's date, a parent's birthday).
  static const int minAge = 2;
  static const int maxAge = 7;

  // Letters of any language (ñ, accents), with the spaces, hyphens, periods
  // and apostrophes real names carry: "Ma. Cristina", "Dela Cruz-Santos",
  // "D'Angelo". At least two letters in all.
  static final RegExp _nameChars = RegExp(r"^[\p{L}][\p{L}\s.'\-]*$", unicode: true);
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  static bool validName(String name) {
    final s = name.trim();
    return _nameChars.hasMatch(s) && _letter.allMatches(s).length >= 2;
  }

  /// Philippine mobile: 11 digits starting 09.
  static bool validContact(String contact) =>
      RegExp(r'^09\d{9}$').hasMatch(contact.trim());

  /// Whole years old on [today].
  static int ageOn(DateTime birthday, DateTime today) {
    var age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// The child's own details (the first step of enrolment).
  static Map<StudentField, StudentFieldProblem> child({
    required String firstName,
    required String lastName,
    String middleName = '',
    required String? gender,
    required DateTime? birthday,
    DateTime? today,
  }) {
    final out = <StudentField, StudentFieldProblem>{};
    void name(StudentField f, String v, {bool optional = false}) {
      if (v.trim().isEmpty) {
        if (!optional) out[f] = StudentFieldProblem.missing;
      } else if (!validName(v)) {
        out[f] = StudentFieldProblem.invalid;
      }
    }

    name(StudentField.firstName, firstName);
    name(StudentField.middleName, middleName, optional: true);
    name(StudentField.lastName, lastName);
    if (gender == null || gender.trim().isEmpty) {
      out[StudentField.gender] = StudentFieldProblem.missing;
    }
    if (birthday == null) {
      out[StudentField.birthday] = StudentFieldProblem.missing;
    } else {
      final age = ageOn(birthday, today ?? DateTime.now());
      if (age < minAge || age > maxAge) {
        out[StudentField.birthday] = StudentFieldProblem.invalid;
      }
    }
    return out;
  }

  /// The parent's details (the second step).
  static Map<StudentField, StudentFieldProblem> parent({
    required String parentName,
    required String parentContact,
  }) {
    final out = <StudentField, StudentFieldProblem>{};
    if (parentName.trim().isEmpty) {
      out[StudentField.parentName] = StudentFieldProblem.missing;
    } else if (!validName(parentName)) {
      out[StudentField.parentName] = StudentFieldProblem.invalid;
    }
    if (parentContact.trim().isEmpty) {
      out[StudentField.parentContact] = StudentFieldProblem.missing;
    } else if (!validContact(parentContact)) {
      out[StudentField.parentContact] = StudentFieldProblem.invalid;
    }
    return out;
  }

  /// What a saved record lacks, for the roster's mark. Only what is missing:
  /// the age range is a typing check, not grounds to flag a child enrolled
  /// years ago who has since grown past it.
  static List<StudentField> missingInRecord(Map<String, dynamic> data) {
    // Older records kept some of these under 'profile'.
    final profile = data['profile'] is Map ? data['profile'] as Map : const {};
    String read(String key) =>
        (data[key] ?? profile[key] ?? '').toString().trim();
    final out = <StudentField>[];
    if (DateTime.tryParse(read('birthday')) == null) {
      out.add(StudentField.birthday);
    }
    if (read('gender').isEmpty) out.add(StudentField.gender);
    if (read('parentName').isEmpty) out.add(StudentField.parentName);
    if (read('parentContact').isEmpty) out.add(StudentField.parentContact);
    return out;
  }
}
