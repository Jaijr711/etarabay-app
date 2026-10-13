# E-Tarabay Project Overview (v1.2.48)

E-Tarabay is a modern, interactive Flutter-based educational mobile application designed for early childhood learning, primarily for daycare learners in Ilocos. It teaches in **Ilokano**, **Filipino** and **English**. The app’s tagline, **"Ang Kabataan ay Pag-asa ng Bayan"** (The Youth are the Hope of the Nation), reflects its core mission of fostering foundational knowledge in young students.

**Current version:** 1.2.48 (build 60) — see [`pubspec.yaml`](pubspec.yaml).

## Core Modules & Features

### Learning Modules

- **Matematika (Numbers)**: Seven levels of counting and number games — Count the Objects, Drag the Number, Match with Line, Pop the Balloon, More or Less, Number Puzzle and Sequencing — each rated with 1–3 stars.
- **Ang Aking Sarili / Pamilya (About Me / My Family)**: Nine levels about the child and their family — All About Me, My Emotions, Daily Routines, My Preferences, Family Members, Family Roles, Family Activities, Family Tree and Our Home.
- **Magbasa (Stories & Songs)**: Five poems (**Tula**), five illustrated stories (**Kwento**) and nine songs with karaoke-style lyrics (**Kanta**), with play, pause and replay controls.
- **Kulay Saya (Color Fun)**: Nine colour-by-number pages that stay inside the lines and save the child's work.
- **Trace It (Sundan)**: Tracing of A–Z, a–z and 1–10 with stroke-order numbers and arrows.
- **Tandaan Mo! (Remember It)**: Memory card matching across four categories.

### Rewards

- **Stars** for every activity, **13 badges** in three tiers, and a **Certificate of Completion** once all twelve graduate badges are claimed and every module is finished.
- A birthday celebration on the child's birthday.

### For Adults

- **Teacher Dashboard**: Enrol students (with auto-generated Student Numbers), follow each child's progress live, see who needs help, and reset all or selected modules.
- **For Parents**: A PIN-locked progress report, and management of the child's login.
- **Developer Dashboard**: Messages and broadcasts to students, account pause, force logout, progress reset and module locks.

### Devices

- Android (APK), web, and an enlarged phone layout on iPads and tablets.
- Works offline; progress syncs to the cloud when a connection is available.
- Daily reminder notifications and an in-app update check (Android).

## Technology Stack

- **Framework**: Flutter (Dart) for cross-platform development.
- **Backend**:
    - **Firebase Auth**: Anonymous app sign-in.
    - **Cloud Firestore**: Cloud synchronization of student records and progress.
- **Local Storage**:
    - **Hive**: Fast, persistent local caching of user profiles and progress.
    - **Shared Preferences**: App settings and per-activity progress.
- **State Management**: Provider package for app state (language, user session, audio).
- **Security**: `flutter_secure_storage` and `local_auth` for PINs, credentials and fingerprint login.

## What's New in 1.2.48

- Home header redesigned so the child's name is always readable, with a gold star medal.
- Developer messages are shown once per student, across all devices.
- Matematika per-level stars and points are now backed up and restored on new devices.
- Badges and the certificate are no longer withdrawn when signing in on a new device.
- Larger, proportional layout on iPads and tablets.

## Edge Cases

- **Offline Mode**: Progress is saved locally with Hive and Shared Preferences and synced to Firestore when online.
- **Language Switching**: The app supports Ilokano, Filipino and English, affecting descriptions and content across screens.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
