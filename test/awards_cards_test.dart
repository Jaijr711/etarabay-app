import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/widgets/badge_emblem.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Awards cards are one kind of card, all the same size: they used to be
/// four kinds (coloured, white with a button, grey with a bar) at different
/// heights, which is what made the page look disordered.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('awards_cards').path);
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
      // 'alphabet' won but not taken: the gold card.
      'claimedBadges': ['firstSteps'],
    });
  });

  for (final lang in ['fil', 'ilo', 'en']) {
    for (final width in [320.0, 412.0]) {
      testWidgets('$lang at $width: medals all one size, nothing spills',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
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
            ChangeNotifierProvider(create: (_) => LanguageProvider(lang)),
            ChangeNotifierProvider<AudioManager>.value(
                value: AudioManager.instance),
          ],
          child: MaterialApp(
            locale: Locale(lang),
            // Ilocano has no Material translations; the app falls back to
            // English ones the same way.
            localizationsDelegates: const [
              AppLocalizations.delegate,
              _MaterialFallback(),
              _CupertinoFallback(),
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AwardsScreen(),
          ),
        ));
        await tester.pump(const Duration(seconds: 3));

        final medals = tester
            .widgetList<BadgeEmblem>(find.byType(BadgeEmblem))
            .where((m) => m.image != null && m.size > 60)
            .toList();
        expect(medals, isNotEmpty);
        expect(medals.map((m) => m.size).toSet(), hasLength(1));
        // A won one, a waiting one and a locked one are all on screen.
        expect(medals.any((m) => m.sparkle), isTrue);
        expect(medals.any((m) => m.locked), isTrue);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
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
