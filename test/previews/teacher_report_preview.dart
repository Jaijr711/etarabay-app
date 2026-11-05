import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/for_parents_screen.dart';
import 'package:e_tarabay/screens/student_login_card_screen.dart';
import 'package:e_tarabay/widgets/reset_progress_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The teacher's view of one child — the report, a module, the login card
/// and the reset sheet — on a small phone, with an invented child. Not part
/// of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/teacher_report_preview.dart
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('report').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    final fb = ByteData.view(
        File('assets/fonts/Fredoka.ttf').readAsBytesSync().buffer);
    await (FontLoader('Fredoka')..addFont(Future.value(fb))).load();
  });

  const child = {
    'id': 'sample-child',
    'name': 'Ana Mendoza Reyes',
    'username': 'ana4821',
    'lrn': 'DC-2026-4821',
    'password': 'DC-2026-4821',
    'avatar': 'girl1',
  };

  final cases = <String, (Widget, Future<void> Function(WidgetTester)?)>{
    'report': (
      ForParentsScreen(
        viewStudentId: 'sample-child',
        viewStudentName: 'Ana Mendoza Reyes',
        viewStudentData: child,
        onEditInfo: () {},
        onShowLogin: () {},
      ),
      null
    ),
    'report_tools': (
      ForParentsScreen(
        viewStudentId: 'sample-child',
        viewStudentName: 'Ana Mendoza Reyes',
        viewStudentData: child,
        onEditInfo: () {},
        onShowLogin: () {},
      ),
      (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
      }
    ),
    'module': (
      const ForParentsScreen(
        viewStudentId: 'sample-child',
        viewStudentName: 'Ana Mendoza Reyes',
        viewStudentData: child,
      ),
      (t) async {
        final row = find.textContaining('Bilang').first;
        await t.ensureVisible(row);
        await t.pump();
        await t.tap(row);
      }
    ),
    'login_card': (
      const StudentLoginCardScreen(
        name: 'Ana Mendoza Reyes',
        avatar: 'girl1',
        username: 'ana4821',
        password: 'DC-2026-4821',
      ),
      null
    ),
    'reset': (
      const Scaffold(
        backgroundColor: Color(0xFF5B5675),
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ResetProgressSheet(
              studentName: 'Ana Mendoza Reyes', preselect: {'matematika'}),
        ),
      ),
      null
    ),
  };

  for (final lang in ['fil', 'ilo']) {
    for (final e in cases.entries) {
      testWidgets('$lang ${e.key}', (tester) async {
        final original = FlutterError.onError;
        final overflows = <String>[];
        FlutterError.onError = (d) {
          if (d.exception is MissingPluginException) return;
          final s = d.exceptionAsString();
          if (s.contains('overflowed')) overflows.add(s.split('\n').first);
        };
        try {
          SharedPreferences.setMockInitialValues({});
          const dpr = 3.0;
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = const Size(360 * dpr, 640 * dpr);
          tester.view.padding =
              const FakeViewPadding(top: 24 * dpr, bottom: 48 * dpr);
          tester.view.viewPadding =
              const FakeViewPadding(top: 24 * dpr, bottom: 48 * dpr);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(RepaintBoundary(
            key: const ValueKey('shot'),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()),
                ChangeNotifierProvider(create: (_) => LanguageProvider(lang)),
                ChangeNotifierProvider<AudioManager>.value(
                    value: AudioManager.instance),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(fontFamily: 'Roboto'),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  _MaterialFallback(),
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale(lang),
                home: e.value.$1,
              ),
            ),
          ));
          Future<void> settle() async {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 600)));
            for (int i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            await tester.runAsync(() async {
              for (final img in tester.widgetList<Image>(find.byType(Image))) {
                await precacheImage(img.image, tester.element(find.byWidget(img)),
                    onError: (_, __) {});
              }
            });
            await tester.pump(const Duration(milliseconds: 200));
          }

          await settle();
          final act = e.value.$2;
          if (act != null) {
            await act(tester);
            await settle();
          }
          await expectLater(
              find.byKey(const ValueKey('shot')),
              matchesGoldenFile(
                  '../../build/report_previews/${lang}_${e.key}.png'));
        } finally {
          FlutterError.onError = original;
          // ignore: avoid_print
          print('OVERFLOW $lang ${e.key}: ${overflows.toSet().join(' | ')}');
        }
      });
    }
  }
}

class _MaterialFallback extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(
          GlobalMaterialLocalizations.delegate.isSupported(locale)
              ? locale
              : const Locale('en'));

  @override
  bool shouldReload(_MaterialFallback old) => false;
}
