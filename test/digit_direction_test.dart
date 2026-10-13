import 'package:e_tarabay/data/letter_tracing_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which way round the child is asked to travel.
///
/// Two digits were drawn backwards and neither looked wrong: a loop traced
/// the wrong way round ends in exactly the same place as one traced correctly,
/// so the picture is identical and only the child's hand knows the difference.
/// The teacher caught both; a rendering never would.
///
///   6  went back up and over the top of its loop after coming down the left,
///      instead of round the bottom and up the right.
///
///   8  ran both loops the same way round, so it was two circles stacked with
///      a doubling-back at the waist. A figure eight changes direction there —
///      that reversal is what makes it one motion.
///
/// These pin the path itself, at points along it, which is the only place the
/// fault ever showed.
void main() {
  /// The point [fraction] of the way through a stroke, by index.
  Offset at(List<Offset> stroke, double fraction) =>
      stroke[(fraction * (stroke.length - 1)).round().clamp(
            0,
            stroke.length - 1,
          )];

  List<Offset> digit(String d) {
    final strokes = numberStrokes[d];
    expect(strokes, isNotNull, reason: 'no strokes for "$d"');
    return strokes!.first;
  }

  group('6 goes round the bottom, not back over the top', () {
    late List<Offset> six;
    setUp(() => six = digit('6'));

    test('it starts at the top right', () {
      expect(six.first.dx, greaterThan(160));
      expect(six.first.dy, lessThan(105));
    });

    test('it comes down the left side before it reaches the bottom', () {
      final quarter = at(six, 0.40);
      expect(quarter.dx, lessThan(140), reason: 'should be on the left');
      expect(quarter.dy, greaterThan(120), reason: 'should have come down');
    });

    test('then round the bottom and up the right', () {
      expect(at(six, 0.55).dy, greaterThan(165), reason: 'the bottom');
      expect(at(six, 0.70).dx, greaterThan(160), reason: 'up the right');
      expect(at(six, 0.85).dy, lessThan(120), reason: 'across the top');
    });
  });

  group('8 is a figure eight, not two stacked circles', () {
    late List<Offset> eight;
    setUp(() => eight = digit('8'));

    test('it starts at the top and comes down the left', () {
      expect(eight.first.dy, lessThan(70));
      expect(at(eight, 0.12).dx, lessThan(140));
    });

    test('it passes through the waist', () {
      final waist = at(eight, 0.25);
      expect(waist.dy, greaterThan(100));
      expect(waist.dy, lessThan(135));
    });

    test('and turns the other way there — right, not left again', () {
      // The whole fault, in one line. Coming down the left into the waist and
      // continuing left is two circles; turning right is an eight.
      expect(at(eight, 0.40).dx, greaterThan(165),
          reason: 'after the waist the pen must go right');
      expect(at(eight, 0.55).dy, greaterThan(165), reason: 'the bottom');
      expect(at(eight, 0.70).dx, lessThan(140), reason: 'up the left');
    });

    test('and closes where it began', () {
      expect((eight.last - eight.first).distance, lessThan(2));
    });
  });

  group('0 is written the way an o is', () {
    test('it starts at the top and goes left first', () {
      final zero = digit('0');
      expect(zero.first.dy, lessThan(70), reason: 'starts at the top');
      expect(at(zero, 0.15).dx, lessThan(140),
          reason: 'counter-clockwise: down the left, not the right');
    });
  });
}
