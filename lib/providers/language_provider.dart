import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage;
  
  // Available languages
  static const List<String> languages = ['English', 'Ilokano', 'Filipino'];
  static const List<String> languageCodes = ['en', 'ilo', 'fil'];
  
  LanguageProvider(this._currentLanguage) {
    if (_currentLanguage.isEmpty) {
      _currentLanguage = 'en'; // Default to English
    }
  }
  
  String get currentLanguage => _currentLanguage.isNotEmpty ? _currentLanguage : 'en';
  String get currentLanguageCode => currentLanguage;
  
  Future<void> setLanguage(String languageCode) async {
    if (languageCode.isNotEmpty) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      notifyListeners();
    }
  }
}