import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/login_screen.dart';
import 'package:e_tarabay/screens/teacher_login_screen.dart';
import 'package:e_tarabay/widgets/login_problem_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The login problems as the old red snackbar said them and as the new sheet
/// says them, over the real login screens, at a phone's size. The shots land
/// in build/previews/login/. Run by hand:
///
///   flutter test test/previews/login_problem_preview.dart
void main() {
  setUpAll(() async {
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-medium.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf',
        ]
      ),
      ('Fredoka', ['assets/fonts/Fredoka.ttf']),
      (
        'MaterialIcons',
        [
          r'C:\develop\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
        ]
      ),
      (
        'packages/flutter_lucide/lucide',
        [
          r'C:\Users\jayjr\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_lucide-1.11.0\lib\fonts\lucide.ttf'
        ]
      ),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) {
          loader.addFont(
              Future.value(ByteData.view(f.readAsBytesSync().buffer)));
        }
      }
      await loader.load();
    }
    Hive.init(Directory.systemTemp.createTempSync('loginpreview').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  final out = Directory('build/previews/login')..createSync(recursive: true);

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> wait(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<BuildContext> open(
      WidgetTester tester, GlobalKey key, Widget screen, String lang) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 1520);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
      key: key,
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
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byWidget(e)));
      }
    });
    await wait(tester);
    return tester.element(find.byType(screen.runtimeType));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  /// The snackbar as both login screens drew it until now.
  void oldSnack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(LucideIcons.circle_alert, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white))),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(minutes: 1),
      ));

  final childCases = <(String, LoginProblem, String? Function(AppLocalizations))>[
    ('connection', LoginProblem.connection, (l) => l.authConnectionError),
    ('username', LoginProblem.usernameNotFound, (l) => l.authUsernameNotFound),
    ('number', LoginProblem.wrongStudentNumber, (l) => l.authWrongStudentNumber),
    ('teacher_here', LoginProblem.teacherOnChildLogin,
        (l) => l.authUseTeacherButton),
    ('empty', LoginProblem.emptyFields, (l) => l.enterUsernamePassword),
  ];

  for (final lang in ['fil', 'en']) {
    for (final (name, problem, old) in childCases) {
      if (lang == 'en' && problem != LoginProblem.connection) continue;
      testWidgets('child $name $lang', (tester) async {
        final key = GlobalKey();
        final context = await open(tester, key, const LoginScreen(), lang);
        oldSnack(context, old(AppLocalizations.of(context)!)!);
        await wait(tester);
        await shot(tester, key, '${lang}_child_${name}_old');
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        await wait(tester);
        LoginProblemSheet.show(context, problem, code: 'N2', onRetry: () {});
        await wait(tester);
        await shot(tester, key, '${lang}_child_${name}_new');
        await close(tester);
      });
    }
  }

  testWidgets('a newcomer', (tester) async {
    final key = GlobalKey();
    final context = await open(tester, key, const LoginScreen(), 'fil');
    await shot(tester, key, 'fil_new_1_screen');
    await tester.tap(find.byType(TextField).first);
    await wait(tester);
    await shot(tester, key, 'fil_new_2_hint');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    LoginProblemSheet.show(context, LoginProblem.howTo);
    await wait(tester);
    await shot(tester, key, 'fil_new_3_howto');
    await close(tester);
  });

  final teacherCases =<(String, LoginProblem, String Function(AppLocalizations))>[
    ('wrong', LoginProblem.wrongTeacherPassword,
        (l) => l.invalidTeacherCredentials),
    ('internet', LoginProblem.needsInternet, (l) => l.teacherCannotVerify),
    ('changed', LoginProblem.passwordChanged, (l) => l.teacherPasswordChanged),
  ];
  for (final (name, problem, old) in teacherCases) {
    testWidgets('teacher $name', (tester) async {
      final key = GlobalKey();
      final context = await open(tester, key, const TeacherLoginScreen(), 'fil');
      oldSnack(context, old(AppLocalizations.of(context)!));
      await wait(tester);
      await shot(tester, key, 'fil_teacher_${name}_old');
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      await wait(tester);
      LoginProblemSheet.show(context, problem, onRetry: () {});
      await wait(tester);
      await shot(tester, key, 'fil_teacher_${name}_new');
      await close(tester);
    });
  }
}
