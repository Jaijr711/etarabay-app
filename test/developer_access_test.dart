import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/developer_dashboard_screen.dart';
import 'package:e_tarabay/screens/teacher_dashboard_screen.dart';
import 'package:e_tarabay/screens/teacher_login_screen.dart';
import 'package:e_tarabay/screens/teacher_settings_screen.dart';
import 'package:e_tarabay/services/auth_service.dart';
import 'package:e_tarabay/services/developer_roster.dart';
import 'package:e_tarabay/services/teacher_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two passwords the teacher login knows, with no Firebase behind it.
class _FakeAuth extends Fake implements AuthService {
  static const teacher = 'guro2026';
  static const developer = 'dev-secret-9';

  @override
  Future<bool?> checkTeacherLogin(String username, String password) async =>
      password == teacher;

  @override
  Future<bool> verifyDeveloperPassword(String password) async =>
      password == developer;

  @override
  Future<bool?> checkTeacherPassword(String password) async =>
      password == teacher;

  final saved = <String>[];

  @override
  Future<bool> setDeveloperPassword(String newPassword) async {
    saved.add(newPassword);
    return true;
  }
}

/// The developer dashboard's one door is the developer's own password in
/// the teacher login; tapping the version number opens nothing any more.
void main() {
  late StreamController<QuerySnapshot<Map<String, dynamic>>> classList;
  late StreamController<Map<String, dynamic>?> config;
  late _FakeAuth auth;

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('devaccess').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    PackageInfo.setMockInitialValues(
        appName: 'E-Tarabay',
        packageName: 'com.etarabay',
        version: '1.2.57',
        buildNumber: '70',
        buildSignature: '');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'teacher_privacy_agreed_v1': true,
      'teacher_privacy_name': 'Maria Santos',
      'teacher_privacy_date': '2026-10-30T00:00:00.000',
    });
    FlutterSecureStorage.setMockInitialValues({});
    await TeacherPin.save('1234');
    TeacherLoginScreen.debugAuthService = _FakeAuth();
    classList =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    config = StreamController<Map<String, dynamic>?>.broadcast();
    TeacherDashboardScreen.debugStudents = classList.stream;
    DeveloperDashboardScreen.debugStudents =
        Stream.value(const <DevRecord>[]);
    DeveloperDashboardScreen.debugConfig = config.stream;
    DeveloperDashboardScreen.debugOwnVersion = '1.2.57';
    DeveloperDashboardScreen.debugAuthService = auth = _FakeAuth();
  });

  tearDown(() {
    TeacherLoginScreen.debugAuthService = null;
    TeacherDashboardScreen.debugStudents = null;
    DeveloperDashboardScreen.debugStudents = null;
    DeveloperDashboardScreen.debugConfig = null;
    DeveloperDashboardScreen.debugOwnVersion = null;
    DeveloperDashboardScreen.debugAuthService = null;
    classList.close();
    config.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, Widget home) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
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

  Future<void> logIn(WidgetTester tester, String password) async {
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Mag-login bilang Guro'));
    await settle(tester);
  }

  testWidgets("the developer's password opens the developer dashboard",
      (tester) async {
    await open(tester, const TeacherLoginScreen());
    await logIn(tester, _FakeAuth.developer);
    expect(find.byType(DeveloperDashboardScreen), findsOneWidget);
    expect(find.byType(TeacherDashboardScreen), findsNothing);
    await close(tester);
  });

  testWidgets("the teacher's password still opens the class", (tester) async {
    await open(tester, const TeacherLoginScreen());
    await logIn(tester, _FakeAuth.teacher);
    expect(find.byType(TeacherDashboardScreen), findsOneWidget);
    expect(find.byType(DeveloperDashboardScreen), findsNothing);
    await close(tester);
  });

  testWidgets('a wrong password opens nothing, and says only the usual',
      (tester) async {
    await open(tester, const TeacherLoginScreen());
    await logIn(tester, 'hulaan-lang');
    expect(find.byType(TeacherLoginScreen), findsOneWidget);
    expect(find.byType(DeveloperDashboardScreen), findsNothing);
    // The usual sheet, the same as any wrong teacher password.
    expect(find.text('Mali ang password'), findsOneWidget);
    await close(tester);
  });

  testWidgets('seven taps on the version open nothing', (tester) async {
    await open(tester, const TeacherSettingsScreen());
    final version = find.text('Bersyon');
    await tester.scrollUntilVisible(version, 200,
        scrollable: find.byType(Scrollable).first);
    for (var i = 0; i < 8; i++) {
      await tester.tap(version, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
    expect(find.byType(TeacherSettingsScreen), findsOneWidget);
    expect(find.byType(DeveloperDashboardScreen), findsNothing);
    await close(tester);
  });

  testWidgets("a new developer password the same as the teacher's is refused",
      (tester) async {
    await open(tester, const DeveloperDashboardScreen());
    config.add({});
    await tester.pump();
    // On the settings page now, with the app's other settings.
    await tester.tap(find.byTooltip('Mga setting ng app'));
    await settle(tester);
    await tester.tap(find.text('Developer password'));
    await settle(tester);
    final fields = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), _FakeAuth.developer);
    await tester.enterText(fields.at(1), _FakeAuth.teacher);
    await tester.enterText(fields.at(2), _FakeAuth.teacher);
    await tester.tap(find.text('I-save'));
    await settle(tester);
    expect(find.text('Kapareho ito ng password ng guro. Pumili ng iba.'),
        findsOneWidget);
    expect(auth.saved, isEmpty);

    // A new one of its own is saved.
    await tester.enterText(fields.at(1), 'bago-ito-77');
    await tester.enterText(fields.at(2), 'bago-ito-77');
    await tester.tap(find.text('I-save'));
    await settle(tester);
    expect(auth.saved, ['bago-ito-77']);
    expect(find.byType(AlertDialog), findsNothing);
    await close(tester);
  });

  testWidgets("a minimum above this phone's own version is refused",
      (tester) async {
    await open(tester, const DeveloperDashboardScreen());
    config.add({});
    await tester.pump();
    await tester.tap(find.byTooltip('Mga setting ng app'));
    await settle(tester);
    await tester.tap(find.text('Pinakamababang bersyon'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '1.3.0');
    await tester.tap(find.text('I-save'));
    await settle(tester);
    expect(find.textContaining('Mas mataas ito sa bersyon ng phone na ito'),
        findsOneWidget);
    // Not even asked: nothing to confirm.
    expect(find.text('Pilitin'), findsNothing);
    await close(tester);
  });
}
