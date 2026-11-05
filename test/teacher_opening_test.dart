import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/splash_screen.dart';
import 'package:e_tarabay/screens/teacher_dashboard_screen.dart';
import 'package:e_tarabay/services/teacher_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// A teacher opening the app again goes PIN, then the class — not PIN, then
/// the train and the logo they had already sat through.
void main() {
  testWidgets('a returning teacher skips the opening video', (tester) async {
    await tester.runAsync(() async {
      Hive.init(Directory.systemTemp.createTempSync('opening').path);
      await Hive.openBox('userProfile');
      await Hive.openBox('userProgress');
    });
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'session_role': 'teacher',
      'teacher_privacy_agreed_v1': true,
      'teacher_privacy_name': 'Maria Santos',
      'teacher_privacy_date': '2026-10-30T00:00:00.000',
    });
    FlutterSecureStorage.setMockInitialValues({});
    await TeacherPin.save('1234');
    // An empty class: the dashboard itself is not what is being tested.
    final empty = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    TeacherDashboardScreen.debugStudents = empty.stream;
    addTearDown(() {
      TeacherDashboardScreen.debugStudents = null;
      empty.close();
    });

    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
        ChangeNotifierProvider<AudioManager>.value(
            value: AudioManager.instance),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: SplashScreen(),
      ),
    ));

    // No train, and no logo standing in for it.
    await tester.pump();
    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byType(Image), findsNothing);

    // Straight on to the class once the session is read.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(TeacherDashboardScreen).evaluate().isNotEmpty) break;
    }
    expect(find.byType(TeacherDashboardScreen), findsOneWidget);
    expect(find.byType(VideoPlayer), findsNothing);

    // Music has no player in a test and retries on a timer; let it give up.
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
