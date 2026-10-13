# Implementation Plan

## Overview

This plan fixes the dual-source trace geometry bug in the "Trace It" game by establishing a single
font-extracted source of truth for each character. It follows the exploratory bugfix workflow:
write a bug condition exploration test that fails on the unfixed code, write preservation tests that
pass on the unfixed code, apply the fix (bundle the font, regenerate `points` from glyph outlines,
draw the faint reference from `points`), then re-run both to confirm the bug is fixed and no
behaviour regressed.

## Tasks

- [-] 1. Write bug condition exploration test (BEFORE implementing the fix)
  - **Property 1: Bug Condition** - Trace Geometry Does Not Match the Displayed Letterform
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the dual-source geometry mismatch
  - **Scoped PBT Approach**: This bug is deterministic (the same `points` and displayed glyph every run), so scope the property to concrete representative characters drawn from `uppercaseLetters`, `lowercaseLetters`, and `numberLetters`
  - For each representative character X (e.g. 'A', 'a', '8', '10') compute the displayed-glyph geometry — the centred font outline normalised into the 300×260 design space — and compare it to `LetterData.points` for X (from `lib/data/letter_tracing_data.dart`)
  - Assert `matchesDisplayedGlyph(X.points, X.letter)` — that the guide/scoring geometry coincides (position and shape) with the displayed letterform
  - Additionally sample an "accurate" trace from the displayed glyph for '8' and assert `_computeSmartScore` accepts it at the 0.60 threshold
  - For the multi-glyph edge case '10', assert `points` cover both displayed digit glyphs
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the geometry diverges and accurate traces are wrongly rejected)
  - Document counterexamples found (e.g., "'A' points are a ~29-point zig-zag off-position vs the centred Poppins 'A'", "accurate trace of displayed '8' scores below 0.60", "'10' points cover a single approximated path, not two glyphs")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4_

- [~] 2. Write preservation property tests (BEFORE implementing the fix)
  - **Property 2: Preservation** - Non-Shape Game Mechanics Unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for inputs where `isBugCondition` does NOT apply (mechanics not tied to shape accuracy):
    - Observe that for a fixed `points` array and a fixed traced-point sequence, `_computeSmartScore` returns a specific value and the 0.60 threshold decision is unchanged
    - Observe that each mode (Uppercase, Lowercase, Numbers) yields its full character set in order
    - Observe that completing a character awards points/stars, saves progress via `UserProvider`/`updateTraceItProgress`, and auto-advances
    - Observe that revisiting a completed character redisplays the saved trace, and smart-resume lands on the first uncompleted character
    - Observe that `Offset(NaN, NaN)` break markers are inserted between strokes and `_buildPath` renders disjoint strokes without connecting lines
  - Write property-based tests capturing these observed behavior patterns from the Preservation Requirements section, generating many inputs across the domain (modes, indices, traced-point sequences, multi-stroke sets)
  - Property-based testing generates many test cases for stronger guarantees that non-shape behavior is unchanged for all non-buggy inputs
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms the baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 3. Fix for dual-source trace geometry (single font-extracted source of truth)

  - [~] 3.1 Bundle the tracing font as a deterministic asset
    - Add the tracing font TTF (the Poppins TTF, or a clearer tracing-oriented font) under the project assets
    - Register it in `pubspec.yaml` under `flutter.fonts` (and/or `assets`) so the reference glyph and the extracted geometry use the same deterministic font file rather than the runtime-fetched `google_fonts` Poppins
    - _Bug_Condition: isBugCondition(X) = NOT matchesDisplayedGlyph(X.points, X.letter)_
    - _Expected_Behavior: deterministic on-device rendering matches the extracted geometry across platforms_
    - _Requirements: 2.1, 2.4_

  - [~] 3.2 Regenerate `points` from the bundled font glyph outlines (offline generation step)
    - Add a one-off generation tool (Dart/Python using a font/glyph library such as fontTools or opentype.js) that, for each character in `uppercaseLetters`, `lowercaseLetters`, and `numberLetters`:
      - Loads the bundled tracing font
      - Extracts the glyph outline(s) for that character
      - Normalises and centres the outline into the 300×260 design space (matching how the canvas centres the glyph in `_computeTransform`)
      - Samples each contour into a polyline and joins disjoint contours/strokes with `Offset(double.nan, double.nan)`
      - Writes the resulting `List<Offset>` back into the `points` field, leaving `letter`, `sound`, `example`, `color`, and `difficulty` untouched
    - Handle the multi-glyph entry `'10'`: extract and place both digit glyphs, joined by a `NaN` break, so the geometry matches the displayed "10"
    - _Bug_Condition: isBugCondition(X) = NOT matchesDisplayedGlyph(X.points, X.letter)_
    - _Expected_Behavior: shape := traceShapeOf'(X); ASSERT matchesDisplayedGlyph(shape, X.letter)_
    - _Preservation: 300×260 design space and `Offset(NaN, NaN)` contour-separator representation reused unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [~] 3.3 Draw the faint reference from `points`, not from a `Text` widget
    - In `lib/screens/trace_it_screen.dart`, replace the `Center(child: Opacity(child: Text(letter.letter, ...)))` reference layer with a faint render of the same `letter.points` path, drawn by `_TracePainter` (reusing `_buildPath` / `_toScreen`)
    - Keep opacity/colour styling equivalent so the visible letterform is literally the trace geometry
    - Leave the downstream pipeline intact: `_drawGuide`, `_getPointOnPath`, `_densifyPoints`, `_computeSmartScore`, visited-point hit detection in `_onPanUpdate`, the 0.60 threshold, multi-stroke `NaN` handling, progress/review/resume/navigation, and the completion dialog all continue to consume `letter.points`, which now matches the display
    - _Bug_Condition: isBugCondition(X) = NOT matchesDisplayedGlyph(X.points, X.letter)_
    - _Expected_Behavior: guide dot, faint reference, and scoring reference all driven by one font-extracted letterform path for X_
    - _Preservation: scoring algorithm weights and 0.60 acceptance threshold unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [~] 3.4 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Trace Geometry Matches the Displayed Letterform
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior; when it passes, it confirms the guide dot, faint reference, and scoring reference all follow the displayed letterform
    - Run the bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms the geometry now matches the display, accurate traces are accepted, and unrelated traces are rejected)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [~] 3.5 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Shape Game Mechanics Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run the preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions in mode switching, points/stars, progress saving, auto-advance, trace review, smart-resume, completion dialog, multi-stroke capture, and the scoring threshold)
    - Confirm all tests still pass after the fix (no regressions)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [~] 4. Checkpoint - Ensure all tests pass
  - Run the full test suite: exploration test (now passing), preservation tests (still passing), unit tests, property-based tests, and integration tests
  - Verify regenerated `points` for each character are non-empty, lie within the 300×260 design bounds, and use `NaN` only as contour separators
  - Verify no `Text(letter.letter)` glyph source remains in the canvas stack
  - Verify '10' produces geometry covering two digit glyphs
  - Ensure all tests pass, ask the user if questions arise

## Task Dependency Graph

```json
{
  "waves": [
    {
      "wave": 1,
      "tasks": ["1", "2"],
      "description": "Author tests before the fix: Property 1 (Bug Condition) fails on unfixed code; Property 2 (Preservation) passes on unfixed code. Independent of each other."
    },
    {
      "wave": 2,
      "tasks": ["3.1"],
      "description": "Bundle the tracing font as a deterministic asset in pubspec.yaml."
    },
    {
      "wave": 3,
      "tasks": ["3.2"],
      "description": "Regenerate points from the bundled font glyph outlines. Depends on 3.1."
    },
    {
      "wave": 4,
      "tasks": ["3.3"],
      "description": "Draw the faint reference from points instead of a Text widget. Depends on 3.2."
    },
    {
      "wave": 5,
      "tasks": ["3.4", "3.5"],
      "description": "Verify exploration test now passes (depends on 1, 3.3) and preservation tests still pass (depends on 2, 3.3)."
    },
    {
      "wave": 6,
      "tasks": ["4"],
      "description": "Checkpoint: run the full suite and confirm all tests pass. Depends on 3.4 and 3.5."
    }
  ]
}
```

```
1 (Bug Condition exploration test - fails on unfixed code)
2 (Preservation tests - pass on unfixed code)
        │
        ▼
3 (Fix: single font-extracted source of truth)
  3.1 (Bundle tracing font asset)
        │
        ▼
  3.2 (Regenerate points from font outlines) ── depends on 3.1
        │
        ▼
  3.3 (Draw faint reference from points) ── depends on 3.2
        │
        ▼
  3.4 (Verify exploration test now passes) ── depends on 1, 3.3
  3.5 (Verify preservation tests still pass) ── depends on 2, 3.3
        │
        ▼
4 (Checkpoint - all tests pass) ── depends on 3.4, 3.5
```

- Tasks 1 and 2 are independent and must both be completed before the fix (task 3).
- Sub-tasks 3.1 → 3.2 → 3.3 are sequential.
- Verification sub-tasks 3.4 and 3.5 depend on the fix being applied (3.3) and on the tests
  authored in tasks 1 and 2 respectively.
- The checkpoint (task 4) depends on all verification sub-tasks passing.

## Notes

- Tasks 1 and 2 are property-based tests. Task 1 (Property 1: Bug Condition) MUST FAIL on the
  unfixed code; task 2 (Property 2: Preservation) MUST PASS on the unfixed code.
- The fix is scoped to the *origin* of the geometry. The downstream pipeline (guide-dot animation,
  `_computeSmartScore`, the 0.60 threshold, visited-point hit detection, multi-stroke `NaN` handling,
  progress/review/resume/navigation, completion dialog) is intentionally left unchanged.
- The 300×260 design space and `Offset(double.nan, double.nan)` contour-separator convention are
  reused, so the painter and scorer require no changes.
- Flutter long-running commands (e.g. `flutter run`) should be run manually by the user. Run tests in
  single-execution mode (e.g. `flutter test`) rather than watch mode.
