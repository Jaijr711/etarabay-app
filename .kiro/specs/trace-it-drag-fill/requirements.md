# Requirements Document

## Introduction

The Trace It module currently teaches uppercase letter formation using a freehand brush-drawing gesture: the child draws anywhere on the canvas and a heuristic (`_computeSmartScore`) evaluates proximity, coverage, out-of-bounds drawing, path length, and overlap to decide whether the trace is accepted. This feature reworks uppercase letter tracing (A–Z only) into a guided, multi-stroke, drag-to-fill mechanic: the child drags along each stroke of the letter, in the letter's correct stroke order, to progressively fill it in. A stroke must be completed before the next stroke in the sequence becomes active. Scoring changes from path-fidelity heuristics to simple completion-based scoring (did the child complete every stroke, in order, without skipping, in a reasonable number of attempts).

This rework introduces no new binary or SVG image assets. The existing code-drawn approach (`CustomPainter` + glyph outline rendered via `ui.Paragraph`, plus vector stroke-path guides) continues to be the visual foundation; only the interaction and underlying stroke data model change.

Lowercase letters (a–z) and numbers (1–10) are explicitly out of scope for this rework and must continue to use the existing freehand tracing mechanic and existing `_computeSmartScore` scoring, unaffected by any change made here.

## Glossary

- **Trace_It_Module**: The existing app feature (implemented in `trace_it_screen.dart`) that presents letters and numbers for the child to trace.
- **Uppercase_Letter_Session**: The portion of the Trace_It_Module in which the child traces an uppercase letter (A–Z) using the new guided drag-fill mechanic defined by this spec.
- **Legacy_Tracing_Session**: The portion of the Trace_It_Module in which the child traces a lowercase letter (a–z) or a number (1–10) using the existing freehand mechanic and `_computeSmartScore`, which this spec does not modify.
- **Letter_Glyph**: The visual outline of an uppercase letter, rendered by the existing `CustomPainter`/`ui.Paragraph` approach, with no new image or SVG asset.
- **Stroke**: A single continuous pen-path segment of an uppercase letter's glyph (e.g., the vertical bar of a "B" is one Stroke, its two bumps may be one or two additional Strokes), represented as an ordered list of design-space points, with a minimum of 2 points (a start point and an end point).
- **Stroke_Order**: The fixed, letter-specific sequence in which the Strokes of a Stroke_Set must be completed, defined by each Stroke's position in the Stroke_Set.
- **Stroke_Set**: The ordered collection of every Stroke that composes one uppercase Letter_Glyph, ordered by Stroke_Order.
- **Active_Stroke**: The single Stroke within a Stroke_Set that the child is currently allowed to drag-fill, determined by Stroke_Order and prior completion state.
- **Stroke_Start_Zone**: A circular hit-test region, centered on the first point of a Stroke, with a radius no greater than 1.5x the rendered stroke width, within which a drag gesture must begin for that Stroke to register as started.
- **Path_Tolerance_Distance**: The maximum perpendicular distance, in design-space units, that the child's drag position may deviate from the Active_Stroke's path while still counting as "on the stroke" for the purpose of advancing Drag_Progress, defined in design.
- **Stroke_Fill_Indicator**: The visual rendering that shows how much of the Active_Stroke has been filled as the child drags along it.
- **Drag_Progress**: A numeric value between 0.0 and 1.0 representing how far along the Active_Stroke's path the child's current drag gesture has advanced.
- **Stroke_Completion_Threshold**: The minimum Drag_Progress value at which an Active_Stroke is considered filled/complete, fixed at 0.85 (85% of the Stroke's path length covered within Path_Tolerance_Distance).
- **Letter_Completion_State**: The state indicating every Stroke in a Stroke_Set has reached the Stroke_Completion_Threshold for the currently displayed uppercase letter.
- **Attempt_Count**: The number of times the child starts a drag gesture on the Active_Stroke's Stroke_Start_Zone during the current uppercase letter session, including gestures that are released before completion, incremented by 1 per qualifying gesture start.
- **Star_Rating**: The number of stars (0–3) awarded to the child upon reaching Letter_Completion_State for an uppercase letter, computed from completion-based criteria rather than path-fidelity heuristics.
- **Letter_Data_Model**: The data structure (in `letter_tracing_data.dart`) describing a letter's Stroke_Set for uppercase letters, or its existing flat point list for lowercase letters and numbers.

## Requirements

### Requirement 1: Stroke-Grouped Data Model for Uppercase Letters

**User Story:** As a developer, I want each uppercase letter's guide points grouped into explicit, ordered strokes, so that the drag-fill mechanic can present and validate one stroke at a time in the correct order.

#### Acceptance Criteria

1. THE Letter_Data_Model SHALL represent each uppercase letter (A–Z) as a Stroke_Set containing one or more Strokes, where each Stroke is an ordered list of design-space points containing at least 2 points.
2. THE Letter_Data_Model SHALL order the Strokes within each uppercase letter's Stroke_Set such that, within any single Stroke, no point retraces a position already covered earlier in that same Stroke (i.e., each Stroke represents one continuous pen-down motion with no backward retracing), with any position requiring the pen to lift and restart marking the boundary between one Stroke and the next.
3. THE Letter_Data_Model SHALL define exactly one Stroke for any uppercase letter that can be fully drawn as one continuous pen-down motion per criterion 2 (e.g., "C", "O", "S", "L", "V").
4. THE Letter_Data_Model SHALL define two or more Strokes, in Stroke_Order, for any uppercase letter that cannot be fully drawn as one continuous pen-down motion per criterion 2 (e.g., "A", "B", "E", "F", "H", "I", "K", "T", "X", "Y"), and criteria 3 and 4 together SHALL classify all 26 uppercase letters (A–Z) with none omitted.
5. THE Trace_It_Module SHALL derive the existing single flat point list used for rendering the dashed Letter_Glyph outline and start-marker by concatenating the Strokes of a Stroke_Set in Stroke_Order, and the resulting concatenated list SHALL contain exactly the same points, in the same order and with the same coordinate values, as the pre-existing flat point list for that letter.
6. THE Letter_Data_Model SHALL leave the lowercase letter (a–z) and number (1–10) point-list representations unchanged in structure and values.

### Requirement 2: Guided Per-Stroke Drag Interaction

**User Story:** As a child using the app, I want to drag along one highlighted stroke of a letter at a time, so that I understand exactly which part of the letter to trace next and can fill it in by dragging.

#### Acceptance Criteria

1. WHEN an Uppercase_Letter_Session begins, OR the current Active_Stroke is marked complete, THE Trace_It_Module SHALL designate the next incomplete Stroke in Stroke_Order as the Active_Stroke.
2. WHILE an Active_Stroke is designated, THE Trace_It_Module SHALL render a circular Stroke_Start_Zone marker, with radius no greater than 1.5x the rendered stroke width, centered at the first point of the Active_Stroke, to indicate where the drag gesture must begin.
3. WHEN the child's drag gesture starts inside the Stroke_Start_Zone of the Active_Stroke, THE Trace_It_Module SHALL begin tracking Drag_Progress for that Stroke and increment the Attempt_Count by 1.
4. IF the child's drag gesture starts outside the Stroke_Start_Zone of the Active_Stroke, THEN THE Trace_It_Module SHALL NOT begin tracking Drag_Progress, SHALL NOT increment Attempt_Count, and SHALL display feedback indicating the child must start at the highlighted point, clearing that feedback after 3 seconds or when the next drag gesture starts, whichever occurs first.
5. WHILE the child drags after starting inside the Stroke_Start_Zone, THE Trace_It_Module SHALL update Drag_Progress based on how far the drag position has advanced along the Active_Stroke's path, moving forward only when the drag position advances toward the Stroke's end point.
6. IF the child's drag position moves away from the Active_Stroke's path beyond the Path_Tolerance_Distance, THEN THE Trace_It_Module SHALL stop increasing Drag_Progress until the drag position returns within the Path_Tolerance_Distance of the path.
7. IF the child's drag gesture moves backward along the Active_Stroke's path (toward the start point) rather than forward, THEN THE Trace_It_Module SHALL NOT decrease previously achieved Drag_Progress below its highest recorded value for that attempt, and SHALL NOT register this as advancing the Stroke.
8. WHEN the child releases the drag gesture before Drag_Progress reaches the Stroke_Completion_Threshold, THE Trace_It_Module SHALL keep the Active_Stroke incomplete, retain any Stroke_Fill_Indicator progress rendered up to the release point, and allow the child to start a new drag gesture inside the Stroke_Start_Zone to continue.
9. WHEN Drag_Progress for the Active_Stroke reaches the Stroke_Completion_Threshold, THE Trace_It_Module SHALL mark that Stroke as complete regardless of whether the drag gesture has been released, and SHALL render that Stroke's Stroke_Fill_Indicator as fully filled along its entire path.
10. THE Trace_It_Module SHALL define the Path_Tolerance_Distance as a fixed perpendicular-distance value, expressed in design-space units, applied uniformly to every Stroke of every uppercase letter.
11. THE Trace_It_Module SHALL define the Stroke_Completion_Threshold as 0.85 (85% of the Active_Stroke's path length covered within the Path_Tolerance_Distance).

### Requirement 3: Multi-Stroke Sequencing

**User Story:** As a child using the app, I want to be guided through each stroke of a letter in the right order, so that I learn the correct way to form multi-stroke letters like B, E, and A.

#### Acceptance Criteria

1. ONCE a Stroke has reached the Stroke_Completion_Threshold, THE Trace_It_Module SHALL NOT redesignate that Stroke as the Active_Stroke again for the remainder of the current Uppercase_Letter_Session.
2. WHEN the Active_Stroke is marked complete AND at least one Stroke later in Stroke_Order remains incomplete, THE Trace_It_Module SHALL designate the next incomplete Stroke in Stroke_Order as the new Active_Stroke.
3. WHILE a Stroke later in Stroke_Order than a given completed Stroke is the Active_Stroke, THE Trace_It_Module SHALL render that completed Stroke in its filled visual state, so the child can see prior progress.
4. IF the child's drag gesture starts inside the Stroke_Start_Zone of a Stroke that is not the Active_Stroke, THEN THE Trace_It_Module SHALL NOT begin tracking Drag_Progress for that Stroke and SHALL display feedback indicating which Stroke to trace next.
5. WHEN every Stroke in the Stroke_Set for the currently displayed uppercase letter has reached the Stroke_Completion_Threshold, THE Trace_It_Module SHALL set Letter_Completion_State for that letter and SHALL NOT designate any further Active_Stroke for that session.

### Requirement 4: Visual Fill Feedback During Drag

**User Story:** As a child using the app, I want to see the stroke visually filling in as I drag, so that I get immediate feedback that I'm tracing correctly.

#### Acceptance Criteria

1. WHILE the Active_Stroke is designated, THE Trace_It_Module SHALL render the Stroke_Fill_Indicator to cover the portion of the Active_Stroke's path from its start point up to the current Drag_Progress position, continuously reflecting the current Drag_Progress value whether or not a drag gesture is actively in progress.
2. THE Trace_It_Module SHALL render the Stroke_Fill_Indicator using a visual treatment that is visibly distinguishable from the unfilled remainder of the Active_Stroke's path, using the existing CustomPainter-based drawing approach, without introducing new image or SVG assets.
3. WHEN a Stroke is marked complete, THE Trace_It_Module SHALL render that Stroke's Stroke_Fill_Indicator as fully filled along its entire path.
4. WHEN Letter_Completion_State is set for the currently displayed uppercase letter, THE Trace_It_Module SHALL render the full Letter_Glyph in its completed celebratory visual state, consistent with the existing completed-letter rendering behavior.
5. IF the child's drag position moves beyond the Path_Tolerance_Distance from the Active_Stroke's path as described in Requirement 2, THEN THE Trace_It_Module SHALL display feedback, visually distinct from the Stroke_Fill_Indicator, indicating the drag has moved off the stroke, without erasing previously filled progress on that Stroke, and SHALL stop displaying that feedback once the drag position returns within the Path_Tolerance_Distance of the path.

### Requirement 5: Completion-Based Scoring for Uppercase Letters

**User Story:** As a child using the app, I want to earn stars for completing a letter's strokes in order, so that scoring feels fair and consistent rather than penalizing imperfect freehand shapes.

#### Acceptance Criteria

1. WHEN Letter_Completion_State is set for an uppercase letter, THE Trace_It_Module SHALL compute a Star_Rating using completion-based criteria (stroke order adherence and Attempt_Count) instead of the freehand `_computeSmartScore` heuristic.
2. THE Trace_It_Module SHALL NOT apply the freehand `_computeSmartScore` heuristic, proximity scoring, coverage scoring, path-length scoring, or overlap-grid scoring to Uppercase_Letter_Session completion.
3. WHEN every Stroke in the Stroke_Set is completed in Stroke_Order with an Attempt_Count within the reasonable-attempt range defined in design, THE Trace_It_Module SHALL award the maximum Star_Rating (3, per the 0–3 Star_Rating range defined in the Glossary) for that letter.
4. IF the Attempt_Count for the Uppercase_Letter_Session exceeds the reasonable-attempt range defined in design, THEN THE Trace_It_Module SHALL award a reduced Star_Rating of at least 1 and less than 3, rather than the maximum, while still recording the letter as complete.
5. WHEN Letter_Completion_State is set, THE Trace_It_Module SHALL persist letter completion for that uppercase letter using the same progress-tracking mechanism (`updateTraceItProgress`) currently used for uppercase letters.
6. WHEN Letter_Completion_State is set, THE Trace_It_Module SHALL award points whose amount corresponds to the computed Star_Rating for that letter, using the same points-awarding mechanism currently used for uppercase letters.
7. WHEN Letter_Completion_State is set, THE Trace_It_Module SHALL award a Star_Rating no lower than 1 (the minimum non-zero value in the 0–3 Star_Rating range), since reaching Letter_Completion_State always reflects a fully completed letter.

### Requirement 6: Lowercase and Number Tracing Remain Unaffected

**User Story:** As a product stakeholder, I want lowercase letters and numbers to keep working exactly as they do today, so that this rework doesn't regress other parts of the Trace It module.

#### Acceptance Criteria

1. THE Trace_It_Module SHALL continue to present lowercase letters (a–z) using the existing freehand Legacy_Tracing_Session mechanic, unmodified by this feature.
2. THE Trace_It_Module SHALL continue to present numbers (1–10) using the existing freehand Legacy_Tracing_Session mechanic, unmodified by this feature.
3. THE Trace_It_Module SHALL continue to use the existing `_computeSmartScore` heuristic, unmodified, to evaluate Legacy_Tracing_Session completion for lowercase letters and numbers.
4. THE Trace_It_Module SHALL NOT apply Stroke_Set data, Active_Stroke sequencing, Stroke_Start_Zone hit-testing, or completion-based Star_Rating logic to lowercase letters or numbers, and WHEN the child transitions between an Uppercase_Letter_Session and a Legacy_Tracing_Session, THE Trace_It_Module SHALL NOT carry over Active_Stroke, Stroke_Completion_Threshold progress, or Attempt_Count state from one session type into the other.
5. THE Letter_Data_Model SHALL keep the `lowercaseLetters` and `numberLetters` collections using their current flat `points` list structure without requiring a Stroke_Set.
6. WHEN a Legacy_Tracing_Session is completed, THE Trace_It_Module SHALL award points and persist letter completion using the same progress-tracking mechanism (`updateTraceItProgress`) and the same point/star award values as before this rework, unaffected by the completion-based Star_Rating logic introduced for Uppercase_Letter_Session.

### Requirement 7: No New Binary or SVG Assets

**User Story:** As a developer maintaining the app, I want the guided drag-fill mechanic to reuse the existing code-drawn rendering approach, so that no asset pipeline, app size increase, or asset-loading complexity is introduced.

#### Acceptance Criteria

1. THE Trace_It_Module SHALL render all uppercase Letter_Glyph outlines, Stroke_Fill_Indicators, and Stroke_Start_Zone markers using Flutter's `CustomPainter` and `dart:ui` drawing primitives (e.g., `ui.Paragraph`, `Path`, `Canvas` drawing calls).
2. THE Trace_It_Module SHALL NOT introduce new SVG files, raster image files (e.g., PNG, JPEG, WebP), custom font files, new `pubspec.yaml` asset manifest entries, new asset directories, or asset-loading packages/widgets (e.g., `flutter_svg`, `Image.asset`) as part of this rework.
3. THE Trace_It_Module SHALL derive the Letter_Glyph outline, every Stroke_Fill_Indicator, and every Stroke_Start_Zone marker used in the drag-fill mechanic exclusively from the Stroke_Set point data defined in the Letter_Data_Model, without reference to any image file or non-bundled font asset.
</content>
