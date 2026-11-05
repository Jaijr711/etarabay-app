import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/screens/student_login_card_screen.dart';
import 'package:e_tarabay/widgets/reset_progress_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    );

void main() {
  group('the reset sheet', () {
    Future<({bool all, Set<String> keys})?> open(WidgetTester tester,
        {Set<String> preselect = const {}}) async {
      ({bool all, Set<String> keys})? picked;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked =
                await showModalBottomSheet<({bool all, Set<String> keys})>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ResetProgressSheet(
                  studentName: 'Ana Reyes', preselect: preselect),
            );
          },
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return picked;
    }

    ElevatedButton button(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byWidgetPredicate(
            (w) => w is ElevatedButton && w.child != null,
            description: 'reset button'));

    testWidgets('does nothing until the warning is ticked', (tester) async {
      await open(tester, preselect: {'matematika'});
      expect(find.text('Reset (1)'), findsOneWidget);
      expect(button(tester).onPressed, isNull);

      await tester.tap(find.text('I understand this cannot be undone.'));
      await tester.pump();
      expect(button(tester).onPressed, isNotNull);
    });

    testWidgets('says the drawings go when Colour Fun is among them',
        (tester) async {
      await open(tester, preselect: {'matematika'});
      expect(find.textContaining('The drawings are kept'), findsOneWidget);

      await tester.tap(find.text('Color Fun').last);
      await tester.pump();
      expect(find.text('Reset (2)'), findsOneWidget);
      expect(find.textContaining('and the drawings too'), findsOneWidget);
    });

    testWidgets('all modules counts six and loses the drawings',
        (tester) async {
      await open(tester);
      expect(find.text('Reset (0)'), findsOneWidget);
      await tester.tap(find.text('All modules'));
      await tester.pump();
      expect(find.text('Reset (6)'), findsOneWidget);
      expect(find.textContaining('and the drawings too'), findsOneWidget);
    });
  });

  testWidgets('the login card shows the user and the password',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const StudentLoginCardScreen(
      name: 'Ana Reyes',
      avatar: 'girl1',
      username: 'ana4821',
      password: 'DC-2026-4821',
    )));
    await tester.pump();
    expect(find.text('Ana Reyes'), findsOneWidget);
    expect(find.text('ana4821'), findsOneWidget);
    expect(find.text('DC-2026-4821'), findsOneWidget);
    expect(find.text('Copy the login'), findsOneWidget);
  });
}
