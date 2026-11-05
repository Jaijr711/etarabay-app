import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/for_parents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A new child once showed stars they never earned. Two ways in: the next
/// child to sign in on a device kept the last one's local work, and the
/// teacher's report read some modules from the device instead of the child.
void main() {
  group('signing a child in on a shared device', () {
    test("another child's work is cleared first", () {
      expect(
          UserProvider.shouldClearLocalData(owner: 'child-a', newId: 'child-b'),
          isTrue);
    });

    test('the same child keeps their own work', () {
      expect(
          UserProvider.shouldClearLocalData(owner: 'child-a', newId: 'child-a'),
          isFalse);
    });

    test('work of unknown owner is cleared, never inherited', () {
      expect(UserProvider.shouldClearLocalData(owner: null, newId: 'child-b'),
          isTrue);
    });
  });

  testWidgets(
      "the teacher's report of a new child shows none of this device's stars",
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(Directory.systemTemp.createTempSync('other_child').path);
      await Hive.openBox('userProfile');
      await Hive.openBox('userProgress');
    });
    // The child who last played on this device did well at Remember It.
    SharedPreferences.setMockInitialValues({
      'tandaan_cat_0_stars': 3,
      'tandaan_cat_1_stars': 3,
      'tandaan_cat_2_stars': 2,
    });
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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
        ChangeNotifierProvider<AudioManager>.value(value: AudioManager.instance),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: ForParentsScreen(
          viewStudentId: 'new-child',
          viewStudentName: 'New Child',
          viewStudentData: {'id': 'new-child', 'name': 'New Child'},
        ),
      ),
    ));
    // The cloud record cannot be fetched in a test; that is the case that
    // used to fall back to this device's own child.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.text('Remember It!').first;
    await tester.ensureVisible(row);
    await tester.pump();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Not yet started'), findsWidgets,
        reason: 'the header and every category, none of them started');
    final filled = tester
        .widgetList<Icon>(find.byIcon(Icons.star_rounded))
        .where((i) => i.color == const Color(0xFFF5A623));
    expect(filled, isEmpty,
        reason: 'stars from the last child on this device');
  });

  testWidgets("a record without its star totals still says what's possible",
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(Directory.systemTemp.createTempSync('other_child_total').path);
      await Hive.openBox('userProfile');
      await Hive.openBox('userProgress');
    });
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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
        ChangeNotifierProvider<AudioManager>.value(value: AudioManager.instance),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: ForParentsScreen(
          viewStudentId: 'new-child',
          viewStudentName: 'New Child',
          viewStudentData: {'id': 'new-child', 'name': 'New Child'},
        ),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.text('Numbers').first;
    await tester.ensureVisible(row);
    await tester.pump();
    await tester.tap(row);
    await tester.pumpAndSettle();

    // Was "0 of 0 stars".
    expect(find.text('of ${UserProvider.matematikaStarCeiling} stars'),
        findsOneWidget);
    expect(find.text('of 0 stars'), findsNothing);
  });
}
