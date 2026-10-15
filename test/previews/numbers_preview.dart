import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the first question of every Numbers level, so the boards can be
/// looked at instead of imagined. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/numbers_preview.dart
void main() {
  setUpAll(() async {
    // The profile and progress boxes, in a scratch folder.
    // Opened here, for real: inside a widget test the file IO would never
    // finish, and the provider finds them already open.
    Hive.init(Directory.systemTemp.createTempSync('numbers_preview').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  for (final level in [0, 1, 2, 3, 4, 5, 6]) {
    testWidgets('level $level', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatematikaScreen(),
        ),
      ));
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      // The level cards, in order.
      final cards = find.byType(Pressable);
      await tester.tap(cards.at(level));
      await tester.binding.setSurfaceSize(const Size(400, 820));
      await tester.runAsync(() async {
        for (final e in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(e.image, tester.element(find.byWidget(e)));
        }
      });
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.runAsync(() async {
        for (final e in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(e.image, tester.element(find.byWidget(e)));
        }
      });
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(find.byType(MatematikaScreen),
          matchesGoldenFile('../../docs/previews/numbers_$level.png'));
    });
  }
}
