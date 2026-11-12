import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/update_checker.dart';
import 'package:e_tarabay/widgets/update_dialog.dart';
import 'package:e_tarabay/widgets/update_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The in-app update: the offer, the download, the one permission and the
/// failure, at a phone's size. The shots land in build/previews/update/.
///
///   flutter test test/previews/update_flow_preview.dart
void main() {
  setUpAll(() async {
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-medium.ttf',
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
          loader.addFont(
              Future.value(ByteData.view(f.readAsBytesSync().buffer)));
        }
      }
      await loader.load();
    }
  });

  final out = Directory('build/previews/update')..createSync(recursive: true);
  const update = UpdateInfo(
    versionName: '1.2.62',
    pageUrl: 'https://example.invalid',
    notes: 'Mga Ayos\n\n- Ang update ay sa loob na ng app: '
        'hindi na naiipon ang mga APK sa Downloads.',
    apkUrl: 'https://example.invalid/E-Tarabay.apk',
    apkSize: 122902714,
    // A patch, as a real update from 1.2.61 on has: the size shown is its own.
    patch: PatchInfo(
      url: 'https://example.invalid/E-Tarabay.patch',
      size: 2254857,
      fromSha256: '',
      toSha256: '',
      toSize: 122902714,
    ),
  );
  final ops = UpdateOps(
    download: (u, p, c, r) async => File('x'),
    canInstall: () async => true,
    openInstallSettings: () async {},
    install: (_) async {},
    openWebsite: (_) async => true,
  );

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<BuildContext> open(WidgetTester tester, GlobalKey key) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 1520);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(backgroundColor: Color(0xFFEFEDF7)),
      ),
    ));
    return tester.element(find.byType(Scaffold));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the offer', (tester) async {
    final key = GlobalKey();
    final context = await open(tester, key);
    showUpdateAvailableDialog(context, update);
    await settle(tester);
    await shot(tester, key, '1_offer');
  });

  for (final (name, stage, progress) in const [
    ('2_downloading', UpdateStage.downloading, 0.45),
    ('3_permission', UpdateStage.needsPermission, null),
    ('4_ready', UpdateStage.ready, null),
    ('5_failed', UpdateStage.failed, null),
  ]) {
    testWidgets(name, (tester) async {
      final key = GlobalKey();
      final context = await open(tester, key);
      showDialog<void>(
        context: context,
        builder: (_) => UpdateFlowDialog(
            update: update,
            ops: ops,
            debugStage: stage,
            debugProgress: progress),
      );
      await settle(tester);
      await shot(tester, key, name);
    });
  }
}
