import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/for_parents_screen.dart';
import 'package:e_tarabay/screens/teacher_dashboard_screen.dart';
import 'package:e_tarabay/screens/teacher_login_screen.dart';
import 'package:e_tarabay/widgets/pin_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the teacher's guide to the app from the real teacher screens: a
/// hand goes through logging in, the privacy agreement, the PIN, the class
/// list, enrolling a child, a child's report and the settings, with words
/// under the screen saying what each part is for. No voice, no sound.
///
/// The frames land in build/math_videos/teacher_fil/ for encode.py. Not part
/// of the suite — run by hand:
///
///   flutter test test/previews/teacher_video_record.dart
///
/// With --dart-define=DRY=true it runs the whole script without writing a
/// frame (one in every 30 only, to look at), to find a broken step in
/// minutes rather than after an hour of recording.
///
/// 15 frames a second: screens that slide and a hand that moves, nothing
/// fast, and half the hour of 30.
const _fps = 15;
const _dry = bool.fromEnvironment('DRY');

/// The phone screen, the phone's edge round it, and the card of words under
/// it, all on a 400×1000 canvas: 14 + 6 + 760 + 6 + 14 + 186 + 14.
const _screen = Size(360, 760);
const _bezel = 6.0;
const _margin = 14.0;
const _canvas = Size(400, 1000);

/// Where the phone's screen starts on the canvas. Finders and gestures count
/// from the canvas; the hand and the spotlight are drawn on the screen.
const _origin = Offset(_margin + _bezel, _margin + _bezel);

/// The app's own violet, for the spotlight and the card.
const _violet = Color(0xFF5C52E5);
const _ink = Color(0xFF1E1B4B);
// 720 px wide: the words on the phone's screen are small, and at 540 they
// came out soft.
const _ratio = 2.0;

void main() {
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
        appName: 'E-Tarabay',
        packageName: 'com.etarabay',
        version: '1.2.57',
        buildNumber: '69',
        buildSignature: '');
    Hive.init(Directory.systemTemp.createTempSync('teachervideo').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
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
      ('Signs', [r'C:\Windows\Fonts\seguisym.ttf']),
      ('Emoji', [r'C:\Windows\Fonts\seguiemj.ttf']),
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
        if (!f.existsSync()) continue;
        loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      }
      await loader.load();
    }
  });

  testWidgets('teacher', (tester) async {
    TeacherDashboardScreen.debugStudents =
        Stream.value(_FakeSnapshot(_kids)).asBroadcastStream();
    ForParentsScreen.debugStudentDoc =
        (id) => Stream.value(_FakeRecord(id, _kids[_ids.indexOf(id)]));
    addTearDown(() {
      TeacherDashboardScreen.debugStudents = null;
      ForParentsScreen.debugStudentDoc = null;
    });
    final rec = await _Rec.open(tester);
    await _script(rec);
    // Some 4 000 frames at 720 px: past the test runner's ten minutes.
  }, timeout: const Timeout(Duration(minutes: 45)));
}

/// The guide, part by part. Each [_Rec.say] puts words under the screen and
/// [_Rec.read] holds until there has been time to read them.
Future<void> _script(_Rec rec) async {
  final t = rec.tester;
  const parts = 8;

  // ── 1. Pagpasok ───────────────────────────────────────────────────────
  rec.part(1, parts, 'Pagpasok');
  rec.say('Ito ang gabay sa paggamit ng E‑Tarabay para sa guro. '
      'I-tap ang video kung gusto mong i-pause.');
  await rec.read();
  rec.say('Sa unang screen ng app, i-tap ang "Ipagpatuloy bilang Guro" '
      'sa ibaba. Bubukas ang Pagpasok ng Guro.');
  await rec.read();
  rec.say('Nakalagay na ang pangalan ng gumagamit. I-type ang password '
      'na ibinigay sa inyo ng paaralan.');
  await rec.enter(t.getCenter(find.byType(TextField).last));
  await rec.typeInto(find.byType(TextField).last, 'guro2026');
  await rec.read();
  rec.say('I-tap ang mata para makita ang na-type mo.');
  await rec.tapOn(_eye(t));
  await rec.read();
  rec.say('Pagkatapos, i-tap ang "Mag-login bilang Guro".');
  // A press only: the real button asks the school's server.
  await rec.tapOn(find.text('Mag-login bilang Guro'), real: false);
  await rec.read();
  rec.nav.currentState!.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TeacherDashboardScreen()));
  await rec.loading(seconds: 1.1);

  // ── 2. Kasunduan sa Privacy ──────────────────────────────────────────
  rec.part(2, parts, 'Kasunduan sa Privacy');
  rec.say('Sa unang pagpasok, babasahin mo ang Kasunduan sa Privacy. '
      'Hawak mo ang impormasyon ng mga bata, kaya may apat na pangako.');
  await rec.read();
  await rec.scroll(find.byType(Scrollable).first, -260);
  rec.say('Isulat ang buong pangalan mo bilang pirma.');
  await rec.typeInto(find.byType(TextField).last, 'Gng. Maria Santos');
  FocusManager.instance.primaryFocus?.unfocus();
  await rec.read();
  rec.say('I-check ang "Sumasang-ayon ako sa kasunduan", saka i-tap ang '
      '"Magpatuloy sa dashboard".');
  await rec.tapOn(find.text('Sumasang-ayon ako sa kasunduan.'));
  await rec.tapOn(find.text('Magpatuloy sa dashboard'));
  await rec.loading(seconds: 1.0);
  await rec.read();

  // ── 3. PIN ───────────────────────────────────────────────────────────
  rec.part(3, parts, 'PIN');
  rec.say('Gumawa ng 4 na numerong PIN. Ito ang magbubukas ng dashboard '
      'sa phone na ito.');
  await rec.pin('2468');
  await rec.loading(seconds: 0.6);
  await rec.read();
  rec.say('Ulitin ang PIN para makasigurado.');
  await rec.pin('2468');
  await rec.loading(seconds: 1.1);
  rec.say('Kapag umalis ka sa app nang 30 segundo, magla-lock ito. PIN o '
      'daliri ang magbubukas. Kapag nakalimutan ang PIN, gamitin ang '
      'password.');
  await rec.read();

  // ── 4. Talaan ng Guro ────────────────────────────────────────────────
  rec.part(4, parts, 'Talaan ng Guro');
  rec.say('Ito ang Talaan ng Guro. Nandito ang lahat ng mag-aaral mo.');
  await rec.read();
  rec.say('Ang berdeng tanda: protektado ang listahan at magla-lock ito '
      'kapag umalis ka sa app.');
  await rec.pointAt(find.textContaining('Protektado'));
  await rec.read();
  rec.say('Kapag may kaarawan ngayon, makikita mo rito ang pangalan ng bata.');
  await rec.pointAt(find.textContaining('kaarawan ngayon'));
  await rec.read();
  rec.say('"Nahuhuli": mga batang nagsimula na pero malayo ang agwat sa '
      'klase.');
  await rec.tapOn(find.textContaining('Nahuhuli').first);
  await rec.read();
  rec.say('"Di Naglalaro": isang linggo o higit nang hindi nagbubukas ng '
      'app.');
  await rec.tapOn(find.textContaining('Di Naglalaro').first);
  await rec.read();
  rec.say('"Lahat": ibalik ang buong listahan.');
  await rec.tapOn(find.textContaining('Lahat').first);
  await rec.read();
  rec.say('Hanapin ang isang bata sa pangalan niya.');
  await rec.typeInto(find.byType(TextField).first, 'Ana');
  await rec.read();
  await t.enterText(find.byType(TextField).first, '');
  FocusManager.instance.primaryFocus?.unfocus();
  await rec.hold(seconds: 0.5);
  rec.say('I-tap ang mata para makita ang buong Student Number ng bawat bata.');
  await rec.tapOn(_eye(t));
  await rec.read();
  await rec.tapOn(_eye(t));
  rec.say('Sa bawat bata: ang bar ay ang progreso niya, at ang bituin ay '
      'ang mga bituing nakuha niya.');
  await rec.pointAt(find.byType(LinearProgressIndicator).first);
  await rec.read();
  rec.say('Ang "Bago" ay may bagong certificate ang bata. Mawawala ito '
      'kapag binuksan mo ang progreso niya.');
  await rec.pointAt(find.text('Bago').first);
  await rec.read();

  // ── 5. Magpatala ng Mag-aaral ────────────────────────────────────────
  rec.part(5, parts, 'Magpatala ng Mag-aaral');
  rec.say('Para magdagdag ng bata, i-tap ang "Magpatala ng Mag-aaral".');
  await rec.tapOn(find.text('Magpatala ng Mag-aaral').last);
  await rec.loading(seconds: 0.7);
  await rec.read();
  rec.say('Hakbang 1: piliin ang Lalaki o Babae, at isulat ang pangalan at '
      'kaarawan ng bata.');
  await rec.tapOn(find.text('Babae').last);
  await rec.typeInto(_field('Unang Pangalan'), 'Liza');
  await rec.typeInto(_field('Apelyido'), 'Ramos');
  FocusManager.instance.primaryFocus?.unfocus();
  await rec.read();
  await rec.tapOn(find.text('Susunod').last);
  await rec.loading(seconds: 0.6);
  rec.say('Hakbang 2: ang pangalan at numero ng magulang o guardian. '
      '11 numero ang cellphone number.');
  await rec.typeInto(_field('Pangalan ng Magulang'), 'Rosa Ramos');
  await rec.typeInto(_field('Numero ng Magulang'), '09171234567');
  FocusManager.instance.primaryFocus?.unfocus();
  await rec.read();
  await rec.tapOn(find.text('Susunod').last);
  await rec.loading(seconds: 0.6);
  rec.say('Hakbang 3: tingnan kung tama ang lahat, at i-check kapag '
      'pumayag na ang magulang.');
  await rec.tapOn(find.byType(Checkbox).last);
  await rec.read();
  rec.say('I-tap ang "Itala". Ibibigay ng app ang username at password ng '
      'bata para sa magulang. Kailangan ng internet dito.');
  // A press only: enrolling writes to the school's server.
  await rec.tapOn(find.text('Itala').last, real: false);
  await rec.read();
  rec.nav.currentState!.pop();
  await rec.loading(seconds: 0.7);

  // ── 6. I-edit at Login card ──────────────────────────────────────────
  rec.part(6, parts, 'I-edit ang detalye');
  rec.say('I-tap ang lapis para baguhin ang detalye ng bata.');
  await rec.tapOn(find.byTooltip('I-edit ang detalye').first);
  await rec.loading(seconds: 0.7);
  await rec.read();
  rec.say('"Bata": pangalan, kasarian at kaarawan. "Magulang": pangalan at '
      'numero ng magulang.');
  await rec.tapOn(find.text('Magulang').last);
  await rec.read();
  rec.say('"Login": ang username at password ng bata.');
  await rec.tapOn(find.text('Login').last);
  await rec.read();
  rec.say('I-tap ang "Ipakita ang login card". Ipakita ito sa magulang o '
      'hayaang kunan nila ng larawan.');
  await rec.tapOn(find.text('Ipakita ang login card').last);
  await rec.loading(seconds: 0.8);
  await rec.read();
  rec.nav.currentState!.pop();
  await rec.loading(seconds: 0.5);
  rec.nav.currentState!.pop();
  await rec.loading(seconds: 0.6);

  // ── 7. Progreso ng bata ──────────────────────────────────────────────
  rec.part(7, parts, 'Progreso ng bata');
  rec.say('I-tap ang pangalan ng bata para makita ang progreso niya.');
  await rec.tapOn(find.text('Ana Mendoza Reyes').first);
  await rec.loading(seconds: 1.1);
  rec.say('Dito ang kabuuang progreso, ang mga bituin, ang natapos, at kung '
      'kailan huling naglaro.');
  await rec.read();
  await rec.scroll(find.byType(Scrollable).first, -330);
  rec.say('"Ano ang Sanayin": ang mga kasanayang madalas pang mali ang bata. '
      'Nasa itaas ang module na pinakakulang.');
  await rec.read();
  await rec.scrollTo(find.text('Mga tool ng teacher'), up: 120);
  rec.say('Sa "Mga tool ng teacher": i-edit ang info, ibigay ang login sa '
      'magulang, o i-reset ang progreso.');
  await rec.read();
  rec.nav.currentState!.pop();
  await rec.loading(seconds: 0.7);
  rec.say('Para alisin ang isang bata, i-swipe pakaliwa ang pangalan niya. '
      'Magtatanong muna ang app bago mag-alis.');
  await rec.swipe(find.text('Carlo Santos').first, -250);
  await rec.loading(seconds: 0.6);
  await rec.read();
  // Cancel: the dialog's first button keeps the child.
  final keep = find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(TextButton));
  await rec.tapOn(keep.first);
  await rec.loading(seconds: 0.6);

  // ── 8. Pag-aayos ─────────────────────────────────────────────────────
  rec.part(8, parts, 'Pag-aayos');
  rec.say('I-tap ang gear para sa Pag-aayos.');
  await rec.tapOn(find.byIcon(LucideIcons.settings).first);
  await rec.loading(seconds: 1.0);
  rec.say('Dito mo papalitan ang wika, ang tunog at musika, at ang '
      'paalala o notipikasyon.');
  await rec.read();
  await rec.scroll(find.byType(Scrollable).first, -300);
  rec.say('Palitan ang PIN, basahin ulit ang Kasunduan sa Privacy, o '
      'mag-login gamit ang daliri.');
  await rec.read();
  await rec.scrollTo(find.text('Burahin lahat ng mag-aaral'), up: 80);
  rec.say('Ang "Burahin lahat ng mag-aaral" ay nagbubura ng buong klase. '
      'Kailangan dito ang password.');
  await rec.pointAt(find.text('Burahin lahat ng mag-aaral'));
  await rec.read();
  rec.say('Mag-logout kapag tapos ka na, lalo na kung hiram ang phone.');
  await rec.pointAt(find.text('Mag-logout').last);
  await rec.read();
  rec.nav.currentState!.pop();
  await rec.loading(seconds: 0.7);

  rec.part(0, parts, 'Handa ka na!');
  rec.say('Mapapanood mo ulit ang gabay na ito sa ▶ "Paano gamitin" sa '
      'itaas ng Talaan ng Guro.');
  await rec.leave();
  await rec.read();
  await rec.finish();
}

/// The text field labelled [label]. By its label: the class list's search
/// field is still there behind a sheet, and would be the first one found.
Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextField)).last;

/// The eye that shows what is hidden: a password, or the Student Numbers.
Finder _eye(WidgetTester t) {
  for (final icon in const [LucideIcons.eye, LucideIcons.eye_off]) {
    final f = find.byIcon(icon);
    if (f.evaluate().isNotEmpty) return f.first;
  }
  throw StateError('no eye on screen');
}

class _Rec {
  _Rec(this.tester, this.dir);

  final WidgetTester tester;
  final Directory dir;
  final nav = GlobalKey<NavigatorState>();
  final GlobalKey _frameKey = GlobalKey();
  final hand = ValueNotifier<Offset?>(null);
  final press = ValueNotifier<double>(0);

  /// The part of the screen being explained, framed in yellow with the rest
  /// dimmed, so the finger never has to sit on it to say "this".
  Finder? _target;
  final frame = ValueNotifier<(Rect, double)?>(null);

  /// Whether the finger points down at [_target] from above it — when
  /// there is no room under it — rather than up from below.
  final fromAbove = ValueNotifier<bool>(false);
  final words = ValueNotifier<String>('');
  final section = ValueNotifier<(int, int, String)>((0, 0, ''));
  int _frame = 0;
  double _saidAt = 0;

  double get now => _frame / _fps;

  static Future<_Rec> open(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.devicePixelRatio = _ratio;
    tester.view.physicalSize = _canvas * _ratio;
    addTearDown(tester.view.reset);

    final dir = Directory('build/math_videos/teacher_fil');
    dir.createSync(recursive: true);
    for (final f in dir.listSync().whereType<File>()) {
      f.deleteSync();
    }
    final rec = _Rec(tester, dir);

    final theme = appTheme();
    await tester.pumpWidget(RepaintBoundary(
      key: rec._frameKey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF221D57), Color(0xFF0E0C24)]),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_margin),
            child: Column(children: [
              // The phone, at a phone's size: the app sees only this much.
              Container(
                padding: const EdgeInsets.all(_bezel),
                decoration: BoxDecoration(
                  color: const Color(0xFF07061A),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x73000000),
                        blurRadius: 30,
                        offset: Offset(0, 12)),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFF3B3670)),
                ),
                child: SizedBox.fromSize(
                  size: _screen,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: MediaQuery(
                      data: const MediaQueryData(
                          size: _screen,
                          devicePixelRatio: _ratio,
                          padding: EdgeInsets.only(top: 24),
                          viewPadding: EdgeInsets.only(top: 24)),
                      child: Stack(children: [
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider(
                                create: (_) => UserProvider()),
                            ChangeNotifierProvider(
                                create: (_) => LanguageProvider('fil')),
                            ChangeNotifierProvider<AudioManager>.value(
                                value: AudioManager.instance),
                          ],
                          child: MaterialApp(
                            navigatorKey: rec.nav,
                            debugShowCheckedModeBanner: false,
                            theme: theme.copyWith(
                                textTheme: theme.textTheme.apply(
                                    fontFamily: 'Roboto',
                                    fontFamilyFallback: ['Emoji', 'Signs']),
                                elevatedButtonTheme: ElevatedButtonThemeData(
                                    style: theme.elevatedButtonTheme.style
                                        ?.copyWith(
                                            textStyle:
                                                const WidgetStatePropertyAll(
                                                    TextStyle(
                                                        fontFamily: 'Roboto',
                                                        fontSize: 16,
                                                        fontWeight: FontWeight
                                                            .bold))))),
                            locale: const Locale('fil'),
                            localizationsDelegates:
                                AppLocalizations.localizationsDelegates,
                            supportedLocales: AppLocalizations.supportedLocales,
                            home: const TeacherLoginScreen(),
                          ),
                        ),
                        Positioned.fill(
                            child: IgnorePointer(child: _HandLayer(rec))),
                        // The camera, in the status bar.
                        const Positioned(
                          top: 7,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 10,
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: Color(0xFF07061A),
                                      shape: BoxShape.circle)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _margin),
              Expanded(child: _Words(rec)),
            ]),
          ),
        ),
      ),
    ));
    await rec._settle(3);
    return rec;
  }

  Future<void> _settle(int seconds) async {
    for (int i = 0; i < seconds * 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await _precache();
  }

  Future<void> _precache() async {
    await tester.runAsync(() async {
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        try {
          await precacheImage(
              img.image, tester.element(find.byWidget(img).first));
        } catch (_) {}
      }
    });
  }

  /// The yellow frame glides to its target and fades in or out.
  void _easeFrame() {
    final shown = frame.value;
    // Read off the screen every frame, so the frame stays on its widget
    // while a sheet settles or a list shifts under it.
    Rect? live;
    final f = _target;
    if (f != null) {
      try {
        // A `.first` of nothing throws rather than finding nothing.
        if (f.evaluate().isNotEmpty) live = tester.getRect(f.first).inflate(6);
      } on StateError {
        live = null;
      }
    }
    if (live == null) {
      if (shown == null) return;
      final a = shown.$2 - 0.25;
      frame.value = a <= 0 ? null : (shown.$1, a);
      return;
    }
    if (shown == null) {
      frame.value = (live, 0.25);
      return;
    }
    frame.value = (
      Rect.lerp(shown.$1, live, 0.4)!,
      (shown.$2 + 0.25).clamp(0.0, 1.0),
    );
  }

  /// One frame of the video.
  Future<void> _step() async {
    _easeFrame();
    await tester.pump(const Duration(microseconds: 1000000 ~/ _fps));
    if (_dry && _frame % 30 != 0) {
      _frame++;
      return;
    }
    final boundary =
        _frameKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final path = '${dir.path}/f${_frame.toString().padLeft(5, '0')}.png';
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: _ratio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File(path).writeAsBytesSync(png!.buffer.asUint8List());
    });
    _frame++;
  }

  Future<void> hold({required double seconds}) async {
    final until = now + seconds;
    while (now < until) {
      await _step();
    }
  }

  /// Frames while a screen opens, with real time between them so its
  /// pictures load and its futures finish.
  Future<void> loading({required double seconds}) async {
    // A new screen: whatever was framed is behind it now.
    _target = null;
    final until = now + seconds;
    while (now < until) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      if (_frame % 6 == 0) await _precache();
      await _step();
    }
  }

  // ── Words ────────────────────────────────────────────────────────────

  void part(int n, int of, String title) {
    section.value = (n, of, title);
    // ignore: avoid_print
    print('PART $n $title at ${now.toStringAsFixed(1)}s');
  }

  void say(String text) {
    words.value = text;
    _saidAt = now;
    _target = null;
  }

  /// Holds until the words have been up long enough to read: a second for
  /// every 20 characters and a little more, never under 2.2 s. Teachers
  /// read quickly, and can pause besides.
  Future<void> read() async {
    final need = (words.value.length / 20 + 0.6).clamp(2.2, 99.0);
    final until = _saidAt + need;
    while (now < until) {
      await _step();
    }
  }

  // ── The hand ─────────────────────────────────────────────────────────

  Future<void> moveTo(Offset to, {double seconds = 0.45}) async {
    final from =
        hand.value ?? _origin + Offset(_screen.width - 30, _screen.height + 60);
    final start = now;
    while (now < start + seconds) {
      final t = Curves.easeInOutCubic
          .transform(((now - start) / seconds).clamp(0.0, 1.0));
      hand.value = Offset.lerp(from, to, t);
      await _step();
    }
    hand.value = to;
  }

  Future<void> enter(Offset toward) async {
    hand.value = _origin + Offset(_screen.width - 30, _screen.height + 60);
    await moveTo(toward, seconds: 0.7);
  }

  Future<void> leave() async {
    await moveTo(_origin + Offset(_screen.width - 30, _screen.height + 80),
        seconds: 0.5);
    hand.value = null;
  }

  Future<void> _press(bool real, {Offset? at}) async {
    final g = real ? await tester.startGesture(at ?? hand.value!) : null;
    for (int i = 0; i < 3; i++) {
      press.value = (i + 1) / 3;
      await _step();
    }
    await g?.up();
    for (int i = 0; i < 4; i++) {
      press.value = 1 - (i + 1) / 4;
      await _step();
    }
  }

  /// The hand goes to [f] and taps it; with [real] false it only presses,
  /// for a button whose real work needs the school's server.
  Future<void> tapOn(Finder f, {bool real = true}) async {
    final box = await _show(f);
    await _press(real, at: box.center);
  }

  /// The hand points at [f] without pressing.
  Future<void> pointAt(Finder f) async {
    // Just the thing named — a badge, not the card it sits on.
    await _show(f, seconds: 0.5, whole: false);
    await hold(seconds: 0.2);
  }

  /// The whole of what [f] is part of: the button round a label, the tab
  /// round its name. The closest one that is still a part of the screen,
  /// not the screen itself.
  Finder _whole(Finder f) {
    final screen = _screen.width * _screen.height;
    final own = tester.getRect(f);
    final around = find.ancestor(
        of: f,
        matching: find.byWidgetPredicate((w) =>
            w is ButtonStyleButton ||
            w is InkWell ||
            w is ListTile ||
            w is CheckboxListTile ||
            w is GestureDetector ||
            w is TextField));
    for (final e in around.evaluate()) {
      final r = tester.getRect(find.byElementPredicate((x) => x == e));
      if (r.width * r.height > screen * 0.3) break;
      if (r.width >= own.width && r.height >= own.height) {
        return find.byElementPredicate((x) => x == e);
      }
    }
    return f;
  }

  /// Frames [f] and brings the fingertip to its edge — under it, or over it
  /// near the bottom of the screen — never on top of what it shows.
  Future<Rect> _show(Finder f,
      {double seconds = 0.45, bool whole = true}) async {
    final box = tester.getRect(f.first);
    _target = whole ? _whole(f.first) : f.first;
    final above = box.bottom - _origin.dy + 70 > _screen.height;
    fromAbove.value = above;
    await moveTo(Offset(box.center.dx, above ? box.top - 10 : box.bottom + 10),
        seconds: seconds);
    return box;
  }

  /// Taps [field] and types [text] into it a letter at a time.
  Future<void> typeInto(Finder field, String text) async {
    await tapOn(field);
    for (int i = 1; i <= text.length; i++) {
      await tester.enterText(field, text.substring(0, i));
      await _step();
    }
  }

  /// The PIN pad: each digit tapped in turn.
  Future<void> pin(String digits) async {
    for (final d in digits.split('')) {
      final key =
          find.descendant(of: find.byType(PinKey), matching: find.text(d));
      final pad = find.ancestor(of: key.first, matching: find.byType(PinKey));
      final box = await _show(pad.first, seconds: 0.28);
      await _press(true, at: box.center);
    }
  }

  /// A slow drag of [f]'s list by [dy], with the finger on it.
  Future<void> scroll(Finder f, double dy) async {
    _target = null;
    fromAbove.value = false;
    final box = tester.getRect(f);
    final from =
        Offset(box.center.dx + 60, box.center.dy + (dy < 0 ? 120 : -120))
            .translate(0, 0);
    await moveTo(from);
    final g = await tester.startGesture(from);
    press.value = 1;
    final start = now;
    const seconds = 0.7;
    var last = from;
    while (now < start + seconds) {
      final t = Curves.easeInOutCubic
          .transform(((now - start) / seconds).clamp(0.0, 1.0));
      final at = from + Offset(0, dy * t);
      await g.moveBy(at - last);
      last = at;
      hand.value = at;
      await _step();
    }
    // Held still a moment first, so letting go does not fling the list.
    await hold(seconds: 0.15);
    await g.up();
    press.value = 0;
    await hold(seconds: 0.2);
  }

  /// Scrolls until [f] is on screen, [up] px above the bottom at least.
  Future<void> scrollTo(Finder f, {double up = 160}) async {
    for (int i = 0; i < 8; i++) {
      if (f.evaluate().isNotEmpty) {
        final y = tester.getCenter(f.first).dy - _origin.dy;
        if (y > 90 && y < _screen.height - up) return;
        final dy = (_screen.height - up - 60) - y;
        await scroll(find.byType(Scrollable).first, dy.clamp(-320.0, 320.0));
      } else {
        await scroll(find.byType(Scrollable).first, -300);
      }
    }
  }

  /// A swipe across [f] by [dx], as to remove a child.
  Future<void> swipe(Finder f, double dx) async {
    _target = null;
    fromAbove.value = false;
    final from = tester.getCenter(f.first) + const Offset(60, 0);
    await moveTo(from);
    final g = await tester.startGesture(from);
    press.value = 1;
    final start = now;
    const seconds = 0.5;
    var last = from;
    while (now < start + seconds) {
      final t = ((now - start) / seconds).clamp(0.0, 1.0);
      final at = from + Offset(dx * t, 0);
      await g.moveBy(at - last);
      last = at;
      hand.value = at;
      await _step();
    }
    await g.up();
    press.value = 0;
  }

  Future<void> finish() async {
    File('${dir.path}/meta.json').writeAsStringSync(
        jsonEncode({'fps': _fps, 'frames': _frame, 'cues': []}));
    hand.value = null;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }
}

/// The card under the phone: which step of the guide this is, how far
/// along, and what the hand is showing. Button names in quotes come out in
/// the app's violet instead.
class _Words extends StatelessWidget {
  const _Words(this.rec);

  final _Rec rec;

  static List<InlineSpan> _spans(String text) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in RegExp(r'"([^"]+)"').allMatches(text)) {
      out.add(TextSpan(text: text.substring(at, m.start)));
      out.add(TextSpan(
          text: m[1],
          style: const TextStyle(color: _violet, fontWeight: FontWeight.w700)));
      at = m.end;
    }
    out.add(TextSpan(text: text.substring(at)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rec.words, rec.section]),
      builder: (_, __) {
        final (n, of, title) = rec.section.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 24,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: _violet, shape: BoxShape.circle),
                  child: n == 0
                      ? const Icon(Icons.check_rounded,
                          size: 20, color: Colors.white)
                      : Text('$n',
                          style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n == 0 ? 'TAPOS NA' : 'HAKBANG $n NG $of',
                          style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B87AD))),
                      const SizedBox(height: 1),
                      Text(title,
                          style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 11),
              Row(children: [
                for (int i = 1; i <= of; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < of ? 4 : 0),
                      decoration: BoxDecoration(
                        color: n == 0 || i <= n
                            ? _violet
                            : const Color(0xFFE8E6F5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  // The old words gone before the new ones come: two sets
                  // crossing each other read as neither.
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: const Interval(0.5, 1),
                  switchOutCurve: const Interval(0.5, 1),
                  layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, if (current != null) current]),
                  child: Text.rich(
                    TextSpan(children: _spans(rec.words.value)),
                    key: ValueKey(rec.words.value),
                    style: const TextStyle(
                        fontFamily: 'Roboto',
                        // The ▶ of the button it points to.
                        fontFamilyFallback: ['Signs', 'Emoji'],
                        fontSize: 16,
                        height: 1.38,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF34315C)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The spotlight on what is being explained, the rest of the screen
/// dimmed, and the finger at the spotlight's edge. A press lights the
/// frame up rather than drawing a ring on top of the thing pressed.
class _HandLayer extends StatelessWidget {
  const _HandLayer(this.rec);

  final _Rec rec;

  static const _size = 54.0;

  /// Where the fingertip sits in the icon, pointing up.
  static const _tip = Offset(_size * 0.40, _size * 0.08);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([rec.hand, rec.press, rec.frame, rec.fromAbove]),
      builder: (_, __) {
        // Kept in canvas terms; drawn on the screen.
        final at = rec.hand.value?.translate(-_origin.dx, -_origin.dy);
        final p = rec.press.value;
        final shown = rec.frame.value;
        final down = rec.fromAbove.value;
        return Stack(children: [
          if (shown != null)
            Positioned.fill(
              child: CustomPaint(
                  painter:
                      _FramePainter(shown.$1.shift(-_origin), shown.$2, p)),
            ),
          if (at != null)
            Positioned(
              left: down ? at.dx - (_size - _tip.dx) : at.dx - _tip.dx,
              top: down
                  ? at.dy - (_size - _tip.dy) - 4 * p
                  : at.dy - _tip.dy + 4 * p,
              child: Transform.rotate(
                angle: down ? 3.14159265 : 0,
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: _size,
                  color: _ink,
                  shadows: [
                    Shadow(color: Colors.white, offset: Offset(2, 0)),
                    Shadow(color: Colors.white, offset: Offset(-2, 0)),
                    Shadow(color: Colors.white, offset: Offset(0, 2)),
                    Shadow(color: Colors.white, offset: Offset(0, -2)),
                    Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 4)),
                  ],
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.box, this.shown, this.press);

  final Rect box;
  final double shown;
  final double press;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(box, const Radius.circular(12));
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(
        dim, Paint()..color = const Color(0xFF0E0C24).withOpacity(0.5 * shown));
    // A soft violet glow outside, then a white edge with a violet line on
    // it: clear on the dimmed screen and on the app's own violet buttons.
    canvas.drawRRect(
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = _violet.withOpacity(0.45 * shown)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    if (press > 0) {
      canvas.drawRRect(
          hole, Paint()..color = _violet.withOpacity(0.16 * press));
    }
    canvas.drawRRect(
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Colors.white.withOpacity(shown));
    canvas.drawRRect(
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 + 1.5 * press
          ..color = _violet.withOpacity(shown));
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.box != box || old.shown != shown || old.press != press;
}

// ── The made-up class ──────────────────────────────────────────────────

final _today = DateTime.now();

/// A child's synced progress, in the shape the report reads: each module's
/// stars out of its ceiling, the weakest at a fraction of [overall].
Map<String, dynamic> _progress(double overall,
    {Map<String, Map<String, int>> misses = const {}}) {
  int part(int ceiling, double share) =>
      (ceiling * (overall * share).clamp(0.0, 1.0)).round();
  final mat = part(UserProvider.matematikaStarCeiling, 0.95);
  final magbasa = part(UserProvider.magbasaStarCeiling, 0.55);
  final kulay = part(UserProvider.kulayStarCeiling, 1.1);
  final trace = part(UserProvider.traceitStarCeiling, 0.8);
  const sariliCeiling =
      UserProvider.sariliStarCeiling + UserProvider.familyStarCeiling;
  final sarili = part(sariliCeiling, 0.7);
  final tandaan = part(UserProvider.tandaanStarCeiling, 0.9);
  final stars = mat + magbasa + kulay + trace + sarili + tandaan;
  return {
    'overallProgress': overall,
    'percentage': overall * 100,
    'totalStars': stars,
    'totalPossibleStars': UserProvider.totalPossibleStars,
    'dayStreak': 3,
    'lastPlayed': _today.subtract(const Duration(hours: 3)).toIso8601String(),
    'totalCompleted': (150 * overall).round(),
    'totalActivities': 150,
    'matematika': {
      'stars': mat,
      'possibleStars': UserProvider.matematikaStarCeiling,
      'completedLevels': (UserProvider.matematikaLevelCount * overall).round(),
      'totalLevels': UserProvider.matematikaLevelCount,
    },
    'magbasa': {
      'stars': magbasa,
      'possibleStars': UserProvider.magbasaStarCeiling,
      'totalCompleted': magbasa,
      'totalActivities': 19,
    },
    'kulay': {
      'stars': kulay,
      'possibleStars': UserProvider.kulayStarCeiling,
      'totalCompleted': kulay,
      'totalActivities': 9,
    },
    'traceit': {
      'stars': trace,
      'possibleStars': UserProvider.traceitStarCeiling,
      'totalCompleted': trace,
      'totalActivities': 62,
    },
    'pamilya': {
      'earnedStars': sarili,
      'possibleStars': sariliCeiling,
      'levelStars': [3, 3, 2, 1, 0, 0, 0, 0, 0],
    },
    'tandaan': {
      'stars': tandaan,
      'possibleStars': UserProvider.tandaanStarCeiling,
    },
    'practiceMisses': misses,
  };
}

Timestamp _ago(int days) =>
    Timestamp.fromDate(_today.subtract(Duration(days: days, hours: 2)));

final _kids = <Map<String, dynamic>>[
  {
    'name': 'Ana Mendoza Reyes',
    'username': 'ana4821',
    'lrn': 'DC-2026-4821',
    'password': 'DC-2026-4821',
    'avatar': 'girl1',
    'gender': 'Female',
    'parentName': 'Liza Reyes',
    'parentContact': '09181234567',
    'birthday': DateTime(2021, 3, 14).toIso8601String(),
    'lastActive': _ago(0),
    'progress': _progress(0.82, misses: {
      'matematika': {'2': 5, '4': 3},
      'pamilya': {'1': 2},
    }),
    'profile': {
      'stars': 45,
      'certificates': <String>['cert-a']
    },
  },
  {
    'name': 'Benjamin Cruz',
    'username': 'ben1234',
    'lrn': 'DC-2026-1234',
    'password': 'DC-2026-1234',
    'avatar': 'boy1',
    'gender': 'Male',
    'birthday': DateTime(2021, _today.month, _today.day).toIso8601String(),
    'lastActive': _ago(0),
    'progress': _progress(0.64),
    'profile': {'stars': 30},
  },
  {
    'name': 'Carlo Santos',
    'username': 'carlo9012',
    'lrn': 'DC-2026-9012',
    'password': 'DC-2026-9012',
    'avatar': 'animal_lion',
    'gender': 'Male',
    'birthday': DateTime(2021, 8, 2).toIso8601String(),
    'lastActive': _ago(2),
    'progress': _progress(0.12),
    'profile': {'stars': 5},
  },
  {
    'name': 'Dina Lopez',
    'username': 'dina3456',
    'lrn': 'DC-2026-3456',
    'password': 'DC-2026-3456',
    'avatar': 'animal_bunny',
    'gender': 'Female',
    'birthday': DateTime(2020, 12, 9).toIso8601String(),
    'lastActive': _ago(10),
    'progress': _progress(0.55),
    'profile': {'stars': 26},
  },
  {
    'name': 'Elena Garcia',
    'username': 'elena7788',
    'lrn': 'DC-2026-7788',
    'password': 'DC-2026-7788',
    'avatar': 'girl1',
    'gender': 'Female',
    'birthday': DateTime(2021, 1, 21).toIso8601String(),
    'lastActive': _ago(1),
    'progress': _progress(0.71),
    'profile': {'stars': 38},
  },
  {
    'name': 'Francis Dela Cruz',
    'username': 'francis5521',
    'lrn': 'DC-2026-5521',
    'password': 'DC-2026-5521',
    'avatar': 'boy1',
    'gender': 'Male',
    'birthday': DateTime(2021, 6, 30).toIso8601String(),
    'lastActive': _ago(3),
    'progress': _progress(0.48),
    'profile': {'stars': 20},
  },
];

final _ids = [for (var i = 0; i < _kids.length; i++) 'kid-$i'];

class _FakeSnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _FakeSnapshot(List<Map<String, dynamic>> rows)
      : docs = [
          for (var i = 0; i < rows.length; i++) _FakeDoc(_ids[i], rows[i])
        ];

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

// Stand-ins for a child's record; the real ones cannot be built in a test.
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

// ignore: subtype_of_sealed_class
class _FakeRecord extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeRecord(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;
}
