import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/auth_service.dart';
import 'package:e_tarabay/widgets/login_problem_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A login that failed for the connection tries once more on a fresh one
/// before it says so; and what it says is in words a newcomer follows.
void main() {
  group('withReconnect', () {
    late List<String> calls;
    setUp(() => calls = []);

    Future<void> reconnect() async => calls.add('reconnect');

    test('the first read answers: no second, no reconnect', () async {
      final v = await AuthService.withReconnect((t) async {
        calls.add('read ${t.inSeconds}');
        return 7;
      }, reconnect: reconnect);
      expect(v, 7);
      expect(calls, ['read 10']);
    });

    test('a failed read reconnects, then tries longer', () async {
      var n = 0;
      final v = await AuthService.withReconnect((t) async {
        calls.add('read ${t.inSeconds}');
        if (n++ == 0) throw FirebaseException(plugin: 'x', code: 'unavailable');
        return 'ok';
      }, reconnect: reconnect);
      expect(v, 'ok');
      expect(calls, ['read 10', 'reconnect', 'read 20']);
    });

    test('both failing: the second failure is what comes out', () async {
      var n = 0;
      await expectLater(
        AuthService.withReconnect<int>((t) async {
          if (n++ == 0) throw FirebaseException(plugin: 'x', code: 'unavailable');
          throw TimeoutException('slow');
        }, reconnect: reconnect),
        throwsA(isA<TimeoutException>()),
      );
      expect(calls, ['reconnect']);
    });

    test('a refusal by the rules is not tried again', () async {
      await expectLater(
        AuthService.withReconnect<int>((t) async {
          calls.add('read');
          throw FirebaseException(plugin: 'x', code: 'permission-denied');
        }, reconnect: reconnect),
        throwsA(isA<FirebaseException>()),
      );
      expect(calls, ['read']);
    });

    test('a reconnect that itself fails still gets the second read',
        () async {
      var n = 0;
      final v = await AuthService.withReconnect((t) async {
        if (n++ == 0) throw Exception('offline');
        return 1;
      }, reconnect: () async => throw Exception('no'));
      expect(v, 1);
    });
  });

  group("Firestore's web answer", () {
    test('reads as the SDK would hand it over', () {
      final rows = AuthService.studentsFromRunQuery([
        {'readTime': '2026-11-08T05:00:00Z'},
        {
          'document': {
            'name': 'projects/p/databases/(default)/documents/students/abc123',
            'fields': {
              'username': {'stringValue': 'Jayjr'},
              'avatarChosen': {'booleanValue': true},
              'age': {'integerValue': '4'},
              'score': {'doubleValue': 2.5},
              'nothing': {'nullValue': null},
              'enrolledAt': {'timestampValue': '2026-09-06T04:19:33.513Z'},
              'profile': {
                'mapValue': {
                  'fields': {
                    'name': {'stringValue': 'Jay R. Dolores'},
                    'avatar': {'stringValue': 'animal_bunny'},
                  }
                }
              },
              'tags': {
                'arrayValue': {
                  'values': [
                    {'stringValue': 'a'},
                    {'integerValue': '2'}
                  ]
                }
              },
              'empty': {'arrayValue': {}},
            },
          },
        },
      ]);
      expect(rows, hasLength(1));
      final d = rows.single.data;
      expect(rows.single.id, 'abc123');
      expect(d['username'], 'Jayjr');
      expect(d['avatarChosen'], isTrue);
      expect(d['age'], 4);
      expect(d['score'], 2.5);
      expect(d.containsKey('nothing'), isTrue);
      expect(d['nothing'], isNull);
      expect(d['enrolledAt'], isA<Timestamp>());
      expect((d['enrolledAt'] as Timestamp).toDate().toUtc().year, 2026);
      expect(d['profile'], isA<Map<String, dynamic>>());
      expect((d['profile'] as Map)['name'], 'Jay R. Dolores');
      expect(d['tags'], ['a', 2]);
      expect(d['empty'], isEmpty);
    });

    test('nothing found, or not a list', () {
      expect(AuthService.studentsFromRunQuery([{'readTime': 'x'}]), isEmpty);
      expect(AuthService.studentsFromRunQuery({'error': 1}), isEmpty);
    });

    test('an error, in one short line', () {
      expect(AuthService.describeError(TimeoutException('x')), 'timeout');
      expect(
          AuthService.describeError(FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
              message: 'The service is\ncurrently unavailable.')),
          'cloud_firestore/unavailable: The service is currently unavailable.');
      expect(AuthService.describeError('x' * 300).length, 141);
    });
  });

  test('the step codes', () {
    expect(AuthService.connectionStep(Exception(), signIn: true), 'N1');
    expect(AuthService.connectionStep(Exception()), 'N2');
    expect(AuthService.connectionStep(TimeoutException('')), 'N3');
  });

  group('the sheet', () {
    Future<void> show(WidgetTester tester, LoginProblem problem,
        {String? code, VoidCallback? onRetry}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 760);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => LoginProblemSheet.show(context, problem,
                  code: code, onRetry: onRetry),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('every kind fits a small phone and has steps', (tester) async {
      for (final p in LoginProblem.values) {
        await show(tester, p, code: 'N2', onRetry: () {});
        expect(tester.takeException(), isNull, reason: '$p');
        expect(find.text('1'), findsOneWidget, reason: '$p');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets("can't connect: try again, and the code", (tester) async {
      var tried = 0;
      await show(tester, LoginProblem.connection,
          code: 'N2', onRetry: () => tried++);
      expect(find.text('Hindi makakonekta'), findsOneWidget);
      expect(find.text('Code: N2'), findsOneWidget);
      await tester.tap(find.text('Subukan ulit'));
      await tester.pumpAndSettle();
      expect(tried, 1);
    });

    testWidgets('the code opens to the error itself', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 760);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => LoginProblemSheet.show(
                  context, LoginProblem.connection,
                  code: 'N2', detail: 'cloud_firestore/unavailable: down'),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('cloud_firestore/unavailable: down'), findsNothing);
      await tester.ensureVisible(find.text('Code: N2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Code: N2'));
      await tester.pump();
      expect(find.text('cloud_firestore/unavailable: down'), findsOneWidget);
    });

    testWidgets("can't connect: retry closes the sheet", (tester) async {
      var tried = 0;
      await show(tester, LoginProblem.connection,
          code: 'N2', onRetry: () => tried++);
      await tester.tap(find.text('Subukan ulit'));
      await tester.pumpAndSettle();
      expect(tried, 1);
      expect(find.text('Hindi makakonekta'), findsNothing);
    });

    testWidgets('a wrong number: no code, no try again', (tester) async {
      await show(tester, LoginProblem.wrongStudentNumber,
          code: 'N2', onRetry: () {});
      expect(find.text('Mali ang Student Number'), findsOneWidget);
      expect(find.textContaining('Code:'), findsNothing);
      expect(find.text('Subukan ulit'), findsNothing);
      await tester.tap(find.text('Sige'));
      await tester.pumpAndSettle();
      expect(find.text('Mali ang Student Number'), findsNothing);
    });

    testWidgets('how to log in shows the login card', (tester) async {
      await show(tester, LoginProblem.howTo);
      expect(find.text('Paano mag-log in'), findsOneWidget);
      expect(find.text('ana1234'), findsOneWidget);
      expect(find.text('DC-2026-0001'), findsOneWidget);
      expect(find.text('unang kahon'), findsOneWidget);
    });
  });
}
