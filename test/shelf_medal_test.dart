import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/badge_claim_celebration.dart';
import 'package:e_tarabay/widgets/badge_emblem.dart';
import 'package:e_tarabay/widgets/floating_bottom_nav_bar.dart';
import 'package:e_tarabay/widgets/shelf_medal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A won medal is taken with one press: the celebration plays and leaves by
/// itself, with no card to press through. Other medals open as before.
void main() {
  Future<({List<String> calls})> pump(WidgetTester tester,
      {required bool ready, bool earned = true}) async {
    final calls = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fil'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: ShelfMedal(
            icon: Icons.star,
            image: null,
            color: Colors.blue,
            tier: 2,
            title: 'Unang Hakbang',
            size: 64,
            isEarned: earned,
            ready: ready,
            claimLabel: 'Kunin!',
            onClaim: () async => calls.add('claim'),
            onOpen: () => calls.add('open'),
          ),
        ),
      ),
    ));
    return (calls: calls);
  }

  testWidgets('one press claims it, and the celebration leaves by itself',
      (tester) async {
    final r = await pump(tester, ready: true);
    expect(find.text('Kunin!'), findsOneWidget);
    await tester.tap(find.byType(ShelfMedal));
    await tester.pump(const Duration(milliseconds: 100));
    expect(r.calls, ['claim']);
    expect(find.byType(BadgeClaimCelebration), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('Nakuha mo!'), findsWidgets);
    // Its whole length, the flight home and the landing.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BadgeClaimCelebration), findsNothing);
    expect(r.calls, ['claim']);
  });

  testWidgets('a press during the celebration skips it', (tester) async {
    await pump(tester, ready: true);
    await tester.tap(find.byType(ShelfMedal));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BadgeClaimCelebration), findsNothing);
  });

  testWidgets('a taken or unwon medal opens its card instead', (tester) async {
    final taken = await pump(tester, ready: false);
    await tester.tap(find.byType(ShelfMedal));
    await tester.pump();
    expect(taken.calls, ['open']);
    expect(find.byType(BadgeClaimCelebration), findsNothing);
  });

  testWidgets('a medal waiting to be taken is still locked on the shelf',
      (tester) async {
    await pump(tester, ready: true);
    expect(tester.widget<BadgeEmblem>(find.byType(BadgeEmblem)).locked, true);
    await pump(tester, ready: false);
    expect(tester.widget<BadgeEmblem>(find.byType(BadgeEmblem)).locked, false);
  });

  testWidgets('the name under it does not move while the medal lands',
      (tester) async {
    await pump(tester, ready: true);
    final name = find.descendant(
        of: find.byType(ShelfMedal), matching: find.text('Unang Hakbang'));
    final before = tester.getRect(name);
    await tester.tap(find.byType(ShelfMedal));
    await tester.pump(const Duration(milliseconds: 100));
    // Through the celebration, until the medal is back on the shelf.
    for (var i = 0;
        i < 60 && find.byType(BadgeClaimCelebration).evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BadgeClaimCelebration), findsNothing);
    // The landing and its spreading gold ring.
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(name), before);
    }
  });

  testWidgets('the Awards button shows how many medals are waiting',
      (tester) async {
    Future<void> bar(int count) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNavBar(
              selectedIndex: 0,
              onTap: (_) {},
              items: [
                const NavItemData(icon: Icons.home, label: 'Home'),
                NavItemData(
                    icon: Icons.emoji_events,
                    label: 'Awards',
                    badgeCount: count),
              ],
            ),
          ),
        ));
    await bar(2);
    expect(find.text('2'), findsOneWidget);
    await bar(12);
    expect(find.text('9+'), findsOneWidget);
    await bar(0);
    expect(find.text('2'), findsNothing);
    expect(find.text('9+'), findsNothing);
    // Nothing waiting, nothing moving: the screen can settle.
    await tester.pumpAndSettle();
  });
}
