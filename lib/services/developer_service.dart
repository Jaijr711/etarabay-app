import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// The kinds of note a developer-dashboard message can be sent as — stored
/// alongside the text itself so a child (and AccountWatcher, which draws
/// the popup) can tell a friendly reminder from an urgent one at a glance,
/// the same way a real classroom notice board uses colour and an icon
/// before anyone reads a word of it.
class AdminMessageCategory {
  static const announcement = 'announcement';
  static const warning = 'warning';
  static const reminder = 'reminder';

  static const all = [announcement, warning, reminder];

  static IconData iconFor(String category) => switch (category) {
        warning => LucideIcons.triangle_alert,
        reminder => LucideIcons.bell,
        _ => LucideIcons.megaphone,
      };

  static Color colorFor(String category) => switch (category) {
        warning => const Color(0xFFE5484D),
        reminder => const Color(0xFF2C7BE5),
        _ => const Color(0xFF238636),
      };
}

/// Backs the hidden developer dashboard: a live list of every student
/// record, a way to drop a message onto one or all of them, a switch to
/// pause an account, a one-time kick, and the global module-lock switches.
/// Kept separate from [AuthService] — that file is the password gate this
/// screen sits behind; this one is what the screen does once it's in.
class DeveloperService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Every student record, live. The dashboard's own read of `lastActive`
  /// is what "online" is judged against — there is no separate presence
  /// system, just the same heartbeat every device already writes on every
  /// sync (see UserProvider._syncToFirebase).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllStudents() {
    return _db.collection('students').snapshots();
  }

  /// Drops a message on one student's own document. The signed-in device
  /// picks it up through the profile listener it already runs — no second
  /// stream needed on that side (see UserProvider._pendingAdminMessageId).
  ///
  /// [category] is one of the keys in [AdminMessageCategory.all] — it
  /// decides which icon and colour the child sees the message wrapped in,
  /// not just the words.
  Future<void> sendMessage(String studentId, String text,
      {String category = AdminMessageCategory.announcement}) {
    final id = _db.collection('students').doc().id; // a fresh id, unused as
    // a document path — just needs to be unique so the same text sent
    // twice is still shown twice.
    return _db.collection('students').doc(studentId).update({
      'adminMessage': {
        'id': id,
        'text': text,
        'category': category,
        'sentAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Same message, dropped on every student at once. One shared id, so
  /// every device's own per-student acknowledgement key treats it as the
  /// same message it is.
  Future<void> broadcastMessage(String text,
      {String category = AdminMessageCategory.announcement}) async {
    final snapshot = await _db.collection('students').get();
    if (snapshot.docs.isEmpty) return;
    final id = _db.collection('students').doc().id;
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'adminMessage': {
          'id': id,
          'text': text,
          'category': category,
          'sentAt': FieldValue.serverTimestamp(),
        },
      });
    }
    await batch.commit();
  }

  /// Pausing signs the student out on their own next snapshot (see
  /// AccountWatcher) — it does not touch anything already saved, so
  /// un-pausing (disabled: false) picks up exactly where they left off.
  Future<void> setDisabled(String studentId, bool disabled) {
    return _db
        .collection('students')
        .doc(studentId)
        .update({'disabledByDev': disabled});
  }

  /// A one-time kick: signs the student out on their next snapshot, same as
  /// [setDisabled], but never sets `disabledByDev` — they can log straight
  /// back in. Useful for a stuck session rather than a real ban.
  Future<void> forceLogout(String studentId) {
    return _db.collection('students').doc(studentId).update({
      'forceLogoutAt': FieldValue.serverTimestamp(),
    });
  }

  /// The shared developer config doc — currently just the password hash
  /// (see AuthService) and the global module-lock list below.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConfig() {
    return _db.collection('config').doc('developer').snapshots();
  }

  /// Locks or unlocks one module app-wide, for every student. Kept as one
  /// array on the shared config doc rather than per-student — a locked
  /// module is a maintenance switch, not something one child is singled
  /// out for.
  Future<void> setModuleLocked(String moduleKey, bool locked) {
    return _db.collection('config').doc('developer').set(
      {
        'lockedModules': locked
            ? FieldValue.arrayUnion([moduleKey])
            : FieldValue.arrayRemove([moduleKey]),
      },
      SetOptions(merge: true),
    );
  }
}
