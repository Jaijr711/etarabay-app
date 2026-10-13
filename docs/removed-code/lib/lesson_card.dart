import 'package:flutter/material.dart';

enum LessonCategory {
  alphabet,
  numbers,
  colors,
  shapes,
  animals,
  objects,
}

class Lesson {
  final String id;
  final String title;
  final String titleIlocano;
  final String titleFilipino;
  final LessonCategory category;
  final List<LessonItem> items;
  final String imagePath;
  final Color color;
  final int level;
  final int starsEarned;

  Lesson({
    required this.id,
    required this.title,
    required this.titleIlocano,
    required this.titleFilipino,
    required this.category,
    required this.items,
    required this.imagePath,
    required this.color,
    required this.level,
    this.starsEarned = 0,
  });
}

class LessonItem {
  final String id;
  final String character;
  final String imagePath;
  final String soundPath;
  final String description;
  final String descriptionIlocano;
  final String descriptionFilipino;
  final List<String> examples;

  LessonItem({
    required this.id,
    required this.character,
    required this.imagePath,
    required this.soundPath,
    required this.description,
    required this.descriptionIlocano,
    required this.descriptionFilipino,
    required this.examples,
  });
}

// Extension for getting lesson items length
extension LessonExtension on Lesson {
  int get itemCount => items.length;
}