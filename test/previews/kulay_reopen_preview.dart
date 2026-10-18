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

/// A page colored, saved, and opened again shows the saved coloring and
/// saves as an update. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/kulay_reopen_preview.dart
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

  testWidgets('saved page reopens colored', (tester) async {
    final original = FlutterError.onError;
    // What a test cannot provide (plugins, sound) is not the point.
    FlutterError.onError = (_) {};
    try {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(400 * 2, 800 * 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('shot'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
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
      await tester.tap(find.text('Puppy').first);
      await settle();
      expect(find.text('Save'), findsOneWidget);

      // A thick stroke across the middle of the picture.
      final c = tester.getCenter(find.byType(InteractiveViewer));
      final g = await tester.startGesture(c - const Offset(80, 0));
      for (int i = 1; i <= 16; i++) {
        await g
            .moveTo(c - const Offset(80, 0) + Offset(i * 10.0, 4.0 * (i % 3)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle();

      await tester.tap(find.text('Save'));
      // Saving writes files: give it real time until the rating shows.
      for (int i = 0; i < 10 && find.text('Done').evaluate().isEmpty; i++) {
        await settle();
      }
      // The star rating that follows a first save.
      await tester.tap(find.text('Done'));
      await settle();
      // The "Saved" note closes itself.
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await settle();

      // Open the same page again.
      await tester.tap(find.text('Puppy').first);
      await settle();
      expect(find.text('Update'), findsOneWidget,
          reason: 'a saved page opens as its creation');
      expect(find.text('View'), findsNothing);
      await expectLater(find.byKey(const ValueKey('shot')),
          matchesGoldenFile('../../docs/previews/kulay_reopen.png'));

      // Add to it in blue, update, and open it once more: the change stays.
      final blue = tester.getCenter(find.byType(InteractiveViewer)) +
          const Offset(-50, 45);
      final g2 = await tester.startGesture(blue);
      for (int i = 1; i <= 12; i++) {
        await g2.moveTo(blue + Offset(i * 9.0, 2.0 * (i % 2)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g2.up();
      await settle();
      await tester.tap(find.text('Update'));
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await settle();
      await tester.tap(find.text('Puppy').first);
      await settle();
      expect(find.text('Update'), findsOneWidget);
      await expectLater(find.byKey(const ValueKey('shot')),
          matchesGoldenFile('../../docs/previews/kulay_reopen_updated.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    } finally {
      FlutterError.onError = original;
    }
  });
}
