import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/main.dart' show AudioManager;
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/teacher_dashboard_screen.dart';
import 'package:e_tarabay/services/teacher_pin.dart';
import 'package:e_tarabay/widgets/how_to_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// A player that needs no platform: ready at once, as long as the guide,
/// so a part chosen near the end is not past it.
class _FakeVideo extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakeVideo() : super(const VideoPlayerValue(duration: Duration.zero));

  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  Future<void> initialize() async => value = const VideoPlayerValue(
      duration: Duration(milliseconds: 199400),
      size: Size(800, 2000),
      isInitialized: true);

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> seekTo(Duration position) async =>
      value = value.copyWith(position: position);

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async => super.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The teacher's guide: once by itself on the first visit to the class, and
/// again from the ▶ in the header whenever the teacher wants it.
void main() {
  final played = <String>[];
  late _FakeVideo video;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> empty;

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('teacherguide').path);
    await Hive.openBox('userProfile');
    await Hive.openBox('userProgress');
  });

  setUp(() async {
    played.clear();
    HowToVideo.controllerFor = (asset) {
      played.add(asset);
      return video = _FakeVideo();
    };
    // Agreed, and a PIN made: the class comes next.
    SharedPreferences.setMockInitialValues({
      'teacher_privacy_agreed_v1': true,
      'teacher_privacy_name': 'Maria Santos',
      'teacher_privacy_date': '2026-10-30T00:00:00.000',
    });
    FlutterSecureStorage.setMockInitialValues({});
    await TeacherPin.save('1234');
    // Broadcast: the second test opens the class twice.
    empty = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    TeacherDashboardScreen.debugStudents = empty.stream;
  });

  tearDown(() {
    HowToVideo.controllerFor = VideoPlayerController.asset;
    HowToVideo.autoPlay = false;
    TeacherDashboardScreen.debugStudents = null;
    empty.close();
  });

  Future<void> openClass(WidgetTester tester) async {
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
      child: const MaterialApp(
        locale: Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TeacherDashboardScreen(),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> skip(WidgetTester tester) async {
    await tester.tap(find.text('Laktawan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> close(WidgetTester tester) async {
    // Music has no player in a test and retries on a timer; let it give up.
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('the ▶ in the header plays the guide, and a tap pauses it',
      (tester) async {
    await openClass(tester);
    expect(played, isEmpty);

    await tester.tap(find.byTooltip('Paano gamitin ang app'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(played, [HowToVideo.teacherGuide]);
    expect(find.text('Laktawan'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(AspectRatio)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);

    await skip(tester);
    expect(find.text('Laktawan'), findsNothing);
    await close(tester);
  });

  testWidgets('a part chosen from the list plays on from its start',
      (tester) async {
    await openClass(tester);
    await tester.tap(find.byTooltip('Paano gamitin ang app'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Mga bahagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(video.value.isPlaying, isFalse);
    expect(find.text('Magpatala ng Mag-aaral'), findsOneWidget);

    await tester.tap(find.text('Magpatala ng Mag-aaral'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // The sheet's way down done, and its route gone with it.
    await tester.pump(const Duration(milliseconds: 100));
    expect(video.value.position, HowToVideo.teacherGuideParts[4].$2);
    expect(video.value.isPlaying, isTrue);
    // The list closed, the video still there.
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Laktawan'), findsOneWidget);

    await skip(tester);
    await close(tester);
  });

  testWidgets('the guide plays by itself on the first visit only',
      (tester) async {
    HowToVideo.autoPlay = true;
    await openClass(tester);
    expect(played, [HowToVideo.teacherGuide]);
    await skip(tester);

    await tester.pumpWidget(const SizedBox());
    await openClass(tester);
    expect(played, [HowToVideo.teacherGuide]);
    expect(find.text('Laktawan'), findsNothing);
    await close(tester);
  });
}
