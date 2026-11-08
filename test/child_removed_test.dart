import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/developer_dashboard_screen.dart';
import 'package:e_tarabay/screens/for_parents_screen.dart';
import 'package:e_tarabay/services/auth_service.dart';
import 'package:e_tarabay/services/developer_roster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Meta extends Fake implements SnapshotMetadata {
  _Meta(this.isFromCache);

  @override
  final bool isFromCache;

  @override
  bool get hasPendingWrites => false;
}

// A child's record as the server sends it, or its absence.
// ignore: subtype_of_sealed_class
class _Record extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Record(this.id, this._data, {this.fromCache = false});

  @override
  final String id;
  final Map<String, dynamic>? _data;
  final bool fromCache;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  SnapshotMetadata get metadata => _Meta(fromCache);
}

/// The developer's removals, answered without a server.
class _FakeAuth extends Fake implements AuthService {
  _FakeAuth(this.answer);

  Map<String, dynamic> answer;
  final deleted = <String>[];

  @override
  Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    deleted.add(studentId);
    return answer;
  }
}

/// A child removed while someone is looking at them: the teacher's open
/// report closes and says why, and the developer is told whether the
/// removal went through.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('removed').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> open(WidgetTester tester, Widget home) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
        ChangeNotifierProvider<AudioManager>.value(
            value: AudioManager.instance),
      ],
      child: MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    // Music has no player in a test and retries on a timer; let it give up.
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets("the teacher's open report closes when the child is removed",
      (tester) async {
    final record = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    ForParentsScreen.debugStudentDoc = (_) => record.stream;
    addTearDown(() {
      ForParentsScreen.debugStudentDoc = null;
      record.close();
    });
    await open(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ForParentsScreen(
                      viewStudentId: 'kid-1', viewStudentName: 'Ana Reyes'))),
              child: const Text('open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open report'));
    await settle(tester);
    record.add(_Record('kid-1', {
      'name': 'Ana Reyes',
      'progress': {'percentage': 40.0, 'totalStars': 12},
    }));
    await settle(tester);
    expect(find.byType(ForParentsScreen), findsOneWidget);

    // A cached "nothing" is not a removal: a phone offline says the same.
    record.add(_Record('kid-1', null, fromCache: true));
    await settle(tester);
    expect(find.byType(ForParentsScreen), findsOneWidget);

    // The server says the record is gone.
    record.add(_Record('kid-1', null));
    await settle(tester);
    expect(find.byType(ForParentsScreen), findsNothing);
    expect(find.text('open report'), findsOneWidget);
    expect(find.text('Inalis na ang batang ito.'), findsOneWidget);
    await close(tester);
  });

  group('the developer is told how a removal went', () {
    late _FakeAuth auth;
    late StreamController<Map<String, dynamic>?> config;

    setUp(() {
      auth = _FakeAuth(const {'status': 'Success'});
      config = StreamController<Map<String, dynamic>?>.broadcast();
      DeveloperDashboardScreen.debugAuthService = auth;
      DeveloperDashboardScreen.debugConfig = config.stream;
      DeveloperDashboardScreen.debugOwnVersion = '1.2.57';
      DeveloperDashboardScreen.debugStudents = Stream.value([
        DevRecord('kid-1', {'name': 'Ana Reyes', 'lrn': 'DC-2026-0001'}),
      ]);
    });

    tearDown(() {
      DeveloperDashboardScreen.debugAuthService = null;
      DeveloperDashboardScreen.debugConfig = null;
      DeveloperDashboardScreen.debugOwnVersion = null;
      DeveloperDashboardScreen.debugStudents = null;
      config.close();
    });

    Future<void> deleteAna(WidgetTester tester) async {
      await open(tester, const DeveloperDashboardScreen());
      config.add({});
      await settle(tester);
      await tester.ensureVisible(find.byTooltip('Mga aksyon'));
      await tester.tap(find.byTooltip('Mga aksyon'));
      await settle(tester);
      await tester.tap(find.text('Burahin ang account'));
      await settle(tester);
      await tester.tap(find.text('Burahin'));
      await settle(tester);
    }

    testWidgets('done', (tester) async {
      await deleteAna(tester);
      expect(auth.deleted, ['kid-1']);
      expect(find.text('Na-delete na si Ana Reyes.'), findsOneWidget);
      await close(tester);
    });

    testWidgets('no internet: nothing was changed, and it says so',
        (tester) async {
      auth.answer = const {'status': 'Error', 'code': 'needsInternet'};
      await deleteAna(tester);
      expect(find.text('Walang internet. Walang nabago.'), findsOneWidget);
      await close(tester);
    });

    testWidgets('refused: try again', (tester) async {
      auth.answer = const {'status': 'Error', 'code': 'removeFailed'};
      await deleteAna(tester);
      expect(find.text('Hindi natuloy. Subukan ulit.'), findsOneWidget);
      await close(tester);
    });
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
