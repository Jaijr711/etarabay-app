import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/providers/language_provider.dart';
import 'package:e_tarabay/widgets/how_to_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// The teacher's guide player with its list of parts, at a phone's size:
/// playing, and with the list open part way through. The film itself has
/// no picture in a test; the rectangle it fills is written out beside each
/// shot, for a frame of the real video to be laid into it. Run by hand:
///
///   flutter test test/previews/teacher_parts_preview.dart
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

void main() {
  setUpAll(() async {
    for (final (family, files) in const [
      (
        'Roboto',
        [
          'assets/fonts/Roboto-regular.ttf',
          'assets/fonts/Roboto-medium.ttf',
          'assets/fonts/Roboto-bold.ttf',
        ]
      ),
      ('Fredoka', ['assets/fonts/Fredoka.ttf']),
      (
        'MaterialIcons',
        [
          r'C:\develop\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
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

  testWidgets('teacher parts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late _FakeVideo video;
    HowToVideo.controllerFor = (_) => video = _FakeVideo();
    addTearDown(() => HowToVideo.controllerFor = VideoPlayerController.asset);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 1520);
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: ChangeNotifierProvider(
        create: (_) => LanguageProvider('fil'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          locale: const Locale('fil'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => HowToVideo.show(
                      context, HowToVideo.teacherGuide,
                      pausable: true, parts: HowToVideo.teacherGuideParts),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final out = Directory('build/previews/teacher_parts')
      ..createSync(recursive: true);
    Future<void> shot(String name) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final rects = <String, List<double>>{
        'video': _ltrb(tester.getRect(find.byType(AspectRatio))),
        if (find.byType(BottomSheet).evaluate().isNotEmpty)
          'sheet': _ltrb(tester.getRect(find.byType(BottomSheet))),
      };
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        File('${out.path}/$name.json').writeAsStringSync(jsonEncode(rects));
      });
    }

    await tester.pump(const Duration(milliseconds: 100));
    await shot('playing');

    // Part way into "Magpatala ng Mag-aaral", then the list.
    video.value = video.value.copyWith(position: const Duration(seconds: 101));
    await tester.tap(find.text('Mga bahagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await shot('parts');

    // A part chosen: the film goes on from its start.
    await tester.tap(find.text('Progreso ng bata'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(video.value.position, const Duration(seconds: 141));
    expect(video.value.isPlaying, isTrue);
    await tester.tap(find.text('Laktawan'));
    await tester.pump(const Duration(milliseconds: 600));
  });
}

List<double> _ltrb(Rect r) => [r.left, r.top, r.right, r.bottom];
