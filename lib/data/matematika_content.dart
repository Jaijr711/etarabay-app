/// The questions for Matematika's three newest levels.
///
/// The first seven levels keep their questions inside the screen as maps of
/// strings. These are out here, and typed, for one reason: they are the only
/// ones whose content can be *wrong* rather than merely ugly. A pattern that
/// does not repeat, a sum that does not add up, or a correct answer missing
/// from its own choices are all invisible until a child meets them — so they
/// are stated in a shape a test can check, and `matematika_content_test.dart`
/// checks every one.
///
/// What the three levels are for, in the order a child meets them:
///
///   * **Ano ang kasunod** — patterning. The one strand of early number the
///     module had nothing for at all: seeing that a run repeats, and saying
///     what the repetition demands next.
///   * **Pagsamahin** — joining two groups. Counting was covered six ways
///     over; putting two counts together was not covered once.
///   * **Bawasan** — taking away, with the removed things still on the screen
///     and crossed out. A child of four cannot subtract from a number they
///     cannot see.
///
/// Everything stays inside five, and every question is answered by looking:
/// no reading, and nothing held in the head.
library;

/// One "what comes next" question.
class PatternQuestion {
  /// The run the child can see, left to right.
  final List<String> shown;

  /// The three pictures offered as the next one.
  final List<String> choices;

  /// Which of [choices] continues the run.
  final int answer;

  const PatternQuestion({
    required this.shown,
    required this.choices,
    required this.answer,
  });

  String get next => choices[answer];

  /// The run with the answer on the end — the whole pattern, as it will look
  /// once the child gets it right.
  List<String> get complete => [...shown, next];
}

/// One "how many altogether" question: two groups of the same thing, joined.
class JoinQuestion {
  /// What is being counted, as the emoji the artwork is keyed by.
  final String item;
  final int left;
  final int right;

  /// The three numbers offered.
  final List<int> choices;

  const JoinQuestion({
    required this.item,
    required this.left,
    required this.right,
    required this.choices,
  });

  int get total => left + right;
}

/// One "how many are left" question: a group, some of it taken away.
class TakeAwayQuestion {
  final String item;

  /// How many there were to begin with.
  final int from;

  /// How many are taken — drawn crossed out rather than removed, so the
  /// child can still count what went.
  final int taken;

  final List<int> choices;

  const TakeAwayQuestion({
    required this.item,
    required this.from,
    required this.taken,
    required this.choices,
  });

  int get left => from - taken;
}

/// Level 8 — Ano ang kasunod.
///
/// Eight questions, and deliberately not eight of the same shape: three
/// repeat in twos, three in threes, one runs three different things in a row
/// and one hangs the odd picture on the end rather than the front. A child
/// who has learnt "it just goes back and forth" still has to look at the
/// fourth one.
const List<PatternQuestion> patternQuestions = [
  PatternQuestion(
    shown: ['🍎', '🍌', '🍎', '🍌'],
    choices: ['🍎', '🍌', '⭐'],
    answer: 0,
  ),
  PatternQuestion(
    shown: ['🔴', '🔵', '🔴', '🔵'],
    choices: ['🔵', '🔴', '🟢'],
    answer: 1,
  ),
  PatternQuestion(
    shown: ['⭐', '⭐', '🎈', '⭐', '⭐'],
    choices: ['⭐', '🎈', '🚗'],
    answer: 1,
  ),
  PatternQuestion(
    shown: ['🐶', '🐱', '🐭', '🐶', '🐱'],
    choices: ['🐶', '🐭', '🐱'],
    answer: 1,
  ),
  PatternQuestion(
    shown: ['🚗', '🌸', '🚗', '🌸', '🚗'],
    choices: ['🚗', '🍒', '🌸'],
    answer: 2,
  ),
  PatternQuestion(
    shown: ['🐟', '⭐', '🐟', '⭐'],
    choices: ['⭐', '🐟', '🍪'],
    answer: 1,
  ),
  PatternQuestion(
    shown: ['🍌', '🍌', '🍎', '🍌', '🍌'],
    choices: ['🍌', '🍎', '🐱'],
    answer: 1,
  ),
  // The odd one on the end, not the front: a child who has worked out
  // "two the same, then a different one" meets the same rule backwards.
  PatternQuestion(
    shown: ['🎈', '🚗', '🚗', '🎈', '🚗'],
    choices: ['🎈', '🌸', '🚗'],
    answer: 2,
  ),
];

/// Level 9 — Pagsamahin.
///
/// Eight questions. The groups start at one apiece and never total more than
/// five, which is as far as a daycare child counts with any confidence. Every
/// wrong choice is a number they could have reached by miscounting by one,
/// not a wild one.
const List<JoinQuestion> joinQuestions = [
  JoinQuestion(item: '🍎', left: 1, right: 1, choices: [1, 2, 3]),
  JoinQuestion(item: '🐟', left: 2, right: 1, choices: [2, 3, 4]),
  JoinQuestion(item: '⭐', left: 2, right: 2, choices: [3, 4, 5]),
  JoinQuestion(item: '🎈', left: 3, right: 1, choices: [2, 3, 4]),
  JoinQuestion(item: '🌸', left: 3, right: 2, choices: [4, 5, 6]),
  JoinQuestion(item: '🍪', left: 1, right: 2, choices: [2, 3, 4]),
  JoinQuestion(item: '🐱', left: 4, right: 1, choices: [3, 4, 5]),
  JoinQuestion(item: '🍒', left: 1, right: 3, choices: [3, 4, 5]),
];

/// Level 10 — Bawasan.
///
/// Eight questions, and it never takes everything: a child left with nothing
/// has nothing to count, and zero is a harder idea than any of the numbers
/// above it.
const List<TakeAwayQuestion> takeAwayQuestions = [
  TakeAwayQuestion(item: '🍌', from: 2, taken: 1, choices: [1, 2, 3]),
  TakeAwayQuestion(item: '🐶', from: 3, taken: 1, choices: [1, 2, 3]),
  TakeAwayQuestion(item: '🍎', from: 4, taken: 2, choices: [2, 3, 4]),
  TakeAwayQuestion(item: '⚽', from: 5, taken: 1, choices: [3, 4, 5]),
  TakeAwayQuestion(item: '🍪', from: 5, taken: 2, choices: [2, 3, 4]),
  TakeAwayQuestion(item: '🌸', from: 4, taken: 1, choices: [2, 3, 4]),
  TakeAwayQuestion(item: '🐟', from: 5, taken: 3, choices: [1, 2, 3]),
  TakeAwayQuestion(item: '⭐', from: 3, taken: 2, choices: [1, 2, 3]),
];
