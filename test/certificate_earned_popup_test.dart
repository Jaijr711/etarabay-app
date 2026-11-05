import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/certificate_earned_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pop-up a child gets the moment the certificate is theirs (design A).
/// How it looks is drawn by test/previews/certificate_popup_preview.dart.
void main() {
  Future<Future<bool>> open(WidgetTester tester, String lang) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(400, 820) * 2;
    addTearDown(tester.view.reset);
    late Future<bool> result;
    await tester.pumpWidget(MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => result = showCertificateEarnedPopup(context,
                  name: 'Ana Mendoza Reyes'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    return result;
  }

  // The confetti and the entrance keep frames coming, so these pump for a
  // set time rather than settle.
  Future<void> close(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  for (final lang in ['fil', 'en']) {
    testWidgets('greets the child by first name, in $lang', (tester) async {
      await open(tester, lang);
      final loc = await AppLocalizations.delegate.load(Locale(lang));
      // The full name would not fit the title; the certificate has it.
      expect(find.text(loc.certEarnedTitle('Ana')), findsWidgets);
      expect(find.text(loc.certEarnedView), findsOneWidget);
      expect(find.text(loc.notNow), findsOneWidget);
      expect(find.text('ANA MENDOZA REYES'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    });
  }

  test('Ilokano has its own words for it', () async {
    final loc = await AppLocalizations.delegate.load(const Locale('ilo'));
    final fil = await AppLocalizations.delegate.load(const Locale('fil'));
    expect(loc.certEarnedTitle('Ana'), contains('Ana'));
    expect(loc.certEarnedBody, isNot(fil.certEarnedBody));
    expect(loc.certEarnedView, isNot(fil.certEarnedView));
  });

  testWidgets('"See my Certificate" answers yes', (tester) async {
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));
    final result = await open(tester, 'fil');
    await tester.tap(find.text(loc.certEarnedView));
    await close(tester);
    expect(await result, isTrue);
    expect(find.byType(CertificateEarnedPopup), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('"Not now" answers no', (tester) async {
    final loc = await AppLocalizations.delegate.load(const Locale('fil'));
    final result = await open(tester, 'fil');
    await tester.tap(find.text(loc.notNow));
    await close(tester);
    expect(await result, isFalse);
    expect(find.byType(CertificateEarnedPopup), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
