import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/teacher_pin.dart';
import 'package:e_tarabay/widgets/pin_key.dart';
import 'package:e_tarabay/widgets/teacher_pin_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    TeacherPin.useSecureStorage = true;
  });

  group('in a browser on the school network (no secure store)', () {
    setUp(() => TeacherPin.useSecureStorage = false);
    tearDown(() => TeacherPin.useSecureStorage = true);

    test('the PIN is made, opens, and blocks the same way', () async {
      expect(await TeacherPin.isSet(), isFalse);
      await TeacherPin.save('2580');
      expect(await TeacherPin.isSet(), isTrue);
      expect(await TeacherPin.check('2580'), PinCheck.ok);
      for (var i = 0; i < TeacherPin.maxTries - 1; i++) {
        expect(await TeacherPin.check('0000'), PinCheck.wrong);
      }
      expect(await TeacherPin.check('0000'), PinCheck.blocked);
      await TeacherPin.save('1357');
      expect(await TeacherPin.check('1357'), PinCheck.ok);
    });

    test('only the salted hash is kept', () async {
      await TeacherPin.save('2580');
      final prefs = await SharedPreferences.getInstance();
      final kept = prefs.getKeys().map((k) => '${prefs.get(k)}');
      expect(kept.any((v) => v.contains('2580')), isFalse);
    });
  });

  group("the teacher's PIN", () {
    test('a new phone has none', () async {
      expect(await TeacherPin.isSet(), isFalse);
    });

    test('the right PIN opens, a wrong one is counted', () async {
      await TeacherPin.save('2580');
      expect(await TeacherPin.isSet(), isTrue);
      expect(await TeacherPin.check('1111'), PinCheck.wrong);
      expect(await TeacherPin.tries(), 1);
      expect(await TeacherPin.check('2580'), PinCheck.ok);
      expect(await TeacherPin.tries(), 0, reason: 'a right PIN starts over');
    });

    test('five wrong tries stop even the right PIN', () async {
      await TeacherPin.save('2580');
      for (var i = 0; i < TeacherPin.maxTries - 1; i++) {
        expect(await TeacherPin.check('0000'), PinCheck.wrong);
      }
      expect(await TeacherPin.check('0000'), PinCheck.blocked);
      expect(await TeacherPin.check('2580'), PinCheck.blocked);
      expect(await TeacherPin.isBlocked(), isTrue);
    });

    test('a new PIN, made after the password, opens again', () async {
      await TeacherPin.save('2580');
      for (var i = 0; i < TeacherPin.maxTries; i++) {
        await TeacherPin.check('0000');
      }
      await TeacherPin.save('1357');
      expect(await TeacherPin.isBlocked(), isFalse);
      expect(await TeacherPin.check('1357'), PinCheck.ok);
      expect(await TeacherPin.check('2580'), PinCheck.wrong);
    });

    test('the PIN itself is never stored', () async {
      await TeacherPin.save('2580');
      const storage = FlutterSecureStorage();
      final all = await storage.readAll();
      expect(all.values.any((v) => v.contains('2580')), isFalse);
    });
  });

  testWidgets('making a PIN asks for it twice and saves only a match',
      (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: TeacherPinFlow(
        start: PinFlowStart.create,
        onDone: () => done = true,
      ),
    ));
    await tester.pump();

    Future<void> type(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.bySemanticsLabel(d));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('Make a PIN'), findsOneWidget);
    await type('2580');
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await type('2581');
    expect(find.text('The PINs are not the same. Try again.'), findsOneWidget);
    expect(find.text('Make a PIN'), findsOneWidget);
    expect(await TeacherPin.isSet(), isFalse);

    await type('2580');
    await type('2580');
    expect(done, isTrue);
    expect(await TeacherPin.check('2580'), PinCheck.ok);
  });

  Widget app(Widget home) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: home,
      );

  testWidgets('with no PIN yet, a PIN is made, not the password asked',
      (tester) async {
    await tester.pumpWidget(
        app(TeacherPinFlow(start: PinFlowStart.unlock, onDone: () {})));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.text('Make a PIN'), findsOneWidget);
    expect(find.text("Teacher's password"), findsNothing);
  });

  testWidgets('a wrong PIN on the lock says how many tries are left',
      (tester) async {
    await TeacherPin.save('2580');
    var opened = false;
    await tester.pumpWidget(app(TeacherPinFlow(
        start: PinFlowStart.unlock, onDone: () => opened = true)));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    for (final d in '1111'.split('')) {
      await tester.tap(find.bySemanticsLabel(d));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);
    for (final d in '2580'.split('')) {
      await tester.tap(find.bySemanticsLabel(d));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, isTrue);
  });

  /// A key drawn faded. Fading every key while the fourth digit was checked
  /// blinked the whole keypad; only a blocked lock may do it.
  final fadedKey = find.descendant(
    of: find.byType(PinKey),
    matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
  );

  testWidgets('the keypad does not fade while a PIN is checked',
      (tester) async {
    await tester.pumpWidget(
        app(TeacherPinFlow(start: PinFlowStart.create, onDone: () {})));
    await tester.pump();
    for (final d in '2580'.split('')) {
      await tester.tap(find.bySemanticsLabel(d));
      await tester.pump();
    }
    // Inside the short wait before the next step.
    await tester.pump(const Duration(milliseconds: 50));
    expect(fadedKey, findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Enter the PIN again'), findsOneWidget);
  });

  testWidgets('a blocked lock still fades its keys', (tester) async {
    await TeacherPin.save('2580');
    for (var i = 0; i < TeacherPin.maxTries; i++) {
      await TeacherPin.check('0000');
    }
    await tester.pumpWidget(
        app(TeacherPinFlow(start: PinFlowStart.unlock, onDone: () {})));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(fadedKey, findsWidgets);
  });
}
