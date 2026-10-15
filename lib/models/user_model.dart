class UserProfile {
  String name;
  String middleName;
  String gender;
  DateTime? birthday;
  DateTime? createdAt;
  String parentName;
  String parentContact;
  String lrn;
  String avatar;
  int stars;
  int lessonsCompleted;
  Map<String, int> achievements;
  List<String> certificates;
  List<String> claimedBadges;

  /// When each badge/certificate id was earned, in epoch milliseconds. The
  /// teacher dashboard's "recent achievements" feed that read these was
  /// removed (2026-10-15); they are still recorded, so a feed could come back
  /// without losing the history. Client clock rather than a server timestamp, in keeping
  /// with the rest of this offline-first sync: the moment that matters is
  /// when the child on this device earned it, not when the write reached
  /// Firestore.
  Map<String, int> badgeClaimedAt;
  Map<String, int> certificateAwardedAt;

  // Computed property for age based on birthday
  int get age {
    if (birthday == null) return 2; // Default age if no birthday
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  UserProfile({
    required this.name,
    this.middleName = '',
    required this.gender,
    this.birthday,
    this.createdAt,
    this.parentName = '',
    this.parentContact = '',
    this.lrn = '',
    this.avatar = '',
    this.stars = 0,
    this.lessonsCompleted = 0,
    Map<String, int>? achievements,
    List<String>? certificates,
    List<String>? claimedBadges,
    Map<String, int>? badgeClaimedAt,
    Map<String, int>? certificateAwardedAt,
  })  : achievements = achievements ?? {},
        certificates = certificates ?? [],
        claimedBadges = claimedBadges ?? [],
        badgeClaimedAt = badgeClaimedAt ?? {},
        certificateAwardedAt = certificateAwardedAt ?? {};

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'middleName': middleName,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'parentName': parentName,
      'parentContact': parentContact,
      'lrn': lrn,
      'avatar': avatar,
      'stars': stars,
      'lessonsCompleted': lessonsCompleted,
      'achievements': achievements,
      'certificates': certificates,
      'claimedBadges': claimedBadges,
      'badgeClaimedAt': badgeClaimedAt,
      'certificateAwardedAt': certificateAwardedAt,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      if (value is Map && value.containsKey('seconds')) {
        final secs = value['seconds'];
        if (secs is int) {
          return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        }
      }
      final str = value.toString();
      if (str.contains('seconds=')) {
        final match = RegExp(r'seconds=(\d+)').firstMatch(str);
        if (match != null) {
          final secs = int.parse(match.group(1)!);
          return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        }
      }
      return DateTime.tryParse(str);
    } catch (_) {
      return null;
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      middleName: json['middleName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      birthday: _parseDateTime(json['birthday']),
      createdAt: _parseDateTime(json['createdAt']),
      parentName: json['parentName']?.toString() ?? '',
      parentContact: json['parentContact']?.toString() ?? '',
      lrn: json['lrn']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      stars: json['stars'] ?? 0,
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      achievements: Map<String, int>.from(json['achievements'] ?? {}),
      certificates: List<String>.from(json['certificates'] ?? []),
      claimedBadges: List<String>.from(json['claimedBadges'] ?? []),
      badgeClaimedAt: Map<String, int>.from(json['badgeClaimedAt'] ?? {}),
      certificateAwardedAt:
          Map<String, int>.from(json['certificateAwardedAt'] ?? {}),
    );
  }
}
