# Bugfix Requirements Document

## Introduction

In the E-Tarabay "Trace It" game (`lib/screens/trace_it_screen.dart`), students practice
tracing letters and numbers. Each character is presented two ways at the same time:

- A faint **reference glyph** rendered from the real font (e.g. the actual "A", "b", "5").
- A **trace guide path** built from hand-coded / AI-approximated coordinate points stored in
  `lib/data/letter_tracing_data.dart`. These points drive the animated guide dot and the
  trace-scoring logic.

Because the visible reference glyph and the traceable guide path come from two different,
unrelated sources, they do not match. The guide dot the student is meant to follow does not
line up with the letter the student actually sees, and the scoring compares the student's
trace against the inaccurate approximated points rather than the real letterform. As a result,
the character a student is asked to fill in is not a faithful representation of the letter,
and correct tracing is judged unreliably. This bug affects every character the student traces
across all three modes (uppercase, lowercase, numbers).

## Bug Analysis

### Current Behavior (Defect)

The traceable guide path and the scoring reference are AI-approximated point arrays that do not
match the real letterform shown to the student.

1.1 WHEN a student views any letter or number on the Trace It screen THEN the system displays an animated guide dot following a path that does not align with the faint reference letter the student sees
1.2 WHEN a student traces accurately over the displayed reference letter THEN the system may reject the attempt as "almost there" because the trace is scored against the mismatched approximated points instead of the real letter shape
1.3 WHEN a student traces along the approximated guide path instead of the actual letter shape THEN the system may accept the attempt as correct even though it does not match the displayed letter
1.4 WHEN a character's approximated points are a rough or distorted representation of its letterform THEN the system presents an inaccurate shape for the student to fill in

### Expected Behavior (Correct)

The character the student fills in, the guide dot path, and the scoring reference must all
correspond to the same accurate letterform that is displayed.

2.1 WHEN a student views any letter or number on the Trace It screen THEN the system SHALL display a guide dot whose path follows the same accurate letterform shown as the reference letter
2.2 WHEN a student traces accurately over the displayed reference letter THEN the system SHALL recognize the attempt as correct
2.3 WHEN a student's trace does not follow the actual displayed letter shape THEN the system SHALL reject the attempt with corrective feedback
2.4 WHEN any letter or number is presented THEN the system SHALL use an accurate representation of that letterform as the shape the student fills in

### Unchanged Behavior (Regression Prevention)

Existing game mechanics that are not tied to the accuracy of the letter shapes must continue
to work exactly as before.

3.1 WHEN a student switches between Uppercase, Lowercase, and Numbers modes THEN the system SHALL CONTINUE TO show the corresponding set of characters
3.2 WHEN a student completes a character THEN the system SHALL CONTINUE TO award points and stars, save progress, and auto-advance to the next character
3.3 WHEN a student returns to or swipes back to a previously completed character THEN the system SHALL CONTINUE TO display their saved trace for review
3.4 WHEN a student opens the Trace It screen THEN the system SHALL CONTINUE TO smart-resume at the first uncompleted character
3.5 WHEN a student completes all characters in a mode THEN the system SHALL CONTINUE TO show the completion dialog
3.6 WHEN a student traces a character THEN the system SHALL CONTINUE TO support free-draw, multi-stroke input and render the student's stroke

## Bug Condition and Properties

### Bug Condition

The bug is triggered for every character presented, because each character's traceable shape is
derived from approximated points rather than the displayed letterform.

```pascal
FUNCTION isBugCondition(X)
  INPUT: X of type LetterData   // a character entry from letter_tracing_data.dart
  OUTPUT: boolean

  // True when the trace guide / scoring reference for X does not match
  // the accurate letterform displayed for X.
  RETURN NOT matchesDisplayedGlyph(X.points, X.letter)
END FUNCTION
```

### Property: Fix Checking

```pascal
// For every character whose traceable shape was mismatched,
// the fixed shape must correspond to the displayed letterform.
FOR ALL X WHERE isBugCondition(X) DO
  shape ← traceShapeOf'(X)
  ASSERT matchesDisplayedGlyph(shape, X.letter)
  // A trace that accurately follows the displayed letter is accepted
  ASSERT accepts(score'(accurateTraceOf(X.letter)))
  // A trace that does not follow the displayed letter is rejected
  ASSERT rejects(score'(unrelatedTrace(X.letter)))
END FOR
```

- **F**: The current Trace It behavior, scoring traces against approximated `points`.
- **F'**: The fixed behavior, where the traceable shape and scoring reference match the
  displayed letterform.

### Property: Preservation Checking

```pascal
// For inputs unrelated to letter-shape accuracy (mode switching, progress,
// scoring threshold mechanics, review, resume, navigation), behavior is unchanged.
FOR ALL X WHERE NOT isBugCondition(X) DO
  ASSERT F(X) = F'(X)
END FOR
```
