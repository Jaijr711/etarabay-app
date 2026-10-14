import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the level-complete card at one, two and three stars, so the
/// difference between them can be looked at instead of imagined. Not part of
/// the suite — run by hand:
///
///   flutter test --update-goldens test/previews/modal_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  for (final stars in [1, 2, 3]) {
    testWidgets('card at $stars', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 860));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Container(
          color: const Color(0xFFEFEDF7),
          child: SuccessModal(
            title: 'Level 4 Completed!',
            subtitle: 'My Preferences',
            score: 40,
            stars: stars,
            // The design has no streak; show one on the one-star card.
            streak: stars == 1 ? 1 : null,
            primaryLabel: 'Finished! 🏆',
            onPrimaryTap: () {},
            secondaryLabel: 'Repeat',
            onSecondaryTap: () {},
          ),
        ),
      ));
      // The card's pictures are real assets; load them before the shot. Only
      // the loading runs in real time — the animations' timers must stay on
      // the test's clock, or the pumps below never start them.
      await tester.runAsync(() async {
        for (final e in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(e.image, tester.element(find.byWidget(e)));
        }
      });
      // In steps, not one jump: each star's entrance is started by a timer,
      // and a timer that fires inside a frame still needs later frames to
      // drive the animation it started.
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await expectLater(find.byType(SuccessModal),
          matchesGoldenFile('../../docs/previews/modal_$stars.png'));
    });
  }
}
