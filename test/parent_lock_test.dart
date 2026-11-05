import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/parents_lock_screen.dart';
import 'package:e_tarabay/services/parent_pin.dart';
import 'package:e_tarabay/widgets/custom_back_button.dart';
import 'package:e_tarabay/widgets/pin_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('parent_lock').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  /// Opens the door from a button, so leaving it can be seen: the result of
  /// the route is what the sign-in waits for.
  Future<List<Object?>> open(WidgetTester tester,
      {String? pin,
      Widget screen = const ParentsLockScreen(setupOnly: true)}) async {
    SharedPreferences.setMockInitialValues({});
    if (pin != null) {
      final prefs = await SharedPreferences.getInstance();
      await ParentPin.write(prefs, pin);
    }
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);

    final results = <Object?>[];
    await tester.pumpWidget(MultiProvider(
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
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => screen))),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    return results;
  }

  Future<void> type(WidgetTester tester, String code) async {
    for (final d in code.split('')) {
      await tester.tap(find.bySemanticsLabel(d));
      await tester.pump();
    }
    await settle(tester);
  }

  testWidgets('a new code is typed twice on the keypad and saved',
      (tester) async {
    final results = await open(tester);
    expect(find.text('Set a 4-digit code'), findsOneWidget);
    // The keypad, not the phone's keyboard.
    expect(find.byType(TextField), findsNothing);

    await type(tester, '1111');
    expect(find.text('Type it again'), findsOneWidget);
    await type(tester, '1111');

    expect(results, [true]);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(await ParentPin.matches(prefs!, '1111'), isTrue);
  });

  testWidgets('a different second code starts again from the first step',
      (tester) async {
    final results = await open(tester);
    await type(tester, '1111');
    await type(tester, '2222');

    expect(find.text('Set a 4-digit code'), findsOneWidget);
    expect(find.text('The two codes are different'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('the saved code opens the door, a wrong one does not',
      (tester) async {
    final results = await open(tester, pin: '4271');
    expect(find.text('Enter your code'), findsOneWidget);

    await type(tester, '9999');
    expect(find.text('Wrong code'), findsOneWidget);
    expect(results, isEmpty);

    await type(tester, '4271');
    expect(results, [true]);
  });

  testWidgets('the keypad does not fade while a code is checked',
      (tester) async {
    await open(tester, pin: '4271');
    for (final d in '999'.split('')) {
      await tester.tap(find.bySemanticsLabel(d));
      await tester.pump();
    }
    // The fourth digit starts the check; the keys must not blink with it.
    await tester.tap(find.bySemanticsLabel('9'));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(PinKey),
        matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
      ),
      findsNothing,
    );
    await settle(tester);
    expect(find.text('Wrong code'), findsOneWidget);
  });

  testWidgets('a forgotten code asks for the Student Number', (tester) async {
    await open(tester, pin: '4271');
    await tester.tap(find.text('Forgot code? Use the Student Number'));
    await settle(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Verify Student Number'), findsOneWidget);

    await tester.tap(find.text('I remember the code'));
    await settle(tester);
    expect(find.text('Enter your code'), findsOneWidget);
  });

  testWidgets('with no code yet, the door asks for the Student Number first',
      (tester) async {
    // A sign-in cut short, or a phone updated from 1.2.52: the hands on it
    // may be the child's, so a code is not offered straight away.
    await open(tester, screen: const ParentsLockScreen());

    expect(find.text('For parents only!'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Verify Student Number'), findsOneWidget);
    expect(find.text('Set a 4-digit code'), findsNothing);
    // No code exists to be remembered.
    expect(find.text('I remember the code'), findsNothing);
  });

  testWidgets('signing out asks for the code and returns once it is right',
      (tester) async {
    final results = await open(tester,
        pin: '4271', screen: const ParentsLockScreen(verifyOnly: true));
    expect(find.text('Code first, before leaving!'), findsOneWidget);

    await type(tester, '9999');
    expect(find.text('Wrong code'), findsOneWidget);
    expect(results, isEmpty);

    await type(tester, '4271');
    expect(results, [true]);
  });

  testWidgets('leaving the sign-out code does not sign out', (tester) async {
    final results = await open(tester,
        pin: '4271', screen: const ParentsLockScreen(verifyOnly: true));
    await tester.tap(find.byType(CustomBackButton));
    await settle(tester);
    expect(results, [null]);
  });
}

/// Lets the prefs reads finish (real async) and the frames that follow.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}
