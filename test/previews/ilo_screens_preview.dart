import 'dart:io';

import 'package:e_tarabay/data/magbasa_content.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/screens/choose_avatar_screen.dart';
import 'package:e_tarabay/screens/home_screen.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:e_tarabay/screens/magbasa_screen.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/profile_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:e_tarabay/widgets/pressable.dart';
import 'package:e_tarabay/widgets/system_bars_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screens on a small phone that draws edge to edge (Android 15+, which
/// this app targets): a 24dp status bar over the top and a 48dp three-button
/// navigation bar over the bottom, both drawn into the shot so anything they
/// would cover shows. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/insets_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('insets').path);
    final box = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await box.put('currentUser', {
      'name': 'Jay R. Dolores',
      'gender': 'male',
      'birthday': DateTime(2022, 9, 23).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_lion',
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

  final song = MagbasaContent.getSongData()['ania_ti_naganmo_full']!;
  final cases = <String, (Widget, Future<void> Function(WidgetTester)?)>{
    'home': (const HomeScreen(), null),
    'lessons': (const LessonsScreen(), null),
    'numbers_levels': (const MatematikaScreen(), null),
    'numbers_count': (
      const MatematikaScreen(),
      (t) async => t.tap(find.byType(Pressable).at(0))
    ),
    'numbers_drag': (
      const MatematikaScreen(),
      (t) async => t.tap(find.byType(Pressable).at(1))
    ),
    for (final i in [2, 3, 4, 5, 6])
      'numbers_game$i': (
        const MatematikaScreen(),
        (t) async {
          await t.ensureVisible(find.byType(Pressable).at(i));
          await t.pump();
          await t.tap(find.byType(Pressable).at(i));
        }
      ),
    'pamilya': (const PamilyaScreen(), null),
    'pamilya_game': (
      const PamilyaScreen(),
      (t) async => t.tap(find.byType(Pressable).first)
    ),
    'kulay': (
      const KulayScreen(),
      (t) async => t.tap(find.byType(Pressable).first)
    ),
    'tandaan': (const TandaanScreen(), null),
    'trace': (const TraceItScreen(), null),
    'magbasa': (const MagbasaScreen(), null),
    'song': (SongScreen(songTitle: song['title'], songData: song), null),
    'awards': (const AwardsScreen(), null),
    'profile': (const ProfileScreen(), null),
    'avatar': (const ChooseAvatarScreen(), null),
  };

  for (final e in cases.entries) {
    testWidgets(e.key, (tester) async {
      final original = FlutterError.onError;
      final overflows = <String>[];
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        final s = d.exceptionAsString();
        if (s.contains('overflowed')) {
          overflows.add(s.split('\n').first);
          return;
        }
        // Anything else a test environment cannot provide is not the point.
        // ignore: avoid_print
        print('ERR ${e.key}: ${s.split('\n').take(3).join(' / ')}');
      };
      try {
        SharedPreferences.setMockInitialValues({});
        const dpr = 3.0;
        tester.view.devicePixelRatio = dpr;
        tester.view.physicalSize = const Size(360 * dpr, 640 * dpr);
        tester.view.padding =
            const FakeViewPadding(top: 24 * dpr, bottom: 48 * dpr);
        tester.view.viewPadding =
            const FakeViewPadding(top: 24 * dpr, bottom: 48 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('shot'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(children: [
              MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => UserProvider()),
                  ChangeNotifierProvider(
                      create: (_) => LanguageProvider('ilo')),
                  ChangeNotifierProvider<AudioManager>.value(
                      value: AudioManager.instance),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(fontFamily: 'Roboto'),
                  // As the app does: Material has no Ilokano, so English.
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    _MaterialFallback(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('ilo'),
                  builder: (_, child) => SystemBarsGuard(child: child!),
                  home: e.value.$1,
                ),
              ),
              // What the phone itself draws over the app.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 24,
                child: IgnorePointer(
                    child: Container(color: Colors.black.withOpacity(0.55))),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 48,
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        Icon(Icons.circle_outlined, color: Colors.white),
                        Icon(Icons.crop_square, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ));
        Future<void> settle() async {
          await tester.runAsync(
              () => Future.delayed(const Duration(milliseconds: 1500)));
          for (int i = 0; i < 6; i++) {
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

        await settle();
        final act = e.value.$2;
        if (act != null) {
          await act(tester);
          await settle();
        }
        await expectLater(find.byKey(const ValueKey('shot')),
            matchesGoldenFile('../../docs/previews/ilo_${e.key}.png'));
      } finally {
        FlutterError.onError = original;
        // ignore: avoid_print
        print('OVERFLOW ${e.key}: ${overflows.toSet().join(' | ')}');
      }
    });
  }
}

class _MaterialFallback extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(
          GlobalMaterialLocalizations.delegate.isSupported(locale)
              ? locale
              : const Locale('en'));

  @override
  bool shouldReload(_MaterialFallback old) => false;
}
