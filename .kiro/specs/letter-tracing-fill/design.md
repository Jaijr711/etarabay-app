# Letter Tracing Fill Bugfix Design

## Overview

In the "Trace It" game (`lib/screens/trace_it_screen.dart`) every character is presented through two
independent, unrelated sources of geometry:

- The **faint reference glyph** the student sees is a Flutter `Text(letter.letter)` widget rendered
  from the real font (Poppins, via `GoogleFonts.poppinsTextTheme()` in `lib/main.dart`), sized
  `260 * _canvasScale` and centred in the canvas.
- The **trace guide path** (animated guide dot) and the **scoring reference** both read
  `LetterData.points` — hand-coded / AI-approximated `List<Offset>` arrays in
  `lib/data/letter_tracing_data.dart`, expressed in a 300×260 "design" coordinate space.

Because the displayed glyph and the `points` array come from different sources, they do not coincide:
the guide dot drifts off the visible letter, an accurate trace over the displayed glyph is scored
against the wrong geometry (false "almost there"), and tracing the approximated path can be accepted
even though it does not match the displayed letter.

The fix adopts the user-specified **Path-based guided tracing module**. Each character is defined by a
single precise `Path` object — an "invisible spine" running down the centre of the letterform. That one
`Path` becomes the **single source of truth** from which all three consumers derive:

1. **Display**: a `CustomPaint` draws a large, hollow, styled outline of the letter from the `Path`.
2. **Guidance & progress**: `PathMetrics` computes the exact coordinate of the current progress point
   along the `Path`, where a small **leading sprite** (bee / glowing circle) follows the curve.
3. **Fill & scoring**: as the student traces within a **tolerance radius** of the `Path`, a solid color
   progressively fills the hollow letter along the predefined path; reaching 100% of the path length
   (detected via `PathMetrics`) triggers completion.

Because the displayed outline, the guide, the fill, and the completion check are all derived from the
same `Path`, they cannot disagree — this is what fixes the bug by construction. The approximated
`points` arrays are replaced by accurate per-character `Path` definitions (uppercase, lowercase,
numbers).

The fix is scoped to the *interaction and geometry layer*. The surrounding game shell — mode switching,
points/stars, progress persistence, saved-trace review, smart-resume, the completion dialog, and
multi-stroke (multi-contour) letters — is preserved.

> **Deviation note (bugfix.md Requirement 3.6).** The chosen fix direction intentionally replaces the
> current *free-draw* interaction with *guided* tracing (the stroke only advances while the touch stays
> within the tolerance radius of the spine, and fill follows the predefined path rather than the raw
> finger path). Multi-stroke support and rendering of the student's progress are preserved (each letter
> stroke is a sub-path of the `Path`, and lifting/restarting between strokes is supported). The
> "free-draw" aspect of Requirement 3.6 is therefore changed by design; this is called out here and in
> the final summary so Requirement 3.6 can be updated to read "guided, multi-stroke tracing".

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug — a character whose traceable/scoring
  geometry (`LetterData.points`) does not match the accurate letterform displayed as the reference.
- **Property (P)**: The desired behaviour — the displayed outline, the guide/leading sprite, the
  progressive fill, and the completion check all follow the same accurate letterform `Path`, so a trace
  that follows the displayed letter completes and a trace that wanders off the letter does not.
- **Preservation**: Game mechanics not tied to shape accuracy that must remain unchanged — mode
  switching, points/stars, progress saving, auto-advance, saved-trace review, smart-resume, completion
  dialog, and multi-stroke (multi-contour) support.
- **Guide Path / Spine**: A single `ui.Path` per character, defined down the centre of the letterform in
  the 300×260 design space, composed of one sub-path per pen stroke (`moveTo` starts a new sub-path).
  The single source of truth.
- **`PathMetrics` / `PathMetric`**: Flutter's arc-length API (`Path.computeMetrics()`). Used to obtain
  total length, extract a partial path (`extractPath`), and get the position/tangent at a distance
  (`getTangentForOffset`).
- **Tolerance radius**: The maximum design-space distance the student's touch may be from the spine for
  the stroke to keep progressing. Outside it, progress pauses until the touch returns.
- **Progress (`t`)**: A value in `[0, 1]` = fraction of total spine arc-length the student has
  successfully traced. Monotonic non-decreasing within a stroke.
- **Leading sprite**: A small widget (bee icon / glowing circle) drawn at the current progress point on
  the spine, computed via `PathMetric.getTangentForOffset(t * length)`.
- **Progressive fill**: The solid-color reveal of the hollow letter from the start of the spine up to
  the current progress point, rendered by stroking `extractPath(0, t * length)`.
- **Hollow outline**: The large, light, styled letterform the student fills in, rendered from the same
  `Path` (a wide light stroke / outlined body).
- **`LetterTracingWidget`**: The new `StatefulWidget` that owns gesture state (touch, progress,
  completion) and hosts the painter.
- **`TracingPainter`**: The new `CustomPainter` that renders the hollow outline, the progressive fill,
  and the leading sprite from the `Path`.
- **`onLetterCompleted()`**: Callback invoked when `PathMetrics` reports 100% progress; the host screen
  uses it to award points/stars, save progress, celebrate, and auto-advance.
- **Design space**: The fixed 300×260 coordinate system (`designW`/`designH` in `_computeTransform`)
  that the spine `Path` is authored in and that the canvas scales/centres onto the screen.

## Bug Details

### Bug Condition

The bug manifests for every character presented, because each character's traceable geometry
(`LetterData.points`) is authored independently of the font glyph displayed to the student. The guide
path and scoring reference are off-position relative to the displayed glyph, a distorted approximation
of the letterform, or both — so the dot the student is told to follow and the shape the student is
scored against do not correspond to the visible letter.

**Formal Specification:**
```
FUNCTION isBugCondition(X)
  INPUT: X of type LetterData   // a character entry from letter_tracing_data.dart
  OUTPUT: boolean

  // True when the trace guide / scoring geometry for X does not match
  // the accurate letterform displayed for X.
  RETURN NOT matchesDisplayedGlyph(X.points, X.letter)
END FUNCTION
```

### Examples

- **'A' (uppercase)**: The reference glyph is the font "A". `points` is a ~29-point zig-zag
  approximation. The animated dot traces the approximation, not the displayed A, and a student who
  traces the visible A is scored against mismatched points. Expected: the displayed hollow A, the guide,
  the fill, and completion all follow one accurate A spine.
- **'a' (lowercase)**: Font lowercase "a" (bowl + tail) vs a 24-point hand-drawn loop; shape and
  position diverge. Expected: the traceable spine equals the displayed "a".
- **'8' (number)**: `points` describe a stylised figure-eight that does not align with the displayed
  "8" crossings, so a correct trace over the visible 8 may be rejected. Expected: guide, fill, and
  completion follow the displayed 8 spine.
- **'10' (number, edge case)**: The displayed reference is the two-glyph string "10", while `points` is
  a single hand-drawn path. The spine must contain a sub-path for "1" and for "0" so the geometry
  matches the displayed "10". Expected: traceable spine covers both digit glyphs.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Switching between Uppercase, Lowercase, and Numbers modes still shows the corresponding character set
  (Requirement 3.1).
- Completing a character still awards points and stars, saves progress, and auto-advances to the next
  character (Requirement 3.2).
- Returning to or swiping back to a completed character still displays the saved/finished trace for
  review (Requirement 3.3).
- Opening the screen still smart-resumes at the first uncompleted character (Requirement 3.4).
- Completing all characters in a mode still shows the completion dialog (Requirement 3.5).
- Tracing still supports **multi-stroke** characters and renders the student's progress (Requirement
  3.6 — multi-stroke aspect preserved; see the deviation note about free-draw being replaced by guided
  tracing).

**Scope:**
All behaviour that is NOT tied to the accuracy of the letter shape must be unaffected by this fix. This
includes:
- Mode switching and character-set selection.
- Points/stars accounting and the on-completion side effects (`UserProvider` /
  `updateTraceItProgress`), and auto-advance timing.
- Saved-trace review, smart-resume, page navigation, and the completion dialog.
- Multi-stroke support: letters composed of several pen strokes (e.g. 'A', 'B', 't', 'i', 'x') remain
  traceable stroke-by-stroke, with the student able to lift and start the next stroke.

The actual expected correct behaviour (display, guide, fill, and completion all driven by one accurate
`Path`) is defined in the Correctness Properties section (Property 1). This section captures what must
NOT change.

## Hypothesized Root Cause

Based on the bug description and code inspection, the root cause is a **dual-source geometry design**:

1. **Two unrelated geometry sources**: The faint reference is a `Text` widget rendered from the font,
   while the guide dot and scoring read `LetterData.points`. Nothing constrains the two to agree.

2. **Approximated / authored `points`**: The `points` arrays in `letter_tracing_data.dart` are
   hand-coded or AI-approximated polylines, not derived from any real letterform. They are rough or
   distorted (Requirement 1.4) and are positioned in design space independently of where the centred
   glyph actually renders.

3. **Scoring is only as good as `points`**: `_computeSmartScore` faithfully compares the trace to
   `LetterData.points`; because that reference is wrong, accurate traces over the displayed glyph are
   rejected (1.2) and traces of the approximated path are wrongly accepted (1.3).

4. **No shared geometry primitive**: There is no single object that simultaneously defines what is
   *shown*, what is *guided*, and what is *scored*. The fix introduces exactly that: one `Path` per
   character from which display, guidance, fill, and completion are all derived, so divergence becomes
   structurally impossible.

## Correctness Properties

Property 1: Bug Condition - Trace Geometry Matches the Displayed Letterform

_For any_ character X where the bug condition holds (`isBugCondition(X)` returns true — the guide and
scoring geometry do not match the displayed glyph), the fixed game SHALL derive the displayed hollow
outline, the leading-sprite guide, the progressive fill, and the completion check from a single
per-character `Path` (spine) for X, so that the guide and fill follow the displayed letter, a trace that
stays within the tolerance radius along the full spine completes the letter, and a trace that wanders
off the spine does not complete it.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation - Non-Shape Game Mechanics Unchanged

_For any_ input where the bug condition does NOT hold (mode switching, points/stars accounting, progress
saving, auto-advance, saved-trace review, smart-resume, completion dialog, and multi-stroke support),
the fixed game SHALL produce the same observable result as the original game, preserving all behaviour
not tied to letter-shape accuracy.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**

## Fix Implementation

### Design Decision: One `Path` per Character as the Single Source of Truth

The approximated `List<Offset> points` is replaced by an accurate per-character `Path` (the spine). One
`Path` drives display, guidance, fill, and completion, so the three consumers cannot diverge. This is
the structural fix for the dual-source bug.

**Why a hand-authored `Path` rather than re-tuned points or runtime font extraction:**
- Re-tuning `points` would still be an approximation authored separately from the display and would
  re-introduce drift.
- Flutter does not expose a stable public API to convert rendered text into a `ui.Path`, and
  `google_fonts` loads Poppins at runtime (non-deterministic for extraction). A hand-authored `Path` in
  design space, drawn with `moveTo`/`lineTo`/`quadraticBezierTo`/`cubicTo`, is accurate by construction,
  deterministic across platforms, supports smooth curves, and — crucially — is the very geometry that is
  displayed, guided, filled, and scored. There is no second source to disagree with.

### Sourcing the per-character `Path` (uppercase, lowercase, numbers)

**File**: `lib/data/letter_tracing_data.dart`

1. **Replace the `points` field with a `Path` builder.** Update `LetterData` so each character supplies a
   spine `Path` in the 300×260 design space:

   ```dart
   class LetterData {
     final String letter;
     final String sound;
     final String example;
     final Color color;
     final int difficulty;
     final Path Function() buildGuidePath; // single source of truth (design space, 300x260)

     const LetterData({
       required this.letter,
       required this.sound,
       required this.example,
       required this.color,
       required this.difficulty,
       required this.buildGuidePath,
     });
   }
   ```

   A function (`Path Function()`) is used because `Path` is not a `const` type. Each builder returns a
   fresh `Path` so callers never mutate shared state.

2. **Author one spine per character**, down the centre of the letterform, matching the proportions of the
   displayed hollow letter. Each pen stroke is a separate sub-path introduced with `moveTo`, so
   multi-stroke letters are represented naturally. Use straight segments for straight strokes and Bézier
   curves for round strokes. Example:

   ```dart
   // 'A' — two diagonal legs (one sub-path) + crossbar (second sub-path)
   buildGuidePath: () => Path()
     ..moveTo(110, 180)..lineTo(150, 60)..lineTo(190, 180) // legs
     ..moveTo(128, 132)..lineTo(172, 132),                 // crossbar

   // 'O' — single closed-ish oval via cubic curves
   buildGuidePath: () => Path()
     ..moveTo(150, 60)
     ..cubicTo(110, 60, 110, 180, 150, 180)
     ..cubicTo(190, 180, 190, 60, 150, 60),
   ```

   Cover all three sets: `uppercaseLetters` (A–Z), `lowercaseLetters` (a–z), `numberLetters` (1–10).

3. **Multi-glyph entry `'10'`**: build the spine with a sub-path for the "1" and a sub-path (or set of
   sub-paths) for the "0", positioned to match the displayed "10", so the traceable geometry covers both
   digits.

> **Stroke order / direction** is encoded by the order of `moveTo`/`lineTo`/curve commands within and
> across sub-paths; `PathMetrics` walks contours in that order, which defines the guidance order.

### Rendering: `TracingPainter extends CustomPainter`

**File**: `lib/screens/trace_it_screen.dart` (replacing `_TracePainter`), or a new
`lib/widgets/letter_tracing_widget.dart`.

The painter receives the design-space spine `Path`, the canvas transform (`scale`, `offset`), the color,
and the current `progress` (`t`). It performs three draws, all from the same transformed `Path`:

```
paint(canvas, size):
  screenPath = guidePath.transform(scaleAndOffsetMatrix)   // design -> screen

  // 1. Hollow, styled letter outline (what the student fills in)
  canvas.drawPath(screenPath, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = bodyWidth          // wide -> letter body
    ..strokeCap = round ..strokeJoin = round
    ..color = color.withOpacity(0.18)) // light = hollow look

  // 2. Progressive solid fill from start to current progress
  for metric in screenPath.computeMetrics():     // per sub-path
    portion = metric.extractPath(0, clampToThisMetric(t * totalLength))
    canvas.drawPath(portion, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyWidth
      ..strokeCap = round ..strokeJoin = round
      ..color = isCompleted ? green : color)    // solid = filled

  // 3. Leading sprite at the current progress point
  (metric, distInMetric) = locate(t * totalLength)
  tangent = metric.getTangentForOffset(distInMetric)
  drawLeadingSprite(canvas, tangent.position)    // bee icon / glowing circle
```

Notes:
- `computeMetrics()` is iterated so multi-sub-path letters fill stroke-by-stroke in order.
- `totalLength` is the sum of all `PathMetric.length`s; `t * totalLength` maps the global progress onto
  the correct contour and offset within it.
- `getTangentForOffset` yields both the position (for the sprite) and the direction (so the sprite can
  rotate to face along the stroke, optional).
- The leading sprite may be drawn in the painter, or as a separate `Positioned` Flutter widget placed at
  `tangent.position` if an animated `Image`/`Icon` widget is preferred. Either way the position comes
  from `PathMetrics`.

### Gesture & state: `LetterTracingWidget extends StatefulWidget`

The widget owns gesture state and hosts the painter inside a `GestureDetector`.

```
state: progress t (0..1), isCompleted, currentMetricIndex

onPanUpdate(details):
  if isCompleted: return
  touchDesign = toDesignSpace(details.localPosition)

  // Project the touch onto the spine, ahead of the current frontier, within a search window.
  (candidateDistance, distanceToPath) = nearestArcLengthAhead(spine, touchDesign, t)

  if distanceToPath <= toleranceRadius:
     // Advance monotonically toward the touch's projection; never go backwards.
     t = max(t, candidateDistance / totalLength)
     setState()
     if t >= completionThreshold (~0.98):
        _complete()
  else:
     // Too far from the line: pause progress (do not advance), optionally flash a hint.
     showStayOnLineHint()

onPanStart(details):
  // Supports lifting between strokes: a new touch near the next sub-path's start resumes guidance there.
```

- **Tolerance**: `toleranceRadius` derives from `difficulty` (easier letters → larger radius), mirroring
  the existing `_hitRadius` scaling so the feel is consistent.
- **Monotonic progress**: `t` only increases, so back-and-forth jitter cannot reduce progress; wandering
  off simply stops advancement until the finger returns to the line.
- **Multi-stroke**: when a contour's portion of `t` is complete, the frontier advances to the next
  contour's start; lifting and re-touching near that start continues guidance — this is how multi-stroke
  support is preserved.

### Completion & celebration

```
_complete():
  setState(isCompleted = true; t = 1.0)
  playCelebration()              // AnimationController scale/burst, or confetti package
  onLetterCompleted?.call()      // host wires this to existing side effects
```

`onLetterCompleted()` is wired by the host screen to the **existing** completion logic
(`_completeTracing`): award +15 points / +3 stars, `_saveLetterComplete(...)`, success overlay,
store the finished render for review, and auto-advance / show the completion dialog. The celebration
uses an `AnimationController` (already available via `TickerProviderStateMixin`) or, optionally, the
`confetti` package.

### Integration with `trace_it_screen.dart` (preserving unchanged behaviour)

- **Display layer**: Remove the `Center(child: Opacity(child: Text(letter.letter, ...)))` reference glyph
  and the old `_TracePainter` guide-dot/user-stroke draw. Replace the canvas content with
  `LetterTracingWidget` (hollow outline + progressive fill + leading sprite), fed `letter.buildGuidePath()`
  and the `_computeTransform` scale/offset.
- **Scoring replacement**: The heuristic `_computeSmartScore` + 0.60 threshold and the "Check" button
  flow are replaced by path-progress completion (reaching 100% within tolerance *is* a correct trace).
  This is the mechanism that makes 2.2/2.3 hold by construction. The "Check" button may be removed or
  repurposed; "Clear" resets `t` to 0.
- **Preserved as-is**: `_selectedMode` / `_currentLetters` mode switching (3.1); points/stars, progress
  saving and auto-advance in `_completeTracing` / `_saveLetterComplete` (3.2); saved-trace review on
  revisit via `_completedTraces` and `_onPageChanged` (3.3) — the stored progress for a completed letter
  renders as a full fill; `_initSmartResume` (3.4); `_showCompletionDialog` (3.5); multi-stroke letters
  via multi-sub-path spines (3.6, multi-stroke aspect).
- **Design space reused**: the 300×260 design space and `_computeTransform`/`_toScreen`/`_toDesign`
  transforms are unchanged; only the geometry primitive changes from `List<Offset>` to `Path`.

## Testing Strategy

### Validation Approach

Two phases: first surface counterexamples that demonstrate the geometry mismatch on the UNFIXED code,
then verify that after the fix the single `Path` drives display/guide/fill/completion correctly and that
all non-shape behaviours are preserved.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples demonstrating the dual-source mismatch BEFORE implementing the fix and
confirm the root cause. If refuted, re-hypothesise.

**Test Plan**: For representative characters compute the displayed glyph geometry (centred font outline
in design space) and compare it to `LetterData.points`; assert correspondence. Also assert that an
"accurate" trace sampled from the displayed glyph scores below the existing 0.60 threshold on the
unfixed code. Run on the UNFIXED code.

**Test Cases**:
1. **Uppercase mismatch ('A')**: Compare displayed-glyph geometry to `points` for 'A' (will fail on
   unfixed code — geometry diverges).
2. **Lowercase mismatch ('a')**: Same comparison for 'a' (will fail on unfixed code).
3. **Number mismatch ('8')**: A trace sampled from the displayed '8' is scored; assert it is accepted
   (will fail on unfixed code — accurate trace is rejected).
4. **Multi-glyph edge case ('10')**: Assert the traceable geometry covers both displayed digits (will
   fail on unfixed code — single approximated path).

**Expected Counterexamples**:
- `points` geometry does not coincide with the displayed glyph (off-position and/or distorted).
- An accurate trace over the displayed letter scores below the 0.60 threshold.
- Possible causes: independent `points` authoring, design-space placement differing from the centred
  glyph, approximated shapes.

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the single `Path` drives a guide,
fill, and completion that follow the displayed letterform.

**Pseudocode:**
```
FOR ALL X WHERE isBugCondition(X) DO
  spine := X.buildGuidePath()                         // the single source of truth
  ASSERT renderedOutline(X) derivedFrom spine         // display == spine
  ASSERT leadingSprite(X, t) == positionOnPath(spine, t)   // guide == spine (via PathMetrics)
  ASSERT fill(X, t) == extractPath(spine, 0, t*len)   // fill == spine
  ASSERT completes(traceAlong(spine, withinTolerance))      // accurate trace completes
  ASSERT NOT completes(traceOffStreet(spine))               // wandering trace does not complete
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed game produces the
same observable result as the original game.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT original(input) = fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation because:
- It generates many inputs automatically across the domain (modes, indices, stroke/touch sequences).
- It catches edge cases manual tests miss (e.g., lifting between multi-stroke contours).
- It gives strong assurance that non-shape behaviour is unchanged for all non-buggy inputs.

**Test Plan**: Observe behaviour on the UNFIXED code for non-shape mechanics, then write property-based
tests capturing that behaviour and re-run them against the fixed code.

**Test Cases**:
1. **Mode switching / character sets**: Verify each mode still yields its full character set in order.
2. **Completion side effects**: Verify reaching completion awards +15 points / +3 stars, saves progress
   via `UserProvider`/`updateTraceItProgress`, and auto-advances.
3. **Review & resume**: Verify a completed character redisplays its finished (fully filled) trace on
   revisit, and smart-resume lands on the first uncompleted character.
4. **Completion dialog**: Verify finishing the last character in a mode shows the completion dialog.
5. **Multi-stroke**: Verify multi-sub-path letters can be traced stroke-by-stroke, with lift-and-restart
   between contours.

### Unit Tests

- Verify each character's `buildGuidePath()` returns a non-empty `Path` whose bounds lie within the
  300×260 design space and whose `computeMetrics()` total length is > 0.
- Verify multi-stroke letters ('A', 'B', 't', 'i', 'x', etc.) produce more than one contour.
- Verify '10' produces contours covering two digit glyphs.
- Verify the canvas stack no longer contains a `Text(letter.letter)` reference glyph; the outline is
  drawn from the `Path`.
- Verify tolerance scales with `difficulty` (easier letters → larger tolerance radius).

### Property-Based Tests

- For traces generated by sampling points along a character's spine (within tolerance), assert progress
  reaches the completion threshold (accurate traces complete).
- For traces generated far from the spine (random/out-of-bounds points beyond the tolerance radius),
  assert progress does NOT reach completion (off-letter traces do not complete).
- For monotonicity: for any touch sequence, assert progress `t` never decreases.
- For randomly generated (mode, index) pairs and multi-stroke inputs, assert non-shape behaviour
  (selected character, completion accounting, review/resume) matches the pre-fix behaviour.

### Integration Tests

- Full trace flow per mode: render a character, trace along the displayed spine, and assert the hollow
  outline fills progressively, the leading sprite follows the curve, and completion awards points/stars
  and auto-advances.
- Switch modes and indices, then trace, asserting the outline/guide/fill track the displayed letter in
  each context.
- Revisit a completed character and assert the finished fill is shown for review and the completion
  dialog appears after the final character.
- Trace a multi-stroke letter, lifting between strokes, and assert each stroke fills in order to
  completion.
