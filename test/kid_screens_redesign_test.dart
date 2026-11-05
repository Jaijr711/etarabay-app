import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:e_tarabay/screens/settings_screen.dart';
import 'package:e_tarabay/widgets/badge_emblem.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three kid screens the user picked new looks for: Lessons as tinted
/// cards with a button on each, Awards as a trophy cabinet, Settings as
/// white cards with 3D pictures.
void main() {
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
        appName: 'E-Tarabay',
        packageName: 'com.etarabay',
        version: '1.2.53',
        buildNumber: '65',
        buildSignature: '');
    Hive.init(Directory.systemTemp.createTempSync('redesign').path);
    final box = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await box.put('currentUser', {
      'name': 'Test',
      'gender': 'female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 10,
      'achievements': {'firstSteps': 3, 'alphabet': 1},
      'claimedBadges': ['firstSteps'],
    });
  });

  late LanguageProvider language;

  Future<void> open(WidgetTester tester, Widget screen,
      {String lang = 'fil',
      Size size = const Size(412, 915),
      bool keepPrefs = false}) async {
    if (!keepPrefs) SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    language = LanguageProvider(lang);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<LanguageProvider>.value(value: language),
        ChangeNotifierProvider<AudioManager>.value(
            value: AudioManager.instance),
      ],
      child: Consumer<LanguageProvider>(
        builder: (_, l, __) => MaterialApp(
          locale: Locale(l.currentLanguageCode),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            _MaterialFallback(),
            _CupertinoFallback(),
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
  }

  for (final size in const [Size(320, 568), Size(412, 915)]) {
    testWidgets(
        'Lessons: six cards with a button each, no titles over them '
        'on $size', (tester) async {
      await open(tester, const LessonsScreen(), size: size);
      final loc = await AppLocalizations.delegate.load(const Locale('fil'));
      // Every module starts at zero here, so each says "Start".
      expect(find.text(loc.lessonStart, skipOffstage: false), findsNWidgets(6));
      // The old layout put each name twice: once as a heading, once on the
      // card. Now only the card says it.
      expect(find.text(loc.matematika, skipOffstage: false), findsOneWidget);
      // Counts read as a sentence, "0 sa 31 na gawain", not "0/31".
      expect(
          find.text(loc.lessonActivities(0, UserProvider.matematikaGameCount),
              skipOffstage: false),
          findsOneWidget);
      // The title has the whole width now, so a small phone shows all of it.
      final title = find.text(loc.overallProgress);
      expect(title, findsOneWidget);
      final shown = tester.renderObject<RenderParagraph>(title);
      expect(shown.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('Lessons: the lesson in progress is the one ringed',
      (tester) async {
    SharedPreferences.setMockInitialValues({'mat_level_0_game_0': true});
    await open(tester, const LessonsScreen(), keepPrefs: true);
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));
    expect(find.text(loc.lessonContinue, skipOffstage: false), findsOneWidget);
    final ringed = tester
        .widgetList<Container>(find.byType(Container, skipOffstage: false))
        .where((c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).border != null &&
            (c.decoration as BoxDecoration).gradient != null);
    expect(ringed, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Awards: the cabinet holds all thirteen, the streak on its own '
      'shelf', (tester) async {
    await open(tester, const AwardsScreen());
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));
    expect(
        find.text(loc.badgeSpecialShelf, skipOffstage: false), findsOneWidget);
    final medals = tester
        .widgetList<BadgeEmblem>(find.byType(BadgeEmblem, skipOffstage: false))
        .where((m) => m.image != null && m.size > 60);
    expect(medals, hasLength(13));
    // Won but not taken: the short "take it" under the medal.
    expect(find.text(loc.claimShort, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Settings: the language switch changes the language',
      (tester) async {
    await open(tester, const SettingsScreen());
    expect(language.currentLanguageCode, 'fil');
    await tester.tap(find.text('English'));
    await tester.pump(const Duration(seconds: 1));
    expect(language.currentLanguageCode, 'en');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Settings: turning sound off shows the muted speaker',
      (tester) async {
    await open(tester, const SettingsScreen());
    bool shows(String name) => tester
        .widgetList<Image>(find.byType(Image))
        .any((i) => '${i.image}'.contains('settings/$name.webp'));
    expect(shows('speaker'), isTrue);
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(shows('speaker_off'), isTrue);
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
