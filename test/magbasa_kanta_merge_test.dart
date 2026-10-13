import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two Ania ti Nagan Mo entries became one, at the front of the 'kanta'
/// list — and completion for every song in that list is stored by
/// position, not by the song's id. Deleting the front slot without
/// shifting everything after it down to match would silently reattach
/// every other song's saved "finished" flag to the wrong song for any
/// child who had already played some of them.
void main() {
  List<bool> slots(List<int> trueAt, {int length = 14}) =>
      List.generate(length, (i) => trueAt.contains(i));

  test('nothing finished anywhere stays nothing finished', () {
    expect(UserProvider.mergedKantaSlots(slots([])), slots([], length: 13));
  });

  test('finishing only the old short entry still counts as the merged song',
      () {
    expect(UserProvider.mergedKantaSlots(slots([0])), slots([0], length: 13));
  });

  test('finishing only the old full entry still counts as the merged song', () {
    expect(UserProvider.mergedKantaSlots(slots([1])), slots([0], length: 13));
  });

  test('finishing both old entries counts once, not twice', () {
    expect(
        UserProvider.mergedKantaSlots(slots([0, 1])), slots([0], length: 13));
  });

  test('a song untouched by the merge keeps its own finished flag, shifted',
      () {
    // Old slot 2 was Uppat a Pato; it becomes new slot 1.
    expect(UserProvider.mergedKantaSlots(slots([2])), slots([1], length: 13));
  });

  test('the last song in the list lands on the last new slot', () {
    // Old slot 13 (Lima a Tinapay) becomes new slot 12, the last of 13.
    expect(UserProvider.mergedKantaSlots(slots([13])), slots([12], length: 13));
  });

  test('a full class of finished songs stays a full class', () {
    final allOld = List.generate(14, (i) => i);
    final allNew = List.generate(13, (i) => i);
    expect(UserProvider.mergedKantaSlots(slots(allOld)),
        slots(allNew, length: 13));
  });

  test('one finished song mid-list does not bleed into its neighbours', () {
    // Old slot 7 (Ni Nanangko) finished, alone; it becomes new slot 6, and
    // nothing on either side of it should have picked up a stray true.
    final result = UserProvider.mergedKantaSlots(slots([7]));
    expect(result, slots([6], length: 13));
  });
}
