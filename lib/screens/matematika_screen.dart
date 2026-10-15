import 'package:e_tarabay/l10n/app_localizations.dart';
// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/sfx.dart';
import '../utils/constants.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/answer_tile.dart';
import '../widgets/question_cloud.dart';
import '../widgets/basket_picture.dart';
import '../widgets/object_picture.dart';
import '../widgets/pop_balloon.dart';
import '../widgets/success_modal.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/pressable.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/star_tally.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/word_fit.dart';

// ─── CustomPainter: draws animated lines between matched nodes ───────────────
class _Game3LinePainter extends CustomPainter {
  final List<Offset> leftDots;
  final List<Offset> rightDots;
  final Map<int, int> matches;
  final Map<int, bool> wrongFlash;

  /// Until the board is graded a line is neither right nor wrong, so it is
  /// drawn in the app's own indigo rather than green.
  final bool checked;

  _Game3LinePainter({
    required this.leftDots,
    required this.rightDots,
    required this.matches,
    required this.wrongFlash,
    required this.checked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in matches.entries) {
      final leftIdx = entry.key;
      final rightIdx = entry.value;

      if (leftIdx >= leftDots.length || rightIdx >= rightDots.length) continue;

      final isWrong = wrongFlash[leftIdx] == true;
      final color = isWrong
          ? Colors.red
          : checked
              ? Colors.green
              : AppColors.primary;

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final p1 = leftDots[leftIdx];
      final p2 = rightDots[rightIdx];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 10);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      canvas.drawPath(path, linePaint);

      canvas.drawCircle(p1, 5.5, dotPaint);
      canvas.drawCircle(p2, 5.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_Game3LinePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────

class MatematikaScreen extends StatefulWidget {
  const MatematikaScreen({super.key});

  @override
  State<MatematikaScreen> createState() => _MatematikaScreenState();
}

class _MatematikaScreenState extends State<MatematikaScreen>
    with TickerProviderStateMixin {
  int _selectedLevel = 0;
  int _currentGameIndex = 0;

  /// False while the child is choosing a level, true while they are in one.
  ///
  /// The board and the wall of cards are never both on screen: that was the
  /// whole point of taking the level strip off the board.
  bool _playing = false;

  int _levelStars = 0;
  int _levelScore = 0;
  int _wrongAttempts = 0;

  /// No countdown in Matematika.
  ///
  /// Counting objects is exactly the task a clock punishes: a preschooler
  /// counts out loud and on their fingers, and the number that comes out of
  /// hurrying is the wrong one. "Ang Aking Sarili" has had no timer for a
  /// while; keeping one here made the same child hurry in one module and
  /// think in another.
  ///
  /// Left behind a flag rather than torn out — every start already checks it,
  /// so nothing runs, and one word turns it back on for older children.
  static const bool _timerEnabled = false;

  int _secondsLeft = 30;
  Timer? _timer;

  String _feedbackMessage = '';
  Color _feedbackColor = Colors.transparent;
  bool _showCorrectOverlay = false;

  int? _selectedAnswer;

  bool _dropCorrect = false;
  bool _dropWrong = false;

  /// Where the basket sits on screen, so a tapped number knows where to
  /// fly to — see [_flyNumberToBasket].
  final GlobalKey _basketKeyGame2 = GlobalKey();

  /// Index of the Game 2 choice currently mid-flight (or just landed), so
  /// its own chip can be hidden — by opacity, not removal — while its flying
  /// copy is what the child actually sees moving. Also doubles as "a flight
  /// is already in progress" so a second tap mid-animation cannot start a
  /// second chip flying before the first has been graded.
  int? _flownChipIndexGame2;

  // Game 3 – node matching state
  int? _selectedLeftIndex;
  final Map<int, int> _lineMatches = {};
  List<int> _shuffledRightIndices = [];

  // Game 3 – new node/line fields
  final List<GlobalKey> _leftNodeKeys = [];
  final List<GlobalKey> _rightNodeKeys = [];
  final GlobalKey _game3StackKey = GlobalKey();
  final Map<int, bool> _wrongFlash = {};

  /// False while the child is still drawing lines, true once the whole board
  /// has been graded. Nothing is coloured right or wrong before that, so a
  /// child gets to connect every pair and change their mind first.
  bool _lineChecked = false;
  bool _showWrongOverlay = false;
  bool _showTimeUpOverlay = false;

  /// True while the child is deliberately playing a level they have already
  /// finished. Every question in such a level is marked completed, and the
  /// "Finished already!" card that covers a completed question is wrapped in
  /// an IgnorePointer — so without this the Repeat button led straight to a
  /// wall of un-tappable questions and replaying was simply impossible.
  bool _replaying = false;
  late AnimationController _shakeController;

  final Set<int> _poppedBalloons = {};
  final Set<int> _wrongBalloons = {};

  String? _selectedSide;

  /// The scrambled tiles the child picks from.
  List<int> _puzzleNumbers = [];

  /// One entry per box in the row, null while the box is still empty.
  ///
  /// The puzzle used to work by swapping: tap one number, tap another, and
  /// they trade places. That asks a three-year-old to hold two positions in
  /// mind at once and understand an exchange between them. Filling boxes left
  /// to right is the same lesson — what comes next — with none of that load.
  List<int?> _puzzleSlots = [];

  bool _isPuzzleSolved = false;

  int _dailyStreak = 0;
  int _consecutiveCorrectStreak = 0;

  late AnimationController _starBurstController;
  late AnimationController _timerPulseController;

  // ─── Game data ──────────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _game1Levels = const [
    {
      'question_en': 'How many apples can you count?',
      'item_name_en': 'apples',
      'item_name_il': 'mansanas',
      'item_name_tl': 'mansanas',
      'objects': ['🍎', '🍎', '🍎'],
      'answers': [1, 2, 3],
      'correct': 3,
    },
    {
      'question_en': 'How many bananas can you count?',
      'item_name_en': 'bananas',
      'item_name_il': 'saging',
      'item_name_tl': 'saging',
      'objects': ['🍌', '🍌'],
      'answers': [1, 2, 3],
      'correct': 2,
    },
    {
      'question_en': 'How many dogs can you count?',
      'item_name_en': 'dogs',
      'item_name_il': 'aso',
      'item_name_tl': 'aso',
      'objects': ['🐶'],
      'answers': [1, 2, 3],
      'correct': 1,
    },
    {
      'question_en': 'How many fish do you count?',
      'item_name_en': 'fish',
      'item_name_il': 'isda',
      'item_name_tl': 'isda',
      'objects': ['🐟', '🐟', '🐟', '🐟'],
      'answers': [2, 3, 4],
      'correct': 4,
    },
    {
      'question_en': 'How many birds you count?',
      'item_name_en': 'birds',
      'item_name_il': 'billit',
      'item_name_tl': 'ibon',
      'objects': ['🐦', '🐦', '🐦', '🐦', '🐦'],
      'answers': [3, 4, 5],
      'correct': 5,
    },
  ];

  /// Level 2 — Drag the Number.
  ///
  /// Deliberately a different set of things from Level 1, which used apples,
  /// bananas, a dog, fish and birds in the counts 3, 2, 1, 4, 5. This level
  /// was a straight copy of that list, so a child who had just finished Level
  /// 1 met the very same five pictures with the very same five answers and
  /// could get through on memory without counting anything.
  ///
  /// The counts climb a little further too (2 → 6 rather than 1 → 5), so the
  /// level asks for something Level 1 did not.
  final List<Map<String, dynamic>> _game2Levels = const [
    {
      'emoji': '🌸',
      'correct': 2,
      'choices': [1, 2, 3]
    },
    {
      'emoji': '🎈',
      'correct': 4,
      'choices': [3, 4, 5]
    },
    {
      'emoji': '🚗',
      'correct': 3,
      'choices': [2, 3, 4]
    },
    {
      'emoji': '⭐',
      'correct': 5,
      'choices': [4, 5, 6]
    },
    {
      'emoji': '⚽',
      'correct': 6,
      'choices': [5, 6, 7]
    },
  ];

  final List<Map<String, dynamic>> _game3Levels = const [
    {
      'target_cat_en': 'fruit',
      'target_cat_il': 'prutas',
      'target_cat_tl': 'prutas',
      'pairs': [
        {
          'objects': ['🍎'],
          'count': 1
        },
        {
          'objects': ['🍎', '🍎'],
          'count': 2
        },
        {
          'objects': ['🍎', '🍎', '🍎'],
          'count': 3
        },
      ],
    },
    {
      'target_cat_en': 'animal',
      'target_cat_il': 'ayup',
      'target_cat_tl': 'hayop',
      'pairs': [
        {
          'objects': ['🐶'],
          'count': 1
        },
        {
          'objects': ['🐱', '🐱'],
          'count': 2
        },
        {
          'objects': ['🐭', '🐭', '🐭'],
          'count': 3
        },
      ],
    },
    {
      'target_cat_en': 'fruit',
      'target_cat_il': 'prutas',
      'target_cat_tl': 'prutas',
      'pairs': [
        {
          'objects': ['🍌'],
          'count': 1
        },
        {
          'objects': ['🍇', '🍇'],
          'count': 2
        },
        {
          'objects': ['🍒', '🍒', '🍒'],
          'count': 3
        },
      ],
    },
  ];

  /// Nine balloons, and a different number of them to pop each time.
  ///
  /// Seven left the bottom row of a three-across board holding a single
  /// balloon with two empty spaces beside it. Nine fills all three rows.
  ///
  /// How many are the right one changes from board to board — two, then
  /// three, four, three, five. Every board asking for exactly three taught
  /// the child to stop after the third: they popped three and waited, whether
  /// or not the board was finished. Now the only way to know they are done is
  /// to have looked at all nine.
  ///
  /// The right ones are spread down the rows on purpose. Bunched together
  /// they can all be taken in at one glance, and the rest of the board never
  /// gets read.
  final List<Map<String, dynamic>> _game4Levels = const [
    // Two, to show what the game is.
    {
      'target': 3,
      'balloons': [1, 3, 2, 4, 1, 2, 3, 4, 1]
    },
    {
      'target': 2,
      'balloons': [2, 1, 3, 4, 2, 1, 3, 2, 4]
    },
    {
      'target': 1,
      'balloons': [1, 3, 2, 1, 4, 1, 3, 2, 1]
    },
    {
      'target': 4,
      'balloons': [2, 4, 1, 3, 4, 5, 2, 1, 4]
    },
    // Five, and every other balloon: the board a child gets to clear.
    {
      'target': 5,
      'balloons': [5, 3, 5, 2, 5, 1, 5, 4, 5]
    },
  ];

  final List<Map<String, dynamic>> _game5Levels = const [
    {
      'type': 'more',
      'leftObjects': ['🍎', '🍎', '🍎'],
      'leftCount': 3,
      'rightObjects': ['🍎'],
      'rightCount': 1,
      'correct': 'left',
    },
    {
      'type': 'less',
      'leftObjects': ['🍌'],
      'leftCount': 1,
      'rightObjects': ['🍌', '🍌'],
      'rightCount': 2,
      'correct': 'left',
    },
    {
      'type': 'more',
      'leftObjects': ['🐶', '🐶'],
      'leftCount': 2,
      'rightObjects': ['🐶', '🐶', '🐶'],
      'rightCount': 3,
      'correct': 'right',
    },
    {
      'type': 'equal',
      'leftObjects': ['🍎', '🍎'],
      'leftCount': 2,
      'rightObjects': ['🍎', '🍎'],
      'rightCount': 2,
      'correct': 'equal',
    },
    {
      'type': 'more',
      'leftObjects': ['🐟', '🐟', '🐟', '🐟'],
      'leftCount': 4,
      'rightObjects': ['🐟', '🐟'],
      'rightCount': 2,
      'correct': 'left',
    },
  ];

  final List<Map<String, dynamic>> _game6Levels = const [
    {
      'sequence': '1 → 2 → 3',
      'scrambled': [3, 1, 2],
      'correct': [1, 2, 3]
    },
    {
      'sequence': '2 → 4 → 6',
      'scrambled': [6, 2, 4],
      'correct': [2, 4, 6]
    },
    {
      'sequence': '1 → 3 → 5',
      'scrambled': [5, 1, 3],
      'correct': [1, 3, 5]
    },
  ];

  final List<Map<String, dynamic>> _game7Levels = const [
    {
      'sequence': [1, 2, null, 4, 5],
      'answers': [2, 3, 4],
      'correct': 3
    },
    {
      'sequence': [2, 3, 4, null, 6],
      'answers': [4, 5, 6],
      'correct': 5
    },
    {
      'sequence': [1, null, 3, 4, 5],
      'answers': [1, 2, 3],
      'correct': 2
    },
    {
      'sequence': [null, 2, 3, 4, 5],
      'answers': [1, 2, 3],
      'correct': 1
    },
    {
      'sequence': [3, 4, 5, null, 7],
      'answers': [5, 6, 7],
      'correct': 6
    },
  ];

  /// The seven level names, in the language the child's app is set to.
  ///
  /// Every one of these already had a translated key; they were written out
  /// in Ilocano here regardless of what the child had chosen.
  List<String> get _levelTitles {
    final loc = AppLocalizations.of(context)!;
    return [
      loc.counting,
      loc.dragNumber,
      loc.lineMatch,
      loc.popBalloon,
      loc.moreOrLess,
      loc.numberPuzzle,
      loc.numberSequence,
    ];
  }

  final List<IconData> _levelIcons = const [
    Icons.looks_one_rounded,
    LucideIcons.grip_vertical,
    LucideIcons.arrow_left_right,
    LucideIcons.party_popper,
    LucideIcons.scale,
    LucideIcons.puzzle,
    LucideIcons.list_ordered,
  ];

  /// Nine colours for nine balloons.
  ///
  /// The list is indexed by position and wrapped, so at seven entries the
  /// eighth and ninth balloons came out the same red and blue as the first
  /// two — and two balloons of one colour on a board where colour is how a
  /// child tells them apart is a board with a mistake on it.
  static const List<Color> _balloonColors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFFEC407A),
    Color(0xFF26C6DA),
    Color(0xFFFFCA28),
    Color(0xFF5C6BC0),
  ];

  // ─── Computed getters ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _currentGames {
    switch (_selectedLevel) {
      case 0:
        return _game1Levels;
      case 1:
        return _game2Levels;
      case 2:
        return _game3Levels;
      case 3:
        return _game4Levels;
      case 4:
        return _game5Levels;
      case 5:
        return _game6Levels;
      case 6:
        return _game7Levels;
      default:
        return _game1Levels;
    }
  }

  Map<String, dynamic> get _currentGame {
    final games = _currentGames;
    if (games.isEmpty) return {};
    return games[_currentGameIndex % games.length];
  }

  int get _starsFromWrong {
    if (_wrongAttempts == 0) return 3;
    if (_wrongAttempts == 1) return 2;
    return 1;
  }

  /// Records the points and the per-level star tally for THIS run.
  ///
  /// The child's actual star total is not touched here: a star is awarded for
  /// finishing a level, at the rating shown on the completion screen, so that
  /// the stars in the level summary, the header and the dashboard are all the
  /// same number. These per-question stars only decide what that rating is.
  /// Points for a correct answer, whatever it took to get there.
  ///
  /// A flat rate on purpose. The old 10-per-star scale paid 30 for a clean
  /// answer and 10 for a struggled one, which put totals in the hundreds —
  /// numbers a three-to-five-year-old cannot read, let alone judge. How well
  /// the answer went is what the 1-to-3 star rating is for; the points just
  /// count correct answers.
  static const int _pointsPerCorrect = 10;

  /// Points for a question the child answered but got wrong.
  ///
  /// Trying and missing is worth something: at three to five, having a go at
  /// all is the behaviour we want to encourage, and a flat zero teaches that
  /// a wrong answer was a waste of effort. Running the clock out earns
  /// nothing, because nothing was attempted.
  static const int _pointsPerWrongAttempt = 5;

  void _awardStars(int earned) {
    setState(() {
      _levelStars += earned;
      _levelScore += _pointsPerCorrect;
    });
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playModuleMusic(ModuleMusic.matematika);

    _starBurstController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _timerPulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _loadEarnedTotals();
    _initSmartResume();
    _startTimer();
  }

  /// Restores the running score and star totals the child has already banked.
  /// They are persisted after every question, so reopening the module must
  /// show the accumulated total rather than restarting from zero.
  Future<void> _loadEarnedTotals() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dailyStreak = prefs.getInt('matematika_streak') ?? 0;
    });
  }

  Future<void> _initSmartResume() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Safety wait for provider initialization (same as SplashScreen fix)
      int retryCount = 0;
      while (!userProvider.isInitialized && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
      }

      // 1. Find the first uncompleted LEVEL
      int firstUncompletedLevel = 0;
      for (int l = 0; l < _levelTitles.length; l++) {
        if (!userProvider.isMatematikaLevelCompleted(l)) {
          firstUncompletedLevel = l;
          break;
        }
        if (l == _levelTitles.length - 1) {
          firstUncompletedLevel = _levelTitles.length - 1;
        }
      }

      if (mounted) {
        setState(() {
          _selectedLevel = firstUncompletedLevel;
          _resetLevelState();
        });
      }
    } catch (e) {
      debugPrint('Smart Resume failed: $e');
      _resetLevelState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _starBurstController.dispose();
    _timerPulseController.dispose();
    _shakeController.dispose();
    AudioManager.instance.resumeHomeMusic();
    super.dispose();
  }

  // ─── Timer ───────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    if (!_timerEnabled) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isMatematikaGameCompleted(
          _selectedLevel, _currentGameIndex)) {
        return;
      }
    } catch (_) {}

    // Generous by design: a preschooler counts objects out loud and on their
    // fingers, so the clock has to outlast that rather than race it.
    int calculatedTime = 45 + (_consecutiveCorrectStreak * 3);
    if (calculatedTime > 60) calculatedTime = 60;
    _secondsLeft = calculatedTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  void _stopTimer() => _timer?.cancel();

  /// Running out of time moves on to the next question and keeps everything
  /// already earned. Sending a 3-to-5-year-old back to question one and wiping
  /// their stars punishes slow counting, which is exactly what they are here
  /// to practise.
  void _onTimeout() {
    // The tap and the last tick of the clock can land in the same frame, and
    // stopping a timer does not un-dispatch a callback already on its way.
    // Without this, that one frame shows two cards and queues two advances.
    if (_overlayShowing) return;
    _verdictRunning = true;
    // Running out of time is not a wrong answer, and must not be shown as
    // one. The clock expiring says nothing about whether the child knew the
    // answer — usually it means they were counting carefully, which is the
    // whole point of the exercise. Flashing the red ✕ at them for it told a
    // three-year-old they had failed at something they had not even attempted.
    //
    // What it shows instead is its own thing: a calm blue clock that neither
    // celebrates nor scolds.
    setState(() {
      _consecutiveCorrectStreak = 0;
      _showTimeUpOverlay = true;
    });

    // Counts as completed for progress tracking, but earns no stars and no
    // points: the child never got to answer.
    _saveQuestionProgress(0, points: 0);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _showTimeUpOverlay = false;
        _resetQuestionState();
      });
      _advanceOrComplete();
    });
  }

  // ─── State reset ─────────────────────────────────────────────────────────────

  void _resetLevelState() {
    // Determine the first uncompleted game index for the current level
    int firstUncompleted = 0;
    if (_replaying) {
      // Replaying: start at question one and let every question be answered
      // again, whatever the saved progress says.
      _currentGameIndex = 0;
      _levelStars = 0;
      _levelScore = 0;
      _wrongAttempts = 0;
      _resetQuestionState();
      return;
    }
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final total = _currentGames.length;
      for (int i = 0; i < total; i++) {
        if (!userProvider.isMatematikaGameCompleted(_selectedLevel, i)) {
          firstUncompleted = i;
          break;
        }
        // If all are completed, we go to the last one or show a completion state
        if (i == total - 1) firstUncompleted = total - 1;
      }
    } catch (_) {
      // Fallback if Provider is not ready
      firstUncompleted = 0;
    }

    _currentGameIndex = firstUncompleted;
    _levelStars = 0;
    _levelScore = 0;
    _wrongAttempts = 0;
    _resetQuestionState();
  }

  void _resetQuestionState() {
    _verdictRunning = false;
    _selectedAnswer = null;
    _dropCorrect = false;
    _dropWrong = false;
    _flownChipIndexGame2 = null;
    _selectedSide = null;
    _lineMatches.clear();
    _selectedLeftIndex = null;
    _poppedBalloons.clear();
    _wrongBalloons.clear();
    _showCorrectOverlay = false;

    // Game 3 extra reset
    _wrongFlash.clear();
    _lineChecked = false;
    _showWrongOverlay = false;
    _showTimeUpOverlay = false;

    if (_selectedLevel == 2) _initLineMatching();
    if (_selectedLevel == 5) _initPuzzle();
  }

  // ─── Game 3: node matching init ──────────────────────────────────────────────

  void _initLineMatching() {
    final count = (_currentGame['pairs'] as List<dynamic>).length;
    _shuffledRightIndices = List<int>.generate(count, (i) => i)
      ..shuffle(Random());
    _lineMatches.clear();
    _selectedLeftIndex = null;
    _wrongFlash.clear();
    _lineChecked = false;

    _leftNodeKeys
      ..clear()
      ..addAll(List.generate(count, (_) => GlobalKey()));
    _rightNodeKeys
      ..clear()
      ..addAll(List.generate(count, (_) => GlobalKey()));
  }

  void _initPuzzle() {
    _puzzleNumbers = List<int>.from(_currentGame['scrambled'] as List<dynamic>);
    _puzzleSlots = List<int?>.filled(_puzzleNumbers.length, null);
    _isPuzzleSolved = false;
  }

  // ─── Level switch ────────────────────────────────────────────────────────────

  void _switchLevel(int level) {
    _stopTimer();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final alreadyFinished = userProvider.isMatematikaLevelCompleted(level);
    setState(() {
      _selectedLevel = level;
      // A finished level is replayed from the beginning: there is no
      // "next unfinished question" to resume at.
      _replaying = alreadyFinished;
      _resetLevelState();
    });
    _startTimer();
  }

  /// Leaves the wall of cards for [level].
  void _openLevel(int level) {
    setState(() => _playing = true);
    _switchLevel(level);
  }

  /// Back to the wall of cards, without leaving Matematika.
  ///
  /// Everything half-finished is cleared on the way out: a verdict still
  /// running, or an overlay still up, would otherwise be waiting on the board
  /// the next time a level is opened.
  void _backToPicker() {
    _stopTimer();
    setState(() {
      _playing = false;
      _verdictRunning = false;
      _showCorrectOverlay = false;
      _showWrongOverlay = false;
      _showTimeUpOverlay = false;
    });
  }

  String _getLevelTitleLocalized(int index) {
    switch (index) {
      case 0:
        return AppLocalizations.of(context)!.counting;
      case 1:
        return AppLocalizations.of(context)!.dragNumber;
      case 2:
        return AppLocalizations.of(context)!.lineMatch;
      case 3:
        return AppLocalizations.of(context)!.popBalloon;
      case 4:
        return AppLocalizations.of(context)!.moreOrLess;
      case 5:
        return AppLocalizations.of(context)!.numberPuzzle;
      case 6:
        return AppLocalizations.of(context)!.numberSequence;
      default:
        return '';
    }
  }

  String _getHowManyFromMap(Map<String, dynamic> game) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    // The app's actual language codes are 'ilo' and 'fil' (see
    // LanguageProvider.languageCodes) — this checked 'il'/'tl', which never
    // matched, so this always fell through to English regardless of the
    // language the child had chosen.
    final key = lang.currentLanguage == 'ilo'
        ? 'item_name_il'
        : (lang.currentLanguage == 'fil' ? 'item_name_tl' : 'item_name_en');
    // The validated English question, written out per board. It sat in the
    // data unused while the screen showed the generic "How many {item}?".
    final english = game['question_en'] as String?;
    if (key == 'item_name_en' && english != null) return english;
    return AppLocalizations.of(context)!.howMany(game[key] ?? 'items');
  }

  String _getMatchFromMap(Map<String, dynamic> game) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    // Same fix as _getHowManyFromMap.
    final key = lang.currentLanguage == 'ilo'
        ? 'target_cat_il'
        : (lang.currentLanguage == 'fil' ? 'target_cat_tl' : 'target_cat_en');
    return AppLocalizations.of(context)!.matchWithNumber(game[key] ?? 'items');
  }

  void _advanceOrComplete() {
    // Every verdict here finishes on a 1.6 second timer, and that timer only
    // ever asked whether the screen was still mounted. Leaving a level is no
    // longer leaving the screen — the child lands on the wall of cards, still
    // inside Matematika — so a child who tapped back while the green check
    // was up was followed out by it: the next question, or the whole
    // level-complete card, opened on top of the cards a second later.
    if (!_playing) return;
    final total = _currentGames.length;
    if (_currentGameIndex < total - 1) {
      setState(() {
        _currentGameIndex++;
        _wrongAttempts = 0;
        _resetQuestionState();
      });
      _startTimer();
    } else {
      _showLevelComplete();
    }
  }

  // ─── Correct / wrong ─────────────────────────────────────────────────────────

  /// True while any answer feedback is on screen.
  ///
  /// The 1.6 seconds a feedback card is up is dead time the child can tap
  /// straight through, and a young child absolutely will — they press the
  /// same spot again the moment nothing happens. Every tap that lands in
  /// that window is counted as another answer, and the damage is real: a
  /// second wrong answer costs another star, banks another 5 points, and
  /// queues a second advance, so the game jumps a whole question and the
  /// level finishes with one never asked. This is what gates it.
  /// A card is on screen this instant. The verdict handlers check this, so
  /// they never refuse their own continuation.
  bool get _overlayShowing =>
      _showCorrectOverlay || _showWrongOverlay || _showTimeUpOverlay;

  /// True from the moment an answer is taken until the next question is up.
  ///
  /// Several games wait a beat before the card — long enough to see the last
  /// balloon pop or the lines turn green — and in that beat nothing was on
  /// screen to stop the next tap. Popping a wrong balloon there cost a star
  /// and skipped the question the child had just got right.
  bool _verdictRunning = false;

  /// Whether the board is the child's to touch. Wider than [_overlayShowing]:
  /// it also covers the beat before the card.
  bool get _feedbackShowing => _verdictRunning || _overlayShowing;

  void _onCorrect() {
    if (_showCorrectOverlay) return;
    HapticFeedback.heavyImpact();
    _stopTimer();

    final earned = _starsFromWrong;
    setState(() {
      if (earned == 3) {
        _consecutiveCorrectStreak++;
      } else {
        _consecutiveCorrectStreak = 0;
      }
      _showCorrectOverlay = true;
    });
    _awardStars(earned);

    _starBurstController.forward(from: 0);
    // No bottom banner on a correct answer. The green check that pops up over
    // the board already says "Good Job!", so the banner underneath repeated it
    // word for word — two announcements of the same thing, one of them below
    // where the child is looking.
    _saveQuestionProgress(earned, points: _pointsPerCorrect);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showCorrectOverlay = false);
      _advanceOrComplete();
    });
  }

  void _onWrong() {
    if (_overlayShowing) return;
    _verdictRunning = true;
    // A soft tap rather than a full buzz — gentler for young children.
    HapticFeedback.lightImpact();
    _shakeController.forward(from: 0);
    _stopTimer();

    setState(() {
      _wrongAttempts++;
      _consecutiveCorrectStreak = 0;
      _showWrongOverlay = true;
    });

    // Kept, rather than counted and discarded. The skill is stored by index:
    // a record holding "Mas Marami o Mas Kaunti" stops meaning anything the
    // moment someone reads the app in another language.
    Provider.of<UserProvider>(context, listen: false)
        .noteAttempt('matematika', 'level$_selectedLevel', correct: false);

    // No bottom banner. The big card that pops up over the board already
    // says this, so the strip underneath repeated it word for word — twice
    // for the same event, the second time below where the child is looking.
    // Half marks for attempting it, and no star.
    setState(() {
      _levelScore += _pointsPerWrongAttempt;
    });
    _saveQuestionProgress(0, points: _pointsPerWrongAttempt);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _showWrongOverlay = false;
        _selectedAnswer = null;
        _dropCorrect = false;
        _dropWrong = false;
        _selectedSide = null;
      });
      _advanceOrComplete();
    });
  }

  void _saveQuestionProgress(int earned, {required int points}) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // A right answer works the skill back down the practice list. Without
    // this the list only ever grows and stops describing the child as they
    // are now.
    if (earned > 0) {
      userProvider.noteAttempt('matematika', 'level$_selectedLevel',
          correct: true);
    }
    // The provider derives the real day streak from the stored last-played
    // date and hands it back for display.
    userProvider.updateMatematikaProgress().then((streak) {
      if (mounted) setState(() => _dailyStreak = streak);
    });
    userProvider.updateMatematikaGameProgress(
        _selectedLevel, _currentGameIndex, true);

    // ── Also persist directly so ForParentsScreen can read progress ──────
    _persistMatematikaProgress(points);
  }

  /// Banks the stars just earned.
  ///
  /// This is a running "stars I have earned" total, so every correct answer
  /// adds to it — including on a replay. Practising the same level again is
  /// exactly what we want a young child to do, and a star that refuses to
  /// move when they answer correctly reads as the game being broken.
  Future<void> _persistMatematikaProgress(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final gameKey = 'mat_level_${_selectedLevel}_game_$_currentGameIndex';

    // Mark this specific game as done
    await prefs.setBool(gameKey, true);

    if (points > 0) {
      await prefs.setInt(
          'mat_total_score', (prefs.getInt('mat_total_score') ?? 0) + points);
    }
  }

  // ─── Game handlers ───────────────────────────────────────────────────────────

  void _checkMCQ(int correct) {
    if (_selectedAnswer == null) {
      _showFeedback(AppLocalizations.of(context)!.chooseFirst, Colors.orange);
      return;
    }
    if (_selectedAnswer == correct) {
      _onCorrect();
    } else {
      _onWrong();
    }
  }

  void _handleDrop(int droppedValue, int correct) {
    if (droppedValue == correct) {
      setState(() {
        _dropCorrect = true;
        _verdictRunning = true;
      });
      Future.delayed(const Duration(milliseconds: 350), _onCorrect);
    } else {
      setState(() => _dropWrong = true);
      _onWrong();
    }
  }

  /// Sends the tapped number flying from where the finger landed to the
  /// basket, then grades it exactly as a drop would have — Game 2 used to
  /// ask a three-year-old to drag the chip there themselves, which tested
  /// carrying it steady more than counting. A tap keeps the counting and
  /// gives the "it went in the basket" moment back as an animation instead.
  void _flyNumberToBasket(int n, int correct, Offset startGlobal) {
    HapticFeedback.selectionClick();
    final basketBox =
        _basketKeyGame2.currentContext?.findRenderObject() as RenderBox?;
    if (basketBox == null || !basketBox.attached) {
      _handleDrop(n, correct);
      return;
    }
    final basketCenter =
        basketBox.localToGlobal(basketBox.size.center(Offset.zero));

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = curved.value;
          final pos = Offset.lerp(startGlobal, basketCenter, t)!;
          final scale = 1.0 - (t * 0.55);
          return Positioned(
            left: pos.dx - 38,
            top: pos.dy - 38,
            child: IgnorePointer(
              child: Opacity(
                opacity: (1.0 - t * 0.3).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: _numberChip(n, floating: true),
                ),
              ),
            ),
          );
        },
      ),
    );
    Overlay.of(context).insert(entry);
    controller.forward().whenCompleteOrCancel(() {
      entry.remove();
      controller.dispose();
      if (mounted) _handleDrop(n, correct);
    });
  }

  // ── Game 3: node tap handlers ─────────────────────────────────────────────

  void _handleLeftTap(int index) {
    // Once the board is graded the child is watching the result, not editing.
    if (_lineChecked) return;

    // Tapping a group that already has a line unhooks it. Because nothing is
    // marked right or wrong until every pair is connected, a child needs a way
    // to take a line back after seeing how the rest of the board turned out.
    if (_lineMatches.containsKey(index)) {
      HapticFeedback.selectionClick();
      setState(() {
        _lineMatches.remove(index);
        _selectedLeftIndex = null;
      });
      return;
    }
    setState(() => _selectedLeftIndex = index);
  }

  void _handleRightTap(int shuffledIndex) {
    if (_lineChecked) return;
    if (_selectedLeftIndex == null) {
      _showFeedback(
          AppLocalizations.of(context)!.chooseLeftFirst, Colors.orange);
      return;
    }
    if (_lineMatches.containsValue(shuffledIndex)) return;

    final pairs = _currentGame['pairs'] as List<dynamic>;
    final leftIdx = _selectedLeftIndex!;

    // The line is drawn whether or not it is right — grading waits until the
    // whole board is connected.
    HapticFeedback.selectionClick();
    setState(() {
      _lineMatches[leftIdx] = shuffledIndex;
      _selectedLeftIndex = null;
    });

    if (_lineMatches.length == pairs.length) {
      _gradeLineBoard(pairs);
    }
  }

  /// Grades every line at once, after the last pair has been connected.
  ///
  /// Matching on paper works this way: you draw all the lines, look at your
  /// work, then find out how you did. Checking each line the moment it is
  /// drawn told the child the answer to the remaining pairs by elimination,
  /// and ended the question on the first slip.
  void _gradeLineBoard(List<dynamic> pairs) {
    final wrong = <int, bool>{};
    _lineMatches.forEach((leftIdx, shuffledIdx) {
      final origRight = _shuffledRightIndices[shuffledIdx];
      if ((pairs[leftIdx]['count'] as int) != origRight + 1) {
        wrong[leftIdx] = true;
      }
    });

    setState(() {
      _lineChecked = true;
      _wrongFlash
        ..clear()
        ..addAll(wrong);
    });

    if (wrong.isEmpty) {
      HapticFeedback.lightImpact();
      _starBurstController.forward(from: 0);
      // A short beat before the card, so the lines turning green and the
      // ticks appearing are seen first — that was the real reason this board
      // had its own delay, and it survives without a second card.
      setState(() => _verdictRunning = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _onCorrect();
      });
      return;
    }

    HapticFeedback.vibrate();
    _shakeController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        // Keep the lines the child got right and lift only the mistakes, so
        // the board still shows what worked.
        for (final leftIdx in wrong.keys) {
          _lineMatches.remove(leftIdx);
        }
        _wrongFlash.clear();
        _lineChecked = false;
      });
      _onWrong();
    });
  }

  // ── Dot position helper ───────────────────────────────────────────────────

  List<Offset> _getDotPositions(List<GlobalKey> keys, {required bool isLeft}) {
    final stackBox =
        _game3StackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return [];
    return keys.map((key) {
      final ctx = key.currentContext;
      if (ctx == null) return Offset.zero;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return Offset.zero;
      final pos = box.localToGlobal(Offset.zero, ancestor: stackBox);
      final size = box.size;
      return isLeft
          ? Offset(pos.dx + size.width, pos.dy + size.height / 2)
          : Offset(pos.dx, pos.dy + size.height / 2);
    }).toList();
  }

  // ── Balloon handler ───────────────────────────────────────────────────────

  void _handleBalloonTap(int balloonIndex, int value, int target) {
    if (_poppedBalloons.contains(balloonIndex)) return;
    if (_wrongBalloons.contains(balloonIndex)) return;

    if (value == target) {
      HapticFeedback.lightImpact();
      // The bang, on the same tap as the buzz and the burst.
      Sfx.play(Sfx.pop);
      final balloons = _currentGame['balloons'] as List<dynamic>;
      final allCorrectIndices = <int>{};
      for (int i = 0; i < balloons.length; i++) {
        if (balloons[i] == target) allCorrectIndices.add(i);
      }
      setState(() => _poppedBalloons.add(balloonIndex));
      if (_poppedBalloons.containsAll(allCorrectIndices)) {
        setState(() => _verdictRunning = true);
        Future.delayed(const Duration(milliseconds: 350), _onCorrect);
      }
    } else {
      setState(() => _wrongBalloons.add(balloonIndex));
      _onWrong();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _wrongBalloons.remove(balloonIndex));
      });
    }
  }

  void _handleSideSelection(String tappedSide) {
    if (_showCorrectOverlay) return;
    if (_selectedSide != null) return;

    final correct = _currentGame['correct'] as String;
    if (correct == 'equal') {
      return; // In equal question mode, child must choose Oo or Hindi button
    }

    final isCorrect = tappedSide == correct;

    setState(() => _selectedSide = tappedSide);

    if (isCorrect) {
      setState(() => _verdictRunning = true);
      Future.delayed(const Duration(milliseconds: 300), _onCorrect);
    } else {
      setState(() => _verdictRunning = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _selectedSide = null);
        _onWrong();
      });
    }
  }

  void _handleEqualChoice(bool choseYes) {
    if (_showCorrectOverlay) return;
    final correct = _currentGame['correct'] as String;
    final isActuallyEqual = correct == 'equal';
    final isCorrect = choseYes == isActuallyEqual;

    if (isCorrect) {
      setState(() {
        _selectedSide = 'equal';
        _verdictRunning = true;
      });
      Future.delayed(const Duration(milliseconds: 300), _onCorrect);
    } else {
      _onWrong();
    }
  }

  /// Drops a dragged tile into the box it was released over.
  ///
  /// The child chooses the box, rather than the game deciding for them: which
  /// number goes *where* is the whole question, so the drop has to land where
  /// they aimed it.
  void _dropPuzzleTile(int value, int slot) {
    if (_isPuzzleSolved) return;
    setState(() {
      // Dropping onto a box that already holds something replaces it; the old
      // number simply returns to the tray below.
      _puzzleSlots[slot] = value;
    });
    HapticFeedback.lightImpact();
    _checkPuzzleComplete();
  }

  /// Puts a tapped number into the first empty box.
  ///
  /// The drag lets a child aim at any box; the tap fills them in order, which
  /// is how they fill them in practice. A wrong guess still comes out with one
  /// tap on the box, so ordering by tap is never a trap.
  void _tapPuzzleTile(int value) {
    if (_isPuzzleSolved || _feedbackShowing) return;
    final slot = _puzzleSlots.indexOf(null);
    if (slot == -1) return;
    _dropPuzzleTile(value, slot);
  }

  /// Takes a tile back out of a box, so a change of mind costs one tap.
  void _clearPuzzleSlot(int slot) {
    if (_isPuzzleSolved || _puzzleSlots[slot] == null) return;
    setState(() => _puzzleSlots[slot] = null);
    HapticFeedback.selectionClick();
  }

  void _checkPuzzleComplete() {
    if (_puzzleSlots.contains(null)) return;
    final correct = List<int>.from(_currentGame['correct'] as List<dynamic>);

    if (_puzzleSlots.join() == correct.join()) {
      setState(() => _isPuzzleSolved = true);
      Future.delayed(const Duration(milliseconds: 450), _onCorrect);
      return;
    }

    // Wrong order: empty the boxes so the child can try the whole row again
    // rather than hunting for which single box is out of place.
    _onWrong();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(
          () => _puzzleSlots = List<int?>.filled(_puzzleNumbers.length, null));
    });
  }

  // ─── Feedback ────────────────────────────────────────────────────────────────

  void _showFeedback(String msg, Color color) {
    setState(() {
      _feedbackMessage = msg;
      _feedbackColor = color;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _feedbackMessage = '';
          _feedbackColor = Colors.transparent;
        });
      }
    });
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  void _showLevelComplete() {
    if (!_playing) return;
    _verdictRunning = false;
    _stopTimer();
    _replaying = false;
    final total = _currentGames.length;
    final avgStars = total == 0 ? 1 : (_levelStars / total).ceil().clamp(1, 3);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.awardMatematikaLevelCompletion(
        _selectedLevel, avgStars, _levelScore);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessModal(
        title: AppLocalizations.of(context)!.levelComplete(_selectedLevel + 1),
        subtitle: _getLevelTitleLocalized(_selectedLevel),
        // This level's points, not the module's running total — the card is
        // reporting the level the child just finished.
        score: _levelScore,
        stars: avgStars,
        streak: _dailyStreak,
        primaryLabel: _selectedLevel < _levelTitles.length - 1
            ? AppLocalizations.of(context)!.continueText
            : AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.pop(context);
          if (_selectedLevel < _levelTitles.length - 1) {
            _switchLevel(_selectedLevel + 1);
          } else {
            // The last level: back to the cards, where the star that was
            // just earned is now sitting on one of them. This used to pop
            // the module itself and drop the child on the dashboard.
            _backToPicker();
          }
        },
        secondaryLabel: AppLocalizations.of(context)!.back,
        onSecondaryTap: () {
          Navigator.pop(context);
          _backToPicker();
        },
        mainColor: AppColors.numbers,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The phone's own back button, and the browser's. In a level it means
      // "leave the level", not "leave Matematika" — a child who taps it
      // mid-question should land on the cards they came from.
      canPop: !_playing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToPicker();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FE), Color(0xFFEDF1F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // The notebook doodles of the About Me boards, behind every game.
            if (_playing) const Positioned.fill(child: DoodleBackground()),
            // Nothing under a feedback card is tappable while it is up.
            //
            // Guarding each handler separately never held: there are a dozen
            // ways into an answer here — tiles, balloons, drag targets, the
            // check button, the level tabs — and every new game added another
            // one to remember. One gate around the whole board cannot be
            // forgotten, and it also stops the child leaving the question
            // mid-feedback, which used to leave the timer and the overlay
            // out of step.
            AbsorbPointer(
              absorbing: _feedbackShowing,
              child: _playing
                  ? Column(
                      children: [
                        _buildProgressHeader(),
                        Expanded(child: _buildGameContent()),
                        _buildFeedbackBanner(),
                      ],
                    )
                  : _buildLevelPicker(),
            ),
            // One card for a correct answer, one for a wrong one, one for
            // the clock — the same three in every game in the module.
            if (_playing && _showCorrectOverlay) _buildCorrectOverlay(),
            if (_playing && _showWrongOverlay) _buildWrongOverlay(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: CustomBackButton(
        iconColor: AppColors.textDark,
        onPressed: () => _playing ? _backToPicker() : Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.matematika,
        style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 16),
              const SizedBox(width: 4),
              // The child's one star total, read straight from the profile so
              // this badge and the dashboard can never show different numbers.
              Text(
                '${Provider.of<UserProvider>(context).displayStars}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  static const List<List<Color>> _levelGradients = [
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)], // Level 0: Coral Sunset
    [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Level 1: Ocean Blue
    [Color(0xFF11998E), Color(0xFF38EF7D)], // Level 2: Emerald Green
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Level 3: Royal Purple
    [Color(0xFFFFB75E), Color(0xFFED8F03)], // Level 4: Sunburst Amber
    [Color(0xFFFF512F), Color(0xFFDD2476)], // Level 5: Warm Rose
    [Color(0xFF4364F7), Color(0xFF6FB1FC)], // Level 6: Electric Blue
  ];

  /// Every level as a card, and nothing else on the screen.
  ///
  /// The levels used to be a strip of tabs pinned above the board for as long
  /// as the child played. It cost about 76 pixels of a board that every game
  /// in here is laid out to fit without scrolling — but the real fault was
  /// that it left a live control sitting directly over the question. One
  /// touch from the palm of a three-year-old holding the phone, and the
  /// question they were in the middle of was gone; the guard around the whole
  /// board names the level tabs as one of the ways that happened.
  ///
  /// As a screen of its own it is also the shelf their stars land on: they
  /// leave it to play, and come back to watch a card fill in.
  Widget _buildLevelPicker() {
    final userProvider = Provider.of<UserProvider>(context);
    int earned = 0;
    for (int i = 0; i < _levelTitles.length; i++) {
      earned += userProvider.matematikaLevelStars(i);
    }
    const possible = UserProvider.matematikaStarCeiling;

    return Column(
      children: [
        StarTally(earned: earned, possible: possible),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              // Taller than wide: the title takes two lines in Tagalog
              // and Ilocano more often than it does in English.
              childAspectRatio: 0.98,
            ),
            itemCount: _levelTitles.length,
            // The wall assembles rather than appearing. Each card is a
            // beat behind the one before it, which walks a child's eye
            // across them instead of dropping seven at once.
            itemBuilder: (_, i) => StaggeredEntrance(
              index: i,
              delayMs: 55,
              durationMs: 380,
              child: _levelCard(i, userProvider),
            ),
          ),
        ),
      ],
    );
  }

  /// One level, in its own colour, with what the child has taken from it.
  Widget _levelCard(int i, UserProvider userProvider) {
    final completed = userProvider.isMatematikaLevelCompleted(i);
    final stars = userProvider.matematikaLevelStars(i);
    final gradient = _levelGradients[i % _levelGradients.length];

    return Pressable(
      onTap: () => completed ? _confirmReplay(i) : _openLevel(i),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // The number lives in the badge rather than on a line of its
                // own. Stacked, the card needed 168 logical pixels of fixed
                // height and a 360-wide phone gives each cell 167 — an
                // overflow stripe on the most common screen there is.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_levelIcons[i],
                    color: Colors.white.withOpacity(0.85), size: 20),
                const Spacer(),
                if (completed)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 16, color: gradient.first),
                  ),
              ],
            ),
            const Spacer(),
            WordSafeText(
              _getLevelTitleLocalized(i),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            _levelStarStrip(stars, true, size: 26),
          ],
        ),
      ),
    );
  }

  /// Tapping a level that is already finished.
  ///
  /// Kept exactly as it was on the old strip: it shows what the level is
  /// currently worth before offering a replay, because a replay replaces that
  /// rating rather than adding to it.
  void _confirmReplay(int i) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 40),
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.finishedAlready,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        // Show what this level is currently worth before
        // offering a replay, so the child can see the star they
        // are about to put back on the table.
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (s) {
                final earned = s < userProvider.matematikaLevelStars(i);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color:
                        earned ? const Color(0xFFFFB800) : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '${userProvider.matematikaLevelScore(i)} '
              '${AppLocalizations.of(context)!.pointsLabel}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.doneAlready,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.replayReplacesStar,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.numbers,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openLevel(i);
            },
            icon: const Icon(LucideIcons.rotate_ccw, size: 19),
            label: Text(AppLocalizations.of(context)!.ulitin,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.okButton,
                style: const TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _levelStarStrip(int stars, bool active, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (s) {
        final got = s < stars;
        return Icon(
          got ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: active
              ? (got ? Colors.white : Colors.white.withOpacity(0.55))
              : (got ? const Color(0xFFFFB800) : Colors.grey.shade400),
        );
      }),
    );
  }

  Widget _buildProgressHeader() {
    final total = _currentGames.length;
    final progress = total == 0 ? 0.0 : (_currentGameIndex + 1) / total;
    final activeGradient =
        _levelGradients[_selectedLevel % _levelGradients.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: activeGradient),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_levelIcons[_selectedLevel],
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(_getLevelTitleLocalized(_selectedLevel),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentGameIndex + 1} / $total',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.02, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: activeGradient),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: activeGradient.last.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectOverlay() {
    return AnswerFeedback.correct(
        message: AppLocalizations.of(context)!.correct);
  }

  Widget _buildWrongOverlay() {
    return AnswerFeedback.wrong(
        message: AppLocalizations.of(context)!.wrongShort);
  }

  Widget _buildFeedbackBanner() {
    if (_feedbackMessage.isEmpty) return const SizedBox(height: 16);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_feedbackColor, _feedbackColor.withOpacity(0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _feedbackColor.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Text(
        _feedbackMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19),
      ),
    );
  }

  // ─── Reusable widgets ────────────────────────────────────────────────────────

  Widget _mcqTile(int answer, {required int correct}) {
    final selected = _selectedAnswer == answer;
    // White until tapped, then green or red — the About Me answer buttons.
    final verdict = selected ? answer == correct : null;
    return Pressable(
      onTap: () {
        if (_feedbackShowing || _selectedAnswer != null) return;
        setState(() => _selectedAnswer = answer);
        _verdictRunning = true;
        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted) _checkMCQ(correct);
        });
      },
      // Large tap target: small fingers need room to hit it reliably.
      child: _chunkyNumber(answer, 92, 44, verdict: verdict),
    );
  }

  Widget _gameCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: AppColors.numbers.withOpacity(0.12), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.numbers.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }

  // ─── Game routing ─────────────────────────────────────────────────────────────

  Widget _buildGameContent() {
    if (_currentGames.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.noGamesAvailable2));
    }

    Widget gameWidget;
    switch (_selectedLevel) {
      case 0:
        gameWidget = _buildGame1();
        break;
      case 1:
        gameWidget = _buildGame2();
        break;
      case 2:
        gameWidget = _buildGame3();
        break;
      case 3:
        gameWidget = _buildGame4();
        break;
      case 4:
        gameWidget = _buildGame5();
        break;
      case 5:
        gameWidget = _buildGame6();
        break;
      case 6:
        gameWidget = _buildGame7();
        break;
      default:
        gameWidget = _buildGame1();
    }

    final userProvider = Provider.of<UserProvider>(context);
    final isCompleted = userProvider.isMatematikaGameCompleted(
        _selectedLevel, _currentGameIndex);

    // A wrong answer — and a question the clock ran out on — still marks the
    // question completed for progress tracking, so without excluding those
    // here the green "Finished already!" card popped up on top of the child's
    // mistake, and again over the Time's Up clock.
    if (isCompleted &&
        !_replaying &&
        !_showCorrectOverlay &&
        !_showWrongOverlay &&
        !_showTimeUpOverlay) {
      return Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: IgnorePointer(child: gameWidget),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.green, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.circle_check,
                      color: Colors.green, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.finishedAlready,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return gameWidget;
  }

  // ─── Game 1: Count & pick ────────────────────────────────────────────────────

  /// The question, said by the dino in the coral speech cloud — the same
  /// [QuestionCloud] the About Me boards ask with.
  ///
  /// Every game asks its question through this, so none of them can drift
  /// from the rest. The cloud is as tall as a share of its width (less when
  /// it is given less), and the words inside shrink to fit it.
  Widget _questionText(String text) => LayoutBuilder(builder: (_, box) {
        final byWidth = box.maxWidth * 0.50;
        final h =
            box.maxHeight.isFinite ? min(box.maxHeight, byWidth) : byWidth;
        return SizedBox(
          width: box.maxWidth,
          height: h,
          child: QuestionCloud(text),
        );
      });

  /// A number on a white 3D button, as the About Me answers are drawn —
  /// turning green or red once [verdict] is known. [width] is the face; the
  /// solid edge under it adds 5.
  Widget _chunkyNumber(int n, double width, double fontSize, {bool? verdict}) {
    return SizedBox(
      width: width,
      height: width + 5,
      child: ToneFrame(
        index: 0,
        verdict: verdict,
        padding: EdgeInsets.zero,
        child: Center(
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: ToneFrame.inkFor(0, verdict: verdict),
            ),
          ),
        ),
      ),
    );
  }

  /// The things to be counted, drawn as large as the space allows.
  ///
  /// The objects *are* the question in a counting game, so they get the room.
  /// They used to sit at a fixed 44px in a Wrap, which left most of the card
  /// empty and the pictures too small for a three-year-old to count without
  /// leaning in — exactly backwards.
  ///
  /// The size is worked out from the box: pick a column count that keeps the
  /// arrangement roughly square, then take the smaller of the cell's width
  /// and height. Capped, so a single object does not swell to fill the card.
  /// [sizeForCount] fixes the picture size to what *that* many objects would
  /// need, instead of to however many are actually here.
  ///
  /// "Which is more?" needs it. Sizing each side to its own count drew one
  /// apple enormous beside three small ones, so the bigger picture belonged
  /// to the smaller number and the child had to ignore what they could see in
  /// order to answer. Pass the larger of the two counts on both sides and
  /// every apple comes out the same size, which is the only way the question
  /// means anything.
  Widget _countableObjects(List<dynamic> objects, {int? sizeForCount}) {
    return LayoutBuilder(builder: (_, box) {
      const gap = 10.0;
      final sizeN = sizeForCount ?? objects.length;

      // The grid is chosen, not fixed: whichever column count makes each
      // picture biggest wins.
      //
      // A fixed two columns was wrong half the time. The space is wider than
      // it is tall, so two columns of five objects means three rows, and the
      // height — not the width — is what shrinks them. Three columns of the
      // same five is two rows, and every bird gets noticeably bigger. But at
      // four objects two columns really is the bigger layout, so neither
      // number is right on its own. Measuring both and keeping the larger
      // result is, and it stays right whatever the phone or the count.
      //
      // Ties keep the fewer columns, which reads tidier, and nothing goes
      // past four across — beyond that a child stops counting and starts
      // scanning.
      int sizeCols = 1;
      double side = 0;
      final maxCols = sizeN < 4 ? sizeN : 4;
      for (int cols = 1; cols <= (maxCols < 1 ? 1 : maxCols); cols++) {
        final rows = (sizeN / cols).ceil();
        // Every picture carries half a gap of padding on each side, so a
        // line of them is a whole gap per picture wider (and a column a
        // whole gap per row taller) than the pictures alone — counting one
        // gap fewer ran the last picture 10 pixels off the card.
        final w = (box.maxWidth - gap * cols) / cols;
        final h = (box.maxHeight - gap * rows) / rows;
        final candidate = w < h ? w : h;
        if (candidate > side) {
          side = candidate;
          sizeCols = cols;
        }
      }
      side = side.clamp(28.0, 170.0);

      // Rows of at most [sizeCols], so the objects sit in tidy lines a child
      // can count along instead of a shape they have to work out first.
      final rows = <List<dynamic>>[];
      for (var i = 0; i < objects.length; i += sizeCols) {
        rows.add(objects.sublist(
            i, i + sizeCols > objects.length ? objects.length : i + sizeCols));
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: gap / 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final o in row)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: gap / 2),
                        // A picture when one exists for this object, the
                        // emoji until then — see [ObjectPicture].
                        child: ObjectPicture(
                          emoji: o as String,
                          size: side,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  /// The question, then the play area under it.
  ///
  /// Several boards are the same shape underneath — something to read, then
  /// something to do — so they share this rather than each growing its own
  /// copy of the arrangement.
  Widget _boardFrame({
    required Widget question,
    required Widget play,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          question,
          const SizedBox(height: 12),
          Expanded(child: play),
        ],
      ),
    );
  }

  Widget _buildGame1() {
    final game = _game1Levels[_currentGameIndex % _game1Levels.length];
    final objects = game['objects'] as List<dynamic>;
    final answers = game['answers'] as List<dynamic>;

    // Laid out to fit, never to scroll. A board a child can swipe away is a
    // board where the question can end up off-screen — and the question is the
    // one thing they must be able to see at all times.
    //
    // Two halves, named: what is being counted, and what the child answers
    // with.
    final card = _gameCard(
      child: Column(
        children: [
          // Capped at a third of the card, so a long question can
          // never squeeze the things being counted into a sliver.
          // Measured against the card rather than fixed at 120: on a
          // small phone the whole card is barely twice that, and a
          // flat number meant the cap did nothing where it was needed
          // most.
          LayoutBuilder(
            builder: (_, box) => ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight * 0.32),
              child: _questionText(_getHowManyFromMap(game)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _countableObjects(objects)),
        ],
      ),
    );

    final answerRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: answers
          .map((a) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _mcqTile(a as int, correct: game['correct'] as int),
              ))
          .toList(),
    );

    final prompt = Text(
      AppLocalizations.of(context)!.selectCorrectAnswer,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Expanded(child: card),
          const SizedBox(height: 12),
          prompt,
          const SizedBox(height: 10),
          answerRow,
        ],
      ),
    );
  }

  // ─── Game 2: Drag & drop ─────────────────────────────────────────────────────

  Widget _buildGame2() {
    final game = _game2Levels[_currentGameIndex % _game2Levels.length];
    final correct = game['correct'] as int;
    final choices = game['choices'] as List<dynamic>;
    final emoji = game['emoji'] as String;

    // The three pieces of this board, named: the objects to count, the
    // basket to drop into, and the numbers to drag.
    final card = _gameCard(
      child: Column(
        children: [
          // The instruction gets at most a third of the card.
          //
          // It had no ceiling before, and it is three lines long, so
          // it was taking well over half — the objects were left
          // roughly 85 logical pixels for two rows and came out at
          // the minimum size the layout allows. Capping it hands that
          // height straight to the things being counted, and the
          // question shrinks to fit rather than being cut off,
          // because _questionText scales down inside whatever room
          // it is given.
          LayoutBuilder(
            builder: (_, box) => ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight * 0.36),
              child: _questionText(
                  AppLocalizations.of(context)!.countAndDragCorrectNumber),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _countableObjects(List.generate(correct, (_) => emoji)),
          ),
        ],
      ),
    );

    // The basket. Landing the right number in it is the whole move, so it
    // is drawn as a real basket rather than a dashed rectangle — a
    // three-year-old understands "put it in the basket" without being
    // able to read a word of the instruction. Keyed so a tapped number
    // knows where on screen to fly to.
    final basket = Column(
      key: _basketKeyGame2,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            BasketPicture(
              // Was 170 — a third of everything below the card, on a
              // screen where the objects being counted were the part
              // too small to use.
              size: 110,
              holding: _dropCorrect ? correct : null,
            ),
            if (_dropCorrect)
              const Positioned(
                top: 0,
                child: Icon(LucideIcons.circle_check,
                    color: Colors.green, size: 42),
              ),
            if (_dropWrong)
              const Positioned(
                top: 0,
                child: Icon(LucideIcons.circle_x,
                    color: Color(0xFFF59E0B), size: 42),
              ),
          ],
        ),
      ],
    );

    // The numbers to choose from, kept clear of the objects so a raised
    // finger never covers what the child is counting.
    //
    // A tap sends the number flying into the basket (see
    // _flyNumberToBasket) rather than asking a three-year-old to carry it
    // there themselves — dragging is a separate fine-motor skill from
    // counting, and this game is about counting.
    final numbers = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: choices.asMap().entries.map((entry) {
        final idx = entry.key;
        final n = entry.value as int;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // Hidden by opacity rather than removed the moment it starts
          // flying — removing it would shrink the row by one chip and slide
          // every number after it sideways to fill the gap, which is not a
          // response to a tap this age reads as "my answer went in", it
          // reads as the whole board rearranging itself. The blank space
          // holds its place until the next question replaces it outright.
          child: Opacity(
            opacity: idx == _flownChipIndexGame2 ? 0 : 1,
            child: GestureDetector(
              onTapDown: (details) {
                if (_feedbackShowing ||
                    _dropCorrect ||
                    _flownChipIndexGame2 != null) {
                  return;
                }
                setState(() => _flownChipIndexGame2 = idx);
                _flyNumberToBasket(n, correct, details.globalPosition);
              },
              child: _numberChip(n),
            ),
          ),
        );
      }).toList(),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Expanded(flex: 5, child: card),
          const SizedBox(height: 12),
          basket,
          const SizedBox(height: 12),
          numbers,
        ],
      ),
    );
  }

  Widget _numberChip(int n, {bool floating = false}) =>
      _chunkyNumber(n, 76, 36);

  // ─── Game 3: Node-to-node line matching ──────────────────────────────────────

  Widget _buildGame3() {
    final game = _currentGame;
    final pairs = game['pairs'] as List<dynamic>;
    final count = pairs.length;

    // Safety: ensure keys are initialised
    while (_leftNodeKeys.length < count) {
      _leftNodeKeys.add(GlobalKey());
    }
    while (_rightNodeKeys.length < count) {
      _rightNodeKeys.add(GlobalKey());
    }
    if (_shuffledRightIndices.length != count) _initLineMatching();

    final matched = _lineMatches.length;

    // Numbers on the right that are on the far end of a wrong line, so they
    // can be marked too instead of only the emoji group.
    final wrongRights = <int>{};
    for (final leftIdx in _wrongFlash.keys) {
      final r = _lineMatches[leftIdx];
      if (r != null) wrongRights.add(r);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Instruction
          _questionText(_getMatchFromMap(game)),
          const SizedBox(height: 3),
          Text(
            AppLocalizations.of(context)!.tapLeftTapRight,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Score badge  (fraction style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: RichText(
              text: TextSpan(
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '$matched',
                    style: TextStyle(
                      // Green means "all correct", which is not known until
                      // the board is graded — a full count alone is not it.
                      color: _lineChecked && _wrongFlash.isEmpty
                          ? Colors.green
                          : AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                  TextSpan(
                    text: ' / $count',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const TextSpan(
                    text: '  natugma',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Main matching area
          Expanded(
            child: Stack(
              key: _game3StackKey,
              children: [
                // ── Lines layer ────────────────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_shakeController, _starBurstController]),
                      builder: (_, __) {
                        final lDots =
                            _getDotPositions(_leftNodeKeys, isLeft: true);
                        final rDots =
                            _getDotPositions(_rightNodeKeys, isLeft: false);
                        return CustomPaint(
                          painter: _Game3LinePainter(
                            leftDots: lDots,
                            rightDots: rDots,
                            matches: Map.from(_lineMatches),
                            wrongFlash: Map.from(_wrongFlash),
                            checked: _lineChecked,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Nodes layer ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT – emoji groups
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(count, (i) {
                            final objs = (pairs[i]['objects'] as List<dynamic>)
                                .cast<String>();
                            final isMatch = _lineMatches.containsKey(i);
                            final isSel = _selectedLeftIndex == i;
                            final isWrong = _wrongFlash[i] == true;
                            return _buildLeftNode(
                              nodeKey: _leftNodeKeys[i],
                              emojis: objs,
                              selected: isSel,
                              matched: isMatch,
                              isWrong: isWrong,
                              checked: _lineChecked,
                              onTap: () => _handleLeftTap(i),
                            );
                          }),
                        ),
                      ),

                      // Centre gap (lines pass through here)
                      const SizedBox(width: 56),

                      // RIGHT – numbers (shuffled)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(count, (shuffled) {
                            final orig = _shuffledRightIndices[shuffled];
                            final isMatch =
                                _lineMatches.containsValue(shuffled);
                            return _buildRightNode(
                              nodeKey: _rightNodeKeys[shuffled],
                              number: orig + 1,
                              matched: isMatch,
                              isWrong: wrongRights.contains(shuffled),
                              checked: _lineChecked,
                              onTap: () => _handleRightTap(shuffled),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // The old full-screen red circle sat in the middle of the
                // board and hid the very lines that show which pairs were
                // wrong. The red lines are the feedback now, and the wrong
                // answer card follows right after.

                // This board used to raise a congratulations card of its
                // own here — its own colour, its own shape, and the words
                // "Nalpas! Good Job!" typed straight into the code in no
                // language the app actually offers. It also ran *before* the
                // shared card, so clearing the board showed two different
                // celebrations back to back. Every game says the same thing
                // the same way now: the one card in [AnswerFeedback].
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Left node widget ──────────────────────────────────────────────────────

  Widget _buildLeftNode({
    required Key nodeKey,
    required List<String> emojis,
    required bool selected,
    required bool matched,
    required bool isWrong,
    required bool checked,
    required VoidCallback onTap,
  }) {
    // A connected group only turns green after the whole board is graded.
    final Color linked = checked ? Colors.green : AppColors.primary;

    final Color border = isWrong
        ? Colors.red
        : matched
            ? linked
            : selected
                ? AppColors.primary
                : Colors.grey.shade300;

    final Color bg = isWrong
        ? Colors.red.withOpacity(0.07)
        : matched
            ? linked.withOpacity(0.07)
            : selected
                ? AppColors.primary.withOpacity(0.09)
                : Colors.white;

    return GestureDetector(
      key: nodeKey,
      // While the board is still being filled in, tapping a connected group
      // takes its line back — see _handleLeftTap.
      onTap: (checked || isWrong) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 66,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.22),
                      blurRadius: 10)
                ]
              : [
                  const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The same pictures as the counting boards, in a row. Drawn one
            // by one rather than as a joined string so each object can be an
            // image; a single Text could only ever be emoji.
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in emojis)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ObjectPicture(emoji: e, size: 26),
                    ),
                ],
              ),
            ),
            // Right-edge connector dot
            Positioned(
              right: -19,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWrong
                        ? Colors.red
                        : matched
                            ? linked
                            : selected
                                ? AppColors.primary
                                : Colors.grey.shade400,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
            // The tick is a verdict, so it only appears after grading.
            if (matched && checked && !isWrong)
              const Positioned(
                top: 4,
                right: -2,
                child: Icon(LucideIcons.circle_check,
                    color: Colors.green, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ── Right node widget ─────────────────────────────────────────────────────

  Widget _buildRightNode({
    required Key nodeKey,
    required int number,
    required bool matched,
    required bool isWrong,
    required bool checked,
    required VoidCallback onTap,
  }) {
    final Color linked = isWrong
        ? Colors.red
        : checked
            ? Colors.green
            : AppColors.primary;
    final border = matched ? linked : Colors.grey.shade300;
    final bg = matched ? linked.withOpacity(0.07) : Colors.white;

    return GestureDetector(
      key: nodeKey,
      onTap: matched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 66,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2.2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: matched ? linked : AppColors.textDark,
                ),
              ),
            ),
            // Left-edge connector dot
            Positioned(
              left: -19,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: matched ? linked : Colors.grey.shade400,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Game 4: Pop the Balloon ─────────────────────────────────────────────────

  Widget _buildGame4() {
    final game = _game4Levels[_currentGameIndex % _game4Levels.length];
    final target = game['target'] as int;
    final balloons = game['balloons'] as List<dynamic>;

    final totalCorrect = balloons.where((b) => b == target).length;
    final popped = _poppedBalloons.length;

    return _boardFrame(
      question: Column(
        children: [
          _questionText(
              '${AppLocalizations.of(context)!.popAllBalloonsWith} $target'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$popped / $totalCorrect  ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              // One dot per balloon that has to go, filling as they do.
              // Both branches used to name the same outline icon, so the
              // row never moved and told the child nothing.
              ...List.generate(
                totalCorrect,
                (i) => Icon(
                  i < popped ? LucideIcons.circle_check : LucideIcons.circle,
                  color: i < popped
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  size: 14,
                ),
              ),
            ],
          ),
        ],
      ),
      play: LayoutBuilder(builder: (_, box) {
        // Size the cells to the space that is actually there, so every
        // balloon is on screen at once. The grid used to keep its own
        // fixed aspect ratio and scroll whatever was left over, which
        // let a child swipe the question off the top of the board while
        // hunting for the last balloon.
        const cols = 3;
        const gap = 12.0;
        final rows = (balloons.length / cols).ceil();
        final cellW = (box.maxWidth - gap * (cols - 1)) / cols;
        final cellH = (box.maxHeight - gap * (rows - 1)) / rows;

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: cellW / (cellH <= 0 ? 1 : cellH),
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
          ),
          itemCount: balloons.length,
          itemBuilder: (_, i) {
            final val = balloons[i] as int;
            final isPopped = _poppedBalloons.contains(i);
            final isWrong = _wrongBalloons.contains(i);
            final color = _balloonColors[i % _balloonColors.length];

            return GestureDetector(
              onTap: () => _handleBalloonTap(i, val, target),
              // Scales into whatever cell the grid worked out, instead of
              // overflowing a fixed 70x82. Not clipped, so the burst is
              // allowed to throw rubber past the edge of its own cell.
              child: FittedBox(
                fit: BoxFit.contain,
                child: PopBalloon(
                  value: val,
                  color: color,
                  popped: isPopped,
                  wrong: isWrong,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ─── Game 5: More / Less / Equal ─────────────────────────────────────────────

  Widget _buildGame5() {
    final game = _game5Levels[_currentGameIndex % _game5Levels.length];
    final correct = game['correct'] as String;
    final isEqual = correct == 'equal' || game['type'] == 'equal';

    // Both sides draw their objects at the size the *larger* pile needs, so
    // one picture is never bigger than another just because there are fewer
    // of them. Without this the answer looked back to front.
    final leftCount = game['leftCount'] as int;
    final rightCount = game['rightCount'] as int;
    final sizeForCount = leftCount > rightCount ? leftCount : rightCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          _questionText(
            game['type'] == 'more'
                ? AppLocalizations.of(context)!.whichIsMore
                : game['type'] == 'less'
                    ? AppLocalizations.of(context)!.whichIsLess
                    : AppLocalizations.of(context)!.isSameNumber,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _game5Side(
                  sideKey: 'left',
                  objects:
                      (game['leftObjects'] as List<dynamic>).cast<String>(),
                  label: AppLocalizations.of(context)!.left,
                  correct: correct,
                  isEqualMode: isEqual,
                  sizeForCount: sizeForCount,
                ),
                _game5Side(
                  sideKey: 'right',
                  objects:
                      (game['rightObjects'] as List<dynamic>).cast<String>(),
                  label: AppLocalizations.of(context)!.right,
                  correct: correct,
                  isEqualMode: isEqual,
                  sizeForCount: sizeForCount,
                ),
              ],
            ),
          ),
          if (isEqual) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _yesNoButton(true)),
                const SizedBox(width: 14),
                Expanded(child: _yesNoButton(false)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _game5Side({
    required String sideKey,
    required List<String> objects,
    required String label,
    required String correct,
    required int sizeForCount,
    bool isEqualMode = false,
  }) {
    final selected = _selectedSide == sideKey;
    final answered = _selectedSide != null;

    // White until answered; then the right side turns green and a wrongly
    // chosen one red. "Same number" boards are answered with Yes / No, so
    // their sides stay white.
    final bool? verdict = !answered || correct == 'equal'
        ? null
        : sideKey == correct
            ? true
            : selected
                ? false
                : null;

    return Expanded(
      child: GestureDetector(
        onTap: isEqualMode ? null : () => _handleSideSelection(sideKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ToneFrame(
            index: 0,
            verdict: verdict,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _countableObjects(objects, sizeForCount: sizeForCount),
                ),
                const SizedBox(height: 6),
                // The count is not printed here.
                //
                // It used to sit under each side as a numeral, which answered
                // the question outright: "which is more" needs no counting once
                // 3 and 1 are written on the board. Reading the pictures is the
                // whole exercise, and the space the badge took is space the
                // pictures needed on a small phone.
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ToneFrame.inkFor(0, verdict: verdict))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Same number?" is answered Yes or No — on the white 3D buttons, with a
  /// green tick and a red cross to say which is which.
  Widget _yesNoButton(bool yes) {
    final loc = AppLocalizations.of(context)!;
    return Pressable(
      onTap: () => _handleEqualChoice(yes),
      child: SizedBox(
        height: 79,
        child: ToneFrame(
          index: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(yes ? LucideIcons.circle_check : LucideIcons.circle_x,
                  color:
                      yes ? const Color(0xFF2E9E3E) : const Color(0xFFE5484D),
                  size: 30),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    yes ? loc.yesAnswer : loc.noAnswer,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: ToneFrame.inkFor(0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Game 6: Number puzzle ────────────────────────────────────────────────────

  Widget _puzzleTile(int n, {bool floating = false}) =>
      _chunkyNumber(n, 74, 34);

  Widget _buildGame6() {
    final game = _currentGame;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          _questionText(AppLocalizations.of(context)!
              .arrange(game['sequence'] as String)),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.putNumbersInOrder,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // The boxes. Each one is its own drop target, so the child decides
          // which number belongs where — that choice is the whole question.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_puzzleSlots.length, (i) {
              final value = _puzzleSlots[i];
              final filled = value != null;

              return DragTarget<int>(
                onWillAcceptWithDetails: (_) => !_isPuzzleSolved,
                onAcceptWithDetails: (d) => _dropPuzzleTile(d.data, i),
                builder: (_, candidate, __) {
                  final hovering = candidate.isNotEmpty;
                  return GestureDetector(
                    // Tapping a filled box takes the number back out, so a
                    // change of mind costs one tap instead of a second drag.
                    onTap: () => _clearPuzzleSlot(i),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: hovering ? 1.12 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 78,
                        height: 78,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: _isPuzzleSolved
                              ? Colors.green.withOpacity(0.14)
                              : hovering
                                  ? AppColors.primary.withOpacity(0.20)
                                  : filled
                                      ? AppColors.primary.withOpacity(0.10)
                                      : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isPuzzleSolved
                                ? Colors.green
                                : (hovering || filled)
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                        // An empty box stays empty. It used to carry its own
                        // position number in grey, which a child reads as an
                        // answer already sitting in the box.
                        child: filled
                            ? Center(
                                child: Text(
                                  '$value',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: _isPuzzleSolved
                                        ? Colors.green
                                        : AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 28),

          // The tiles waiting to be dragged up into the boxes.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            // Only the numbers still waiting. A tile that has been placed is
            // gone from here entirely — no faded ghost of it left behind, and
            // none while it is being dragged either. The number is either in
            // a box or in the child's hand, never in two places at once.
            children:
                _puzzleNumbers.where((n) => !_puzzleSlots.contains(n)).map((n) {
              if (_isPuzzleSolved) return _puzzleTile(n);
              // Tapping fills the first empty box, left to right — the order
              // a child fills them in anyway. Dragging still puts a number in
              // any box they choose.
              return GestureDetector(
                onTap: () => _tapPuzzleTile(n),
                child: Draggable<int>(
                  data: n,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _puzzleTile(n, floating: true),
                  ),
                  // Holds the gap open so the other tiles do not jump around
                  // mid-drag, but shows nothing at all.
                  childWhenDragging: const SizedBox(width: 74, height: 79),
                  child: _puzzleTile(n),
                ),
              );
            }).toList(),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ─── Game 7: Missing number ───────────────────────────────────────────────────

  Widget _buildGame7() {
    final game = _game7Levels[_currentGameIndex % _game7Levels.length];
    final sequence = game['sequence'] as List<dynamic>;
    final answers = game['answers'] as List<dynamic>;
    final correct = game['correct'] as int;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          _questionText(AppLocalizations.of(context)!.whatIsMissingNumber),
          const SizedBox(height: 12),
          _gameCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: sequence.map((item) {
                    final isBlank = item == null;
                    return Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isBlank
                            ? (_selectedAnswer != null
                                ? AppColors.primary.withOpacity(0.15)
                                : Colors.grey.shade100)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBlank
                              ? (_selectedAnswer != null
                                  ? AppColors.primary
                                  : Colors.grey.shade400)
                              : AppColors.primary.withOpacity(0.3),
                          width: isBlank ? 2.0 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isBlank
                            ? Text(
                                _selectedAnswer?.toString() ?? '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedAnswer != null
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                              )
                            : Text(
                                (item as int).toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(AppLocalizations.of(context)!.selectCorrectAnswer,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: answers
                .map((a) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _mcqTile(a as int, correct: correct),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
