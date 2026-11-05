import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/models/certificate_model.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/certificates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The certificate a child gets once everything is finished: the list with
/// the earned card, and the certificate itself as it opens, in landscape.
/// Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/certificate_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('certificate').path);
    final box = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await box.put('currentUser', {
      'name': 'Ana Mendoza Reyes',
      // The Student Number line reads this; it comes from the child's record
      // when they sign in.
      'lrn': 'DC-2026-0001',
      'gender': 'female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 180,
      'achievements': {for (final id in UserProvider.graduateBadgeIds) id: 3},
      'claimedBadges': UserProvider.graduateBadgeIds,
      'certificates': ['e_tarabay_graduate'],
      'certificateAwardedAt': {
        'e_tarabay_graduate': DateTime(2026, 11, 3).millisecondsSinceEpoch,
      },
    });
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

  Future<void> shoot(WidgetTester tester, String lang, Size size, Widget home,
      String name) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    try {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = size * 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider(lang)),
          ChangeNotifierProvider<AudioManager>.value(
              value: AudioManager.instance),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
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
      // Past the confetti, so the certificate is seen as it settles.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../build/size_audit/${name}_$lang.png'));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  for (final lang in ['fil', 'en']) {
    testWidgets('certificate list $lang', (tester) async {
      await shoot(tester, lang, const Size(380, 900),
          const CertificatesScreen(), 'certificate_list');
    });
    testWidgets('certificate detail $lang', (tester) async {
      await shoot(
          tester,
          lang,
          const Size(844, 390),
          CertificateDetailScreen(
            certificate: allCertificates['e_tarabay_graduate']!,
            langCode: lang,
          ),
          'certificate_detail');
    });
  }
}
