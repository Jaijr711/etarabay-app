import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/screens/certificates_screen.dart';
import 'package:e_tarabay/screens/settings_screen.dart';
import 'package:e_tarabay/screens/for_parents_screen.dart';
import 'package:e_tarabay/screens/onboarding_screen.dart';
import 'package:e_tarabay/screens/parents_lock_screen.dart';
import 'package:e_tarabay/screens/privacy_notice_screen.dart';
import 'package:e_tarabay/screens/profile_screen.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:e_tarabay/screens/student_login_card_screen.dart';
import 'package:e_tarabay/screens/teacher_agreement_screen.dart';
import 'package:e_tarabay/screens/teacher_dashboard_screen.dart';
import 'package:e_tarabay/services/teacher_pin.dart';
import 'package:e_tarabay/widgets/reset_progress_sheet.dart';
import 'package:e_tarabay/widgets/tablet_scale.dart';
import 'package:e_tarabay/widgets/teacher_pin_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every screen added in the redesign, at five sizes from a small phone to
/// a tablet on its side, drawn through [TabletScale] as the app draws them,
/// in Ilocano (the longest words). Overflows are printed. Invented children
/// only. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/size_audit_preview.dart
void main() {
  setUpAll(() async {
    // Settings shows the app's version, which a test has no platform for.
    PackageInfo.setMockInitialValues(
        appName: 'E-Tarabay',
        packageName: 'com.etarabay',
        version: '1.2.53',
        buildNumber: '65',
        buildSignature: '');
    Hive.init(Directory.systemTemp.createTempSync('sizes').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    // The real faces, so the pictures look like the app: Roboto and the
    // two icon sets from the Flutter SDK and the icon package. Without them
    // every icon is drawn as an empty box.
    Future<void> load(String family, List<String> paths) async {
      final loader = FontLoader(family);
      var any = false;
      for (final path in paths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        loader.addFont(
            Future.value(ByteData.view(file.readAsBytesSync().buffer)));
        any = true;
      }
      if (any) await loader.load();
    }

    final sdk = Platform.environment['FLUTTER_ROOT'] ?? r'C:\develop\flutter';
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    final pub = Platform.environment['PUB_CACHE'] ??
        '${Platform.environment['LOCALAPPDATA']}/Pub/Cache';
    await load('Roboto', [
      '$fonts/roboto-regular.ttf',
      '$fonts/roboto-medium.ttf',
      '$fonts/roboto-bold.ttf',
      '$fonts/roboto-black.ttf',
    ]);
    await load('MaterialIcons', ['$fonts/materialicons-regular.otf']);
    await load('packages/flutter_lucide/lucide',
        ['$pub/hosted/pub.dev/flutter_lucide-1.11.0/lib/fonts/lucide.ttf']);
    await load('Fredoka', ['assets/fonts/Fredoka.ttf']);
  });

  // Chosen at the command line:
  //   --dart-define=LANG=fil       (default ilo, the longest words)
  //   --dart-define=SIZES=phone    (default all five)
  const lang = String.fromEnvironment('LANG', defaultValue: 'ilo');
  const sizeSet = String.fromEnvironment('SIZES', defaultValue: 'all');

  const allSizes = <String, Size>{
    'a_small': Size(320, 568),
    'b_phone': Size(360, 640),
    'c_large': Size(412, 915),
    'd_tablet': Size(800, 1280),
    'e_tabletLand': Size(1280, 800),
  };
  final sizes =
      sizeSet == 'phone' ? {'b_phone': allSizes['b_phone']!} : allSizes;

  const child = {
    'id': 'sample-child',
    'name': 'Ana Mendoza Reyes',
    'username': 'ana4821',
    'lrn': 'DC-2026-4821',
    'password': 'DC-2026-4821',
    'avatar': 'girl1',
    'parentName': 'Liza Reyes',
    'parentContact': '09171234321',
    'birthday': '2021-05-03T00:00:00.000',
  };

  Future<void> tapText(WidgetTester t, String text) async {
    final f = find.text(text).last;
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f, warnIfMissed: false);
  }

  AppLocalizations l(WidgetTester t) =>
      AppLocalizations.of(t.element(find.byType(Navigator).first))!;

  Future<void> settleSome(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> openEnrol(WidgetTester t) async {
    await t.tap(find.byType(FloatingActionButton));
    await settleSome(t);
  }

  Future<void> enrolChild(WidgetTester t) async {
    await openEnrol(t);
    final fields = find.descendant(
        of: find.byType(BottomSheet), matching: find.byType(TextField));
    await t.enterText(fields.at(0), 'Ana');
    await t.enterText(fields.at(1), 'Mendoza');
    await t.enterText(fields.at(2), 'Reyes');
    await t.pump();
    await tapText(t, l(t).next);
    await settleSome(t);
  }

  Future<void> enrolParent(WidgetTester t) async {
    await enrolChild(t);
    final fields = find.descendant(
        of: find.byType(BottomSheet), matching: find.byType(TextField));
    await t.enterText(fields.at(0), 'Liza Reyes');
    await t.enterText(fields.at(1), '09171234321');
    await t.pump();
    await tapText(t, l(t).next);
    await settleSome(t);
  }

  Future<void> openInfo(WidgetTester t) async {
    await t.tap(find.byIcon(LucideIcons.square_pen).first, warnIfMissed: false);
    await settleSome(t);
  }

  final cases =
      <String, (Widget Function(), Future<void> Function(WidgetTester)?)>{
    'onboarding_lang': (() => const OnboardingScreen(), null),
    'onboarding_page': (
      () => const OnboardingScreen(),
      (t) async => t.tap(find.byType(ElevatedButton).last)
    ),
    'agreement': (() => const TeacherAgreementScreen(), null),
    'privacy_notice': (
      () => const PrivacyNoticeScreen(requireAcknowledge: true),
      null
    ),
    'pin_create': (
      () => TeacherPinFlow(start: PinFlowStart.create, onDone: () {}),
      null
    ),
    'pin_enter': (
      () => TeacherPinFlow(start: PinFlowStart.unlock, onDone: () {}),
      (t) async {
        for (final d in '9999'.split('')) {
          await t.tap(find.bySemanticsLabel(d), warnIfMissed: false);
          await t.pump();
        }
      }
    ),
    'pin_password': (
      () => TeacherPinFlow(
          start: PinFlowStart.unlock, onDone: () {}, onLogout: () async {}),
      (t) async => tapText(t, l(t).teacherForgotPin)
    ),
    'dashboard': (() => const TeacherDashboardScreen(), null),
    'enroll_1': (() => const TeacherDashboardScreen(), openEnrol),
    'enroll_2': (() => const TeacherDashboardScreen(), enrolChild),
    'enroll_3': (
      () => const TeacherDashboardScreen(),
      (t) async {
        await enrolParent(t);
        await tapText(t, l(t).parentConsentCheck);
        await settleSome(t);
      }
    ),
    'info_child': (() => const TeacherDashboardScreen(), openInfo),
    'info_parent': (
      () => const TeacherDashboardScreen(),
      (t) async {
        await openInfo(t);
        await tapText(t, l(t).parentLabelShort);
      }
    ),
    'info_login': (
      () => const TeacherDashboardScreen(),
      (t) async {
        await openInfo(t);
        await tapText(t, l(t).tabLogin);
      }
    ),
    'agreement_settings': (
      () => const TeacherAgreementScreen(readOnly: true),
      null
    ),
    'parent_lock': (
      () => const ParentsLockScreen(),
      (t) async {
        for (final d in ['4', '2']) {
          await t.tap(find.text(d));
          await t.pump();
        }
      }
    ),
    'parent_lock_set': (
      () => const ParentsLockScreen(setupOnly: true),
      (t) async {
        for (final d in ['1', '2', '3', '4', '1']) {
          await t.tap(find.text(d));
          await t.pump(const Duration(milliseconds: 100));
        }
      }
    ),
    'parent_lock_forgot': (
      () => const ParentsLockScreen(),
      (t) async => tapText(t, l(t).forgotPin)
    ),
    // No code on the phone yet: the Student Number comes first.
    'parent_lock_first': (() => const ParentsLockScreen(), null),
    // The child's own pages with the coloured header band.
    'profile': (() => const ProfileScreen(), null),
    'certificates': (() => const CertificatesScreen(), null),
    'lessons': (() => const LessonsScreen(), null),
    'awards': (() => const AwardsScreen(), null),
    'settings': (() => const SettingsScreen(), null),
    // The pickers inside five modules.
    'pick_bilang': (() => const MatematikaScreen(), null),
    'pick_ako': (() => const PamilyaScreen(), null),
    'pick_kulay': (() => const KulayScreen(), null),
    'pick_kulay_cat': (
      () => const KulayScreen(),
      (t) async => tapText(t, l(t).catAnimals)
    ),
    'pick_sulat': (() => const TraceItScreen(), null),
    'pick_tandaan': (() => const TandaanScreen(), null),
    'parent_lock_logout': (
      () => const ParentsLockScreen(verifyOnly: true),
      (t) async {
        await t.tap(find.text('7'));
        await t.pump();
      }
    ),
    'module_bilang': (
      () => const ForParentsScreen(
            viewStudentId: 'sample-child',
            viewStudentName: 'Ana Mendoza Reyes',
            viewStudentData: child,
          ),
      (t) async => tapText(t, l(t).matematika)
    ),
    'report': (
      () => ForParentsScreen(
            viewStudentId: 'sample-child',
            viewStudentName: 'Ana Mendoza Reyes',
            viewStudentData: child,
            onEditInfo: () {},
            onShowLogin: () {},
          ),
      null
    ),
    'report_tools': (
      () => ForParentsScreen(
            viewStudentId: 'sample-child',
            viewStudentName: 'Ana Mendoza Reyes',
            viewStudentData: child,
            onEditInfo: () {},
            onShowLogin: () {},
          ),
      (t) async => t.drag(find.byType(Scrollable).first, const Offset(0, -2000))
    ),
    'module_sarili': (
      () => const ForParentsScreen(
            viewStudentId: 'sample-child',
            viewStudentName: 'Ana Mendoza Reyes',
            viewStudentData: child,
          ),
      (t) async => tapText(t, l(t).angAkingSarili.replaceAll('\n', ' '))
    ),
    'module_tandaan': (
      () => const ForParentsScreen(
            viewStudentId: 'sample-child',
            viewStudentName: 'Ana Mendoza Reyes',
            viewStudentData: child,
          ),
      (t) async => tapText(t, l(t).tandaanTitle)
    ),
    'login_card': (
      () => const StudentLoginCardScreen(
            name: 'Ana Mendoza Reyes',
            avatar: 'girl1',
            username: 'ana4821',
            password: 'DC-2026-4821',
          ),
      null
    ),
    'reset': (
      () => const Scaffold(
            backgroundColor: Color(0xFF5B5675),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ResetProgressSheet(
                  studentName: 'Ana Mendoza Reyes', preselect: {'kulay'}),
            ),
          ),
      null
    ),
  };

  for (final e in cases.entries) {
    for (final size in sizes.entries) {
      testWidgets('${e.key} ${size.key}', (tester) async {
        final original = FlutterError.onError;
        final overflows = <String>[];
        FlutterError.onError = (d) {
          if (d.exception is MissingPluginException) return;
          final s = d.exceptionAsString();
          if (s.contains('overflowed')) {
            // Which widget, so a failure can be found without a debugger.
            final where = d
                .toString()
                .split('\n')
                .skipWhile((l) => !l.contains('relevant error-causing'))
                .skip(1)
                .take(1)
                .join();
            overflows.add('${s.split('\n').first} at $where');
          }
        };
        try {
          SharedPreferences.setMockInitialValues({
            // A parent code exists, so the parents' door asks for it —
            // except where the picture is of making one.
            if (e.key != 'parent_lock_set' && e.key != 'parent_lock_first')
              'parent_pin': '8c2b0f8f5a0b0b2f',
            'teacher_privacy_agreed_v1': true,
            'teacher_privacy_name': 'Maria Santos',
            'teacher_privacy_date': '2026-10-29T00:00:00.000',
          });
          FlutterSecureStorage.setMockInitialValues({});
          await TeacherPin.save('1234');
          TeacherDashboardScreen.debugStudents =
              Stream.value(_FakeSnapshot(_kids));

          const dpr = 2.0;
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = size.value * dpr;
          tester.view.padding =
              const FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
          tester.view.viewPadding =
              const FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
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
                // The app's own theme, so cards and fields are drawn as on
                // the phone; only the font is swapped for one loaded here.
                // The button theme carries its own text style, so it needs the
                // font too or its labels fall back to the test's box glyphs.
                theme: () {
                  final t = appTheme();
                  final button = t.elevatedButtonTheme.style;
                  final label = button?.textStyle?.resolve({});
                  return t.copyWith(
                    textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: button?.copyWith(
                        textStyle: WidgetStatePropertyAll(
                            (label ?? const TextStyle())
                                .copyWith(fontFamily: 'Roboto')),
                      ),
                    ),
                  );
                }(),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  _MaterialFallback(),
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale(lang),
                builder: (_, c) => TabletScale(child: c!),
                home: e.value.$1(),
              ),
            ),
          ));
          Future<void> settle() async {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 500)));
            for (int i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 150));
            }
            await tester.runAsync(() async {
              for (final img in tester.widgetList<Image>(find.byType(Image))) {
                await precacheImage(
                    img.image, tester.element(find.byWidget(img).first),
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
                  '../../build/size_audit/${lang}_${e.key}__${size.key}.png'));
        } finally {
          FlutterError.onError = original;
          TeacherDashboardScreen.debugStudents = null;
          // ignore: avoid_print
          print('OVERFLOW ${e.key} ${size.key}: '
              '${overflows.toSet().join(' | ')}');
        }
      });
    }
  }
}

final _kids = <Map<String, dynamic>>[
  {
    'name': 'Ana Mendoza Reyes',
    'username': 'ana4821',
    'lrn': 'DC-2026-4821',
    'avatar': 'girl1',
    'progress': {'overallProgress': 0.82},
    'profile': {
      'stars': 45,
      'certificates': <String>['cert-a']
    },
  },
  {
    'name': 'Benjamin Cruz Villanueva',
    'username': 'ben1234',
    'lrn': 'DC-2026-1234',
    'avatar': 'boy1',
    'progress': {'overallProgress': 0.64},
    'profile': {'stars': 30},
  },
  {
    'name': 'Carlo Santos',
    'username': 'carlo9012',
    'lrn': 'DC-2026-9012',
    'avatar': 'animal_lion',
    'progress': {'overallProgress': 0.12},
    // Finished by the developer: the card's "Pang-test" tag.
    'testAccount': true,
    'profile': {'stars': 5},
  },
  {
    'name': 'Dina Lopez',
    'username': 'dina3456',
    'lrn': 'DC-2026-3456',
    'avatar': 'animal_bunny',
    'progress': {'overallProgress': 0.55},
    'profile': {'stars': 26},
  },
];

class _FakeSnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _FakeSnapshot(List<Map<String, dynamic>> rows)
      : docs = [
          for (var i = 0; i < rows.length; i++) _FakeDoc('kid-$i', rows[i])
        ];

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

// A stand-in for one child's record; the real one cannot be built in a test.
// ignore: subtype_of_sealed_class
class _FakeDoc extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
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
