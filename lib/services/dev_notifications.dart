import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'reminder_service.dart';
import 'update_checker.dart';

/// What lands in the phone's notification bar without anyone opening the
/// app: a notification the developer sent, to this child or to the
/// teachers, and word of a new version.
///
/// There is no server to push them. The phone asks instead — every 15
/// minutes or so in the background (Android's floor), and whenever the app
/// opens — so a notification arrives within about 15–30 minutes, at once
/// when the app is open.
///
/// The asking is kept apart from Firestore, the plugin and the clock, so it
/// can be checked without any of them (see [DevNotifications.new]).
class DevNotifications {
  DevNotifications({
    required this.prefs,
    required this.readChild,
    required this.readTeacher,
    required this.newerVersion,
    required this.show,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SharedPreferences prefs;

  /// The child's record, from the server; null when it is not there.
  final Future<Map<String, dynamic>?> Function(String studentId) readChild;

  /// `config/notifications`, from the server.
  final Future<Map<String, dynamic>?> Function() readTeacher;

  /// A version newer than this one, or null when this one is current.
  final Future<String?> Function() newerVersion;

  final Future<void> Function(int id, String title, String body,
      {required bool update}) show;

  final DateTime Function() _now;

  static const int childId = 2001;
  static const int teacherId = 2002;
  static const int updateId = 2003;

  /// Older than this, a notification is not shown: a phone signing in today
  /// should not be handed last week's.
  static const Duration maxAge = Duration(days: 2);

  /// GitHub allows 60 unsigned asks an hour from one address, and a
  /// school's phones share one.
  static const Duration updateEvery = Duration(hours: 6);

  /// Looks once for each kind. Never throws: a failure is the same as
  /// nothing new, and is tried again next time.
  Future<void> run() async {
    // The background and the app are two isolates with a cache each.
    await prefs.reload();
    final role = prefs.getString('session_role');
    final childOn = prefs.getBool('notifications_enabled') ?? false;

    if (role == 'student' && childOn) {
      final id = prefs.getString('session_student_id');
      if (id != null && id.isNotEmpty) {
        await _devNotif('child_$id', childId,
            () async => (await readChild(id))?['devNotif']);
      }
    } else if (role == 'teacher') {
      await _devNotif(
          'teacher', teacherId, () async => (await readTeacher())?['teacher']);
    }

    // A child's parents turned notifications off: nothing, this included.
    if (role != 'student' || childOn) await _update();
  }

  Future<void> _devNotif(
      String target, int notifId, Future<Object?> Function() read) async {
    final Object? raw;
    try {
      raw = await read();
    } catch (e) {
      debugPrint('DevNotifications($target): $e');
      return;
    }
    if (raw is! Map) return;
    final id = '${raw['id'] ?? ''}';
    final body = '${raw['body'] ?? ''}'.trim();
    if (id.isEmpty || body.isEmpty) return;
    final seenKey = 'dev_notif_seen_$target';
    if (prefs.getString(seenKey) == id) return;
    final sent = raw['sentAt'];
    final at = sent is Timestamp ? sent.toDate() : null;
    // Not yet stamped by the server, or too old: marked, never shown.
    if (at == null || _now().difference(at) > maxAge) {
      if (at != null) await prefs.setString(seenKey, id);
      return;
    }
    final title = '${raw['title'] ?? ''}'.trim();
    await show(notifId, title.isEmpty ? 'E-Tarabay' : title, body,
        update: false);
    await prefs.setString(seenKey, id);
  }

  Future<void> _update() async {
    final last = prefs.getInt('update_notif_checked_at');
    final now = _now();
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            updateEvery) {
      return;
    }
    final String? version;
    try {
      version = await newerVersion();
    } catch (e) {
      debugPrint('DevNotifications(update): $e');
      return;
    }
    await prefs.setInt('update_notif_checked_at', now.millisecondsSinceEpoch);
    if (version == null) return;
    final shownKey = 'update_notif_shown_$version';
    if (prefs.getBool(shownKey) == true) return;
    final (title, body) =
        updateText(prefs.getString('language') ?? 'en', version);
    await show(updateId, title, body, update: true);
    await prefs.setBool(shownKey, true);
  }

  static (String, String) updateText(String language, String version) =>
      switch (language) {
        'fil' => (
            'May bagong E-Tarabay!',
            'Bersyon $version — pindutin para i-update.'
          ),
        'ilo' => (
            'Adda baro nga E-Tarabay!',
            'Bersion $version — pindutem tapno ma-update.'
          ),
        _ => ('A new E-Tarabay is out!', 'Version $version — tap to update.'),
      };

  // ── On the phone ────────────────────────────────────────────────────────

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// One look, now, with the real Firestore and plugin. Firebase must be
  /// up already. In the app it waits for the app's own sign-in rather than
  /// race it with a second one; in the background it signs in itself.
  static Future<void> runNow({bool inBackground = false}) async {
    if (!_supported) return;
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        if (inBackground) {
          await auth.signInAnonymously().timeout(const Duration(seconds: 15));
        } else {
          await auth
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 20));
        }
      }
      final db = FirebaseFirestore.instance;
      Future<Map<String, dynamic>?> server(
              DocumentReference<Map<String, dynamic>> doc) async =>
          (await doc
                  .get(const GetOptions(source: Source.server))
                  .timeout(const Duration(seconds: 12)))
              .data();
      await DevNotifications(
        prefs: await SharedPreferences.getInstance(),
        readChild: (id) => server(db.collection('students').doc(id)),
        readTeacher: () => server(db.collection('config').doc('notifications')),
        newerVersion: () async =>
            (await UpdateChecker.instance.checkForUpdate())?.versionName,
        show: (id, title, body, {required update}) =>
            ReminderService.instance.showNow(id, title, body, update: update),
      ).run();
    } catch (e) {
      debugPrint('DevNotifications.runNow: $e');
    }
  }

  /// Has the phone ask every 15 minutes, with the app closed too. Once is
  /// enough for good; a second call keeps the first.
  static Future<void> register() async {
    if (!_supported) return;
    try {
      await Workmanager().initialize(devNotificationsDispatcher);
      await Workmanager().registerPeriodicTask(
        'etarabay-notifications',
        'check',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('DevNotifications.register: $e');
    }
  }
}

/// Where the background look starts: its own isolate, with nothing of the
/// app's running, so Firebase is brought up here.
@pragma('vm:entry-point')
void devNotificationsDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      await DevNotifications.runNow(inBackground: true);
    } catch (e) {
      debugPrint('devNotificationsDispatcher: $e');
    }
    return true;
  });
}
