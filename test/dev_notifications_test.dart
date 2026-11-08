import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/services/dev_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What reaches the notification bar with the app closed: the developer's
/// notification to one child or to the teachers, and word of a new
/// version, each once, and only where it belongs.
void main() {
  final now = DateTime(2026, 11, 8, 15, 0);

  Map<String, dynamic> notif(String id,
          {Duration ago = const Duration(minutes: 5),
          String title = 'E-Tarabay',
          String body = 'May bago kang badge!'}) =>
      {
        'id': id,
        'title': title,
        'body': body,
        'sentAt': Timestamp.fromDate(now.subtract(ago)),
      };

  late List<String> shown;
  late List<String> asked;
  Map<String, dynamic>? child;
  Map<String, dynamic>? teacher;
  String? newer;
  Object? failWith;

  Future<SharedPreferences> prefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Future<void> run(SharedPreferences p, {DateTime? at}) => DevNotifications(
        prefs: p,
        readChild: (id) async {
          asked.add('child $id');
          if (failWith != null) throw failWith!;
          return child;
        },
        readTeacher: () async {
          asked.add('teacher');
          if (failWith != null) throw failWith!;
          return teacher;
        },
        newerVersion: () async {
          asked.add('update');
          return newer;
        },
        show: (id, title, body, {required update}) async =>
            shown.add('$id|$title|$body'),
        now: () => at ?? now,
      ).run();

  setUp(() {
    shown = [];
    asked = [];
    child = null;
    teacher = null;
    newer = null;
    failWith = null;
  });

  const childPhone = {
    'session_role': 'student',
    'session_student_id': 'kid-1',
    'notifications_enabled': true,
  };

  group("the developer's notification", () {
    test('a new one for this child is shown, once', () async {
      final p = await prefs(childPhone);
      child = {'devNotif': notif('n1', title: '')};
      await run(p);
      expect(shown, ['2001|E-Tarabay|May bago kang badge!']);
      await run(p);
      expect(shown, hasLength(1));
    });

    test('a second one, with a new id, is shown too', () async {
      final p = await prefs(childPhone);
      child = {'devNotif': notif('n1')};
      await run(p);
      child = {'devNotif': notif('n2', body: 'Balik ka bukas!')};
      await run(p);
      expect(shown.last, '2001|E-Tarabay|Balik ka bukas!');
    });

    test('one older than two days is not shown', () async {
      final p = await prefs(childPhone);
      child = {'devNotif': notif('old', ago: const Duration(days: 3))};
      await run(p);
      expect(shown, isEmpty);
    });

    test("not with the parents' notifications switch off", () async {
      final p = await prefs({...childPhone, 'notifications_enabled': false});
      child = {'devNotif': notif('n1')};
      newer = '1.2.58';
      await run(p);
      expect(shown, isEmpty);
      expect(asked, isEmpty);
    });

    test("a teacher's phone reads only the teachers' one", () async {
      final p = await prefs({'session_role': 'teacher'});
      teacher = {'teacher': notif('t1', body: 'May pulong bukas.')};
      await run(p);
      expect(shown, ['2002|E-Tarabay|May pulong bukas.']);
      expect(asked.where((a) => a.startsWith('child')), isEmpty);
    });

    test('signed out: no developer notification is looked for', () async {
      final p = await prefs({});
      await run(p);
      expect(asked, ['update']);
    });

    test('offline: nothing shown and nothing marked, so it comes later',
        () async {
      final p = await prefs(childPhone);
      child = {'devNotif': notif('n1')};
      failWith = Exception('unavailable');
      await run(p);
      expect(shown, isEmpty);
      failWith = null;
      await run(p);
      expect(shown, hasLength(1));
    });

    test('one not yet stamped by the server waits', () async {
      final p = await prefs(childPhone);
      child = {
        'devNotif': {'id': 'n1', 'body': 'Hello', 'sentAt': null}
      };
      await run(p);
      expect(shown, isEmpty);
      child = {'devNotif': notif('n1', body: 'Hello')};
      await run(p);
      expect(shown, hasLength(1));
    });
  });

  group('a new version', () {
    test('is shown once, in the app language', () async {
      final p = await prefs({'language': 'fil'});
      newer = '1.2.58';
      await run(p);
      expect(shown, [
        '2003|May bagong E-Tarabay!|Bersyon 1.2.58 — pindutin para i-update.'
      ]);
      await run(p, at: now.add(const Duration(hours: 7)));
      expect(shown, hasLength(1));
    });

    test('is asked for at most every six hours', () async {
      final p = await prefs({});
      await run(p);
      await run(p, at: now.add(const Duration(hours: 1)));
      expect(asked.where((a) => a == 'update'), hasLength(1));
      await run(p, at: now.add(const Duration(hours: 7)));
      expect(asked.where((a) => a == 'update'), hasLength(2));
    });

    test('nothing when this version is current', () async {
      final p = await prefs({});
      await run(p);
      expect(shown, isEmpty);
    });

    test('reaches a teacher and a signed-out phone', () async {
      newer = '1.2.58';
      await run(await prefs({'session_role': 'teacher'}));
      await run(await prefs({}));
      expect(shown.where((s) => s.startsWith('2003')), hasLength(2));
    });
  });
}
