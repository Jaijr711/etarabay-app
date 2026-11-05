import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/screens/certificates_screen.dart';
import 'package:e_tarabay/widgets/kid_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Awards and My Certificate keep their header still, as Lessons and
/// Settings do: it used to be the first thing in the scrolling list, so it
/// slid away with the medals and played in with them.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('kid_header').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  for (final entry in {
    'Awards': () => const AwardsScreen(),
    'My Certificate': () => const CertificatesScreen(),
  }.entries) {
    testWidgets('${entry.key} keeps its header still when the list scrolls',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        original?.call(d);
      };
      addTearDown(() => FlutterError.onError = original);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
          ChangeNotifierProvider<AudioManager>.value(
              value: AudioManager.instance),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: entry.value(),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));

      final header = find.byType(KidPageHeader);
      expect(header, findsOneWidget);
      final before = tester.getTopLeft(header);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(header), before);
      // Let the medals' staggered entrances finish before the tree goes.
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
