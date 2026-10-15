import 'dart:io';

import 'package:e_tarabay/data/magbasa_content.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/magbasa_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The song, story and poem screens in the storybook look. Not part of the
/// suite — run by hand:
///
///   flutter test --update-goldens test/previews/storybook_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('storybook').path);
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

  final screens = <String, Widget Function()>{
    'song': () {
      final d = MagbasaContent.getSongData()['ania_ti_naganmo_full']!;
      return SongScreen(songTitle: d['title'], songData: d);
    },
    'story': () {
      final d = MagbasaContent.getStoryData()['ni_marti']!;
      return StoryScreen(storyTitle: d['title'], storyData: d);
    },
    'story_cover': () {
      final d = MagbasaContent.getStoryData()['ni_milio']!;
      return StoryScreen(storyTitle: d['title'], storyData: d);
    },
    'poem': () {
      final d = MagbasaContent.getPoemData()['sipsipat']!;
      return PoemScreen(poemTitle: d['title'], poemData: d);
    },
    'poem_long': () {
      final d = MagbasaContent.getPoemData()['ti_pusak']!;
      return PoemScreen(poemTitle: d['title'], poemData: d);
    },
  };

  for (final e in screens.entries) {
    testWidgets(e.key, (tester) async {
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
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: e.value(),
          ),
        ));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 2));
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(img.image, tester.element(find.byWidget(img)));
          }
        });
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../docs/previews/storybook_${e.key}.png'));
      } finally {
        FlutterError.onError = original;
      }
    });
  }
}
