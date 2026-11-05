import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Numbers and About Me as tiles two to a row, part way through — the same
/// progress as the design C preview, at each phone width. Not part of the
/// suite — run by hand:
///
///   flutter test --update-goldens test/previews/module_tiles_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('tiles').path);
    final profile = await Hive.openBox('userProfile');
    final progress = await Hive.openBox('userProgress');
    await profile.put('currentUser', {
      'name': 'Ana',
      'gender': 'Male',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 146,
    });
    // Numbers: three levels done, the fourth begun. About Me: two done.
    await progress.put(
        'matematika_levels', [true, true, true, false, false, false, false]);
    for (final (i, s) in const [(0, 3), (1, 3), (2, 3), (3, 2)]) {
      await progress.put('mat_level_${i}_stars', s);
    }
    await progress.put('pamilya_levels',
        [true, true, false, false, false, false, false, false, false]);
    for (final (i, s) in const [(0, 3), (1, 3), (2, 2)]) {
      await progress.put('pamilya_level_${i}_stars', s);
    }
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
    ('numbers', const MatematikaScreen()),
    ('ako', const PamilyaScreen()),
  ]) {
    for (final width in const [320.0, 360.0, 412.0]) {
      testWidgets('tiles $name ${width.toInt()}', (tester) async {
        final original = FlutterError.onError;
        FlutterError.onError = (d) {
          if (d.exception is MissingPluginException) return;
          original?.call(d);
        };
        try {
          SharedPreferences.setMockInitialValues({});
          tester.view.devicePixelRatio = 2;
          // Tall enough to show every tile, so it compares with the preview.
          tester.view.physicalSize = Size(width, width * 3.6) * 2;
          addTearDown(tester.view.reset);
          final theme = appTheme();
          await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => UserProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
              ChangeNotifierProvider<AudioManager>.value(
                  value: AudioManager.instance),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme.copyWith(
                  textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
              locale: const Locale('en'),
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
          expect(tester.takeException(), isNull);
          await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                  '../../build/size_audit/tiles_${name}_${width.toInt()}.png'));
          await tester.pump(const Duration(seconds: 5));
        } finally {
          FlutterError.onError = original;
        }
      });
    }
  }
}
