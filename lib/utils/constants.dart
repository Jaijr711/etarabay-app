import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5C52E5);
  static const Color primaryLight = Color(0xFF7E76F2);
  static const Color secondary = Color(0xFFFF5B79);
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color starGold = Color(0xFFFFD700);

  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  
  // The bottom bar. One colour per destination, the same on every screen,
  // because a child learns "the orange one is my prizes" by its paint and
  // that only works if the paint never changes.
  static const Color navHome = Color(0xFF2C7BE5);
  static const Color navLessons = Color(0xFF2E9E5B);
  static const Color navAwards = Color(0xFFF5A623);
  static const Color navSettings = Color(0xFF7C3AED);

  static const Color alphabet = Color(0xFFFF6B6B);
  static const Color numbers = Color(0xFF4ECDC4);
  static const Color colors = Color(0xFFFFB347);
  static const Color shapes = Color(0xFF95D9C3);
  static const Color animals = Color(0xFFA8E6CF);
  static const Color family = Color(0xFFFF99C8);
  static const Color body = Color(0xFFA0D6B4);
}

class AppStyles {
  static const TextStyle instructionText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const TextStyle instructionHeader = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
  );
}

/// Maps an avatar preset key (e.g. 'boy1', 'girl2', 'female') to the matching
/// character image so kids can easily tell male from female.
String avatarAssetForPreset(String preset) {
  final p = preset.toLowerCase();
  if (p.startsWith('girl') || p == 'female') {
    return 'assets/images/female.webp';
  }
  return 'assets/images/male.webp';
}

/// Soft background tint behind a character avatar, based on gender.
Color avatarTintForPreset(String preset) {
  final p = preset.toLowerCase();
  if (p.startsWith('girl') || p == 'female') {
    return const Color(0xFFFFE1EC);
  }
  return const Color(0xFFDCEBFF);
}