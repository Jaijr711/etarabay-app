// Bug Condition Exploration Test for the "letter-tracing-fill" bugfix spec.
//
// Property 1 (Bug Condition): Trace Geometry Does NOT Match the Displayed Letterform.
//
// CRITICAL: This test is written to encode the EXPECTED (post-fix) behaviour and is
// therefore EXPECTED TO FAIL on the current (unfixed) code. Its failure surfaces the
// counterexamples that prove the dual-source geometry bug: the traceable / scoring
// geometry in `LetterData.points` is authored independently of the centred font glyph
// the child actually sees, so the two diverge in position, scale and shape.
//
// The bug is deterministic (the same `points` and the same displayed glyph every run),
// so the property is SCOPED to concrete representative characters drawn from
// `uppercaseLetters`, `lowercaseLetters`, and `numberLetters` ('A', 'a', '8', '10').
//
// Validates: Requirements 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4

import 'dart:math' as math;

import 'package:e_tarabay/data/letter_tracing_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Displayed-glyph model (derived from the production rendering setup)
// ─────────────────────────────────────────────────────────────────────────────
//
// In `trace_it_screen.dart` the faint reference letter is a
//   `Center(child: Opacity(opacity: 0.18, child: Text(letter.letter,
//        style: TextStyle(fontSize: 260 * _canvasScale, fontWeight: bold))))`
// laid over a canvas whose design space is 300 x 260 (`_computeTransform`:
// designW = 300, designH = 260) and that is centred via `_canvasOffset`.
//
// Two consequences define the geometry the trace data MUST match:
//   1. POSITION: the `Center` widget places the glyph's centre at the design-space
//      centre, i.e. (150, 130). A faithful trace path is centred there too.
//   2. SCALE: the glyph is rendered at fontSize `260 * scale`; in design units that
//      is a font size of 260 within a 260-tall design box, so the glyph's ink fills
//      most of the vertical space (cap/x-height of a 260 em is well above 150 units).
const double kDesignW = 300.0;
const double kDesignH = 260.0;
const Offset kDesignCenter = Offset(150.0, 130.0);

// Tolerance (design units) for the centre of the trace geometry vs the displayed
// glyph centre.
const double kCenterTolerance = 6.0;

// A glyph drawn at fontSize 260 fills most of the 260-unit-tall design box. A
// faithful, centred trace of it must span at least this many design units
// vertically. The hand-authored `points` are markedly smaller.
const double kMinGlyphVerticalExtent = 150.0;

const double kHitRadius = 20.0; // mirrors `_TracePainter`/`_TraceItScreenState`.

// ─────────────────────────────────────────────────────────────────────────────
//  Geometry helpers
// ─────────────────────────────────────────────────────────────────────────────

List<Offset> _finite(List<Offset> pts) =>
    pts.where((p) => p.dx.isFinite && p.dy.isFinite).toList();

/// Splits a point list into contour groups separated by `Offset(NaN, NaN)`
/// break markers (the same convention used by `_buildPath`).
List<List<Offset>> _contourGroups(List<Offset> pts) {
  final groups = <List<Offset>>[];
  var current = <Offset>[];
  for (final p in pts) {
    if (p.dx.isNaN || p.dy.isNaN) {
      if (current.isNotEmpty) {
        groups.add(current);
        current = <Offset>[];
      }
    } else {
      current.add(p);
    }
  }
  if (current.isNotEmpty) groups.add(current);
  return groups;
}

Rect _bbox(List<Offset> pts) {
  double minX = double.infinity,
      minY = double.infinity,
      maxX = -double.infinity,
      maxY = -double.infinity;
  for (final p in pts) {
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx);
    maxY = math.max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

LetterData _byLetter(List<LetterData> list, String letter) =>
    list.firstWhere((e) => e.letter == letter);

/// Returns the list of reasons the trace geometry for [d] does NOT match the
/// centred displayed glyph. An empty list means it matches (post-fix behaviour).
List<String> _displayedGlyphMismatches(LetterData d) {
  final reasons = <String>[];
  final finite = _finite(d.points);
  if (finite.isEmpty) {
    reasons.add('no finite points');
    return reasons;
  }

  final box = _bbox(finite);
  final cx = box.center.dx;
  final cy = box.center.dy;

  if ((cx - kDesignCenter.dx).abs() > kCenterTolerance) {
    reasons.add(
        'horizontal centre ${cx.toStringAsFixed(1)} is off the displayed-glyph '
        'centre ${kDesignCenter.dx.toStringAsFixed(1)} by '
        '${(cx - kDesignCenter.dx).abs().toStringAsFixed(1)} units');
  }
  if ((cy - kDesignCenter.dy).abs() > kCenterTolerance) {
    reasons.add(
        'vertical centre ${cy.toStringAsFixed(1)} is off the displayed-glyph '
        'centre ${kDesignCenter.dy.toStringAsFixed(1)} by '
        '${(cy - kDesignCenter.dy).abs().toStringAsFixed(1)} units');
  }

  final vExtent = box.height;
  if (vExtent < kMinGlyphVerticalExtent) {
    reasons.add(
        'vertical extent ${vExtent.toStringAsFixed(1)} is smaller than the '
        'displayed fontSize-260 glyph (expected >= '
        '${kMinGlyphVerticalExtent.toStringAsFixed(0)})');
  }

  // Multi-glyph strings (e.g. "10") must contain one contour group per glyph.
  if (d.letter.length > 1) {
    final groups = _contourGroups(d.points);
    if (groups.length < d.letter.length) {
      reasons.add(
          'multi-glyph "${d.letter}" has only ${groups.length} contour group(s); '
          'expected >= ${d.letter.length} (one per displayed digit)');
    }
  }

  return reasons;
}

bool _matchesDisplayedGlyph(LetterData d) =>
    _displayedGlyphMismatches(d).isEmpty;

// ─────────────────────────────────────────────────────────────────────────────
//  Scoring replica
// ─────────────────────────────────────────────────────────────────────────────
//
// Faithful re-implementation of `_TraceItScreenState._computeSmartScore` (and the
// visited-point accumulation from `_onPanUpdate`), operating directly in design
// coordinates. The scoring ALGORITHM is unchanged by the fix — only its input
// data (`points`) changes — so this replica stays valid before and after the fix.

List<Offset> _densify(List<Offset> pts, int steps) {
  if (pts.length < 2 || steps <= 0) return pts;
  final out = <Offset>[pts[0]];
  for (int i = 1; i < pts.length; i++) {
    final p0 = pts[i - 1];
    final p1 = pts[i];
    for (int s = 1; s <= steps; s++) {
      final t = s / (steps + 1);
      out.add(Offset.lerp(p0, p1, t)!);
    }
    out.add(p1);
  }
  return out;
}

double _smartScore({
  required List<Offset> guidePoints,
  required List<Offset> tracedDesignPoints,
  required int difficulty,
}) {
  final pts = guidePoints;
  if (tracedDesignPoints.length < 3) return 0.0;

  final designPts =
      tracedDesignPoints.where((p) => p.dx.isFinite && p.dy.isFinite).toList();
  if (designPts.isEmpty) return 0.0;

  final densePts = _densify(pts, 6);
  final outerRadius = kHitRadius * 3.0;
  final nearRadius = kHitRadius * 2.0;

  int nearCount = 0;
  int outOfBoundsCount = 0;
  for (final dp in designPts) {
    double minDist = double.infinity;
    for (final gp in densePts) {
      final dd = (dp - gp).distance;
      if (dd < minDist) minDist = dd;
    }
    if (minDist <= nearRadius) nearCount++;
    if (minDist > outerRadius) outOfBoundsCount++;
  }

  // Visited-point accumulation (mirrors `_onPanUpdate`).
  final visited = <int>{};
  final dynamicRadius = kHitRadius * (1.2 + (4 - difficulty) * 0.15);
  for (final dp in designPts) {
    for (int i = 0; i < pts.length; i++) {
      if ((dp - pts[i]).distance <= dynamicRadius) visited.add(i);
    }
  }

  final proximity = nearCount / designPts.length;
  final coverage = visited.length / pts.length;
  final outOfBoundsPenalty = outOfBoundsCount / designPts.length;

  double drawnLength = 0;
  for (int i = 1; i < designPts.length; i++) {
    drawnLength += (designPts[i] - designPts[i - 1]).distance;
  }
  double guideLength = 0;
  for (int i = 1; i < pts.length; i++) {
    guideLength += (pts[i] - pts[i - 1]).distance;
  }
  final lengthRatio = guideLength > 0 ? drawnLength / guideLength : 0;
  double lengthScore = 1.0;
  if (lengthRatio < 0.2 || lengthRatio > 3.5) {
    lengthScore = 0.0;
  } else if (lengthRatio < 0.4 || lengthRatio > 2.5) {
    lengthScore = 0.6;
  }

  bool touchedStart = false;
  bool touchedEnd = false;
  for (final dp in designPts) {
    if ((dp - pts.first).distance <= nearRadius) touchedStart = true;
    if ((dp - pts.last).distance <= nearRadius) touchedEnd = true;
  }
  double startEndScore = 0.5;
  if (touchedStart || touchedEnd) startEndScore = 0.75;
  if (touchedStart && touchedEnd) startEndScore = 1.0;

  double rawScore = (coverage * 0.40) +
      (proximity * 0.30) +
      (lengthScore * 0.15) +
      (startEndScore * 0.15);
  rawScore -= outOfBoundsPenalty * 0.35;

  return rawScore.clamp(0.0, 1.0);
}

/// An "accurate" trace sampled from the DISPLAYED glyph for '8': a full-size,
/// centred figure-eight (two stacked loops) filling the design box around the
/// glyph centre (150, 130). This is what tracing the visible '8' looks like.
List<Offset> _accurateDisplayedEightTrace() {
  final out = <Offset>[];
  const topCenter = Offset(150, 88);
  const bottomCenter = Offset(150, 172);
  const topR = 40.0;
  const bottomR = 42.0;
  for (double t = 0; t <= 2 * math.pi + 0.001; t += 0.18) {
    out.add(Offset(
        topCenter.dx + topR * math.sin(t), topCenter.dy - topR * math.cos(t)));
  }
  for (double t = 0; t <= 2 * math.pi + 0.001; t += 0.18) {
    out.add(Offset(bottomCenter.dx + bottomR * math.sin(t),
        bottomCenter.dy + bottomR * math.cos(t)));
  }
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // Representative characters for the scoped property (one per mode + the
  // multi-glyph edge case).
  final representatives = <LetterData>[
    _byLetter(uppercaseLetters, 'A'),
    _byLetter(lowercaseLetters, 'a'),
    _byLetter(numberLetters, '8'),
    _byLetter(numberLetters, '10'),
  ];

  group('Property 1 (Bug Condition): trace geometry matches displayed glyph', () {
    test(
        'scoped property: every representative character\'s trace geometry '
        'coincides with the centred displayed letterform', () {
      final failures = <String>[];
      for (final d in representatives) {
        final reasons = _displayedGlyphMismatches(d);
        if (reasons.isNotEmpty) {
          failures.add('  - "${d.letter}": ${reasons.join('; ')}');
        }
        // Expected (post-fix) behaviour: the geometry matches the displayed glyph.
        expect(
          _matchesDisplayedGlyph(d),
          isTrue,
          reason:
              'matchesDisplayedGlyph("${d.letter}") should hold, but: ${reasons.join('; ')}',
        );
      }
      // ignore: avoid_print
      if (failures.isNotEmpty) print('Counterexamples:\n${failures.join('\n')}');
    });

    test('number "8": an accurate trace of the displayed glyph is accepted',
        () {
      final eight = _byLetter(numberLetters, '8');
      final accurate = _accurateDisplayedEightTrace();
      final score = _smartScore(
        guidePoints: eight.points,
        tracedDesignPoints: accurate,
        difficulty: eight.difficulty,
      );
      // ignore: avoid_print
      print('Accurate displayed-"8" trace scored ${score.toStringAsFixed(3)} '
          '(threshold 0.60).');
      // Expected (post-fix) behaviour: tracing the displayed letter is accepted.
      expect(
        score,
        greaterThanOrEqualTo(0.60),
        reason:
            'An accurate trace over the displayed "8" scores below the 0.60 '
            'acceptance threshold because it is compared against mismatched points',
      );
    });

    test('multi-glyph "10": points cover both displayed digit glyphs', () {
      final ten = _byLetter(numberLetters, '10');
      final groups = _contourGroups(ten.points);
      // ignore: avoid_print
      print('"10" points form ${groups.length} contour group(s); '
          'expected 2 (one per displayed digit).');
      expect(
        groups.length,
        greaterThanOrEqualTo(2),
        reason:
            '"10" is displayed as two digit glyphs but its points form a single '
            'approximated path with no contour separator',
      );
    });
  });
}
