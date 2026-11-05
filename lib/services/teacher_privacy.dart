import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The teacher's privacy agreement: the promise to keep the children's
/// details to themselves, agreed once on each phone the teacher uses.
///
/// Kept on the phone so the dashboard opens offline once it has been agreed
/// to, and copied to `config/teacher` so the school has a record of who
/// agreed and when. Raising [policyVersion] asks every teacher again.
class TeacherPrivacy {
  TeacherPrivacy._();

  static const int policyVersion = 1;

  static const _agreedKey = 'teacher_privacy_agreed_v$policyVersion';
  static const _nameKey = 'teacher_privacy_name';
  static const _dateKey = 'teacher_privacy_date';

  /// Whether this phone's teacher has agreed to the current version.
  static Future<bool> hasAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_agreedKey) ?? false;
  }

  /// Who agreed on this phone and when, or null if nobody has yet.
  static Future<({String name, DateTime date})?> agreement() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_agreedKey) ?? false)) return null;
    final date = DateTime.tryParse(prefs.getString(_dateKey) ?? '');
    if (date == null) return null;
    return (name: prefs.getString(_nameKey) ?? '', date: date);
  }

  /// Records the agreement on this phone, then in the cloud. The cloud copy
  /// is queued when offline, and never holds the dashboard up.
  static Future<void> record(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool(_agreedKey, true);
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_dateKey, now.toIso8601String());
    try {
      await FirebaseFirestore.instance.collection('config').doc('teacher').set({
        'privacyAgreement': {
          'name': name.trim(),
          'version': policyVersion,
          'agreedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Firestore keeps the write and sends it once back online.
      debugPrint('Privacy agreement saved on this phone only for now: $e');
    }
  }
}
