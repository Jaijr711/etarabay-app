import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Awards page with a made-up child part way through: medals at one,
/// two and three stars, one waiting to be claimed, the rest still locked.
/// Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/awards_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('awards').path);
    final box = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await box.put('currentUser', {
      'name': 'Ana Mendoza Reyes',
      'gender': 'female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 45,
      'achievements': {
        'firstSteps': 3,
        'alphabet': 2,
        'numbers': 1,
        'colors': 1,
        'shapes': 2,
        'bookworm': 1,
      },
      // 'numbers' earned but not yet taken: it shows the claim sparkle.
      'claimedBadges': [
        'firstSteps',
        'alphabet',
        'colors',
        'shapes',
        'bookworm'
      ],
    });
    for (final (family, file) in const [
      ('Roboto', r'C:\Windows\Fonts\arialbd.ttf'),
      ('Fredoka', 'assets/fonts/Fredoka.ttf'),
    ]) {
      final f = File(file);
      if (!f.existsSync()) continue;
      final bytes = ByteData.view(f.readAsBytesSync().buffer);
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }
  });

  for (final lang in ['fil', 'en']) {
    testWidgets('awards $lang', (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      try {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(380, 1200) * 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider(lang)),
            ChangeNotifierProvider<AudioManager>.value(
                value: AudioManager.instance),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto'),
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AwardsScreen(),
          ),
        ));
        await tester
            .runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
        await tester.pump(const Duration(seconds: 3));
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            // A won medal shows its picture twice (the picture and its
            // shadow), so the same widget can be found more than once.
            await precacheImage(
                img.image, tester.element(find.byWidget(img).first));
          }
        });
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                '../../build/size_audit/awards_medals_$lang.png'));
        await tester.pump(const Duration(seconds: 5));
      } finally {
        FlutterError.onError = original;
      }
    });
  }
}
