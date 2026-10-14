import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Metadata for each certificate/badgex
class CertificateInfo {
  final String id;
  final String title;
  final String titleFil;
  final String titleIlo;
  final String description;
  final String descriptionFil;
  final String descriptionIlo;
  final String emoji;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final List<String> requirements;

  const CertificateInfo({
    required this.id,
    required this.title,
    required this.titleFil,
    required this.titleIlo,
    required this.description,
    required this.descriptionFil,
    required this.descriptionIlo,
    required this.emoji,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.requirements,
  });
}

final Map<String, CertificateInfo> allCertificates = {
  'e_tarabay_graduate': const CertificateInfo(
    id: 'e_tarabay_graduate',
    title: 'Certificate of Completion',
    titleFil: 'Sertipiko ng Pagtatapos',
    titleIlo: 'Sertipiko ti Panagtungpal',
    description: 'You completed EVERYTHING in E-Tarabay! You are a true star!',
    descriptionFil: 'Natapos mo ang LAHAT sa E-Tarabay. Napakagaling mo!',
    descriptionIlo: 'Nakumpletom amin iti E-Tarabay! Pudno a sikat ka!',
    emoji: '🎓',
    icon: LucideIcons.graduation_cap,
    primaryColor: Color(0xFF2D3436),
    secondaryColor: Color(0xFF636E72),
    accentColor: Color(0xFFFFD700),
    requirements: [
      'Earn all 12 badges in E-Tarabay',
      'Complete every learning module',
    ],
  ),
};
