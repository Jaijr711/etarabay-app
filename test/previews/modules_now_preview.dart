import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/screens/magbasa_screen.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What each module looks like when it first opens, part way through. Not
/// part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/modules_now_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('modules').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
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

  for (final (name, screen) in <(String, Widget)>[
    ('matematika', const MatematikaScreen()),
    ('pamilya', const PamilyaScreen()),
    ('kulay', const KulayScreen()),
    ('trace', const TraceItScreen()),
    ('magbasa', const MagbasaScreen()),
    ('tandaan', const TandaanScreen()),
  ]) {
    testWidgets('module $name', (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      try {
        SharedPreferences.setMockInitialValues({
          for (var g = 0; g < 4; g++) 'mat_level_0_game_$g': true,
          for (var i = 0; i < 3; i++) 'kulay_page_Animals_$i': true,
        });
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(412, 915) * 2;
        addTearDown(tester.view.reset);
        final theme = appTheme();
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
            ChangeNotifierProvider<AudioManager>.value(
                value: AudioManager.instance),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
                textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
                elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontFamily: 'Roboto')))),
            locale: const Locale('fil'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: screen,
          ),
        ));
        await tester
            .runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
        await tester.pump(const Duration(seconds: 3));
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            try {
              await precacheImage(
                  img.image, tester.element(find.byWidget(img).first));
            } catch (_) {}
          }
        });
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../build/size_audit/now_$name.png'));
        await tester.pump(const Duration(seconds: 5));
      } finally {
        FlutterError.onError = original;
      }
    });
  }
}
