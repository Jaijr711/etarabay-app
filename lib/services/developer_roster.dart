import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_version.dart';

/// How the developer dashboard counts, narrows and orders the list of
/// student records. Plain data in, plain data out — no Firestore reads —
/// so every edge (midnight, the seventh day, a record never synced) can be
/// tested without a database.

/// A device counts as online if it wrote its `lastActive` heartbeat this
/// recently. There is no separate presence system; this is the same
/// heartbeat every device already writes on every sync.
const onlineWindow = Duration(seconds: 90);

/// Away: not seen for this long, or never.
const awayAfter = Duration(days: 7);

/// What the list is narrowed to — one of the counts at the top.
enum DevFilter { all, online, today, away, paused, outdated }

/// The order of the list.
enum DevSort { onlineFirst, name, progressLow, lastActive }

/// One student record as the dashboard reads it.
class DevRecord {
  DevRecord(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  String get name => (data['name'] ?? id).toString();
  String get lrn => (data['lrn'] ?? '').toString();
  bool get paused => data['disabledByDev'] == true;

  /// Finished by the developer for testing (see TestAccount).
  bool get testAccount => data['testAccount'] == true;

  DateTime? get lastActive {
    final ts = data['lastActive'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  /// 0..1, or null when the record has never synced any progress.
  double? get progress {
    final p = data['progress'];
    return p is Map ? (p['overallProgress'] as num?)?.toDouble() : null;
  }

  /// "1.2.57", or null for a phone on a version too old to say.
  String? get appVersion {
    final v = (data['appVersion'] ?? '').toString();
    return v.isEmpty ? null : v;
  }

  bool isOnline(DateTime now) {
    final at = lastActive;
    return at != null && now.difference(at) < onlineWindow;
  }

  bool isToday(DateTime now) {
    final at = lastActive?.toLocal();
    final today = now.toLocal();
    return at != null &&
        at.year == today.year &&
        at.month == today.month &&
        at.day == today.day;
  }

  bool isAway(DateTime now) {
    final at = lastActive;
    return at == null || now.difference(at) > awayAfter;
  }

  /// Behind the newest version any phone reports. A phone that reports no
  /// version is not counted: it may well be current, just never asked.
  bool isOutdated(String? newest) {
    final v = appVersion;
    return v != null && newest != null && AppVersion.compare(v, newest) < 0;
  }
}

/// The newest version any record reports, or null when none does.
String? newestVersion(Iterable<DevRecord> records) {
  String? newest;
  for (final r in records) {
    final v = r.appVersion;
    if (v != null && (newest == null || AppVersion.compare(v, newest) > 0)) {
      newest = v;
    }
  }
  return newest;
}

/// How many records each filter would show.
class DevRosterCounts {
  const DevRosterCounts({
    required this.all,
    required this.online,
    required this.today,
    required this.away,
    required this.paused,
    required this.outdated,
  });

  final int all;
  final int online;
  final int today;
  final int away;
  final int paused;
  final int outdated;

  int of(DevFilter f) => switch (f) {
        DevFilter.all => all,
        DevFilter.online => online,
        DevFilter.today => today,
        DevFilter.away => away,
        DevFilter.paused => paused,
        DevFilter.outdated => outdated,
      };
}

bool _matches(DevRecord r, DevFilter f, DateTime now, String? newest) =>
    switch (f) {
      DevFilter.all => true,
      DevFilter.online => r.isOnline(now),
      DevFilter.today => r.isToday(now),
      DevFilter.away => r.isAway(now),
      DevFilter.paused => r.paused,
      DevFilter.outdated => r.isOutdated(newest),
    };

DevRosterCounts countRoster(List<DevRecord> records, DateTime now) {
  final newest = newestVersion(records);
  int count(DevFilter f) =>
      records.where((r) => _matches(r, f, now, newest)).length;
  return DevRosterCounts(
    all: records.length,
    online: count(DevFilter.online),
    today: count(DevFilter.today),
    away: count(DevFilter.away),
    paused: count(DevFilter.paused),
    outdated: count(DevFilter.outdated),
  );
}

/// The records [filter] keeps and [query] matches (a name or a Student
/// Number containing it, any case), in [sort] order.
List<DevRecord> filterAndSort(
  List<DevRecord> records, {
  required DateTime now,
  DevFilter filter = DevFilter.all,
  DevSort sort = DevSort.onlineFirst,
  String query = '',
}) {
  final newest = newestVersion(records);
  final q = query.trim().toLowerCase();
  final kept = records.where((r) {
    if (!_matches(r, filter, now, newest)) return false;
    if (q.isEmpty) return true;
    return r.name.toLowerCase().contains(q) || r.lrn.toLowerCase().contains(q);
  }).toList();

  int byName(DevRecord a, DevRecord b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  kept.sort(switch (sort) {
    // "Who is on right now" at the top, without scrolling for it.
    DevSort.onlineFirst => (a, b) {
        final ao = a.isOnline(now), bo = b.isOnline(now);
        if (ao != bo) return ao ? -1 : 1;
        return byName(a, b);
      },
    DevSort.name => byName,
    // The children who need a look first. Never synced reads as nothing
    // done.
    DevSort.progressLow => (a, b) {
        final c = (a.progress ?? 0).compareTo(b.progress ?? 0);
        return c != 0 ? c : byName(a, b);
      },
    // Newest first; never seen last.
    DevSort.lastActive => (a, b) {
        final at = a.lastActive, bt = b.lastActive;
        if (at == null && bt == null) return byName(a, b);
        if (at == null) return 1;
        if (bt == null) return -1;
        final c = bt.compareTo(at);
        return c != 0 ? c : byName(a, b);
      },
  });
  return kept;
}
