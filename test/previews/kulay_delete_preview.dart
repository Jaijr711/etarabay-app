import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deleting a drawing deletes every saved copy of its page: the card goes
/// back to blank and unticked. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/kulay_delete_preview.dart
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

  testWidgets('delete clears the page', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      SharedPreferences.setMockInitialValues({});
      Map<String, dynamic> puppy(int date) => {
            'name': 'Puppy',
            'date': date,
            'thumbnailPath': '',
            'sourcePagePath': 'assets/images/paint1.png',
            'base64Image': '',
            'strokes': [],
            'stars': 3,
          };
      await tester
          .runAsync(() => Hive.box('userProgress').put('coloring_creations', [
                puppy(1),
                puppy(2),
                {
                  'name': 'Cat',
                  'date': 3,
                  'thumbnailPath': '',
                  'sourcePagePath': 'assets/images/paint2.png',
                  'base64Image': '',
                  'strokes': [],
                  'stars': 3,
                }
              ]));
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
            .runAsync(() => Future.delayed(const Duration(milliseconds: 1200)));
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await settle();
      expect(find.byIcon(LucideIcons.check), findsNWidgets(2),
          reason: 'Puppy and Cat start ticked');

      await tester.tap(find.text('My Creations'));
      await settle();
      await tester.tap(find.text('Puppy').first);
      await settle();
      await tester.tap(find.text('Delete').first);
      await settle();
      await tester.tap(find.text('Delete').last);
      await settle();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await settle();

      final left = await tester.runAsync(() async =>
          (Hive.box('userProgress').get('coloring_creations') as List)
              .map((c) => (c as Map)['name'])
              .toList());
      expect(left, ['Cat'], reason: 'both Puppy copies deleted, Cat kept');

      await tester.tap(find.text('Color'));
      await settle();
      expect(find.byIcon(LucideIcons.check), findsOneWidget,
          reason: 'only Cat is still ticked');
      await expectLater(find.byKey(const ValueKey('shot')),
          matchesGoldenFile('../../docs/previews/kulay_after_delete.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    } finally {
      FlutterError.onError = original;
    }
  });
}
