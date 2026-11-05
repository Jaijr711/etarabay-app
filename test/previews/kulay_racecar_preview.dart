import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The soda can replaced by the race car: a soda creation saved on the
/// phone is deleted on opening Color Fun, the others stay, and the race car
/// colors inside its lines. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/kulay_racecar_preview.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final docs = Directory.systemTemp.createTempSync('kulay_docs').path;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Sound plays nothing here, and files go to a temp folder, as on a phone.
    for (final ch in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global'
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(ch), (_) async => null);
    }
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => docs);
    Hive.init(Directory.systemTemp.createTempSync('kulay').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
  });

  testWidgets('soda removed, race car colors', (tester) async {
    final original = FlutterError.onError;
    // What a test cannot provide (plugins, sound) is not the point.
    FlutterError.onError = (_) {};
    try {
      SharedPreferences.setMockInitialValues({});
      await tester
          .runAsync(() => Hive.box('userProgress').put('coloring_creations', [
                {
                  'name': 'Soda',
                  'date': 1,
                  'thumbnailPath': '',
                  'sourcePagePath': 'assets/images/paint9.png',
                  'base64Image': '',
                  'strokes': [],
                },
                {
                  'name': 'Teddy Bear',
                  'date': 2,
                  'thumbnailPath': '',
                  'sourcePagePath': 'assets/images/paint8.png',
                  'base64Image': '',
                  'strokes': [],
                },
              ]));
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(400 * 2, 800 * 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('shot'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider('ilo')),
            ChangeNotifierProvider<AudioManager>.value(
                value: AudioManager.instance),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const KulayScreen(),
          ),
        ),
      ));
      Future<void> settle() async {
        await tester
            .runAsync(() => Future.delayed(const Duration(milliseconds: 1500)));
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await settle();
      final left = (Hive.box('userProgress').get('coloring_creations') as List)
          .map((c) => (c as Map)['name'])
          .toList();
      expect(left, ['Teddy Bear'], reason: 'the soda creation is deleted');

      await tester.ensureVisible(find.text('Toys').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Toys').first);
      await settle();
      await expectLater(find.byKey(const ValueKey('shot')),
          matchesGoldenFile('../../docs/previews/racecar_toys.png'));

      await tester.tap(find.text('Race Car').first);
      await settle();
      final c = tester.getCenter(find.byType(InteractiveViewer));
      // Across the car's body, and a dab on a front wheel.
      final g = await tester.startGesture(c + const Offset(-10, 0));
      for (int i = 1; i <= 12; i++) {
        await g.moveTo(c + Offset(-10 + i * 8.0, 2.0 * (i % 2)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle();
      await expectLater(find.byKey(const ValueKey('shot')),
          matchesGoldenFile('../../docs/previews/racecar_colored.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    } finally {
      FlutterError.onError = original;
    }
  });
}
