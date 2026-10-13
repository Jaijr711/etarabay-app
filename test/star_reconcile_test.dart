import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two accounts of a child's star total, and which one wins.
///
/// A star total is stored twice: as a running number on the profile, and as
/// the record of finished work it was added up from. They part company the
/// moment the cloud copy of the first one is older than the second — which is
/// this app's normal state, because a child plays offline and the upload
/// waits.
///
/// What a teacher saw: ten stars during the session, the app closed, and
/// sixteen on reopening. Nothing had been earned in between. The cloud's
/// stale ten had replaced the child's sixteen at login and stayed there all
/// session, and the recount that would have caught it ran only when the
/// document happened to carry a `rawProgress` map. The stars were never lost
/// — they were shown a launch late.
void main() {
  group('a stale cloud copy cannot take stars away', () {
    test('the record raises the total before it has been restored', () {
      // The child's own device says sixteen. The cloud, last written before
      // an offline week, says ten.
      expect(
        UserProvider.reconcileStars(
            shown: 10, counted: 16, recordRestored: false),
        16,
      );
    });

    test('an empty record cannot zero a real total', () {
      // A device that has never pulled has nothing to count. Counting it as
      // zero and believing the answer is how a child loses everything.
      expect(
        UserProvider.reconcileStars(
            shown: 16, counted: 0, recordRestored: false),
        16,
      );
    });

    test('nothing earned anywhere stays nothing', () {
      expect(
        UserProvider.reconcileStars(
            shown: 0, counted: 0, recordRestored: false),
        0,
      );
    });
  });

  group('a restored record is the whole truth', () {
    test('it raises a total the cloud had understated', () {
      expect(
        UserProvider.reconcileStars(
            shown: 10, counted: 16, recordRestored: true),
        16,
      );
    });

    test('it lowers one that a replay has since brought down', () {
      // Replaying a level replaces that level's rating rather than adding to
      // it, so a weaker second run legitimately costs stars. A rule that only
      // ever raised would quietly undo that.
      expect(
        UserProvider.reconcileStars(
            shown: 16, counted: 10, recordRestored: true),
        10,
      );
    });

    test('agreement changes nothing', () {
      expect(
        UserProvider.reconcileStars(
            shown: 12, counted: 12, recordRestored: true),
        12,
      );
    });
  });
}
