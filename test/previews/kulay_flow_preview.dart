import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Color Fun's new way through, screen by screen: the categories with the
/// star count, a picture with the Done button, the finished card, and Clear
/// on a saved picture. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/kulay_flow_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('kulayflow').path);
    final profile = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await profile.put('currentUser', {
      'name': 'Ana',
      'gender': 'Male',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 146,
    });
    for (final (family, file) in const [
      ('Roboto', r'C:\Windows\Fonts\arialbd.ttf'),
      ('Fredoka', 'assets/fonts/Fredoka.ttf'),
      (
        'MaterialIcons',
        r'C:\develop\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
      ),
    ]) {
      final f = File(file);
      if (!f.existsSync()) continue;
      final bytes = ByteData.view(f.readAsBytesSync().buffer);
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('kulay flow', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    // Bake at the first save, so the picture after it can be compared with
    // the one before.
    kulayBakeMaxStrokes = 1;
    kulayBakeKeep = 0;
    try {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(360, 760) * 2;
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
          home: const KulayScreen(),
        ),
      ));
      final loc = await AppLocalizations.delegate.load(const Locale('fil'));

      Future<void> settle([int seconds = 1]) async {
        for (int i = 0; i < seconds * 4; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)));
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            try {
              await precacheImage(
                  img.image, tester.element(find.byWidget(img).first));
            } catch (_) {}
          }
        });
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<void> shot(String name) => expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../build/size_audit/kulayflow_$name.png'));

      await settle(2);
      await shot('1_categories');

      await tester.tap(find.text(loc.catAnimals));
      await settle();
      await tester.tap(find.text(loc.pagePuppy));
      await settle(3);
      await shot('2_canvas');

      // Color a little: a few strokes across the puppy.
      final board = tester.getRect(find.byType(InteractiveViewer));
      for (final dy in [0.45, 0.55, 0.65]) {
        await tester.dragFrom(
            Offset(
                board.left + board.width * 0.3, board.top + board.height * dy),
            Offset(board.width * 0.4, 0));
        await settle();
      }
      await shot('2b_colored');
      await tester.tap(find.text(loc.finishColoring));
      await settle(3);
      await shot('3_finished');

      await tester.tap(find.text(loc.colorMore));
      await settle();
      await shot('3b_after_bake');
      await tester.tap(find.text(loc.clear));
      await settle();
      await shot('4_clear_question');

      await tester.tap(find.text(loc.startOverYes));
      await settle();
      await shot('5_cleared');

      await tester.tap(find.text(loc.undo).last);
      await settle(2);
      await shot('6_undone');
      await tester.pump(const Duration(seconds: 8));
    } finally {
      FlutterError.onError = original;
    }
  });
}
