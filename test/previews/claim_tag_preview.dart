import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/widgets/shelf_medal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the "Claim!" tag sits on the shelf, and the shelf after the medal
/// is taken: the wood must not move. Shots in build/previews/claim_tag/.
///
///   flutter test test/previews/claim_tag_preview.dart
void main() {
  setUpAll(() async {
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf'
        ]
      ),
      ('Fredoka', ['assets/fonts/Fredoka.ttf']),
      (
        'MaterialIcons',
        [
          r'C:\develop\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
        ]
      ),
      (
        'packages/flutter_lucide/lucide',
        [
          r'C:\Users\jayjr\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_lucide-1.11.0\lib\fonts\lucide.ttf'
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

  final out = Directory('build/previews/claim_tag')
    ..createSync(recursive: true);

  for (final (name, placement, claimed) in const [
    ('1_top', 'top', ['alphabet']),
    ('2_corner', 'corner', ['alphabet']),
    ('3_after', 'top', ['alphabet', 'firstSteps', 'numbers']),
  ]) {
    testWidgets(name, (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      addTearDown(() => FlutterError.onError = original);
      ShelfMedal.tagPlacement = placement;
      await tester.runAsync(() async {
        Hive.init(Directory.systemTemp.createTempSync('tag').path);
        final box = await Hive.openBox('userProfile');
        await Hive.openBox('userProgress');
        await box.put('currentUser', {
          'name': 'Ana Mendoza Reyes',
          'gender': 'female',
          'birthday': DateTime(2021, 5, 3).toIso8601String(),
          'createdAt': DateTime(2026, 9, 6).toIso8601String(),
          'avatar': 'animal_bunny',
          'stars': 45,
          'achievements': {'firstSteps': 3, 'alphabet': 2, 'numbers': 3},
          'claimedBadges': claimed,
        });
      });
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(720, 1520);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
            ChangeNotifierProvider<AudioManager>.value(
                value: AudioManager.instance),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto'),
            locale: const Locale('fil'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AwardsScreen(),
          ),
        ),
      ));
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() async {
        for (final img in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(
              img.image, tester.element(find.byWidget(img).first));
        }
      });
      // Past the wiggle, so the medals stand still for the shot.
      await tester.pump(const Duration(milliseconds: 1200));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      await tester.runAsync(() => Hive.close());
    });
  }
}
