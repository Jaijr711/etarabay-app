import 'dart:io';

import 'package:e_tarabay/data/magbasa_content.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/awards_screen.dart';
import 'package:e_tarabay/screens/certificates_screen.dart';
import 'package:e_tarabay/screens/choose_avatar_screen.dart';
import 'package:e_tarabay/screens/for_parents_screen.dart';
import 'package:e_tarabay/screens/home_screen.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/screens/lessons_screen.dart';
import 'package:e_tarabay/screens/magbasa_screen.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/onboarding_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/parents_lock_screen.dart';
import 'package:e_tarabay/screens/privacy_notice_screen.dart';
import 'package:e_tarabay/screens/profile_screen.dart';
import 'package:e_tarabay/screens/settings_screen.dart';
import 'package:e_tarabay/screens/student_login_card_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:e_tarabay/widgets/module_cards.dart';
import 'package:e_tarabay/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every part of the app, one picture each, for the thesis' Chapter 3 plates.
/// An invented child, never a real one. Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/chapter3_plates_preview.dart
///
/// The pictures land in build/chapter3/.
void main() {
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'E-Tarabay',
      packageName: 'com.defended.etarabay',
      version: '1.2.53',
      buildNumber: '65',
      buildSignature: '',
    );
    Hive.init(Directory.systemTemp.createTempSync('chapter3').path);
    final profile = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await profile.put('currentUser', {
      'name': 'Ana',
      'gender': 'Female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 140,
    });
    final sdkFonts = '${Platform.environment['FLUTTER_ROOT'] ?? r'C:\develop\flutter'}'
        r'\bin\cache\artifacts\material_fonts';
    final pubCache = '${Platform.environment['LOCALAPPDATA']}'
        r'\Pub\Cache\hosted\pub.dev';
    for (final (family, files) in [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-medium.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf',
        ]
      ),
      // Text with no family of its own falls to the test font, which draws
      // every letter as a box; on a phone it is the system's Roboto.
      (
        'FlutterTest',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-medium.ttf',
          'assets/fonts/Roboto-bold.ttf',
          'assets/fonts/Roboto-black.ttf',
        ]
      ),
      ('Fredoka', ['assets/fonts/Fredoka.ttf']),
      ('MaterialIcons', ['$sdkFonts\\materialicons-regular.otf']),
      (
        'packages/flutter_lucide/lucide',
        ['$pubCache\\flutter_lucide-1.11.0\\lib\\fonts\\lucide.ttf']
      ),
      ('Emoji', [r'C:\Windows\Fonts\seguiemj.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        final f = File(file);
        if (!f.existsSync()) continue;
        loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      }
      await loader.load();
    }
  });

  late AppLocalizations loc;

  Future<void> show(WidgetTester tester, Widget screen,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues({
      'privacy_notice_ack_v1': true,
      ...prefs,
    });
    FlutterSecureStorage.setMockInitialValues({});
    const dpr = 3.0;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = const Size(360, 760) * dpr;
    addTearDown(tester.view.reset);
    final theme = appTheme();
    loc = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('en')),
        ChangeNotifierProvider<AudioManager>.value(value: AudioManager.instance),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamilyFallback: ['Emoji']),
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ));
  }

  Future<void> settle(WidgetTester tester, [int seconds = 1]) async {
    for (int i = 0; i < seconds * 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.runAsync(() async {
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        try {
          await precacheImage(
              img.image, tester.element(find.byWidget(img).first));
        } catch (_) {}
      }
    });
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Text with no family of its own is drawn by the phone in its system
  // Roboto, but the test engine draws it as boxes whatever font is loaded.
  // So, for the picture only, such text is given Roboto by name.
  InlineSpan named(InlineSpan span) {
    if (span is! TextSpan) return span;
    final style = span.style;
    return TextSpan(
      text: span.text,
      style: style == null
          ? const TextStyle(fontFamily: 'Roboto')
          : style.fontFamily == null
              ? style.copyWith(fontFamily: 'Roboto')
              : style,
      children: span.children?.map(named).toList(),
      recognizer: span.recognizer,
      semanticsLabel: span.semanticsLabel,
    );
  }

  Future<void> shot(WidgetTester tester, String name) async {
    void visit(RenderObject o) {
      if (o is RenderParagraph) o.text = named(o.text);
      o.visitChildren(visit);
    }

    visit(tester.renderObject(find.byType(MaterialApp)));
    // One frame, so the new text is laid out and painted before the picture.
    tester.binding.scheduleFrame();
    await tester.pump(Duration.zero);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../../build/chapter3/$name.png'));
  }

  // Each plate: the screen, what to do on it, and the pictures to take.
  void plate(String name, Widget Function() screen,
      Future<void> Function(WidgetTester t) steps,
      {Map<String, Object> prefs = const {}}) {
    testWidgets(name, (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exception is MissingPluginException) return;
        final s = d.exceptionAsString();
        if (s.contains('overflowed')) return;
        // ignore: avoid_print
        print('ERR $name: ${s.split('\n').take(3).join(' / ')}');
      };
      try {
        await show(tester, screen(), prefs: prefs);
        await settle(tester, 2);
        await steps(tester);
        // Off the screen, so its timers end with it.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      } finally {
        FlutterError.onError = original;
      }
    });
  }

  // Some lessons already played, so the walls look lived in.
  final played = <String, Object>{
    for (var g = 0; g < 4; g++) 'mat_level_0_game_$g': true,
    for (var g = 0; g < 4; g++) 'mat_level_1_game_$g': true,
  };

  // The sign-in screens need Firebase; their pictures come from the web build.
  plate('01_privacy', () => const PrivacyNoticeScreen(),
      (t) => shot(t, 'p01c_privacy'));
  plate('02_onboarding', () => const OnboardingScreen(),
      (t) => shot(t, 'p02_onboarding'));
  plate('02_avatar', () => const ChooseAvatarScreen(firstTime: true),
      (t) => shot(t, 'p02b_avatar'));
  plate('03_home', () => const HomeScreen(), (t) => shot(t, 'p03_home'),
      prefs: played);

  plate('04_numbers', () => const MatematikaScreen(), (t) async {
    await shot(t, 'p04_numbers');
    await t.tap(find.byType(ModuleLevelTile).at(2));
    await settle(t, 2);
    await shot(t, 'p04b_numbers_game');
  }, prefs: played);

  plate('05_about_me', () => const PamilyaScreen(), (t) async {
    await shot(t, 'p05_about_me');
    await t.tap(find.byType(ModuleLevelTile).first);
    await settle(t, 2);
    await shot(t, 'p05b_about_me_game');
  });

  plate('06_color_fun', () => const KulayScreen(), (t) async {
    await shot(t, 'p06_color_fun');
    await t.tap(find.text(loc.catAnimals));
    await settle(t);
    await t.tap(find.text(loc.pagePuppy));
    await settle(t, 3);
    final board = t.getRect(find.byType(InteractiveViewer));
    for (final dy in [0.45, 0.55, 0.65]) {
      await t.dragFrom(
          Offset(board.left + board.width * 0.3, board.top + board.height * dy),
          Offset(board.width * 0.4, 0));
      await settle(t);
    }
    await shot(t, 'p06b_coloring');
    await t.tap(find.text(loc.finishColoring));
    await settle(t, 3);
    await shot(t, 'p06c_finished');
    await t.tap(find.text(loc.myCreations).last);
    await settle(t, 2);
    await shot(t, 'p06d_my_creations');
  });

  plate('07_trace_it', () => const TraceItScreen(), (t) async {
    await shot(t, 'p07_trace_it');
    await t.tap(find.text('A'));
    await settle(t, 2);
    await shot(t, 'p07b_trace_board');
  });

  plate('08_stories', () => const MagbasaScreen(),
      (t) => shot(t, 'p08_stories'));
  plate('08_story', () {
    final d = MagbasaContent.getStoryData()['ni_marti']!;
    return StoryScreen(storyTitle: d['title'], storyData: d);
  }, (t) => shot(t, 'p08b_story'));
  plate('08_song', () {
    final d = MagbasaContent.getSongData()['ania_ti_naganmo_full']!;
    return SongScreen(songTitle: d['title'], songData: d);
  }, (t) => shot(t, 'p08c_song'));

  plate('09_remember_it', () => const TandaanScreen(), (t) async {
    await shot(t, 'p09_remember_it');
    await t.tap(find.byType(Pressable).at(2));
    for (int i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await settle(t);
    await shot(t, 'p09b_cards');
  });

  plate('10_lessons', () => const LessonsScreen(),
      (t) => shot(t, 'p10_lessons'));
  plate('11_awards', () => const AwardsScreen(), (t) => shot(t, 'p11_awards'),
      prefs: played);
  plate('11_certificates', () => const CertificatesScreen(),
      (t) => shot(t, 'p11b_certificates'),
      prefs: played);
  plate('12_settings', () => const SettingsScreen(),
      (t) => shot(t, 'p12_settings'));
  plate('12_profile', () => const ProfileScreen(),
      (t) => shot(t, 'p12b_profile'));
  plate('12_parents_lock', () => const ParentsLockScreen(),
      (t) => shot(t, 'p12c_parents_lock'));

  const child = {
    'id': 'sample-child',
    'name': 'Ana Mendoza Reyes',
    'username': 'ana4821',
    'lrn': 'DC-2026-4821',
    'password': 'DC-2026-4821',
    'avatar': 'girl1',
  };
  plate(
      '13_report',
      () => ForParentsScreen(
            viewStudentId: 'sample-child',
            viewStudentName: 'Ana Mendoza Reyes',
            viewStudentData: child,
            onEditInfo: () {},
            onShowLogin: () {},
          ),
      (t) => shot(t, 'p13b_report'),
      prefs: played);
  plate(
      '13_login_card',
      () => const StudentLoginCardScreen(
            name: 'Ana Mendoza Reyes',
            avatar: 'girl1',
            username: 'ana4821',
            password: 'DC-2026-4821',
          ),
      (t) => shot(t, 'p13c_login_card'));
}
