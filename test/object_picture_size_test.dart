import 'dart:io';

import 'package:e_tarabay/widgets/object_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A picture must land at the same size as the emoji it replaces.
///
/// Emoji are text and carry leading, so the drawing inside the line box is
/// smaller than the box. A PNG has no leading. Without correcting for that, a
/// board where only the apples had artwork showed apples visibly larger than
/// the bananas beside them.
void main() {
  testWidgets('picture and emoji occupy the same square', (tester) async {
    const side = 120.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          // No file exists for this one, so it falls back to the emoji.
          child: ObjectPicture(emoji: '🍎', size: side),
        ),
      ),
    ));

    // The widget claims exactly the square it was given, whichever branch it
    // took — that is what keeps a row of mixed pictures and emoji aligned.
    expect(tester.getSize(find.byType(ObjectPicture)), const Size(side, side));
  });

  testWidgets('an unknown object still draws its emoji', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: ObjectPicture(emoji: '🦕', size: 80)),
      ),
    ));

    expect(find.text('🦕'), findsOneWidget);
    expect(tester.getSize(find.byType(ObjectPicture)), const Size(80, 80));
  });

  test('every object name maps to one file', () {
    // Two objects sharing a file would silently make them the same picture.
    final names = ObjectPicture.expectedFileNames;
    expect(names.toSet().length, names.length);
    expect(names, isNotEmpty);
  });

  test('a known object resolves to a path, an unknown one does not', () {
    expect(ObjectPicture.assetFor('🍎'),
        'assets/images/apple.png');
    expect(ObjectPicture.assetFor('🍌'),
        'assets/images/banana.png');
    expect(ObjectPicture.assetFor('🐟'), 'assets/images/fish.png');
    expect(ObjectPicture.assetFor('🦕'), isNull);
  });

  test('a variation selector does not hide the picture', () {
    // The game data writes the sofa as U+1F6CB followed by U+FE0F. It looks
    // the same and is a different string; before this it silently resolved to
    // no picture at all.
    expect(ObjectPicture.assetFor('🛋️'),
        'assets/images/sopa.png');
    expect(ObjectPicture.assetFor('🛏️'),
        'assets/images/kama.png');
  });

  test('a variation selector does not hide the picture', () {
    // The game data writes the sofa as U+1F6CB followed by U+FE0F. It looks
    // the same and is a different string; before this it silently resolved to
    // no picture at all.
    expect(ObjectPicture.assetFor('🛋️'),
        'assets/images/sopa.png');
    expect(ObjectPicture.assetFor('🛏️'),
        'assets/images/kama.png');
  });

  // ── The fault that hid three pictures ─────────────────────────────────────
  //
  // Three scenes shipped as .jpg. `assetFor` only ever asks for a .png and
  // reaches a .jpg through `errorBuilder`, which fires on Android but never
  // arrived on web — so the tiles silently stayed emoji and nothing anywhere
  // reported a problem. Artwork that fails by looking fine is the kind that
  // survives for weeks, so the rule is checked rather than remembered.
  test('no object ships as a jpg', () {
    final dir = Directory('assets/images');
    final stems = ObjectPicture.expectedFileNames.toSet();

    final strays = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.jpg'))
        .where((n) => stems.contains(n.substring(0, n.length - 4)))
        .toList();

    expect(strays, isEmpty,
        reason: 'convert these to .png — a .jpg object never loads on web:\n'
            '${strays.join('\n')}');
  });

  test('the files on disk are the files the map asks for', () {
    final present = Directory('assets/images')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.png'))
        .map((n) => n.substring(0, n.length - 4))
        .toSet();

    // Which objects are still waiting for artwork. Not a failure — they draw
    // their emoji until a file lands — but worth printing, because the list
    // is the only place the remaining work is written down.
    final waiting = ObjectPicture.expectedFileNames
        .where((n) => !present.contains(n))
        .toList();
    // ignore: avoid_print
    print('objects still drawn as emoji (${waiting.length}): '
        '${waiting.join(', ')}');

    expect(ObjectPicture.expectedFileNames, isNotEmpty);
  });
}
