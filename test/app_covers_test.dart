import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/widgets/account_watcher.dart';
import 'package:e_tarabay/widgets/app_covers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A screen with something to lose: a count the child has tapped up.
class _Game extends StatefulWidget {
  const _Game();

  @override
  State<_Game> createState() => _GameState();
}

class _GameState extends State<_Game> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => setState(() => taps++),
            child: Text('taps $taps'),
          ),
        ),
      );
}

/// The developers' two covers over the whole app: maintenance over a
/// child's, and "update first" over everyone's.
void main() {
  late UserProvider user;

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('covers').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> open(WidgetTester tester, {String? role}) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    user = UserProvider();
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: user),
        ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
        ChangeNotifierProvider<AudioManager>.value(
            value: AudioManager.instance),
      ],
      child: MaterialApp(
        navigatorKey: nav,
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            AccountWatcher(navigatorKey: nav, child: child!),
        home: const _Game(),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (role != null) user.setCurrentRole(role);
    await tester.pump();
  }

  Future<void> set(WidgetTester tester, Map<String, dynamic> config,
      {String installed = '1.2.57'}) async {
    user.debugSetConfig(config, installedVersion: installed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  const note = 'Inaayos namin ang E-Tarabay. Balik ka mamaya!';
  // By the cover itself: its title is drawn in three layers.
  final covered = find.byType(MaintenanceCover);

  testWidgets("maintenance covers a child's app, and lifts with its place kept",
      (tester) async {
    await open(tester, role: 'student');
    await tester.tap(find.text('taps 0'));
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);

    await set(tester, {'maintenanceOn': true, 'maintenanceMessage': note});
    expect(covered, findsOneWidget);
    expect(find.text(note), findsOneWidget);
    // Nothing under it can be played.
    await tester.tapAt(tester.getCenter(find.text('taps 1')));
    await tester.pump();

    await set(tester, {'maintenanceOn': false});
    expect(covered, findsNothing);
    // The same screen, the count where it was: not rebuilt from nothing,
    // and not tapped through the cover.
    expect(find.text('taps 1'), findsOneWidget);
    await close(tester);
  });

  testWidgets("maintenance leaves the teacher's side open", (tester) async {
    await open(tester, role: 'teacher');
    await set(tester, {'maintenanceOn': true, 'maintenanceMessage': note});
    expect(covered, findsNothing);
    await close(tester);
  });

  testWidgets('maintenance leaves the login open, with nobody signed in',
      (tester) async {
    await open(tester);
    await set(tester, {'maintenanceOn': true, 'maintenanceMessage': note});
    expect(covered, findsNothing);
    await close(tester);
  });

  final mustUpdate = find.byType(UpdateRequiredCover);

  for (final role in [null, 'student', 'teacher']) {
    testWidgets('an older version is covered for ${role ?? 'nobody'}',
        (tester) async {
      await open(tester, role: role);
      await set(tester, {'minVersion': '1.2.57'}, installed: '1.2.56');
      expect(mustUpdate, findsOneWidget);
      expect(find.textContaining('bersyon 1.2.57'), findsOneWidget);

      await set(tester, {}, installed: '1.2.56');
      expect(mustUpdate, findsNothing);
      await close(tester);
    });
  }

  testWidgets('the update cover comes before maintenance', (tester) async {
    await open(tester, role: 'student');
    await set(
        tester,
        {
          'minVersion': '1.2.57',
          'maintenanceOn': true,
          'maintenanceMessage': note,
        },
        installed: '1.2.56');
    expect(mustUpdate, findsOneWidget);
    expect(covered, findsNothing);
    await close(tester);
  });

  testWidgets('the version asked for, or newer, is not covered',
      (tester) async {
    await open(tester, role: 'teacher');
    await set(tester, {'minVersion': '1.2.57'}, installed: '1.2.57');
    expect(mustUpdate, findsNothing);
    await set(tester, {'minVersion': '1.2.57'}, installed: '1.3.0');
    expect(mustUpdate, findsNothing);
    await close(tester);
  });
}
