import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/home_screen.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/services/device_performance.dart';
import 'package:e_tarabay/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remember It's 3D cards face up (the look at the start) and face down, and
/// the Home card with its new picture. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/tandaan_cards_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('tandaancards').path);
    final box = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await box.put('currentUser', {
      'name': 'Ana',
      'gender': 'Female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 12,
    });
    for (final (family, file) in const [
      ('Roboto', r'C:\Windows\Fonts\arialbd.ttf'),
      ('Fredoka', 'assets/fonts/Fredoka.ttf'),
    ]) {
      final f = File(file);
      if (!f.existsSync()) continue;
      final bytes = ByteData.view(f.readAsBytesSync().buffer);
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }
  });

  Future<void> show(WidgetTester tester, Widget screen) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(360, 760) * 2;
    addTearDown(tester.view.reset);
    final theme = appTheme();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
        ChangeNotifierProvider<AudioManager>.value(value: AudioManager.instance),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> sharpen(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        try {
          await precacheImage(img.image, tester.element(find.byWidget(img).first));
        } catch (_) {}
      }
    });
    await tester.pump(const Duration(milliseconds: 50));
  }

  for (final (name, deck) in const [('hugis', 2), ('titik', 3)]) {
    testWidgets('cards $name', (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      try {
        await show(tester, const TandaanScreen());
        await tester.tap(find.byType(Pressable).at(deck));
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        await sharpen(tester);
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../build/size_audit/cards_${name}_up.png'));
        // Past the look at the start: every card turns face down.
        for (int i = 0; i < 80; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await sharpen(tester);
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../build/size_audit/cards_${name}_down.png'));
        await tester.pump(const Duration(seconds: 5));
      } finally {
        FlutterError.onError = original;
      }
    });
  }

  testWidgets('lessons', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    try {
      await show(tester, const LessonsScreen());
      await tester.scrollUntilVisible(
          find.text('Tandaan!'), 200, scrollable: find.byType(Scrollable).first);
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await sharpen(tester);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../build/size_audit/lessons_tandaan.png'));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  });

  testWidgets('home lite', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    DevicePerformance.lite.value = true;
    try {
      await show(tester, const HomeScreen());
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await sharpen(tester);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../build/size_audit/home_lite.png'));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      DevicePerformance.lite.value = false;
      FlutterError.onError = original;
    }
  });

  testWidgets('home', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    try {
      await show(tester, const HomeScreen());
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await sharpen(tester);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../build/size_audit/home_tandaan.png'));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  });
}
