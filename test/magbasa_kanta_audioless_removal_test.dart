import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Four songs in the v2, 13-entry 'kanta' list never got a recording of
/// their own (old slots 3, 5, 8 and 10) and were dropped from the list —
/// and, same as the earlier merge, completion for every song in that list
/// is stored by position, not by the song's id. Dropping four slots out of
/// the middle without shifting everything after each one down to match
/// would silently reattach every later song's saved "finished" flag to the
/// wrong song for any child who had already played some of them.
void main() {
  List<bool> slots(List<int> trueAt, {int length = 13}) =>
      List.generate(length, (i) => trueAt.contains(i));

  test('nothing finished anywhere stays nothing finished', () {
    expect(UserProvider.audiolessRemovedKantaSlots(slots([])),
        slots([], length: 9));
  });

  test('a song right after a removed slot keeps its flag, shifted', () {
    // Old slot 4 (Bassit a Lawwalawwa) sits right after the first removed
    // slot (3); it becomes new slot 3.
    expect(UserProvider.audiolessRemovedKantaSlots(slots([4])),
        slots([3], length: 9));
  });

  test('finishing only a removed song leaves every surviving slot false', () {
    // Old slot 3 (Agrimat-rimat Bassit a Bituen) had no recording, so no
    // real device could have marked it finished, but the migration must
    // not let a stray true there leak onto its new neighbour either way.
    expect(UserProvider.audiolessRemovedKantaSlots(slots([3])),
        slots([], length: 9));
  });

  test('the last song in the list lands on the last new slot', () {
    // Old slot 12 (Lima a Tinapay) becomes new slot 8, the last of 9.
    expect(UserProvider.audiolessRemovedKantaSlots(slots([12])),
        slots([8], length: 9));
  });

  test('every song between two removed slots keeps its own flag', () {
    // Old slots 6 and 7 (Maysa Dua Baduya, Ni Nanangko) sit between the
    // second (5) and third (8) removed slots; they become new slots 4 and
    // 5, each independently.
    expect(UserProvider.audiolessRemovedKantaSlots(slots([6, 7])),
        slots([4, 5], length: 9));
  });

  test('a full class of finished surviving songs stays a full class', () {
    const survivingOld = [0, 1, 2, 4, 6, 7, 9, 11, 12];
    final allNew = List.generate(9, (i) => i);
    expect(UserProvider.audiolessRemovedKantaSlots(slots(survivingOld)),
        slots(allNew, length: 9));
  });
}
