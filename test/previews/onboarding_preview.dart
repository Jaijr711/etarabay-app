import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four onboarding pages on a small edge-to-edge phone, in the
/// longest language (Ilocano) and in Filipino. Not part of the suite — run
/// by hand:
///
///   flutter test --update-goldens test/previews/onboarding_preview.dart
void main() {
  setUpAll(() async {
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    final fb = ByteData.view(
        File('assets/fonts/Fredoka.ttf').readAsBytesSync().buffer);
    await (FontLoader('Fredoka')..addFont(Future.value(fb))).load();
  });

  for (final lang in ['ilo', 'fil']) {
    for (int page = 0; page < 4; page++) {
      testWidgets('$lang page $page', (tester) async {
        final original = FlutterError.onError;
        final overflows = <String>[];
        FlutterError.onError = (d) {
          if (d.exception is MissingPluginException) return;
          final s = d.exceptionAsString();
          if (s.contains('overflowed')) overflows.add(s.split('\n').first);
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
                ChangeNotifierProvider(
                  create: (_) => LanguageProvider(lang),
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData(fontFamily: 'Roboto'),
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      _MaterialFallback(),
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: Locale(lang),
                    home: const OnboardingScreen(),
                  ),
                ),
                // What the phone itself draws over the app.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 24,
                  child: IgnorePointer(
                      child: Container(color: const Color(0x8C000000))),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 48,
                  child: IgnorePointer(
                      child: Container(color: const Color(0x8C000000))),
                ),
              ]),
            ),
          ));
          Future<void> settle() async {
            for (int i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 150));
            }
            await tester.runAsync(() async {
              for (final img in tester.widgetList<Image>(find.byType(Image))) {
                await precacheImage(
                    img.image, tester.element(find.byWidget(img)),
                    onError: (_, __) {});
              }
            });
            await tester.pump(const Duration(milliseconds: 200));
          }

          await settle();
          for (int i = 0; i < page; i++) {
            await tester.tap(find.byType(ElevatedButton));
            await settle();
          }
          await expectLater(find.byKey(const ValueKey('shot')),
              matchesGoldenFile('../../build/onboarding_previews/${lang}_$page.png'));
        } finally {
          FlutterError.onError = original;
          // ignore: avoid_print
          print('OVERFLOW $lang $page: ${overflows.toSet().join(' | ')}');
        }
      });
    }
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
