# Implementation Plan: E-Tarabay v1.0.4 Features (Updated)

Based on your feedback, this plan has been revised to address the specific overhauls required for drawing, localization, and offline video playback.

## User Review Required
> [!IMPORTANT]
> Please review the proposed strategies below, especially the localization and video storage approaches, and approve if they align with your vision.

## Proposed Changes

---

### 1. Adding Games (Suggested)
*Based on the existing curriculum (Math, Reading, Family, Colors, Tracing), I propose the following two new games:*

#### [NEW] `lib/screens/memory_match_screen.dart`
- **Memory Card Match**: Kids flip over cards to find matching pairs (e.g., matching a picture of a dog to the Ilokano word "Aso", or matching colors/shapes). This reinforces memory and language.

#### [NEW] `lib/screens/shape_sorter_screen.dart`
- **Shape Sorter**: A drag-and-drop game where kids drag basic shapes (circle, square, triangle) into their corresponding outlines.

---

### 2 & 3. Overhaul Coloring and Tracing Games
*Rebuilding the drawing engine from scratch for proper gesture accuracy.*

#### [MODIFY] `pubspec.yaml`
- Add the `perfect_freehand` package. This package is the industry standard in Flutter for converting touch gestures into perfectly smooth, pressure-sensitive drawing strokes (similar to Apple Notes or Procreate).

#### [MODIFY] `lib/screens/kulay_screen.dart` & `lib/screens/sundan_screen.dart`
- Completely replace the old `CustomPainter` with a new `GestureDetector` that feeds touch points into `perfect_freehand`.
- **Tracing (Sundan)**: Implement a path-checking algorithm that calculates the distance between the user's stroke points and the ideal letter path to determine accuracy (giving a score like 90% accurate).
- **Coloring (Kulay)**: Implement accurate flood-fill and smooth brush strokes.

---

### 4. Language Overhaul (English, Tagalog, Ilokano)
*A massive refactor to remove all hardcoded texts and use proper internationalization.*

#### [MODIFY] `lib/l10n/app_en.arb`, `lib/l10n/app_fil.arb`
#### [NEW] `lib/l10n/app_ilo.arb`
- Create a new Ilokano (`ilo`) translation file.
- We will scan all screens (like `matematika_screen.dart`, `pamilya_screen.dart`, etc.) and replace hardcoded strings like `Text('Magaling! Natapos mo ang tula!')` with `Text(AppLocalizations.of(context)!.greatFinishedPoem)`.
- Ensure the language switcher in the settings/profile screen fully supports switching between all three languages dynamically.

---

### 5. Video Dance (Baby Shark, etc.)
*Robust video playback with offline support.*

#### [MODIFY] `pubspec.yaml`
- Add `video_player` and `chewie` (for child-friendly playback controls).

#### [NEW] `assets/videos/`
- **Caching Strategy**: Since this is an app for children, internet connectivity should not be required. I propose we **store the videos locally in the app assets** (e.g., `assets/videos/baby_shark_en.mp4`). This increases the APK size but guarantees zero buffering and 100% offline playability.
- If the videos are too large (>100MB), we will instead use `flutter_cache_manager` to download them on the first run and cache them locally on the device's storage.

#### [NEW] `lib/screens/video_dance_screen.dart`
- A screen with a list of available dances, playing in full screen with a toggle for language (e.g., swap Baby Shark English to Tagalog).

---

### 6. Add Certificate
*Provide a certificate of completion.*

#### [NEW] `lib/screens/certificate_screen.dart`
- Create a screen that generates a visual Certificate (using the child's name from the local database). Includes `confetti` effects.

---

### 7. Music Game (Karaoke)
*Interactive music game with synchronized lyrics.*

#### [NEW] `lib/screens/music_karaoke_screen.dart`
- Create a UI that highlights lyrics as the audio progresses, using `audioplayers` Streams to track playback time.

## Verification Plan

### Automated/Manual Tests
- **Gestures**: Manually test the new `perfect_freehand` drawing to ensure zero lag and high accuracy.
- **Localization Check**: Change the device language and in-app language to ensure **NO** English/Tagalog words leak into the Ilokano version.
- **Video Playback**: Verify videos play smoothly offline or from cache.
