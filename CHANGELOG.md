# Changelog

## [v1.0.4+] - Wet Season Update

### Added & Improved Features
- **Tracing Module Overlap Detection**: Added strict grid-based overlap detection in the "Trace It" module. Students can no longer pass the tracing activities by scribbling or repeatedly drawing over the same area. A heavy score penalty is now applied for excessive overlapping.
- **Onboarding Redesign**: Replaced the previous image assets on the intro screens with clean, scalable Lucide icons (`rocket`, `globe`, `chart_column`), ensuring they always load properly.
- **Settings Version**: Displayed in-app version as "v1.0.4+" in the Settings screen.
- **Games & Content**:
  - Improved the coloring game.
  - Added new music games with karaoke-style lyrics.
  - Revamped the "Trace It" (with dots/guides).
  - Fixed and updated language translations across Ilokano, Tagalog, and English.
- **UI/UX Enhancements**:
  - Interactive UI improvements to make it more child-friendly.
  - Custom birthday pop-up ("Happy Birthday 🎉" with animation) for students when logging in.
  - Improved Certificate design to be more colorful and fit the app's child-like theme.
  - Changed the background music in different modules (Matematika, Bagik, Kolor Saya, etc.) to playful and enjoyable tracks.
  - Updated the Teacher Dashboard to include Settings, matching the Student Dashboard.

### Optimizations & Fixes
- **Massive APK Size Reduction**: Optimized the Android build configuration. The release APK size was reduced dramatically (from ~111MB to ~69MB) by excluding emulator architectures (x86_64) and removing unused image assets.
- **32-Bit Phone Support**: Explicitly added support for `armeabi-v7a` to prevent the app from crashing on older 32-bit Android phones. The app now builds universally for both 32-bit and 64-bit devices.
