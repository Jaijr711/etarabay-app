import 'dart:math' as math;

import 'package:e_tarabay/data/letter_tracing_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// What Sundan Ito now depends on.
///
/// The screen used to hold two mechanics: drag-to-fill, and a freehand mode
/// that scored a drawing against `LetterData.points`. Which one a character
/// got depended on whether `strokesForMode` had strokes for it — and it has
/// them for all 62 characters, so the freehand path never ran once. It has
/// been removed, along with the painter that only it used.
///
/// That removal turns two things that happened to be true into things that
/// must stay true, and neither of them is visible from reading a screen:
///
///   * A character with no strokes now draws *nothing at all*. There is no
///     second painter to fall back to.
///   * A stroke with fewer than two points cannot be dragged along, so a
///     child would be stuck on it with no way forward and no way to know why.
///
/// The third test guards the two constants the canvas is sized from. If a
/// redrawn glyph grows past them the letter overflows its card and runs into
/// the border — which is what happened before they were introduced.

/// Where `_TraceItScreenState._magnify` puts the middle of every glyph.
const Offset _glyphCentre = Offset(150, 120);

/// Mirrors `_TraceItScreenState._glyphHalfWidth` / `_glyphHalfHeight`: how far
/// the furthest point of any glyph may sit from [_glyphCentre] once centred,
/// and before the screen scales it up. 64 across is the two-digit "10"; 69
/// down is the "j", counting its dot and its descender.
const double _glyphHalfWidth = 64.0;
const double _glyphHalfHeight = 69.0;

/// The centring half of `_TraceItScreenState._magnify`. The screen then scales
/// the result by one fixed factor, which moves every glyph in the same
/// proportion and so cannot change which of them reaches furthest.
List<List<Offset>> _centre(List<List<Offset>> strokes) {
  double minX = double.infinity, maxX = double.negativeInfinity;
  double minY = double.infinity, maxY = double.negativeInfinity;
  for (final stroke in strokes) {
    for (final p in stroke) {
      if (p.dx.isNaN || p.dy.isNaN) continue;
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
  }
  final dx = minX.isFinite ? _glyphCentre.dx - (minX + maxX) / 2 : 0.0;
  final dy = minY.isFinite ? _glyphCentre.dy - (minY + maxY) / 2 : 0.0;
  return [
    for (final stroke in strokes)
      [
        for (final p in stroke)
          (p.dx.isNaN || p.dy.isNaN)
              ? p
              : Offset(p.dx + dx, p.dy + dy)
      ]
  ];
}

/// Every character the module offers, paired with the mode it lives in.
Iterable<(int mode, String name, LetterData letter)> _allCharacters() sync* {
  for (final (mode, name, list) in [
    (0, 'uppercase', uppercaseLetters),
    (1, 'lowercase', lowercaseLetters),
    (2, 'numbers', numberLetters),
  ]) {
    for (final letter in list) {
      yield (mode, name, letter);
    }
  }
}

void main() {
  group('Sundan Ito stroke data', () {
    test('every character has strokes to drag along', () {
      final missing = <String>[];
      for (final (mode, name, letter) in _allCharacters()) {
        final strokes = strokesForMode(mode, letter.letter);
        if (strokes == null || strokes.isEmpty) {
          missing.add('$name "${letter.letter}"');
        }
      }
      expect(missing, isEmpty,
          reason: 'These characters would draw an empty canvas — the freehand '
              'painter that used to cover for them has been removed:\n'
              '${missing.join('\n')}');
    });

    test('every stroke can actually be dragged', () {
      final broken = <String>[];
      for (final (mode, name, letter) in _allCharacters()) {
        final strokes = strokesForMode(mode, letter.letter) ?? const [];
        for (var i = 0; i < strokes.length; i++) {
          final real =
              strokes[i].where((p) => !p.dx.isNaN && !p.dy.isNaN).toList();
          if (real.length < 2) {
            broken.add('$name "${letter.letter}" stroke ${i + 1}: '
                '${real.length} point(s)');
            continue;
          }
          double length = 0;
          for (var k = 1; k < real.length; k++) {
            length += (real[k] - real[k - 1]).distance;
          }
          if (length <= 0) {
            broken.add('$name "${letter.letter}" stroke ${i + 1}: zero length');
          }
        }
      }
      expect(broken, isEmpty,
          reason: 'A stroke with no length has nowhere to drag to, so the '
              'child cannot finish the character:\n${broken.join('\n')}');
    });

    test('no glyph outgrows the box the canvas is sized from', () {
      final overflowing = <String>[];
      for (final (mode, name, letter) in _allCharacters()) {
        final strokes = strokesForMode(mode, letter.letter) ?? const [];
        if (strokes.isEmpty) continue;

        double halfW = 0, halfH = 0;
        for (final stroke in _centre(strokes)) {
          for (final p in stroke) {
            if (p.dx.isNaN || p.dy.isNaN) continue;
            halfW = math.max(halfW, (p.dx - _glyphCentre.dx).abs());
            halfH = math.max(halfH, (p.dy - _glyphCentre.dy).abs());
          }
        }
        if (halfW > _glyphHalfWidth + 0.5 || halfH > _glyphHalfHeight + 0.5) {
          overflowing.add('$name "${letter.letter}": '
              '${halfW.toStringAsFixed(1)} x ${halfH.toStringAsFixed(1)} '
              '(limit $_glyphHalfWidth x $_glyphHalfHeight)');
        }
      }
      expect(overflowing, isEmpty,
          reason: 'These glyphs reach past the half-extents the canvas '
              'transform is built on, so they render into the card border:\n'
              '${overflowing.join('\n')}');
    });
  });
}
