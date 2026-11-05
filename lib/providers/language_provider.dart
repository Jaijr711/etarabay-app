import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage;

  // Available languages
  static const List<String> languages = ['English', 'Ilocano', 'Filipino'];
  static const List<String> languageCodes = ['en', 'ilo', 'fil'];

  /// [code] if it is one of [languageCodes], else English.
  ///
  /// A saved value the app does not know (an older build's, a hand edit)
  /// used to be taken as it was: the menus fell back to English on their
  /// own while About Me fell back to Ilocano on its own, and the child got
  /// an English screen with Ilocano questions.
  static String validCode(String? code) =>
      languageCodes.contains(code) ? code! : 'en';

  LanguageProvider(String language) : _currentLanguage = validCode(language);

  String get currentLanguage => _currentLanguage;
  String get currentLanguageCode => currentLanguage;

  Future<void> setLanguage(String languageCode) async {
    if (!languageCodes.contains(languageCode)) return;
    // The screen first, the disk after: waiting on the write held the
    // switch back, and a write that failed left the screen unchanged.
    _currentLanguage = languageCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }
}
