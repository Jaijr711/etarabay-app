import 'package:e_tarabay/widgets/object_picture.dart';
import 'package:e_tarabay/widgets/shape_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A square has to be the same square on every phone.
///
/// The memory game asks a child to find two matching cards. When the card face
/// is an emoji, the shape it draws comes from whatever font the device has —
/// so 🔺 is a narrow red wedge on one phone and a wide orange one on another,
/// and 🔷 and 🔵 can end up nearly the same blue. Drawn from a definition
/// instead, they cannot drift.
void main() {
  // Only the ones with no artwork. The colour circles and the star have
  // uploaded pictures and must keep them.
  const shapes = ['🟦', '🔺', '❤', '🔷', '✕'];

  group('which objects are drawn', () {
    test('every plain shape and colour is drawn', () {
      for (final e in shapes) {
        expect(ShapeGlyph.handles(e), isTrue, reason: '$e is not drawn');
      }
    });

    test('a variation selector does not hide a shape', () {
      // ❤️ is the heart followed by U+FE0F, which is a different string from
      // ❤ and looks identical. The same slip once cost four objects their
      // pictures.
      expect(ShapeGlyph.handles('❤️'), isTrue);
      expect(ShapeGlyph.handles('✕'), isTrue);
    });

    test('a thing with a picture is left alone', () {
      // These are illustrations, not shapes — drawing them here would replace
      // real artwork with a coloured blob.
      for (final e in ['🍎', '🐶', '👧', '🏠', '🎈', '⭐', '🔴']) {
        expect(ShapeGlyph.handles(e), isFalse, reason: '$e should not be drawn');
      }
    });
  });

  group('the picture map', () {
    test('no drawn shape still asks for a file', () {
      // A file would be looked up, fail, and fall back — for a shape that is
      // already exact. Worse, it would let a stray PNG replace it.
      for (final e in shapes) {
        expect(ObjectPicture.assetFor(e), isNull,
            reason: '$e is drawn but still mapped to a file');
      }
    });
  });

  testWidgets('a drawn shape fills the box it is given', (tester) async {
    const side = 96.0;
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: ObjectPicture(emoji: '🟦', size: side)),
      ),
    ));
    expect(tester.takeException(), isNull);

    final box = tester.getSize(find.byType(ObjectPicture));
    expect(box.width, side);
    expect(box.height, side);

    // The glyph itself is inset to match the space an emoji's drawing
    // occupied, so a board that mixes the two keeps one size.
    final glyph = tester.getSize(find.byType(ShapeGlyph));
    expect(glyph.width, lessThanOrEqualTo(side));
    expect(glyph.width, greaterThan(side * 0.5));
  });

  testWidgets('every shape renders without throwing', (tester) async {
    for (final e in shapes) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: ObjectPicture(emoji: e, size: 64))),
      ));
      expect(tester.takeException(), isNull, reason: '$e threw while drawing');
    }
  });
}
