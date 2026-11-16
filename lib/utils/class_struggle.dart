/// Which lesson each child is furthest behind the class in, for the
/// "Hirap sa: Bilang" mark on the teacher's class list.
///
/// "Nahuhuli" says a child is behind; this says where. A child is behind in
/// a lesson when they have done less than half of what the middle of the
/// class has done in it: the same measure as "Nahuhuli", per lesson. Only a
/// child who has started playing is judged, and only in a lesson the class
/// has started, so a quiet first week marks nobody.
class ClassStruggle {
  /// The lessons in the order the app shows them, with where each keeps
  /// its done and total counts in a child's synced progress.
  static const modules = <(String, String, String)>[
    ('matematika', 'gamesCompleted', 'totalGames'),
    ('pamilya', 'completedLevels', 'totalLevels'),
    ('kulay', 'totalCompleted', 'totalActivities'),
    ('traceit', 'totalCompleted', 'totalActivities'),
    ('magbasa', 'totalCompleted', 'totalActivities'),
    ('tandaan', 'roundsCompleted', 'totalRounds'),
  ];

  /// How much of [module] a child has done, 0 to 1, from their progress.
  static double share(Map<String, dynamic>? progress, String module) {
    for (final (key, doneKey, totalKey) in modules) {
      if (key != module) continue;
      final m = progress?[key];
      if (m is! Map) return 0;
      final done = (m[doneKey] as num?)?.toDouble() ?? 0;
      final total = (m[totalKey] as num?)?.toDouble() ?? 0;
      return total > 0 ? (done / total).clamp(0.0, 1.0) : 0;
    }
    return 0;
  }

  /// Child id to the lesson they are furthest behind in, for every child
  /// who is behind in one. [progressById] is each child's synced progress.
  static Map<String, String> of(
      Map<String, Map<String, dynamic>?> progressById) {
    bool started(Map<String, dynamic>? p) =>
        ((p?['overallProgress'] as num?) ?? 0) > 0;
    final playing =
        progressById.entries.where((e) => started(e.value)).toList();
    if (playing.length < 2) return const {};

    final medians = <String, double>{};
    for (final (key, _, _) in modules) {
      final shares = [for (final e in playing) share(e.value, key)]..sort();
      medians[key] = shares[shares.length ~/ 2];
    }

    final result = <String, String>{};
    for (final e in playing) {
      String? worst;
      var worstRatio = 0.5; // under half of the middle of the class
      for (final (key, _, _) in modules) {
        final median = medians[key]!;
        if (median <= 0) continue;
        final ratio = share(e.value, key) / median;
        if (ratio < worstRatio) {
          worstRatio = ratio;
          worst = key;
        }
      }
      if (worst != null) result[e.key] = worst;
    }
    return result;
  }
}
