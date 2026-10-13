/// The single source of truth for every award badge.
///
/// Badges are recognition, not currency: earning one does not grant stars.
/// A child's star total is exactly the sum of the ratings they earned for
/// finishing activities, so it can always be explained — a badge that quietly
/// added 5 more made the number impossible to account for.
///
/// Before this file existed the badge list was written twice — once in
/// `awards_screen.dart` for display (symbol, colour, star value) and again in
/// `user_provider.dart` for the earn check. The two had to be kept in step by
/// hand, and when they drifted nothing failed loudly: the app simply showed
/// one thing and awarded another. Both now read from here.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// How far a child has come towards one badge.
class BadgeProgress {
  /// How much of the requirement is done (e.g. 23 letters traced).
  final int current;

  /// How much is needed in total (e.g. 26 letters).
  final int target;

  /// All-or-nothing: no one-star or two-star step in between.
  final bool single;

  const BadgeProgress(this.current, this.target, {this.single = false});

  bool get isEarned => tier >= 1;

  /// How far in: 0 none, then 1, 2 or 3 stars on the medal's ring — see
  /// [BadgeEmblem.ringFor], which picks the actual colours.
  ///
  /// Every badge used to be the whole module or nothing, so a child who had
  /// traced 25 of 26 letters had no badge and no sign they were one letter
  /// away. Three steps means the shelf always has something on it and always
  /// has something just out of reach — which is the only shape of reward that
  /// works at this age.
  ///
  /// [single] badges keep one step, for requirements with no sensible middle:
  /// five days running is not two-thirds of anything.
  int get tier {
    if (target <= 0) return 0;
    if (current >= target) return 3;
    if (single) return 0;
    if (current * 3 >= target * 2) return 2;
    if (current * 3 >= target) return 1;
    return 0;
  }

  /// 0.0–1.0, safe to hand straight to a progress indicator.
  double get fraction {
    if (target <= 0) return 0;
    final f = current / target;
    return f < 0 ? 0 : (f > 1 ? 1 : f);
  }
}

/// Reads [BadgeProgress] out of the aggregated progress map returned by
/// `UserProvider.getAllProgress()`.
typedef BadgeRule = BadgeProgress Function(Map<String, dynamic> progress);

class BadgeDef {
  /// Stable storage key. Never change these — a child's earned badges are
  /// recorded against the id, so renaming one would silently take it away.
  final String id;

  /// The symbol struck into the medal.
  ///
  /// A drawn icon rather than an emoji, because emoji render as a different
  /// picture on every phone — and a child's award should not change shape
  /// depending on the device it is shown on.
  final IconData icon;

  final int color;

  final BadgeRule rule;

  const BadgeDef({
    required this.id,
    required this.icon,
    required this.color,
    required this.rule,
  });

  BadgeProgress progressFrom(Map<String, dynamic> progress) => rule(progress);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reading helpers — the progress map is loosely typed, so every lookup has to
//  survive a missing or differently-typed entry.
// ─────────────────────────────────────────────────────────────────────────────

int _int(dynamic value) => value is int ? value : 0;

int _module(Map<String, dynamic> progress, String module, String field) {
  final m = progress[module];
  if (m is Map) return _int(m[field]);
  return 0;
}

int _nested(
    Map<String, dynamic> progress, String module, String group, String field) {
  final m = progress[module];
  if (m is! Map) return 0;
  final g = m[group];
  if (g is! Map) return 0;
  return _int(g[field]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  The catalog
// ─────────────────────────────────────────────────────────────────────────────
//
//  The symbol matches the skill the badge actually certifies, because a
//  three-to-five-year-old reads the picture long before the words: the badge
//  for tracing letters shows letters, not an animal.

const List<BadgeDef> badgeCatalog = [
  BadgeDef(
    id: 'firstSteps',
    icon: LucideIcons.footprints,
    color: 0xFF6C63FF,
    rule: _firstStepsRule,
  ),
  BadgeDef(
    id: 'alphabet',
    icon: LucideIcons.book_open_text,
    color: 0xFF6C63FF,
    rule: _alphabetRule,
  ),
  BadgeDef(
    id: 'numbers',
    icon: LucideIcons.hash,
    color: 0xFFFF6B6B,
    rule: _numbersRule,
  ),
  BadgeDef(
    id: 'colors',
    icon: LucideIcons.palette,
    color: 0xFFFF9F43,
    rule: _colorsRule,
  ),
  // Was "Shape Creator ⬛" — it certifies uppercase letter tracing, so it now
  // shows letters.
  BadgeDef(
    id: 'shapes',
    icon: LucideIcons.case_upper,
    color: 0xFF4ECDC4,
    rule: _uppercaseRule,
  ),
  // Was "Animal Friend 🐶" — it certifies lowercase letter tracing.
  BadgeDef(
    id: 'animals',
    icon: LucideIcons.case_lower,
    color: 0xFF5F27CD,
    rule: _lowercaseRule,
  ),
  BadgeDef(
    id: 'bookworm',
    icon: LucideIcons.library_big,
    color: 0xFF4ECDC4,
    rule: _bookwormRule,
  ),
  // Was "Star Student ⭐" — it certifies the "Ang Aking Sarili" games.
  BadgeDef(
    id: 'starStudent',
    icon: LucideIcons.smile,
    color: 0xFFFFB800,
    rule: _selfGamesRule,
  ),
  BadgeDef(
    id: 'mathWhiz',
    icon: LucideIcons.calculator,
    color: 0xFFFF6B6B,
    rule: _mathLevelsRule,
  ),
  BadgeDef(
    id: 'familyHero',
    icon: LucideIcons.house_heart,
    color: 0xFF5F27CD,
    rule: _familyLevelsRule,
  ),
  BadgeDef(
    id: 'writingStar',
    icon: LucideIcons.pencil,
    color: 0xFFFF9F43,
    rule: _writeNumbersRule,
  ),
  BadgeDef(
    id: 'songbird',
    icon: LucideIcons.music,
    color: 0xFFFF9F43,
    rule: _songbirdRule,
  ),
  // Rewards showing up rather than volume, so a child who plays a little every
  // day is recognised alongside one who plays a lot in a single sitting.
  BadgeDef(
    id: 'streakFive',
    icon: LucideIcons.flame,
    color: 0xFF2F9E63,
    rule: _streakRule,
  ),
];

BadgeDef? badgeById(String id) {
  for (final b in badgeCatalog) {
    if (b.id == id) return b;
  }
  return null;
}

// Rules are top-level functions so the catalog stays a `const` list.
//
// Every rule below is counted in STARS, and every target is all the stars its
// area can give. That is the whole design: the dashboard shows the child
// "37 / 269", a badge card shows "12 / 21", and both numbers are the same
// thing. A badge is therefore never handed out for merely turning up — it
// says the child collected everything that area had, which is what makes it
// worth showing a teacher.
//
// The rules used to count completions instead ("play 20 math games"), so a
// child who answered every question wrongly earned the same badge as one who
// answered them all correctly. Under stars, a wrong answer costs the level a
// star and the badge stays locked until the level is replayed properly.

/// The child's very first three stars — one activity done well.
///
/// [single]: with a target this small, the shared three-step formula's
/// first star (roughly a third of the target) is reached at just 1 star —
/// the badge was showing as claimable the moment a child earned their very
/// first single star, not the three the name and description promise. One
/// activity done well has no sensible middle either, the same reasoning
/// [_streakRule] already uses.
BadgeProgress _firstStepsRule(Map<String, dynamic> p) =>
    BadgeProgress(_int(p['totalStars']), 3, single: true);

/// Every star in Let's Read: 5 poems, 5 stories and 9 songs.
BadgeProgress _alphabetRule(Map<String, dynamic> p) =>
    BadgeProgress(_module(p, 'magbasa', 'stars'), 19);

/// Every number traced, 1 to 10.
BadgeProgress _numbersRule(Map<String, dynamic> p) =>
    BadgeProgress(_nested(p, 'traceit', 'numbers', 'stars'), 10);

/// Every star in Kulay-Saya: 9 colouring pages.
///
/// Was 13 (4 base activities that were never built into kulay_screen.dart,
/// so those stars could never be earned) — the third and top star was
/// unreachable no matter how much a child coloured. See
/// UserProvider.kulayStarCeiling.
BadgeProgress _colorsRule(Map<String, dynamic> p) =>
    BadgeProgress(_module(p, 'kulay', 'stars'), 9);

BadgeProgress _uppercaseRule(Map<String, dynamic> p) =>
    BadgeProgress(_nested(p, 'traceit', 'uppercase', 'stars'), 26);

BadgeProgress _lowercaseRule(Map<String, dynamic> p) =>
    BadgeProgress(_nested(p, 'traceit', 'lowercase', 'stars'), 26);

/// All five stories.
BadgeProgress _bookwormRule(Map<String, dynamic> p) =>
    BadgeProgress(_nested(p, 'magbasa', 'kwento', 'stars'), 5);

/// Three stars on all four "About Myself" levels.
BadgeProgress _selfGamesRule(Map<String, dynamic> p) =>
    BadgeProgress(_module(p, 'pamilya', 'sariliStars'), 12);

/// Three stars on every Matematika level — a perfect module.
///
/// Three stars on all seven Matematika levels — a perfect module.
///
/// The module's own ceiling, repeated here rather than imported: this file is
/// deliberately free of the provider. Adding a level to Matematika means
/// changing this number too, or the badge goes on calling a child perfect who
/// has finished only part of it.
BadgeProgress _mathLevelsRule(Map<String, dynamic> p) =>
    BadgeProgress(_module(p, 'matematika', 'earnedStars'), 21);

/// Three stars on all five "And My Family" levels.
BadgeProgress _familyLevelsRule(Map<String, dynamic> p) =>
    BadgeProgress(_module(p, 'pamilya', 'familyStars'), 15);

/// Every letter and every number traced — the whole module.
BadgeProgress _writeNumbersRule(Map<String, dynamic> p) =>
    BadgeProgress(_module(p, 'traceit', 'stars'), 62);

/// All nine songs.
BadgeProgress _songbirdRule(Map<String, dynamic> p) =>
    BadgeProgress(_nested(p, 'magbasa', 'kanta', 'stars'), 9);

/// The one badge that is not about stars: showing up five days running is
/// worth recognising on its own.
BadgeProgress _streakRule(Map<String, dynamic> p) =>
    BadgeProgress(_int(p['dayStreak']), 5, single: true);
