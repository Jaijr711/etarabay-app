import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/teacher_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The teacher cannot get past the child's step with details missing: a
/// first and a last name used to be all it asked for.
///
/// With ET_SHOTS=1 it also saves what the teacher sees, for the preview,
/// into build/previews/enroll_required/.
void main() {
  final shots = Platform.environment['ET_SHOTS'] == '1';

  setUpAll(() async {
    if (!shots) return;
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf'
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
          loader
              .addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
        }
      }
      await loader.load();
    }
  });

  testWidgets('Next stays on the child step until every detail is given',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(Directory.systemTemp.createTempSync('enroll').path);
      await Hive.openBox('userProfile');
      await Hive.openBox('userProgress');
    });
    // Past the teacher's privacy agreement, as a teacher already is.
    SharedPreferences.setMockInitialValues({
      'teacher_privacy_agreed_v1': true,
      'teacher_privacy_name': 'Maria Santos',
      'teacher_privacy_date': '2026-10-30T00:00:00.000',
    });
    final empty = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    TeacherDashboardScreen.debugStudents = empty.stream;
    addTearDown(() {
      TeacherDashboardScreen.debugStudents = null;
      empty.close();
    });
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
          ChangeNotifierProvider<AudioManager>.value(
              value: AudioManager.instance),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          locale: const Locale('fil'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TeacherDashboardScreen(),
        ),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));

    Future<void> shot(String name) async {
      if (!shots) return;
      final out = Directory('build/previews/enroll_required')
        ..createSync(recursive: true);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    await tester.tap(find.text(loc.enrollStudent).first);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Names only, as a teacher could before: no gender chosen, no birthday.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Juan');
    await tester.enterText(fields.at(2), 'Dela Cruz');
    await tester.pump();
    await tester.tap(find.text(loc.next));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Still on the child's step, saying what is missing.
    expect(find.text(loc.stepNumber(1, 3).toUpperCase()), findsOneWidget);
    expect(find.textContaining(loc.missingFields('')), findsOneWidget);
    expect(find.text(loc.genderRequired), findsOneWidget);
    expect(find.text(loc.fieldRequired), findsOneWidget); // the birthday
    await shot('1_missing');
    // The shot run stops at the picture: with the real fonts loaded the
    // summary sits over Next for longer than the test waits.
    if (shots) {
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      return;
    }

    // A name that is not a name. (The summary first goes away, so it is not
    // what the next tap lands on.)
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.enterText(fields.at(0), 'J0hn');
    await tester.pump();
    await tester.tap(find.text(loc.next));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(loc.nameLettersOnly), findsOneWidget);
    expect(find.text(loc.stepNumber(1, 3).toUpperCase()), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets(
      'the class list marks missing details and where a child is behind',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(Directory.systemTemp.createTempSync('roster').path);
      await Hive.openBox('userProfile');
      await Hive.openBox('userProgress');
    });
    SharedPreferences.setMockInitialValues({
      'teacher_privacy_agreed_v1': true,
      'teacher_privacy_name': 'Maria Santos',
      'teacher_privacy_date': '2026-10-30T00:00:00.000',
    });
    TeacherDashboardScreen.debugStudents = Stream.value(_FakeSnapshot([
      {
        'name': 'Ana Mendoza Reyes',
        'username': 'ana4821',
        'lrn': 'DC-2026-4821',
        'avatar': 'girl1',
        'gender': 'Female',
        'birthday': '2022-03-01T00:00:00.000',
        'parentName': 'Maria Reyes',
        'parentContact': '09171234567',
        'progress': {
          'overallProgress': 0.6,
          'matematika': {'gamesCompleted': 12, 'totalGames': 21},
        },
        'profile': {'stars': 30},
      },
      {
        'name': 'Carlo Santos',
        'username': 'carlo7710',
        'lrn': 'DC-2026-7710',
        'avatar': 'boy1',
        'gender': 'Male',
        'birthday': '2021-06-01T00:00:00.000',
        'parentName': 'Rosa Santos',
        'parentContact': '09191234567',
        'progress': {
          'overallProgress': 0.5,
          'matematika': {'gamesCompleted': 10, 'totalGames': 21},
        },
        'profile': {'stars': 22},
      },
      {
        // Enrolled before a birthday was asked for.
        'name': 'Benjamin Cruz',
        'username': 'ben1234',
        'lrn': 'DC-2026-1234',
        'avatar': 'boy1',
        'gender': 'Male',
        'parentName': 'Jose Cruz',
        'parentContact': '09181234567',
        // Far behind the class in Numbers.
        'progress': {
          'overallProgress': 0.3,
          'matematika': {'gamesCompleted': 2, 'totalGames': 21},
        },
        'profile': {'stars': 12},
      },
    ]));
    addTearDown(() => TeacherDashboardScreen.debugStudents = null);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
          ChangeNotifierProvider<AudioManager>.value(
              value: AudioManager.instance),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          locale: const Locale('fil'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TeacherDashboardScreen(),
        ),
      ),
    ));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));
    expect(find.text(loc.infoIncomplete), findsOneWidget);
    // And where Benjamin is behind, on a line of its own.
    expect(find.text(loc.strugglingIn(loc.matematika)), findsOneWidget);
    if (shots) {
      final out = Directory('build/previews/enroll_required')
        ..createSync(recursive: true);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/2_roster.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });
}

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
