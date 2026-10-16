import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/update_checker.dart';
import 'package:e_tarabay/widgets/background_permission_dialog.dart';
import 'package:e_tarabay/widgets/locked_module_dialog.dart';
import 'package:e_tarabay/widgets/success_modal.dart';
import 'package:e_tarabay/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The student-side pop-ups in the card style. Not part of the suite — run
/// by hand:
///
///   flutter test --update-goldens test/previews/popups_preview.dart
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

  final cases = <String, void Function(BuildContext)>{
    'update': (c) => showUpdateAvailableDialog(
        c,
        const UpdateInfo(
            versionName: '1.2.51',
            apkUrl: 'x',
            notes: 'Bago\n\n- Bagong itsura ng Color Fun.\n- Pumili ng avatar.')),
    'locked': (c) => showLockedModuleDialog(c),
    'permission': (c) => showBackgroundPermissionDialog(c),
  };

  for (final e in cases.entries) {
    testWidgets(e.key, (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 820));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                  onPressed: () => e.value(context), child: const Text('open')),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../docs/previews/popup_${e.key}.png'));
    });
  }

  testWidgets('stars', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SuccessModal(
          title: 'Level 4 Completed!',
          subtitle: 'My Preferences',
          score: 40,
          stars: 2,
          primaryLabel: 'Next',
          onPrimaryTap: () {},
          secondaryLabel: 'Repeat',
          onSecondaryTap: () {},
        ),
      ),
    ));
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.tap(find.textContaining('2/3').first);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../../docs/previews/popup_stars.png'));
  });
}
