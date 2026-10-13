import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The streak is the one badge that rewards showing up rather than scoring.
///
/// It is also the only thing in the app whose answer depends on the calendar,
/// and calendar arithmetic goes wrong quietly: a child who plays every day and
/// is told on Thursday that their run has reset has no way to argue, and no
/// way to know it was the app.
void main() {
  String iso(DateTime d) => d.toIso8601String();
  DateTime daysAgo(int n) => DateTime.now().subtract(Duration(days: n));

  group('starting out', () {
    test('a child who has never played is on day one', () {
      expect(UserProvider.computeDailyStreak(null, 0), 1);
      expect(UserProvider.computeDailyStreak('', 0), 1);
    });

    test('an unreadable date starts again rather than crashing', () {
      // A corrupted preference should cost the child their run, not the app.
      expect(UserProvider.computeDailyStreak('not a date', 7), 1);
    });
  });

  group('the run', () {
    test('playing again today does not add a second day', () {
      expect(UserProvider.computeDailyStreak(iso(DateTime.now()), 4), 4);
    });

    test('playing yesterday continues the run', () {
      expect(UserProvider.computeDailyStreak(iso(daysAgo(1)), 4), 5);
    });

    test('missing a day starts again at one', () {
      expect(UserProvider.computeDailyStreak(iso(daysAgo(2)), 9), 1);
      expect(UserProvider.computeDailyStreak(iso(daysAgo(30)), 9), 1);
    });

    test('an evening then a morning is two days, not twelve hours', () {
      // The rule is calendar days, not elapsed time. A child who plays at 8pm
      // and again at 8am has played on two days even though half a day
      // passed — counting hours would deny them the second one.
      final lastNight = DateTime.now()
          .subtract(const Duration(days: 1))
          .copyWith(hour: 20, minute: 0);
      expect(UserProvider.computeDailyStreak(iso(lastNight), 1), 2);
    });
  });

  group('a total that cannot be trusted', () {
    test('a stored zero still counts today', () {
      // Playing today is always worth at least one day, whatever was stored.
      expect(UserProvider.computeDailyStreak(iso(DateTime.now()), 0), 1);
      expect(UserProvider.computeDailyStreak(iso(daysAgo(1)), 0), 1);
    });

    test('a negative stored streak cannot make the run negative', () {
      expect(UserProvider.computeDailyStreak(iso(DateTime.now()), -5), 1);
      expect(UserProvider.computeDailyStreak(iso(daysAgo(1)), -5), 1);
    });

    test('a date in the future does not break the run', () {
      // A phone whose clock is wrong, or one that has just been corrected.
      // Losing the run over it would punish the child for the clock.
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(UserProvider.computeDailyStreak(iso(tomorrow), 6), 6);
    });
  });

  test('each call is one day, and the caller keeps the total', () {
    // The function measures the gap to *today*, so it cannot be walked
    // forward through a week — it answers one question: given when they last
    // played and what they had, what is the run now. A child reaches the
    // five-day badge because the answer is stored each day and handed back,
    // not because this ever counts past one step.
    var streak = 1;
    for (var day = 2; day <= 5; day++) {
      streak = UserProvider.computeDailyStreak(iso(daysAgo(1)), streak);
      expect(streak, day, reason: 'day $day of a run kept by the caller');
    }
    expect(streak, 5);

    // And one missed day undoes all of it, whatever had been stored.
    expect(UserProvider.computeDailyStreak(iso(daysAgo(2)), streak), 1);
  });
}
