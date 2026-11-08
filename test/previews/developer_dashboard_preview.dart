import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/screens/developer_dashboard_screen.dart';
import 'package:e_tarabay/services/developer_roster.dart';
import 'package:e_tarabay/widgets/app_covers.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The developer dashboard with its summary, order, maintenance and version
/// sheets, and the two covers a phone can be put under, at a phone's size.
/// The shots land in build/previews/developer/. Run by hand:
///
///   flutter test test/previews/developer_dashboard_preview.dart
final _now = DateTime(2026, 11, 7, 15, 42);

Map<String, dynamic> _kid(String name, String lrn,
        {Duration? ago,
        double? progress,
        bool paused = false,
        bool test = false,
        String? version}) =>
    {
      'name': name,
      'lrn': lrn,
      if (ago != null) 'lastActive': Timestamp.fromDate(_now.subtract(ago)),
      if (progress != null) 'progress': {'overallProgress': progress},
      if (paused) 'disabledByDev': true,
      if (version != null) 'appVersion': version,
      if (test) 'testAccount': true,
    };

final _records = [
  _kid('Ana Mendoza Reyes', 'DC-2026-4821',
      ago: const Duration(seconds: 20), progress: 0.82, version: '1.2.57'),
  _kid('Benjamin Cruz', 'DC-2026-1234',
      ago: const Duration(seconds: 50),
      progress: 1.0,
      test: true,
      version: '1.2.57'),
  _kid('Carlo Santos', 'DC-2026-9012',
      ago: const Duration(hours: 2), progress: 0.12, version: '1.2.56'),
  _kid('Dina Lopez', 'DC-2026-3456',
      ago: const Duration(days: 10), progress: 0.55),
  _kid('Elena Garcia', 'DC-2026-7788',
      ago: const Duration(hours: 5), progress: 0.71, version: '1.2.57'),
  _kid('Francis Dela Cruz', 'DC-2026-5521',
      ago: const Duration(days: 1, hours: 3), progress: 0.48, version: '1.2.55'),
  _kid('Gina Ramos', 'DC-2026-6610',
      ago: const Duration(minutes: 1), progress: 0.93, version: '1.2.57'),
  _kid('Hector Villanueva', 'DC-2026-2290',
      ago: const Duration(days: 14), progress: 0.2, paused: true),
  _kid('Isabel Navarro', 'DC-2026-8843',
      ago: const Duration(hours: 9), progress: 0.37, version: '1.2.57'),
  _kid('Jose Bautista', 'DC-2026-1175'),
  _kid('Karla Mercado', 'DC-2026-4402',
      ago: const Duration(days: 3), progress: 0.6, version: '1.2.56'),
  _kid('Luis Aquino', 'DC-2026-3318',
      ago: const Duration(hours: 1), progress: 0.05, version: '1.2.57'),
];

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
  });

  final out = Directory('build/previews/developer')
    ..createSync(recursive: true);

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Widget app(GlobalKey key, Widget home, {String locale = 'fil'}) =>
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          locale: Locale(locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            _MaterialFallback(),
            _CupertinoFallback(),
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 1520);
    addTearDown(tester.view.reset);
  }

  testWidgets('dashboard', (tester) async {
    phone(tester);
    final config = StreamController<Map<String, dynamic>?>.broadcast();
    DeveloperDashboardScreen.debugStudents = Stream.value([
      for (var i = 0; i < _records.length; i++)
        DevRecord('kid-$i', _records[i]),
    ]);
    DeveloperDashboardScreen.debugConfig = config.stream;
    DeveloperDashboardScreen.debugOwnVersion = '1.2.57';
    DeveloperDashboardScreen.debugNow = () => _now;
    DeveloperDashboardScreen.debugNotifications = Stream.value({
      'teacher': {
        'id': 'n1',
        'title': 'E-Tarabay',
        'body': 'May bagong video ng gabay sa Talaan ng Guro.',
        'sentAt': Timestamp.fromDate(_now.subtract(const Duration(days: 1))),
      },
    });
    addTearDown(() {
      DeveloperDashboardScreen.debugStudents = null;
      DeveloperDashboardScreen.debugConfig = null;
      DeveloperDashboardScreen.debugOwnVersion = null;
      DeveloperDashboardScreen.debugNow = null;
      DeveloperDashboardScreen.debugNotifications = null;
      config.close();
    });
    final key = GlobalKey();
    await tester.pumpWidget(app(key, const DeveloperDashboardScreen()));
    config.add({});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '1_all');

    await tester.tap(find.text('Online'));
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '2_online');
    await tester.tap(find.text('Online'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.textContaining('Ayos:'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Progreso (mababa muna)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, key, '3_progress');

    config.add({
      'maintenanceOn': true,
      'maintenanceMessage': 'Inaayos namin ang E-Tarabay. Balik ka mamaya!',
      'maintenanceSince': Timestamp.fromDate(_now),
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '4_banner');

    // The app's settings, on a page of their own.
    await tester.tap(find.byTooltip('Mga setting ng app'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '5_settings');
    await tester.tap(find.text('Maintenance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '5_maintenance');
    await tester.tapAt(const Offset(180, 60));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Pinakamababang bersyon'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '6_versions');
    await tester.tapAt(const Offset(180, 60));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // A test account: its tag, the row's menu, and what is asked first.
    await tester.enterText(find.byType(TextField).first, 'Benjamin');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, key, '9_test_row');
    final menu = find.byTooltip('Mga aksyon');
    await tester.tap(menu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '9_test_menu');
    await tester.tap(find.text('Tapusin lahat (pang-test)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '9_test_confirm');
    await tester.tap(find.text('Kanselahin'));
    await tester.pump(const Duration(milliseconds: 500));

    // What cannot be undone, asked in Tagalog.
    await tester.tap(menu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Burahin ang account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '9_delete');
    await tester.tap(find.text('Kanselahin'));
    await tester.pump(const Duration(milliseconds: 500));

    // A notification to one child, from the row's menu.
    await tester.tap(menu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Notif sa phone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last,
        'Benjamin, may bago kang badge na makukuha!');
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '10_notif_child');
    await tester.tap(find.text('Kanselahin'));
    await tester.pump(const Duration(milliseconds: 500));

    // To the teachers, from the app bar's Ipadala.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Ipadala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, key, '11_send_sheet');
    await tester.tap(find.text('Notif sa mga teacher'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last,
        'Paalala: may pulong ang mga teacher bukas, 3:00 PM.');
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '12_notif_teacher');
  });

  for (final lang in ['fil', 'en', 'ilo']) {
    testWidgets('maintenance cover $lang', (tester) async {
      phone(tester);
      final key = GlobalKey();
      await tester.pumpWidget(app(
          key,
          const MaintenanceCover(
              message: 'Inaayos namin ang E-Tarabay. Balik ka mamaya!'),
          locale: lang));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump(const Duration(milliseconds: 300));
      await shot(tester, key, '7_cover_$lang');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('notification bar', (tester) async {
    phone(tester);
    final key = GlobalKey();
    Widget card(String title, String body, String when) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F1F8),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipOval(
              child: Image.asset('assets/images/app_logo.jpg',
                  width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-Tarabay · $when',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF5F5B6E))),
                  const SizedBox(height: 2),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1B1F))),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF3B3847))),
                ],
              ),
            ),
          ]),
        );
    await tester.pumpWidget(app(
      key,
      Scaffold(
        backgroundColor: const Color(0xFFE6E1EE),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 6),
                child: Text('3:42',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1C1B1F))),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: Text('Sab, Nobyembre 8',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5F5B6E))),
              ),
              card('E-Tarabay',
                  'Benjamin, may bago kang badge na makukuha!', 'ngayon'),
              card('E-Tarabay',
                  'Paalala: may pulong ang mga teacher bukas, 3:00 PM.',
                  '12m'),
              card('May bagong E-Tarabay!',
                  'Bersyon 1.2.58 — pindutin para i-update.', '1h'),
            ],
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/images/app_logo.jpg'),
          tester.element(find.byType(Scaffold)));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '13_notification_bar');
  });

  testWidgets('update cover', (tester) async {
    phone(tester);
    final key = GlobalKey();
    await tester.pumpWidget(app(
        key,
        const UpdateRequiredCover(
            minVersion: '1.2.57', installedVersion: '1.2.56')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, key, '8_update');
  });
}

class _MaterialFallback extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_MaterialFallback old) => false;
}

class _CupertinoFallback extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_CupertinoFallback old) => false;
}
