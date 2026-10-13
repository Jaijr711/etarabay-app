import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The star is the app's one currency, and everything is built on it: the
/// fraction on the dashboard, every badge's target, the certificates, and both
/// the parent and teacher reports. A module whose ceiling is wrong makes all of
/// those lie at once, quietly.
void main() {
  // Named here rather than read from the provider so that changing a ceiling
  // has to be a deliberate act with a number typed next to it.
  const expected = <String, int>{
    'traceit': 62, // one per character: 26 + 26 + 10
    'magbasa': 19, // one per poem, story and song: 5 + 5 + 9
    'matematika': 21, // 7 graded levels at 3
    'family': 15, // 5 graded levels at 3
    'kulay': 9, // one per picture: 9 pages
    'sarili': 12, // 4 graded levels at 3
    'tandaan': 12, // 4 graded categories at 3
  };

  test('each module is worth what it is meant to be worth', () {
    expect(UserProvider.traceitStarCeiling, expected['traceit']);
    expect(UserProvider.magbasaStarCeiling, expected['magbasa']);
    expect(UserProvider.matematikaStarCeiling, expected['matematika']);
    expect(UserProvider.familyStarCeiling, expected['family']);
    expect(UserProvider.kulayStarCeiling, expected['kulay']);
    expect(UserProvider.sariliStarCeiling, expected['sarili']);
    expect(UserProvider.tandaanStarCeiling, expected['tandaan']);
  });

  test('the total is the sum of its parts', () {
    final sum = expected.values.reduce((a, b) => a + b);
    expect(UserProvider.totalPossibleStars, sum,
        reason: 'A new activity has been given stars without being added to a '
            'ceiling, so the dashboard fraction is now understating what the '
            'child can reach.');
  });

  test('no single module owns more than half the app', () {
    // What the re-weighting was for. Under the old weighting Let\'s Read and
    // Trace It held 57% between them, so a child who only listened outscored
    // a child who answered questions.
    const total = UserProvider.totalPossibleStars;
    for (final entry in expected.entries) {
      expect(entry.value / total, lessThan(0.5),
          reason: '${entry.key} is ${entry.value} of $total stars');
    }
  });

  test('the graded modules together outweigh the ungraded ones', () {
    // Matematika, About Myself, My Family and Remember It all mark the
    // child's answer; Let's Read and Colour Fun cannot, because there is
    // nothing there to be wrong about. Finishing something that was marked
    // should be worth more in total than finishing something that was not.
    const graded = ['matematika', 'sarili', 'family', 'tandaan'];
    const ungraded = ['magbasa', 'kulay'];

    int sum(List<String> keys) =>
        keys.map((k) => expected[k]!).reduce((a, b) => a + b);

    expect(sum(graded), greaterThan(sum(ungraded)),
        reason: 'graded ${sum(graded)} vs ungraded ${sum(ungraded)}');
  });
}
