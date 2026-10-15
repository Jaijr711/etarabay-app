// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/object_picture.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/success_modal.dart';
import '../widgets/pressable.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/star_tally.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/word_fit.dart';
import '../widgets/replay_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TANDAAN MO! — Memory / Matching Game
// ─────────────────────────────────────────────────────────────────────────────

class TandaanScreen extends StatefulWidget {
  const TandaanScreen({super.key});

  @override
  State<TandaanScreen> createState() => _TandaanScreenState();
}

class _CardData {
  final int id;
  final String emoji;
  final String label;
  bool isFlipped = false;
  bool isMatched = false;

  _CardData({
    required this.id,
    required this.emoji,
    required this.label,
  });
}

class _TandaanScreenState extends State<TandaanScreen>
    with TickerProviderStateMixin {
  // ── Navigation ─────────────────────────────────────────────────────────────
  int _selectedCategory = 0;
  int _currentRound = 0;

  /// Whether the child has already been told how this game works.
  ///
  /// The instruction is the same sentence for every round and every category,
  /// and it was rebuilt above the grid every time. Once is what it is worth;
  /// after that it is a hundred pixels taken from the cards. Reset each visit,
  /// so a child coming back tomorrow still gets the reminder.
  bool _instructionSeen = false;

  // ── Scoring ──────────────────────────────────────────────────────────────

  /// Points banked in the category currently being played, reset when the
  /// child switches or restarts one. The running module totals live in
  /// SharedPreferences under [_totalStarsKey] and [_totalScoreKey], where the
  /// parents' report reads them; this screen only ever shows the category the
  /// child just finished.
  int _categoryScore = 0;

  int _categoryStars = 0;
  int _wrongAttempts = 0;

  // ── Timer ────────────────────────────────────────────────────────────────
  /// No countdown in Tandaan.
  ///
  /// This is a memory game, and a clock punishes the one thing it measures:
  /// stopping to remember where the pair was. A child who hurries here is
  /// guessing, which is the opposite of the skill.
  ///
  /// Left behind a flag for the same reason as Matematika's.
  static const bool _timerEnabled = false;

  int _secondsLeft = 60;
  Timer? _timer;

  // ── Feedback ─────────────────────────────────────────────────────────────
  final String _feedbackMessage = '';
  final Color _feedbackColor = Colors.transparent;
  bool _showCorrectOverlay = false;
  bool _showTimeUpOverlay = false;

  // ── The look ─────────────────────────────────────────────────────────────
  //
  // Every round used to begin with the board face down, so the child's first
  // move was a blind guess and usually the second one too. They were not
  // remembering anything; they were turning cards over until something
  // happened. The board opens face up now, for long enough to take in.

  /// True while the cards are face up and the round has not started.
  bool _previewing = false;
  int _previewMsLeft = 0;
  int _previewMsTotal = 0;
  Timer? _previewTimer;

  /// How long the cards stay face up, taken from how many there are.
  ///
  /// A child cannot take in ten cards in the time it takes to take in six, so
  /// a fixed number would be too long for the first round and too short for
  /// the last. Six cards get about six seconds, ten get about nine.
  Duration get _previewDuration =>
      Duration(milliseconds: 2000 + _cards.length * 700);

  // ── Card state ───────────────────────────────────────────────────────────
  List<_CardData> _cards = [];
  int? _firstFlippedIndex;
  bool _isProcessing = false;

  // ── Completion tracking ──────────────────────────────────────────────────
  final Set<int> _completedCategories = {};

  /// False while the child is choosing a category, true while they are in one.
  bool _playing = false;
  final Map<int, List<bool>> _categoryRoundProgress = {};

  /// True for exactly one open of a finished category — the one just
  /// confirmed through [_confirmReplayCategory] — so that one open shows the
  /// card grid instead of the completed view. Same pattern as Matematika's
  /// own `_replaying` flag.
  bool _replayingCategory = false;

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _starBurstController;
  late AnimationController _shakeController;
  late AnimationController _timerPulseController;

  // ── Category data ────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = const [
    {
      'title_en': 'Animals',
      'title_tl': 'Hayop',
      'title_il': 'Ayup',
      'color': AppColors.animals,
      'pairs': [
        {
          'emoji': '🐶',
          'label_en': 'Dog',
          'label_tl': 'Aso',
          'label_il': 'Aso'
        },
        {
          'emoji': '🐱',
          'label_en': 'Cat',
          'label_tl': 'Pusa',
          'label_il': 'Pusa'
        },
        {
          'emoji': '🐮',
          'label_en': 'Cow',
          'label_tl': 'Baka',
          'label_il': 'Baka'
        },
        {
          'emoji': '🐷',
          'label_en': 'Pig',
          'label_tl': 'Baboy',
          'label_il': 'Baboy'
        },
        {
          'emoji': '🐔',
          'label_en': 'Chicken',
          'label_tl': 'Manok',
          'label_il': 'Manok'
        },
        {
          'emoji': '🐰',
          'label_en': 'Rabbit',
          'label_tl': 'Kuneho',
          'label_il': 'Kuneho'
        },
      ],
    },
    {
      'title_en': 'Fruits',
      'title_tl': 'Prutas',
      'title_il': 'Prutas',
      'color': AppColors.colors,
      'pairs': [
        {
          'emoji': '🍎',
          'label_en': 'Apple',
          'label_tl': 'Mansanas',
          'label_il': 'Mansanas'
        },
        {
          'emoji': '🍌',
          'label_en': 'Banana',
          'label_tl': 'Saging',
          'label_il': 'Saging'
        },
        {
          'emoji': '🍇',
          'label_en': 'Grapes',
          'label_tl': 'Ubas',
          'label_il': 'Ubas'
        },
        {
          'emoji': '🍊',
          'label_en': 'Orange',
          'label_tl': 'Kahel',
          'label_il': 'Kahel'
        },
        {
          'emoji': '🍓',
          'label_en': 'Strawberry',
          'label_tl': 'Presa',
          'label_il': 'Presa'
        },
        {
          'emoji': '🍍',
          'label_en': 'Pineapple',
          'label_tl': 'Pinya',
          'label_il': 'Pinya'
        },
      ],
    },
    {
      'title_en': 'Shapes',
      'title_tl': 'Hugis',
      'title_il': 'Hugis',
      'color': AppColors.shapes,
      'pairs': [
        {
          // Not '🔴' — that emoji is reserved for the colour red in Ang
          // Aking Sarili's colours pairs (see ObjectPicture._fileNames), and
          // reusing it here drew that colour's paint-bucket picture where a
          // plain circle belongs. '⚪' draws as an actual circle instead
          // (see ShapeGlyph).
          'emoji': '⚪',
          'label_en': 'Circle',
          'label_tl': 'Bilog',
          'label_il': 'Bilog'
        },
        {
          'emoji': '🟦',
          'label_en': 'Square',
          'label_tl': 'Parisukat',
          'label_il': 'Parisukat'
        },
        {
          'emoji': '🔺',
          'label_en': 'Triangle',
          'label_tl': 'Tatsulok',
          'label_il': 'Tatsulok'
        },
        {
          'emoji': '⭐',
          'label_en': 'Star',
          'label_tl': 'Bituin',
          'label_il': 'Bituen'
        },
        {
          'emoji': '❤️',
          'label_en': 'Heart',
          'label_tl': 'Puso',
          'label_il': 'Puso'
        },
        {
          'emoji': '🔷',
          'label_en': 'Diamond',
          'label_tl': 'Diamante',
          'label_il': 'Diamante'
        },
      ],
    },
    {
      'title_en': 'Letters',
      'title_tl': 'Titik',
      'title_il': 'Letra',
      'color': AppColors.alphabet,
      'pairs': [
        {
          'emoji': 'Aa',
          'label_en': 'A a',
          'label_tl': 'A a',
          'label_il': 'A a'
        },
        {
          'emoji': 'Bb',
          'label_en': 'B b',
          'label_tl': 'B b',
          'label_il': 'B b'
        },
        {
          'emoji': 'Cc',
          'label_en': 'C c',
          'label_tl': 'C c',
          'label_il': 'C c'
        },
        {
          'emoji': 'Dd',
          'label_en': 'D d',
          'label_tl': 'D d',
          'label_il': 'D d'
        },
        {
          'emoji': 'Ee',
          'label_en': 'E e',
          'label_tl': 'E e',
          'label_il': 'E e'
        },
        {
          'emoji': 'Ff',
          'label_en': 'F f',
          'label_tl': 'F f',
          'label_il': 'F f'
        },
      ],
    },
  ];

  // Rounds per category: pair count for each round
  final List<List<int>> _roundConfigs = const [
    [3, 4, 5], // Animals: 3 pairs, 4 pairs, 5 pairs
    [3, 4, 5], // Fruits
    [3, 4, 5], // Shapes
    [3, 4, 5], // Letters
  ];

  List<IconData> get _categoryIcons => const [
        LucideIcons.paw_print,
        LucideIcons.coffee,
        LucideIcons.shapes,
        LucideIcons.whole_word,
      ];

  // ── Getters ──────────────────────────────────────────────────────────────

  Map<String, dynamic> get _currentCategory => _categories[_selectedCategory];
  int get _currentPairCount => _roundConfigs[_selectedCategory][_currentRound];
  int get _totalRounds => _roundConfigs[_selectedCategory].length;
  bool get _allCategoriesCompleted =>
      _completedCategories.length == _categories.length;

  bool get _currentCategoryCompleted =>
      _completedCategories.contains(_selectedCategory);

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playModuleMusic(ModuleMusic.tandaan);
    _starBurstController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _timerPulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _loadCompletedCategories().then((_) {
      if (!_currentCategoryCompleted) {
        _initRound();
        _startTimer();
      }
    });
  }

  Future<void> _loadCompletedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    int firstUncompleted = -1; // -1 means not found yet

    for (int cat = 0; cat < _categories.length; cat++) {
      bool allDone = true;
      final rounds = <bool>[];
      for (int round = 0; round < 3; round++) {
        final done = prefs.getBool('tandaan_cat_${cat}_round_$round') == true;
        rounds.add(done);
        if (!done) allDone = false;
      }
      if (mounted) {
        setState(() {
          _categoryRoundProgress[cat] = rounds;
          if (allDone) _completedCategories.add(cat);
        });
      }
      if (!allDone && firstUncompleted == -1) {
        firstUncompleted = cat; // First incomplete category found
      }
    }

    // If all done, land on the last category; otherwise on first uncompleted
    final target =
        firstUncompleted == -1 ? _categories.length - 1 : firstUncompleted;

    if (mounted && target != _selectedCategory) {
      setState(() {
        _selectedCategory = target;
        _currentRound = 0;
        _categoryStars = 0;
        _categoryScore = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _previewTimer?.cancel();
    _starBurstController.dispose();
    _shakeController.dispose();
    _timerPulseController.dispose();
    AudioManager.instance.resumeHomeMusic();
    super.dispose();
  }

  // ── Game init ────────────────────────────────────────────────────────────

  void _initRound() {
    final cat = _currentCategory;
    final allPairs = List<Map<String, dynamic>>.from(cat['pairs'] as List);
    allPairs.shuffle(Random());
    final selectedPairs = allPairs.take(_currentPairCount).toList();

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    // Same fix as _getCategoryTitleLocalized: the real codes are 'ilo'/'fil'.
    final labelKey = lang.currentLanguage == 'ilo'
        ? 'label_il'
        : (lang.currentLanguage == 'fil' ? 'label_tl' : 'label_en');

    final List<_CardData> newCards = [];
    for (int i = 0; i < selectedPairs.length; i++) {
      final pair = selectedPairs[i];
      final emoji = pair['emoji'] as String;
      final label = pair[labelKey] as String;
      // Add each pair twice
      newCards.add(_CardData(id: i, emoji: emoji, label: label));
      newCards.add(_CardData(id: i, emoji: emoji, label: label));
    }
    newCards.shuffle(Random());

    setState(() {
      _cards = newCards;
      _firstFlippedIndex = null;
      _isProcessing = false;
      _wrongAttempts = 0;
    });
    _startPreview();
  }

  /// Turns the whole board face up and counts the look down.
  ///
  /// The round's own timer, if it is ever switched back on, does not start
  /// until this finishes — looking is not part of the time the child is being
  /// measured on.
  void _startPreview() {
    _previewTimer?.cancel();
    _stopTimer();
    final total = _previewDuration.inMilliseconds;
    setState(() {
      for (final c in _cards) {
        c.isFlipped = true;
      }
      _previewing = true;
      _previewMsTotal = total;
      _previewMsLeft = total;
    });
    _previewTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_previewMsLeft <= 100) {
        t.cancel();
        _endPreview();
        return;
      }
      setState(() => _previewMsLeft -= 100);
    });
  }

  void _endPreview() {
    _previewTimer?.cancel();
    if (!mounted) return;
    setState(() {
      for (final c in _cards) {
        if (!c.isMatched) c.isFlipped = false;
      }
      _previewing = false;
      _previewMsLeft = 0;
    });
    if (_timerEnabled) _startTimer();
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    if (!_timerEnabled) return;
    _timer?.cancel();
    _secondsLeft = 30 + (_currentPairCount * 8);
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

  /// Running out of time moves on to the next round and keeps every star
  /// already earned. Sending a 3-to-5-year-old back to round one and wiping
  /// their stars punishes the slow, careful looking this game is meant to
  /// build.
  void _onTimeout() {
    // Its own signal, not the wrong-answer one — see matematika's _onTimeout.
    // The round earns no stars, but everything banked so far is kept.
    setState(() => _showTimeUpOverlay = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showTimeUpOverlay = false);
      _advanceOrComplete();
    });
  }

  // ── Category switch ────────────────────────────────────────────────────────

  /// Leaves the wall of cards for one category.
  ///
  /// Not [_switchCategory]: that one returns early when the category asked
  /// for is the one already selected, which is exactly what happens when a
  /// child comes back to the wall and taps the same card again.
  void _openCategory(int index) {
    _stopTimer();
    setState(() {
      _playing = true;
      _selectedCategory = index;
      _currentRound = 0;
      _categoryStars = 0;
      _categoryScore = 0;
    });
    // NOT reset here: build() reads _replayingCategory on the very next
    // frame to decide whether to show the card grid or the completed view,
    // and this function's own caller (_confirmReplayCategory) sets it right
    // before calling this. Clearing it here would make it read false again
    // before that frame ever draws — see _showCategoryComplete and
    // _backToPicker for where it actually gets cleared.
    if (_currentCategoryCompleted && !_replayingCategory) return;
    _initRound();
  }

  /// Back to the wall of cards, without leaving the module.
  void _backToPicker() {
    _stopTimer();
    setState(() {
      _playing = false;
      _showCorrectOverlay = false;
      _showTimeUpOverlay = false;
      _replayingCategory = false;
    });
  }

  void _switchCategory(int index) {
    if (_selectedCategory == index) return;
    _stopTimer();
    setState(() {
      _selectedCategory = index;
      _currentRound = 0;
      _categoryStars = 0;
      _categoryScore = 0;
    });
    // A completed category is locked — show its "done" state, no replay.
    if (_currentCategoryCompleted) return;
    // _initRound shows the board first; the round timer starts with the round.
    _initRound();
  }

  // ── Card tap logic ───────────────────────────────────────────────────────

  void _onCardTap(int index) {
    // Every category done is exactly the state a replay starts from — this
    // guard used to fire on the very first tap of a replay too, since it
    // never knew the difference, and silently turned "Ulitin" into a button
    // that reopened the same finished screen it was tapped from.
    if (_allCategoriesCompleted && !_replayingCategory) {
      _showAlreadyFinishedDialog();
      return;
    }
    // Still looking. A child this age taps the instant anything appears, and
    // letting that tap end the look would cut short the one part of the round
    // that actually helps them.
    if (_previewing) return;
    if (_isProcessing) return;
    if (_cards[index].isMatched) return;
    if (_cards[index].isFlipped) return;

    HapticFeedback.lightImpact();

    setState(() => _cards[index].isFlipped = true);

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
      return;
    }

    final first = _firstFlippedIndex!;
    final second = index;

    if (_cards[first].id == _cards[second].id) {
      // Match!
      _isProcessing = true;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _cards[first].isMatched = true;
          _cards[second].isMatched = true;
          _firstFlippedIndex = null;
          _isProcessing = false;
        });
        _checkRoundComplete();
      });
    } else {
      // No match
      _isProcessing = true;
      _wrongAttempts++;
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _cards[first].isFlipped = false;
          _cards[second].isFlipped = false;
          _firstFlippedIndex = null;
          _isProcessing = false;
        });
      });
    }
  }

  void _checkRoundComplete() {
    final allMatched = _cards.every((c) => c.isMatched);
    if (!allMatched) return;

    _stopTimer();
    final earned = _starsFromWrong;
    setState(() {
      _categoryStars += earned;
      _categoryScore += _pointsPerCorrect;
      _showCorrectOverlay = true;
    });
    _persistScore();
    _starBurstController.forward(from: 0);

    // No bottom banner. The big card that pops up over the board already
    // says this, so the strip underneath repeated it word for word — twice
    // for the same event, the second time below where the child is looking.

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showCorrectOverlay = false);
      _advanceOrComplete();
    });
  }

  /// Points for a correct answer, whatever it took to get there.
  ///
  /// A flat rate on purpose. The old 10-per-star scale paid 30 for a clean
  /// answer and 10 for a struggled one, which put totals in the hundreds —
  /// numbers a three-to-five-year-old cannot read, let alone judge. How well
  /// the answer went is what the 1-to-3 star rating is for; the points just
  /// count correct answers.
  static const int _pointsPerCorrect = 10;

  int get _starsFromWrong {
    if (_wrongAttempts == 0) return 3;
    if (_wrongAttempts <= 2) return 2;
    return 1;
  }

  void _advanceOrComplete() async {
    // The round the child just finished is recorded either way — they did the
    // work — but nothing is put on the screen if they have already gone back
    // to the wall of categories.
    final stillPlaying = _playing;
    // Record the round that was just finished so per-round progress (and the
    // Lessons screen counter) actually advances instead of only saving the
    // very last round on category completion.
    await _markRoundDone(_currentRound);
    if (!stillPlaying || !_playing) return;
    if (_currentRound < _totalRounds - 1) {
      setState(() {
        _currentRound++;
        // They have played a whole round now; they know what to do.
        _instructionSeen = true;
      });
      _initRound();
    } else {
      _showCategoryComplete();
    }
  }

  /// Persist a single completed round and refresh the local progress state.
  Future<void> _markRoundDone(int round) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tandaan_cat_${_selectedCategory}_round_$round', true);

    if (mounted) {
      setState(() {
        _categoryRoundProgress[_selectedCategory] ??= [false, false, false];
        _categoryRoundProgress[_selectedCategory]![round] = true;
      });
    }

    // Mark the whole category complete once all three rounds are done.
    bool allDone = true;
    for (int r = 0; r < 3; r++) {
      if (prefs.getBool('tandaan_cat_${_selectedCategory}_round_$r') != true) {
        allDone = false;
        break;
      }
    }
    if (allDone && mounted) {
      setState(() => _completedCategories.add(_selectedCategory));
    }
  }

  /// Offers to replay a finished category — same choice Matematika gives on
  /// a finished level, and the same trade: a replay swaps this category's
  /// banked rating for whatever the new run earns (see
  /// [_awardCategoryStars]), it does not add to it.
  Future<void> _confirmReplayCategory(int i) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final stars = prefs.getInt('tandaan_cat_${i}_stars') ?? 0;

    showReplayDialog(
      context,
      stars: stars,
      onRepeat: () {
        _replayingCategory = true;
        _openCategory(i);
      },
    );
  }

  void _showAlreadyFinishedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.finishedAlready,
            textAlign: TextAlign.center),
        content: Text(AppLocalizations.of(context)!.doneAlready,
            textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.okButton),
          )
        ],
      ),
    );
  }

  void _showCategoryComplete() {
    // A round that finishes on a timer must not open its card over the wall
    // of categories the child has already gone back to.
    if (!_playing) return;
    _stopTimer();
    // This replay is done being played — cleared here, before the "what's
    // next" buttons on the modal below can act, so it does not leak into
    // whichever category the child opens after it (letting a later,
    // separately-completed category skip its own replay confirmation).
    _replayingCategory = false;
    final avgStars = _totalRounds == 0
        ? 1
        : (_categoryStars / _totalRounds).ceil().clamp(1, 3);

    _saveProgress();
    _awardCategoryStars(avgStars);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessModal(
        title: AppLocalizations.of(context)!.congratulations,
        subtitle: _getCategoryTitleLocalized(_selectedCategory),
        // This category's points, not the module's running total.
        score: _categoryScore,
        stars: avgStars,
        primaryLabel: _selectedCategory < _categories.length - 1
            ? AppLocalizations.of(context)!.continueText
            : AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.pop(context);
          if (_selectedCategory < _categories.length - 1) {
            _openCategory(_selectedCategory + 1);
          } else {
            // The last one: back to the wall, where the card the child has
            // just finished is now ticked. This used to leave the module.
            _backToPicker();
          }
        },
        secondaryLabel: AppLocalizations.of(context)!.back,
        onSecondaryTap: () {
          Navigator.pop(context);
          _backToPicker();
        },
        mainColor: _currentCategory['color'] as Color,
      ),
    );
  }

  /// Restores the star total the child has already banked, so reopening the
  /// module shows what they achieved instead of restarting from zero.
  static const String _totalStarsKey = 'tandaan_total_stars';
  static const String _totalScoreKey = 'tandaan_total_score';

  Future<void> _persistScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalScoreKey,
        (prefs.getInt(_totalScoreKey) ?? 0) + _pointsPerCorrect);
  }

  /// Awards [stars] — the rating shown on the category-complete screen — to
  /// the child's one star total, so the stars in the summary, the header here
  /// and the dashboard are all the same number. Replaying a category earns its
  /// rating again, because practising the same set is exactly what we want a
  /// young child to do.
  /// Banks the rating for a finished category.
  ///
  /// Same rule as the other modules: a category is worth one rating — the one
  /// from the run just finished — so replaying it swaps the old rating for the
  /// new one instead of stacking another on top.
  Future<void> _awardCategoryStars(int stars) async {
    if (stars <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'tandaan_cat_${_selectedCategory}_stars';
    final previous = prefs.getInt(key) ?? 0;
    final delta = stars - previous;
    await prefs.setInt(key, stars);
    await prefs.setInt(
        _totalStarsKey, (prefs.getInt(_totalStarsKey) ?? 0) + delta);
    if (!mounted) return;
    await Provider.of<UserProvider>(context, listen: false).adjustStars(delta);
  }

  /// Stars are banked per round in [_checkRoundComplete]; this only closes out
  /// the final round's progress record.
  Future<void> _saveProgress() async {
    await _markRoundDone(_currentRound);
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getCategoryTitleLocalized(int index) {
    final cat = _categories[index];
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    // The app's actual language codes are 'ilo' and 'fil' (see
    // LanguageProvider.languageCodes) — this checked 'il'/'tl', which never
    // matched, so a category title never came out as anything but English
    // regardless of the language the child had chosen.
    final key = lang.currentLanguage == 'ilo'
        ? 'title_il'
        : (lang.currentLanguage == 'fil' ? 'title_tl' : 'title_en');
    return cat[key] as String;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The phone's own back button, and the browser's. Inside a level it
      // means "leave the level", not "leave the module" — a child who taps it
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
            // Nothing under a feedback card takes a tap while it is up. The
            // same gate as Matematika and Ang Aking Sarili: the card here
            // stays for 1.6 seconds, and a child who keeps tapping through it
            // was flipping cards into the next round.
            AbsorbPointer(
              absorbing: _showCorrectOverlay || _showTimeUpOverlay,
              child: _playing
                  ? Column(
                      children: [
                        if (!(_currentCategoryCompleted && !_replayingCategory))
                          _buildProgressHeader(),
                        Expanded(
                          child:
                              (_currentCategoryCompleted && !_replayingCategory)
                                  ? _buildCompletedView()
                                  : _buildCardGrid(),
                        ),
                        _buildFeedbackBanner(),
                      ],
                    )
                  : _buildLevelPicker(),
            ),
            if (_playing && _showCorrectOverlay) _buildCorrectOverlay(),
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
        AppLocalizations.of(context)!.tandaanTitle,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// The four categories as cards, and nothing else on the screen.
  ///
  /// They used to be a strip pinned above the board for as long as the child
  /// played — a live control sitting directly over the cards they were trying
  /// to remember, on a screen where the whole game is "do not touch the wrong
  /// thing". It is a screen of its own now, which they leave to play and come
  /// back to when a category is finished.
  Widget _buildLevelPicker() {
    final userProvider = Provider.of<UserProvider>(context);
    final progress = userProvider.getTandaanProgress();
    final perCategory =
        (progress['categoryStars'] as List<dynamic>?) ?? const [];
    final earned = (progress['stars'] as int?) ?? 0;
    const possible = UserProvider.tandaanStarCeiling;

    int starsOf(int i) =>
        i < perCategory.length ? (perCategory[i] as int? ?? 0) : 0;

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
              childAspectRatio: 0.98,
            ),
            itemCount: _categories.length,
            // The wall assembles rather than appearing. Each card is a
            // beat behind the one before it, which walks a child's eye
            // across them instead of dropping seven at once.
            itemBuilder: (_, i) => StaggeredEntrance(
              index: i,
              delayMs: 55,
              durationMs: 380,
              child: _categoryCard(i, starsOf(i)),
            ),
          ),
        ),
      ],
    );
  }

  /// One category, in its own colour, with what the child took from it.
  Widget _categoryCard(int i, int stars) {
    final color = _categories[i]['color'] as Color;
    final completed = _completedCategories.contains(i);

    return Pressable(
      onTap: () => completed ? _confirmReplayCategory(i) : _openCategory(i),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_categoryIcons[i], color: Colors.white, size: 20),
                ),
                const Spacer(),
                if (completed)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 16, color: color),
                  ),
              ],
            ),
            const Spacer(),
            WordSafeText(
              _getCategoryTitleLocalized(i),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (n) {
                final got = n < stars;
                return Icon(
                  got ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 26,
                  color: got ? Colors.white : Colors.white.withOpacity(0.55),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final color = _currentCategory['color'] as Color;
    const lookColour = Color(0xFFF5A300);

    final progress = _previewing
        ? (_previewMsTotal == 0 ? 0.0 : _previewMsLeft / _previewMsTotal)
        : (_totalRounds == 0 ? 0.0 : (_currentRound + 1) / _totalRounds);
    final barColour = _previewing ? lookColour : color;
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
                      color:
                          (_previewing ? lookColour : color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        _previewing
                            ? LucideIcons.eye
                            : _categoryIcons[_selectedCategory],
                        color: _previewing ? lookColour : color,
                        size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _previewing
                        ? AppLocalizations.of(context)!.memoriseTheCards
                        : '${AppLocalizations.of(context)!.round} ${_currentRound + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _previewing ? lookColour : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentRound + 1} / $_totalRounds',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color),
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
                widthFactor: progress.clamp(0.0, 1.0),
                child: AnimatedContainer(
                  // No easing while the look drains — it ticks every tenth of
                  // a second and a 300ms animation would lag behind it.
                  duration: Duration(milliseconds: _previewing ? 0 : 300),
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [barColour, barColour.withOpacity(0.75)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: barColour.withOpacity(0.4),
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

  Widget _buildCardGrid() {
    if (_cards.isEmpty) return const Center(child: CircularProgressIndicator());

    final color = _currentCategory['color'] as Color;
    const spacing = 12.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Said once, at the start, and then out of the way.
          if (!_instructionSeen) ...[
            _buildInstructionCard(color),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Try every column count and keep whichever makes the card
                // biggest.
                //
                // The grid used to be fixed at two rows — 3x2, 4x2, 5x2 — and
                // two rows is the wrong shape for a portrait phone, where the
                // width runs out long before the height does. At ten cards it
                // divided about 310 usable pixels into five columns: a 62
                // pixel card, for a child who has to recognise a picture on
                // it. Three columns and four rows makes the same ten cards
                // roughly 110 across.
                double cell = 0;
                int crossAxisCount = 2;
                final most = _cards.length < 5 ? _cards.length : 5;
                for (int cols = 2; cols <= most; cols++) {
                  final rows = (_cards.length / cols).ceil();
                  final w =
                      (constraints.maxWidth - (cols - 1) * spacing) / cols;
                  final h =
                      (constraints.maxHeight - (rows - 1) * spacing) / rows;
                  final side = w < h ? w : h;
                  if (side > cell) {
                    cell = side;
                    crossAxisCount = cols;
                  }
                }
                final gridWidth =
                    cell * crossAxisCount + spacing * (crossAxisCount - 1);

                return Center(
                  child: SizedBox(
                    width: gridWidth,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return _buildCard(index, card, cell);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the current category is already fully completed — like the
  /// Matematika module, a finished tab stays done and cannot be replayed.
  Widget _buildCompletedView() {
    final color = _currentCategory['color'] as Color;
    final next = _nextUncompletedCategory();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.circle_check,
                  color: Colors.green, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              _getCategoryTitleLocalized(_selectedCategory),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.doneAlready,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.star_rounded,
                      color: Color(0xFFFFB800), size: 28),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (next != null)
              SizedBox(
                width: 220,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _switchCategory(next),
                  icon: const Icon(LucideIcons.arrow_right, size: 20),
                  label: Text(AppLocalizations.of(context)!.continueText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.party_popper,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.finishedAlready,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Always offered, whether or not there is a next category to
            // move on to — the same "already finished, want to try again?"
            // choice the picker wall's own tap gives, so a child does not
            // have to back out to the wall first. Same trade as there: a
            // replay swaps this category's rating rather than adding to it.
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => _confirmReplayCategory(_selectedCategory),
              icon: Icon(LucideIcons.rotate_ccw, size: 18, color: color),
              label: Text(AppLocalizations.of(context)!.ulitin,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  int? _nextUncompletedCategory() {
    for (int i = 0; i < _categories.length; i++) {
      if (!_completedCategories.contains(i)) return i;
    }
    return null;
  }

  Widget _buildInstructionCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.lightbulb, color: color, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.matchThePairs,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.flipCardsToMatch,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// One card, drawn to fill the [cell] the grid worked out for it.
  ///
  /// The face used to be built at a fixed 46-pixel picture over 12-pixel text
  /// inside a `FittedBox(scaleDown)` — and scaleDown only ever shrinks. A
  /// bigger card was therefore a bigger white square with the same small
  /// picture floating in it, which is not what bigger cards means to a child
  /// trying to tell a dog from a carabao.
  Widget _buildCard(int index, _CardData card, double cell) {
    final color = _currentCategory['color'] as Color;
    final isEmoji = card.emoji.length <= 2 && card.emoji != 'Aa';
    final showFront = card.isFlipped || card.isMatched;
    final art = (cell * 0.46).clamp(40.0, 110.0);
    final labelSize = (cell * 0.115).clamp(11.0, 20.0);

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutBack,
        decoration: BoxDecoration(
          gradient: showFront
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.78)],
                ),
          color: showFront
              ? (card.isMatched ? Colors.green.withOpacity(0.12) : Colors.white)
              : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: card.isMatched ? Colors.green : color.withOpacity(0.45),
            width: card.isMatched ? 4 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (card.isMatched ? Colors.green : color).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
              child: FadeTransition(
                opacity: anim,
                child: child,
              ),
            );
          },
          child: showFront
              ? Stack(
                  key: ValueKey('front_$index'),
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // The face of the card is the game here — a
                              // child is matching what they see, not reading
                              // the word under it. A drawn picture when one
                              // exists; the emoji until then.
                              isEmoji
                                  ? ObjectPicture(emoji: card.emoji, size: art)
                                  : Text(
                                      card.emoji,
                                      style: TextStyle(
                                        fontSize: art * 0.6,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                card.label,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (card.isMatched)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.check,
                              color: Colors.white, size: 15),
                        ),
                      ),
                  ],
                )
              : Container(
                  key: ValueKey('back_$index'),
                  alignment: Alignment.center,
                  child: Container(
                    width: (cell * 0.38).clamp(34.0, 88.0),
                    height: (cell * 0.38).clamp(34.0, 88.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: (cell * 0.24).clamp(20.0, 52.0),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCorrectOverlay() {
    return AnswerFeedback.correct(
        message: AppLocalizations.of(context)!.correct);
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
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 19,
        ),
      ),
    );
  }
}
