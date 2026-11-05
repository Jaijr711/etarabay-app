import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/auth_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the teacher is told after removing or resetting a child. Offline,
/// nothing is sent and the teacher hears so; sent but not yet confirmed, it
/// finishes on its own — neither may read as a plain failure, which had
/// teachers press again and find it done twice later.
void main() {
  Future<BuildContext> contextIn(WidgetTester tester, String lang) async {
    // The app's own words only: Ilocano has no Material translations, and
    // none are needed to pick a message.
    late BuildContext captured;
    await tester.pumpWidget(Localizations(
      locale: Locale(lang),
      delegates: const [
        AppLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Builder(builder: (context) {
        captured = context;
        return const SizedBox();
      }),
    ));
    await tester.pump();
    return captured;
  }

  for (final lang in ['en', 'fil', 'ilo']) {
    testWidgets('$lang: offline, queued and failed each say their own thing',
        (tester) async {
      final context = await contextIn(tester, lang);
      final loc = AppLocalizations.of(context)!;
      final said = {
        for (final code in [
          'needsInternet',
          'finishesOnline',
          'removeFailed',
          'resetProgressFailed',
        ])
          code: authMessage(context, {'code': code, 'message': 'fallback'}),
      };
      expect(said['needsInternet'], loc.authNeedsInternet);
      expect(said['finishesOnline'], loc.authFinishesOnline);
      expect(said['removeFailed'], loc.authRemoveFailed);
      expect(said['resetProgressFailed'], loc.resetActivitiesFailed);
      expect(said.values.toSet(), hasLength(4));
      expect(said.values, isNot(contains('fallback')));
    });
  }

  testWidgets('the button that deletes the class does not say "reset"',
      (tester) async {
    for (final lang in ['en', 'fil', 'ilo']) {
      final context = await contextIn(tester, lang);
      final label = AppLocalizations.of(context)!.resetAllStudents;
      expect(label.toLowerCase(), isNot(contains('reset')), reason: lang);
      // Ilocano "isubli" is "to return / restore".
      expect(label.toLowerCase(), isNot(contains('isubli')), reason: lang);
    }
  });
}
