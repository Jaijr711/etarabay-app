import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_tarabay/data/badge_catalog.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/badge_claim_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The claim animation, frame by frame at 30 fps, at a phone's size. The
/// frames land in build/previews/claim/ for ffmpeg to join with the sound:
///
///   flutter test test/previews/badge_claim_preview.dart
void main() {
  setUpAll(() async {
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf',
        ]
      ),
      ('Fredoka', ['assets/fonts/Fredoka.ttf']),
      (
        'MaterialIcons',
        [
          r'C:\develop\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
        ]
      ),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) {
          loader
              .addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
        }
      }
      await loader.load();
    }
  });

  testWidgets('the claim, frame by frame', (tester) async {
    final out = Directory('build/previews/claim')..createSync(recursive: true);
    for (final f in out.listSync()) {
      f.deleteSync();
    }
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 1520);
    addTearDown(tester.view.reset);
    final badge = badgeCatalog.first;
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Container(
          // The awards shelf's warm wood, darkened as the dialog does.
          color: const Color(0xFF2A1C10),
          child: BadgeClaimCelebration(
            icon: badge.icon,
            image: badge.image,
            color: Color(badge.color),
            tier: 3,
            title: 'Unang Hakbang',
            autoClose: false,
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    for (var i = 0; i < 96; i++) {
      await tester.pump(const Duration(milliseconds: 33));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/f${i.toString().padLeft(3, '0')}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
