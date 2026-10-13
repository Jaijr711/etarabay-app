# Implementation Plan: Trace It Drag-Fill (Targeted Fix)

## Overview

The guided drag-fill mechanic described in the design is **already substantially implemented** in `lib/screens/trace_it_screen.dart` (`_StrokeFillPainter`, `_onDragFillStart`/`_onDragFillUpdate`, `_completeActiveStroke`, `_completeDragFillLetter`) and `lib/data/letter_tracing_data.dart` (`uppercaseStrokes`, `strokesForMode`). This plan is therefore a **targeted fix/refactor**, not a from-scratch build. It addresses the concrete gaps between the current code and the spec:

1. `strokesForMode` currently routes ALL THREE modes through stroke data, so lowercase/numbers wrongly get the drag-fill mechanic instead of staying on `_computeSmartScore` (Requirement 6 regression — highest priority).
2. `_strokeCompleteThreshold` is `0.9` in code but must be `0.85` per Requirement 2.11 / design.
3. Star-rating math is inline in `_completeDragFillLetter` instead of the named, testable `_computeStarRating` function the design specifies.
4. Starting a drag inside a non-active stroke's start zone isn't distinguished from missing the zone entirely (Requirement 3.4).
5. Off-path drags only flash a border color with no text feedback (Requirement 4.5).
6. The 26-letter stroke classification table in design.md needs verification against the real `uppercaseStrokes` data, and any drift between `uppercaseLetters[i].points` and the flattened `uppercaseStrokes` entries (Requirement 1.5) needs to be found and fixed.

No new packages or assets are introduced. `flutter_test` (via the `flutter_test: sdk: flutter` dev dependency already in `pubspec.yaml`) is used for all unit and property tests; property tests are hand-rolled using `dart:math`'s `Random` with a fixed seed, per the design's Testing Strategy — no new test package is needed.

**Testing note for implementers:** Several functions the design calls out (`_computeStarRating`, `_polylineLength`, `_partialPolyline`, `_projectOntoPolyline`, and the gesture handlers) are library-private (leading underscore) top-level/class members of `trace_it_screen.dart` and cannot be imported directly from a separate test file. Follow the pattern already established in `test/letter_tracing_fill_bug_test.dart`: mirror the exact algorithm inside the test file for pure-logic properties, and use `WidgetTester`-driven drag gestures plus `find.text(...)` assertions for anything only observable through the UI (feedback messages). `strokesForMode`, `uppercaseStrokes`, `lowercaseLetters`, `numberLetters`, and `flattenStrokes` in `letter_tracing_data.dart` have no leading underscore and ARE directly importable/testable.

## Tasks

- [x] 1. Fix the uppercase-only mode-routing regression in `letter_tracing_data.dart`
  - [x] 1.1 Narrow `strokesForMode` to uppercase only and remove the lowercase/number stroke maps
    - In `lib/data/letter_tracing_data.dart`, change `strokesForMode(int mode, String letter)` (currently a `switch` at the bottom of the file returning `uppercaseStrokes[letter]` / `lowercaseStrokes[letter]` / `numberStrokes[letter]`) to: `if (mode != 0) return null; return uppercaseStrokes[letter];`
    - Delete the `const Map<String, List<List<Offset>>> lowercaseStrokes = { ... }` block (under the "LOWERCASE STROKE SKELETONS" header) and the `const Map<String, List<List<Offset>>> numberStrokes = { ... }` block (under the "NUMBER STROKE SKELETONS" header) in their entirety.
    - Delete the now-redundant `List<List<Offset>>? strokesForUppercase(String letter) => uppercaseStrokes[letter];` helper (it duplicates the narrowed `strokesForMode(0, letter)`); confirm no call sites reference it before deleting (none should, per current usage in `trace_it_screen.dart`).
    - In `lib/screens/trace_it_screen.dart`, update the `_useDragFill` getter to add the explicit mode guard so the gate is structurally uppercase-only even if `strokesForMode` is ever changed again: `bool get _useDragFill => _selectedMode == 0 && strokesForMode(_selectedMode, _currentLetter.letter) != null;`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  - [x] 1.2 Add the `flattenStrokes` derivation helper
    - Add the public top-level function `List<Offset> flattenStrokes(List<List<Offset>> strokes) => strokes.expand((s) => s).toList();` to `lib/data/letter_tracing_data.dart` near `uppercaseStrokes`/`strokesForMode`, matching the design's `flattenStrokes` signature exactly.
    - _Requirements: 1.5_
  - [ ]* 1.3 Write unit tests guarding the Requirement 6 regression fix
    - New test file `test/letter_tracing_data_test.dart`. Assert `strokesForMode(1, 'a') == null` and `strokesForMode(2, '5') == null` directly (mirrors the design's stated regression-guard example).
    - Assert `lowercaseStrokes` and `numberStrokes` are no longer defined (compile-time — the test file simply must not reference them; the absence itself is verified by the file compiling after their removal).
    - Assert `lowercaseLetters` and `numberLetters` still expose only the flat `points` list structure (no stroke-set field added) by checking `LetterData` field access compiles unchanged.
    - _Requirements: 6.4, 6.5_
  - [ ]* 1.4 Write property test for Property 5 (lowercase/number structural non-regression)
    - **Property 5: Lowercase/number data shape is unaffected**
    - **Validates: Requirements 1.6, 6.5**
    - In `test/letter_tracing_data_test.dart`, generate random indices into `lowercaseLetters` and `numberLetters` (mode 1 and 2) with a seeded `Random`, run >= 100 iterations, and assert `strokesForMode(mode, letter) == null` for every sampled entry, and that each entry's `points` list length/values match a hard-coded snapshot list captured from the pre-feature literals (use a handful of representative letters/numbers as the snapshot set, e.g. 'a', 'm', 'z', '1', '8', '10').

- [ ] 2. Verify and correct the uppercase Stroke_Set data model
  - [-] 2.1 Verify the 26-letter classification table against real `uppercaseStrokes` data and fix any discrepancies
    - Cross-check every entry in `uppercaseStrokes` (A–Z) in `lib/data/letter_tracing_data.dart` against design.md's "Full 26-letter stroke breakdown (uppercase)" table: confirm actual stroke count matches the table's "Strokes" column, and that {C, O, S, L, V} have exactly 1 stroke while {A, B, E, F, H, I, K, T, X, Y} have >= 2 strokes.
    - For any letter whose current `uppercaseStrokes` entry contradicts the table (wrong stroke count) or violates the no-backward-retracing-within-a-stroke rule (Requirement 1.2 — a point coordinate repeating an earlier point in the same stroke, or arc length not strictly increasing), fix that letter's stroke entry in place so it satisfies both the table and Requirement 1.2.
    - For any letter where `uppercaseStrokes[letter]`, when flattened in order, does not reproduce `uppercaseLetters[i].points` exactly (same length, order, and coordinate values — Requirement 1.5), fix either the `uppercaseStrokes` entry or the `points` list (whichever has drifted from the other) so they match.
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  - [ ]* 2.2 Write property test for Property 1 (Stroke_Set shape validity)
    - **Property 1: Stroke_Set shape validity**
    - **Validates: Requirements 1.1**
    - In `test/letter_tracing_data_test.dart`, generate >= 100 random uppercase letters (seeded `Random` over `uppercaseLetters`), assert `uppercaseStrokes[letter]` is non-empty and every stroke in it has `length >= 2`.
  - [ ]* 2.3 Write property test for Property 2 (no backward retracing within a Stroke)
    - **Property 2: No backward retracing within a Stroke**
    - **Validates: Requirements 1.2**
    - In `test/letter_tracing_data_test.dart`, for >= 100 randomly sampled strokes across all of `uppercaseStrokes`, assert no two points in the same stroke are coordinate-identical and that cumulative arc length strictly increases from point to point (0-length segments fail the property).
  - [ ]* 2.4 Write property test for Property 3 (26-letter coverage & classification)
    - **Property 3: Full 26-letter stroke-count classification**
    - **Validates: Requirements 1.3, 1.4**
    - In `test/letter_tracing_data_test.dart`, iterate all 26 letters A–Z and assert an `uppercaseStrokes` entry exists for each; assert `{'C','O','S','L','V'}` each have exactly 1 stroke; assert `{'A','B','E','F','H','I','K','T','X','Y'}` each have `>= 2` strokes.
  - [ ]* 2.5 Write property test for Property 4 (concatenated strokes reproduce the flat point list)
    - **Property 4: Concatenated strokes reproduce the flat point list**
    - **Validates: Requirements 1.5**
    - In `test/letter_tracing_data_test.dart`, for >= 100 randomly sampled uppercase letters, assert `flattenStrokes(uppercaseStrokes[letter]) == uppercaseLetters.firstWhere((l) => l.letter == letter).points` (same length, order, and coordinate values).

- [~] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Fix and harden the drag-fill gesture/scoring mechanic in `trace_it_screen.dart`
  - [x] 4.1 Fix the Stroke_Completion_Threshold constant
    - Change `static const double _strokeCompleteThreshold = 0.9;` to `static const double _strokeCompleteThreshold = 0.85;` (currently declared alongside `_startZoneRadius`/`_pathTolerance` in `_TraceItScreenState`).
    - _Requirements: 2.11_
  - [-] 4.2 Extract `_computeStarRating` as a named pure function and update the call site
    - Add a new function `int _computeStarRating({required int attempts, required int strokeCount})` implementing `final reasonable = strokeCount + 1; if (attempts <= reasonable) return 3; if (attempts <= reasonable + 3) return 2; return 1;` — matching the existing inline thresholds (`strokeCount + 1` / `strokeCount + 4`) exactly, just named and pulled out of `_completeDragFillLetter`.
    - In `_completeDragFillLetter` (currently computes `stars` inline via an `if`/`else if`/`else` on `_dragAttempts` and `strokeCount`), replace the inline block with `final stars = _computeStarRating(attempts: _dragAttempts, strokeCount: _strokes.length);` and keep `final earned = stars * 5;` and the rest of the function unchanged.
    - _Requirements: 5.1, 5.2, 5.7_
  - [ ]* 4.3 Write unit tests for `_computeStarRating` boundary examples
    - Mirror the algorithm from 4.2 in a new test file `test/trace_it_drag_fill_test.dart` (it is library-private, so replicate rather than import). Assert: `attempts == strokeCount+1` → 3, `attempts == strokeCount+2` → 2, `attempts == strokeCount+5` → 2, `attempts == strokeCount+6` → 1, for `strokeCount` in `{1, 3, 4}`.
    - _Requirements: 5.3, 5.4_
  - [ ]* 4.4 Write property test for Property 18 (star-rating threshold function)
    - **Property 18: Star_Rating threshold function**
    - **Validates: Requirements 5.3, 5.4, 5.7**
    - In `test/trace_it_drag_fill_test.dart`, using the mirrored `_computeStarRating` replica, generate >= 100 random non-negative `(attempts, strokeCount)` pairs and assert: result `== 3` iff `attempts <= strokeCount + 1`; result `== 1` iff `attempts > strokeCount + 4`; result `== 2` otherwise; result is never `< 1`.
  - [ ]* 4.5 Write property test for Property 19 (awarded points correspond to Star_Rating)
    - **Property 19: Awarded points correspond to Star_Rating**
    - **Validates: Requirements 5.6**
    - In `test/trace_it_drag_fill_test.dart`, for >= 100 random star ratings in `{1,2,3}` (mirroring `final earned = stars * 5;` from `_completeDragFillLetter`), assert awarded points `== stars * 5`.
  - [~] 4.6 Add distinguishing feedback for drags starting inside a non-active stroke's start zone
    - In `_onDragFillStart` (currently only checks `_strokes[_activeStroke].first` and falls through to the generic `AppLocalizations.of(context)!.startAtDot` message otherwise), before the existing active-stroke distance check, loop over all strokes with index `!= _activeStroke` and check if `(designPt - stroke.first).distance <= _startZoneRadius`. If so, call `_showFeedback` with a new distinct message (do not increment `_dragAttempts`, do not set `_dragging`) instead of falling through to the generic "start at the dot" branch.
    - Add a new localization key (e.g. `traceHighlightedStroke`, English text "That part comes later — trace the highlighted stroke first!") to `lib/l10n/app_en.arb` (and mirror placeholder entries in `app_fil.arb`/`app_ilo.arb` alongside the existing `startAtDot` key so the app continues to build for all locales), then reference it via `AppLocalizations.of(context)!.traceHighlightedStroke` in the new branch. Run the project's localization codegen (`flutter gen-l10n` or the existing build step that regenerates `app_localizations*.dart`) so the new getter compiles.
    - _Requirements: 3.4_
  - [ ]* 4.7 Write unit test for the non-active-stroke feedback message
    - In `test/trace_it_drag_fill_test.dart`, use `WidgetTester` to pump `TraceItScreen` (wrapped with the app's required providers/localization, matching the setup pattern used elsewhere in the test suite or `widget_test.dart`), navigate to a multi-stroke uppercase letter (e.g. 'B'), simulate a drag starting inside stroke 2's start zone while stroke 0 is active, and assert `find.text` shows the new distinct message rather than the generic `startAtDot` text, and that `_dragAttempts`-driven behavior (no stroke progress change) holds by checking the letter's completion state is unaffected.
    - _Requirements: 3.4_
  - [ ]* 4.8 Write property test for Property 14 (non-active stroke start attempts rejected)
    - **Property 14: Non-active Stroke start attempts are rejected with distinguishing feedback**
    - **Validates: Requirements 3.4**
    - In `test/trace_it_drag_fill_test.dart`, mirror the start-zone hit-test logic (active-stroke check plus the new non-active-stroke check from 4.6) as a pure replica function, generate >= 100 random `(activeStroke, targetStrokeIndex, strokeCount)` combinations where `targetStrokeIndex != activeStroke`, and assert Drag_Progress tracking never begins and Attempt_Count never increments for the non-active target.
  - [~] 4.9 Add off-path text feedback alongside the existing border flash
    - In `_onDragFillUpdate` (currently: `if (proj.distance > _pathTolerance) { if (!_outOfBounds) { setState(() => _outOfBounds = true); _warningController.forward(from: 0).then((_) => _warningController.reverse()); } return; }`), add a call to `_showFeedback` with a short new message (e.g. via a new localization key `stayOnPath`, English text "Stay on the path!") inside the `if (!_outOfBounds)` block, alongside the existing border-flash logic — do not remove or alter the border flash.
    - Add the new `stayOnPath` key to `lib/l10n/app_en.arb` (and `app_fil.arb`/`app_ilo.arb`) next to `startAtDot`/`almostThere`, and regenerate localizations.
    - Ensure the feedback clears once `_outOfBounds` flips back to `false` (the drag returns within tolerance) or via `_showFeedback`'s existing auto-clear timer, whichever occurs first — reuse the existing `_showFeedback` clearing mechanism rather than adding new timer state.
    - _Requirements: 4.5_
  - [ ]* 4.10 Write unit test confirming off-path feedback appears and clears correctly
    - In `test/trace_it_drag_fill_test.dart`, using `WidgetTester`, drag along an active stroke's path, then drag beyond `_pathTolerance`, and assert the new off-path feedback text appears while `_outOfBounds` is true; then drag back within tolerance and assert the feedback clears and previously filled `_strokeProgress` for that stroke is unchanged (not erased).
    - _Requirements: 4.5_
  - [ ]* 4.11 Write property test for Property 10 (off-path drag pauses progress without erasing it)
    - **Property 10: Off-path drag pauses progress without erasing it**
    - **Validates: Requirements 2.6, 4.5**
    - In `test/trace_it_drag_fill_test.dart`, mirror the forward-only/tolerance-gated progress update logic from `_onDragFillUpdate` as a pure replica, generate >= 100 random drag-position sequences that move beyond tolerance and later return within it, and assert Drag_Progress does not increase while beyond tolerance, is not reduced by the excursion, and resumes increasing once back within tolerance.
  - [ ]* 4.12 Write property test for Property 6 (Active_Stroke is always the first incomplete Stroke)
    - **Property 6: Active_Stroke is always the first incomplete Stroke**
    - **Validates: Requirements 2.1, 3.1, 3.2**
    - In `test/trace_it_drag_fill_test.dart`, mirror the `_activeStroke` advancement logic from `_completeActiveStroke` (increment on completion, never revisit a completed index), generate >= 100 random Stroke_Sets and random valid completion-order prefixes, and assert Active_Stroke always equals the first incomplete stroke index (or `strokes.length` once all complete), and a completed index is never reassigned as active.
  - [ ]* 4.13 Write property test for Property 7 (Stroke_Start_Zone radius bound)
    - **Property 7: Stroke_Start_Zone radius bound**
    - **Validates: Requirements 2.2**
    - In `test/trace_it_drag_fill_test.dart`, assert the fixed constants satisfy `_startZoneRadius (30.0) <= 1.5 * trackWidth (26.0 == 39.0)` as a direct numeric check, and generate >= 100 random strokes to confirm the marker is always centered at `stroke.first` (mirroring `_StrokeFillPainter._drawStartMarker`'s `at` parameter derivation).
  - [ ]* 4.14 Write property test for Property 8 (start-zone hit-test gates tracking and Attempt_Count)
    - **Property 8: Start-zone hit-test gates tracking and Attempt_Count**
    - **Validates: Requirements 2.3, 2.4**
    - In `test/trace_it_drag_fill_test.dart`, mirror `_onDragFillStart`'s distance check, generate >= 100 random points at varying distances from a stroke's first point, and assert tracking begins and Attempt_Count increments by exactly 1 iff `distance <= _startZoneRadius`; otherwise both remain unchanged.
  - [ ]* 4.15 Write property test for Property 9 (Drag_Progress is forward-only and never regresses)
    - **Property 9: Drag_Progress is forward-only and never regresses**
    - **Validates: Requirements 2.5, 2.7**
    - In `test/trace_it_drag_fill_test.dart`, mirror the forward-only update (`if (proj.progress > cur) ...`) from `_onDragFillUpdate`, generate >= 100 random drag-point sequences (including backward and jittering movement), and assert recorded progress at every step is `>=` its previous value and equals the max in-tolerance progress seen so far.
  - [ ]* 4.16 Write property test for Property 11 (threshold crossing completes a Stroke immediately)
    - **Property 11: Threshold crossing completes a Stroke immediately**
    - **Validates: Requirements 2.9, 4.3**
    - In `test/trace_it_drag_fill_test.dart`, mirror the `_strokeProgress[_activeStroke] >= _strokeCompleteThreshold` check and `_completeActiveStroke` transition, generate >= 100 random progress trajectories crossing 0.85, and assert the stroke is marked complete (`progress == 1.0`, active index advances) at the first point progress `>= 0.85`, independent of release state.
  - [ ]* 4.17 Write property test for Property 12 (Stroke_Fill_Indicator geometry matches Drag_Progress)
    - **Property 12: Stroke_Fill_Indicator geometry matches Drag_Progress**
    - **Validates: Requirements 4.1, 4.2**
    - In `test/trace_it_drag_fill_test.dart`, mirror `_partialPolyline`/`_polylineLength` from `trace_it_screen.dart`, generate >= 100 random `(stroke, progress)` pairs with `progress` in `[0,1]`, and assert the arc length of `_partialPolyline(stroke, progress)` equals `progress * _polylineLength(stroke)` within floating-point epsilon.
  - [ ]* 4.18 Write property test for Property 13 (completed Strokes remain visibly filled)
    - **Property 13: Completed Strokes remain visibly filled while later Strokes are active**
    - **Validates: Requirements 3.3**
    - In `test/trace_it_drag_fill_test.dart`, mirror the `_StrokeFillPainter` fill-fraction rule (every stroke's rendered fill fraction is read directly from `strokeProgress[i]` regardless of `activeStroke`), generate >= 100 random Stroke_Sets with a random subset of strokes marked complete and one later stroke active, and assert every completed stroke's fill fraction is `1.0`.
  - [ ]* 4.19 Write property test for Property 15 (Letter_Completion_State terminal invariant)
    - **Property 15: Letter_Completion_State is the correct terminal state**
    - **Validates: Requirements 3.5**
    - In `test/trace_it_drag_fill_test.dart`, mirror the full stroke-advancement sequence, drive every stroke's progress to `>= 0.85` in order for >= 100 random Stroke_Sets, and assert `_activeStroke == strokes.length` and no further Active_Stroke is designated afterward.
  - [ ]* 4.20 Write property test for Property 16 (session-type state isolation)
    - **Property 16: Session-type state isolation**
    - **Validates: Requirements 6.4**
    - In `test/trace_it_drag_fill_test.dart`, using `WidgetTester` on `TraceItScreen`, drive random sequences of mode switches (`_selectedMode` 0 ↔ 1/2) interleaved with drag-fill progress on uppercase letters, and assert `_strokes`, `_strokeProgress`, `_activeStroke`, `_dragAttempts` are fully reset (via `_initStrokes`) whenever transitioning into an Uppercase_Letter_Session, and that legacy-only state (`_tracedPoints`, `_visitedPoints`, `_overlapGrid`) is untouched while an Uppercase_Letter_Session is active. Assert this holds after the Task 1 mode-routing fix (regression guard).
  - [ ]* 4.21 Write property test for Property 17 (uppercase and legacy scoring paths are mutually exclusive)
    - **Property 17: Uppercase and legacy scoring paths are mutually exclusive**
    - **Validates: Requirements 5.1, 5.2, 6.1, 6.2, 6.3, 6.6**
    - In `test/trace_it_drag_fill_test.dart`, using `WidgetTester`, complete a random uppercase letter via drag-fill and assert `_computeSmartScore` is never invoked (verify via the flat 15pt/3-star legacy award NOT appearing, and the drag-fill `stars * 5` award appearing instead); complete a random lowercase letter and a random number via the legacy `_checkTracing`/`_computeSmartScore` path and assert the awarded points/stars equal the fixed legacy values (15 points, 3 stars) and that `_computeStarRating` is never reached (no stroke-set state is populated, per `_useDragFill == false`).

- [~] 5. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP, though they cover all 19 correctness properties and the Requirement 6 regression guard called out as highest priority.
- Tasks 1.1–1.2 and 2.1 all edit `lib/data/letter_tracing_data.dart` and must be applied sequentially (in the listed order) to avoid conflicting edits to the same file.
- Tasks 4.1, 4.2, 4.6, and 4.9 all edit `lib/screens/trace_it_screen.dart` and must be applied sequentially (in the listed order) for the same reason.
- Because several tested functions are library-private to `trace_it_screen.dart`, most Task 4 tests mirror the production algorithm inside the test file rather than importing it directly — follow the precedent already set by `test/letter_tracing_fill_bug_test.dart`.
- Each property test targets a minimum of 100 iterations using a seeded `dart:math` `Random` for reproducibility, per the design's Testing Strategy.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["2.1"] },
    { "id": 3, "tasks": ["1.3", "1.4", "2.2", "2.3", "2.4", "2.5"] },
    { "id": 4, "tasks": ["4.1"] },
    { "id": 5, "tasks": ["4.2"] },
    { "id": 6, "tasks": ["4.6"] },
    { "id": 7, "tasks": ["4.9"] },
    { "id": 8, "tasks": ["4.3", "4.4", "4.5", "4.7", "4.8", "4.10", "4.11", "4.12", "4.13", "4.14", "4.15", "4.16", "4.17", "4.18", "4.19", "4.20", "4.21"] }
  ]
}
```
