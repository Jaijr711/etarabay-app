import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/letter_tracing_data.dart';
import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../utils/path_smoothing.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/question_cloud.dart' show DoodleBackground;
import '../widgets/success_modal.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HIDDEN-GUIDE TRACING PAINTER
// ─────────────────────────────────────────────────────────────────────────────

/// Width of the drawn stroke track, per unit of canvas scale.
///
/// Shared between the layout maths and the painter so the two can never
/// disagree about how much room the ink actually needs.
const double _kTrackWidth = 26.0;

// ─────────────────────────────────────────────────────────────────────────────
//  POLYLINE MATH (shared by the drag-to-fill painter and gesture logic)
// ─────────────────────────────────────────────────────────────────────────────

/// Projects [p] onto the polyline, returning how far along the path the nearest
/// point is (progress 0..1) and the perpendicular distance to the path.
({double progress, double distance}) _projectOntoPolyline(
    List<Offset> pts, Offset p) {
  if (pts.isEmpty) return (progress: 0.0, distance: double.infinity);
  if (pts.length < 2) {
    return (progress: 0.0, distance: (p - pts.first).distance);
  }
  final total = polylineLength(pts);
  double acc = 0, bestDist = double.infinity, bestProg = 0;
  for (int i = 1; i < pts.length; i++) {
    final a = pts[i - 1];
    final b = pts[i];
    final seg = (b - a).distance;
    if (seg == 0) continue;
    final abx = b.dx - a.dx, aby = b.dy - a.dy;
    double t = ((p.dx - a.dx) * abx + (p.dy - a.dy) * aby) / (seg * seg);
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + abx * t, a.dy + aby * t);
    final d = (p - proj).distance;
    if (d < bestDist) {
      bestDist = d;
      bestProg = total > 0 ? (acc + seg * t) / total : 0.0;
    }
    acc += seg;
  }
  return (progress: bestProg, distance: bestDist);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAG-TO-FILL PAINTER (uppercase letters)
// ─────────────────────────────────────────────────────────────────────────────
//
//  Renders each stroke of an uppercase letter as a light "track", fills the
//  completed portion in the letter's color as the child drags, and marks the
//  active stroke's start with a numbered, pulsing dot + direction arrow. No
//  image or SVG assets — pure CustomPainter drawing from the stroke skeletons.
class _StrokeFillPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<double> strokeProgress;
  final int activeStroke;
  final Color color;
  final bool isCompleted;
  final double scale;
  final Offset offset;
  final double? guideProgress;

  /// The twinkle on the star waiting at the end of the last stroke.
  final Animation<double> starPulse;

  /// Runs 0 to 1 once the character is finished, as the star is collected.
  final Animation<double> collect;

  _StrokeFillPainter({
    required this.strokes,
    required this.strokeProgress,
    required this.activeStroke,
    required this.color,
    required this.isCompleted,
    required this.scale,
    required this.offset,
    required this.starPulse,
    required this.collect,
    this.guideProgress,
  }) :
        // Both animations drive the canvas directly. Driving them through
        // `setState` instead would rebuild the whole screen sixty times a
        // second to move one star.
        super(repaint: Listenable.merge([starPulse, collect]));

  Offset _toScreen(Offset d) =>
      Offset(d.dx * scale + offset.dx, d.dy * scale + offset.dy);

  Path _screenPath(List<Offset> designPts) {
    if (designPts.isEmpty) return Path();
    return smoothPolylinePath([for (final p in designPts) _toScreen(p)]);
  }

  /// Draws [path] as a dashed line using its path metrics.
  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dash = 9, double gap = 7}) {
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = math.min(dist + dash, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final trackWidth = _kTrackWidth * scale;
    final fillWidth = (_kTrackWidth - 2.0) * scale;

    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillColor = isCompleted ? const Color(0xFF4CAF50) : color;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = fillWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. All stroke tracks (background).
    for (final stroke in strokes) {
      canvas.drawPath(_screenPath(stroke), trackPaint);
    }

    // 1b. Dashed centerline guide inside each track so the child sees the
    // path to follow. The fill drawn next covers the dashes as they trace.
    final guidePaint = Paint()
      ..color =
          (isCompleted ? const Color(0xFF4CAF50) : color).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;
    for (final stroke in strokes) {
      _drawDashedPath(canvas, _screenPath(stroke), guidePaint,
          dash: 9.0 * scale, gap: 7.0 * scale);
    }

    // 2. Filled portions.
    for (int i = 0; i < strokes.length; i++) {
      final prog = i < strokeProgress.length ? strokeProgress[i] : 0.0;
      if (prog <= 0) continue;
      final filled = partialPolyline(strokes[i], prog);
      if (filled.length >= 2) {
        canvas.drawPath(_screenPath(filled), fillPaint);
      } else if (filled.isNotEmpty) {
        canvas.drawCircle(
            _toScreen(filled.first), fillWidth / 2, Paint()..color = fillColor);
      }
    }

    // 3. The handle the child pulls: the numbered dot.
    //
    // It used to be nailed to the start of the stroke while the colour filled
    // in underneath it, so nothing on screen followed the finger. Now it sits
    // at the head of the fill — the child drags the number itself along the
    // letter, and the arrow ahead of it keeps pointing at where to go next
    // rather than where they began.
    if (!isCompleted && activeStroke >= 0 && activeStroke < strokes.length) {
      final stroke = strokes[activeStroke];
      if (stroke.isNotEmpty) {
        final done = strokeProgress[activeStroke].clamp(0.0, 1.0);
        final at = _toScreen(partialPolyline(stroke, done).last);
        // A little further along the stroke, so the arrow points forward.
        final ahead =
            _toScreen(partialPolyline(stroke, math.min(1.0, done + 0.06)).last);
        double angle = math.pi / 2;
        if ((ahead - at).distance > 0.5) {
          angle = math.atan2(ahead.dy - at.dy, ahead.dx - at.dx);
        } else if (stroke.length > 1) {
          final n = _toScreen(stroke[1]);
          angle = math.atan2(n.dy - at.dy, n.dx - at.dx);
        }
        _drawHandle(canvas, at, angle, activeStroke + 1);
      }
    }

    // 4. The star, waiting at the very end of the last stroke.
    //
    // It appears only once the child reaches the final stroke, so it reads as
    // the thing they are about to earn rather than as decoration that was
    // always there. The handle drags towards it; finishing collects it.
    if (strokes.isNotEmpty && strokes.last.isNotEmpty) {
      final goal = _toScreen(strokes.last.last);

      if (!isCompleted && activeStroke == strokes.length - 1) {
        final done = strokeProgress[activeStroke].clamp(0.0, 1.0);
        final handle = _toScreen(partialPolyline(strokes.last, done).last);
        // Six characters end where their last stroke began: O, o, 8 and 10
        // are closed loops, and on i and j the last stroke is only the tittle.
        // Drawing the star under the handle on those would show it already
        // collected before the child had moved at all. It appears once they
        // have travelled away from it — which on a closed letter is exactly
        // the right lesson: come back round to where you started.
        if ((handle - goal).distance >= 24) {
          final beat = 1.0 + 0.12 * math.sin(starPulse.value * math.pi * 2);
          _drawStar(canvas, goal, 15 * beat, 1.0);
        }
      }

      // Collected: it swells and fades out where it stood. At 1 it is gone,
      // which is why a finished character carries no star — the child has it.
      final c = collect.value;
      if (isCompleted && c > 0 && c < 1) {
        _drawStar(canvas, goal, 15 * (1 + c * 1.4), 1 - c);
      }
    }
  }

  /// A five-pointed star, drawn rather than typed.
  ///
  /// A ★ from a font is a different shape on every phone — the same reason
  /// the objects a child counts stopped being emoji.
  void _drawStar(Canvas canvas, Offset c, double r, double opacity) {
    final path = Path();
    const points = 5;
    final inner = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final p =
          Offset(c.dx + math.cos(a) * radius, c.dy + math.sin(a) * radius);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawCircle(c, r * 1.5,
        Paint()..color = const Color(0xFFFFC107).withOpacity(0.22 * opacity));
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(
        path, Paint()..color = const Color(0xFFFFB300).withOpacity(opacity));
  }

  void _drawHandle(Canvas canvas, Offset at, double angle, int number) {
    // With the text nudge gone, this halo is the whole instruction — it
    // needs to read as "tap here" on its own, so the swing is bigger than
    // the guide-demo pulse used to need.
    final beat = guideProgress != null && guideProgress! >= 0
        ? math.sin(guideProgress! * math.pi * 2)
        : 0.0;
    final pulse = 1.0 + 0.35 * beat;
    final haloOpacity = 0.22 + 0.2 * (beat * 0.5 + 0.5);

    final arrowPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dir = Offset(math.cos(angle), math.sin(angle));
    final base = at + dir * 20;
    final tip = at + dir * 38;
    canvas.drawLine(base, tip, arrowPaint);
    final head1 =
        tip + Offset(math.cos(angle + 2.5), math.sin(angle + 2.5)) * 9;
    final head2 =
        tip + Offset(math.cos(angle - 2.5), math.sin(angle - 2.5)) * 9;
    canvas.drawLine(tip, head1, arrowPaint);
    canvas.drawLine(tip, head2, arrowPaint);

    canvas.drawCircle(
        at, 16 * pulse, Paint()..color = Colors.green.withOpacity(haloOpacity));
    canvas.drawCircle(at, 11, Paint()..color = const Color(0xFF2E7D32));
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_StrokeFillPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TraceItScreen extends StatefulWidget {
  const TraceItScreen({super.key});

  @override
  State<TraceItScreen> createState() => _TraceItScreenState();
}

class _TraceItScreenState extends State<TraceItScreen>
    with TickerProviderStateMixin {
  // ── UI state ───────────────────────────────────────────────────────────────
  int _selectedMode = 0; // 0=Uppercase, 1=Lowercase, 2=Numbers
  int _selectedIndex = 0;
  int _score = 0;

  // Same points-per-star rate the other modules use, so a star is worth the
  // same everywhere and the totals a teacher compares stay meaningful.
  static const int _pointsPerStar = 10;

  /// A traced letter or number is worth one star. The unit here is a single
  /// character, and there are 62 of them — rating each one out of three would
  /// make Trace It worth more than every other module combined.
  static const int _starsPerLetter = 1;

  // ── Tracing state ──────────────────────────────────────────────────────────
  bool _isCompleted = false;

  // Grid-based overlap detection – each cell counts stroke pass-throughs

  // Store kid's drawing per letter so they can review it later

  // ── Canvas transform ───────────────────────────────────────────────────────
  double _canvasScale = 1.0;
  Offset _canvasOffset = Offset.zero;
  Size _canvasSize = Size.zero;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late AnimationController _warningController;
  late Animation<double> _warningAnimation;
  late PageController _pageController;

  // Guide dot animation
  late AnimationController _guideController;
  double _guideProgress = -1; // -1 = inactive, 0-1 = active

  // ── Letting go before the stroke is finished ──────────────────────────────
  //
  // A stroke is one movement, so a half-drawn one is not kept. The number
  // slides back to the start dot and the colour drains out behind it, which
  // shows the child what happened instead of just deleting their work.
  late AnimationController _rewindController;
  double _rewindFrom = 0;

  /// The star's twinkle. Repeats for as long as the screen is open; it drives
  /// the canvas on its own rather than through the widget tree.
  late AnimationController _starController;

  final Set<int> _completedUpper = {};
  final Set<int> _completedLower = {};
  final Set<int> _completedNums = {};

  // ── Drag-to-fill state (uppercase letters) ─────────────────────────────────
  List<List<Offset>> _strokes = [];
  List<double> _strokeProgress = [];
  int _activeStroke = 0;
  bool _dragging = false;
  // Design-space thresholds (same ~300x260 space as the stroke skeletons).
  static const double _startZoneRadius = 30.0;
  // How far the finger may stray from the centre of the stroke.
  //
  // It was 42, and the drawn line is only 26 wide — the child could be a
  // whole line-width outside the ink and still be counted as tracing. That is
  // what let them cut corners: on an L, a straight diagonal from the top to
  // the end of the foot never comes closer than 30 to the corner, so at 42 it
  // passed and the corner was never drawn.
  //
  // One line-width from the centre instead. The rule the child can see is now
  // the rule being applied: keep your finger on the line.
  static const double _pathTolerance = _kTrackWidth;

  // How far ahead of where they have got the child may be matched, in design
  // units. Roughly two line-widths — enough that a quick drag is not lost,
  // short enough that the far side of a loop is out of reach.
  static const double _lookAheadUnits = 55.0;
  static const double _strokeCompleteThreshold = 0.85;
  // Cap how far progress can jump in a single drag update. This forces the
  // child to actually drag ALONG the stroke instead of jumping the finger to
  // the end — important for self-touching paths like O, 8, g, 6 and 9 where
  // the start and end points are near each other.
  static const double _maxProgressStep = 0.12;

  // Enlarge the drawn letter by scaling the skeleton around the glyph center.
  // Applied consistently to both rendering and drag hit-testing so they align.
  static const double _letterMagnify = 1.35;
  static const Offset _glyphCenter = Offset(150, 120);

  /// Enlarges a character and squares it up in the middle of the canvas.
  ///
  /// Every character is centred on both axes, on its own. 49 of the 63 were
  /// authored off-centre horizontally — 'J', 'K', 'r' and '1' by a full 11
  /// units — and the lowercase set was worse vertically still, with 'b' and
  /// 'd' sitting 30 units high and 'p', 'q', 'y' 24 units low.
  ///
  /// An earlier version deliberately left the vertical offsets alone, to keep
  /// the fact that some letters reach up and others hang below the line. That
  /// was the wrong call here: the canvas shows one character by itself, with
  /// no baseline and no neighbours, so there is nothing for a letter to sit
  /// high or low *against*. The offset taught nothing and simply looked
  /// crooked.
  ///
  /// What does survive is relative size, which is untouched: 'l' is still 120
  /// units tall against 68 for 'a', so a tall letter still looks tall.
  /// Restoring the positional meaning would mean drawing the three writing
  /// guide lines to measure it against — a separate change.
  List<List<Offset>> _magnify(List<List<Offset>> strokes) {
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final stroke in strokes) {
      for (final p in stroke) {
        if (p.dx.isNaN || p.dy.isNaN) continue;
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    final double dx = minX.isFinite ? _glyphCenter.dx - (minX + maxX) / 2 : 0.0;
    final double dy = minY.isFinite ? _glyphCenter.dy - (minY + maxY) / 2 : 0.0;

    return [
      for (final stroke in strokes)
        [
          for (final p in stroke)
            // Pen-lift separators carry no position; passing one through the
            // arithmetic would turn it into an ordinary point and draw a line
            // across the gap it exists to create.
            (p.dx.isNaN || p.dy.isNaN)
                ? p
                : Offset(
                    _glyphCenter.dx +
                        (p.dx + dx - _glyphCenter.dx) * _letterMagnify,
                    _glyphCenter.dy +
                        (p.dy + dy - _glyphCenter.dy) * _letterMagnify,
                  )
        ]
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Getters
  // ─────────────────────────────────────────────────────────────────────────

  List<LetterData> get _currentLetters {
    if (_selectedMode == 0) return uppercaseLetters;
    if (_selectedMode == 1) return lowercaseLetters;
    return numberLetters;
  }

  LetterData get _currentLetter => _currentLetters[_selectedIndex];

  /// (Re)initialise the drag-to-fill stroke state for the current letter.
  void _initStrokes() {
    final raw = strokesForMode(_selectedMode, _currentLetter.letter);
    if (raw == null) {
      _strokes = [];
      _strokeProgress = [];
      _activeStroke = 0;
      _dragging = false;
      return;
    }
    _strokes = _magnify(raw);
    _dragging = false;
    if (_currentCompletedSet.contains(_selectedIndex)) {
      _strokeProgress = List<double>.filled(_strokes.length, 1.0);
      _activeStroke = _strokes.length;
    } else {
      _strokeProgress = List<double>.filled(_strokes.length, 0.0);
      _activeStroke = 0;
    }
  }

  Set<int> get _currentCompletedSet {
    if (_selectedMode == 0) return _completedUpper;
    if (_selectedMode == 1) return _completedLower;
    return _completedNums;
  }

  /// The furthest letter the student is allowed to reach: every completed
  /// letter plus the single next one they still need to trace. They can go
  /// back to finished letters but cannot skip ahead to ones "not yet present",
  /// so they can't randomly trace whatever they want.
  int get _maxReachableIndex {
    for (int i = 0; i < _currentLetters.length; i++) {
      if (!_currentCompletedSet.contains(i)) return i;
    }
    return _currentLetters.length - 1;
  }

  void _goToLetter(int index) {
    if (index < 0 || index >= _currentLetters.length) return;
    if (index > _maxReachableIndex) return; // cannot skip ahead
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playModuleMusic(ModuleMusic.traceIt);

    _successController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut));

    _warningController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _warningAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _warningController, curve: Curves.easeInOut));

    _pageController = PageController(initialPage: _selectedIndex);

    _guideController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _guideController.addListener(() {
      if (mounted) setState(() => _guideProgress = _guideController.value);
    });

    _starController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _rewindController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _rewindController.addListener(() {
      if (!mounted || _activeStroke >= _strokeProgress.length) return;
      final t = Curves.easeOutCubic.transform(_rewindController.value);
      setState(() => _strokeProgress[_activeStroke] = _rewindFrom * (1 - t));
    });
    _rewindController.addStatusListener((status) {
      // Back at the start, so the dot pulses again — that is where the next
      // try begins.
      if (status == AnimationStatus.completed && mounted && !_isCompleted) {
        _guideController
          ..reset()
          ..repeat();
      }
    });

    _initStrokes();
    _loadEarnedTotals();
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

      int targetMode = 0;
      int targetIndex = 0;
      bool found = false;

      for (int i = 0; i < uppercaseLetters.length; i++) {
        if (!userProvider.isTraceItActivityCompleted('uppercase', i)) {
          targetMode = 0;
          targetIndex = i;
          found = true;
          break;
        }
      }

      if (!found) {
        for (int i = 0; i < lowercaseLetters.length; i++) {
          if (!userProvider.isTraceItActivityCompleted('lowercase', i)) {
            targetMode = 1;
            targetIndex = i;
            found = true;
            break;
          }
        }
      }

      if (!found) {
        for (int i = 0; i < numberLetters.length; i++) {
          if (!userProvider.isTraceItActivityCompleted('numbers', i)) {
            targetMode = 2;
            targetIndex = i;
            found = true;
            break;
          }
        }
      }

      if (!found) {
        targetMode = 2;
        targetIndex = 9;
      }

      if (mounted) {
        setState(() {
          _selectedMode = targetMode;
          _selectedIndex = targetIndex;
          _resetTracing();
        });
        // Sync the PageView to the resumed letter via jumpToPage. Recreating
        // the controller here would NOT move the viewport (Flutter transfers
        // the old scroll position to the new controller), which desynced the
        // page from _selectedIndex.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _pageController.hasClients &&
              _pageController.page?.round() != targetIndex) {
            _pageController.jumpToPage(targetIndex);
          }
        });
      }
    } catch (e) {
      debugPrint('TraceIt Smart Resume failed: $e');
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    _warningController.dispose();
    _pageController.dispose();
    _guideController.dispose();
    _rewindController.dispose();
    _starController.dispose();
    AudioManager.instance.resumeHomeMusic();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Progress persistence
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadProgress() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isInitialized) return;

    setState(() {
      _completedUpper.clear();
      _completedLower.clear();
      _completedNums.clear();

      for (int i = 0; i < uppercaseLetters.length; i++) {
        if (userProvider.isTraceItActivityCompleted('uppercase', i)) {
          _completedUpper.add(i);
        }
      }
      for (int i = 0; i < lowercaseLetters.length; i++) {
        if (userProvider.isTraceItActivityCompleted('lowercase', i)) {
          _completedLower.add(i);
        }
      }
      for (int i = 0; i < numberLetters.length; i++) {
        if (userProvider.isTraceItActivityCompleted('numbers', i)) {
          _completedNums.add(i);
        }
      }
    });
  }

  Future<void> _saveLetterComplete(
      int modeIndex, int letterIndex, int stars) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String modeKey = modeIndex == 0
        ? 'uppercase'
        : modeIndex == 1
            ? 'lowercase'
            : 'numbers';
    await userProvider.updateTraceItProgress(modeKey, letterIndex, true,
        stars: stars);
  }

  static const String _totalScoreKey = 'traceit_total_score';

  /// Restores the points the child has already banked. Stars are not stored
  /// here — they live on the profile so the header, the dashboard and the
  /// parents' report can never show different numbers.
  Future<void> _loadEarnedTotals() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _score = prefs.getInt(_totalScoreKey) ?? 0);
  }

  /// Banks the points for a finished letter. The star itself is awarded by
  /// [_saveLetterComplete] via the provider, so it is granted in exactly one
  /// place.
  Future<void> _persistLetterPoints(int stars) async {
    if (stars <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalScoreKey,
        (prefs.getInt(_totalScoreKey) ?? 0) + (_pointsPerStar * stars));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Canvas transform
  // ─────────────────────────────────────────────────────────────────────────

  /// How far the furthest point of any glyph sits from [_glyphCenter], before
  /// [_letterMagnify] is applied.
  ///
  /// Measured across all 63 characters in `letter_tracing_data.dart` *after*
  /// [_magnify] has centred them: 64 horizontally (the two-character '10')
  /// and 69 vertically (the 'j', counting both its dot and its descender).
  /// Everything else fits inside those.
  ///
  /// Centring buys size as well as tidiness — a glyph that no longer leans to
  /// one side or sags in its box needs less room around it.
  static const double _glyphHalfWidth = 64.0;
  static const double _glyphHalfHeight = 69.0;

  void _computeTransform(Size canvasSize) {
    if (_canvasSize == canvasSize) return;
    _canvasSize = canvasSize;

    // The stroke data is authored around (150, 120) in a nominal 300×260
    // design space, but no glyph comes anywhere near filling that box — the
    // widest reaches 72 from the centre, not 150. Fitting the *empty box* to
    // the canvas therefore threw away most of the width and left the letter
    // roughly a third of the screen: too small for a child who is still
    // learning the shape of the stroke, and too small to trace accurately
    // with a finger.
    //
    // Fit the glyph's real extent instead.
    //
    // The same box is used for every character deliberately. Scaling each
    // letter to fill the canvas on its own would render 'i' as tall as 'M'
    // and 'a' as tall as 'b', teaching a child exactly the wrong thing about
    // how letters sit next to each other.
    //
    // The half-extents above measure the *path*, but what the child sees is a
    // track [_kTrackWidth] wide with round caps drawn along it, so the ink
    // reaches half that beyond the path on every side. Sizing to the path
    // alone overflowed the canvas on every phone tested — 412px of ink in a
    // 390px box — and the letter ran into the border and the corner badge.
    const inkHalf = _kTrackWidth / 2;

    // Fill most of the canvas, not all of it. A glyph pressed right up to the
    // edge reads as cramped and leaves the child no room to overshoot a
    // stroke, which at this age they constantly do.
    const comfort = 0.90;
    const padding = 20.0;

    final scaleX = (canvasSize.width - padding * 2) *
        comfort /
        (2 * (_glyphHalfWidth * _letterMagnify + inkHalf));
    final scaleY = (canvasSize.height - padding * 2) *
        comfort /
        (2 * (_glyphHalfHeight * _letterMagnify + inkHalf));
    _canvasScale = scaleX < scaleY ? scaleX : scaleY;

    // Put the design-space centre on the canvas centre. The extra two units
    // upward keep the traced guide sitting on the painted glyph, which is
    // centred on its paragraph box rather than on its own ink.
    _canvasOffset = Offset(
      canvasSize.width / 2 - _glyphCenter.dx * _canvasScale,
      canvasSize.height / 2 - (_glyphCenter.dy + 2) * _canvasScale,
    );
  }

  Offset _toDesign(Offset screen) => Offset(
        (screen.dx - _canvasOffset.dx) / _canvasScale,
        (screen.dy - _canvasOffset.dy) / _canvasScale,
      );

  void _onPanStart(DragStartDetails d) {
    if (_canvasSize == Size.zero) return;
    // Already finished — the green canvas says so, no message needed.
    if (_isCompleted) return;
    _onDragFillStart(d);
  }

  bool _outOfBounds = false;

  // ── Drag-to-fill gesture logic ─────────────────────────────────────────────

  void _onDragFillStart(DragStartDetails d) {
    if (_activeStroke >= _strokes.length) return;
    final designPt = _toDesign(d.localPosition);
    final start = _strokes[_activeStroke].first;
    if ((designPt - start).distance <= _startZoneRadius) {
      _guideController.stop();
      // Catching the dot mid-slide starts the stroke over rather than
      // resuming from wherever the animation had got to.
      _rewindController.stop();
      setState(() {
        _strokeProgress[_activeStroke] = 0;
        _dragging = true;
        _outOfBounds = false;
      });
    } else {
      // No text: a pre-reader can't read "Start at the dot!" anyway. The
      // pulsing numbered handle is the actual instruction — a miss just
      // gets a light buzz, the same nudge a real button press would give.
      HapticFeedback.selectionClick();
    }
  }

  void _onDragFillUpdate(DragUpdateDetails d) {
    if (!_dragging || _isCompleted || _activeStroke >= _strokes.length) return;
    final designPt = _toDesign(d.localPosition);
    final stroke = _strokes[_activeStroke];
    final cur = _strokeProgress[_activeStroke];

    // Only the next stretch of the stroke counts.
    //
    // Matching against the whole stroke meant a finger resting near a part of
    // the letter the child had not reached still pushed progress forward —
    // on O, 8, g, 6 and 9 the end of the path passes close to its own start,
    // so a child could finish the letter without going round it.
    final total = polylineLength(stroke);
    final window =
        total > 0 ? math.max(_maxProgressStep, _lookAheadUnits / total) : 1.0;
    final ahead = polylineSegment(stroke, cur, math.min(1.0, cur + window));
    final proj = _projectOntoPolyline(ahead, designPt);

    // Off the stroke, or reaching past the stretch that is open: pause
    // progress and flash the warning border.
    if (proj.distance > _pathTolerance) {
      if (!_outOfBounds) {
        // The try is over, not merely paused. `_dragging` goes down with it,
        // so keeping the finger pressed and wandering back onto the line does
        // not pick up where they left off — the child lifts and starts the
        // stroke again from its dot, the same as letting go half way.
        setState(() {
          _outOfBounds = true;
          _dragging = false;
        });
        // The border belongs to the warning, so the warning takes it down.
        // Tying it to the slide instead left it orange forever on the one
        // case where there is no slide: leaving the line before having
        // traced anything at all.
        _warningController
            .forward(from: 0)
            .then((_) => _warningController.reverse())
            .whenComplete(() {
          if (mounted && !_dragging) setState(() => _outOfBounds = false);
        });
        if (!_sendHandleHome()) {
          _guideController
            ..reset()
            ..repeat();
        }
      }
      return;
    }

    setState(() {
      _outOfBounds = false;
      // The window begins where they had got to, so what it reports is how
      // much further they have come — never a position somewhere else on the
      // letter. Still capped per update, so a flick cannot outrun the hand.
      final gained =
          total > 0 ? proj.progress * polylineLength(ahead) / total : 0.0;
      if (gained > 0) {
        _strokeProgress[_activeStroke] =
            math.min(cur + gained, cur + _maxProgressStep);
      }
    });

    if (_strokeProgress[_activeStroke] >= _strokeCompleteThreshold) {
      _completeActiveStroke();
    }
  }

  void _completeActiveStroke() {
    setState(() {
      _strokeProgress[_activeStroke] = 1.0;
      _activeStroke++;
      _dragging = false;
      _outOfBounds = false;
    });
    if (_activeStroke >= _strokes.length) {
      _completeDragFillLetter();
    } else {
      // Restart the pulse so the next stroke's start dot draws attention.
      _guideController
        ..reset()
        ..repeat();
    }
  }

  void _completeDragFillLetter() {
    if (_isCompleted) return;
    // One star per character — see _starsPerLetter.
    const int stars = _starsPerLetter;
    const earned = stars * _pointsPerStar;

    setState(() {
      _isCompleted = true;
      _dragging = false;
      // Points move right away; the star lands via _saveLetterComplete.
      _score += earned;
    });

    _currentCompletedSet.add(_selectedIndex);
    _saveLetterComplete(_selectedMode, _selectedIndex, stars);
    _persistLetterPoints(stars);

    _guideController.stop();
    _successController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_selectedIndex + 1 < _currentLetters.length) {
        _pageController.animateToPage(
          _selectedIndex + 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _onDragFillUpdate(d);
  }

  /// Sends the numbered handle back to the start of the stroke.
  ///
  /// The two ways a try can end badly are the same thing: a stroke is one
  /// movement along the letter. Lifting the finger half way is not a stroke,
  /// and neither is leaving the line — so both end here rather than in two
  /// places that could drift apart.
  /// Returns false when there was nothing to send back — the child had not
  /// moved along the stroke yet, so no slide runs and the caller has to put
  /// the start dot back to pulsing itself.
  bool _sendHandleHome() {
    if (_isCompleted) return false;
    if (_activeStroke >= _strokeProgress.length) return false;
    final reached = _strokeProgress[_activeStroke];
    if (reached <= 0) return false;

    _rewindFrom = reached;
    _rewindController.forward(from: 0);
    return true;
  }

  void _onPanEnd(DragEndDetails d) {
    final wasDragging = _dragging;
    setState(() {
      _dragging = false;
      _outOfBounds = false;
    });

    // A finished stroke has already moved on — `_completeActiveStroke` clears
    // `_dragging` itself, so lifting the finger at the end is not a failure.
    // Nor is a try that already ended when the finger left the line.
    if (!wasDragging || _isCompleted) return;
    _sendHandleHome();
  }

  void _resetTracing() {
    final completed = _currentCompletedSet.contains(_selectedIndex);
    _rewindController.reset();
    setState(() {
      _isCompleted = completed;
      _outOfBounds = false;
      _canvasSize = Size.zero;
      _guideProgress = completed ? -1 : 0;
      _initStrokes();
    });
    if (!completed) {
      _guideController.repeat();
    } else {
      _guideController.stop();
    }
    _successController.reset();
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
        // Closing the dialog used to be the whole of "Continue": it dropped
        // the child back on the last letter of a set they had just finished,
        // with every letter green and nothing left to do. Carry them into the
        // next set instead — ABC, then abc, then 123 — and off the screen
        // once there is no next set.
        primaryLabel: _selectedMode < 2
            ? AppLocalizations.of(context)!.continueText
            : AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.pop(context);
          if (_selectedMode < 2) {
            _switchMode(_selectedMode + 1);
          } else {
            Navigator.pop(context);
          }
        },
        secondaryLabel: AppLocalizations.of(context)!.back,
        onSecondaryTap: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        mainColor: AppColors.primary,
      ),
    );
  }

  void _onPageChanged(int index) {
    if (index != _selectedIndex) {
      final wasCompleted = _currentCompletedSet.contains(index);
      // Otherwise a slide still running would write progress into whichever
      // stroke the next character happens to have at that index.
      _rewindController.reset();
      setState(() {
        _selectedIndex = index;
        _isCompleted = wasCompleted;
        // A finished character shows its strokes already filled, so the
        // pulsing start dot is not wanted on it.
        _guideProgress = wasCompleted ? -1 : 0;
        _outOfBounds = false;
        _canvasSize = Size.zero;
        _initStrokes();
      });
      if (!wasCompleted) {
        _guideController.repeat();
      } else {
        _guideController.stop();
      }
      _successController.reset();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final loc = AppLocalizations.of(context)!;

    // As the team drew it, under the usual app bar: doodles behind, chunky 3D
    // mode pills, the character in a glossy bubble between two round arrows,
    // a glossy progress bar ending in a smiling star, and the tracing card in
    // a thick green frame.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      // The app bar is the plain one the app always had — kept at the team's
      // request; the page under it follows the design.
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 60,
        leading: Center(
          child: CustomBackButton(
            iconColor: AppColors.textDark,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(loc.traceItTitle,
              maxLines: 1,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 16),
              const SizedBox(width: 4),
              // The child's one star total, read straight from the profile.
              Text('${Provider.of<UserProvider>(context).displayStars}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(children: [
        const Positioned.fill(child: _TraceBackdrop()),
        SafeArea(
          child: Column(children: [
            _buildModeTabs(),
            _letterHeader(loc),

            // Canvas
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _currentLetters.length,
                // Navigation is arrow-only so students can't swipe to letters they
                // haven't reached yet.
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final letter = _currentLetters[index];
                  // Selected page reuses the already-magnified live strokes;
                  // other pages magnify on the fly for their preview. Every
                  // character in every mode has strokes, so the empty list is
                  // unreachable and only keeps a future character from crashing.
                  final rawStrokes =
                      strokesForMode(_selectedMode, letter.letter) ?? const [];
                  final letterStrokes =
                      _selectedIndex == index ? _strokes : _magnify(rawStrokes);
                  return Center(
                    child: AnimatedBuilder(
                      animation: _warningAnimation,
                      builder: (_, child) {
                        final done = _currentCompletedSet.contains(index) ||
                            (_isCompleted && _selectedIndex == index);
                        // A thick green frame round the canvas, as drawn.
                        return Container(
                          width: size.width,
                          height: size.height * 0.98,
                          margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBFE6C4),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                                color: const Color(0xFF9ED3A6), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF6DBB7A).withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          foregroundDecoration: const _FrameSpeckles(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              // A finished letter turns the whole canvas green. It
                              // says "done" without a banner popping up over the
                              // letter the child just traced.
                              color: done
                                  ? const Color(0xFFE3F6E6)
                                  : const Color(0xFFF2FBF3),
                              borderRadius: BorderRadius.circular(24),
                              border: _outOfBounds && _selectedIndex == index
                                  ? Border.all(
                                      color: Colors.orange.withOpacity(
                                          0.6 + _warningAnimation.value * 0.4),
                                      width: 3)
                                  : Border.all(
                                      color: done
                                          ? const Color(0xFF34C759)
                                          : const Color(0xFFA8D9AF),
                                      width: done ? 3 : 2),
                              // A glow only once the character is done; the
                              // green frame round it already lifts it off the
                              // page, and a shadow in the letter's colour left
                              // a muddy band along the frame's bottom.
                              boxShadow: [
                                if (done)
                                  BoxShadow(
                                    color: const Color(0xFF34C759)
                                        .withOpacity(0.35),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: LayoutBuilder(builder: (_, constraints) {
                              final cs = Size(
                                  constraints.maxWidth, constraints.maxHeight);
                              _computeTransform(cs);
                              return GestureDetector(
                                onPanStart: _onPanStart,
                                onPanUpdate: _onPanUpdate,
                                onPanEnd: _onPanEnd,
                                child: Stack(fit: StackFit.expand, children: [
                                  CustomPaint(
                                    painter: _StrokeFillPainter(
                                      strokes: letterStrokes,
                                      strokeProgress: _selectedIndex == index
                                          ? _strokeProgress
                                          : List<double>.filled(
                                              letterStrokes.length,
                                              _currentCompletedSet
                                                      .contains(index)
                                                  ? 1.0
                                                  : 0.0),
                                      activeStroke: _selectedIndex == index
                                          ? _activeStroke
                                          : (_currentCompletedSet
                                                  .contains(index)
                                              ? letterStrokes.length
                                              : 0),
                                      color: letter.color,
                                      isCompleted:
                                          _currentCompletedSet.contains(index),
                                      scale: _canvasScale,
                                      offset: _canvasOffset,
                                      guideProgress: _selectedIndex == index
                                          ? _guideProgress
                                          : null,
                                      starPulse: _starController,
                                      // Only the character on screen collects a
                                      // star; the pages either side must not
                                      // borrow this one's moment.
                                      collect: _selectedIndex == index
                                          ? _successController
                                          : kAlwaysDismissedAnimation,
                                    ),
                                  ),
                                  // Completion mark, tucked into the corner.
                                  //
                                  // This used to be a wide "Good Job!" banner across
                                  // the bottom of the canvas — it covered the letter
                                  // the child had just traced, and repeated word for
                                  // word the message already shown below the canvas.
                                  if (_isCompleted && _selectedIndex == index)
                                    Positioned(
                                      top: 14,
                                      right: 14,
                                      child: ScaleTransition(
                                        scale: _scaleAnimation,
                                        child: Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.45),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 4))
                                            ],
                                          ),
                                          child: const Icon(LucideIcons.check,
                                              color: Colors.white, size: 26),
                                        ),
                                      ),
                                    ),
                                ]),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Start this character again.
            //
            // The only other control here was a "Suriin" button guarded by
            // `if (!_useDragFill)`. Every character in all three alphabets has
            // drag-fill strokes, so that guard has never once been true and the
            // button has never been drawn — leaving a lone grey outline in the
            // smallest type on the screen as the child's only way back.
            //
            // Shown only while the character is still being traced: once it is
            // finished there is nothing to clear, and the button only invited
            // a child to wipe out work they had just completed.
            if (!_isCompleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: _ChunkyPill(
                  label: loc.clear,
                  icon: LucideIcons.rotate_ccw,
                  top: const Color(0xFF45DCCB),
                  bottom: const Color(0xFF18A8B6),
                  edge: const Color(0xFF0F7A85),
                  onTap: _resetTracing,
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  /// The letter, where the child is, and the way forward — in one band.
  ///
  /// The arrows sit either side of the character they move between, and one
  /// line underneath says how far along this alphabet the child has come — in
  /// stars, because a finished character is worth exactly one. Drawn as in
  /// the design: round 3D arrows, the character in a glossy teal bubble, a
  /// glossy green bar ending in a smiling star.
  Widget _letterHeader(AppLocalizations loc) {
    final done = _currentCompletedSet.length;
    final total = _currentLetters.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Column(children: [
        Row(children: [
          _buildNavArrow(
            icon: Icons.chevron_left_rounded,
            enabled: _selectedIndex > 0,
            onTap: () => _goToLetter(_selectedIndex - 1),
            colors: const [Color(0xFFC9A8F5), Color(0xFF9468E0)],
            edge: const Color(0xFF6C45B8),
          ),
          const SizedBox(width: 10),
          _CharBubble(_currentLetter.letter),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedMode == 2
                    // The word alone: the bubble beside it already shows
                    // the character, and "Letter X" next to an X said it
                    // twice.
                    ? loc.numberWord
                    : loc.letterWord,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14204A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildNavArrow(
            icon: Icons.chevron_right_rounded,
            enabled: _selectedIndex < _maxReachableIndex,
            onTap: () => _goToLetter(_selectedIndex + 1),
            colors: const [Color(0xFF8FB4F7), Color(0xFF4F7BE0)],
            edge: const Color(0xFF3358B4),
          ),
        ]),
        const SizedBox(height: 10),
        // How far through this alphabet the child has come. One star per
        // character, which is exactly what finishing one is worth.
        _GlossyProgress(
          value: total == 0 ? 0 : done / total,
          label: '$done/$total',
        ),
      ]),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required List<Color> colors,
    required Color edge,
  }) {
    // 56 across: these move the child between characters and sit at the very
    // edge of the screen, where a small hand is least accurate.
    return _RoundButton(
      colors: enabled ? colors : const [Color(0xFFE3E6EC), Color(0xFFC9CED8)],
      edge: enabled ? edge : const Color(0xFFB3B9C4),
      icon: icon,
      size: 56,
      onTap: enabled ? onTap : null,
    );
  }

  /// The first letter in [mode] the child has not completed yet, or 0 if
  /// the mode is already finished — there is nothing to resume to, so
  /// reviewing from the start is the reasonable default.
  int _firstUnfinishedIndex(int mode) {
    final total = mode == 0
        ? uppercaseLetters.length
        : mode == 1
            ? lowercaseLetters.length
            : numberLetters.length;
    final completed = mode == 0
        ? _completedUpper
        : mode == 1
            ? _completedLower
            : _completedNums;
    for (int i = 0; i < total; i++) {
      if (!completed.contains(i)) return i;
    }
    return 0;
  }

  void _switchMode(int index) {
    if (_selectedMode == index) return;
    // Jump to page 0 while the current mode's page count is still valid, THEN
    // switch mode. Letter counts differ per mode (26/26/10), so switching first
    // could leave the controller holding an out-of-range offset.
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    // Resumes at the first letter not yet completed in the target mode,
    // not always its first letter — a child who had worked up to R in
    // Uppercase, tried Numbers, and tapped back to ABC was landing on A
    // again instead of picking up where they actually left off.
    final target = _firstUnfinishedIndex(index);
    setState(() {
      _selectedMode = index;
      _selectedIndex = target;
      _resetTracing();
    });
    // Same reasoning as the Smart Resume jump in initState: the PageView
    // has not rebuilt with the new mode's item count yet inside this same
    // call, so moving now would land against the old mode's page range.
    //
    // Animated, not a jump — the new mode's first page (from the reset
    // above) is what actually paints on the next frame, so a plain
    // jumpToPage here read as the letter flashing to A and then snapping
    // to wherever the child had left off, rather than one smooth move.
    if (target != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _pageController.hasClients &&
            _pageController.page?.round() != target) {
          _pageController.animateToPage(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// The three alphabets as chunky 3D pills, as in the design: pale with a
  /// tinted rim until chosen, then bright with a solid edge under it.
  Widget _buildModeTabs() {
    final loc = AppLocalizations.of(context)!;
    final modes = [
      (
        index: 0,
        badge: 'ABC',
        label: loc.upper,
        completed: _completedUpper.length >= uppercaseLetters.length,
        face: const Color(0xFFDCE8FF),
        ink: const Color(0xFF3D6CC4),
        rim: const Color(0xFF9DBBF0),
        bright: const [Color(0xFF7FB2FF), Color(0xFF3D7BE0)],
        edge: const Color(0xFF2A5BB0),
      ),
      (
        index: 1,
        badge: 'abc',
        label: loc.lower,
        completed: _completedLower.length >= lowercaseLetters.length,
        face: const Color(0xFFD9F2E9),
        ink: const Color(0xFF2E8A6A),
        rim: const Color(0xFF98D3BD),
        bright: const [Color(0xFF5BDDA4), Color(0xFF1FA874)],
        edge: const Color(0xFF147A54),
      ),
      (
        index: 2,
        badge: '123',
        label: loc.numbers,
        completed: _completedNums.length >= numberLetters.length,
        face: const Color(0xFFFFE2D8),
        ink: const Color(0xFFD9573A),
        rim: const Color(0xFFF5AE96),
        bright: const [Color(0xFFFF8F70), Color(0xFFF0533A)],
        edge: const Color(0xFFB8361F),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Row(children: [
        for (final m in modes)
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(m.index),
              behavior: HitTestBehavior.opaque,
              child: _modePill(
                active: _selectedMode == m.index,
                badge: m.badge,
                label: m.label,
                completed: m.completed,
                face: m.face,
                ink: m.ink,
                rim: m.rim,
                bright: m.bright,
                edge: m.edge,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _modePill({
    required bool active,
    required String badge,
    required String label,
    required bool completed,
    required Color face,
    required Color ink,
    required Color rim,
    required List<Color> bright,
    required Color edge,
  }) {
    final text = active ? Colors.white : ink;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 50,
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 5),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bright,
              )
            : null,
        color: active ? null : face,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: active ? edge : rim, width: 2.5),
        boxShadow: [
          BoxShadow(color: active ? edge : rim, offset: const Offset(0, 5)),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.28)
                    : ink.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: text)),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: text)),
            if (completed) ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.circle_check, size: 16, color: text),
            ],
          ]),
        ),
      ),
    );
  }
}

/// The page behind everything: a soft wash with faint doodles.
class _TraceBackdrop extends StatelessWidget {
  const _TraceBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBFCFF), Color(0xFFF1F4FB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: DoodleBackground(),
    );
  }
}

/// A round, glossy button with a solid 3D edge — the back button and the
/// arrows either side of the character.
class _RoundButton extends StatelessWidget {
  final List<Color> colors;
  final Color edge;
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.colors,
    required this.edge,
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          border: Border.all(color: edge, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      ),
    );
  }
}

/// The character being traced, in a glossy teal bubble with a white rim
/// round its letters.
class _CharBubble extends StatelessWidget {
  final String char;
  const _CharBubble(this.char);

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    const style = TextStyle(fontSize: 42, fontWeight: FontWeight.w900);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.95,
          colors: [Color(0xFF9DEEF8), Color(0xFF2EB8D3), Color(0xFF0E7F9E)],
          stops: [0, 0.55, 1],
        ),
        border: Border.all(color: const Color(0xFF0B6E8A), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0B6E8A), offset: Offset(0, 4)),
        ],
      ),
      child: Stack(alignment: Alignment.center, children: [
        // The shine at the top left.
        Positioned(
          top: 8,
          left: 14,
          child: Container(
            width: 24,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(alignment: Alignment.center, children: [
              Text(char,
                  style: style.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 7
                      ..strokeJoin = StrokeJoin.round
                      ..color = Colors.white,
                  )),
              Text(char, style: style.copyWith(color: const Color(0xFF0B5D78))),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A glossy green bar with a smiling star riding its end, and the count.
class _GlossyProgress extends StatelessWidget {
  final double value;
  final String label;
  const _GlossyProgress({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    const barH = 22.0;
    const star = 44.0;
    return Row(children: [
      Expanded(
        child: LayoutBuilder(builder: (_, box) {
          final fill = (box.maxWidth * value.clamp(0.0, 1.0));
          return SizedBox(
            height: star,
            child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: barH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(barH),
                      border:
                          Border.all(color: const Color(0xFFCFE3D3), width: 2),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: barH,
                    width: fill < barH && fill > 0 ? barH : fill,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(barH),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF8BE38F), Color(0xFF3FB34F)],
                      ),
                      border:
                          Border.all(color: const Color(0xFF2E8F3C), width: 2),
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.5),
                      child: FractionallySizedBox(
                        widthFactor: 0.92,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (fill - star / 2)
                        .clamp(-star / 4, box.maxWidth - star * 0.6),
                    child: Image.asset('assets/images/star_happy_3.webp',
                        width: star, height: star),
                  ),
                ]),
          );
        }),
      ),
      const SizedBox(width: 12),
      Text(label,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A5A00))),
    ]);
  }
}

/// Little dots and leaf shapes in the tracing card's green frame.
class _FrameSpeckles extends Decoration {
  const _FrameSpeckles();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _SpecklePainter();
}

class _SpecklePainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;
    final paint = Paint()..color = const Color(0xFF8CC796).withOpacity(0.8);
    final random = math.Random(3);
    // Inside the frame band only: 4 to 13 px in from the card's edge.
    void dot(double x, double y) {
      final r = 1.6 + random.nextDouble() * 2.4;
      if (random.nextBool()) {
        canvas.drawCircle(Offset(x, y), r, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: r * 3.2, height: r * 1.4),
            paint);
        canvas.restore();
      }
    }

    double band() => 5 + random.nextDouble() * 6;
    for (double x = rect.left + 30; x < rect.right - 30; x += 18) {
      dot(x + random.nextDouble() * 8, rect.top + band());
      dot(x + random.nextDouble() * 8, rect.bottom - band());
    }
    for (double y = rect.top + 30; y < rect.bottom - 30; y += 18) {
      dot(rect.left + band(), y + random.nextDouble() * 8);
      dot(rect.right - band(), y + random.nextDouble() * 8);
    }
  }
}

/// A full-width rounded button with a solid 3D edge — "Clear".
class _ChunkyPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color top, bottom, edge;
  final VoidCallback onTap;

  const _ChunkyPill({
    required this.label,
    required this.icon,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: edge, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 5))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}
