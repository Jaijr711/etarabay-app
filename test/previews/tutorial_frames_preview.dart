import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/update_checker.dart';
import 'package:e_tarabay/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The update notice in Filipino at phone size, for the install tutorial
/// video on the website. The page behind it is left clear, so the video
/// lays the real app screen underneath. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/tutorial_frames_preview.dart
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
    // Without the real icon font every icon draws as a box.
    final icons = File(r'C:\develop\flutter\bin\cache\artifacts\material_fonts'
        r'\materialicons-regular.otf');
    if (icons.existsSync()) {
      final bytes = ByteData.view(icons.readAsBytesSync().buffer);
      await (FontLoader('MaterialIcons')..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('update dialog, Filipino', (tester) async {
    // A 412 × 892 phone at 2.625× (1081 × 2341 px), the shape of the
    // website screenshots the video uses.
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1081.5, 2341.5);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
          fontFamily: 'Roboto', scaffoldBackgroundColor: Colors.transparent),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fil'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
                onPressed: () => showUpdateAvailableDialog(
                    context,
                    const UpdateInfo(
                        versionName: '1.2.57',
                        pageUrl: 'x',
                        notes: 'Bago\n'
                            '- Mas madaling sundan ang mga aralin.\n\n'
                            'Mga Ayos\n- Mas mabilis magbukas ang app.')),
                child: const Text('open',
                    style: TextStyle(color: Colors.transparent))),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../../docs/previews/tutorial_update_dialog.png'));
  });
}
