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
///   flutter test --update-goldens test/modal_preview.dart
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
      await tester.binding.setSurfaceSize(const Size(420, 900));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Container(
          color: const Color(0xFFEFEDF7),
          child: SuccessModal(
            title: 'Nakumpleto ang Level 7!',
            subtitle: 'Pagkakasunod ng Numero',
            score: 50,
            stars: stars,
            streak: 1,
            primaryLabel: 'Tapos',
            onPrimaryTap: () {},
            secondaryLabel: 'Bumalik',
            onSecondaryTap: () {},
          ),
        ),
      ));
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
