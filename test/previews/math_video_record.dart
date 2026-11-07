import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager, appTheme;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/screens/matematika_screen.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:e_tarabay/widgets/crayon_swatch.dart';
import 'package:e_tarabay/widgets/family_tree_picture.dart';
import 'package:e_tarabay/widgets/home_house.dart';
import 'package:e_tarabay/widgets/object_picture.dart';
import 'package:e_tarabay/widgets/pop_balloon.dart';
import 'package:e_tarabay/widgets/pressable.dart';
import 'package:e_tarabay/widgets/tip_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the "how to play" video of a Matematika level from the real
/// game: a hand plays the first question right, frame by frame. The frames
/// and the tap times land in build/math_videos/L<n>_<lang>/ for ffmpeg.
/// Color Fun gets one too, in build/math_videos/kulay_<lang>/.
/// Not part of the suite — run by hand:
///
///   flutter test test/previews/math_video_record.dart
const _fps = 30;
const _size = Size(360, 760);
const _ratio = 1.5;

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('mathvideo').path);
    final profile = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await profile.put('currentUser', {
      'name': 'Ana',
      'gender': 'Female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 24,
    });
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
      // For the few signs the bundled Roboto lacks (the arrow in a hint),
      // which a phone finds in its own fonts.
      ('Signs', [r'C:\Windows\Fonts\seguisym.ttf']),
      // The emoji in Ang Aking Sarili's pop-ups, which a phone has too.
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

  kulayVideo();
  traceVideo();
  tandaanVideo();
  pamilyaVideos();

  // Trace It with a letter open, the ones before it already finished.
  for (final letter in const ['A', 'M', 'T', 'W']) {
    testWidgets('trace $letter', (tester) async {
      const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      // Real time for the box: its file writes never finish on the test clock.
      await tester.runAsync(() async {
        final progress = Hive.box('userProgress');
        await progress.clear();
        for (int i = 0; i < abc.indexOf(letter); i++) {
          await progress.put('traceit_uppercase_$i', true);
        }
      });
      final rec = await _Recorder.open(tester,
          name: 'trace_$letter', home: const TraceItScreen(), lang: 'fil');
      await tester.tap(find.text(letter).first);
      await rec._settle(2);
      await rec.finish(at: 0.01);
    });
  }

  // Trace It on a short phone, where the letter must stay under the corners.
  testWidgets('trace short', (tester) async {
    final rec = await _Recorder.open(tester,
        name: 'trace_short',
        home: const TraceItScreen(),
        view: const Size(360, 640),
        lang: 'fil');
    await tester.tap(find.text('A').first);
    await rec._settle(2);
    await rec.finish(at: 0.01);
  });

  // One still each of the headers with the ▶ Panoorin pill, at 360 wide.
  testWidgets('pill, Numbers', (tester) async {
    final rec =
        await _Recorder.open(tester, level: 0, name: 'pill_math', lang: 'fil');
    await rec.finish(at: 0.01);
  });
  testWidgets('pill, Trace It', (tester) async {
    final rec = await _Recorder.open(tester,
        name: 'pill_trace', home: const TraceItScreen(), lang: 'fil');
    await tester.tap(find.text('A').first);
    await rec._settle(1);
    await rec.finish(at: 0.01);
  });
  testWidgets('pill, Tandaan', (tester) async {
    final rec = await _Recorder.open(tester,
        name: 'pill_tandaan', home: const TandaanScreen(), lang: 'fil');
    await tester.tap(find.byType(Pressable).at(0));
    await rec._settle(1);
    await rec.finish(at: 0.01);
  });
  testWidgets('pill, Color Fun', (tester) async {
    final rec = await _Recorder.open(tester,
        name: 'pill_kulay', home: const KulayScreen(), lang: 'fil');
    await rec.finish(at: 0.01);
  });

  // Each video's beats come from its voice/L<n>_fil.words.json; the voice
  // starts [_v] seconds in, so a word at w seconds is on screen at w + _v.
  testWidgets('level 1, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 0, lang: 'fil');
    final apples = find.byType(ObjectPicture);
    await rec.enter(tester.getCenter(apples.at(0)) + const Offset(0, 60),
        until: 2.2 + _v);
    for (final (i, at) in const [(0, 3.2), (1, 4.01), (2, 4.82)]) {
      final apple = tester.getRect(apples.at(i));
      await rec.moveTo(apple.center, until: at + _v - 0.05);
      await rec.point(label: '${i + 1}', over: apple.topCenter);
    }
    final three = _lowest(tester, find.text('3'));
    await rec.moveTo(tester.getCenter(three), until: 7.9 + _v);
    await rec.tap(right: true);
    await rec.leave(from: 9.2 + _v, until: 10.0 + _v);
    await rec.finish(at: 11.0);
  });

  testWidgets('level 2, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 1, lang: 'fil');
    final flowers = find.byType(ObjectPicture);
    await rec.enter(tester.getCenter(flowers.at(0)) + const Offset(0, 80),
        until: 1.4 + _v);
    for (final (i, at) in const [(0, 2.13), (1, 3.03)]) {
      final f = tester.getRect(flowers.at(i));
      await rec.moveTo(f.center, until: at + _v - 0.05);
      await rec.point(label: '${i + 1}', over: f.topCenter);
    }
    final chip = _chip(2), basket = find.byType(DragTarget<int>);
    await rec.moveTo(tester.getCenter(chip), until: 5.4 + _v);
    rec.clearLabels();
    await rec.grab();
    await rec.moveTo(tester.getCenter(basket), until: 7.0 + _v);
    await rec.release(right: true);
    await rec.leave(from: 8.2 + _v, until: 9.0 + _v);
    await rec.finish(at: 11.6);
  });

  testWidgets('level 3, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 2, lang: 'fil');
    // On the left the groups of one, two and three apples, top to bottom.
    final apples = find.byType(ObjectPicture);
    Rect group(int i) {
      final from = const [0, 1, 3][i];
      var r = tester.getRect(apples.at(from));
      for (int j = from; j < from + i + 1; j++) {
        r = r.expandToInclude(tester.getRect(apples.at(j)));
      }
      return r;
    }

    Finder number(int n) {
      final f = find.text('$n');
      for (int i = 0; i < f.evaluate().length; i++) {
        final c = tester.getCenter(f.at(i));
        if (c.dx > _size.width / 2 && c.dy > 200) return f.at(i);
      }
      throw StateError('no $n on the right');
    }

    await rec.enter(group(0).center + const Offset(40, 80));
    for (final (i, left, right) in const [
      (0, 2.99, 4.44),
      (1, 5.25, 6.70),
      (2, 7.55, 9.09),
    ]) {
      await rec.moveTo(group(i).center, until: left + _v - 0.1);
      await rec.tap();
      final n = number(i + 1);
      await rec.moveTo(tester.getCenter(n), until: right + _v - 0.1);
      await rec.tap(right: i == 2);
    }
    await rec.leave(from: 10.6 + _v, until: 11.4 + _v);
    await rec.finish(at: 14.0);
  });

  testWidgets('level 4, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 3, lang: 'fil');
    final threes =
        find.byWidgetPredicate((w) => w is PopBalloon && w.value == 3);
    await rec.enter(tester.getCenter(threes.at(0)) + const Offset(30, 120));
    for (final (i, at) in const [(0, 2.82), (1, 3.67)]) {
      await rec.moveTo(tester.getCenter(threes.at(i)), until: at + _v - 0.1);
      await rec.tap(right: i == 1);
    }
    await rec.leave(from: 5.0 + _v, until: 5.8 + _v);
    await rec.finish(at: 7.6);
  });

  testWidgets('level 5, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 4, lang: 'fil');
    // Three apples on the left, one on the right.
    final apples = find.byType(ObjectPicture);
    Rect side(List<int> of) {
      var r = tester.getRect(apples.at(of.first));
      for (final i in of) {
        r = r.expandToInclude(tester.getRect(apples.at(i)));
      }
      return r;
    }

    final left = side(const [0, 1, 2]), right = side(const [3]);
    await rec.enter(left.center + const Offset(60, 80));
    await rec.moveTo(left.center, until: 2.6 + _v - 0.05);
    await rec.point(label: '3', over: left.topCenter);
    await rec.moveTo(right.center, until: 4.27 + _v - 0.05);
    await rec.point(label: '1', over: right.topCenter);
    await rec.moveTo(left.center, until: 7.6 + _v);
    rec.clearLabels();
    await rec.tap(right: true);
    await rec.leave(from: 8.9 + _v, until: 9.7 + _v);
    await rec.finish(at: 11.0);
  });

  testWidgets('level 6, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 5, lang: 'fil');
    final slots = find.byType(DragTarget<int>);
    await rec.enter(tester.getCenter(_chip(1)) + const Offset(30, 90));
    await rec.moveTo(tester.getCenter(_chip(1)), until: 1.9 + _v);
    for (final (n, at) in const [(1, 2.73), (2, 3.71), (3, 4.78)]) {
      if (n > 1) {
        await rec.moveTo(tester.getCenter(_chip(n)), until: at + _v - 0.6);
      }
      await rec.grab();
      await rec.moveTo(tester.getCenter(slots.at(n - 1)), until: at + _v);
      await rec.release(right: n == 3);
    }
    await rec.leave(from: 6.4 + _v, until: 7.2 + _v);
    await rec.finish(at: 10.0);
  });

  testWidgets('level 7, Filipino', (tester) async {
    final rec = await _Recorder.open(tester, level: 6, lang: 'fil');
    // The row along the top: 1 2 ? 4 5.
    Finder top(String t) => _highest(tester, find.text(t));
    await rec.enter(tester.getCenter(top('1')) + const Offset(40, 120));
    for (final (t, at) in const [
      ('1', 2.30),
      ('2', 3.16),
      ('4', 4.14),
      ('5', 4.82),
      ('?', 5.67),
    ]) {
      await rec.moveTo(tester.getCenter(top(t)), until: at + _v - 0.05);
      await rec.point();
    }
    final three = _lowest(tester, find.text('3'));
    await rec.moveTo(tester.getCenter(three), until: 7.7 + _v);
    await rec.tap(right: true);
    await rec.leave(from: 9.0 + _v, until: 9.8 + _v);
    await rec.finish(at: 11.4);
  });
}

/// Color Fun: a picture is picked, colored by rubbing in two colors, rubbed
/// with the eraser, enlarged and fitted again, then pinched and slid with
/// two fingers.
void kulayVideo() {
  testWidgets('kulay, Filipino', (tester) async {
    final rec = await _Recorder.open(tester,
        name: 'kulay', home: const KulayScreen(), lang: 'fil');
    await rec.enter(tester.getCenter(find.text('Mga Hayop')),
        until: 4.35 + _v - 0.1);
    await rec.tap();
    await rec.loading(until: 5.4 + _v);
    await rec.moveTo(tester.getCenter(find.text('Tuta')),
        until: 5.59 + _v - 0.05);
    await rec.tap();
    await rec.loading(until: 7.2 + _v);

    final board = tester.getRect(find.byType(InteractiveViewer));
    Offset at(double x, double y) =>
        board.topLeft + Offset(board.width * x, board.height * y);
    // Back and forth inside one part of the picture: the color stays in
    // the part the rub starts in, so each one starts well inside it.
    Future<void> rub(Rect part,
        {required double from, required double until}) async {
      await rec.moveTo(at(part.left, part.top), until: from - 0.15);
      await rec.grab();
      const turns = 10;
      final step = (until - rec.now) / turns;
      for (int i = 1; i <= turns; i++) {
        await rec.moveTo(
            at(i.isOdd ? part.right : part.left,
                part.top + part.height * i / turns),
            until: rec.now + step);
      }
      await rec.release();
    }

    Future<void> press(Finder f, {required double until}) async {
      await rec.moveTo(tester.getCenter(f), until: until);
      await rec.tap();
    }

    // Where the puppy is on its page, as fractions of the board.
    const body = Rect.fromLTRB(0.30, 0.58, 0.62, 0.72);
    const head = Rect.fromLTRB(0.50, 0.20, 0.70, 0.32);
    const rubOut = Rect.fromLTRB(0.32, 0.60, 0.46, 0.70);

    final crayons = find.byType(CrayonSwatch);
    await press(crayons.at(0), until: 7.6 + _v);
    await rub(body, from: 9.73 + _v, until: 12.9 + _v);
    await press(crayons.at(3), until: 13.5 + _v);
    await rub(head, from: 14.46 + _v, until: 15.9 + _v);
    await press(find.text('Burahin'), until: 17.5 + _v);
    await rub(rubOut, from: 18.29 + _v, until: 19.5 + _v);
    await press(find.text('Palakihin'), until: 21.3 + _v);
    await press(find.text('Iangkop'), until: 24.0 + _v);

    // Two fingers: spread apart to enlarge, then slid together to move.
    final mid = at(0.5, 0.5);
    rec.second.value = Offset(-60, mid.dy + 40);
    await rec.moveBoth(mid + const Offset(25, 20), mid + const Offset(-25, -20),
        until: 26.7 + _v);
    await rec.bothDown();
    await rec.moveBoth(mid + const Offset(62, 50), mid + const Offset(-62, -50),
        until: 29.8 + _v);
    await rec.hold(until: 30.8 + _v);
    await rec.moveBoth(mid + const Offset(122, 120), mid + const Offset(-2, 20),
        until: 32.8 + _v);
    await rec.bothUp();
    await rec.hold(until: 34.5 + _v);
    rec._cue('chime');
    await rec.moveBoth(Offset(_size.width - 30, _size.height + 80),
        Offset(-80, _size.height + 80),
        until: 35.6 + _v);
    await rec.finish(at: 38.2);
  });
}

/// Trace It: A is picked on the wall and traced stroke by stroke, with one
/// slip off the line on the way, where the dot goes back to its start.
void traceVideo() {
  testWidgets('trace, Filipino', (tester) async {
    await tester.runAsync(() => Hive.box('userProgress').clear());
    final rec = await _Recorder.open(tester,
        name: 'trace', home: const TraceItScreen(), lang: 'fil');
    await rec.enter(tester.getCenter(find.text('A').first), until: 1.4);
    await rec.tap();
    await rec.loading(until: 2.6);

    // Where the strokes are on screen, read off the painter of the letter.
    final paint = find.byWidgetPredicate((w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_StrokeFillPainter' &&
        (w.painter as dynamic).guide != null);
    final p = tester.widget<CustomPaint>(paint).painter as dynamic;
    final origin = tester.getTopLeft(paint);
    List<Offset> stroke(int i) => [
          for (final d in (p.strokes as List<List<Offset>>)[i])
            origin + d * (p.scale as double) + (p.offset as Offset)
        ];

    final one = stroke(0);
    await rec.moveTo(one.first, until: 3.6);
    await rec.hold(until: 3.9);
    await rec.grab();
    await rec.trace(one, to: 0.45, until: 5.1);
    await rec.moveTo(rec.hand.value! + const Offset(60, 0), until: 5.5);
    await rec.release();
    await rec.hold(until: 6.6);
    for (final (i, from, until) in const [
      (0, 7.4, 8.9),
      (1, 9.7, 11.2),
      (2, 12.0, 13.2),
    ]) {
      final line = stroke(i);
      await rec.moveTo(line.first, until: from);
      await rec.grab();
      await rec.trace(line, until: until);
      await rec.release(right: i == 2);
    }
    await rec.leave(from: 13.4, until: 14.0);
    await rec.finish(at: 14.1);
  });
}

/// Tandaan!: the cards are shown, then one pair that does not match turns
/// back over, and the three pairs are found.
void tandaanVideo() {
  testWidgets('tandaan, Filipino', (tester) async {
    final rec = await _Recorder.open(tester,
        name: 'tandaan', home: const TandaanScreen(), lang: 'fil');
    await rec.enter(tester.getCenter(find.byType(Pressable).at(0)), until: 1.4);
    await rec.tap();
    await rec.loading(until: 2.4);

    // The pairs, read while every card is face up: each name is on two.
    final pairs = <List<Offset>>[];
    for (final label in const [
      'Aso',
      'Pusa',
      'Kalabaw',
      'Baboy',
      'Manok',
      'Kuneho'
    ]) {
      final f = find.text(label);
      if (f.evaluate().length == 2) {
        pairs.add([tester.getCenter(f.at(0)), tester.getCenter(f.at(1))]);
      }
    }
    expect(pairs, hasLength(3), reason: 'the three pairs on the board');

    await rec.moveTo(pairs[0][0], until: 3.6);
    await rec.moveTo(pairs[0][1], until: 4.8);
    await rec.moveTo(pairs[1][0], until: 6.0);
    await rec.hold(until: 8.6);
    // Two that are not the same: they turn back over.
    await rec.tap();
    await rec.moveTo(pairs[0][0], until: 9.6);
    await rec.tap();
    await rec.hold(until: 11.6);
    var at = 12.4;
    for (final pair in pairs) {
      for (final (j, card) in pair.indexed) {
        await rec.moveTo(card, until: at);
        await rec.tap(right: j == 1);
        at += j == 0 ? 0.9 : 1.2;
      }
    }
    await rec.leave(from: at - 0.6, until: at);
    await rec.finish(at: at + 0.6);
  });
}

/// Ang Aking Sarili's two boards, past the seven questions before each.
void pamilyaVideos() {
  /// Opens the lesson called [title] and answers its questions off camera until
  /// [board] is up.
  Future<_Recorder> openBoard(
      WidgetTester tester, String name, String title, Finder board) async {
    final rec = await _Recorder.open(tester,
        name: name, home: const PamilyaScreen(), lang: 'fil');
    final lesson = find.text(title);
    await tester.ensureVisible(lesson);
    await rec._settle(1);
    await tester.tap(lesson);
    await rec._settle(2);
    for (int q = 0; q < 12 && board.evaluate().isEmpty; q++) {
      await tester.tap(find.byType(AnswerTile).first);
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }
    expect(board, findsOneWidget);
    await rec._settle(1);
    return rec;
  }

  /// The pop-up that says what was tapped.
  final tip = find.byType(TipCloud);

  /// Leaves the pop-up up long enough to see, then closes it with a tap.
  Future<void> readTip(WidgetTester tester, _Recorder rec) async {
    await rec.hold(until: rec.now + 2.2);
    if (tip.evaluate().isEmpty) return;
    await rec.moveTo(tester.getCenter(tip), until: rec.now + 0.6);
    await rec.tap();
    await rec.hold(until: rec.now + 0.5);
  }

  testWidgets('pill, Pamilya', (tester) async {
    final rec = await openBoard(tester, 'pill_pamilya', 'Talaan ng Pamilya',
        find.byType(FamilyTreePicture));
    await rec.finish(at: 0.01);
  });

  testWidgets('tree, Filipino', (tester) async {
    final tree = find.byType(FamilyTreePicture);
    final rec = await openBoard(tester, 'tree', 'Talaan ng Pamilya', tree);
    final pic = tester
        .getRect(find.descendant(of: tree, matching: find.byType(Image)).first);
    Offset face(double x, double y) =>
        pic.topLeft + Offset(pic.width * x / 900, pic.height * y / 1574);
    await rec.enter(face(160, 1020), until: 1.6);
    // A grandfather, a father, a big brother.
    for (final (x, y) in const [
      (160.0, 1020.0),
      (233.0, 625.0),
      (125.0, 232.0)
    ]) {
      await rec.moveTo(face(x, y), until: rec.now + 0.8);
      await rec.tap();
      await readTip(tester, rec);
    }
    await rec.moveTo(tester.getCenter(find.byType(ElevatedButton)),
        until: rec.now + 0.9);
    await rec.tap(right: true);
    final end = rec.now;
    await rec.leave(from: end + 0.8, until: end + 1.5);
    await rec.finish(at: end + 2.6);
  });

  testWidgets('home, Filipino', (tester) async {
    final house = find.byType(HomeHouse);
    final rec = await openBoard(tester, 'home', 'Ang Aking Tahanan', house);
    final box = tester.getRect(house);
    // The picture keeps its shape inside the box.
    final w = box.height * 900 / 1241 > box.width
        ? box.width
        : box.height * 900 / 1241;
    final pic =
        Rect.fromCenter(center: box.center, width: w, height: w * 1241 / 900);
    Offset room(double x, double y) =>
        pic.topLeft + Offset(pic.width * x, pic.height * y);
    // The middle of each room, in the order the things come: living room,
    // kitchen, bedroom, bathroom, yard.
    final rooms = [
      room(0.29, 0.63),
      room(0.70, 0.33),
      room(0.29, 0.33),
      room(0.70, 0.63),
      room(0.50, 0.88),
    ];
    await rec.enter(rooms[0], until: 1.0);
    await rec.hold(until: 1.8);
    for (final (i, r) in rooms.indexed) {
      await rec.moveTo(r, until: rec.now + 0.9);
      await rec.tap(right: i == 4);
      if (i < 4) await readTip(tester, rec);
    }
    final end = rec.now;
    await rec.leave(from: end + 0.8, until: end + 1.5);
    await rec.finish(at: end + 3.0);
  });
}

/// When the voice starts, in seconds.
const _v = 0.6;

/// The number chip [n] that can be dragged.
Finder _chip(int n) => find
    .ancestor(of: find.text('$n'), matching: find.byType(Draggable<int>))
    .first;

/// The highest match on screen.
Finder _highest(WidgetTester tester, Finder f) {
  var best = 0;
  for (int i = 0; i < f.evaluate().length; i++) {
    if (tester.getCenter(f.at(i)).dy < tester.getCenter(f.at(best)).dy) {
      best = i;
    }
  }
  return f.at(best);
}

/// The answer tile of [f]: the lowest match on screen, under the board.
Finder _lowest(WidgetTester tester, Finder f) {
  var best = 0;
  for (int i = 0; i < f.evaluate().length; i++) {
    if (tester.getCenter(f.at(i)).dy > tester.getCenter(f.at(best)).dy) {
      best = i;
    }
  }
  return f.at(best);
}

class _Recorder {
  _Recorder(this.tester, this.dir);

  final WidgetTester tester;
  final Directory dir;
  final GlobalKey _frameKey = GlobalKey();
  final hand = ValueNotifier<Offset?>(null);
  final second = ValueNotifier<Offset?>(null);
  final press = ValueNotifier<double>(0);
  final labels = ValueNotifier<List<(Offset, String)>>([]);
  final cues = <Map<String, Object>>[];
  int _frame = 0;
  TestGesture? _down;

  double get now => _frame / _fps;

  /// Opens Matematika at [level], or with [home] the screen given, which
  /// is recorded as [name].
  static Future<_Recorder> open(WidgetTester tester,
      {int? level,
      String? name,
      Widget? home,
      Map<String, Object> prefs = const {},
      Size? view,
      required String lang}) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.devicePixelRatio = _ratio;
    tester.view.physicalSize = (view ?? _size) * _ratio;
    addTearDown(tester.view.reset);

    final dir =
        Directory('build/math_videos/${name ?? 'L${level! + 1}'}_$lang');
    dir.createSync(recursive: true);
    for (final f in dir.listSync().whereType<File>()) {
      f.deleteSync();
    }
    final rec = _Recorder(tester, dir);

    final theme = appTheme();
    await tester.pumpWidget(RepaintBoundary(
      key: rec._frameKey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(children: [
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => UserProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider(lang)),
              ChangeNotifierProvider<AudioManager>.value(
                  value: AudioManager.instance),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme.copyWith(
                  textTheme: theme.textTheme.apply(
                      fontFamily: 'Roboto',
                      fontFamilyFallback: ['Emoji', 'Signs']),
                  // The buttons' own text style names no face either.
                  elevatedButtonTheme: ElevatedButtonThemeData(
                      style: theme.elevatedButtonTheme.style?.copyWith(
                          textStyle: const WidgetStatePropertyAll(TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.bold))))),
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home ?? const MatematikaScreen(),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: _HandLayer(rec))),
        ]),
      ),
    ));
    await rec._settle(3);
    if (level == null) return rec;
    final card = find.byType(Pressable).at(level);
    await tester.ensureVisible(card);
    await rec._settle(1);
    await tester.tap(card);
    await rec._settle(3);
    return rec;
  }

  Future<void> _settle(int seconds) async {
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

  /// One frame of the video: a step of the clock, then a picture of it.
  Future<void> _step() async {
    await tester.pump(const Duration(microseconds: 1000000 ~/ _fps));
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

  /// Frames while a new screen opens: real time passes between them too, so
  /// its pictures are read from disk and decoded as it slides in.
  Future<void> loading({required double until}) async {
    while (now < until) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      if (_frame % 6 == 0) {
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            try {
              await precacheImage(
                  img.image, tester.element(find.byWidget(img).first));
            } catch (_) {}
          }
        });
      }
      await _step();
    }
  }

  Future<void> hold({required double until}) async {
    while (now < until) {
      await _step();
    }
  }

  /// Glides the hand's fingertip to [to], arriving at [until].
  Future<void> moveTo(Offset to, {required double until}) async {
    final from = hand.value ?? to;
    final start = now;
    final span = (until - start).clamp(1 / _fps, 99.0);
    while (now < until) {
      final t =
          Curves.easeInOutCubic.transform(((now - start) / span).clamp(0, 1));
      hand.value = Offset.lerp(from, to, t);
      await _down?.moveTo(hand.value!);
      await _step();
    }
    hand.value = to;
  }

  /// Drags the finger along [line] at an even pace, [to] of the way along
  /// it by [until]. Tracing stops a finger that runs too far ahead in one
  /// move, so this never speeds up in the middle as [moveTo] does.
  Future<void> trace(List<Offset> line,
      {double to = 1, required double until}) async {
    final ends = <double>[0];
    for (int i = 1; i < line.length; i++) {
      ends.add(ends.last + (line[i] - line[i - 1]).distance);
    }
    Offset along(double d) {
      for (int i = 1; i < line.length; i++) {
        if (d <= ends[i] || i == line.length - 1) {
          final t = ((d - ends[i - 1]) / (ends[i] - ends[i - 1])).clamp(0, 1);
          return Offset.lerp(line[i - 1], line[i], t.toDouble())!;
        }
      }
      return line.last;
    }

    final start = now, span = (until - start).clamp(1 / _fps, 99.0);
    while (now < until) {
      final t = ((now + 1 / _fps - start) / span).clamp(0.0, 1.0);
      hand.value = along(ends.last * to * t);
      await _down?.moveTo(hand.value!);
      await _step();
    }
  }

  /// The hand glides in from off the screen at the bottom right, to
  /// [toward] by [until].
  Future<void> enter(Offset toward, {double until = 1.0}) async {
    hand.value = Offset(_size.width - 30, _size.height + 60);
    await moveTo(toward, until: until);
  }

  /// Out at the bottom right, between [from] and [until].
  Future<void> leave({required double from, required double until}) async {
    await hold(until: from);
    await moveTo(Offset(_size.width - 30, _size.height + 80), until: until);
  }

  void clearLabels() => labels.value = [];

  /// A press of the finger that does not touch the game: for counting.
  Future<void> point({String? label, Offset? over}) async {
    _cue('click');
    if (label != null && over != null) {
      labels.value = [...labels.value, (over, label)];
    }
    for (int i = 0; i < 8; i++) {
      press.value = i < 3 ? (i + 1) / 3 : 1 - (i - 2) / 6;
      await _step();
    }
    press.value = 0;
  }

  /// A real tap on the game where the fingertip is. [right] is the answer
  /// that wins the question, which rings the chime.
  Future<void> tap({bool right = false}) async {
    _cue('pop');
    labels.value = [];
    final g = await tester.startGesture(hand.value!);
    for (int i = 0; i < 4; i++) {
      press.value = (i + 1) / 4;
      await _step();
    }
    await g.up();
    if (right) _cue('chime');
    for (int i = 0; i < 6; i++) {
      press.value = 1 - (i + 1) / 6;
      await _step();
    }
  }

  /// Puts the finger down to drag: [moveTo] carries what it holds.
  Future<void> grab() async {
    _cue('click');
    _down = await tester.startGesture(hand.value!);
    for (int i = 0; i < 4; i++) {
      press.value = (i + 1) / 4;
      await _step();
    }
  }

  /// Lets go of what the finger was dragging.
  Future<void> release({bool right = false}) async {
    await _down!.up();
    _down = null;
    _cue(right ? 'chime' : 'pop');
    for (int i = 0; i < 6; i++) {
      press.value = 1 - (i + 1) / 6;
      await _step();
    }
  }

  TestGesture? _down2;

  /// Both hands glide, the main one to [a] and the other to [b]; with the
  /// fingers down, that pinches or slides the picture.
  Future<void> moveBoth(Offset a, Offset b, {required double until}) async {
    final fromA = hand.value ?? a, fromB = second.value ?? b;
    final start = now;
    final span = (until - start).clamp(1 / _fps, 99.0);
    while (now < until) {
      final t =
          Curves.easeInOutCubic.transform(((now - start) / span).clamp(0, 1));
      hand.value = Offset.lerp(fromA, a, t);
      second.value = Offset.lerp(fromB, b, t);
      await _down?.moveTo(hand.value!);
      await _down2?.moveTo(second.value!);
      await _step();
    }
  }

  /// Both fingers down at once.
  Future<void> bothDown() async {
    _cue('click');
    _down = await tester.startGesture(hand.value!, pointer: 41);
    _down2 = await tester.startGesture(second.value!, pointer: 42);
    for (int i = 0; i < 4; i++) {
      press.value = (i + 1) / 4;
      await _step();
    }
  }

  Future<void> bothUp() async {
    await _down!.up();
    await _down2!.up();
    _down = _down2 = null;
    for (int i = 0; i < 6; i++) {
      press.value = 1 - (i + 1) / 6;
      await _step();
    }
  }

  void _cue(String sound) => cues.add({'t': now, 'sound': sound});

  Future<void> finish({required double at}) async {
    await hold(until: at);
    File('${dir.path}/meta.json').writeAsStringSync(
        jsonEncode({'fps': _fps, 'frames': _frame, 'cues': cues}));
    // Lets the game's own timers run out before the test ends.
    hand.value = second.value = null;
    labels.value = [];
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }
}

/// The finger: navy with a white edge, and a ring that opens on a press.
class _HandLayer extends StatelessWidget {
  const _HandLayer(this.rec);

  final _Recorder rec;

  static const _size = 64.0;
  static const _tip = Offset(_size * 0.40, _size * 0.10);

  /// A finger at [at], pressed [p] of the way down; [left] is the other
  /// hand, the same hand turned round.
  List<Widget> _finger(Offset at, double p, {bool left = false}) => [
        if (p > 0)
          Positioned(
            left: at.dx - 28,
            top: at.dy - 28,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.35 * p),
                border: Border.all(
                    color: const Color(0xFF1A8F5A).withOpacity(p), width: 4),
              ),
              transform: Matrix4.identity()
                ..translate(28.0, 28.0)
                ..scale(0.6 + 0.4 * p)
                ..translate(-28.0, -28.0),
            ),
          ),
        Positioned(
          left: left ? at.dx - (_size - _tip.dx) : at.dx - _tip.dx,
          top: at.dy - _tip.dy + 6 * p,
          child: Transform.scale(
            scaleX: (left ? -1 : 1) * (1 - 0.08 * p),
            scaleY: 1 - 0.08 * p,
            child: const Icon(
              Icons.touch_app_rounded,
              size: _size,
              color: Color(0xFF26215C),
              shadows: [
                Shadow(color: Colors.white, offset: Offset(2, 0)),
                Shadow(color: Colors.white, offset: Offset(-2, 0)),
                Shadow(color: Colors.white, offset: Offset(0, 2)),
                Shadow(color: Colors.white, offset: Offset(0, -2)),
                Shadow(
                    color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([rec.hand, rec.second, rec.press, rec.labels]),
      builder: (_, __) {
        final at = rec.hand.value;
        if (at == null) return const SizedBox.shrink();
        final p = rec.press.value;
        return Stack(children: [
          // Numbers counted so far, each over the thing it counted.
          for (final (o, text) in rec.labels.value)
            Positioned(
              left: o.dx - 22,
              top: o.dy - 40,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFC83D),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Text(text,
                    style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF26215C))),
              ),
            ),
          ..._finger(at, p),
          if (rec.second.value != null)
            ..._finger(rec.second.value!, p, left: true),
        ]);
      },
    );
  }
}
