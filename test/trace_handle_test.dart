import 'package:e_tarabay/data/letter_tracing_data.dart';
import 'package:e_tarabay/utils/path_smoothing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the numbered handle sits while a child drags a stroke.
///
/// Sundan Ito used to pin the numbered dot to the start of the stroke and fill
/// colour in underneath it, so nothing on screen followed the finger. The dot
/// now rides the head of the fill — the child is pulling the number along the
/// letter — and it slides back to the start if they let go before the stroke
/// is finished.
///
/// The screen reads that position out of [partialPolyline], so these are the
/// properties the drag depends on. They are cheap to state and impossible to
/// notice breaking: a handle that lags, jumps or overshoots still draws a
/// number somewhere on the letter and looks roughly right.
void main() {
  // An L: down the side, then along the foot. Two segments of 100 and 60, so
  // the corner falls at exactly 100/160 = 0.625 of the way along.
  const l = <Offset>[Offset(0, 0), Offset(0, 100), Offset(60, 100)];

  group('the handle follows the drag', () {
    test('it starts on the first point of the stroke', () {
      expect(partialPolyline(l, 0).last, l.first);
    });

    test('it ends on the last point of the stroke', () {
      expect(partialPolyline(l, 1).last, l.last);
    });

    test('half way along is half the length, not the middle point', () {
      // The naive reading — "the middle of the list" — would put the handle on
      // the corner, which is 62.5% of the way along, not 50%.
      final mid = partialPolyline(l, 0.5).last;
      expect(mid.dx, 0);
      expect(mid.dy, closeTo(80, 0.001));
    });

    test('it lands exactly on the corner at the corner', () {
      final at = partialPolyline(l, 0.625).last;
      expect(at.dx, closeTo(0, 0.001));
      expect(at.dy, closeTo(100, 0.001));
    });

    test('it never goes backwards as the drag advances', () {
      double travelled = -1;
      Offset previous = l.first;
      for (var f = 0.0; f <= 1.0; f += 0.02) {
        final at = partialPolyline(l, f).last;
        final step = (at - previous).distance;
        expect(step, greaterThanOrEqualTo(0));
        final along = polylineLength(partialPolyline(l, f));
        expect(along, greaterThanOrEqualTo(travelled),
            reason: 'the handle jumped back at $f');
        travelled = along;
        previous = at;
      }
    });

    test('past the end it stays on the end rather than running off', () {
      expect(partialPolyline(l, 1.4).last, l.last);
    });

    test('before the start it stays on the start', () {
      expect(partialPolyline(l, -0.3).last, l.first);
    });
  });

  group('the star at the end of the last stroke', () {
    // The reward is drawn at the very last point of the very last stroke, and
    // the handle is dragged to it. On most characters those are far apart and
    // the star is simply a place to travel to.
    //
    // On seven of them they are not. O, o, b, p and 10 finish a closed bowl
    // exactly where it began, and on i and j the last stroke is only the
    // tittle. Drawn plainly, the star would sit under the numbered handle and
    // look collected before the child had moved. The painter hides it while
    // the handle is within 24 px of it, which is why that rule exists — and
    // this is the list it exists for. A character joining or leaving the list
    // is a change worth noticing.
    //
    // It has already caught two changes: regenerating the letterforms turned
    // b and p into true circles that close, and redrawing 8 as a single
    // figure eight — top, round the left, through the waist, back up the
    // right — brought it back, because that path ends where it started.
    test('shares a point with the handle on exactly the closed characters',
        () {
      final closed = <String>[];
      for (final (mode, name, list) in [
        (0, 'uppercase', uppercaseLetters),
        (1, 'lowercase', lowercaseLetters),
        (2, 'numbers', numberLetters),
      ]) {
        for (final letter in list) {
          final strokes = strokesForMode(mode, letter.letter) ?? const [];
          if (strokes.isEmpty) continue;
          final last = strokes.last;
          expect(last, isNotEmpty,
              reason: '$name "${letter.letter}" has an empty last stroke');
          if ((last.last - last.first).distance < 20) {
            closed.add('$name ${letter.letter}');
          }
        }
      }
      expect(
          closed,
          orderedEquals([
            'uppercase O',
            'lowercase b',
            'lowercase i',
            'lowercase j',
            'lowercase o',
            'lowercase p',
            'numbers 8',
            'numbers 10',
          ]));
    });

    test('sits on the path the handle actually ends at', () {
      // The handle's position at full progress and the star's position are
      // read from two different expressions; they have to agree, or the child
      // drags the number to a star it never reaches.
      for (final (mode, name, list) in [
        (0, 'uppercase', uppercaseLetters),
        (1, 'lowercase', lowercaseLetters),
        (2, 'numbers', numberLetters),
      ]) {
        for (final letter in list) {
          final strokes = strokesForMode(mode, letter.letter) ?? const [];
          if (strokes.isEmpty) continue;
          final last = strokes.last;
          if (last.length < 2) continue;
          expect(partialPolyline(last, 1).last, last.last,
              reason: '$name "${letter.letter}"');
        }
      }
    });
  });

  group('the arrow ahead of the handle', () {
    // The painter points the arrow at a spot slightly further along the
    // stroke. If that spot ever fell behind the handle the arrow would point
    // back the way the child came.
    const lookAhead = 0.06;

    test('is never behind the handle, on any stroke of any character', () {
      for (final (mode, name, list) in [
        (0, 'uppercase', uppercaseLetters),
        (1, 'lowercase', lowercaseLetters),
        (2, 'numbers', numberLetters),
      ]) {
        for (final letter in list) {
          final strokes = strokesForMode(mode, letter.letter) ?? const [];
          for (final stroke in strokes) {
            if (stroke.length < 2) continue;
            for (var f = 0.0; f < 1.0; f += 0.1) {
              final here = polylineLength(partialPolyline(stroke, f));
              final ahead = polylineLength(
                  partialPolyline(stroke, (f + lookAhead).clamp(0.0, 1.0)));
              expect(ahead, greaterThanOrEqualTo(here),
                  reason: '$name "${letter.letter}" went backwards at $f');
            }
          }
        }
      }
    });
  });
}
