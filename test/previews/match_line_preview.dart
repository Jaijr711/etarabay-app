import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Match with Line on a 360 phone: two lines joined and a group chosen, then
/// the board joined right and graded. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/match_line_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('lineprev').path);
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

  for (final graded in [false, true]) {
    testWidgets('line board ${graded ? 'graded' : 'joining'}', (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
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
            home: const MatematikaScreen(),
          ),
        ));
        await tester.pump(const Duration(seconds: 2));
        final loc = await AppLocalizations.delegate.load(const Locale('fil'));
        Future<void> beat([int n = 4]) async {
          for (int i = 0; i < n; i++) {
            await tester.pump(const Duration(milliseconds: 150));
          }
        }

        await tester.tap(find.text(loc.lineMatch));
        await beat();
        final boxes = find.byWidgetPredicate(
            (w) => w is GestureDetector && w.key is GlobalKey);
        Finder number(int n) =>
            find.descendant(of: boxes, matching: find.text('$n'));
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(
                img.image, tester.element(find.byWidget(img).first));
          }
        });
        final pairs = graded ? [0, 1, 2] : [0, 2];
        for (final i in pairs) {
          await tester.tap(boxes.at(i));
          await beat();
          await tester.tap(number(i + 1));
          await beat();
        }
        if (graded) {
          await beat(2);
        } else {
          await tester.tap(boxes.at(1));
          await beat(3);
        }
        // The lines draw themselves in on the real clock.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 700)));
        await tester.pump(const Duration(milliseconds: 16));
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                '../../build/size_audit/line_${graded ? 'graded' : 'joining'}.png'));
        await tester.pump(const Duration(seconds: 5));
      } finally {
        FlutterError.onError = original;
      }
    });
  }
}
