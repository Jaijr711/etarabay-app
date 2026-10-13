# Design Document

## Overview

The Trace It module currently has **two rendering/interaction paths already partially built** in `trace_it_screen.dart`:

- `_TracePainter` + freehand `GestureDetector` handlers + `_computeSmartScore()` — the legacy path.
- `_StrokeFillPainter` + drag-fill handlers (`_onDragFillStart/_onDragFillUpdate`) + `_polylineLength`/`_projectOntoPolyline`/`_partialPolyline` helpers — the new guided drag-fill path.

However, the current code in the repo applies the drag-fill path to **all three modes** (`strokesForMode` looks up `uppercaseStrokes`, `lowercaseStrokes`, and `numberStrokes`), which violates Requirement 6 (lowercase/numbers must stay on the legacy freehand mechanic and `_computeSmartScore`, completely untouched by this feature) and Requirement 5 (completion-based scoring must be scoped to uppercase only).

This design keeps the already-built `_StrokeFillPainter`, `_projectOntoPolyline`, `_partialPolyline`, `_polylineLength` machinery — it is correct and reusable — but:

1. Removes `lowercaseStrokes` and `numberStrokes` entirely from `letter_tracing_data.dart` (they should never have existed per Requirement 6.5).
2. Narrows `strokesForMode`/the routing getter so only `_selectedMode == 0` (uppercase) can ever resolve to a non-null stroke set.
3. Fixes the star-rating call site so completion-based scoring only ever executes for uppercase, and legacy freehand scoring (`_computeSmartScore`, flat 15 pts / 3 stars) is untouched for lowercase/numbers.
4. Formalizes the two per-letter stroke maps that already exist (`uppercaseStrokes`) into the `Letter_Data_Model` described by Requirement 1, verifies the classification of all 26 uppercase letters, and adds the derivation check (concatenated strokes == legacy flat `points`).
5. Fixes small correctness gaps in the existing drag-fill state machine relative to the requirements (Attempt_Count semantics, start-zone radius formula relative to stroke width, off-path feedback duration/clearing, forward-only clamping) as detailed in Error Handling.

No new packages, no new assets. Everything continues to run through `CustomPainter` + `dart:ui` (`ui.Paragraph`, `Path`, `Canvas`).

## Architecture

### Session-type split (single source of truth)

The core architectural fix is making **one boolean** the single gate that decides which entire subsystem (data, gesture handlers, painter, scoring) is active for the currently displayed item:

```
_selectedMode == 0 (Uppercase)   ──►  Uppercase_Letter_Session  (drag-fill)
_selectedMode == 1 (Lowercase)   ──►  Legacy_Tracing_Session    (freehand)
_selectedMode == 2 (Numbers)     ──►  Legacy_Tracing_Session    (freehand)
```

```dart
/// Whether the current item uses the guided drag-fill mechanic.
/// ONLY true for uppercase letters — this is the single flag that gates the
/// entire uppercase-only subsystem (data lookup, gesture handlers, painter,
/// and completion-based scoring). Lowercase and numbers must always evaluate
/// to false here, regardless of any per-letter data.
bool get _useDragFill =>
    _selectedMode == 0 && strokesForMode(_selectedMode, _currentLetter.letter) != null;
```

`strokesForMode` is narrowed so it is structurally impossible for modes 1/2 to return a stroke set:

```dart
List<List<Offset>>? strokesForMode(int mode, String letter) {
  if (mode != 0) return null; // lowercase & numbers never have a Stroke_Set
  return uppercaseStrokes[letter];
}
```

This is the "strategy split without duplicating unrelated logic" the requirements call for: every place in `trace_it_screen.dart` that currently branches on `_useDragFill` (`_onPanStart`, `_onPanUpdate`, `_onPanEnd`, the `CustomPaint` `painter:` selection, the "Check" button visibility) keeps working exactly as already written — because with the narrowed `strokesForMode`, `_useDragFill` can now only ever be `true` when `_selectedMode == 0`. No new branches need to be added to the gesture handlers themselves; the fix is entirely in the data layer (`strokesForMode`) plus one call site (star-rating), which is the smallest change that removes the regression risk to lowercase/numbers.

### Component breakdown

```
trace_it_screen.dart
├── _TracePainter                  (UNCHANGED) legacy freehand painter, dashed
│                                  glyph + free-drawn stroke overlay
├── _StrokeFillPainter             (UNCHANGED rendering logic) uppercase-only
│                                  stroke-track + fill-indicator painter
├── Polyline math (module-level)   (UNCHANGED) _polylineLength,
│                                  _partialPolyline, _projectOntoPolyline
│                                  — pure functions, reused by both the
│                                  painter and the gesture logic
├── _TraceItScreenState
│   ├── Mode/session state          _selectedMode, _selectedIndex
│   ├── Legacy session state        _tracedPoints, _visitedPoints,
│   │                               _overlapGrid, _completedTraces
│   │                               (UNCHANGED — Requirement 6)
│   ├── Uppercase session state     _strokes, _strokeProgress, _activeStroke,
│   │                               _dragAttempts, _dragging, _outOfBounds
│   │                               (NARROWED to only ever populate for
│   │                               uppercase — see _initStrokes below)
│   ├── Gesture routing             _onPanStart/_onPanUpdate/_onPanEnd
│   │                               branch on _useDragFill (UNCHANGED code,
│   │                               now provably uppercase-only)
│   ├── Scoring                     _computeSmartScore()      (UNCHANGED,
│   │                               legacy-only, Requirement 6.3)
│   │                               _computeStarRating()      (NEW — pure
│   │                               function, replaces the inline stars
│   │                               calc in _completeDragFillLetter,
│   │                               Requirement 5)
│   └── Persistence                 _saveLetterComplete → updateTraceItProgress
│                                    (UNCHANGED call site/signature, both
│                                    paths call it identically —
│                                    Requirement 5.5, 6.6)
└── letter_tracing_data.dart
    ├── LetterData                  (UNCHANGED) flat `points` — still used
    │                               by lowercase/numbers AND by uppercase's
    │                               dashed-outline background render
    ├── uppercaseStrokes            (KEPT, verified) Map<String, List<List<Offset>>>
    │                               — the Stroke_Set data model for A–Z
    ├── lowercaseStrokes            (REMOVED) — was a Requirement 6 violation
    ├── numberStrokes               (REMOVED) — was a Requirement 6 violation
    └── strokesForMode()            (NARROWED) mode 0 only
```

### Data flow for an Uppercase_Letter_Session

```
initState/_onPageChanged/_resetTracing
        │
        ▼
   _initStrokes()  ── reads uppercaseStrokes[letter], magnifies to screen
        │              design space, sets _activeStroke = 0 (or full-complete
        │              if letter already in _completedUpper)
        ▼
GestureDetector.onPanStart ──► _onDragFillStart
        │  inside Stroke_Start_Zone(_activeStroke)?
        │      yes → _dragging=true, _dragAttempts++
        │      no  → feedback "start at the dot", no state change
        ▼
GestureDetector.onPanUpdate ──► _onDragFillUpdate
        │  _projectOntoPolyline(strokes[_activeStroke], dragPoint)
        │      distance > _pathTolerance → _outOfBounds=true, pause progress
        │      distance <= _pathTolerance → forward-only progress update
        │  progress >= 0.85 → _completeActiveStroke()
        ▼
_completeActiveStroke()
        │  strokeProgress[_activeStroke] = 1.0
        │  _activeStroke++ (next incomplete stroke becomes active)
        │  last stroke? → _completeDragFillLetter()
        ▼
_completeDragFillLetter()
        │  stars = _computeStarRating(attempts: _dragAttempts, strokeCount: _strokes.length)
        │  _saveLetterComplete(...) → userProvider.updateTraceItProgress('uppercase', i, true)
        │  award stars*5 points (existing mechanism)
```

## Components and Interfaces

### `LetterData` (existing, unchanged)

```dart
class LetterData {
  final String letter;
  final String sound;
  final String example;
  final Color color;
  final int difficulty;
  final List<Offset> points; // still used for the dashed background glyph
                              // outline & start-marker in BOTH session types
  const LetterData({...});
}
```

Requirement 1.5 requires that the flat `points` list for an uppercase letter equal the concatenation of its `uppercaseStrokes` entry, in order, with identical coordinate values. This is not expressed as a new field — it's a data-consistency invariant between two existing top-level structures (`uppercaseLetters` and `uppercaseStrokes`), checked by a property test (Property 5) and a one-time static assertion helper used in that test:

```dart
/// Testing/verification helper: concatenates a Stroke_Set in order.
/// Not used at runtime — the runtime UI never needs the flattened form
/// (it already has `LetterData.points` for the background glyph and
/// `uppercaseStrokes` for the drag-fill mechanic separately).
List<Offset> flattenStrokes(List<List<Offset>> strokes) =>
    strokes.expand((s) => s).toList();
```

### `uppercaseStrokes` (existing map, verified/kept)

```dart
const Map<String, List<List<Offset>>> uppercaseStrokes = { ... }; // A–Z, see Data Models
```

This is the `Letter_Data_Model`'s Stroke_Set representation for uppercase letters. `List<List<Offset>>` is the concrete Dart shape for "ordered collection of Strokes, each Stroke an ordered list of design-space points."

### `strokesForMode` (narrowed)

```dart
/// Ordered stroke skeletons for the given mode (0=uppercase only) and
/// letter, or null. Lowercase (1) and numbers (2) NEVER have a Stroke_Set —
/// they always return null and therefore always resolve to the legacy
/// freehand mechanic, per Requirement 6.
List<List<Offset>>? strokesForMode(int mode, String letter) {
  if (mode != 0) return null;
  return uppercaseStrokes[letter];
}
```

`lowercaseStrokes`, `numberStrokes`, and `strokesForUppercase` (the redundant single-purpose lookup) are removed from `letter_tracing_data.dart`.

### `_computeStarRating` (new, pure function)

Replaces the inline star calculation currently embedded in `_completeDragFillLetter`, as its own testable pure function:

```dart
/// Completion-based Star_Rating for an Uppercase_Letter_Session.
/// Pure function of Attempt_Count and stroke count — does NOT call
/// _computeSmartScore or any of its proximity/coverage/length/overlap
/// sub-scores (Requirement 5.2).
///
/// "Reasonable attempt range" = one attempt per stroke, plus up to 1 extra
/// restart, i.e. attempts <= strokeCount + 1 is a "clean" run.
int _computeStarRating({required int attempts, required int strokeCount}) {
  final reasonable = strokeCount + 1;
  if (attempts <= reasonable) return 3;
  if (attempts <= reasonable + 3) return 2;
  return 1; // never 0 — reaching Letter_Completion_State always completed
}
```

This matches the thresholds already present in the existing (soon-replaced) inline code (`strokeCount + 1` / `strokeCount + 4`), just extracted into a named, independently testable function, and documents the "reasonable-attempt range" that Requirement 5.3/5.4 refers to design for.

`_completeDragFillLetter` changes from computing stars inline to calling this function:

```dart
void _completeDragFillLetter() {
  if (_isCompleted) return;
  final stars = _computeStarRating(
    attempts: _dragAttempts,
    strokeCount: _strokes.length,
  );
  final earned = stars * 5; // existing points-per-star mechanism, unchanged
  setState(() {
    _isCompleted = true;
    _dragging = false;
    _score += earned;
    _stars += stars;
  });
  _currentCompletedSet.add(_selectedIndex);
  _saveLetterComplete(_selectedMode, _selectedIndex); // same updateTraceItProgress call
  ...
}
```

`_saveLetterComplete` and `userProvider.updateTraceItProgress('uppercase', index, true)` are unchanged — this satisfies Requirement 5.5/5.6 (same persistence mechanism, same points-awarding mechanism, just a different — and now testable — star computation feeding it).

### `_PathProjection` utility (existing free functions, formalized as one namespace for the design doc)

These already exist as top-level functions in `trace_it_screen.dart`. This design keeps them exactly as implemented (they are correct) and documents them as the `PathProjection` utility referenced by the requirements:

```dart
/// Total Euclidean length of a polyline.
double _polylineLength(List<Offset> pts);

/// Sub-polyline from the start up to `fraction` (0..1) of total length.
/// Used by _StrokeFillPainter to render the Stroke_Fill_Indicator.
List<Offset> _partialPolyline(List<Offset> pts, double fraction);

/// Nearest-segment projection: for point `p`, finds the closest point on
/// any segment of the polyline, returning:
///   - progress: arc-length fraction (0..1) of that closest point along
///     the whole polyline (nearest-segment projection + arc-length
///     accumulation, per Requirement 2's projection algorithm)
///   - distance: perpendicular (Euclidean) distance from `p` to that
///     closest point (used against Path_Tolerance_Distance)
({double progress, double distance}) _projectOntoPolyline(
    List<Offset> pts, Offset p);
```

**Projection algorithm** (already implemented, kept as-is):
1. Walk every segment `[pts[i-1], pts[i]]` of the polyline.
2. For each segment, clamp-project `p` onto the segment (`t = clamp(dot(p-a, b-a)/|b-a|², 0, 1)`), getting a candidate point and its distance to `p`.
3. Track the candidate with the smallest distance across all segments.
4. That candidate's `progress` is `(arc length up to that segment + t * segment length) / total polyline length`.
5. Return the best `(progress, distance)` pair.

This correctly implements "nearest-segment projection + arc-length accumulation" — no changes needed here.

### `_StrokeFillPainter` (existing, kept, uppercase-only)

Unchanged rendering logic; documented here for completeness since it's the visual half of the mechanic:

- **Track** (unfilled remainder): every stroke drawn once as a light grey (`Colors.grey.shade200`) round-cap/round-join stroked `Path`, width `26.0 * scale`.
- **Stroke_Fill_Indicator**: for each stroke `i`, `_partialPolyline(strokes[i], strokeProgress[i])` is turned into a `Path` and stroked in the letter's color (or green if the whole letter `isCompleted`), width `24.0 * scale` — 2px narrower than the track so the track's rounded edge remains visible as a subtle outline, which is the "visibly distinguishable" treatment required by 4.2. Because every stroke (not just the active one) is redrawn every frame from `strokeProgress`, completed strokes automatically stay rendered fully filled while a later stroke is active — this directly satisfies Requirement 3.3 with no extra state.
- **Stroke_Start_Zone marker**: numbered pulsing dot + direction arrow drawn only for `activeStroke`, at `strokes[activeStroke].first`, radius `16 * scale * pulse` (pulse animated 0.85–1.0) for the outer glow and a fixed `11 * scale`-radius solid dot — both well within the "no greater than 1.5x rendered stroke width" cap (see Error Handling for the exact numbers).
- **Completed-letter celebration**: unchanged — `_TracePainter`'s `isCompleted` branch (solid green glyph) is reused for the background glyph render regardless of which foreground painter (`_StrokeFillPainter` vs `_TracePainter`) is active, satisfying Requirement 4.4 without duplicating celebration logic.

### Gesture handlers (existing, kept, now provably uppercase-only via narrowed `strokesForMode`)

```dart
void _onDragFillStart(DragStartDetails d) { ... }   // Stroke_Start_Zone hit-test, Attempt_Count++
void _onDragFillUpdate(DragUpdateDetails d) { ... } // projection, tolerance check, forward-only clamp
```

Two behavior fixes are made here relative to the current implementation (see Error Handling for rationale): the off-path feedback now surfaces a visible message (currently it only flashes the container border) and the start-zone-miss feedback timing/next-attempt clearing is made explicit.

## Data Models

### Stroke-grouped shape for uppercase letters

```dart
/// Stroke_Set representation: ordered list of Strokes, each Stroke an
/// ordered list of design-space points (>= 2 points per Stroke).
/// Keyed by the uppercase letter character.
const Map<String, List<List<Offset>>> uppercaseStrokes = { ... };
```

`LetterData.points` (flat `List<Offset>`) continues to be the representation for `lowercaseLetters` and `numberLetters` — **unchanged in structure and values** (Requirement 1.6, 6.5). No `Stroke_Set`-shaped field is added to `LetterData` itself; the Stroke_Set lives in the separate `uppercaseStrokes` map, keyed by letter, exactly as already structured in the codebase. This keeps the two data shapes fully decoupled per-mode rather than adding an optional/nullable field to a shared class.

### Full 26-letter stroke breakdown (uppercase)

This is the exact per-letter decomposition already encoded in `uppercaseStrokes` in `letter_tracing_data.dart`, verified against Requirement 1.2's no-backward-retracing-within-a-stroke rule. "Strokes" column is stroke count; "Classification" reflects Requirement 1.3 (single stroke) vs 1.4 (multi-stroke).

| Letter | Strokes | Classification | Stroke breakdown (in Stroke_Order) |
|---|---|---|---|
| A | 3 | multi-stroke | 1: left leg (top→bottom-left), 2: right leg (top→bottom-right), 3: horizontal crossbar |
| B | 3 | multi-stroke | 1: vertical spine (top→bottom), 2: upper bowl (spine-top→out→back to spine-mid), 3: lower bowl (spine-mid→out→back to spine-bottom) |
| C | 1 | single-stroke | 1: continuous open curve, top-right → around left → bottom-right |
| D | 2 | multi-stroke | 1: vertical spine (top→bottom), 2: bowl curve (spine-top→out right→back to spine-bottom) |
| E | 4 | multi-stroke | 1: vertical spine (top→bottom), 2: top horizontal bar, 3: middle horizontal bar, 4: bottom horizontal bar |
| F | 3 | multi-stroke | 1: vertical spine (top→bottom), 2: top horizontal bar, 3: middle horizontal bar |
| G | 2 | multi-stroke | 1: open curve (like C, continuing further to an inward hook), 2: short horizontal inner bar |
| H | 3 | multi-stroke | 1: left vertical (top→bottom), 2: right vertical (top→bottom), 3: horizontal crossbar |
| I | 3 | multi-stroke | 1: top horizontal serif, 2: vertical spine (top→bottom), 3: bottom horizontal serif |
| J | 1 | single-stroke | 1: continuous path, top→down the spine→curving into the bottom hook |
| K | 3 | multi-stroke | 1: vertical spine (top→bottom), 2: upper diagonal (top-right→spine-middle), 3: lower diagonal (spine-middle→bottom-right) |
| L | 1 | single-stroke | 1: continuous path, top→down→right along the base |
| M | 1 | single-stroke | 1: continuous zig-zag, bottom-left→top-left→middle-peak→top-right→bottom-right |
| N | 1 | single-stroke | 1: continuous zig-zag, bottom-left→top-left→bottom-right→top-right |
| O | 1 | single-stroke | 1: continuous closed curve, top→around→back to top |
| P | 2 | multi-stroke | 1: vertical spine (top→bottom), 2: upper bowl (spine-top→out→back to spine-middle) |
| Q | 2 | multi-stroke | 1: closed curve (same shape as O), 2: short diagonal tail stroke |
| R | 3 | multi-stroke | 1: vertical spine (top→bottom), 2: upper bowl (spine-top→out→back to spine-middle), 3: diagonal leg (spine-middle→bottom-right) |
| S | 1 | single-stroke | 1: continuous S-curve, top-right→left→middle→right→bottom-left |
| T | 2 | multi-stroke | 1: top horizontal bar, 2: vertical spine (top→bottom) |
| U | 1 | single-stroke | 1: continuous curve, top-left down→curve at bottom→up to top-right |
| V | 1 | single-stroke | 1: continuous path, top-left→down to bottom point→up to top-right |
| W | 1 | single-stroke | 1: continuous zig-zag, top-left→down→up-middle-peak→down→up top-right |
| X | 2 | multi-stroke | 1: diagonal top-left→bottom-right, 2: diagonal top-right→bottom-left |
| Y | 3 | multi-stroke | 1: upper-left diagonal (top-left→center), 2: upper-right diagonal (top-right→center), 3: vertical tail (center→bottom) |
| Z | 1 | single-stroke | 1: continuous path, top-left→top-right→diagonal to bottom-left→bottom-right |

This covers all 26 uppercase letters with none omitted (Requirement 1.4's completeness clause), and matches the examples the requirements call out explicitly: single-stroke {C, O, S, L, V} and multi-stroke {A, B, E, F, H, I, K, T, X, Y} — all confirmed as 1-stroke / ≥2-stroke respectively in the table above.

### Interaction/state model

```dart
// Per-Uppercase_Letter_Session state (reset in _initStrokes on letter change):
List<List<Offset>> _strokes;       // magnified Stroke_Set for the current letter
List<double> _strokeProgress;      // Drag_Progress per stroke, 0.0-1.0, forward-only
int _activeStroke;                 // index of the Active_Stroke; == strokes.length
                                    // once Letter_Completion_State is reached
int _dragAttempts;                 // Attempt_Count for this session
bool _dragging;                    // true while a qualifying drag is in progress
bool _outOfBounds;                 // true while current drag position is beyond
                                    // Path_Tolerance_Distance from the active path

// Fixed constants (Requirement 2.10, 2.11):
static const double _startZoneRadius = 30.0;       // design-space units
static const double _pathTolerance = 42.0;         // design-space units — see
                                                    // Error Handling for justification
static const double _strokeCompleteThreshold = 0.85; // Stroke_Completion_Threshold
```

**Path_Tolerance_Distance justification**: strokes render with a track width of `26.0` design-space units (see `_StrokeFillPainter.trackWidth`) and a fill width of `24.0`. A child's fingertip contact area is wide and imprecise relative to a mouse/stylus, so the tolerance must comfortably exceed half the visual stroke width or the child will constantly trigger the off-path state while still visibly "on" the drawn track. `42.0` (~1.6x the track half-width of 13.0, i.e. roughly the full track width) is chosen so the entire visual stroke — plus a small margin — counts as "on the stroke," while still rejecting drags that stray meaningfully outside the glyph's local area (adjacent strokes in the same letter are typically ≥30 design units apart, so `42.0` does not accidentally bridge two unrelated strokes together). This is the existing constant already present in the code; this design keeps it and documents the reasoning per Requirement 2.10's "defined in design" clause.

**Stroke_Start_Zone radius vs. rendered stroke width**: rendered stroke width is `26.0` (track) design-space units before the `scale` transform is applied on screen; `1.5x` of that is `39.0`. The current `_startZoneRadius = 30.0` is comfortably within this cap (satisfies Requirement 2.2/Glossary's "no greater than 1.5x").

### Forward-only progress computation

```
newProgress = _projectOntoPolyline(activeStroke, dragPoint).progress
if newProgress > _strokeProgress[activeStroke] AND distance <= _pathTolerance:
    _strokeProgress[activeStroke] = newProgress
else:
    # backward movement or off-path: no change to recorded progress
    pass
```

This is exactly the existing `_onDragFillUpdate` logic (`if (proj.progress > _strokeProgress[_activeStroke])`), which already satisfies Requirement 2.5/2.6/2.7's "advance only forward, never regress below highest value, pause while off-path" semantics. No change needed to this computation itself.

## Error Handling

| Condition | Requirement | Current behavior | Design fix |
|---|---|---|---|
| Drag starts outside Active_Stroke's Stroke_Start_Zone | 2.4 | Shows a 2-second feedback banner via `_showFeedback`, does not increment Attempt_Count or start tracking — correct, but the spec requires clearing after **3 seconds or next drag start**, whichever first. | Keep `_showFeedback`'s existing "clear after N seconds" behavior but change its duration to 3000ms for this specific message, and additionally clear it immediately inside `_onDragFillStart` before evaluating the new attempt (so a new drag-start always supersedes the old banner). |
| Drag starts inside a non-active stroke's Stroke_Start_Zone (Requirement 3.4) | 3.4 | Not currently handled — `_onDragFillStart` only checks `_strokes[_activeStroke]`, so starting inside a *different*, non-active stroke's zone falls through to the "outside zone" `else` branch, showing the generic "start at the dot" message rather than a "trace the highlighted stroke next" message. | Before the start-zone distance check, iterate all strokes; if the drag start is within `_startZoneRadius` of a **non-active** stroke's first point, show a distinct message ("that part comes later — trace the highlighted stroke first") without incrementing Attempt_Count, instead of falling through to the generic message. |
| Drag moves beyond Path_Tolerance_Distance mid-stroke | 2.6, 4.5 | Sets `_outOfBounds = true` and flashes the canvas border orange via `_warningController` — visually distinct from the fill indicator, and does not erase `_strokeProgress` (correct, since progress is simply not updated while off-path). | Keep the border flash, but also surface a short text feedback (reusing `_showFeedback`, e.g. "stay on the path") so the "off-path" signal is legible, not just a color flash — satisfies 4.5's "display feedback...visually distinct from the Stroke_Fill_Indicator" more robustly. Feedback clears automatically once `_outOfBounds` flips back to `false` (drag returns within tolerance) or via the existing timer, whichever first. |
| Drag moves backward along the path | 2.7 | `_strokeProgress[_activeStroke]` is only updated when `proj.progress > _strokeProgress[_activeStroke]`, so backward movement is a no-op — correct already. | No change; documented and covered by Property 6/7. |
| Progress crosses threshold mid-drag (before release) | 2.9 | `_onDragFillUpdate` checks `_strokeProgress[_activeStroke] >= _strokeCompleteThreshold` immediately after updating, calling `_completeActiveStroke()` synchronously — correct, completion doesn't wait for release. | No change; covered by Property 9. |
| Letter/mode switch mid-drag (Requirement 6.4) | 6.4 | `_onPageChanged`/`_resetTracing` call `_initStrokes()` which fully resets `_strokes`, `_strokeProgress`, `_activeStroke`, `_dragAttempts`, `_dragging` — and separately resets `_tracedPoints`/`_visitedPoints` for the legacy path. Because these are two disjoint state groups already, switching mode never leaks one into the other. | No structural change needed; add a regression property test (Property 15) that asserts uppercase-only state is all at its initial/reset values immediately after any transition into a Legacy_Tracing_Session, and vice versa. |
| Uppercase letter has no `uppercaseStrokes` entry (defensive) | — (not explicitly required, but 1.4 requires full A–Z coverage) | `_useDragFill` would be `false` and the letter would silently fall back to the legacy freehand mechanic for that one letter. | Keep as a safe fallback (never crashes), but Property 3 (full A–Z coverage) is a hard gate that should make this case unreachable in practice — treated as a defensive fallback, not the primary path. |
| Star_Rating computation given Attempt_Count == 0 (defensive; can't normally happen since completion requires ≥1 attempt) | 5.7 | N/A (attempts is always ≥1 by the time completion is reached, since starting a stroke drag is what increments it) | `_computeStarRating` is a total function over all non-negative integers and always returns ≥1, so even a defensive/theoretical 0-attempt call is still safe and satisfies 5.7. |

## Testing Strategy

**Unit tests** (specific examples, edge cases, integration points):
- `_computeStarRating`: exact boundary examples (`attempts == strokeCount+1` → 3, `attempts == strokeCount+2` → 2, `attempts == strokeCount+5` → 2, `attempts == strokeCount+6` → 1) for a couple of concrete `strokeCount` values (1, 3, 4).
- Named single-stroke set {C, O, S, L, V} and multi-stroke set {A, B, E, F, H, I, K, T, X, Y} explicit membership checks against `uppercaseStrokes`.
- `_onDragFillStart` outside-zone feedback message text/color, and that it's cleared by a subsequent drag start (example, since this is a discrete two-trigger clearing rule, not a universal property).
- `_onDragFillStart` inside-a-non-active-stroke's-zone feedback message (distinct copy from the generic miss message).
- Legacy path (`_computeSmartScore`, `_checkTracing`, `_completeTracing`) completion still awards flat 15 pts / 3 stars for a representative lowercase letter and a representative number — regression example.
- `strokesForMode(1, 'a')` / `strokesForMode(2, '5')` return `null` — direct example, guards the Requirement 6 fix.

**Property tests** (minimum 100 iterations each, `dart:math`'s `Random` with a fixed seed for reproducibility, no new packages required — hand-rolled generators over `uppercaseLetters`/`uppercaseStrokes` keys and synthetic point sequences):

- Property 1 (Stroke_Set shape) — generate random uppercase letters, assert `uppercaseStrokes[letter]` is non-empty and every stroke has `length >= 2`.
- Property 2 (no backward retrace within a stroke) — for random strokes, assert no two points are coordinate-identical and cumulative arc-length is strictly increasing point-to-point (0-length segments excluded).
- Property 3 (26-letter coverage & classification) — for all 26 letters A-Z, assert an entry exists; for the named single/multi-stroke subsets, assert stroke count == 1 / >= 2 respectively.
- Property 4 (flatten round-trip) — for random uppercase letters, `flattenStrokes(uppercaseStrokes[letter]) == uppercaseLetters[i].points`.
- Property 5 (lowercase/number structural non-regression) — for random lowercase/number entries, `strokesForMode(mode, letter) == null` and `LetterData.points` is unchanged (snapshot equality against the pre-feature literal values).
- Property 6 (Active_Stroke invariant) — for random Stroke_Sets and random valid completion-order prefixes, Active_Stroke always equals the first incomplete stroke index (or `strokes.length` once all complete); a completed stroke index is never reassigned as active afterward.
- Property 7 (Stroke_Start_Zone radius bound) — for random strokes, computed marker radius `<= 1.5 * renderedStrokeWidth`.
- Property 8 (start-zone hit-test correctness) — for random points at varying distances from a stroke's first point, dragging starts tracking and increments Attempt_Count iff distance `<= _startZoneRadius`; otherwise both remain unchanged.
- Property 9 (forward-only, no-regression progress) — for random drag-point sequences (including ones that move backward or jitter), the recorded `_strokeProgress` sequence over time is non-decreasing and always equals the max of all `progress` values seen so far where `distance <= _pathTolerance`.
- Property 10 (off-path pauses, doesn't erase) — for random sequences that exceed tolerance then return, progress recorded during the excursion never changes, and `_outOfBounds` is true iff current distance `> _pathTolerance`.
- Property 11 (threshold-crossing completes immediately) — for random progress trajectories crossing 0.85, the stroke is marked complete (`_strokeProgress[i] == 1.0`, `_activeStroke` advances) at the first point progress `>= 0.85`, independent of release state.
- Property 12 (fill-indicator geometry matches progress) — for random progress values in [0,1] and random strokes, `_partialPolyline(stroke, progress)`'s arc length equals `progress * _polylineLength(stroke)` within floating-point epsilon.
- Property 13 (completed strokes stay rendered filled) — for random letters with a random subset of strokes marked complete and one later stroke active, every completed stroke's rendered fill fraction is `1.0` regardless of which stroke is active.
- Property 14 (Letter_Completion_State terminal invariant) — for any Stroke_Set, driving every stroke's progress to `>= 0.85` in order always results in `_activeStroke == strokes.length` and no further Active_Stroke designation.
- Property 15 (session-type isolation) — for random sequences of mode switches interleaved with drag-fill progress, uppercase-only state (`_strokes`, `_strokeProgress`, `_activeStroke`, `_dragAttempts`) is fully reset whenever the session transitions into or out of a Legacy_Tracing_Session, and legacy-only state (`_tracedPoints`, `_visitedPoints`, `_overlapGrid`) is never touched during an Uppercase_Letter_Session.
- Property 16 (star-rating threshold function) — for random non-negative `attempts` and `strokeCount`, `_computeStarRating` returns `3` iff `attempts <= strokeCount + 1`, returns `1` iff `attempts > strokeCount + 4`, returns `2` otherwise, and is never `< 1`.
- Property 17 (points-per-star consistency) — for random computed star ratings in `{1,2,3}`, awarded points `== stars * 5` (the existing points-per-star mechanism).
- Property 18 (scoring-path exclusivity) — for random uppercase completions, `_computeSmartScore` is never invoked (spy/mock the call); for random lowercase/number completions, `_computeStarRating` is never invoked and awarded points/stars always equal the fixed legacy values (15 / 3).

Both test types are complementary: unit tests pin down specific UX copy, boundary examples, and the Requirement 6 regression guards; property tests exhaustively validate the geometric/state-machine invariants (projection, forward-only progress, sequencing, scoring thresholds) that the drag-fill mechanic's correctness actually rests on.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Stroke_Set shape validity

For all uppercase letters A–Z, the Stroke_Set has at least one Stroke, and every Stroke in it contains at least 2 points.

**Validates: Requirements 1.1**

### Property 2: No backward retracing within a Stroke

For any Stroke belonging to any uppercase letter's Stroke_Set, no point coordinate repeats an earlier point in that same Stroke, and the cumulative arc length strictly increases from point to point.

**Validates: Requirements 1.2**

### Property 3: Full 26-letter stroke-count classification

For all 26 uppercase letters A–Z, a Stroke_Set entry exists; for any letter in {C, O, S, L, V} the Stroke_Set has exactly one Stroke, and for any letter in {A, B, E, F, H, I, K, T, X, Y} the Stroke_Set has two or more Strokes.

**Validates: Requirements 1.3, 1.4**

### Property 4: Concatenated strokes reproduce the flat point list

For any uppercase letter, concatenating its Strokes in Stroke_Order produces a point list identical in length, order, and coordinate values to that letter's pre-existing flat `points` list.

**Validates: Requirements 1.5**

### Property 5: Lowercase/number data shape is unaffected

For any lowercase letter or number, `strokesForMode` returns null and that letter's/number's `points` list structure and values remain exactly as they were before this feature.

**Validates: Requirements 1.6, 6.5**

### Property 6: Active_Stroke is always the first incomplete Stroke

For any Stroke_Set and any sequence of Stroke completions applied in Stroke_Order, the Active_Stroke is always the first Stroke that has not yet reached the Stroke_Completion_Threshold, and once a Stroke reaches that threshold it is never redesignated as the Active_Stroke again for the remainder of the session.

**Validates: Requirements 2.1, 3.1, 3.2**

### Property 7: Stroke_Start_Zone radius bound

For any Active_Stroke, the rendered Stroke_Start_Zone marker's radius is no greater than 1.5 times the rendered stroke width, and is centered at the Active_Stroke's first point.

**Validates: Requirements 2.2**

### Property 8: Start-zone hit-test gates tracking and Attempt_Count

For any drag start position and any Active_Stroke, Drag_Progress tracking begins and Attempt_Count increments by exactly 1 if and only if the start position is within the Stroke_Start_Zone radius of the Active_Stroke's first point; otherwise neither changes.

**Validates: Requirements 2.3, 2.4**

### Property 9: Drag_Progress is forward-only and never regresses

For any sequence of drag positions along or near an Active_Stroke's path, the recorded Drag_Progress at every step is greater than or equal to its value at the previous step, and equals the highest progress value reached by any prior position that was within the Path_Tolerance_Distance of the path.

**Validates: Requirements 2.5, 2.7**

### Property 10: Off-path drag pauses progress without erasing it

For any sequence of drag positions that moves beyond the Path_Tolerance_Distance from the Active_Stroke's path and later returns within it, Drag_Progress does not increase while beyond tolerance, is not reduced by the excursion, and resumes increasing once the position returns within tolerance.

**Validates: Requirements 2.6, 4.5**

### Property 11: Threshold crossing completes a Stroke immediately

For any drag trajectory whose Drag_Progress reaches the Stroke_Completion_Threshold at any point, that Stroke is marked complete and rendered fully filled at that moment, regardless of whether the drag gesture has since been released.

**Validates: Requirements 2.9, 4.3**

### Property 12: Stroke_Fill_Indicator geometry matches Drag_Progress

For any Stroke and any Drag_Progress value between 0.0 and 1.0, the arc length of the rendered filled portion equals Drag_Progress multiplied by the Stroke's total path length, within floating-point tolerance.

**Validates: Requirements 4.1, 4.2**

### Property 13: Completed Strokes remain visibly filled while later Strokes are active

For any Stroke_Set in which one or more Strokes are complete and a later Stroke in Stroke_Order is the Active_Stroke, every completed Stroke's rendered fill fraction is 1.0, independent of which Stroke is currently active.

**Validates: Requirements 3.3**

### Property 14: Non-active Stroke start attempts are rejected with distinguishing feedback

For any Stroke in a Stroke_Set that is not the current Active_Stroke, a drag starting inside that Stroke's Stroke_Start_Zone does not begin Drag_Progress tracking for it and does not increment Attempt_Count.

**Validates: Requirements 3.4**

### Property 15: Letter_Completion_State is the correct terminal state

For any Stroke_Set, driving every Stroke's Drag_Progress to the Stroke_Completion_Threshold in Stroke_Order always results in Letter_Completion_State being set and no further Active_Stroke being designated.

**Validates: Requirements 3.5**

### Property 16: Session-type state isolation

For any sequence of transitions between an Uppercase_Letter_Session and a Legacy_Tracing_Session, Active_Stroke, per-stroke Drag_Progress, and Attempt_Count are fully reset whenever entering an Uppercase_Letter_Session, and are never read or mutated while a Legacy_Tracing_Session is active.

**Validates: Requirements 6.4**

### Property 17: Uppercase and legacy scoring paths are mutually exclusive

For any Uppercase_Letter_Session completion, the freehand `_computeSmartScore` heuristic (and its proximity, coverage, path-length, and overlap sub-scores) is never invoked; for any Legacy_Tracing_Session completion, the completion-based Star_Rating function is never invoked and the awarded points and stars equal the fixed pre-existing legacy values.

**Validates: Requirements 5.1, 5.2, 6.1, 6.2, 6.3, 6.6**

### Property 18: Star_Rating threshold function

For any non-negative Attempt_Count and any Stroke_Set size, the computed Star_Rating equals 3 when Attempt_Count is within the reasonable-attempt range, equals a value in {1, 2} when Attempt_Count exceeds that range, and is never less than 1.

**Validates: Requirements 5.3, 5.4, 5.7**

### Property 19: Awarded points correspond to Star_Rating

For any computed Star_Rating in {1, 2, 3}, the points awarded through the existing points-awarding mechanism equal that rating multiplied by the fixed per-star point value.

**Validates: Requirements 5.6**
