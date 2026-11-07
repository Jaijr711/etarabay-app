// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../widgets/fun_dialog.dart';
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
import '../widgets/module_cards.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../widgets/replay_dialog.dart';
import '../widgets/design_scale.dart';
import '../widgets/how_to_video.dart';

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

  /// Stars each finished round earned, by category then round, so a
  /// category picked up halfway is still rated on all three.
  final Map<int, Map<int, int>> _roundStars = {};

  /// True for exactly one open of a finished category — the one just
  /// confirmed through [_confirmReplayCategory] — so that one open shows the
  /// card grid instead of the completed view. Same pattern as Matematika's
  /// own `_replaying` flag.
  bool _replayingCategory = false;

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _starBurstController;
  late AnimationController _shakeController;

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
        // The picture is a carabao (kalabaw_mukha), so the card says so: it
        // was labelled a cow.
        {
          'emoji': '🐮',
          'label_en': 'Carabao',
          'label_tl': 'Kalabaw',
          'label_il': 'Nuang'
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
      'title_il': 'Bungbunga',
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
          'label_il': 'Saba'
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
      'title_il': 'Suksukog',
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
          'label_il': 'Sirkulo'
        },
        {
          'emoji': '🟦',
          'label_en': 'Square',
          'label_tl': 'Parisukat',
          'label_il': 'Kudrado'
        },
        {
          'emoji': '🔺',
          'label_en': 'Triangle',
          'label_tl': 'Tatsulok',
          'label_il': 'Trianggulo'
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

    _loadCompletedCategories().then((_) {
      // Left before the saved rounds were read: nothing to start.
      if (!mounted) return;
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
      final stars = <int, int>{};
      for (int round = 0; round < 3; round++) {
        final done = prefs.getBool('tandaan_cat_${cat}_round_$round') == true;
        rounds.add(done);
        if (!done) allDone = false;
        final s = prefs.getInt('tandaan_cat_${cat}_round_${round}_stars');
        if (s != null) stars[round] = s;
      }
      if (mounted) {
        setState(() {
          _categoryRoundProgress[cat] = rounds;
          _roundStars[cat] = stars;
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
    AudioManager.instance.resumeHomeMusicAfter(ModuleMusic.tandaan);
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
    _afterDelay(const Duration(milliseconds: 1400), () {
      setState(() => _showTimeUpOverlay = false);
      _advanceOrComplete();
    });
  }

  // ── Category switch ────────────────────────────────────────────────────────

  /// Goes up each time a category is opened or left. A card's or a
  /// verdict's delayed step only runs in the board it was given on
  /// ([_afterDelay]): one left running after back reached into the next
  /// category's cards by index, and marked its round done for that one.
  int _playSession = 0;

  void _afterDelay(Duration delay, VoidCallback then) {
    final session = _playSession;
    Future.delayed(delay, () {
      if (mounted && session == _playSession) then();
    });
  }

  /// Leaves the wall of cards for one category.
  ///
  /// Not [_switchCategory]: that one returns early when the category asked
  /// for is the one already selected, which is exactly what happens when a
  /// child comes back to the wall and taps the same card again.
  void _openCategory(int index) {
    _stopTimer();
    _playSession++;
    // Back where the child left off: rounds already done are not played
    // again, and their stars still count towards the category's rating.
    // Every category used to start at round one, so "Continue" undid them.
    final rounds = _categoryRoundProgress[index] ?? const <bool>[];
    final resumeAt = _replayingCategory ? 0 : rounds.indexWhere((r) => !r);
    final start = resumeAt < 0 ? 0 : resumeAt;
    setState(() {
      _playing = true;
      _selectedCategory = index;
      _currentRound = start;
      _categoryStars = 0;
      _categoryScore = 0;
      for (int r = 0; r < start; r++) {
        _categoryStars += _roundStars[index]?[r] ?? 3;
        _categoryScore += _pointsPerCorrect;
      }
    });
    // NOT reset here: build() reads _replayingCategory on the very next
    // frame to decide whether to show the card grid or the completed view,
    // and this function's own caller (_confirmReplayCategory) sets it right
    // before calling this. Clearing it here would make it read false again
    // before that frame ever draws — see _showCategoryComplete and
    // _backToPicker for where it actually gets cleared.
    if (_currentCategoryCompleted && !_replayingCategory) return;
    _initRound();
    // The first round ever played opens with the film of one.
    HowToVideo.claimFirstTime('tandaan', child: HowToVideo.childOf(context))
        .then((first) {
      if (first && mounted) _watchHowTo();
    });
  }

  /// Plays the film of a round, then lets the child look at the cards
  /// again: a look that ran out behind the video helped no one.
  Future<void> _watchHowTo() async {
    final session = _playSession;
    _previewTimer?.cancel();
    await HowToVideo.show(context, HowToVideo.assetFor(context, 'tandaan'));
    if (!mounted || !_playing || session != _playSession) return;
    if (_cards.every((c) => c.isMatched)) return;
    _firstFlippedIndex = null;
    _startPreview();
  }

  /// Back to the wall of cards, without leaving the module.
  void _backToPicker() {
    _stopTimer();
    _playSession++;
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
    _playSession++;
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
      _afterDelay(const Duration(milliseconds: 400), () {
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
      _afterDelay(const Duration(milliseconds: 800), () {
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
      (_roundStars[_selectedCategory] ??= {})[_currentRound] = earned;
    });
    _persistScore();
    unawaited(SharedPreferences.getInstance().then((p) => p.setInt(
        'tandaan_cat_${_selectedCategory}_round_${_currentRound}_stars',
        earned)));
    _starBurstController.forward(from: 0);

    // No bottom banner. The big card that pops up over the board already
    // says this, so the strip underneath repeated it word for word — twice
    // for the same event, the second time below where the child is looking.

    _afterDelay(const Duration(milliseconds: 1600), () {
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
    // Saved here, not through the provider, so nothing sent it up: a round
    // reached the cloud only if its category's stars happened to change.
    if (mounted) {
      unawaited(
          Provider.of<UserProvider>(context, listen: false).requestSync());
    }

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
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => FunDialog(
        child: FunMessage(
          picture:
              const FunCoin(icon: Icons.check_rounded, tone: Color(0xFF2E9E3E)),
          title: loc.finishedAlready,
          message: loc.doneAlready,
          buttons: [
            FunPillButton(
              label: loc.okButton,
              colors: FunColors.purple,
              onTap: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
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
        // On to the next category not yet finished, not simply the next one
        // along: that could be finished already, and opened on its "done"
        // page.
        primaryLabel: _nextCategoryToPlay() != null
            ? AppLocalizations.of(context)!.continueText
            : AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.pop(context);
          final next = _nextCategoryToPlay();
          if (next != null) {
            _openCategory(next);
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

  /// [UserProvider.progressVersion] when the rounds were last read.
  int? _seenProgressVersion;

  @override
  Widget build(BuildContext context) {
    // Rounds that arrive from the cloud after this screen opened show on the
    // wall of categories — never under a round being played.
    final version = context.select<UserProvider, int>((p) => p.progressVersion);
    _seenProgressVersion ??= version;
    if (version != _seenProgressVersion && !_playing) {
      _seenProgressVersion = version;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_playing) _loadCompletedCategories();
      });
    }
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
                  : DesignScale(child: _buildLevelPicker()),
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
        if (_playing) PanoorinPill(onTap: _watchHowTo),
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
  /// What is on each category's top card: an animal, a fruit, the shapes,
  /// and letters — the things its pairs are made of.
  static const List<String> _categoryPictures = [
    'assets/images/dog.webp',
    'assets/images/apple.webp',
    'assets/images/tandaan/hugis.webp',
    'assets/images/tandaan/titik.webp',
  ];

  Widget _buildLevelPicker() {
    final userProvider = Provider.of<UserProvider>(context);
    final loc = AppLocalizations.of(context)!;
    final progress = userProvider.getTandaanProgress();
    final perCategory =
        (progress['categoryStars'] as List<dynamic>?) ?? const [];
    final earned = (progress['stars'] as int?) ?? 0;
    const possible = UserProvider.tandaanStarCeiling;

    int starsOf(int i) =>
        i < perCategory.length ? (perCategory[i] as int? ?? 0) : 0;
    int next = -1;
    for (int i = 0; i < _categories.length; i++) {
      if (!_completedCategories.contains(i)) {
        next = i;
        break;
      }
    }

    Widget deck(int i) => StaggeredEntrance(
          index: i,
          delayMs: 55,
          durationMs: 380,
          child: _categoryDeck(i, starsOf(i), highlight: i == next),
        );

    return Column(
      children: [
        ModuleTally(
          picture: 'assets/images/star_gold.webp',
          done: earned,
          total: possible,
          label: (n) => loc.starsOfPossible(n, possible),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
            children: [
              for (int r = 0; r < _categories.length; r += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: deck(r)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: r + 1 < _categories.length
                            ? deck(r + 1)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// One category as a little pile of memory cards: two face down in its
  /// colour, and one face up on top showing what the pairs are of. The
  /// stars it has earned sit underneath.
  Widget _categoryDeck(int i, int stars, {required bool highlight}) {
    final color = _categories[i]['color'] as Color;
    final completed = _completedCategories.contains(i);

    return Pressable(
      onTap: () => completed ? _confirmReplayCategory(i) : _openCategory(i),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1 / 1.05,
            child: _MemoryDeck(
              color: color,
              picture: _categoryPictures[i % _categoryPictures.length],
              highlight: highlight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCategoryTitleLocalized(i),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          ModuleStars(count: stars, size: 20),
        ],
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

  /// After the one just finished, the next category still to do — looking
  /// on from it first, then from the start.
  int? _nextCategoryToPlay() {
    final n = _categories.length;
    for (int k = 1; k < n; k++) {
      final i = (_selectedCategory + k) % n;
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

  /// What the shapes and letters show on a card: 3D shapes from the same
  /// set as the medals and Settings, and toy letter blocks. Animals and fruit
  /// already come out of [ObjectPicture] as the app's own pictures.
  static const Map<String, String> _faceAssets = {
    '⚪': 'assets/images/tandaan/shape_circle.webp',
    '🟦': 'assets/images/tandaan/shape_square.webp',
    '🔺': 'assets/images/tandaan/shape_triangle.webp',
    '⭐': 'assets/images/tandaan/shape_star.webp',
    '❤': 'assets/images/tandaan/shape_heart.webp',
    '🔷': 'assets/images/tandaan/shape_diamond.webp',
    'Aa': 'assets/images/tandaan/letter_a.webp',
    'Bb': 'assets/images/tandaan/letter_b.webp',
    'Cc': 'assets/images/tandaan/letter_c.webp',
    'Dd': 'assets/images/tandaan/letter_d.webp',
    'Ee': 'assets/images/tandaan/letter_e.webp',
    'Ff': 'assets/images/tandaan/letter_f.webp',
  };

  /// The picture for a card's [emoji], with the variation selectors that
  /// make one emoji two strings taken off.
  static String? _faceAsset(String emoji) => _faceAssets[
      emoji.trim().replaceAll('\uFE0F', '').replaceAll('\uFE0E', '')];

  /// One card, drawn to fill the [cell] the grid worked out for it.
  ///
  /// The picture is sized from the cell, never shrunk into a fixed box: a
  /// bigger card has to mean a bigger picture to a child telling a dog from a
  /// carabao. A wrong pair shakes before it turns back.
  Widget _buildCard(int index, _CardData card, double cell) {
    final color = _currentCategory['color'] as Color;
    final art = cell * .6;
    final asset = _faceAsset(card.emoji);
    final picture = asset != null
        ? Image.asset(asset,
            width: art,
            height: art,
            fit: BoxFit.contain,
            excludeFromSemantics: true)
        : ObjectPicture(emoji: card.emoji, size: art);
    final wrong = card.isFlipped && !card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (_, child) {
          final v = wrong ? _shakeController.value : 0.0;
          return Transform.translate(
            offset: Offset(sin(v * pi * 6) * 5 * (1 - v), 0),
            child: child,
          );
        },
        child: _MemoryCard(
          color: color,
          picture: picture,
          label: card.label,
          faceUp: card.isFlipped || card.isMatched,
          matched: card.isMatched,
          size: cell,
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

/// Two cards face down, fanned, and one face up on top — the look of a
/// memory game before it starts.
class _MemoryDeck extends StatelessWidget {
  final Color color;
  final String picture;
  final bool highlight;

  const _MemoryDeck({
    required this.color,
    required this.picture,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final cardW = w * 0.8, cardH = h * 0.88;
      Widget card(
          {required Widget child,
          Color? fill,
          double turns = 0,
          double shift = 0,
          bool ring = false}) {
        final radius = BorderRadius.circular(16);
        return Positioned(
          left: w * 0.1,
          top: h * 0.06,
          width: cardW,
          height: cardH,
          child: Transform.translate(
            offset: Offset(cardW * shift, 0),
            child: Transform.rotate(
              angle: turns,
              child: Container(
                decoration: BoxDecoration(
                  color: fill ?? Colors.white,
                  borderRadius: radius,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF282850).withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                foregroundDecoration: ring
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: color, width: 3),
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
              ),
            ),
          ),
        );
      }

      final back = Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _CardDots()),
          Center(
            child: Text(
              '?',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: cardW * 0.26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
      return Stack(
        clipBehavior: Clip.none,
        children: [
          card(child: back, fill: color, turns: -0.157, shift: -0.08),
          card(child: back, fill: color, turns: 0.122, shift: 0.08),
          card(
            ring: highlight,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.72,
                heightFactor: 0.72,
                child: Image.asset(picture,
                    fit: BoxFit.contain, excludeFromSemantics: true),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// The dotted back of a memory card.
class _CardDots extends CustomPainter {
  const _CardDots();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.35);
    for (double y = 7; y < size.height; y += 14) {
      for (double x = 7; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CardDots old) => false;
}

/// One memory card, drawn as a thick 3D card that really turns over.
///
/// Chosen from the preview (B): the back is the category's colour with candy
/// dots, a dashed rim and Tarabay peeking up from the bottom beside a "?";
/// the face is white with a coloured rim, the picture large, and its name on
/// a pill. A card has a solid edge under it, so it reads as something to pick
/// up, and turning it is a real half-turn, not a fade. A found pair goes
/// green, pops, gets a tick and throws a few stars.
class _MemoryCard extends StatelessWidget {
  final Color color;
  final Widget picture;
  final String label;
  final bool faceUp;
  final bool matched;
  final double size;

  const _MemoryCard({
    required this.color,
    required this.picture,
    required this.label,
    required this.faceUp,
    required this.matched,
    required this.size,
  });

  static const Color _green = Color(0xFF22A559);
  static const Color _greenEdge = Color(0xFF178A45);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final card = TweenAnimationBuilder<double>(
      tween: Tween(end: faceUp ? 1 : 0),
      duration: Duration(milliseconds: still ? 0 : 550),
      curve: const Cubic(.3, 1.35, .5, 1),
      builder: (_, t, __) {
        final angle = t * pi;
        final front = angle > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(angle),
          child: front
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: _front(),
                )
              : _back(),
        );
      },
    );

    // A found pair pops once, gets its tick, and throws six little stars.
    return TweenAnimationBuilder<double>(
      key: ValueKey(matched),
      tween: Tween(begin: 0, end: matched ? 1 : 0),
      duration: Duration(milliseconds: still ? 0 : 800),
      builder: (_, v, child) => Transform.scale(
        scale: 1 + .1 * sin(pi * (v * 1.6).clamp(0.0, 1.0)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: child!),
            if (matched)
              Positioned(
                right: -6,
                top: -6,
                child: Transform.scale(
                  scale: Curves.elasticOut.transform((v * 2).clamp(0.0, 1.0)),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: _greenEdge, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 15, color: Colors.white),
                  ),
                ),
              ),
            if (matched && v > 0 && v < 1)
              for (int k = 0; k < 6; k++)
                Positioned.fill(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(cos(k / 6 * 2 * pi) * size * .5 * v,
                          sin(k / 6 * 2 * pi) * size * .5 * v),
                      child: Opacity(
                        opacity: 1 - v,
                        child: const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFFFC531)),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
      child: card,
    );
  }

  double get _radius => (size * .2).clamp(14.0, 26.0);

  List<BoxShadow> _thickness(Color edge, {bool glow = false}) => [
        BoxShadow(color: edge, offset: const Offset(0, 6)),
        if (glow) BoxShadow(color: _green.withOpacity(.22), spreadRadius: 4),
        BoxShadow(
          color: const Color(0xFF1E1E3C).withOpacity(.18),
          blurRadius: 16,
          offset: const Offset(0, 12),
        ),
      ];

  Widget _back() {
    final deep = Color.lerp(color, Colors.black, .3)!;
    final r = BorderRadius.circular(_radius);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: r,
        boxShadow: _thickness(deep),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _CandyDots()),
            Padding(
              padding: EdgeInsets.all(size * .06),
              child: CustomPaint(painter: _DashedRim(_radius * .75)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -size * .06,
              child: Center(
                child: Image.asset(
                  'assets/images/mascot_wave.webp',
                  width: size * .78,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Positioned(
              right: size * .09,
              top: size * .08,
              child: Container(
                width: size * .3,
                height: size * .3,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: deep, offset: const Offset(0, 3))
                  ],
                ),
                child: Text(
                  '?',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: size * .18,
                    height: 1,
                    color: deep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The rim and name pill in the category's colour, deepened when that
  /// colour is pale: white letters on the mint of Shapes could not be read.
  Color get _strong => color.computeLuminance() > .45
      ? Color.lerp(color, Colors.black, .3)!
      : color;

  Widget _front() {
    final rim = matched ? _green : _strong;
    final edge = matched ? _greenEdge : Color.lerp(color, Colors.black, .32)!;
    return Container(
      padding: EdgeInsets.all(size * .06),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.2),
          radius: .9,
          colors: [
            Colors.white,
            Colors.white,
            Color.lerp(color, Colors.white, .82)!
          ],
          stops: const [0, .55, 1],
        ),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: rim, width: 4),
        boxShadow: _thickness(edge, glow: matched),
      ),
      child: Column(
        children: [
          Expanded(child: Center(child: picture)),
          const SizedBox(height: 3),
          Container(
            padding: EdgeInsets.symmetric(horizontal: size * .09, vertical: 2),
            decoration: BoxDecoration(
              color: rim,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: (size * .11).clamp(10.0, 18.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White candy dots on a card's back, two sizes on offset rows.
class _CandyDots extends CustomPainter {
  const _CandyDots();

  @override
  void paint(Canvas canvas, Size size) {
    final big = Paint()..color = Colors.white.withOpacity(.3);
    final small = Paint()..color = Colors.white.withOpacity(.18);
    for (double y = 0; y < size.height + 30; y += 30) {
      for (double x = 0; x < size.width + 30; x += 30) {
        canvas.drawCircle(Offset(x, y), 6, big);
        canvas.drawCircle(Offset(x + 15, y + 15), 4, small);
      }
    }
  }

  @override
  bool shouldRepaint(_CandyDots old) => false;
}

/// The dashed line just inside a card's back.
class _DashedRim extends CustomPainter {
  final double radius;
  const _DashedRim(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRim old) => old.radius != radius;
}
