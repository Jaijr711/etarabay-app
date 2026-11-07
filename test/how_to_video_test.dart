import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/widgets/how_to_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// A player that needs no platform: it is ready at once, ten seconds long,
/// and plays only when told to.
class _FakeVideo extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakeVideo({this.fails = false})
      : super(const VideoPlayerValue(duration: Duration.zero));

  final bool fails;

  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  Future<void> initialize() async {
    if (fails) throw PlatformException(code: 'gone');
    value = const VideoPlayerValue(
        duration: Duration(seconds: 10),
        size: Size(540, 1140),
        isInitialized: true);
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> setVolume(double volume) async {}

  void reachEnd() => value = value.copyWith(position: value.duration);

  @override
  Future<void> dispose() async => super.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeVideo video;
  var fails = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fails = false;
    HowToVideo.controllerFor = (_) => video = _FakeVideo(fails: fails);
  });

  tearDown(() => HowToVideo.controllerFor = VideoPlayerController.asset);

  Future<void> openApp(WidgetTester tester, {bool pausable = false}) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanguageProvider('fil'),
      child: MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: PanoorinPill(
                  onTap: () => HowToVideo.show(
                      context, HowToVideo.assetFor(context, 'level1'),
                      pausable: pausable)),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> watch(WidgetTester tester) async {
    await tester.tap(find.text('Panoorin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  final skip = find.text('Laktawan');

  testWidgets('Panoorin plays the video; Laktawan closes it', (tester) async {
    await openApp(tester);
    await watch(tester);
    expect(skip, findsOneWidget);
    expect(video.value.isPlaying, isTrue);

    await tester.tap(skip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(skip, findsNothing);
    expect(find.text('Panoorin'), findsOneWidget);
  });

  testWidgets('the video closes by itself when it ends', (tester) async {
    await openApp(tester);
    await watch(tester);
    video.reachEnd();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(skip, findsNothing);
  });

  testWidgets('a tap on the picture does not pause it', (tester) async {
    await openApp(tester);
    await watch(tester);
    await tester.tapAt(tester.getCenter(find.byType(AspectRatio)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(video.value.isPlaying, isTrue);
    expect(skip, findsOneWidget);
    await tester.tap(skip);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets("the teacher's guide pauses at a tap and plays on at another",
      (tester) async {
    await openApp(tester, pausable: true);
    await watch(tester);
    final picture = tester.getCenter(find.byType(AspectRatio));
    await tester.tapAt(picture);
    await tester.pump(const Duration(milliseconds: 400));
    expect(video.value.isPlaying, isFalse);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    // Paused long past its length, it is still there to be read.
    await tester.pump(const Duration(seconds: 30));
    expect(skip, findsOneWidget);

    await tester.tapAt(picture);
    await tester.pump(const Duration(milliseconds: 400));
    expect(video.value.isPlaying, isTrue);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
    await tester.tap(skip);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('a video that will not load never leaves a black screen',
      (tester) async {
    fails = true;
    await openApp(tester);
    await watch(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(skip, findsNothing);
  });

  test('a first visit counts once per phone', () async {
    HowToVideo.autoPlay = true;
    addTearDown(() => HowToVideo.autoPlay = false);
    expect(await HowToVideo.claimFirstTime('math0'), isTrue);
    expect(await HowToVideo.claimFirstTime('math0'), isFalse);
    expect(await HowToVideo.claimFirstTime('math1'), isTrue);
  });

  test('two children on one phone each get their own first visit', () async {
    HowToVideo.autoPlay = true;
    addTearDown(() => HowToVideo.autoPlay = false);
    expect(await HowToVideo.claimFirstTime('math0', child: 'ana'), isTrue);
    expect(await HowToVideo.claimFirstTime('math0', child: 'ana'), isFalse);
    // Her brother, signed in on the same phone, has not seen it.
    expect(await HowToVideo.claimFirstTime('math0', child: 'ben'), isTrue);
    expect(await HowToVideo.claimFirstTime('math0', child: 'ben'), isFalse);
    // Nor has the phone itself, for the teacher's guide.
    expect(await HowToVideo.claimFirstTime('math0'), isTrue);
  });

  test('with videos off, nothing counts as a first visit', () async {
    expect(await HowToVideo.claimFirstTime('kulay'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('howto_seen_kulay'), isNull);
  });
}
