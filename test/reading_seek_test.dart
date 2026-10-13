import 'package:e_tarabay/screens/magbasa_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stepping back a line has to land on that line.
///
/// The back button looked broken because two separate pieces of arithmetic
/// disagreed: the seek worked out where a line starts by dividing the
/// recording evenly between the non-empty lines, while the highlight worked
/// out which line a position is in by weighting lines by their word count. A
/// press seeked to a position the highlight then resolved to a *different*
/// line — and because the seek aimed at a line's boundary, and the highlight
/// resolves a boundary to the line before it, one press stepped back two.
///
/// Both ends now use `lineWeights` with `fractionAtLine` and `lineAtFraction`,
/// and this asserts the property that makes them one model rather than two:
/// seek to a line, read the position back, get the same line.
void main() {
  const poem = [
    'Sipsipat, sipsipat',
    'Addaanak patupat',
    'Kanek ti agpatpatnag',
    'Bayat ti panagbasak',
  ];

  const withStanzaBreaks = [
    'Ang unang taludtod',
    'Ang pangalawang taludtod na mas mahaba pa nang kaunti',
    '',
    'Bagong saknong dito',
    'At ang huling linya',
  ];

  const uneven = [
    'Isa',
    'Dalawang salita dito na napakahaba talaga at marami ang salita',
    'Tatlo',
    'A',
  ];

  for (final (name, lines) in [
    ('a four line poem', poem),
    ('a poem with a stanza break', withStanzaBreaks),
    ('lines of very uneven length', uneven),
  ]) {
    test('$name: every line seeks back to itself', () {
      final weights = lineWeights(lines);
      for (var i = 0; i < lines.length; i++) {
        final landed = lineAtFraction(weights, fractionAtLine(weights, i));
        expect(landed, i,
            reason: 'seeking to line $i of ${lines.length} put the highlight '
                'on line $landed');
      }
    });
  }

  test('a blank line still occupies an index', () {
    // Weighted 1, not 0. A zero-width line would sit exactly on the boundary
    // between its neighbours, and the two functions would disagree about
    // which side of it a position falls.
    final weights = lineWeights(withStanzaBreaks);
    expect(weights[2], greaterThan(0));
  });

  test('a position before the first line resolves to the first line', () {
    final weights = lineWeights(poem);
    expect(lineAtFraction(weights, 0), 0);
    expect(lineAtFraction(weights, -1), 0);
  });

  test('a position past the end resolves to the last line', () {
    final weights = lineWeights(poem);
    expect(lineAtFraction(weights, 1.0), poem.length - 1);
    expect(lineAtFraction(weights, 2.0), poem.length - 1);
  });

  test('an empty poem does not divide by zero', () {
    expect(lineWeights(const []), isEmpty);
    expect(lineAtFraction(const [], 0.5), 0);
    expect(fractionAtLine(const [], 3), 0);
  });
}
