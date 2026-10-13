import 'package:e_tarabay/data/letter_tracing_data.dart';
import 'package:e_tarabay/utils/path_smoothing.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two ways a child could finish a letter without tracing it.
///
/// Sundan Ito matched the finger against the whole stroke and allowed it to
/// stray 42 design units from the centre — while the drawn line is only 26
/// wide. Both numbers were generous enough to be exploitable, and neither
/// failure looks like one: the letter fills in and the star is collected, so
/// a child can be rewarded for a gesture that taught them nothing.
///
/// These pin the geometry the fix rests on. They do not touch the screen —
/// they state the facts about the letterforms that make the rules necessary.
void main() {
  /// The rule the screen applies: the finger must stay within one line-width
  /// of the centre of the stroke.
  const tolerance = 26.0;

  /// How far ahead of the child's progress the screen will match, in design
  /// units.
  const lookAhead = 55.0;

  /// Shortest distance from [p] to the polyline through [pts].
  double distanceToPath(List<Offset> pts, Offset p) {
    var best = double.infinity;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final seg = (b - a).distance;
      if (seg == 0) continue;
      final abx = b.dx - a.dx;
      final aby = b.dy - a.dy;
      var t = ((p.dx - a.dx) * abx + (p.dy - a.dy) * aby) / (seg * seg);
      t = t.clamp(0.0, 1.0);
      final proj = Offset(a.dx + abx * t, a.dy + aby * t);
      final d = (p - proj).distance;
      if (d < best) best = d;
    }
    return best;
  }

  group('cutting a corner', () {
    // An L: 100 down, then 60 across.
    const l = <Offset>[Offset(0, 0), Offset(0, 100), Offset(60, 100)];

    test('the diagonal across an L is off the line', () {
      // A child sweeping straight from the top of the stem to the end of the
      // foot never draws the corner. Half way along that sweep they are 30
      // from the nearest ink — inside the old 42, outside the new 26.
      final midOfShortcut = Offset.lerp(l.first, l.last, 0.5)!;
      final d = distanceToPath(l, midOfShortcut);
      expect(d, greaterThan(tolerance),
          reason: 'the corner cut would still be accepted');
      expect(d, lessThan(42.0),
          reason: 'and this is the gap the old tolerance let through');
    });

    test('actually tracing the L stays well inside the rule', () {
      // The honest gesture must not be caught by the tighter rule.
      for (var f = 0.0; f <= 1.0; f += 0.02) {
        final onPath = partialPolyline(l, f).last;
        expect(distanceToPath(l, onPath), lessThan(0.001));
      }
    });
  });

  group('jumping ahead on a letter that meets itself', () {
    test('the window offered never reaches the far side of a loop', () {
      // O closes on itself: standing at the start, the end of the path is
      // within a few units of the finger. Matching against the whole stroke
      // reported that as "almost finished". The window only ever offers the
      // next stretch, so what the finger can reach is bounded by its length,
      // not by how near the letter passes itself.
      for (final (mode, name, list) in [
        (0, 'uppercase', uppercaseLetters),
        (1, 'lowercase', lowercaseLetters),
        (2, 'numbers', numberLetters),
      ]) {
        for (final letter in list) {
          final strokes = strokesForMode(mode, letter.letter) ?? const [];
          for (final stroke in strokes) {
            if (stroke.length < 2) continue;
            final total = polylineLength(stroke);
            if (total <= 0) continue;
            final fraction =
                lookAhead / total < 0.12 ? 0.12 : lookAhead / total;

            for (var at = 0.0; at < 1.0; at += 0.1) {
              final to = (at + fraction).clamp(0.0, 1.0);
              final window = polylineSegment(stroke, at, to);
              final len = polylineLength(window);
              expect(len, lessThanOrEqualTo(total * fraction + 0.001),
                  reason: '$name "${letter.letter}" offered too much at $at');
            }
          }
        }
      }
    });
  });

  group('the window itself', () {
    const l = <Offset>[Offset(0, 0), Offset(0, 100), Offset(60, 100)];

    test('the whole path is the whole path', () {
      expect(polylineSegment(l, 0, 1).first, l.first);
      expect(polylineSegment(l, 0, 1).last, l.last);
      expect(polylineLength(polylineSegment(l, 0, 1)),
          closeTo(polylineLength(l), 0.001));
    });

    test('it begins exactly where the child had got to', () {
      // If it began anywhere else, progress would jump the moment they moved.
      for (var f = 0.0; f < 1.0; f += 0.05) {
        expect((polylineSegment(l, f, f + 0.2).first - partialPolyline(l, f).last)
            .distance,
            lessThan(0.001));
      }
    });

    test('it keeps the corner rather than cutting straight across it', () {
      // A window spanning the corner has to contain three points, or the
      // screen would be matching the finger against a shortcut of its own.
      final across = polylineSegment(l, 0.5, 0.75);
      expect(across.length, 3);
      expect(across[1], const Offset(0, 100));
    });

    test('an empty window is a point, not an empty list', () {
      // `_projectOntoPolyline` is handed this at the very end of a stroke.
      expect(polylineSegment(l, 1, 1).length, 1);
      expect(polylineSegment(l, 0.8, 0.3).length, 1);
    });
  });
}
