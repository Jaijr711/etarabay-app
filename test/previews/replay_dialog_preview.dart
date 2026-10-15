import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/replay_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "Finished already!" card, with three stars and points (Numbers) and
/// with one star and none (Tandaan), in English and Filipino. Not part of the
/// suite — run by hand:
///
///   flutter test --update-goldens test/previews/replay_dialog_preview.dart
void main() {
  setUpAll(() async {
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    final fredoka = File('assets/fonts/Fredoka.ttf');
    final fb = ByteData.view(fredoka.readAsBytesSync().buffer);
    await (FontLoader('Fredoka')..addFont(Future.value(fb))).load();
  });

  for (final c in [
    ('en', 3, 50),
    ('fil', 1, null),
  ]) {
    testWidgets('replay ${c.$1}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 820));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        locale: Locale(c.$1),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFEDF7),
            body: Center(
              child: ElevatedButton(
                onPressed: () => showReplayDialog(context,
                    stars: c.$2, points: c.$3, onRepeat: () {}),
                child: const Text('open'),
              ),
            ),
          );
        }),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.runAsync(() async {
        for (final e in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(e.image, tester.element(find.byWidget(e)));
        }
      });
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../docs/previews/replay_${c.$1}.png'));
    });
  }
}
