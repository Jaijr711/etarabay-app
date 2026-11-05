import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/home_screen.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:e_tarabay/widgets/custom_back_button.dart';
import 'package:e_tarabay/widgets/module_cards.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The pickers inside five modules, as chosen from the preview: Numbers and
/// About Me as lists of picture cards, Color Fun as categories first, Trace
/// It as a wall of letters, Remember It as piles of memory cards.
void main() {
  late Box profile;

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('pickers').path);
    profile = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  // Hive writes a file; inside a widget test's fake clock that never
  // finishes unless it runs on the real one.
  Future<void> child(WidgetTester tester, String gender) async =>
      tester.runAsync(() => profile.put('currentUser', {
            'name': 'Test',
            'gender': gender,
            'birthday': DateTime(2021, 5, 3).toIso8601String(),
            'createdAt': DateTime(2026, 9, 6).toIso8601String(),
            'avatar': 'animal_bunny',
            'stars': 0,
          }));

  Future<AppLocalizations> open(WidgetTester tester, Widget screen,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
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
      child: MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          _MaterialFallback(),
          _CupertinoFallback(),
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
    return AppLocalizations.delegate.load(const Locale('fil'));
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  // A picture decoded at its shown size is wrapped in a ResizeImage.
  String named(ImageProvider p) =>
      p is ResizeImage ? named(p.imageProvider) : '$p';

  bool shows(WidgetTester tester, String file) => tester
      .widgetList<Image>(find.byType(Image, skipOffstage: false))
      .any((i) => named(i.image).contains(file));

  int ringed(WidgetTester tester) => tester
      .widgetList<ModuleLevelTile>(
          find.byType(ModuleLevelTile, skipOffstage: false))
      .where((c) => c.highlight)
      .length;

  testWidgets('Numbers: seven picture tiles, the next one ringed',
      (tester) async {
    await child(tester, 'Male');
    await open(tester, const MatematikaScreen(),
        prefs: {for (var g = 0; g < 4; g++) 'mat_level_0_game_$g': true});
    expect(find.byType(ModuleLevelTile, skipOffstage: false), findsNWidgets(7));
    expect(ringed(tester), 1);
    expect(shows(tester, 'bilang/level3.webp'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  for (final (gender, picture) in const [
    ('Male', 'boy.webp'),
    ('Female', 'girl.webp'),
  ]) {
    testWidgets('About Me: "All About Me" shows a $picture for a $gender',
        (tester) async {
      await child(tester, gender);
      final loc = await open(tester, const PamilyaScreen());
      expect(find.text(loc.aboutMeShort), findsOneWidget);
      expect(shows(tester, picture), isTrue);
      expect(
          shows(tester, gender == 'Male' ? 'girl.webp' : 'boy.webp'), isFalse);
      // Nine lessons in one list; the last is further down on a phone.
      await tester.scrollUntilVisible(find.text(loc.myHome), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(loc.myHome), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('About Me: back from a lesson returns to the cards',
      (tester) async {
    await child(tester, 'Female');
    final loc = await open(tester, const PamilyaScreen());
    await tester.tap(find.byType(ModuleLevelTile).first);
    await settle(tester);
    expect(find.byType(ModuleLevelTile, skipOffstage: false), findsNothing);
    // The arrow at the top lands on the cards, not out of the module.
    await tester.tap(find.byType(CustomBackButton));
    await settle(tester);
    expect(find.byType(ModuleLevelTile, skipOffstage: false), findsWidgets);
    expect(find.text(loc.aboutMeShort), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  // The tip after a right answer used to come back to the cards with the
  // child and sit over them.
  for (final (label, wait) in const [
    ('while the tip is up', Duration(milliseconds: 2500)),
    ('before the tip is up', Duration(milliseconds: 500)),
  ]) {
    testWidgets('About Me: no tip left on the cards after back $label',
        (tester) async {
      await child(tester, 'Female');
      final loc = await open(tester, const PamilyaScreen());
      await tester.tap(find.byType(ModuleLevelTile).first);
      await settle(tester);
      // "What is your name?" — the child's own name is the right answer.
      await tester.tap(find.text('Test').last);
      await tester.pump(wait);
      expect(find.text(loc.whatIsYourNameDescription),
          wait.inMilliseconds > 1500 ? findsOneWidget : findsNothing);
      await tester.tap(find.byType(CustomBackButton));
      await settle(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ModuleLevelTile, skipOffstage: false), findsWidgets);
      expect(find.text(loc.whatIsYourNameDescription), findsNothing);
      await tester.pump(const Duration(seconds: 10));
    });
  }

  // Each tab replaces the last, so the phone's back on one closed the app.
  testWidgets("Lessons: the phone's back goes Home, not out of the app",
      (tester) async {
    await child(tester, 'Female');
    await open(tester, const LessonsScreen());
    final handled = await tester.binding.handlePopRoute();
    await settle(tester);
    expect(handled, isTrue, reason: 'back was left to close the app');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LessonsScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Color Fun: categories first, back from one returns to them',
      (tester) async {
    await child(tester, 'Female');
    final loc = await open(tester, const KulayScreen());
    for (final name in [
      loc.catAnimals,
      loc.catFlowers,
      loc.catFruits,
      loc.catToys
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    await tester.tap(find.text(loc.catAnimals));
    await settle(tester);
    // Inside: the category's name is the title and its pages show.
    expect(find.text(loc.pagePuppy), findsOneWidget);
    expect(find.text(loc.catFlowers), findsNothing);
    await tester.tap(find.byType(CustomBackButton));
    await settle(tester);
    expect(find.text(loc.catFlowers), findsOneWidget);
    expect(find.text(loc.coloringBook), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Trace It: the wall, a locked letter, a letter, and back',
      (tester) async {
    await child(tester, 'Male');
    final loc = await open(tester, const TraceItScreen());
    await settle(tester);
    expect(find.text(loc.pickLetter), findsOneWidget);
    // B is not reached yet: it shakes and the wall names A.
    await tester.tap(find.text('B'));
    await settle(tester);
    expect(find.text(loc.traceLockedHint('A')), findsOneWidget);
    expect(find.text(loc.pickLetter), findsOneWidget);
    // A opens the board.
    await tester.tap(find.text('A'));
    await settle(tester);
    expect(find.text(loc.pickLetter), findsNothing);
    // Back from the board lands on the wall, not out of the module.
    await tester.tap(find.byType(CustomBackButton));
    await settle(tester);
    expect(find.text(loc.pickLetter), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Remember It: four piles of cards, stars under each',
      (tester) async {
    await child(tester, 'Female');
    await open(tester, const TandaanScreen());
    await settle(tester);
    expect(find.byType(ModuleStars), findsNWidgets(4));
    expect(shows(tester, 'hugis.webp'), isTrue);
    expect(shows(tester, 'dog.webp'), isTrue);
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
