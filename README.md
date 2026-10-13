# E-Tarabay Project Overview (v 1.0.4)

E-Tarabay is a modern, interactive Flutter-based educational mobile application designed for early childhood learning, primarily focused on Filipino learners (Tagalog/English). The app’s tagline, **"Ang Kabataan ay Pag-asa ng Bayan"** (The Youth are the Hope of the Nation), reflects its core mission of fostering foundational knowledge in young students.

## Core Modules & Features

### Learning Modules (Pag-aaral)
*   **Lessons**: Curated educational content for various subjects.
*   **Matematika (Math)**: Interactive math exercises and games.
*   **Magbasa (Reading)**: Dedicated screens for reading stories (**Kwento**) and poems (**Tula**).
*   **Alphabet & Numbers**: Foundational literacy and numeracy.

### Creative & Social
*   **Kulay (Coloring)**: An interactive coloring and art activities section.
*   **Sundan (Tracing)**: Tracing exercises for motor skill development.
*   **Pamilya (Family)**: Lessons focused on family values and identification.

### Gamification (Achievements)
*   **Awards & Achievements**: Motivation through visual rewards and milestones for completed tasks.

### Audio & Visual
*   Background music management via a dedicated **AudioManager**.
*   Rich assets including custom illustrations and audio feedback for an engaging experience.

## Technology Stack

*   **Framework**: Flutter (Dart) for cross-platform mobile development.
*   **Backend**: 
    *   **Firebase Auth**: For user authentication across student, teacher, and parent roles.
    *   **Firestore & Realtime Database**: For cloud synchronization of progress and data.
*   **Local Storage**:
    *   **Hive**: For fast, persistent local caching of user profiles and progress.
    *   **Shared Preferences**: For simple app settings (e.g., language, music toggle).
*   **State Management**: Provider package for handling app state (Language, User session, Audio).
*   **Security**: `flutter_secure_storage` for protecting sensitive information such as PINs and login credentials.

## Edge Cases

*   **Offline Mode**: The app uses Hive and Shared Preferences for local data, but core authentication and dashboard features likely require an internet connection for Firebase synchronization.
*   **Language Switching**: The app supports bilingual (English/Tagalog/Ilocano) toggling, affecting descriptions and content across screens.

## Credits

Maintained by [**BONFIRE BASE Studio**](https://bonfire.base69.studio).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
