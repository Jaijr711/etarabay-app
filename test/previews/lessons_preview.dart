import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Lessons page part way through: some of Numbers done (so it is the one
/// ringed), all the colouring finished, the rest not started. Not part of
/// the suite — run by hand:
///
///   flutter test --update-goldens test/previews/lessons_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('lessons').path);
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

  for (final (name, size) in const [
    ('phone', Size(412, 915)),
    ('small', Size(320, 640)),
  ]) {
    testWidgets('lessons $name', (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      try {
        SharedPreferences.setMockInitialValues({
          for (var g = 0; g < 4; g++) 'mat_level_0_game_$g': true,
          for (final (cat, n) in const [
            ('Animals', 3),
            ('Flowers', 2),
            ('Fruits', 2),
            ('Toys', 2),
          ])
            for (var i = 0; i < n; i++) 'kulay_page_${cat}_$i': true,
        });
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = size * 2;
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
                textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
            locale: const Locale('fil'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LessonsScreen(),
          ),
        ));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 2)));
        await tester.pump(const Duration(seconds: 3));
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(
                img.image, tester.element(find.byWidget(img).first));
          }
        });
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../build/size_audit/lessons_c_$name.png'));
        await tester.pump(const Duration(seconds: 5));
      } finally {
        FlutterError.onError = original;
      }
    });
  }
}
