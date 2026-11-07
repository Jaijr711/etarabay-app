import 'dart:math';

/// The answers of a question in an order of their own for each child.
///
/// Content lists the right answer in the same place again and again — first
/// in most About Me questions, the middle number in Numbers — and every
/// child saw the same order, so "always tap the first one" passed a level.
/// Each order here is seeded on the question and the child: it holds still
/// while they think (a rebuild does not reshuffle it), differs from question
/// to question, and differs from one child to the next.

/// A seeded order of the indexes `0 .. count-1`. [keepLast], when given, is
/// left at the end.
List<int> shuffledOrder(int count, {required String seed, int? keepLast}) {
  final order = [
    for (int i = 0; i < count; i++)
      if (i != keepLast) i
  ]..shuffle(Random(seed.hashCode));
  if (keepLast != null && keepLast >= 0 && keepLast < count) {
    order.add(keepLast);
  }
  return order;
}

/// [items] in a seeded order — for boards that check the answer by its
/// value, so where it sits does not matter to the grading.
List<T> shuffledList<T>(List<T> items, {required String seed}) => [
      for (final i in shuffledOrder(items.length, seed: seed)) items[i],
    ];

/// The "everything above" answers, which read wrongly anywhere but last.
const _everything = {
  'all of the above',
  'lahat ng nabanggit',
  'amin kadagitoy',
};

/// The picture an answer can start with ('👨‍👩‍👧 Lahat ng nabanggit'): a
/// first word with no letters or digits in it. Matched here rather than
/// through AnswerTile so this file stays free of widgets.
final _leadingPicture = RegExp(r'^[^\p{L}\p{N}\s]+\s+', unicode: true);

/// An answer's words alone, for comparing against [_everything].
String _words(String label) =>
    label.trim().replaceFirst(_leadingPicture, '').toLowerCase();

/// [choices] in a seeded order, and where the right one ([correct]) went.
///
/// "All of the above" stays last, where it reads as meant — unless
/// [keepAllOfTheAboveLast] is false, for a board whose catch-all answers are
/// whole sentences ("Anyone can") that read fine anywhere.
(List<T>, int) shuffledChoices<T>(List<T> choices, int correct,
    {required String seed, bool keepAllOfTheAboveLast = true}) {
  final last = choices.isNotEmpty &&
          keepAllOfTheAboveLast &&
          choices.last is String &&
          _everything.contains(_words(choices.last as String))
      ? choices.length - 1
      : null;
  final order = shuffledOrder(choices.length, seed: seed, keepLast: last);
  return ([for (final i in order) choices[i]], order.indexOf(correct));
}

/// The Number Puzzle's tray, mixed — but never already in order, which
/// would leave nothing to solve.
List<int> unsolvedTray(List<int> numbers, {required String seed}) {
  final tray = shuffledList(numbers, seed: seed);
  final sorted = [...numbers]..sort();
  bool inOrder(List<int> l) {
    for (int i = 0; i < l.length; i++) {
      if (l[i] != sorted[i]) return false;
    }
    return true;
  }

  if (tray.length > 1 && inOrder(tray)) {
    final first = tray.removeAt(0);
    tray.add(first);
  }
  return tray;
}
