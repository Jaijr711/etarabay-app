import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/screens/teacher_agreement_screen.dart';
import 'package:e_tarabay/services/teacher_privacy.dart';
import 'package:e_tarabay/widgets/teacher_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('coming back to the app', () {
    test('a teacher away for half a minute or more is asked again', () {
      expect(
          shouldLockTeacher(
              hasPin: true, role: 'teacher', away: const Duration(seconds: 30)),
          isTrue);
      expect(
          shouldLockTeacher(
              hasPin: true, role: 'teacher', away: const Duration(hours: 3)),
          isTrue);
    });

    test('a quick look at another app is let go', () {
      expect(
          shouldLockTeacher(
              hasPin: true, role: 'teacher', away: const Duration(seconds: 29)),
          isFalse);
    });

    test('with no PIN made yet there is no lock: the dashboard asks for one',
        () {
      expect(
          shouldLockTeacher(
              hasPin: false, role: 'teacher', away: const Duration(hours: 3)),
          isFalse);
    });

    test('a child or a logged-out phone is never locked', () {
      expect(
          shouldLockTeacher(
              hasPin: true, role: 'student', away: const Duration(minutes: 10)),
          isFalse);
      expect(
          shouldLockTeacher(
              hasPin: true, role: null, away: const Duration(minutes: 10)),
          isFalse);
    });
  });

  group('the privacy agreement', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a new phone has not agreed yet', () async {
      expect(await TeacherPrivacy.hasAgreed(), isFalse);
      expect(await TeacherPrivacy.agreement(), isNull);
    });

    test('agreeing is remembered with the name and the day', () async {
      await TeacherPrivacy.record('  Maria Santos ');
      expect(await TeacherPrivacy.hasAgreed(), isTrue);
      final agreed = await TeacherPrivacy.agreement();
      expect(agreed!.name, 'Maria Santos');
      expect(DateTime.now().difference(agreed.date).inMinutes, 0);
    });

    testWidgets('the dashboard opens only after signing and ticking',
        (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context)
                .push<bool>(MaterialPageRoute(
                    builder: (_) => const TeacherAgreementScreen())),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      ElevatedButton enter() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue to the dashboard'));
      expect(enter().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Maria Santos');
      await tester.pump();
      expect(enter().onPressed, isNull, reason: 'not ticked yet');

      await tester.ensureVisible(find.text('I agree to this agreement.'));
      await tester.pump();
      await tester.tap(find.text('I agree to this agreement.'));
      await tester.pump();
      expect(enter().onPressed, isNotNull);

      await tester.ensureVisible(find.text('Continue to the dashboard'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Continue to the dashboard'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(await tester.runAsync(TeacherPrivacy.hasAgreed), isTrue);
    });
  });
}
