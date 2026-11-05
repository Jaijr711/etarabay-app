import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Match with Line, with the walking-dot lines chosen from the preview: a
/// line can be joined, taken back, and the whole board joined right, with
/// the dots walking the whole time.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('matchline').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  testWidgets('a line joins, comes back off, and a right board is accepted',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
        ChangeNotifierProvider<AudioManager>.value(
            value: AudioManager.instance),
      ],
      child: const MaterialApp(
        locale: Locale('fil'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          _MaterialFallback(),
          _CupertinoFallback(),
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MatematikaScreen(),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));

    Future<void> beat() async {
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await tester.tap(find.text(loc.lineMatch));
    await beat();

    // The boxes are the tappable things with a global key: three groups on
    // the left, then three numbers on the right.
    List<Finder> boxes() {
      final all = find
          .byWidgetPredicate((w) => w is GestureDetector && w.key is GlobalKey);
      return [for (int i = 0; i < 6; i++) all.at(i)];
    }

    Finder score(int n) =>
        find.textContaining('$n / 3  natugma', findRichText: true);
    Finder number(int n) => find.descendant(
        of: find.byWidgetPredicate(
            (w) => w is GestureDetector && w.key is GlobalKey),
        matching: find.text('$n'));

    expect(score(0), findsOneWidget);

    // Join the one apple to 1, then take it back by tapping the group again.
    await tester.tap(boxes()[0]);
    await beat();
    await tester.tap(number(1));
    await beat();
    expect(score(1), findsOneWidget);
    await tester.tap(boxes()[0]);
    await beat();
    expect(score(0), findsOneWidget);

    // Now the whole board, right: one apple to 1, two to 2, three to 3.
    for (int i = 0; i < 3; i++) {
      await tester.tap(boxes()[i]);
      await beat();
      await tester.tap(number(i + 1));
      await beat();
    }
    expect(score(3), findsOneWidget);
    // The verdict, the star burst and the shared "correct" card.
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

class _MaterialFallback extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_MaterialFallback old) => false;
}

class _CupertinoFallback extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_CupertinoFallback old) => false;
}
