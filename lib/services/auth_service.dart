import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Password/credential verification for both gated areas of the app: the
/// teacher dashboard and the hidden developer dashboard. Every password
/// this class ever touches is hashed with [hashLrn] before it reaches
/// Firestore — nothing here ever stores or transmits one in plaintext.
class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// The Firestore rules require *some* authenticated app instance —
  /// anonymous is fine — before they allow a read at all (see
  /// firestore.rules). main.dart already tries this once at startup, but
  /// silently: a slow or failed attempt there left the app permanently
  /// unauthenticated for the rest of the session, with nothing to say why.
  /// Called right before the read that actually needs it, so a login can
  /// retry the one thing it depends on instead of inheriting whatever
  /// happened to succeed or fail minutes earlier at launch — and, unlike
  /// main.dart's attempt, does not swallow the exception: a caller that
  /// wants to know why sign-in failed can.
  Future<void> ensureAuthenticated() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseAuth.instance
        .signInAnonymously()
        .timeout(const Duration(seconds: 15));
  }

  // Application "pepper" mixed into the LRN before hashing. The LRN (password)
  // is never stored in plaintext — only this one-way SHA-256 hash is saved,
  // so the raw password can't be read straight out of the database.
  static const String _lrnPepper = 'e_tarabay_v1_lrn_pepper';

  /// One-way hash of an LRN/password for storage and verification.
  static String hashLrn(String lrn) {
    final bytes = utf8.encode('$_lrnPepper:${lrn.trim()}');
    return sha256.convert(bytes).toString();
  }

  // ── Teacher credentials (config/teacher) ──────────────────────────────────

  /// Fetch the current teacher username from `config/teacher`.
  Future<String?> getTeacherUsername() async {
    try {
      final snap = await _db
          .collection('config')
          .doc('teacher')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 15));
      final u = (snap.data()?['username'] ?? '').toString();
      return u.isEmpty ? null : u;
    } catch (e) {
      debugPrint('getTeacherUsername error: $e');
      return null;
    }
  }

  /// Verify a teacher password against the hash stored in `config/teacher`.
  /// Uses serverAndCache so it works offline after the first online login.
  Future<bool> verifyTeacherPassword(String password) async {
    try {
      final snap = await _db
          .collection('config')
          .doc('teacher')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 15));
      final storedHash = (snap.data()?['passwordHash'] ?? '').toString();
      return storedHash.isNotEmpty && storedHash == hashLrn(password);
    } catch (e) {
      debugPrint('verifyTeacherPassword error: $e');
      return false;
    }
  }

  // ── Developer credentials (config/developer) ──────────────────────────────
  //
  // Same shape and same one-way hash as the teacher credential above, kept
  // separate so a teacher's password can never double as the developer
  // dashboard's key. There is no username: this is one hidden password,
  // not an account.

  /// Whether a developer password has ever been set. The dashboard's own
  /// entry screen uses this to tell "first time — choose a password" apart
  /// from "log in with the one already set".
  Future<bool> hasDeveloperPassword() async {
    try {
      final snap = await _db
          .collection('config')
          .doc('developer')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 15));
      return ((snap.data()?['passwordHash'] ?? '') as String).isNotEmpty;
    } catch (e) {
      debugPrint('hasDeveloperPassword error: $e');
      return false;
    }
  }

  /// Verify a developer password against the hash stored in
  /// `config/developer`. Uses serverAndCache so it still works offline once
  /// the hash has been read at least once.
  Future<bool> verifyDeveloperPassword(String password) async {
    try {
      final snap = await _db
          .collection('config')
          .doc('developer')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 15));
      final storedHash = (snap.data()?['passwordHash'] ?? '').toString();
      return storedHash.isNotEmpty && storedHash == hashLrn(password);
    } catch (e) {
      debugPrint('verifyDeveloperPassword error: $e');
      return false;
    }
  }

  /// Sets (or replaces) the developer password. Only ever reachable from
  /// the hidden developer entry point, which already requires the current
  /// password before it lets a child call this again — so this itself
  /// stays unconditional, the same as a teacher rotating their own password.
  Future<bool> setDeveloperPassword(String newPassword) async {
    try {
      await _db.collection('config').doc('developer').set(
        {'passwordHash': hashLrn(newPassword)},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('setDeveloperPassword error: $e');
      return false;
    }
  }

  /// Update the teacher's stored credentials. The password is written only as a
  /// one-way hash — plaintext never touches Firestore. Pass a new [username]
  /// and/or [newPassword] (omit/empty to leave a field unchanged).
  Future<Map<String, dynamic>> updateTeacherCredentials({
    String? username,
    String? newPassword,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null && username.trim().isNotEmpty) {
        updates['username'] = username.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        updates['passwordHash'] = hashLrn(newPassword);
      }
      if (updates.isEmpty) {
        return {
          'status': 'Error',
          'code': 'nothingToUpdate',
          'message': 'Nothing to update.'
        };
      }
      await _db
          .collection('config')
          .doc('teacher')
          .set(updates, SetOptions(merge: true));
      return {'status': 'Success'};
    } catch (e) {
      debugPrint('updateTeacherCredentials error: $e');
      return {
        'status': 'Error',
        'code': 'saveFailed',
        'message': 'Could not save changes. Please check your connection.',
      };
    }
  }

  /// Update a student's login credentials (parent-controlled). The password
  /// (LRN) is stored only as a hash. Username is optional and, when provided,
  /// checked for uniqueness so it stays a valid roster identity.
  /// The shortest password a parent may set.
  ///
  /// Deliberately not the DC-2026-0001 rule enrolment uses: the point of
  /// letting a parent change it is that they pick something they will not
  /// forget, and a formatted serial number is the thing they forgot.
  static const int minPasswordLength = 4;

  Future<Map<String, dynamic>> updateStudentCredentials({
    required String studentId,
    String? username,
    String? newPassword,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (newPassword != null &&
          newPassword.trim().isNotEmpty &&
          newPassword.trim().length < minPasswordLength) {
        return {
          'status': 'Error',
          'code': 'passwordTooShort',
          'message': 'The password is too short.',
        };
      }

      if (username != null && username.trim().isNotEmpty) {
        final uname = username.trim();
        final clash = await _db
            .collection('students')
            .where('username', isEqualTo: uname)
            .get();
        final takenByOther = clash.docs.any((d) => d.id != studentId);
        if (takenByOther) {
          return {
            'status': 'Error',
            'code': 'usernameTaken',
            'message': 'That username is already taken. Please pick another.',
          };
        }
        updates['username'] = uname;
      }

      if (newPassword != null && newPassword.trim().isNotEmpty) {
        updates['lrnHash'] = hashLrn(newPassword);
        // Kept in the clear so the teacher can read it back to a parent who
        // has forgotten it — that is the recovery route this app has.
        //
        // It used to be written into `lrn` as well, which meant a parent
        // changing their password renamed the child: the Student Number on
        // the teacher's roster became whatever the parent last typed.
        updates['password'] = newPassword.trim();
      }

      if (updates.isEmpty) {
        return {'status': 'Error', 'message': 'Nothing to update.'};
      }

      await _db.collection('students').doc(studentId).update(updates);
      return {'status': 'Success'};
    } catch (e) {
      debugPrint('updateStudentCredentials error: $e');
      return {
        'status': 'Error',
        'message': 'Could not save changes. Please check your connection.',
      };
    }
  }

  /// Verify a student's password (LRN) against the stored hash. Used by the
  /// parent portal before enabling biometric or changing credentials.
  Future<bool> verifyStudentPassword(String studentId, String password) async {
    try {
      final snap = await _db
          .collection('students')
          .doc(studentId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 15));
      final storedHash = (snap.data()?['lrnHash'] ?? '').toString();
      final legacyLrn = (snap.data()?['lrn'] ?? '').toString().trim();
      if (storedHash.isNotEmpty) return storedHash == hashLrn(password);
      return legacyLrn.isNotEmpty && legacyLrn == password.trim();
    } catch (e) {
      debugPrint('verifyStudentPassword error: $e');
      return false;
    }
  }

  /// Fetch a student's current username (for pre-filling parent forms / storing
  /// biometric credentials).
  Future<String?> getStudentUsername(String studentId) async {
    try {
      final snap = await _db
          .collection('students')
          .doc(studentId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 15));
      final u = (snap.data()?['username'] ?? '').toString();
      return u.isEmpty ? null : u;
    } catch (e) {
      debugPrint('getStudentUsername error: $e');
      return null;
    }
  }

  /// Login a student/parent using credentials enrolled by the teacher.
  /// Looks up `students` collection in Firestore.
  /// Matches username and LRN (password).
  Future<Map<String, dynamic>> loginStudent(
      String username, String password) async {
    try {
      await ensureAuthenticated();

      final query = _db
          .collection('students')
          .where('username', isEqualTo: username.trim());

      // Cache-first: returning students are already cached locally, so login
      // is instant with no spinner wait. Only fall back to the server when the
      // student isn't cached yet (e.g. first login on this device).
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      try {
        querySnapshot = await query.get(const GetOptions(source: Source.cache));
        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await query
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 15));
        }
      } catch (_) {
        querySnapshot = await query
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
      }

      if (querySnapshot.docs.isEmpty) {
        // Check if they are trying to login as teacher on student screen
        if (username.toLowerCase().trim() == 'daycare teacher') {
          return {
            'status': 'Error',
            'code': 'useTeacherButton',
            'message':
                'This is the Student Login. Please use the "Continue as Teacher" button at the bottom of the screen.',
          };
        }
        return {
          'status': 'Error',
          'code': 'usernameNotFound',
          'message':
              'This username does not exist. Please check your spelling or ask your teacher if you are enrolled.',
        };
      }

      final doc = querySnapshot.docs.first;
      final studentData = doc.data();
      final storedHash = (studentData['lrnHash'] ?? '').toString();
      final legacyLrn = (studentData['lrn'] ?? '').toString().trim();

      bool matches = false;
      if (storedHash.isNotEmpty) {
        // Preferred path: compare against the stored one-way hash.
        matches = storedHash == hashLrn(password);
      } else if (legacyLrn.isNotEmpty) {
        // Legacy records only hold a plaintext LRN — verify, then add the
        // hash. The plaintext is kept so the teacher can view the password.
        matches = legacyLrn == password.trim();
        if (matches) {
          try {
            await doc.reference.update({
              'lrnHash': hashLrn(password),
            });
          } catch (_) {}
        }
      }

      if (matches) {
        return {
          'status': 'Success',
          'studentId': doc.id,
          'studentData': studentData,
        };
      }

      return {
        'status': 'Error',
        'code': 'wrongStudentNumber',
        'message':
            'The Student Number (password) you entered is incorrect. Please try again.',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'status': 'Error',
        'code': 'connectionError',
        'message': 'A connection error occurred. Please check your internet.',
      };
    }
  }

  /// Validate password format for DC-2026-0001 structure.
  /// Format: DC-YYYY-XXXX (e.g., DC-2026-0001)
  /// Also detects repeated digits in suffix (e.g. DC-2026-0000, DC-2026-1111).
  /// Mints a student number that `validateDcPasswordFormat` will accept and
  /// that no one in [taken] already holds.
  ///
  /// Kept beside that validator on purpose. The generator used to live in the
  /// dashboard and could produce DC-2026-1111, which the validator here
  /// refuses; the teacher met the refusal on the final button of enrolment,
  /// worded as though they had typed the number themselves.
  ///
  /// The number is also the child's password, so a repeat hands two children
  /// each other's account.
  static String mintStudentNumber(Set<String> taken, {int? year}) {
    final y = year ?? DateTime.now().year;
    // Random where the sweep starts, so numbers do not run in sequence, then
    // a full pass. Drawing at random and giving up after so many tries can
    // report failure while free numbers remain.
    final start = Random().nextInt(9000);
    for (var step = 0; step < 9000; step++) {
      final id = 'DC-$y-${(start + step) % 9000 + 1000}';
      if (taken.contains(id)) continue;
      if (validateDcPasswordFormat(id)['isValid'] == true) return id;
    }
    // Every number in the year is spoken for. Returning one anyway would give
    // a second child someone's password, so say so instead.
    return '';
  }

  static Map<String, dynamic> validateDcPasswordFormat(String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      return {
        'isValid': false,
        'code': 'numberEmpty',
        'message': 'Password (Student Number) cannot be empty.'
      };
    }

    // Match DC-XXXX-XXXX format (e.g. DC-2026-0001)
    final regex = RegExp(r'^DC-\d{4}-\d{4}$', caseSensitive: false);
    if (!regex.hasMatch(trimmed)) {
      return {
        'isValid': false,
        'code': 'numberFormat',
        'message': 'Password must follow format: DC-2026-0001',
      };
    }

    // Extract trailing numeric portion
    final parts = trimmed.split('-');
    final numericPart = parts.last;

    // Check for identical repeated digits
    if (RegExp(r'^(\d)\1{3}$').hasMatch(numericPart)) {
      return {
        'isValid': false,
        'code': 'numberRepeated',
        'message':
            'Password cannot contain repeated digits (e.g., 0000, 1111).',
      };
    }

    return {'isValid': true, 'message': ''};
  }

  /// Enroll a student — called by the teacher.
  /// Adds a new student record to `students` collection.
  Future<Map<String, dynamic>> enrollStudent({
    required String name,
    String middleName = '',
    required String lrn,
    required String gender,
    required String username,
    DateTime? birthday,
    String parentName = '',
    String parentContact = '',
    String? avatar,
  }) async {
    try {
      // Check if Student Number already exists to prevent duplicates (compare hashes)
      final lrnHash = hashLrn(lrn);
      final existingCheck = await _db
          .collection('students')
          .where('lrnHash', isEqualTo: lrnHash)
          .get();

      if (existingCheck.docs.isNotEmpty) {
        return {
          'status': 'Error',
          'code': 'numberTaken',
          'message': 'A student with this Student Number is already enrolled.',
        };
      }

      // Check if username already exists
      final usernameCheck = await _db
          .collection('students')
          .where('username', isEqualTo: username.trim())
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return {
          'status': 'Error',
          'code': 'usernameTaken',
          'message': 'This username is already taken. Please try again.',
        };
      }

      // Create the student record in Firestore
      final docRef = _db.collection('students').doc();
      final studentData = {
        'name': name,
        'middleName': middleName.trim(),
        'lrnHash': lrnHash,
        // The temporary password the teacher hands over. The parent changes
        // it later; the number above stays put.
        'password': lrn.trim(),
        // Plaintext LRN kept so the teacher can view a student's login
        // password from the dashboard. Verification still uses lrnHash.
        'lrn': lrn.trim(),
        'gender': gender,
        'username': username.trim(),
        'birthday': birthday?.toIso8601String(),
        'parentName': parentName,
        'parentContact': parentContact,
        'avatar': avatar,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': {
          'overallProgress': 0.0,
          'totalCompleted': 0,
          'totalActivities': 100,
        },
        'profile': {
          'name': name,
          'middleName': middleName.trim(),
          'gender': gender,
          'birthday': birthday?.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'parentName': parentName,
          'parentContact': parentContact,
          'avatar': avatar,
          'stars': 0,
          'lessonsCompleted': 0,
          'achievements': {},
        }
      };

      await docRef.set(studentData);

      return {
        'status': 'Success',
        'studentId': docRef.id,
        'studentData': studentData,
      };
    } catch (e) {
      debugPrint('Enrollment error: $e');
      return {
        'status': 'Error',
        'code': 'enrollFailed',
        'message': 'Could not enroll student. Please check your connection.',
      };
    }
  }

  /// Get all enrolled students (for teacher dashboard).
  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentsStream() {
    return _db
        .collection('students')
        .orderBy('enrolledAt', descending: true)
        .snapshots();
  }

  /// Update student details (name, LRN).
  Future<void> updateStudent({
    required String studentId,
    required String name,
    String? middleName,
    required String lrn,
    String? gender,
    DateTime? birthday,
    String? parentName,
    String? parentContact,
    String? avatar,
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name,
      };

      if (middleName != null) {
        updates['middleName'] = middleName.trim();
      }

      // Only change the password hash when a new LRN is actually provided;
      // never overwrite it with an empty value. Keep the plaintext LRN so the
      // teacher can view the student's login password.
      if (lrn.trim().isNotEmpty) {
        updates['lrn'] = lrn.trim();
        // The password follows the number only while it is still the one
        // handed out at enrolment. Once a parent has chosen their own, a
        // teacher fixing a typo in the number must not silently lock them out.
        final doc = await _db.collection('students').doc(studentId).get();
        final data = doc.data();
        final current = (data?['password'] ?? data?['lrn'] ?? '').toString();
        final previous = (data?['lrn'] ?? '').toString();
        if (current.isEmpty || current == previous) {
          updates['lrnHash'] = hashLrn(lrn);
          updates['password'] = lrn.trim();
        }
      }

      final profileUpdates = <String, dynamic>{
        'profile.name': name,
      };
      if (middleName != null) {
        profileUpdates['profile.middleName'] = middleName.trim();
      }

      if (gender != null) {
        updates['gender'] = gender;
        profileUpdates['profile.gender'] = gender;
      }
      if (birthday != null) {
        updates['birthday'] = birthday.toIso8601String();
        profileUpdates['profile.birthday'] = birthday.toIso8601String();
      }
      if (parentName != null) {
        updates['parentName'] = parentName;
        profileUpdates['profile.parentName'] = parentName;
      }
      if (parentContact != null) {
        updates['parentContact'] = parentContact;
        profileUpdates['profile.parentContact'] = parentContact;
      }
      if (avatar != null) {
        updates['avatar'] = avatar;
        profileUpdates['profile.avatar'] = avatar;
      }

      await _db.collection('students').doc(studentId).update({
        ...updates,
        ...profileUpdates,
      });
    } catch (e) {
      debugPrint('Error updating student: $e');
    }
  }

  /// Delete a student record.
  Future<void> deleteStudent(String studentId) async {
    try {
      await _db.collection('students').doc(studentId).delete();
    } catch (e) {
      debugPrint('Error deleting student: $e');
    }
  }

  /// Delete all student records from Firestore.
  Future<Map<String, dynamic>> deleteAllStudents() async {
    try {
      final querySnapshot = await _db.collection('students').get();
      final docs = querySnapshot.docs;

      if (docs.isEmpty) {
        return {
          'status': 'Success',
          'code': 'noStudentsToDelete',
          'message': 'No students to delete.',
          'count': 0,
        };
      }

      // Firestore batches are limited to 500 operations
      const int batchLimit = 500;
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _db.batch();
        final end =
            (i + batchLimit < docs.length) ? i + batchLimit : docs.length;
        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }
        await batch.commit();
      }

      return {
        'status': 'Success',
        'code': 'allStudentsDeleted',
        'message': 'All students deleted.',
        'count': docs.length,
      };
    } catch (e) {
      debugPrint('Error deleting all students: $e');
      return {
        'status': 'Error',
        'code': 'deleteFailed',
        'message': 'Could not delete students. Please try again.',
      };
    }
  }

  /// Reset credentials for all existing students to DC-2026-XXXX format.
  Future<Map<String, dynamic>> resetAllStudentCredentialsToDcFormat() async {
    try {
      final querySnapshot = await _db.collection('students').get();
      final docs = querySnapshot.docs;

      if (docs.isEmpty) {
        return {
          'status': 'Success',
          'code': 'noStudentsToReset',
          'message': 'No students found to reset.',
          'updatedStudents': <Map<String, String>>[],
        };
      }

      final year = DateTime.now().year;
      final updatedList = <Map<String, String>>[];
      final usedIds = <String>{};

      const int batchLimit = 500;
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _db.batch();
        final end =
            (i + batchLimit < docs.length) ? i + batchLimit : docs.length;

        for (var j = i; j < end; j++) {
          final doc = docs[j];
          final name = (doc.data()['name'] ?? 'Student').toString();
          final username = (doc.data()['username'] ?? '').toString();

          // Generate unique DC-YYYY-XXXX ID
          String newId;
          do {
            final rand = (Random().nextInt(9000) + 1000).toString();
            newId = 'DC-$year-$rand';
          } while (usedIds.contains(newId));

          usedIds.add(newId);
          final newHash = hashLrn(newId);

          batch.update(doc.reference, {
            'lrn': newId,
            'lrnHash': newHash,
            // A reset takes the password back to the number, whatever the
            // parent had set. Leaving theirs would mean the new number the
            // teacher hands out does not open the app.
            'password': newId,
            'profile.lrn': newId,
          });

          updatedList.add({
            'name': name,
            'username': username,
            'studentId': newId,
          });
        }
        await batch.commit();
      }

      return {
        'status': 'Success',
        'code': 'resetDone',
        'message':
            'Successfully reset credentials for ${docs.length} students.',
        'updatedStudents': updatedList,
      };
    } catch (e) {
      debugPrint('Error resetting student credentials: $e');
      return {
        'status': 'Error',
        'code': 'resetFailed',
        'message': 'Failed to reset credentials. Please try again.',
      };
    }
  }

  /// Reset student activity progress
  Future<bool> resetStudentActivityProgress(String studentId) async {
    try {
      if (studentId.trim().isEmpty) {
        debugPrint(
            'CRITICAL ERROR: resetStudentActivityProgress called with empty studentId!');
        return false;
      }
      if (studentId.isNotEmpty) {
        await _db.collection('students').doc(studentId).update({
          'progress': {
            'overallProgress': 0.0,
            'totalCompleted': 0,
            'totalActivities': 145,
            'magbasa': {'totalCompleted': 0, 'totalActivities': 19},
            'kulay': {'totalCompleted': 0, 'totalActivities': 9},
            'traceit': {'totalCompleted': 0, 'totalActivities': 62},
            'matematika': {
              'gamesCompleted': 0,
              'totalGames': 31,
              'totalScore': 0
            },
            'pamilya': {'gamesCompleted': 0, 'totalGames': 25, 'totalScore': 0},
          },
          'rawProgress': {},
          'profile.stars': 0,
          'profile.lessonsCompleted': 0,
          'profile.achievements': {},
          // Cleared here as well as recomputed on the device: without this
          // the child's next sync pulls the old certificate back down before
          // the recompute has run.
          'profile.certificates': [],
          'profile.claimedBadges': [],
          'creations': [],
          'coloring_creations': [],
          'activities': {},
          'lastResetAt': FieldValue.serverTimestamp(),
          // What kind of reset this was. The child's device reads it to know
          // whether to clear everything or only the modules named — without
          // it, a one-module reset wiped their stars, badges and
          // certificates, none of which were reset in the cloud, so nothing
          // ever brought them back.
          'lastResetScope': 'all',
        });
      }
      // Only when this *is* the child's device.
      //
      // This ran wherever the button was pressed, which is normally the
      // teacher's phone — where it cleared whichever child happened to be
      // signed in and did nothing at all for the child being reset. The child
      // learns of the reset through `lastResetAt` on their own device; this
      // is only the shortcut for the case where they are the same phone.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('session_student_id') != studentId) return true;

      const keysToKeep = {
        'has_seen_onboarding',
        'notifications_enabled',
        'sound_enabled',
        'music_enabled',
        'session_student_id',
        'session_role',
        'language_code',
      };
      final allKeys = prefs.getKeys();
      for (final k in allKeys) {
        if (!keysToKeep.contains(k)) {
          if (k.startsWith('sundan_') ||
              k.startsWith('traceit_') ||
              k.startsWith('mat_') ||
              k.startsWith('matematika_') ||
              k.startsWith('pamilya_') ||
              k.startsWith('kulay_') ||
              k.startsWith('magbasa_') ||
              k.startsWith('tula_') ||
              k.startsWith('kwento_') ||
              k.startsWith('kanta_') ||
              k.startsWith('karaoke_') ||
              k.startsWith('tandaan_') ||
              k.startsWith('quiz_') ||
              k.startsWith('progress_') ||
              k.startsWith('level_') ||
              k.startsWith('game_') ||
              k.contains('_activity') ||
              k.contains('_completed') ||
              k.contains('_score') ||
              k.contains('_stars') ||
              k.contains('_attempts') ||
              k.contains('_creations')) {
            await prefs.remove(k);
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error resetting activity progress: $e');
      return false;
    }
  }

  /// Reset specific activity categories for a student
  Future<bool> resetStudentSpecificActivities(
      String studentId, List<String> categories) async {
    try {
      if (studentId.trim().isEmpty || categories.isEmpty) return false;

      final updates = <String, dynamic>{
        'lastResetAt': FieldValue.serverTimestamp(),
        // Exactly what the teacher chose, so the child's device clears these
        // and nothing else.
        'lastResetScope': categories.join(','),
      };

      for (final cat in categories) {
        switch (cat) {
          case 'matematika':
            updates['progress.matematika'] = {
              'gamesCompleted': 0,
              'totalGames': 31,
              'totalScore': 0
            };
            break;
          case 'pamilya':
            updates['progress.pamilya'] = {
              'gamesCompleted': 0,
              'totalGames': 25,
              'totalScore': 0
            };
            break;
          case 'magbasa':
            updates['progress.magbasa'] = {
              'totalCompleted': 0,
              'totalActivities': 23
            };
            break;
          case 'traceit':
            updates['progress.traceit'] = {
              'totalCompleted': 0,
              'totalActivities': 62
            };
            break;
          case 'kulay':
            updates['progress.kulay'] = {
              'totalCompleted': 0,
              'totalActivities': 9
            };
            updates['creations'] = [];
            updates['coloring_creations'] = [];
            break;
          case 'tandaan':
            updates['activities.tandaan'] = {};
            break;
        }
      }

      await _db.collection('students').doc(studentId).update(updates);

      // Local prefs cleanup, for the same reason as above: only if the
      // device pressing the button is the one the child plays on.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('session_student_id') != studentId) return true;
      final allKeys = prefs.getKeys();

      for (final k in allKeys) {
        bool shouldRemove = false;
        for (final cat in categories) {
          if (cat == 'matematika' &&
              (k.startsWith('mat_') || k.startsWith('matematika_'))) {
            shouldRemove = true;
          } else if (cat == 'pamilya' && k.startsWith('pamilya_')) {
            shouldRemove = true;
          } else if (cat == 'tandaan' && k.startsWith('tandaan_')) {
            shouldRemove = true;
          } else if (cat == 'traceit' &&
              (k.startsWith('sundan_') || k.startsWith('traceit_'))) {
            shouldRemove = true;
          } else if (cat == 'magbasa' &&
              (k.startsWith('magbasa_') ||
                  k.startsWith('tula_') ||
                  k.startsWith('kwento_') ||
                  k.startsWith('kanta_') ||
                  k.startsWith('karaoke_'))) {
            shouldRemove = true;
          } else if (cat == 'kulay' &&
              (k.startsWith('kulay_') || k.contains('_creations'))) {
            shouldRemove = true;
          }
        }
        if (shouldRemove) {
          await prefs.remove(k);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error resetting specific activities: $e');
      return false;
    }
  }
}
