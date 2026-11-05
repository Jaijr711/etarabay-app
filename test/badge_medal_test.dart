import 'dart:io';

import 'package:e_tarabay/data/badge_catalog.dart';
import 'package:e_tarabay/widgets/badge_emblem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every award has its 3D picture, and the trophy is there too', () {
    for (final def in badgeCatalog) {
      expect(File(def.image).existsSync(), isTrue,
          reason: '${def.id} has no picture at ${def.image}');
    }
    expect(File('assets/images/badges/trophy.webp').existsSync(), isTrue);
  });

  test('the badges folder ships with the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/badges/'));
  });

  testWidgets('the coin draws locked, earned and full-star medals',
      (tester) async {
    final def = badgeCatalog.first;
    await tester.pumpWidget(MaterialApp(
      home: Row(
        children: [
          for (final (locked, tier) in const [(true, 0), (false, 1), (false, 3)])
            BadgeEmblem(
              icon: def.icon,
              color: Color(def.color),
              size: 80,
              locked: locked,
              tier: tier,
              image: def.image,
            ),
        ],
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Taller than wide, so the ribbon hangs below the coin.
    expect(tester.getSize(find.byType(BadgeEmblem).first),
        const Size(80, 80 * BadgeEmblem.coinAspect));
    // The locked one is an outline only; the won ones carry a shadow copy.
    expect(find.byType(Image), findsNWidgets(5));
  });
}
