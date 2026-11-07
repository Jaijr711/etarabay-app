import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/screens/developer_dashboard_screen.dart';
import 'package:e_tarabay/services/app_version.dart';
import 'package:e_tarabay/services/developer_roster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The developer dashboard's counts, filters and orders, and the version
/// compare the minimum version rests on.
void main() {
  // A Saturday afternoon; the edges are counted from it.
  final now = DateTime(2026, 11, 7, 15, 42);

  DevRecord kid(String name,
          {Duration? ago,
          double? progress,
          bool paused = false,
          String? version}) =>
      DevRecord(name, {
        'name': name,
        'lrn': 'DC-${name.hashCode.abs() % 10000}',
        if (ago != null) 'lastActive': Timestamp.fromDate(now.subtract(ago)),
        if (progress != null) 'progress': {'overallProgress': progress},
        if (paused) 'disabledByDev': true,
        if (version != null) 'appVersion': version,
      });

  group('version compare', () {
    test('part by part, padded, by leading digits', () {
      expect(AppVersion.compare('1.2', '1.2.0'), 0);
      expect(AppVersion.compare('1.10.0', '1.9.0'), 1);
      expect(AppVersion.compare('1.2.56', '1.2.57'), -1);
      // A tag left over from testing still reads as its numbers.
      expect(AppVersion.compare('1.2.17-g', '1.2.17'), 0);
    });
  });

  group('counts and filters', () {
    final records = [
      kid('Ana', ago: const Duration(seconds: 89), version: '1.2.57'),
      kid('Ben', ago: const Duration(seconds: 90), version: '1.2.56'),
      // Last night, a minute before midnight: not today.
      kid('Carlo',
          ago: now.difference(DateTime(2026, 11, 6, 23, 59)),
          version: '1.2.57'),
      kid('Dina', ago: const Duration(days: 7)),
      kid('Elena', ago: const Duration(days: 7, minutes: 1), paused: true),
      kid('Francis'),
    ];

    test('the edges of online, today and away', () {
      final c = countRoster(records, now);
      expect(c.all, 6);
      expect(c.online, 1, reason: 'under 90 s only');
      expect(c.today, 2, reason: 'Ana and Ben, not last night');
      expect(c.away, 2, reason: 'past 7 days, or never seen');
      expect(c.paused, 1);
      // Ben is behind 1.2.57; the ones with no version are not counted.
      expect(c.outdated, 1);
    });

    List<String> names(List<DevRecord> l) => [for (final r in l) r.name];

    test('each filter keeps its own', () {
      List<String> only(DevFilter f) => names(filterAndSort(records,
          now: now, filter: f, sort: DevSort.name));
      expect(only(DevFilter.online), ['Ana']);
      expect(only(DevFilter.today), ['Ana', 'Ben']);
      expect(only(DevFilter.away), ['Elena', 'Francis']);
      expect(only(DevFilter.paused), ['Elena']);
      expect(only(DevFilter.outdated), ['Ben']);
    });

    test('search and a filter together', () {
      expect(
          names(filterAndSort(records,
              now: now, filter: DevFilter.today, query: 'be')),
          ['Ben']);
      expect(
          names(filterAndSort(records,
              now: now, filter: DevFilter.paused, query: 'ana')),
          isEmpty);
    });
  });

  group('orders', () {
    final records = [
      kid('Carlo', ago: const Duration(hours: 2), progress: 0.12),
      kid('ana', ago: const Duration(days: 3), progress: 0.8),
      kid('Ben', ago: const Duration(seconds: 10), progress: 0.5),
      kid('Dina'),
    ];
    List<String> by(DevSort s) =>
        [for (final r in filterAndSort(records, now: now, sort: s)) r.name];

    test('online first, then by name, any case', () {
      expect(by(DevSort.onlineFirst), ['Ben', 'ana', 'Carlo', 'Dina']);
    });
    test('by name', () {
      expect(by(DevSort.name), ['ana', 'Ben', 'Carlo', 'Dina']);
    });
    test('lowest progress first; never synced counts as none', () {
      expect(by(DevSort.progressLow), ['Dina', 'Carlo', 'Ben', 'ana']);
    });
    test('newest activity first; never seen last', () {
      expect(by(DevSort.lastActive), ['Ben', 'Carlo', 'ana', 'Dina']);
    });
  });

  testWidgets('a count at the top narrows the list, and again lets go',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 900);
    addTearDown(tester.view.reset);
    final config = StreamController<Map<String, dynamic>?>.broadcast();
    DeveloperDashboardScreen.debugStudents = Stream.value([
      kid('Ana', ago: const Duration(seconds: 5)),
      kid('Hector', ago: const Duration(days: 2), paused: true),
      kid('Luis', ago: const Duration(hours: 1)),
    ]);
    DeveloperDashboardScreen.debugConfig = config.stream;
    DeveloperDashboardScreen.debugOwnVersion = '1.2.57';
    DeveloperDashboardScreen.debugNow = () => now;
    addTearDown(() {
      DeveloperDashboardScreen.debugStudents = null;
      DeveloperDashboardScreen.debugConfig = null;
      DeveloperDashboardScreen.debugOwnVersion = null;
      DeveloperDashboardScreen.debugNow = null;
      config.close();
    });
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DeveloperDashboardScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('3 na bata'), findsOneWidget);

    // The count at the top, not the paused child's own label below it.
    final paused = find.text('Naka-pause').first;
    await tester.ensureVisible(paused);
    await tester.pump();
    await tester.tap(paused);
    await tester.pump();
    expect(find.text('1 na bata'), findsOneWidget);
    expect(find.text('Hector'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);

    await tester.tap(find.text('Naka-pause').first);
    await tester.pump();
    expect(find.text('3 na bata'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });
}
