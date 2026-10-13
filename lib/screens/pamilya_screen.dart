import '../services/audio_source.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/pamilya_content.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/answer_tile.dart';
import '../widgets/object_picture.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/family_tree_picture.dart';
import '../widgets/home_house.dart';
import '../widgets/success_modal.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';
import '../widgets/pressable.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/star_tally.dart';
import 'dart:async';
import 'package:flutter_lucide/flutter_lucide.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BADGE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class FamilyBadge {
  final String emoji;
  String title;
  String description;
  final Color color;
  bool isEarned;

  FamilyBadge({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    this.isEarned = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PamilyaScreen extends StatefulWidget {
  const PamilyaScreen({super.key});

  @override
  State<PamilyaScreen> createState() => _PamilyaScreenState();
}

class _PamilyaScreenState extends State<PamilyaScreen>
    with TickerProviderStateMixin {
  // ── Navigation ─────────────────────────────────────────────────────────────
  int _selectedMainCategory = 0;

  /// False while the child is choosing a level, true while they are in one.
  bool _playing = false;
  int _selectedLevel = 0;
  int _currentGameIndex = 0;

  // ── Scoring ────────────────────────────────────────────────────────────────
  int _totalScore = 0;
  int _levelStars = 0;
  int _levelScore = 0;
  int _wrongAttempts = 0;

  // ── Timer ──────────────────────────────────────────────────────────────────
  int _secondsLeft = 60;
  Timer? _timer;

  /// No clock in "Ang Aking Sarili".
  ///
  /// This module asks a child what makes them happy, who lives in their
  /// house, what they do in the morning. Those are questions to think about,
  /// and a countdown turns thinking into hurrying — at three to five, a
  /// visible clock mostly teaches that being slow is being wrong. The other
  /// modules keep theirs: counting objects is a skill where a gentle time
  /// pressure is fair.
  ///
  /// Left as a flag rather than torn out, because every start is already
  /// guarded by it and the machinery is harmless while it is false — and if
  /// this module is ever wanted for older children, one word turns it back
  /// on.
  final bool _timerEnabled = false;

  // ── Feedback ───────────────────────────────────────────────────────────────
  bool _showCorrectOverlay = false;
  bool _showWrongOverlay = false;
  bool _showTimeUpOverlay = false;

  // ── Sarili states ──────────────────────────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  /// The tip currently shown in the middle of the board, or null.
  String? _tipMessage;
  Timer? _tipTimer;
  DateTime? _tipShownAt;
  VoidCallback? _afterTip;

  int? _selectedAboutMeAnswer;
  int? _selectedEmotionAnswer;
  int? _selectedRoutineAnswer;
  int? _selectedFoodIndex;
  int? _selectedColorIndex;
  int? _selectedGameIndex;
  int? _selectedAnimalIndex;

  // ── Pamilya states ─────────────────────────────────────────────────────────
  int? _selectedFamilyAnswer;
  int? _selectedRoleAnswer;
  int? _selectedActivityAnswer;
  bool _myHomeCompleted = false;
  int _homeChallengeIndex = 0;
  final Set<int> _matchedHomeItems = {};
  int? _selectedTreeQuizAnswer;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _starBurstController;
  late AnimationController _timerPulseController;
  late AnimationController _celebrationController;

  late AudioPlayer _audioPlayer;

  String get _currentLang =>
      Provider.of<LanguageProvider>(context, listen: false).currentLanguageCode;

  // ─────────────────────────────────────────────────────────────────────────
  //  DATA
  // ─────────────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _mainCategories =>
      PamilyaContent.getMainCategories(_currentLang);

  List<List<String>> get _categoryLevelTitles =>
      PamilyaContent.getCategoryLevelTitles(_currentLang);

  final List<List<IconData>> _categoryLevelIcons = [
    [LucideIcons.user, LucideIcons.smile, LucideIcons.clock, LucideIcons.heart],
    [
      LucideIcons.users,
      LucideIcons.briefcase,
      LucideIcons.party_popper,
      LucideIcons.workflow,
      LucideIcons.house
    ],
  ];

  // ── Sarili Level 1 ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _sariliLevel1Games =>
      PamilyaContent.getSariliLevel1Games(_currentLang);

  // ── Sarili Level 2: Emotions (full Ilocano) ────────────────────────────────
  List<Map<String, dynamic>> get _sariliLevel2Games =>
      PamilyaContent.getSariliLevel2Games(_currentLang);

  // ── Sarili Level 3: Daily Routines ─────────────────────────────────────────
  List<Map<String, dynamic>> get _sariliLevel3Games =>
      PamilyaContent.getSariliLevel3Games(_currentLang);

  // ── Sarili Level 4: Preferences ────────────────────────────────────────────
  List<Map<String, dynamic>> get _sariliLevel4Games =>
      PamilyaContent.getSariliLevel4Games(_currentLang);

  // ── Pamilya Level 1: Family Members ────────────────────────────────────────
  List<Map<String, dynamic>> get _pamilyaLevel1Games =>
      PamilyaContent.getPamilyaLevel1Games(_currentLang);

  // ── Pamilya Level 2: Family Roles ──────────────────────────────────────────
  List<Map<String, dynamic>> get _pamilyaLevel2Games =>
      PamilyaContent.getPamilyaLevel2Games(_currentLang);

  // ── Pamilya Level 3: Family Activities ─────────────────────────────────────
  List<Map<String, dynamic>> get _pamilyaLevel3Games =>
      PamilyaContent.getPamilyaLevel3Games(_currentLang);

  // ── Pamilya Level 4: Family Tree ───────────────────────────────────────────
  List<Map<String, dynamic>> get _pamilyaLevel4Games =>
      PamilyaContent.getPamilyaLevel4Games(_currentLang);

  // ── Pamilya Level 5: Our Home ──────────────────────────────────────────────
  List<Map<String, dynamic>> get _pamilyaLevel5Games =>
      PamilyaContent.getPamilyaLevel5Games(_currentLang);

  // ── Family Tree ────────────────────────────────────────────────────────────
  Map<String, dynamic> get _familyTreeData =>
      PamilyaContent.getFamilyTreeData(_currentLang);

  // ── My Home ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _homeRooms =>
      PamilyaContent.getHomeRooms(_currentLang);

  String _getMainCategoryTitle(int index) {
    if (index == 0) {
      return AppLocalizations.of(context)!.angAkingSarili.replaceAll('\n', ' ');
    }
    if (index == 1) {
      return AppLocalizations.of(context)!.atAkingPamilya.replaceAll('\n', ' ');
    }
    return '';
  }

  String _getLevelTitle(int catIndex, int lvlIndex) {
    if (catIndex == 0) {
      switch (lvlIndex) {
        case 0:
          return AppLocalizations.of(context)!.allAboutMe;
        case 1:
          return AppLocalizations.of(context)!.myEmotions;
        case 2:
          return AppLocalizations.of(context)!.dailyRoutines;
        case 3:
          return AppLocalizations.of(context)!.myPreferences;
      }
    } else {
      switch (lvlIndex) {
        case 0:
          return AppLocalizations.of(context)!.familyMembers;
        case 1:
          return AppLocalizations.of(context)!.familyRoles;
        case 2:
          return AppLocalizations.of(context)!.familyActivities;
        case 3:
          return AppLocalizations.of(context)!.familyTree;
        case 4:
          return AppLocalizations.of(context)!.myHome;
      }
    }
    return '';
  }

  String _getLevelSubTitle(int catIndex, int lvlIndex) {
    if (catIndex == 0) {
      switch (lvlIndex) {
        case 0:
          return AppLocalizations.of(context)!.aboutMeSubtitle;
        case 1:
          return AppLocalizations.of(context)!.myEmotionsSubtitle;
        case 2:
          return AppLocalizations.of(context)!.dailyRoutinesSubtitle;
        case 3:
          return AppLocalizations.of(context)!.myPreferencesSubtitle;
      }
    } else {
      switch (lvlIndex) {
        case 0:
          return AppLocalizations.of(context)!.familyMembersSubtitle;
        case 1:
          return AppLocalizations.of(context)!.familyRolesSubtitle;
        case 2:
          return AppLocalizations.of(context)!.familyActivitiesSubtitle;
        case 3:
          return AppLocalizations.of(context)!.familyTreeSubtitle;
        case 4:
          return AppLocalizations.of(context)!.myHomeSubtitle;
      }
    }
    return '';
  }

  String _getGameString(Map<String, dynamic> game, String key) {
    final id = game['id'] as String;
    if (key == 'question') {
      switch (id) {
        case 'about_name':
          return AppLocalizations.of(context)!.whatIsYourName;
        case 'about_age':
          return AppLocalizations.of(context)!.howOldAreYou;
        case 'about_gender':
          return AppLocalizations.of(context)!.areYouBoyOrGirl;
      }
    } else if (key == 'description') {
      switch (id) {
        case 'about_name':
          return AppLocalizations.of(context)!.whatIsYourNameDescription;
        case 'about_age':
          return AppLocalizations.of(context)!.howOldAreYouDescription;
        case 'about_gender':
          return AppLocalizations.of(context)!.genderDescription;
      }
    } else if (key == 'hint') {
      switch (id) {
        case 'about_name':
          return AppLocalizations.of(context)!.typeNameHint;
        case 'about_age':
          return AppLocalizations.of(context)!.ageHint;
      }
    }
    return game[key] ?? '';
  }
  // ─────────────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _currentGames {
    if (_selectedMainCategory == 0) {
      switch (_selectedLevel) {
        case 0:
          return _sariliLevel1Games;
        case 1:
          return _sariliLevel2Games;
        case 2:
          return _sariliLevel3Games;
        case 3:
          return _sariliLevel4Games;
        default:
          return _sariliLevel1Games;
      }
    } else {
      switch (_selectedLevel) {
        case 0:
          return _pamilyaLevel1Games;
        case 1:
          return _pamilyaLevel2Games;
        case 2:
          return _pamilyaLevel3Games;
        case 3:
          return _pamilyaLevel4Games;
        case 4:
          return _pamilyaLevel5Games;
        default:
          return _pamilyaLevel1Games;
      }
    }
  }

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
  /// all is the behaviour we want to encourage. Running the clock out earns
  /// nothing, because nothing was attempted.
  static const int _pointsPerWrongAttempt = 5;

  int get _starsFromWrong {
    if (_wrongAttempts == 0) return 3;
    if (_wrongAttempts == 1) return 2;
    return 1;
  }

  Color get _currentMainColor =>
      _mainCategories[_selectedMainCategory]['color'];

  // ─────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playModuleMusic(ModuleMusic.pamilya);

    _starBurstController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _timerPulseController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _celebrationController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    _audioPlayer = AudioPlayer();

    _initSmartResume();

    if (_timerEnabled) _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

      // 1. Find the first uncompleted CATEGORY and LEVEL
      int savedMainCat = 0;
      int savedLevel = 0;
      bool found = false;

      for (int c = 0; c < _mainCategories.length; c++) {
        for (int l = 0; l < _categoryLevelTitles[c].length; l++) {
          if (!userProvider.isPamilyaLevelCompleted(c, l)) {
            savedMainCat = c;
            savedLevel = l;
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // If all completed, default to last
      if (!found) {
        savedMainCat = _mainCategories.length - 1;
        savedLevel = _categoryLevelTitles[savedMainCat].length - 1;
      }

      if (mounted) {
        setState(() {
          _selectedMainCategory = savedMainCat;
          _selectedLevel = savedLevel;

          // Restore both banked totals so reopening the module shows what the
          // child already achieved instead of restarting the score at zero.
          final pProgress = userProvider.getPamilyaProgress();
          _totalScore = pProgress['totalScore'] ?? 0;

          _resetLevelState();
        });
      }
    } catch (e) {
      debugPrint('Pamilya Smart Resume failed: $e');
      _resetLevelState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tipTimer?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    _placeController.dispose();
    _starBurstController.dispose();
    _timerPulseController.dispose();
    _celebrationController.dispose();
    _audioPlayer.dispose();

    // Full volume again, now rather than next frame: the post-frame callback
    // this used only runs if another frame happens to be scheduled.
    AudioManager.instance.unduckMusic();
    AudioManager.instance.resumeHomeMusic();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Timer
  // ─────────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isPamilyaGameCompleted(
          _selectedMainCategory, _selectedLevel, _currentGameIndex)) {
        return;
      }
    } catch (_) {}

    _secondsLeft = 60;
    _timerPulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _timerPulseController.stop();
        _onTimeout();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerPulseController.stop();
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timerPulseController.stop();
  }

  void _onTimeout() {
    // The tap and the last tick of the clock can land in the same frame — see
    // matematika's _onTimeout.
    if (_overlayShowing) return;
    // Its own signal, not the wrong-answer one — see matematika's _onTimeout.
    setState(() => _showTimeUpOverlay = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _showTimeUpOverlay = false;
        _resetQuestionState();
      });
      if (_timerEnabled) _startTimer();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  State reset
  // ─────────────────────────────────────────────────────────────────────────

  void _resetLevelState() {
    // A level always opens at its first question.
    //
    // It used to resume at the first question not yet marked complete, which
    // sounds right until you remember that a *wrong* answer marks a question
    // complete too — it has to, or the level could never end. So a child who
    // missed a few, went back to the dashboard and returned was dropped past
    // every question they had got wrong, sometimes straight onto the last one,
    // with no way back to the ones they had not actually learned.
    //
    // Starting from the top costs a child who was halfway through a few taps
    // they have already done. It saves a child who was struggling from being
    // skipped past the very questions they needed.
    _currentGameIndex = 0;
    _levelStars = 0;
    _levelScore = 0;
    _wrongAttempts = 0;
    _resetQuestionState();
  }

  void _resetQuestionState() {
    setState(() {
      _verdictRunning = false;
      _selectedAboutMeAnswer = null;
      // Cancel with it, or the pending close fires on the next question and
      // runs a continuation meant for the last one.
      _tipTimer?.cancel();
      _tipTimer = null;
      _afterTip = null;
      _tipMessage = null;
      _selectedEmotionAnswer = null;
      _selectedRoutineAnswer = null;
      _selectedFoodIndex = null;
      _selectedColorIndex = null;
      _selectedGameIndex = null;
      _selectedAnimalIndex = null;
      _selectedFamilyAnswer = null;
      _selectedRoleAnswer = null;
      _selectedActivityAnswer = null;
      _myHomeCompleted = false;
      _homeChallengeIndex = 0;
      _matchedHomeItems.clear();
      _selectedTreeQuizAnswer = null;
      _showCorrectOverlay = false;
    });
  }

  void _switchMainCategory(int index) {
    _stopTimer();
    setState(() {
      _selectedMainCategory = index;
      _selectedLevel = 0;
      _resetLevelState();
    });
    if (_timerEnabled) _startTimer();
  }

  /// Leaves the wall of cards for one level of one category.
  void _openLevel(int cat, int level) {
    setState(() {
      _playing = true;
      _selectedMainCategory = cat;
    });
    _switchLevel(level);
  }

  /// Back to the wall of cards, without leaving the module.
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

  void _switchLevel(int level) {
    _stopTimer();
    setState(() {
      _selectedLevel = level;
      _resetLevelState();
    });
    if (_timerEnabled) _startTimer();
  }

  void _advanceOrComplete() {
    // See the note in Matematika: a verdict that finishes after the child has
    // gone back to the cards must not drag the next question out there with
    // it.
    if (!_playing) return;
    final total = _currentGames.length;
    if (_currentGameIndex < total - 1) {
      setState(() {
        _currentGameIndex++;
        _wrongAttempts = 0;
        _resetQuestionState();
      });
      if (_timerEnabled) _startTimer();
    } else {
      _showLevelComplete();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Correct / Wrong
  // ─────────────────────────────────────────────────────────────────────────

  /// True while any answer feedback is on screen.
  ///
  /// The 1.6 seconds a feedback card is up is dead time the child can tap
  /// straight through, and a young child absolutely will — they press the
  /// same spot again the moment nothing happens. Every tap that lands in
  /// that window is counted as another answer, and the damage is real: a
  /// second wrong answer costs another star, banks another 5 points, and
  /// queues a second advance, so the game jumps a whole question and the
  /// level finishes with one never asked. This is what gates it.
  /// True from the moment an answer is taken until the next question is on
  /// screen — including the gaps between the cards.
  bool _verdictRunning = false;

  /// A card is on screen this instant.
  bool get _overlayShowing =>
      _showCorrectOverlay || _showWrongOverlay || _showTimeUpOverlay;

  /// The board is not the child's to touch. Wider than [_overlayShowing] on
  /// purpose — see the note above.
  bool get _feedbackShowing =>
      _verdictRunning ||
      _overlayShowing ||
      // The teaching pop-up counts too. It holds for three to five seconds —
      // longer than any verdict card — and it was the one message the gate
      // did not cover, so a child could tap straight through the part that
      // was there to be read.
      _tipMessage != null;

  void _onCorrect() {
    if (_showCorrectOverlay) return;
    HapticFeedback.heavyImpact();
    _stopTimer();

    final earned = _starsFromWrong;
    setState(() {
      _totalScore += _pointsPerCorrect;
      _levelStars += earned;
      _levelScore += _pointsPerCorrect;
      _showCorrectOverlay = true;
    });

    _starBurstController.forward(from: 0);
    _celebrationController.forward(from: 0);

    // No bottom banner. The big card that pops up over the board already
    // says this, so the strip underneath repeated it word for word — twice
    // for the same event, the second time below where the child is looking.
    _saveQuestionProgress(earned);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _showCorrectOverlay = false;
        _celebrationController.reset();
      });
      _advanceOrComplete();
    });
  }

  void _saveQuestionProgress(int earned) {
    // A right answer works the skill back down the list. Without it the list
    // only grows and stops describing the child as they are now.
    if (earned > 0) {
      Provider.of<UserProvider>(context, listen: false).noteAttempt(
          _selectedMainCategory == 0 ? 'sarili' : 'pamilya',
          'level$_selectedLevel',
          correct: true);
    }
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.updatePamilyaProgress(
      _selectedMainCategory,
      _selectedLevel,
      _currentGameIndex,
      true,
      earnedStars: earned,
    );
  }

  void _onWrong() {
    if (_overlayShowing) return;
    _verdictRunning = true;
    // A soft tap rather than a full buzz — gentler for young children.
    HapticFeedback.lightImpact();
    _stopTimer();

    setState(() {
      _wrongAttempts++;
      _showWrongOverlay = true;
    });
    Provider.of<UserProvider>(context, listen: false).noteAttempt(
        _selectedMainCategory == 0 ? 'sarili' : 'pamilya',
        'level$_selectedLevel',
        correct: false);

    // Half marks for attempting it, and no star.
    setState(() {
      _totalScore += _pointsPerWrongAttempt;
      _levelScore += _pointsPerWrongAttempt;
    });
    _saveQuestionProgress(0);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showWrongOverlay = false);
      _advanceOrComplete();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Game handlers
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds the answers for one "All About Me" question from the child's own
  /// profile, and says which one is right.
  ///
  /// This level used to ask the child to *type* their name, their age and the
  /// name of their town. A three-to-five-year-old cannot do that, and the
  /// hint under the box — "Type your name here" — was written for someone who
  /// can already read. Recognising your own name among others is the skill
  /// that actually comes first, and it is one the app can check, because the
  /// profile already holds the answer.
  ///
  /// Distractors are picked to be close, not obviously wrong: names of a
  /// similar shape, ages one either side. Picking out "Ana" from "Ana, Ani,
  /// Anna" is recognition; picking it from "Ana, Bartholomew, 7" is not.
  (List<String>, int) _aboutMeChoices(Map<String, dynamic> game) {
    final profile =
        Provider.of<UserProvider>(context, listen: false).userProfile;
    final id = game['id'].toString();

    // Seeded on the question and the child, so the answers stay put while
    // they think about them instead of reshuffling on every rebuild — but
    // still differ from question to question.
    final rnd = Random('$id|${profile?.name ?? ''}'.hashCode);

    List<String> shuffledWith(String answer, List<String> others) {
      final pool = others.where((o) => o != answer).toList()..shuffle(rnd);
      final out = [answer, ...pool.take(2)]..shuffle(rnd);
      return out;
    }

    switch (id) {
      case 'about_name':
        final name = (profile?.name.trim().isNotEmpty ?? false)
            ? profile!.name.trim().split(' ').first
            : 'Ana';
        final decoys = _nameDecoysFor(name);
        final opts = shuffledWith(name, decoys);
        return (opts, opts.indexOf(name));

      case 'about_age':
        final age = profile?.age ?? 4;
        final opts = shuffledWith(
            '$age',
            ['${age - 1}', '${age + 1}', '${age + 2}'].where((v) {
              final n = int.tryParse(v) ?? 0;
              return n > 0;
            }).toList());
        return (opts, opts.indexOf('$age'));

      case 'about_gender':
        // The two options come from the content file, in the child's language.
        final raw = (game['options'] as List?)?.cast<String>() ??
            const ['👧 Girl', '👦 Boy'];
        // The profile stores this as "Male" / "Female" — the rest of the app
        // compares against 'male' — while the answers here read "Boy" and
        // "Girl". The first version of this check also carried a third clause
        // reading `startsWith('b') == false`, which is true for "Male", so
        // every boy was told his own answer was wrong.
        final g = (profile?.gender ?? '').toLowerCase();
        final isGirl = g.startsWith('f') || g.startsWith('g');
        return (raw, isGirl ? 0 : 1);

      case 'about_birthday':
        final month = profile?.birthday?.month ?? 1;
        const names = _monthNames;
        final answer = names[month - 1];
        final opts = shuffledWith(answer, List.of(names));
        return (opts, opts.indexOf(answer));

      default:
        // "Who do you live with?" — no profile field to draw on, and none is
        // needed: for a child this age the answer is the point, not a lookup.
        final raw = (game['options'] as List?)?.cast<String>() ??
            const ['👨‍👩‍👧 My family', '🐶 A dog', '🧸 My toys'];
        return (raw, 0);
    }
  }

  static const List<String> _monthNames = [
    'Enero',
    'Pebrero',
    'Marso',
    'Abril',
    'Mayo',
    'Hunyo',
    'Hulyo',
    'Agosto',
    'Setyembre',
    'Oktubre',
    'Nobyembre',
    'Disyembre',
  ];

  /// Names that look and sound like [name], so the child has to read rather
  /// than spot the odd one out.
  List<String> _nameDecoysFor(String name) {
    const pool = [
      'Ana',
      'Ani',
      'Anna',
      'Ara',
      'Bea',
      'Ben',
      'Cara',
      'Dina',
      'Ella',
      'Emma',
      'Ian',
      'Ina',
      'Jose',
      'Juan',
      'Lea',
      'Lia',
      'Mara',
      'Mia',
      'Nena',
      'Nina',
      'Paz',
      'Rea',
      'Rica',
      'Rosa',
      'Sara',
      'Tina',
      'Vina',
    ];
    final first = name.isEmpty ? '' : name[0].toLowerCase();
    final sameLetter = pool
        .where((p) => p.isNotEmpty && p[0].toLowerCase() == first && p != name)
        .toList();
    final rest = pool.where((p) => p != name).toList();
    // Same initial first — a child who knows their letter still has to look.
    return [...sameLetter, ...rest];
  }

  void _handleAboutMeAnswer(int index, int correct, String description) {
    if (_selectedAboutMeAnswer != null) return;
    setState(() => _selectedAboutMeAnswer = index);
    if (index == correct) {
      _correctThenTip(description);
    } else {
      _onWrong();
    }
  }

  void _handleEmotionAnswer(
      int index, int correct, String explanation, String tip) {
    _pauseTimer();
    setState(() => _selectedEmotionAnswer = index);
    if (index == correct) {
      _showEmojiExplation(explanation, tip);
    } else {
      _onWrong();
    }
  }

  /// How long a tip stays up: long enough to be read to a child, and longer
  /// for a longer sentence.
  ///
  /// How long a pop-up stays up, from how much there is to read.
  ///
  /// Counted in characters, not words. Words are the wrong unit here because
  /// the app runs in three languages and they do not build words the same
  /// way: "nagrerelaks", "pinakamatanda" and "agsasaruno" are one word each
  /// and take as long to read as three short ones. Characters are the same
  /// measure in every language, so a message does not get less time just for
  /// being written in Ilokano.
  ///
  /// The rate is 9 characters a second — the pace of an adult reading aloud
  /// to a small child, which is about a third slower than reading silently.
  /// On top of that is a flat 1.4 seconds, because the first moment of any
  /// pop-up is spent noticing it rather than reading it.
  ///
  /// The old rule was words ÷ 4, floored at 3 seconds. "Bakuran: pamilya ay
  /// naglalaro at naglilibang" is seven words, so it asked for 1.75 seconds
  /// and got the 3-second floor — for 46 characters. It now gets 6.5.
  ///
  /// The 8-second ceiling is not about reading speed but about waiting: the
  /// board is locked while a pop-up is up, and past eight seconds a
  /// three-year-old has stopped reading and started wondering if the game
  /// has broken.
  Duration _tipDuration(String tip) {
    final characters = tip.trim().runes.length;
    final seconds = 1.4 + characters / 9.0;
    final clamped = seconds < 3.5 ? 3.5 : (seconds > 8.0 ? 8.0 : seconds);
    return Duration(milliseconds: (clamped * 1000).round());
  }

  /// Shows the verdict first, then the tip in the middle of the board.
  ///
  /// The tip used to slide in as a strip along the bottom, under the answers
  /// and often under the child's own hand. It is the part worth reading, so
  /// it belongs where they are already looking.
  void _showTipThenAdvance(String tip) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _raiseTip(tip, then: _onCorrect);
    });
  }

  /// Puts a pop-up on screen and schedules what happens when it goes.
  ///
  /// A real [Timer] rather than a delayed future, because the child can now
  /// close the pop-up early by tapping it and the pending close has to be
  /// cancellable — otherwise it fires again later and advances a question
  /// the child is already answering.
  void _raiseTip(String tip, {VoidCallback? then}) {
    _tipTimer?.cancel();
    _afterTip = then;
    _tipShownAt = DateTime.now();
    setState(() => _tipMessage = tip);
    _tipTimer = Timer(_tipDuration(tip), _closeTip);
  }

  /// Closes the pop-up and runs whatever was waiting on it.
  void _closeTip() {
    _tipTimer?.cancel();
    _tipTimer = null;
    final next = _afterTip;
    _afterTip = null;
    if (!mounted) return;
    setState(() => _tipMessage = null);
    next?.call();
  }

  /// A tap on the pop-up means "I have read this" — but not in the first
  /// three-quarters of a second.
  ///
  /// The tap that answered the question is often still coming: a child who
  /// presses an answer twice would have the second press land on the pop-up
  /// and wipe it before it had finished appearing. The grace period is short
  /// enough that a deliberate tap never feels ignored.
  void _dismissTipByTap() {
    final shown = _tipShownAt;
    if (shown == null) return;
    if (DateTime.now().difference(shown) < const Duration(milliseconds: 750)) {
      return;
    }
    _closeTip();
  }

  /// The one way a correct answer is announced in this module.
  ///
  /// Card first, then whatever there is to teach as its own pop-up in the
  /// middle of the board, then the next question. "About Myself" has always
  /// worked this way; "And My Family" used to answer with a green strip
  /// along the bottom instead — under the answers, often under the child's
  /// own hand, and nothing like the card every other game shows.
  void _correctThenTip(String? tip) {
    setState(() {
      _verdictRunning = true;
      _showCorrectOverlay = true;
    });
    if (tip == null || tip.trim().isEmpty) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() => _showCorrectOverlay = false);
        _onCorrect();
      });
      return;
    }
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showCorrectOverlay = false);
    });
    _showTipThenAdvance(tip);
  }

  /// The explanation used to sit in a panel under the answers while the tip
  /// popped up in the middle — two halves of the same thought, in two places,
  /// one of them where nobody was looking. They are one message now.
  void _showEmojiExplation(String explanation, String tip) {
    final joined = explanation.trim().isEmpty
        ? tip
        : (tip.trim().isEmpty ? explanation : '$explanation  $tip');
    _correctThenTip(joined);
  }

  void _handleRoutineAnswer(
      int index, int correct, String explanation, String tip) {
    _pauseTimer();
    setState(() => _selectedRoutineAnswer = index);
    if (index == correct) {
      setState(() => _showCorrectOverlay = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showCorrectOverlay = false);
      });
      _showTipThenAdvance(tip);
    } else {
      _onWrong();
    }
  }

  /// "Ang Aking Paborito" has no right answer, so it gets no verdict.
  ///
  /// The app cannot know a child's favourite food, and it never could — so
  /// the green tick it used to show appeared whatever they tapped. A tick
  /// that is always right is worse than no tick: it is the same mark this
  /// module uses on questions that *do* have an answer, and a child who sees
  /// it earned for anything learns it means nothing.
  ///
  /// What comes up instead simply says their choice back to them, which is
  /// the whole point of the level — naming what you like. The stars still
  /// come, because answering about yourself is the work here.
  /// "🐶 Aso" → "Aso".
  ///
  /// The preference options carry their picture in the text — and the tile
  /// draws that same picture large above the label, so every answer showed
  /// its emoji twice, once big and once shrunk into the caption. Stripped
  /// here rather than in the data, so it holds for all three languages and
  /// for any option that has no picture in front of it.
  /// The picture an answer starts with, or null when it is only words.
  ///
  /// The words of an answer with any leading picture taken off.
  ///
  /// The picture half of that split moved to [AnswerTile] with the tile it
  /// draws; this half is still read by the favourite-chosen message and by
  /// the family tree board.
  String _withoutLeadingEmoji(String label) {
    final trimmed = label.trim();
    final space = trimmed.indexOf(' ');
    if (space <= 0) return trimmed;
    final head = trimmed.substring(0, space);
    // A leading word has letters or digits in it; a picture does not.
    if (RegExp(r'[A-Za-z0-9]').hasMatch(head)) return trimmed;
    return trimmed.substring(space + 1).trim();
  }

  void _handlePreferenceSelection(
      int index, String type, String emoji, String label) {
    setState(() {
      if (type == 'food') {
        _selectedFoodIndex = index;
      } else if (type == 'color') {
        _selectedColorIndex = index;
      } else if (type == 'game') {
        _selectedGameIndex = index;
      } else if (type == 'animal') {
        _selectedAnimalIndex = index;
      }
      _verdictRunning = true;
    });

    // A beat first, so the child sees their own choice light up before the
    // pop-up covers the board.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _raiseTip(
        '$emoji ${AppLocalizations.of(context)!.favoriteChosen(_withoutLeadingEmoji(label))}',
        then: _onCorrect,
      );
    });
  }

  void _handleFamilyAnswer(int index, int correct, Map<String, dynamic> game) {
    setState(() => _selectedFamilyAnswer = index);
    if (index == correct) {
      if (game['audioPath'] != null) {
        _playItemAudio(game['audioPath']);
      }
      // What the panel under the board used to say, said in the pop-up
      // instead — the sentence about what this family member does, and the
      // note about what they are called at home. It is the part worth
      // reading, so it goes where the child is already looking.
      //
      // Where the game carries its own validated pop-up text (the English
      // games do, from the language validation), that whole text is shown
      // as written; "{member} is {roles}." joined to the note did not make a
      // sentence.
      final popup = game['popup'];
      if (popup is String && popup.isNotEmpty) {
        _correctThenTip(popup);
      } else {
        final sentence = AppLocalizations.of(context)!
            .familyRoleSentence(game['member'], game['roles']);
        _correctThenTip('$sentence  📖 ${game['note']}');
      }
    } else {
      _onWrong();
    }
  }

  /// Family Roles has no wrong answer: who cooks, works, tells stories or
  /// plays differs from one family to the next, and a child naming their own
  /// family's cook should not be told they are wrong. The listed answer keeps
  /// its own explanation; any other choice gets a reply that fits everyone.
  void _handleRoleAnswer(int index, int correct, String explanation) {
    setState(() => _selectedRoleAnswer = index);
    _correctThenTip(index == correct
        ? explanation
        : AppLocalizations.of(context)!.roleAnyAnswer);
  }

  void _handleActivityAnswer(int index, int correct, String explanation) {
    setState(() => _selectedActivityAnswer = index);
    if (index == correct) {
      _correctThenTip(explanation);
    } else {
      // Was a red strip and another go at the same question — the only two
      // games in the app that re-asked. Every other one shows the amber card
      // and moves on, and the star rating is what records the miss.
      _onWrong();
    }
  }

  void _handleFamilyTreeComplete() {
    _correctThenTip(AppLocalizations.of(context)!.iLearnedFamilyTree);
  }

  void _handleTreeQuizAnswer(int index, int correct, String explanation) {
    setState(() => _selectedTreeQuizAnswer = index);
    if (index == correct) {
      _correctThenTip(explanation);
    } else {
      _onWrong();
    }
  }

  /// One item into one room. This is the only board where a single question
  /// holds several moves, so it cannot hand off to [_onCorrect] after each
  /// one — but it says the same things in the same shapes as everywhere
  /// else: the pop-up in the middle for what the room is for, the amber card
  /// for a miss.
  void _handleRoomTap(int roomIdx) {
    if (_myHomeCompleted) return;
    if (_feedbackShowing) return;

    final challenges = _homeItemChallenges;
    if (_homeChallengeIndex >= challenges.length) return;

    final currentChallenge = challenges[_homeChallengeIndex];
    final correctRoomIdx = currentChallenge['roomIndex'] as int;

    if (roomIdx == correctRoomIdx) {
      HapticFeedback.mediumImpact();
      final room = _homeRooms[roomIdx];
      setState(() => _matchedHomeItems.add(_homeChallengeIndex));
      _raiseTip(
        '${currentChallenge['itemEmoji']} '
        '${room['name']}: ${room['activity']}',
        then: () {
          if (_homeChallengeIndex + 1 < challenges.length) {
            setState(() => _homeChallengeIndex++);
          } else {
            _handleMyHomeComplete();
          }
        },
      );
    } else {
      HapticFeedback.vibrate();
      // The same amber card as a wrong answer anywhere else, but the board
      // stays put: there are still items to place, so this is a miss on one
      // move, not the end of the question.
      setState(() {
        _wrongAttempts++;
        _showWrongOverlay = true;
      });
      Provider.of<UserProvider>(context, listen: false).noteAttempt(
          _selectedMainCategory == 0 ? 'sarili' : 'pamilya',
          'level$_selectedLevel',
          correct: false);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _showWrongOverlay = false);
      });
    }
  }

  void _handleMyHomeComplete() {
    setState(() => _myHomeCompleted = true);
    _correctThenTip(AppLocalizations.of(context)!.thatIsOurHome);
  }

  /// Raises a pop-up in the middle of the board and clears it again.
  ///
  /// Replaces a green strip that slid in along the bottom of the screen —
  /// below the answers, and on a small phone usually below the child's own
  /// hand. Nothing in this module speaks from down there any more.
  void _showTip(String msg) => _raiseTip(msg);

  // ─────────────────────────────────────────────────────────────────────────
  //  Dialogs
  // ─────────────────────────────────────────────────────────────────────────

  void _showLevelComplete() {
    if (!_playing) return;
    _verdictRunning = false;
    _stopTimer();
    final total = _currentGames.length;
    final avgStars = total == 0 ? 1 : (_levelStars / total).ceil().clamp(1, 3);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.awardPamilyaLevelCompletion(
        _selectedMainCategory, _selectedLevel, avgStars);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessModal(
        title: AppLocalizations.of(context)!.levelCompleted(_selectedLevel + 1),
        subtitle: _getLevelTitle(_selectedMainCategory, _selectedLevel),
        score: _levelScore,
        stars: avgStars,
        primaryLabel: _selectedLevel <
                _categoryLevelTitles[_selectedMainCategory].length - 1
            ? AppLocalizations.of(context)!.next
            : AppLocalizations.of(context)!.finished,
        onPrimaryTap: () {
          Navigator.pop(context);
          if (_selectedLevel <
              _categoryLevelTitles[_selectedMainCategory].length - 1) {
            _switchLevel(_selectedLevel + 1);
          } else {
            _showCategoryComplete();
          }
        },
        secondaryLabel: AppLocalizations.of(context)!.ulitin,
        onSecondaryTap: () {
          Navigator.pop(context);
          _switchLevel(_selectedLevel);
        },
        mainColor: _currentMainColor,
      ),
    );
  }

  void _showCategoryComplete() {
    if (!_playing) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessModal(
        title: AppLocalizations.of(context)!.proudOfYou,
        subtitle: AppLocalizations.of(context)!
            .categoryCompleted(_getMainCategoryTitle(_selectedMainCategory)),
        score: _totalScore,
        stars: 3,
        // Both buttons used to run the identical `Navigator.pop(context)`:
        // two choices that did the same nothing, leaving the child parked on
        // the last level of a category they had already finished. "Back" in
        // particular went nowhere at all.
        primaryLabel: _selectedMainCategory < _mainCategories.length - 1
            ? AppLocalizations.of(context)!.continueText
            : AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.pop(context);
          if (_selectedMainCategory < _mainCategories.length - 1) {
            _switchMainCategory(_selectedMainCategory + 1);
          } else {
            // The whole module is finished: back to the wall, where every
            // card the child just filled is waiting to be looked at. This
            // used to drop them on the dashboard.
            _backToPicker();
          }
        },
        secondaryLabel: AppLocalizations.of(context)!.back,
        onSecondaryTap: () {
          Navigator.pop(context);
          _backToPicker();
        },
        mainColor: _currentMainColor,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: CustomBackButton(
        iconColor: AppColors.textDark,
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getMainCategoryTitle(_selectedMainCategory),
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(AppLocalizations.of(context)!.level(_selectedLevel + 1),
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ],
      ),
      actions: [
        _buildAppBarPill(
          icon: '⭐',
          label: '${Provider.of<UserProvider>(context).displayStars}',
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey.withOpacity(0.12),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildAppBarPill({
    required String icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Future<void> _playItemAudio(String path) async {
    try {
      await AudioManager.instance.duckMusic();
      await _audioPlayer.stop();
      await _audioPlayer.play(audioSourceFor(path));

      // Back to full volume when the clip finishes. This runs from a stream
      // event rather than a tap, which is exactly where a play() would be
      // refused — a volume change is not.
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted) {
          AudioManager.instance.unduckMusic();
        }
      });
    } catch (e) {
      debugPrint('Error playing item audio: $e');
      AudioManager.instance.unduckMusic();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
            // Nothing under a feedback card is tappable while it is up —
            // see the note on [_feedbackShowing]. The same gate as Matematika,
            // because the same child taps the same way in both.
            AbsorbPointer(
              absorbing: _feedbackShowing,
              child: _playing
                  ? Column(
                      children: [
                        _buildProgressHeader(),
                        Expanded(child: _buildGameContent()),
                      ],
                    )
                  : _buildLevelPicker(),
            ),
            if (_playing && _showCorrectOverlay) _buildCorrectOverlay(),
            if (_playing && _showWrongOverlay) _buildWrongOverlay(),
            if (_playing && _showTimeUpOverlay) _buildTimeUpOverlay(),
            if (_tipMessage != null) _buildTipOverlay(_tipMessage!),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TABS
  // ─────────────────────────────────────────────────────────────────────────

  // ── Gradient themes per level ─────────────────────────────────────────────
  static const List<List<Color>> _levelGradients = [
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)], // 0: Coral Sunset
    [Color(0xFF4FACFE), Color(0xFF00F2FE)], // 1: Ocean Blue
    [Color(0xFF11998E), Color(0xFF38EF7D)], // 2: Emerald Green
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // 3: Royal Purple
    [Color(0xFFFFB75E), Color(0xFFED8F03)], // 4: Sunburst Amber
    [Color(0xFFFF512F), Color(0xFFDD2476)], // 5: Warm Rose
    [Color(0xFF4364F7), Color(0xFF6FB1FC)], // 6: Electric Blue
    [Color(0xFF43E97B), Color(0xFF38F9D7)], // 7: Mint
    [Color(0xFFF093FB), Color(0xFFF5576C)], // 8: Pink Flamingo
  ];

  List<Color> _currentGradient() {
    final idx =
        _selectedMainCategory == 0 ? _selectedLevel : 4 + _selectedLevel;
    return _levelGradients[idx % _levelGradients.length];
  }

  /// Every level in both parts of the module, as cards.
  ///
  /// This screen carried two pinned strips — the two big categories, and then
  /// the levels inside the chosen one — costing about 136 logical pixels
  /// above every question, and putting two live controls where a child rests
  /// their thumb. Both are gone: the categories are headings on one wall the
  /// child leaves to play and comes back to.
  Widget _buildLevelPicker() {
    final userProvider = Provider.of<UserProvider>(context);

    int earned = 0;
    for (int cat = 0; cat < _categoryLevelIcons.length; cat++) {
      for (int i = 0; i < _categoryLevelIcons[cat].length; i++) {
        earned += userProvider.pamilyaLevelStars(cat, i);
      }
    }
    const possible =
        UserProvider.sariliStarCeiling + UserProvider.familyStarCeiling;

    return Column(
      children: [
        StarTally(earned: earned, possible: possible),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              for (int cat = 0; cat < _categoryLevelIcons.length; cat++) ...[
                Padding(
                  padding: EdgeInsets.only(top: cat == 0 ? 0 : 22, bottom: 10),
                  child: Text(
                    _getMainCategoryTitle(cat),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.98,
                  ),
                  itemCount: _categoryLevelIcons[cat].length,
                  // The beat carries on across the second heading — the two
                  // groups are one wall, not two lists that each start over.
                  itemBuilder: (_, i) => StaggeredEntrance(
                    index: cat == 0 ? i : _categoryLevelIcons[0].length + i,
                    delayMs: 55,
                    durationMs: 380,
                    child: _levelCard(cat, i, userProvider),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The three stars of one level, as they sit on its card.
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

  /// One level, in its own colour, with what the child has taken from it.
  Widget _levelCard(int cat, int i, UserProvider userProvider) {
    final completed = userProvider.isPamilyaLevelCompleted(cat, i);
    final stars = userProvider.pamilyaLevelStars(cat, i);
    final gradient =
        _levelGradients[(cat == 0 ? i : 4 + i) % _levelGradients.length];

    return Pressable(
      onTap: () => completed ? _confirmReplay(cat, i) : _openLevel(cat, i),
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
                Icon(_categoryLevelIcons[cat][i],
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
            Text(
              _getLevelTitle(cat, i),
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

  /// Tapping a level that is already finished — kept exactly as it was on the
  /// old strip: what the level is worth now, then the offer to replay it.
  void _confirmReplay(int cat, int i) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final levelStars = userProvider.pamilyaLevelStars(cat, i);
    final stars = levelStars;
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (sIdx) {
                final got = sIdx < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    got ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: got ? const Color(0xFFFFB800) : Colors.grey.shade300,
                  ),
                );
              }),
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
              backgroundColor: _currentMainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openLevel(cat, i);
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

  Widget _buildProgressHeader() {
    final total = _currentGames.length;
    final progress = total == 0 ? 0.0 : (_currentGameIndex + 1) / total;
    final activeGradient = _currentGradient();
    final icons = _categoryLevelIcons[_selectedMainCategory];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  child: Icon(icons[_selectedLevel],
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_getLevelTitle(_selectedMainCategory, _selectedLevel),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(_getLevelSubTitle(_selectedMainCategory, _selectedLevel),
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ]),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_currentGameIndex + 1} / $total',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
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
      ]),
    );
  }

  Widget _buildCorrectOverlay() {
    return AnswerFeedback.correct(
        message: AppLocalizations.of(context)!.straightOrCorrect);
  }

  Widget _buildWrongOverlay() {
    return AnswerFeedback.wrong(
        message: AppLocalizations.of(context)!.wrongShort);
  }

  /// The thing worth remembering, in the middle of the board.
  ///
  /// Shown after the verdict has had its moment, and held for [_tipDuration]
  /// so an adult reading it aloud is not cut off mid-sentence.
  Widget _buildTipOverlay(String tip) {
    // Tapping anywhere on it means the child is done reading. This is the one
    // thing on screen that still answers a touch while a message is up — the
    // board underneath is sealed off.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismissTipByTap,
      child: Container(
        color: Colors.black.withOpacity(0.18),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF3EA8E5), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3EA8E5).withOpacity(0.35),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF6FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.lightbulb,
                        color: Color(0xFF2B8FCC), size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tip,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A4C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The clock ran out. Calm blue with a clock face — never the amber ✕ of a
  /// wrong answer, because the child did not answer wrongly.
  Widget _buildTimeUpOverlay() {
    return AnswerFeedback.timeUp(
        message: AppLocalizations.of(context)!.timesUp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GAME CONTENT ROUTER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGameContent() {
    Widget gameWidget;
    if (_selectedMainCategory == 0) {
      switch (_selectedLevel) {
        case 0:
          gameWidget = _buildSariliGame1();
          break;
        case 1:
          gameWidget = _buildSariliGame2();
          break;
        case 2:
          gameWidget = _buildSariliGame3();
          break;
        case 3:
          gameWidget = _buildSariliGame4();
          break;
        default:
          gameWidget = _buildSariliGame1();
      }
    } else {
      switch (_selectedLevel) {
        case 0:
          gameWidget = _buildFamilyMembersGame();
          break;
        case 1:
          gameWidget = _buildFamilyRolesGame();
          break;
        case 2:
          gameWidget = _buildFamilyActivitiesGame();
          break;
        case 3:
          // Show quiz questions first, visual Family Tree only at last index
          if (_currentGameIndex < _pamilyaLevel4Games.length - 1) {
            gameWidget = _buildPamilyaQuizGame(
              _pamilyaLevel4Games[_currentGameIndex],
            );
          } else {
            gameWidget = _buildFamilyTreeGame();
          }
          break;
        case 4:
          // Show quiz questions first, visual My Home only at last index
          if (_currentGameIndex < _pamilyaLevel5Games.length - 1) {
            gameWidget = _buildPamilyaQuizGame(
              _pamilyaLevel5Games[_currentGameIndex],
            );
          } else {
            gameWidget = _buildMyHomeGame();
          }
          break;
        default:
          gameWidget = _buildFamilyMembersGame();
      }
    }

    // No "Finished already!" card over a question.
    //
    // A level now always opens at its first question, and a wrong answer
    // marks a question completed just as a right one does — so this card
    // fired on question one every single time a child came back to a level
    // they had touched before, wrapped in an IgnorePointer that made the
    // whole board dead. There is nothing useful it can say: the child is
    // here to answer, and answering again is allowed.

    return gameWidget;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SHARED CARD WRAPPER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _gameCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.family.withOpacity(0.12), width: 2),
        boxShadow: [
          BoxShadow(
              color: AppColors.family.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: child,
    );
  }

  /// One board, laid out to fit rather than to scroll.
  ///
  /// Every question game here was a [SingleChildScrollView], so the board
  /// could be swiped and the question pushed off the top — the one thing a
  /// child who cannot read the choices yet must always be able to see.
  ///
  /// The choices share whatever height is left, which makes them far bigger
  /// targets than the old fixed 54px rows. With two or three answers on a
  /// phone that is a tile a small hand cannot miss.
  /// Longest label that still reads comfortably at half the board's width.
  static const int _twoColumnLabelLimit = 16;

  Widget _gameBoard({
    required String question,
    required List<Widget> choices,
    List<String>? labels,
    Widget? beneathQuestion,
    Widget? footer,
  }) {
    // Two side by side when the answers are short words, one per row when
    // they are sentences.
    //
    // A single column shares the whole card between two or three answers, so
    // "Girl" and "Boy" each came out as a tile half the screen tall with one
    // word floating in it. Splitting short answers across two columns gives
    // them a sensible size and still puts them all in view at once.
    final short = labels != null &&
        labels.isNotEmpty &&
        labels.every((l) => l.trim().length <= _twoColumnLabelLimit);
    final cols = (short && choices.length >= 2) ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: _gameCard(
              child: LayoutBuilder(
                builder: (_, box) => Column(
                  children: [
                    // Nearly half the card for the question.
                    //
                    // At a third, a three-line question was being scaled down
                    // to about 19px while four answers below it sat in tiles
                    // tall enough to hold three lines each — the small thing
                    // was the one that had to be read, and the big things
                    // were single words. The question is the board.
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxHeight: box.maxHeight * 0.46),
                      child: _questionBox(question),
                    ),
                    if (beneathQuestion != null) ...[
                      const SizedBox(height: 6),
                      beneathQuestion,
                    ],
                    const SizedBox(height: 10),
                    Expanded(
                      child: LayoutBuilder(builder: (_, inner) {
                        const gap = 10.0;
                        final rows = (choices.length / cols).ceil();
                        final cellW =
                            (inner.maxWidth - gap * (cols - 1)) / cols;

                        // A tile is as tall as it needs to be, not as tall as
                        // the space allows.
                        //
                        // The grid used to divide every last pixel between
                        // the answers, so two short words became two tiles
                        // half the card high with one word floating in the
                        // middle of each. Capping the height and centring
                        // what is left turns that dead space into margin
                        // above and below, which reads as room to breathe
                        // instead of a mistake.
                        final available =
                            (inner.maxHeight - gap * (rows - 1)) / rows;
                        // Raised from 92 and 80. Those caps were chosen when
                        // two pinned strips held about 136 pixels above this
                        // board; with the strips gone the same caps left the
                        // extra room as blank card. At this height a short
                        // answer stands its picture above its word instead of
                        // beside it — see [AnswerTile].
                        final cap = short ? 132.0 : 108.0;
                        final cellH = available < cap ? available : cap;

                        final grid = GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: cols,
                          childAspectRatio: cellW / (cellH <= 0 ? 1 : cellH),
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          children: choices,
                        );
                        // Every answer at one size — see [AnswerTileGroup].
                        return Center(
                          child: labels == null || labels.isEmpty
                              ? grid
                              : AnswerTileGroup(
                                  fontSize: AnswerTile.fitFontSize(
                                    labels,
                                    cellW: cellW,
                                    cellH: cellH,
                                    textScaler:
                                        MediaQuery.textScalerOf(context),
                                  ),
                                  child: grid,
                                ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 10),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _questionBox(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: _currentMainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      // The question is the one thing on the board that must stay readable,
      // so it is set large and allowed to wrap. A bare FittedBox only ever
      // shrinks — it never grows text into the room it has — which left short
      // questions small with an empty card around them.
      child: LayoutBuilder(
        builder: (_, box) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.maxWidth,
            child: Text(
              question,
              style: TextStyle(
                // The base size, not the final one: the box scales it down to
                // fit, so this only sets how big a short question is allowed
                // to become.
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: _currentMainColor,
                height: 1.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// One answer, drawn by [AnswerTile].
  ///
  /// The drawing of it used to live here, sized by constants that were tuned
  /// when a strip of category tabs and a strip of level tabs were eating the
  /// top of this screen. It is a widget of its own now — it measures the slot
  /// the board gives it and sizes the picture and the word from that, and it
  /// can be rendered on its own in a preview instead of only inside a running
  /// app.
  Widget _choiceTile({
    required String label,
    required bool isSelected,
    required bool? isCorrect,
    required VoidCallback onTap,
    double minHeight = 54,
  }) =>
      AnswerTile(
        label: label,
        selected: isSelected,
        correct: isCorrect,
        onTap: onTap,
        minHeight: minHeight,
      );

  // ─────────────────────────────────────────────────────────────────────────
  //  SARILI GAME 1: All About Me
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSariliGame1() {
    final game = _sariliLevel1Games[_currentGameIndex];
    final (choices, correct) = _aboutMeChoices(game);

    return _gameBoard(
      question: _getGameString(game, 'question'),
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedAboutMeAnswer == i;
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          isCorrect: sel ? i == correct : null,
          onTap: () => _handleAboutMeAnswer(
              i, correct, _getGameString(game, 'description')),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SARILI GAME 2: Emotions
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSariliGame2() {
    final game = _sariliLevel2Games[_currentGameIndex];
    final choices = game['choices'] as List;
    return _gameBoard(
      question: game['question'],
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedEmotionAnswer == i;
        final correct = i == game['correct'];
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          isCorrect: sel ? correct : null,
          onTap: () => _handleEmotionAnswer(
              i, game['correct'], game['explanation'], game['tip']),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SARILI GAME 3: Daily Routines
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSariliGame3() {
    final game = _sariliLevel3Games[_currentGameIndex];
    final choices = game['choices'] as List;
    return _gameBoard(
      question: game['question'],
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedRoutineAnswer == i;
        final correct = i == game['correct'];
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          isCorrect: sel ? correct : null,
          onTap: () => _handleRoutineAnswer(
              i, game['correct'], game['explanation'], game['tip']),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SARILI GAME 4: Preferences
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSariliGame4() {
    final game = _sariliLevel4Games[_currentGameIndex];
    final options = game['options'] as List;
    final emojis = game['emojis'] as List;
    final type = game['id'].toString().replaceFirst('preference_', '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Expanded(
          child: _gameCard(
              child: Column(children: [
            // Capped, so a long question cannot squeeze the pictures.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: _questionBox(game['question']),
            ),
            const SizedBox(height: 4),
            Text(game['description'],
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(builder: (_, box) {
                // A GridView works its row height out from the *width* and a
                // fixed aspect ratio, and simply overflows if the rows do not
                // happen to fit the height it was given — which is why the
                // bottom row kept losing its labels. Derive the ratio from the
                // space actually available instead.
                const cols = 2;
                const gap = 12.0;
                final rows = (options.length / cols).ceil();
                final cellW = (box.maxWidth - gap * (cols - 1)) / cols;
                final cellH = (box.maxHeight - gap * (rows - 1)) / rows;
                return GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  childAspectRatio: cellW / (cellH <= 0 ? 1 : cellH),
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  children: List.generate(options.length, (i) {
                    bool sel = false;
                    if (type == 'food') {
                      sel = _selectedFoodIndex == i;
                    } else if (type == 'color') {
                      sel = _selectedColorIndex == i;
                    } else if (type == 'game') {
                      sel = _selectedGameIndex == i;
                    } else if (type == 'animal') {
                      sel = _selectedAnimalIndex == i;
                    }

                    return GestureDetector(
                      onTap: () => _handlePreferenceSelection(
                          i, type, emojis[i], options[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        // Green when chosen, never the module's red.
                        //
                        // This board lit the chosen tile in the category
                        // colour, and "Ang Aking Sarili" is red — the exact
                        // red every other game in the module uses to mark a
                        // wrong answer. A child picking their favourite food
                        // watched it turn the colour of a mistake. Green is
                        // what "yes, that one" looks like everywhere else
                        // here, so it is what it looks like here.
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF2E9E5B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? const Color(0xFF2E9E5B)
                                  : Colors.grey.shade300,
                              width: 2),
                          // The same lift every other answer in the module
                          // now has: a flat outline reads as a label, and a
                          // label does not invite a small hand to push it.
                          boxShadow: [
                            BoxShadow(
                              color: sel
                                  ? const Color(0xFF2E9E5B).withOpacity(0.35)
                                  : Colors.black.withOpacity(0.06),
                              blurRadius: sel ? 12 : 6,
                              offset: Offset(0, sel ? 4 : 3),
                            )
                          ],
                        ),
                        // The picture takes the tile; the word sits under it.
                        //
                        // These answers are pictures first — a scene of
                        // children playing piko tells a three-year-old what
                        // the tile means long before the word does. The tile
                        // used to draw a fixed 46-pixel picture into whatever
                        // cell the grid handed it, so most of the tile was
                        // empty and the picture was too small to read. Both
                        // now take their size from the cell: the word gets a
                        // band at the bottom deep enough to hold it, and the
                        // picture gets everything left over.
                        child: LayoutBuilder(builder: (_, cell) {
                          final band =
                              (cell.maxHeight * 0.26).clamp(20.0, 38.0);
                          final art = (cell.maxHeight - band - 14)
                              .clamp(28.0, cell.maxWidth - 16);
                          return Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ObjectPicture(
                                      emoji: emojis[i] as String, size: art),
                                  SizedBox(
                                    height: band,
                                    // Never wraps and never clips — a long
                                    // answer like "Tumbang Preso" shrinks to
                                    // fit its band instead of losing its tail.
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                          _withoutLeadingEmoji(options[i]),
                                          style: TextStyle(
                                              color: sel
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontWeight: sel
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 16),
                                          textAlign: TextAlign.center),
                                    ),
                                  ),
                                ]),
                          );
                        }),
                      ),
                    );
                  }),
                );
              }),
            ),
          ])),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAMILYA GAME 1: Family Members
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFamilyMembersGame() {
    final game = _pamilyaLevel1Games[_currentGameIndex];
    final choices = game['choices'] as List;
    return _gameBoard(
      question: game['question'],
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedFamilyAnswer == i;
        final correct = i == game['correct'];
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          isCorrect: sel ? correct : null,
          onTap: () => _handleFamilyAnswer(i, game['correct'], game),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAMILYA GAME 2: Family Roles
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFamilyRolesGame() {
    final game = _pamilyaLevel2Games[_currentGameIndex];
    final choices = game['choices'] as List;
    return _gameBoard(
      question: game['question'],
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedRoleAnswer == i;
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          // Every choice is right here — see _handleRoleAnswer.
          isCorrect: sel ? true : null,
          onTap: () =>
              _handleRoleAnswer(i, game['correct'], game['explanation']),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAMILYA GAME 3: Family Activities
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFamilyActivitiesGame() {
    final game = _pamilyaLevel3Games[_currentGameIndex];
    final choices = game['choices'] as List;
    return _gameBoard(
      question: game['question'],
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedActivityAnswer == i;
        final correct = i == game['correct'];
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          isCorrect: sel ? correct : null,
          onTap: () =>
              _handleActivityAnswer(i, game['correct'], game['explanation']),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAMILYA QUIZ GAME (for Family Tree & Aming Tahanan quiz questions)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPamilyaQuizGame(Map<String, dynamic> game) {
    final choices = game['choices'] as List;
    return _gameBoard(
      question: game['question'],
      labels: choices.map((e) => e.toString()).toList(),
      choices: List.generate(choices.length, (i) {
        final sel = _selectedTreeQuizAnswer == i;
        final correct = i == game['correct'];
        return _choiceTile(
          label: choices[i],
          isSelected: sel,
          isCorrect: sel ? correct : null,
          onTap: () => _handleTreeQuizAnswer(
              i, game['correct'], game['explanation'] ?? ''),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAMILYA GAME 4: Family Tree (Interactive)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFamilyTreeGame() {
    final generations = _familyTreeData['generations'] as List;

    // The tree is a picture — see FamilyTreePicture — with no heading over
    // it: the tree is the heading. The board shows "Lolo"; tapping a person
    // says their full relation, "Lolo (ama ni Tatay)".
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Expanded(
          child: _gameCard(
            child: FamilyTreePicture(
              generations: generations,
              onMemberTap: (m) => _showTip('${m['emoji']} ${m['relation']}'),
              ownLabels: _currentLang != 'en',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context)!.familyTreeTapHint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleFamilyTreeComplete,
            icon: const Icon(LucideIcons.circle_check, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.iLearnedFamilyTree,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentMainColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── PAMILYA GAME 5: My Home (Interactive Object-to-Room Matching Game) ───

  List<Map<String, dynamic>> get _homeItemChallenges => [
        {
          'itemEmoji': '📺',
          'itemName': _currentLang == 'en'
              ? 'Television'
              : (_currentLang == 'fil' ? 'Telebisyon' : 'TV / Buya'),
          'roomIndex': 0, // Living Room / Sala
          'question': _currentLang == 'en'
              ? 'Where do we watch TV together as a family?'
              : (_currentLang == 'fil'
                  ? 'Saang bahagi ng bahay sama-samang nanonood ng telebisyon ang pamilya?'
                  : 'Adino ti pagbuyaantayo iti TV a sangsangkamaysa?'),
        },
        {
          'itemEmoji': '🍳',
          'itemName': _currentLang == 'en'
              ? 'Frying Pan & Stove'
              : (_currentLang == 'fil' ? 'Kawali at Kalan' : 'Paglutuan'),
          'roomIndex': 1, // Kitchen / Kusina
          'question': _currentLang == 'en'
              ? 'Where does Nanang cook delicious meals?'
              : (_currentLang == 'fil'
                  ? 'Saan nagluluto ng masasarap na pagkain si Nanay?'
                  : 'Adino ti paglutlutoan ni Nanang iti naimbag a taraon?'),
        },
        {
          'itemEmoji': '🛏️',
          'itemName': _currentLang == 'en'
              ? 'Bed and Pillow'
              : (_currentLang == 'fil' ? 'Kama at Unan' : 'Kama ken Pango'),
          'roomIndex': 2, // Bedroom / Kwarto
          'question': _currentLang == 'en'
              ? 'Where do we rest and sleep at night?'
              : (_currentLang == 'fil'
                  ? 'Saan tayo nagpapahinga at natutulog sa gabi?'
                  : 'Adino ti pagturturogantayo no rabii?'),
        },
        {
          'itemEmoji': '🧼',
          'itemName': _currentLang == 'en'
              ? 'Soap and Shampoo'
              : (_currentLang == 'fil'
                  ? 'Sabon at Shampoo'
                  : 'Sabon ken Digos'),
          'roomIndex': 3, // Bathroom / Banyo
          'question': _currentLang == 'en'
              ? 'Where do we take a bath and wash ourselves?'
              : (_currentLang == 'fil'
                  ? 'Saan tayo naliligo at naghuhugas ng katawan?'
                  : 'Adino ti pagdigosantayo ken pagbugguantayo?'),
        },
        {
          'itemEmoji': '🌷',
          'itemName': _currentLang == 'en'
              ? 'Garden & Plants'
              : (_currentLang == 'fil'
                  ? 'Hardin at mga Halaman'
                  : 'Mulmula ken Ay-ayam'),
          'roomIndex': 4, // Yard / Bakuran
          'question': _currentLang == 'en'
              ? 'Where do we play outdoors and water the plants?'
              : (_currentLang == 'fil'
                  ? 'Saan tayo naglalaro sa labas at nagdidilig ng mga halaman?'
                  : 'Adino ti pagay-ayamantayo ken pagsibugantayo iti mulmula?'),
        },
      ];

  /// The items placed so far, by the room they went into.
  Map<int, List<String>> _placedSoFar(List challenges) {
    final placed = <int, List<String>>{};
    for (int c = 0; c < challenges.length; c++) {
      if (!_matchedHomeItems.contains(c)) continue;
      placed
          .putIfAbsent(challenges[c]['roomIndex'] as int, () => [])
          .add(challenges[c]['itemEmoji'] as String);
    }
    return placed;
  }

  Widget _buildMyHomeGame() {
    final challenges = _homeItemChallenges;
    final isFinished = _matchedHomeItems.length >= challenges.length;
    final safeIndex = _homeChallengeIndex.clamp(0, challenges.length - 1);
    final activeChallenge = challenges[safeIndex];

    // A house, drawn, with the rooms inside it.
    //
    // The rooms used to be a flat 2x3 grid of cards under a tall banner. The
    // banner and the step dots are fixed height, the grid took what was left,
    // and on a phone what was left was not enough for three rows — so the
    // cards overlapped each other and their captions ran out the sides. It
    // also asked a child to imagine that six rounded rectangles were a home.
    //
    // Now the rooms sit under a roof, inside walls, with the yard on the
    // grass below — and the banner has been flattened to a single row so the
    // house gets the height it needs.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Expanded(
          child: _gameCard(
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.house, color: _currentMainColor, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(AppLocalizations.of(context)!.ourHomeTitle,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _currentMainColor)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              // What to place, on one line. The stacked version of this card
              // was 190 pixels tall on its own — most of the board, spent on
              // one word and one question.
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFinished
                        ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
                        : [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Center(
                      child: ObjectPicture(
                          emoji: isFinished
                              ? '🏡'
                              : activeChallenge['itemEmoji'] as String,
                          size: 34),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isFinished
                              ? AppLocalizations.of(context)!.thatIsOurHome
                              : activeChallenge['itemName'],
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        if (!isFinished) ...[
                          const SizedBox(height: 2),
                          Text(
                            activeChallenge['question'],
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(challenges.length, (idx) {
                  final done = _matchedHomeItems.contains(idx);
                  final isCurrent = idx == _homeChallengeIndex && !isFinished;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isCurrent ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: done
                          ? Colors.green
                          : (isCurrent
                              ? AppColors.primary
                              : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: HomeHouse(
                  rooms: _homeRooms,
                  placed: _placedSoFar(challenges),
                  onRoomTap: _handleRoomTap,
                  ownLabels: _currentLang != 'en',
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
