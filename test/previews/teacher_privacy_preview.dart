import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/screens/teacher_agreement_screen.dart';
import 'package:e_tarabay/services/teacher_pin.dart';
import 'package:e_tarabay/widgets/teacher_pin_flow.dart';
import 'package:e_tarabay/widgets/teacher_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The teacher's privacy agreement and the lock, on a small edge-to-edge
/// phone, in Ilocano (the longest) and Filipino. Not part of the suite —
/// run by hand:
///
///   flutter test --update-goldens test/previews/teacher_privacy_preview.dart
void main() {
  setUpAll(() async {
    final arial = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (arial.existsSync()) {
      final bytes = ByteData.view(arial.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }
    final fb = ByteData.view(
        File('assets/fonts/Fredoka.ttf').readAsBytesSync().buffer);
    await (FontLoader('Fredoka')..addFont(Future.value(fb))).load();
  });

  final navigatorKey = GlobalKey<NavigatorState>();
  final cases = <String, Widget Function()>{
    'agreement': () => const TeacherAgreementScreen(),
    'lock': () => const _FakeClass(),
    'password': () => const _FakeClass(),
    'create': () =>
        TeacherPinFlow(start: PinFlowStart.create, onDone: () {}),
  };

  for (final lang in ['ilo', 'fil']) {
    for (final e in cases.entries) {
      testWidgets('$lang ${e.key}', (tester) async {
        final original = FlutterError.onError;
        final overflows = <String>[];
        FlutterError.onError = (d) {
          final s = d.exceptionAsString();
          if (s.contains('overflowed')) {
            overflows.add(s.split('\n').first);
          } else {
            // ignore: avoid_print
            print('ERR ${s.split('\n').take(4).join(' / ')}');
          }
        };
        try {
          final locked = e.key == 'lock' || e.key == 'password';
          SharedPreferences.setMockInitialValues(
              {'session_role': locked ? 'teacher' : 'none'});
          FlutterSecureStorage.setMockInitialValues({});
          // A PIN for the lock; none for the password view.
          if (e.key == 'lock') {
            await TeacherPin.save('1234');
            await TeacherPin.check('0000');
          }
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
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: ThemeData(
                fontFamily: 'Roboto',
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                _MaterialFallback(),
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(lang),
              builder: (_, child) =>
                  TeacherLockGate(navigatorKey: navigatorKey, child: child!),
              home: e.value(),
            ),
          ));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)));
          for (int i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 150));
          }
          await tester.runAsync(() async {
            for (final img in tester.widgetList<Image>(find.byType(Image))) {
              await precacheImage(img.image, tester.element(find.byWidget(img)),
                  onError: (_, __) {});
            }
          });
          await tester.pump(const Duration(milliseconds: 200));
          await expectLater(
              find.byKey(const ValueKey('shot')),
              matchesGoldenFile(
                  '../../build/teacher_previews/${lang}_${e.key}.png'));
        } finally {
          FlutterError.onError = original;
          // ignore: avoid_print
          print('OVERFLOW $lang ${e.key}: ${overflows.toSet().join(' | ')}');
        }
      });
    }
  }
}

/// Something class-like to blur behind the lock.
class _FakeClass extends StatelessWidget {
  const _FakeClass();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        children: [
          for (final n in ['Ana Reyes', 'Ben Cruz', 'Carlo Santos', 'Dina Lopez'])
            Card(child: ListTile(title: Text(n), subtitle: const Text('LRN'))),
        ],
      ),
    );
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
