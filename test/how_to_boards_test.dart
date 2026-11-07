import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/pamilya_screen.dart';
import 'package:e_tarabay/screens/tandaan_screen.dart';
import 'package:e_tarabay/screens/trace_it_screen.dart';
import 'package:e_tarabay/widgets/answer_tile.dart';
import 'package:e_tarabay/widgets/custom_back_button.dart';
import 'package:e_tarabay/widgets/family_tree_picture.dart';
import 'package:e_tarabay/widgets/how_to_video.dart';
import 'package:e_tarabay/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// A player that needs no platform: ready at once and ten seconds long.
class _FakeVideo extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakeVideo(this.dataSource)
      : super(const VideoPlayerValue(duration: Duration.zero));

  @override
  final String dataSource;

  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  Future<void> initialize() async => value = const VideoPlayerValue(
      duration: Duration(seconds: 10),
      size: Size(540, 1140),
      isInitialized: true);

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async => super.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Sundan Mo, Tandaan! and Ang Aking Sarili's two boards each have a
/// how-to film: it plays by itself the first time, and ▶ Panoorin plays it
/// again.
void main() {
  final played = <String>[];

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('howtoboards').path);
    final profile = await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
    await profile.put('currentUser', {
      'name': 'Ana',
      'gender': 'Female',
      'birthday': DateTime(2021, 5, 3).toIso8601String(),
      'createdAt': DateTime(2026, 9, 6).toIso8601String(),
      'avatar': 'animal_bunny',
      'stars': 0,
    });
  });

  setUp(() {
    played.clear();
    HowToVideo.controllerFor = (asset) {
      played.add(asset);
      return _FakeVideo(asset);
    };
  });

  tearDown(() => HowToVideo.controllerFor = VideoPlayerController.asset);

  Future<void> open(WidgetTester tester, Widget screen,
      {bool firstTime = false}) async {
    SharedPreferences.setMockInitialValues({});
    HowToVideo.autoPlay = firstTime;
    addTearDown(() => HowToVideo.autoPlay = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 1100);
    addTearDown(tester.view.reset);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider('fil')),
        ChangeNotifierProvider<AudioManager>.value(
            value: AudioManager.instance),
      ],
      child: MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  final pill = find.text('Panoorin');
  final skip = find.text('Laktawan');

  Future<void> skipIt(WidgetTester tester) async {
    await tester.tap(skip);
    await settle(tester);
    expect(skip, findsNothing);
  }

  /// Lets the screen's own timers run out before the test ends.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('Sundan Mo: the first letter opened plays the film, once',
      (tester) async {
    await open(tester, const TraceItScreen(), firstTime: true);
    expect(pill, findsNothing, reason: 'nothing to watch on the wall');
    await tester.tap(find.text('A').first);
    await settle(tester);
    expect(skip, findsOneWidget);
    expect(played, ['assets/videos/trace_fil.mp4']);
    await skipIt(tester);

    // Back to the wall and into the letter again: not a second time.
    await tester.tap(find.byType(CustomBackButton));
    await settle(tester);
    await tester.tap(find.text('A').first);
    await settle(tester);
    expect(skip, findsNothing, reason: 'shown once per phone');

    await tester.tap(pill);
    await settle(tester);
    expect(skip, findsOneWidget);
    await skipIt(tester);
    await leave(tester);
  });

  testWidgets('Tandaan: the look at the cards starts again after the film',
      (tester) async {
    await open(tester, const TandaanScreen(), firstTime: true);
    await tester.tap(find.byType(Pressable).at(0));
    await settle(tester);
    expect(skip, findsOneWidget);
    expect(played, ['assets/videos/tandaan_fil.mp4']);

    // Longer than the whole look: none of it may run out behind the film.
    await tester.pump(const Duration(seconds: 5));
    await skipIt(tester);
    expect(find.text('Tandaan mo ang mga kard!'), findsOneWidget);

    await tester.tap(pill);
    await settle(tester);
    expect(skip, findsOneWidget);
    await skipIt(tester);
    await leave(tester);
  });

  testWidgets('Ang Aking Sarili: the family tree has its film, the quiz none',
      (tester) async {
    await open(tester, const PamilyaScreen(), firstTime: true);
    final lesson = find.text('Talaan ng Pamilya');
    await tester.ensureVisible(lesson);
    await settle(tester);
    await tester.tap(lesson);
    await settle(tester);
    expect(find.byType(AnswerTile), findsWidgets);
    expect(pill, findsNothing, reason: 'a question to answer needs no film');

    // Answered until the film covers the screen: the tree is under it.
    final tree = find.byType(FamilyTreePicture);
    for (int q = 0;
        q < 12 && tree.evaluate().isEmpty && skip.evaluate().isEmpty;
        q++) {
      await tester.tap(find.byType(AnswerTile).first);
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }
    await settle(tester);
    expect(skip, findsOneWidget);
    expect(played, ['assets/videos/tree_fil.mp4']);
    await skipIt(tester);
    expect(tree, findsOneWidget);

    await tester.tap(pill);
    await settle(tester);
    expect(skip, findsOneWidget);
    expect(played.last, 'assets/videos/tree_fil.mp4');
    await skipIt(tester);
    await leave(tester);
  });
}
