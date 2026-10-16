import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Color Fun, walked through: the drawing screen, Start over?, Rate
/// Artwork, a saved picture's viewer and Delete Artwork. Not part of the
/// suite — run by hand:
///
///   flutter test --update-goldens test/previews/kulay_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('kulay').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    final fb = ByteData.view(
        File('assets/fonts/Fredoka.ttf').readAsBytesSync().buffer);
    await (FontLoader('Fredoka')..addFont(Future.value(fb))).load();
  });

  testWidgets('color fun', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    try {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(400, 820));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const KulayScreen(),
        ),
      ));
      Future<void> settle() async {
        await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(img.image, tester.element(find.byWidget(img)),
                onError: (_, __) {});
          }
        });
        await tester.pump(const Duration(milliseconds: 200));
      }

      Future<void> shot(String name) => expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../docs/previews/kulay_$name.png'));

      await settle();
      await tester.tap(find.text('Puppy').first);
      await settle();
      await shot('draw');

      await tester.tap(find.text('Clear').first);
      await settle();
      await shot('clear');
      await tester.tap(find.text('No, keep it').first, warnIfMissed: false);
      await settle();

      // A tap on the puppy's body fills it, then save.
      final canvas = tester.getRect(find.byType(RawImage).first);
      await tester.tapAt(canvas.center + Offset(0, canvas.height * 0.15));
      await settle();
      await tester.tap(find.text('Save').first);
      await settle();
      await settle();
      await shot('rate');
      await tester.tap(find.byType(Image).at(3), warnIfMissed: false);
      await settle();
      await tester.tap(find.text('Done').last);
      await settle();
      await settle();

      await tester.tap(find.text('My Creations').first);
      await settle();
      await tester.tap(find.text('Puppy').first);
      await settle();
      await shot('view');
      await tester.tap(find.text('Delete').last);
      await settle();
      await shot('delete');
      await tester.tap(find.text('Delete').last);
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      await shot('deleted');
    } finally {
      FlutterError.onError = original;
    }
  });
}
