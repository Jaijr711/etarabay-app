import 'package:e_tarabay/l10n/app_localizations.dart';
// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/custom_back_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../data/letter_tracing_data.dart';

import '../utils/constants.dart';
import '../utils/path_smoothing.dart';
import '../widgets/success_modal.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PROGRESS KEYS  (shared with for_parents_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
class SundanProgressKeys {
  // sundan_upper_A, sundan_upper_B … sundan_lower_a … sundan_num_1 …
  static String upperKey(String letter) => 'sundan_upper_$letter';
  static String lowerKey(String letter) => 'sundan_lower_$letter';
  static String numKey(String num) => 'sundan_num_$num';

  static const String totalAttempts = 'sundan_total_attempts';
  static const String totalCompleted = 'sundan_total_completed';
  static const String lastActivity = 'sundan_last_activity';
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONFETTI PARTICLE
// ─────────────────────────────────────────────────────────────────────────────
class _ConfettiParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  double opacity;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    this.opacity = 1.0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONFETTI PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LETTER TRACING PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class LetterTracingPainter extends CustomPainter {
  final List<Offset> guidePoints;
  final List<Offset> tracedPoints;
  final Color color;
  final bool isCompleted;
  final Set<int> visitedPoints;
  final double scale;
  final Offset offset;

  LetterTracingPainter({
    required this.guidePoints,
    required this.tracedPoints,
    required this.color,
    required this.isCompleted,
    required this.visitedPoints,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const userStroke = 24.0;

    // 1. User stroke
    if (tracedPoints.length >= 2) {
      canvas.drawPath(
        _buildPath(tracedPoints),
        Paint()
          ..color = isCompleted ? Colors.green : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = userStroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  Path _buildPath(List<Offset> pts) {
    if (pts.length < 2) return Path();
    return smoothPolylinePath(pts);
  }

  @override
  bool shouldRepaint(LetterTracingPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SundanScreen extends StatefulWidget {
  const SundanScreen({super.key});

  @override
  State<SundanScreen> createState() => _SundanScreenState();
}

class _SundanScreenState extends State<SundanScreen>
    with TickerProviderStateMixin {
  // ── UI state ───────────────────────────────────────────────────────────────
  int _selectedMode = 0; // 0=Uppercase, 1=Lowercase, 2=Numbers
  int _selectedIndex = 0;
  int _score = 0;
  int _stars = 0;

  // ── Tracing state ──────────────────────────────────────────────────────────
  List<Offset> _tracedPoints = [];
  bool _isCompleted = false;
  Set<int> _visitedPoints =
      {}; // Using set for order-independent (but proximity-based) progress
  bool _outOfBounds = false;
  int _wrongAttempts = 0;

  // Store kid's drawing per letter so they can review it later
  final Map<int, List<Offset>> _completedTraces = {};

  // ── Feedback ───────────────────────────────────────────────────────────────
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.transparent;

  // ── Canvas transform ────────────────────────────────────────────────────────
  double _canvasScale = 1.0;
  Offset _canvasOffset = Offset.zero;
  Size _canvasSize = Size.zero;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late AnimationController _confettiController;
  late AnimationController _warningController;
  late Animation<double> _warningAnimation;

  late PageController _pageController;

  final List<_ConfettiParticle> _confettiParticles = [];
  final Random _rng = Random();

  static const double _hitRadius = 18.0;

  SharedPreferences? _prefs;

  final Set<int> _completedUpper = {};
  final Set<int> _completedLower = {};
  final Set<int> _completedNums = {};

  // ─────────────────────────────────────────────────────────────────────────
  //  Letter data
  // ─────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────
  //  Getters
  // ─────────────────────────────────────────────────────────────────────────

  List<LetterData> get _currentLetters {
    if (_selectedMode == 0) return uppercaseLetters;
    if (_selectedMode == 1) return lowercaseLetters;
    return numberLetters;
  }

  LetterData get _currentLetter => _currentLetters[_selectedIndex];

  Set<int> get _currentCompletedSet {
    if (_selectedMode == 0) return _completedUpper;
    if (_selectedMode == 1) return _completedLower;
    return _completedNums;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProgress();

    _successController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut));

    _confettiController = AnimationController(
        duration: const Duration(milliseconds: 2500), vsync: this)
      ..addListener(_updateConfetti);

    _warningController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _warningAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _warningController, curve: Curves.easeInOut));

    _pageController = PageController(initialPage: _selectedIndex);

    _loadProgress();
    _initSmartResume();
  }

  Future<void> _initSmartResume() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      int retryCount = 0;
      while (!userProvider.isInitialized && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
      }

      // Mode 0=Upper, 1=Lower, 2=Numbers
      int targetMode = 0;
      int targetIndex = 0;
      bool found = false;

      // Mode 0: Uppercase (A-Z)
      for (int i = 0; i < 26; i++) {
        if (!userProvider.isTraceItActivityCompleted('uppercase', i)) {
          targetMode = 0;
          targetIndex = i;
          found = true;
          break;
        }
      }

      if (!found) {
        // Mode 1: Lowercase (a-z)
        for (int i = 0; i < 26; i++) {
          if (!userProvider.isTraceItActivityCompleted('lowercase', i)) {
            targetMode = 1;
            targetIndex = i;
            found = true;
            break;
          }
        }
      }

      if (!found) {
        // Mode 2: Numbers (1-10)
        for (int i = 0; i < 10; i++) {
          if (!userProvider.isTraceItActivityCompleted('numbers', i)) {
            targetMode = 2;
            targetIndex = i;
            found = true;
            break;
          }
        }
      }

      // If all completed, default to the last mode/item
      if (!found) {
        targetMode = 2;
        targetIndex = 9;
      }

      if (mounted) {
        setState(() {
          _selectedMode = targetMode;
          _selectedIndex = targetIndex;
          _pageController = PageController(initialPage: _selectedIndex);
          _resetTracing();
        });
      }
    } catch (e) {
      debugPrint('Sundan Smart Resume failed: $e');
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    _confettiController.dispose();
    _warningController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Progress persistence
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadProgress() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedUpper.clear();
      _completedLower.clear();
      _completedNums.clear();

      for (int i = 0; i < uppercaseLetters.length; i++) {
        final k = SundanProgressKeys.upperKey(uppercaseLetters[i].letter);
        if (_prefs!.getBool(k) == true) {
          _completedUpper.add(i);
        }
      }
      for (int i = 0; i < lowercaseLetters.length; i++) {
        final k = SundanProgressKeys.lowerKey(lowercaseLetters[i].letter);
        if (_prefs!.getBool(k) == true) {
          _completedLower.add(i);
        }
      }
      for (int i = 0; i < numberLetters.length; i++) {
        final k = SundanProgressKeys.numKey(numberLetters[i].letter);
        if (_prefs!.getBool(k) == true) {
          _completedNums.add(i);
        }
      }
    });
  }

  void _syncToUserProvider(int modeIndex, int letterIndex) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String modeKey = modeIndex == 0
        ? 'uppercase'
        : modeIndex == 1
            ? 'lowercase'
            : 'numbers';
    userProvider.updateTraceItProgress(modeKey, letterIndex, true);
  }

  Future<void> _saveLetterComplete(int modeIndex, int letterIndex) async {
    if (_prefs == null) return;
    String key;
    if (modeIndex == 0) {
      key = SundanProgressKeys.upperKey(uppercaseLetters[letterIndex].letter);
    } else if (modeIndex == 1) {
      key = SundanProgressKeys.lowerKey(lowercaseLetters[letterIndex].letter);
    } else {
      key = SundanProgressKeys.numKey(numberLetters[letterIndex].letter);
    }
    // Check completion BEFORE writing so replay doesn't inflate totals
    final alreadyDone = _prefs!.getBool(key) == true;
    await _prefs!.setBool(key, true);
    final attempts =
        (_prefs!.getInt(SundanProgressKeys.totalAttempts) ?? 0) + 1;
    await _prefs!.setInt(SundanProgressKeys.totalAttempts, attempts);
    if (!alreadyDone) {
      final completed =
          (_prefs!.getInt(SundanProgressKeys.totalCompleted) ?? 0) + 1;
      await _prefs!.setInt(SundanProgressKeys.totalCompleted, completed);
    }

    final modeName = modeIndex == 0
        ? 'Uppercase'
        : modeIndex == 1
            ? 'Lowercase'
            : 'Numbers';
    final letter = modeIndex == 0
        ? uppercaseLetters[letterIndex].letter
        : modeIndex == 1
            ? lowercaseLetters[letterIndex].letter
            : numberLetters[letterIndex].letter;
    await _prefs!
        .setString(SundanProgressKeys.lastActivity, '$modeName: $letter');

    _syncToUserProvider(modeIndex, letterIndex);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Canvas transform
  // ─────────────────────────────────────────────────────────────────────────

  void _computeTransform(Size canvasSize) {
    if (_canvasSize == canvasSize) return;
    _canvasSize = canvasSize;
    const designW = 300.0;
    const designH = 260.0; // Increased design height to prevent clipping
    const padding = 20.0; // Increased padding for safety
    final scaleX = (canvasSize.width - padding * 2) / designW;
    final scaleY = (canvasSize.height - padding * 2) / designH;
    _canvasScale = (scaleX < scaleY
        ? scaleX
        : scaleY); // Removed the 1.15 multiplier to keep it in view
    _canvasOffset = Offset(
      (canvasSize.width - designW * _canvasScale) / 2,
      (canvasSize.height - designH * _canvasScale) / 2,
    );
  }

  Offset _toDesign(Offset screen) => Offset(
        (screen.dx - _canvasOffset.dx) / _canvasScale,
        (screen.dy - _canvasOffset.dy) / _canvasScale,
      );

  Offset _toScreen(Offset design) => Offset(
        design.dx * _canvasScale + _canvasOffset.dx,
        design.dy * _canvasScale + _canvasOffset.dy,
      );

  void _onPanStart(DragStartDetails d) {
    if (_canvasSize == Size.zero) return;
    if (_isCompleted) {
      _showFeedback(AppLocalizations.of(context)!.doneAlready, Colors.green);
      return;
    }
    final designPt = _toDesign(d.localPosition);

    // Free-draw mode: child can start anywhere on the canvas
    setState(() {
      // Break marker for multi-stroke (prevents connecting line between strokes)
      if (_tracedPoints.isNotEmpty) {
        _tracedPoints.add(const Offset(double.nan, double.nan));
      }
      _tracedPoints.add(_toScreen(designPt));
      _outOfBounds = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isCompleted || _tracedPoints.isEmpty) return;
    final designPt = _toDesign(d.localPosition);
    final screenPt = _toScreen(designPt);
    final pts = _currentLetter.points;

    // Free-draw mode: mark ANY nearby guide point as visited (no order restriction)
    for (int i = 0; i < pts.length; i++) {
      double dist = (designPt - pts[i]).distance;
      double dynamicRadius =
          _hitRadius * (1.1 + (4 - _currentLetter.difficulty) * 0.12);
      if (dist <= dynamicRadius) {
        _visitedPoints.add(i);
      }
    }

    setState(() {
      _outOfBounds = false;

      if (_tracedPoints.isEmpty ||
          (screenPt - _tracedPoints.last).distance > 2.0) {
        _tracedPoints.add(screenPt);
      }
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_isCompleted) return;
    setState(() => _outOfBounds = false);
  }

  /// Computes a smart score: coverage of guide points + proximity of drawn path.
  /// Returns 0.0–1.0.  Weighted: 65% coverage, 35% proximity.
  double _computeSmartScore() {
    final pts = _currentLetter.points;
    if (_tracedPoints.length < 3) return 0.0;

    // 1. Coverage: what % of guide points were passed near
    double coverage = _visitedPoints.length / pts.length;

    // 2. Proximity: are user strokes near the guide path?
    final validPoints =
        _tracedPoints.where((p) => !p.dx.isNaN && !p.dy.isNaN).toList();
    if (validPoints.isEmpty) return 0.0;

    int nearCount = 0;
    for (final screenPt in validPoints) {
      final designPt = _toDesign(screenPt);
      double minDist = double.infinity;
      for (final gp in pts) {
        final d = (designPt - gp).distance;
        if (d < minDist) minDist = d;
      }
      if (minDist <= _hitRadius * 2.5) nearCount++;
    }
    double proximity = nearCount / validPoints.length;

    return (coverage * 0.65) + (proximity * 0.35);
  }

  void _checkTracing() {
    if (_isCompleted || _tracedPoints.length < 3) return;
    final score = _computeSmartScore();
    if (score >= 0.55) {
      _completeTracing();
    } else {
      _triggerWarning(AppLocalizations.of(context)!.almostThere);
    }
  }

  void _resetTracing() {
    setState(() {
      _tracedPoints = [];
      // CORRECT: Check against the fresh completed sets
      _isCompleted = _currentCompletedSet.contains(_selectedIndex);
      _visitedPoints = {};
      _outOfBounds = false;
      _wrongAttempts = 0;
      _canvasSize = Size.zero;
    });
    _confettiParticles.clear();
    _successController.reset();
    _confettiController.stop();
  }

  void _completeTracing() {
    if (_isCompleted) return;
    setState(() {
      _isCompleted = true;
      _score += 10;
      _stars += 3;
    });

    // Mark this letter/number as done
    _currentCompletedSet.add(_selectedIndex);
    _saveLetterComplete(_selectedMode, _selectedIndex);

    _successController.forward(from: 0);
    _spawnConfetti();
    _showFeedback(
        AppLocalizations.of(context)!.goodJobPoints(10), Colors.green);

    // Store the kid's drawing for review
    _completedTraces[_selectedIndex] = List.from(_tracedPoints);

    if (_currentCompletedSet.length >= _currentLetters.length) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showCompletionDialog();
      });
    }
  }

  void _triggerWarning(String msg) {
    _warningController
        .forward(from: 0)
        .then((_) => _warningController.reverse());
    _showFeedback(msg, Colors.orange);

    setState(() {
      _wrongAttempts++;
    });

    if (_wrongAttempts >= 5) {
      _showFeedback(AppLocalizations.of(context)!.tooHardSwitch, Colors.blue);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Confetti
  // ─────────────────────────────────────────────────────────────────────────

  void _spawnConfetti() {
    _confettiParticles.clear();
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.cyan
    ];
    final cx = _canvasSize.width / 2;
    final cy = _canvasSize.height / 3;
    for (int i = 0; i < 60; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 3.0 + _rng.nextDouble() * 5;
      _confettiParticles.add(_ConfettiParticle(
        position: Offset(cx, cy),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 6),
        color: colors[_rng.nextInt(colors.length)],
        size: 8 + _rng.nextDouble() * 8,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.3,
        opacity: 1.0,
      ));
    }
    _confettiController.forward(from: 0);
  }

  void _onPageChanged(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
        _isCompleted = _currentCompletedSet.contains(index);
        if (_isCompleted && _completedTraces.containsKey(index)) {
          _tracedPoints = List.from(_completedTraces[index]!);
          _visitedPoints = {};
        } else {
          _tracedPoints = [];
          _visitedPoints = {};
        }
        _outOfBounds = false;
        _wrongAttempts = 0;
        _canvasSize = Size.zero;
      });
      _confettiParticles.clear();
      _successController.reset();
      _confettiController.stop();
    }
  }

  void _updateConfetti() {
    if (!mounted) return;
    setState(() {
      for (final p in _confettiParticles) {
        p.position += p.velocity;
        p.velocity = Offset(p.velocity.dx * 0.98, p.velocity.dy + 0.25);
        p.rotation += p.rotationSpeed;
        p.opacity = (1.0 - _confettiController.value).clamp(0.0, 1.0);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Feedback & Dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _showFeedback(String message, Color color) {
    setState(() {
      _feedbackMessage = message;
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

  void _showCompletionDialog() {
    final modeName = _selectedMode == 0
        ? AppLocalizations.of(context)!.uppercase
        : _selectedMode == 1
            ? AppLocalizations.of(context)!.lowercase
            : AppLocalizations.of(context)!.numbers;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessModal(
        title: AppLocalizations.of(context)!.iKnowIt,
        subtitle: AppLocalizations.of(context)!.categoryCompleted(modeName),
        score: _score,
        stars: 3,
        primaryLabel: AppLocalizations.of(context)!.continueText,
        onPrimaryTap: () => Navigator.pop(context),
        secondaryLabel: AppLocalizations.of(context)!.ulitin,
        onSecondaryTap: () {
          Navigator.pop(context);
          _resetTracing();
          setState(() => _selectedIndex = 0);
        },
        mainColor: AppColors.primary,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Real-time account deletion check
    if (userProvider.isAccountDeleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CustomBackButton(
          iconColor: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.surotemKabaelam,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
              const SizedBox(width: 4),
              Text('$_stars',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF1F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildModeTab(0, 'ABC', AppLocalizations.of(context)!.upper)),
                    Expanded(child: _buildModeTab(1, 'abc', AppLocalizations.of(context)!.lower)),
                    Expanded(child: _buildModeTab(
                        2, '123', AppLocalizations.of(context)!.numbers)),
                  ]),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FE), Color(0xFFEDF1F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _currentLetter.color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _currentLetter.color, width: 2),
              ),
              child: Center(
                  child: Text(_currentLetter.letter,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _currentLetter.color))),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      AppLocalizations.of(context)!
                          .letterLabel(_currentLetter.letter),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('${_currentLetter.example} • "${_currentLetter.sound}"',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ])),
            // Completed count chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${_currentCompletedSet.length}/${_currentLetters.length} ✓',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Column(children: [
              Text(AppLocalizations.of(context)!.pointsLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text('$_score',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ]),
          ]),
        ),

        // Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${_selectedIndex + 1} / ${_currentLetters.length}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600)),
          ]),
        ),

        // Canvas
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _currentLetters.length,
            physics: _currentCompletedSet.contains(_selectedIndex)
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final letter = _currentLetters[index];
              return Center(
                child: AnimatedBuilder(
                  animation: _warningAnimation,
                  builder: (_, child) => Container(
                    width: size.width * 0.88,
                    height: size.width * 0.88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: _outOfBounds && _selectedIndex == index
                          ? Border.all(
                              color: Colors.orange.withOpacity(
                                  0.6 + _warningAnimation.value * 0.4),
                              width: 3)
                          : Border.all(color: Colors.grey.shade100, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _isCompleted && _selectedIndex == index
                              ? Colors.green.withOpacity(0.25)
                              : letter.color.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: LayoutBuilder(builder: (_, constraints) {
                      final cs =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      _computeTransform(cs);
                      return GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Stack(fit: StackFit.expand, children: [
                          // Letter reference
                          Center(
                              child: Opacity(
                                  opacity: 0.06,
                                  child: Text(letter.letter,
                                      style: TextStyle(
                                          fontSize: 220 * _canvasScale,
                                          fontWeight: FontWeight.bold,
                                          color: letter.color)))),
                          // Tracing
                          CustomPaint(
                            painter: LetterTracingPainter(
                              guidePoints: letter.points,
                              tracedPoints: _selectedIndex == index
                                  ? _tracedPoints
                                  : [], // Only show tracing on active page
                              color: letter.color,
                              isCompleted: _currentCompletedSet.contains(index),
                              visitedPoints:
                                  _selectedIndex == index ? _visitedPoints : {},
                              scale: _canvasScale,
                              offset: _canvasOffset,
                            ),
                          ),
                          // Confetti
                          if (_confettiParticles.isNotEmpty &&
                              _selectedIndex == index)
                            CustomPaint(
                                painter: _ConfettiPainter(_confettiParticles)),
                          // Success overlay (Moved to bottom of canvas)
                          if (_isCompleted && _selectedIndex == index)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.green.withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 2)
                                    ],
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.circle_check,
                                            color: Colors.white, size: 28),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .goodJob,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                ),
                              ),
                            ),
                        ]),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),

        // Feedback banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _feedbackMessage.isEmpty ? 0 : 48,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: _feedbackColor, borderRadius: BorderRadius.circular(12)),
          child: _feedbackMessage.isEmpty
              ? const SizedBox.shrink()
              : Text(_feedbackMessage,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis),
        ),

        // Check & Reset buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCompleted ? null : _checkTracing,
                  icon: const Icon(LucideIcons.circle_check),
                  label: Text(AppLocalizations.of(context)!.checkTracing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetTracing,
                  icon: const Icon(LucideIcons.refresh_cw),
                  label: Text(AppLocalizations.of(context)!.ulitin),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
      ),
    );
  }

  Widget _buildModeTab(int index, String icon, String label) {
    final isSelected = _selectedMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = index;
          _selectedIndex = 0;
          _resetTracing();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
