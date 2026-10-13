import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/birthday_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the birthday overlay as a birthday child would actually meet it —
/// the moment the app opens on their day, and the moment they tap it away.
/// Not part of the suite — run by hand:
///
///   flutter test --update-goldens test/previews/birthday_preview.dart
void main() {
  setUpAll(() async {
    final file = File(r'C:\Windows\Fonts\arialbd.ttf');
    if (file.existsSync()) {
      final bytes = ByteData.view(file.readAsBytesSync().buffer);
      await (FontLoader('Roboto')..addFont(Future.value(bytes))).load();
    }

    // The card now plays real music, via a fresh AudioPlayer() the sandbox
    // has never constructed before. audioplayers' own first-use setup calls
    // out to a platform channel with nothing on the other end here, and does
    // it from a Future this test never gets a handle on — so the resulting
    // MissingPluginException cannot be caught from birthday_celebration.dart
    // at all; it surfaces after the test that triggered it has already
    // finished. Answering the channel here, the same way the framework's
    // own test bindings answer plugin channels, heads it off before it ever
    // throws.
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'), (_) async => null);
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'),
            (_) async => null);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 820));
    // setSurfaceSize alone only resizes the captured golden canvas — it does
    // not touch what MediaQuery reports inside the tree, which otherwise
    // stays at the harness's default 800x600. The card sizes its balloons
    // off MediaQuery's size, so left uncorrected they were laid out for an
    // 800-wide screen and then painted onto a 400-wide capture: balloons
    // meant to travel edge to edge crossed most of that in a single frame,
    // and half of the six behind the card landed past the right edge of the
    // image entirely.
    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fil'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          // The home screen's own background, so the overlay is seen the
          // way a child actually meets it: dropped over the dashboard they
          // just opened, not floating on plain white.
          backgroundColor: const Color(0xFFF7F9FC),
          body: Stack(
            children: [
              const Center(
                child: Text('E-Tarabay',
                    style: TextStyle(fontSize: 28, color: Colors.black26)),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showBirthdayCelebration(context, name: 'Juan'),
                  child: const Text('open'),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  // Not a preview — nothing here is asserted. audioplayers' very first
  // AudioPlayer() in this process kicks off a plugin-channel handshake that
  // throws once, asynchronously, after whichever test happened to be
  // running when it lands — the mock handlers above answer the channel but
  // do not stop that first attempt from firing. Spending that one failure
  // here, on a throwaway player nothing depends on, is what keeps it off
  // the three tests below that actually produce something to look at.
  testWidgets('warm up the audio plugin', (tester) async {
    await tester.runAsync(() async {
      final player = AudioPlayer();
      try {
        await player.play(AssetSource('audio/birthday/happy_birthday.mp3'));
      } catch (_) {
        // Expected here — see above.
      }
      await player.dispose();
    });
  });

  testWidgets('birthday card, settled', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('open'));
    await tester.pump(); // starts the route push
    // The confetti is a real loop and the party emoji breathes forever —
    // pumped in steps rather than pumpAndSettle, which would wait for those
    // to finish on their own and never return.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await expectLater(find.byType(BirthdayCelebrationOverlay),
        matchesGoldenFile('../../docs/previews/birthday_card_open.png'));
  });

  testWidgets('birthday card, mid-entrance', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    // Partway through the 400ms transitionDuration — the frame this test
    // exists to catch. Before the outer card rode the dialog's own
    // animation (see _CardEntrance), there was nothing to see here: the
    // card only ever animated in on its own one-shot effect, disconnected
    // from how far the dialog itself had actually opened.
    await tester.pump(const Duration(milliseconds: 160));
    await expectLater(find.byType(BirthdayCelebrationOverlay),
        matchesGoldenFile('../../docs/previews/birthday_card_entering.png'));
  });

  testWidgets('birthday card, mid-exit', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    // Dismiss the way a child actually does: tap the card's own OK button.
    await tester.tap(find.text('OK'));
    await tester.pump();
    // Partway through the close. This is the animation running in reverse —
    // the same _CardEntrance, the same curve family — not a separate exit
    // effect, so there is nothing extra to keep in sync by hand.
    await tester.pump(const Duration(milliseconds: 160));
    await expectLater(find.byType(BirthdayCelebrationOverlay),
        matchesGoldenFile('../../docs/previews/birthday_card_leaving.png'));
  });
}
