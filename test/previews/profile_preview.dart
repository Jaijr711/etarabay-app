import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The profile page with a made-up child, in English and Filipino. Not part
/// of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/profile_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('profile').path);
    final box = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await box.put('currentUser', {
      'name': 'Jay R. Dolores',
      'gender': 'male',
      'birthday': DateTime(2022, 9, 23).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'parentName': 'Jay Aslor Dolores',
      'parentContact': '09854646616',
      'avatar': 'male',
      'stars': 12,
    });
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    final fb = ByteData.view(
        File('assets/fonts/Fredoka.ttf').readAsBytesSync().buffer);
    await (FontLoader('Fredoka')..addFont(Future.value(fb))).load();
  });

  for (final lang in ['en', 'fil']) {
    testWidgets('profile $lang', (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      try {
        // No student session: one would start the cloud listener, which
        // has no Firebase in a test. The parent rows are hidden without it.
        SharedPreferences.setMockInitialValues({});
        await tester.binding.setSurfaceSize(const Size(400, 1300));
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider(lang)),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto'),
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 2));
        });
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(img.image, tester.element(find.byWidget(img)));
          }
        });
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../docs/previews/profile_$lang.png'));
      } finally {
        FlutterError.onError = original;
      }
    });
  }
}
