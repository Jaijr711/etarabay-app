import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/parents_lock_screen.dart';
import 'package:e_tarabay/screens/privacy_notice_screen.dart';
import 'package:e_tarabay/services/parent_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
        ChangeNotifierProvider<AudioManager>.value(value: AudioManager.instance),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: home,
      ),
    );

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('parent_privacy').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  testWidgets('the code made at sign-in is the one the parents door asks for',
      (tester) async {
    // Made at sign-in, through ParentPin. The door used to look under its
    // own per-child key, find nothing, and ask for a new code.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await ParentPin.write(prefs, '4271');

    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(_app(const ParentsLockScreen()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    expect(find.text('Set a 4-digit code'), findsNothing);
    expect(find.text('Enter your code'), findsWidgets);
  });

  testWidgets('the privacy notice is read once and recorded', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (_) =>
                    const PrivacyNoticeScreen(requireAcknowledge: true))),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Notice'), findsOneWidget);
    // No way round it: back does nothing until it is acknowledged.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Privacy Notice'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('I understand'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(result, isTrue);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(await PrivacyNotice.isAcknowledged(prefs!), isTrue);
  });
}
