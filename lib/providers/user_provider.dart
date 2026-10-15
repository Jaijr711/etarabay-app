import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/badge_catalog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  Box? _pb;
  Box? _gb;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  String? _currentStudentId;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  bool _hasSyncedFromCloud = false;

  /// How many times [syncFromFirebase] has retried after a failed initial
  /// pull this session — see the retry scheduled at the bottom of that
  /// method for why this exists.
  int _syncRetryCount = 0;
  static const int _maxSyncRetries = 5;
  String? _currentRole; // 'student' or 'teacher'
  bool _isAccountDeleted = false; // Flag to track if account was deleted
  bool _isDisabledByDev = false;

  /// The developer dashboard's own per-student note, kept as one field on
  /// the student's document (`adminMessage: {id, text, category}`) rather
  /// than a second Firestore stream — this one already exists and is
  /// already listened to for every signed-in student.
  String? _pendingAdminMessageId;
  String? _pendingAdminMessageText;

  /// One of [AdminMessageCategory.all] — decides which icon/colour
  /// AccountWatcher wraps the message in. Defaults to the plain
  /// announcement look for a message sent before this field existed.
  String _pendingAdminMessageCategory = 'announcement';

  /// A one-time kick from the developer dashboard, distinct from
  /// [_isDisabledByDev]: consumed the moment it's seen (see
  /// [_appliedForceLogoutKey]), so it never re-fires once this device has
  /// acted on it, and never blocks logging back in the way a pause does.
  bool _forceLogoutPending = false;

  /// The modules the developer dashboard has locked, app-wide, for every
  /// student — kept on the shared `config/developer` doc rather than per
  /// student, and watched independently of any student session (see
  /// [_startConfigListener]) so a lock applies even before anyone signs in.
  Set<String> _lockedModules = {};
  StreamSubscription<DocumentSnapshot>? _configSubscription;

  Box get _profileBox => _pb!;
  Box get _progressBox => _gb!;

  /// The `lastResetAt` marker we have already acted on, so one teacher reset
  /// wipes local progress exactly once instead of on every cloud snapshot.
  /// The reset this device has already acted on, kept per child.
  ///
  /// It used to be one key shared by everybody on the phone. On a device with
  /// two children — which the parent switcher exists to support — child A's
  /// marker sat in that slot when child B signed in; B's own, older marker did
  /// not match it, so B's progress was wiped for a reset that was never
  /// theirs. Switching back wiped A for the same reason, and it never settled:
  /// the two erased each other on every switch.
  ///
  /// Nothing cleared it, either. It matches none of the progress prefixes, so
  /// it outlived account switches and full local wipes alike.
  String get _appliedResetKey => appliedResetKeyFor(_currentStudentId);

  /// Named so a test can hold the two children apart, which is the whole
  /// point of the key.
  static String appliedResetKeyFor(String? studentId) =>
      'applied_reset_marker_$studentId';

  /// The id of the last developer-dashboard message this device has shown
  /// for the signed-in student — kept per student for the same reason
  /// [_appliedResetKey] is: a shared device can hold more than one child's
  /// account.
  String get _acknowledgedAdminMessageKey =>
      'acknowledged_admin_message_$_currentStudentId';

  /// Marks the current developer-dashboard message as shown, so it does
  /// not reappear on the next snapshot or the next app launch. Call this
  /// once the child has dismissed it.
  Future<void> acknowledgeAdminMessage() async {
    final id = _pendingAdminMessageId;
    if (id == null) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    await prefs.setString(_acknowledgedAdminMessageKey, id);
    // Also recorded on the student's own document. The local key alone is
    // per device, while the message stays on the document indefinitely, so
    // every new phone or browser this child signs in on showed it again —
    // long after it was read. Best effort: offline, the local key still
    // covers this device and Firestore queues the write.
    final studentId = _currentStudentId;
    if (studentId != null) {
      FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .update({'adminMessageAckId': id}).catchError((e) {
        debugPrint('acknowledgeAdminMessage: cloud ack failed: $e');
      });
    }
    _pendingAdminMessageId = null;
    _pendingAdminMessageText = null;
    _pendingAdminMessageCategory = 'announcement';
    notifyListeners();
  }

  /// The last developer-dashboard force-logout marker this device has
  /// already acted on for the signed-in student — same idea as
  /// [_appliedResetKey], kept per student for the same shared-device
  /// reason.
  String get _appliedForceLogoutKey =>
      'applied_force_logout_$_currentStudentId';

  /// Where each module keeps its progress, in both Hive and SharedPreferences.
  ///
  /// Used to undo one module without touching the others. The full reset has
  /// its own, longer list — it is allowed to be blunt.
  static const Map<String, List<String>> moduleKeyPrefixes = {
    'matematika': ['mat_', 'matematika_'],
    'pamilya': ['pamilya_'],
    'magbasa': ['magbasa_', 'tula_', 'kwento_', 'kanta_', 'karaoke_'],
    'traceit': ['traceit_', 'sundan_'],
    'kulay': ['kulay_'],
    'tandaan': ['tandaan_'],
  };

  UserProfile? get userProfile => _userProfile;
  bool get hasUserProfile => _userProfile != null;
  bool get isInitialized => _isInitialized;
  String? get currentStudentId => _currentStudentId;
  String? get currentRole => _currentRole;
  bool get isAccountDeleted => _isAccountDeleted;
  bool get isDisabledByDev => _isDisabledByDev;

  /// The developer dashboard's message for this student, if there is one
  /// this device hasn't shown yet — null once [acknowledgeAdminMessage]
  /// has recorded that it has.
  String? get pendingAdminMessage => _pendingAdminMessageText;

  /// Which icon/colour AccountWatcher should wrap [pendingAdminMessage] in
  /// — one of `AdminMessageCategory.all`.
  String get pendingAdminMessageCategory => _pendingAdminMessageCategory;

  /// True for exactly one build after a developer-dashboard kick this
  /// device hasn't acted on yet — see [_appliedForceLogoutKey]. Consumed by
  /// [logoutAndClearData] the same moment [AccountWatcher] acts on it, so
  /// it never lingers into the next session.
  bool get forceLogoutPending => _forceLogoutPending;

  /// The modules currently locked app-wide by the developer dashboard —
  /// see [moduleKeyPrefixes] for the keys this checks against.
  Set<String> get lockedModules => _lockedModules;

  /// Set the current student ID (from RTDB login result) for syncing.
  void setCurrentStudentId(String? id) {
    _currentStudentId = id;
    if (_currentStudentId != null) {
      _isAccountDeleted = false; // Reset when setting new user
      _prefs?.setString('session_student_id', id!);
      _hasSyncedFromCloud = false; // Reset for new user
      _startProfileListener();
    } else {
      _prefs?.remove('session_student_id');
      _hasSyncedFromCloud = false;
      _stopProfileListener();
    }
    notifyListeners();
  }

  void setCurrentRole(String? role) {
    _currentRole = role;
    if (role != null) {
      _prefs?.setString('session_role', role);
    } else {
      _prefs?.remove('session_role');
    }
    notifyListeners();
  }

  /// Store the LRN the student typed at login locally (device only) so the
  /// certificate can display it. This is never synced to the cloud as
  /// plaintext (the cloud only keeps the hashed `lrnHash`).
  Future<void> setSessionLrn(String lrn) async {
    if (_userProfile == null || lrn.trim().isEmpty) return;
    _userProfile!.lrn = lrn.trim();
    await _profileBox.put('currentUser', _userProfile!.toJson());
    notifyListeners();
  }

  Future<void> logout() async {
    _currentStudentId = null;
    _currentRole = null;
    _userProfile = null;
    _hasSyncedFromCloud = false;
    _isAccountDeleted = false;
    _stopProfileListener();

    if (_prefs != null) {
      await _prefs!.remove('session_student_id');
      await _prefs!.remove('session_role');
    }

    await _profileBox.clear();
    // Note: We don't clear progressBox here because they might want to use it offline,
    // but the session is cleared.
    notifyListeners();
  }

  void _startProfileListener() {
    _stopProfileListener();
    if (_currentStudentId == null) return;

    _profileSubscription = FirebaseFirestore.instance
        .collection('students')
        .doc(_currentStudentId)
        .snapshots()
        .listen((snapshot) async {
      // A snapshot that did NOT come from the cache is the app's proof that
      // it is talking to the server right now. That is the one moment we can
      // be sure the online half is available.
      final bool fromServer = !snapshot.metadata.isFromCache;

      // If the child started playing offline, the initial pull failed and
      // `_hasSyncedFromCloud` stayed false, which blocks every upload for the
      // rest of the session — even after the signal comes back. Reaching the
      // server clears that block and flushes what they earned offline.
      final bool releasingGuard = fromServer && !_hasSyncedFromCloud;

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          if (data.containsKey('profile')) {
            final profileData =
                Map<String, dynamic>.from(data['profile'] as Map);
            // Inject root-level avatar if profile.avatar is missing
            if (data.containsKey('avatar') &&
                (profileData['avatar'] == null ||
                    profileData['avatar'] == '')) {
              profileData['avatar'] = data['avatar'];
            }
            if (profileData.isNotEmpty) {
              // Once the first pull has landed, this device is the authority
              // on the running totals for the rest of the session — it is the
              // one the child is playing on, and every change it makes is
              // queued straight back up.
              //
              // This used to be a "stars only ever grow" clamp, which stopped
              // a stale cloud copy from erasing freshly earned stars. That
              // clamp cannot survive replaying a level: a replay now replaces
              // that level's rating, so a weaker second run legitimately
              // *lowers* the total, and a rule that forbids decreases would
              // silently undo it.
              final previous = _userProfile;
              _userProfile = UserProfile.fromJson(profileData);
              if (_hasSyncedFromCloud && previous != null) {
                _userProfile!.stars = previous.stars;
                _userProfile!.lessonsCompleted = previous.lessonsCompleted;
                // Same reasoning as stars above: once the first pull has
                // landed, this device is the authority on badges for the
                // rest of the session too. Without this, a claim (or a
                // freshly-raised tier) written here and echoed back by a
                // snapshot that hasn't caught up yet — the write is
                // fire-and-forget — got clobbered by the older cloud copy
                // this same replacement had just loaded, and the badge
                // reappeared unclaimed a moment after it was claimed.
                _userProfile!.achievements = previous.achievements;
                _userProfile!.claimedBadges = previous.claimedBadges;
                _userProfile!.badgeClaimedAt = previous.badgeClaimedAt;
                // The certificate has to travel with the badges it is made
                // of. It was left out of this list, so a child who finished
                // offline — claiming the twelfth badge, which awards the
                // certificate locally on the spot — had it taken away again
                // the moment the signal came back: their own upload is
                // fire-and-forget, so the first snapshot to arrive is still
                // the cloud's older copy with no certificate in it, and this
                // replacement took that copy's empty list. The badges beside
                // it survived only because they are named here.
                _userProfile!.certificates = previous.certificates;
                _userProfile!.certificateAwardedAt =
                    previous.certificateAwardedAt;
              } else if (_isInitialized) {
                // Before the first pull lands, what arrives here can be
                // Firestore's cached copy of the document from an earlier
                // session — older than what this device has already
                // recorded. Taking its star total wholesale rolled the child
                // back to the last number the cloud knew, and left them
                // there for the rest of the session; the stars came back on
                // the next launch, out of nowhere. The record on this device
                // can raise the total but never lower it, because the record
                // may not have been restored yet.
                _userProfile!.stars = reconcileStars(
                  shown: _userProfile!.stars,
                  counted: recountStarsFromProgress(),
                  recordRestored: false,
                );
              }
              _profileBox.put('currentUser', _userProfile!.toJson());
            }
          }

          // A second device on this same account shows up here the moment
          // it pushes — not just the next time *this* device happens to
          // sync — so the dashboard picks up the other device's freshly
          // finished activities live, the same way its stars and badges
          // already do above.
          if (data['rawProgress'] is Map) {
            await _mergeRawProgressFromCloud(data);
            if (_userProfile != null) {
              _userProfile!.stars = recountStarsFromProgress();
              await _profileBox.put('currentUser', _userProfile!.toJson());
              // The merge can be what completes the last lesson — the other
              // device finished it, or this one finished it offline and is
              // only now getting the cloud's side of the story. Since the
              // certificate asks for every lesson finished as well as every
              // badge claimed, it has to be re-settled here; otherwise it
              // waited for the child to happen to do something else before
              // the app noticed they had already earned it. Cheap when
              // nothing changed: the check only writes if it awards or
              // withdraws something.
              await checkAndAwardCertificates();
            }
          }

          // The developer dashboard's kill switch. Checked on every snapshot,
          // same as the reset marker below, so it takes effect the moment it
          // is set rather than waiting for this device's next sync.
          _isDisabledByDev = data['disabledByDev'] == true;

          // The developer dashboard's message for this student, if this
          // device has not already shown it. Compared by id (a Firestore
          // auto-id, not the text) so a message equal to a previous one is
          // still shown, and one already acknowledged is not shown again
          // after a plain snapshot re-fires for an unrelated field.
          final adminMessage = data['adminMessage'];
          if (adminMessage is Map) {
            final id = adminMessage['id']?.toString();
            final text = adminMessage['text']?.toString();
            final category = adminMessage['category']?.toString();
            if (id != null &&
                id.isNotEmpty &&
                text != null &&
                text.isNotEmpty) {
              final prefs = _prefs ?? await SharedPreferences.getInstance();
              _prefs ??= prefs;
              final acknowledged =
                  prefs.getString(_acknowledgedAdminMessageKey);
              // Read on any device counts — see acknowledgeAdminMessage.
              final ackedInCloud =
                  data['adminMessageAckId']?.toString() == id;
              if (acknowledged != id && !ackedInCloud) {
                _pendingAdminMessageId = id;
                _pendingAdminMessageText = text;
                _pendingAdminMessageCategory =
                    (category != null && category.isNotEmpty)
                        ? category
                        : 'announcement';
              } else if (_pendingAdminMessageId == id) {
                // Dismissed on another device while showing here.
                _pendingAdminMessageId = null;
                _pendingAdminMessageText = null;
                _pendingAdminMessageCategory = 'announcement';
              }
            }
          }

          // The developer dashboard's one-time kick. Same shape as the
          // reset marker below — a marker this device applies once, keyed
          // per student so a second child on this device isn't kicked by a
          // marker meant for the first.
          final forceLogoutMarker = data['forceLogoutAt']?.toString();
          if (forceLogoutMarker != null && forceLogoutMarker.isNotEmpty) {
            final prefs = _prefs ?? await SharedPreferences.getInstance();
            _prefs ??= prefs;
            final applied = prefs.getString(_appliedForceLogoutKey);
            if (applied != forceLogoutMarker) {
              await prefs.setString(_appliedForceLogoutKey, forceLogoutMarker);
              _forceLogoutPending = true;
            }
          }

          // Wipe local progress only for a NEW teacher-initiated reset.
          //
          // This used to also fire whenever the server reported zero progress,
          // but "zero on the server" is indistinguishable from "this device
          // hasn't uploaded yet" — so every snapshot wiped the stars the child
          // had just earned. It also re-ran on every snapshot for the same
          // `lastResetAt`, so one reset kept erasing progress forever. Both are
          // fixed by keying off a reset marker we haven't applied yet.
          final resetMarker = data['lastResetAt']?.toString();
          if (resetMarker != null && resetMarker.isNotEmpty) {
            // Not `_prefs?`. If a snapshot arrived before initialisation had
            // finished, the read gave null, the wipe ran, and the write was
            // silently skipped — so the next snapshot wiped again, and every
            // one after it, for as long as the app stayed open. The child
            // would have watched their stars vanish over and over.
            final prefs = _prefs ?? await SharedPreferences.getInstance();
            _prefs ??= prefs;
            final appliedMarker = prefs.getString(_appliedResetKey);
            if (appliedMarker != resetMarker) {
              // A teacher who reset one module did not ask for the child's
              // stars, badges and certificates to go with it.
              await _clearLocalStudentProgressKeys(
                  scope: data['lastResetScope']?.toString() ?? 'all');
              await prefs.setString(_appliedResetKey, resetMarker);
            }
          }

          notifyListeners();
        }
      } else if (fromServer) {
        // Only the server can testify that an account is gone. Offline — or
        // on a device that has never cached this student's document — the
        // snapshot is empty simply because there is nothing local to read,
        // and treating that as a deletion locked a child out of a game they
        // were entitled to play without any internet at all.
        if (_currentStudentId != null) {
          debugPrint(
              'DEBUG: Account for $_currentStudentId does not exist on server.');
          _isAccountDeleted = true;
          notifyListeners();
        }
      }

      // Done last, so the upload carries the freshly merged profile rather
      // than whatever was in memory before this snapshot arrived.
      if (releasingGuard) {
        _hasSyncedFromCloud = true;
        _syncRetryCount = 0;
        debugPrint('Back online: flushing offline progress.');
        unawaited(_syncToFirebase());
      }
    }, onError: (Object e) {
      // A dropped stream must not take the app down with it. Playing is
      // local; the listener is only how the cloud half announces itself.
      debugPrint('Profile listener error: $e');
    });
  }

  /// Undo a teacher's reset on this device.
  ///
  /// [scope] is `'all'`, or the comma-separated modules the teacher chose.
  /// Anything but `'all'` clears only those modules and then recounts what
  /// the child still has — because a reset of Matematika used to run this
  /// whole method and take the child's stars, badges and certificates with
  /// it. Those were never reset in the cloud, so nothing brought them back:
  /// they were simply gone.
  Future<void> _clearLocalStudentProgressKeys({String scope = 'all'}) async {
    try {
      if (scope.isNotEmpty && scope != 'all') {
        await _clearModulesLocally(scope.split(','));
        return;
      }

      // 1. Clear Hive progress box
      if (_gb != null) {
        await _gb!.clear();
      }

      // 2. Reset Profile stars & completed counts & achievements
      if (_userProfile != null) {
        _userProfile!.stars = 0;
        _userProfile!.lessonsCompleted = 0;
        _userProfile!.achievements = {};
        // The collected list has to go with the earned list. Clearing only
        // `achievements` left badges in `claimedBadges` that were no longer
        // earned and no longer drawn in the grid, so the trophy counter kept
        // reporting awards the child could not see anywhere.
        _userProfile!.claimedBadges = [];
        if (_pb != null) {
          await _pb!.put('currentUser', _userProfile!.toJson());
        }
      }

      // 3. Clear all local SharedPreferences progress & lesson keys
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      const keysToKeep = {
        'has_seen_onboarding',
        'notifications_enabled',
        'sound_enabled',
        'music_enabled',
        'session_student_id',
        'session_role',
        'language_code',
      };

      final allKeys = prefs.getKeys();
      for (final k in allKeys) {
        if (!keysToKeep.contains(k)) {
          if (k.startsWith('sundan_') ||
              k.startsWith('traceit_') ||
              k.startsWith('mat_') ||
              k.startsWith('matematika_') ||
              k.startsWith('pamilya_') ||
              k.startsWith('kulay_') ||
              k.startsWith('magbasa_') ||
              k.startsWith('tula_') ||
              k.startsWith('kwento_') ||
              k.startsWith('kanta_') ||
              k.startsWith('karaoke_') ||
              k.startsWith('tandaan_') ||
              k.startsWith('quiz_') ||
              k.startsWith('progress_') ||
              k.startsWith('level_') ||
              k.startsWith('game_') ||
              k.contains('_activity') ||
              k.contains('_completed') ||
              k.contains('_score') ||
              k.contains('_stars') ||
              k.contains('_attempts') ||
              k.contains('_creations')) {
            await prefs.remove(k);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing local student progress keys: $e');
    }
  }

  /// Clears just the modules the teacher named, and leaves the rest alone.
  ///
  /// Stars and badges are not zeroed here — they are recounted from what the
  /// child still has finished. A child who loses Matematika keeps the stars
  /// they earned in Magbasa, and the badges that no longer hold are withdrawn
  /// by the same check that awards them.
  Future<void> _clearModulesLocally(List<String> modules) async {
    final prefixes = <String>[];
    for (final m in modules) {
      prefixes.addAll(moduleKeyPrefixes[m.trim()] ?? const []);
    }
    if (prefixes.isEmpty) return;

    bool matches(String key) => prefixes.any(key.startsWith);

    if (_gb != null) {
      for (final key in _gb!.keys.toList()) {
        if (key is String && matches(key)) await _gb!.delete(key);
      }
    }

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (matches(key)) await prefs.remove(key);
    }

    // The box seeds a module's defaults on open; the keys just deleted have to
    // come back as zeroes or the getters read null and the dashboard blanks.
    _initProgressBox();

    if (_userProfile != null) {
      _userProfile!.stars = recountStarsFromProgress();
      if (_pb != null) {
        await _pb!.put('currentUser', _userProfile!.toJson());
      }
    }
    // Withdraws whatever the remaining work no longer earns, certificates
    // included.
    await checkAndAwardBadges();
    notifyListeners();
  }

  /// Public method to force reset all local student progress state instantly
  Future<void> resetAllProgressLocally() async {
    await _clearLocalStudentProgressKeys();
  }

  void _stopProfileListener() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  /// The developer dashboard's module locks, watched independently of any
  /// student session — a lock is app-wide, not something tied to who's
  /// signed in, so this starts once at launch rather than in
  /// [_startProfileListener].
  void _startConfigListener() {
    _configSubscription = FirebaseFirestore.instance
        .collection('config')
        .doc('developer')
        .snapshots()
        .listen((snapshot) {
      final locked = snapshot.data()?['lockedModules'];
      _lockedModules =
          locked is List ? locked.map((e) => e.toString()).toSet() : <String>{};
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Config listener error: $e');
    });
  }

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _ensureInitialized();
      await _initializeBoxes();
      _startConfigListener();
      _watchSignIn();
    } catch (e) {
      debugPrint('CRITICAL: UserProvider initialization failed: $e');
    }
  }

  StreamSubscription<User?>? _authSubscription;
  String? _authedUid;

  /// Firestore only answers a signed-in app, and the anonymous sign-in now
  /// finishes in the background after the first frame (see main.dart) — so
  /// the listeners started at launch can be refused before it lands, and a
  /// refused listener stays dead. When the sign-in arrives they are started
  /// again, and a pull that was refused is retried.
  void _watchSignIn() {
    try {
      _authSubscription ??=
          FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null || user.uid == _authedUid) return;
        _authedUid = user.uid;
        _configSubscription?.cancel();
        _startConfigListener();
        if (_currentStudentId != null) {
          _startProfileListener();
          if (!_hasSyncedFromCloud) syncFromFirebase();
        }
      });
    } catch (e) {
      debugPrint('Sign-in watch unavailable: $e');
    }
  }

  /// Ensures that boxes are ready before usage in async methods.
  Future<void> _ensureInitialized() async {
    try {
      if (_pb == null) {
        if (Hive.isBoxOpen('userProfile')) {
          _pb = Hive.box('userProfile');
        } else {
          _pb = await Hive.openBox('userProfile');
        }
      }

      if (_gb == null) {
        if (Hive.isBoxOpen('userProgress')) {
          _gb = Hive.box('userProgress');
        } else {
          _gb = await Hive.openBox('userProgress');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring boxes are initialized: $e');
    }
  }

  Future<void> _initializeBoxes() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load session
      _currentRole = _prefs!.getString('session_role');
      _currentStudentId = _prefs!.getString('session_student_id');

      if (_currentStudentId != null) {
        _startProfileListener();
        // Trigger background sync if they just opened the app
        syncFromFirebase();
      }

      _loadUserProfile();
      _initProgressBox();
      _isInitialized = true;
      // A profile written under the old weighting is re-counted here, once.
      unawaited(_migrateStarWeighting());
      unawaited(_migrateMagbasaKantaLayout());
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing boxes: $e');
    }
  }

  void _initProgressBox() {
    // Matematika progress
    if (!_progressBox.containsKey('matematika_total')) {
      _progressBox.put('matematika_total', 0);
    }
    if (!_progressBox.containsKey('matematika_stars')) {
      _progressBox.put('matematika_stars', 0);
    }
    if (!_progressBox.containsKey('matematika_levels')) {
      _progressBox.put(
          'matematika_levels', List<bool>.filled(matematikaLevelCount, false));
    }
    if (!_progressBox.containsKey('matematika_games')) {
      _progressBox.put('matematika_games', {});
    }
    if (!_progressBox.containsKey('matematika_streak')) {
      _progressBox.put('matematika_streak', 0);
    }
    if (!_progressBox.containsKey('matematika_last_played')) {
      _progressBox.put(
          'matematika_last_played', DateTime.now().toIso8601String());
    }

    // Pamilya (Ang Aking Sarili) progress
    if (!_progressBox.containsKey('pamilya_total')) {
      _progressBox.put('pamilya_total', 0);
    }
    if (!_progressBox.containsKey('pamilya_stars')) {
      _progressBox.put('pamilya_stars', 0);
    }
    if (!_progressBox.containsKey('pamilya_levels')) {
      _progressBox.put('pamilya_levels', List.filled(9, false));
    }
    if (!_progressBox.containsKey('pamilya_games')) {
      _progressBox.put('pamilya_games', {});
    }
    if (!_progressBox.containsKey('pamilya_streak')) {
      _progressBox.put('pamilya_streak', 0);
    }
    if (!_progressBox.containsKey('pamilya_last_played')) {
      _progressBox.put('pamilya_last_played', DateTime.now().toIso8601String());
    }

    // Magbasa Tayo progress
    if (!_progressBox.containsKey('magbasa_total')) {
      _progressBox.put('magbasa_total', 0);
    }
    if (!_progressBox.containsKey('magbasa_tula')) {
      _progressBox.put('magbasa_tula', {});
    }
    if (!_progressBox.containsKey('magbasa_kwento')) {
      _progressBox.put('magbasa_kwento', {});
    }
    if (!_progressBox.containsKey('magbasa_kanta')) {
      _progressBox.put('magbasa_kanta', {});
    }

    // Kulay-Saya progress
    if (!_progressBox.containsKey('kulay_basic')) {
      _progressBox.put('kulay_basic', false);
    }
    if (!_progressBox.containsKey('kulay_mixing')) {
      _progressBox.put('kulay_mixing', false);
    }
    if (!_progressBox.containsKey('kulay_objects')) {
      _progressBox.put('kulay_objects', false);
    }
    if (!_progressBox.containsKey('kulay_coloring')) {
      _progressBox.put('kulay_coloring', false);
    }
    if (!_progressBox.containsKey('kulay_total')) {
      _progressBox.put('kulay_total', 0);
    }

    // Trace It progress
    if (!_progressBox.containsKey('traceit_uppercase')) {
      _progressBox.put('traceit_uppercase', List.filled(26, false));
    }
    if (!_progressBox.containsKey('traceit_lowercase')) {
      _progressBox.put('traceit_lowercase', List.filled(26, false));
    }
    if (!_progressBox.containsKey('traceit_numbers')) {
      _progressBox.put('traceit_numbers', List.filled(10, false));
    }
    if (!_progressBox.containsKey('traceit_total')) {
      _progressBox.put('traceit_total', 0);
    }
  }

  void _loadUserProfile() {
    if (_pb == null) return;
    try {
      final data = _pb!.get('currentUser');
      if (data != null) {
        _userProfile = UserProfile.fromJson(Map<String, dynamic>.from(data));
        _claimPendingStars();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> createUserProfile(
    String name,
    String gender, {
    String middleName = '',
    DateTime? birthday,
    String? parentName,
    String? parentContact,
    String? lrn,
  }) async {
    await _ensureInitialized();
    _userProfile = UserProfile(
      name: name,
      middleName: middleName,
      gender: gender,
      birthday: birthday,
      createdAt: DateTime.now(),
      parentName: parentName ?? '',
      parentContact: parentContact ?? '',
      lrn: lrn ?? '',
    );
    if (_pb != null) {
      await _pb!.put('currentUser', _userProfile!.toJson());
    }
    await _syncToFirebase();
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? name,
    String? middleName,
    String? gender,
    DateTime? birthday,
    String? parentName,
    String? parentContact,
    String? lrn,
  }) async {
    await _ensureInitialized();
    if (_userProfile == null) return;

    _userProfile = UserProfile(
      name: name ?? _userProfile!.name,
      middleName: middleName ?? _userProfile!.middleName,
      gender: gender ?? _userProfile!.gender,
      birthday: birthday ?? _userProfile!.birthday,
      createdAt: _userProfile!.createdAt ?? DateTime.now(),
      parentName: parentName ?? _userProfile!.parentName,
      parentContact: parentContact ?? _userProfile!.parentContact,
      lrn: lrn ?? _userProfile!.lrn,
      // Kept. It was left out here, so saving the edit sheet reset the
      // child's picture to none.
      avatar: _userProfile!.avatar,
      stars: _userProfile!.stars,
      lessonsCompleted: _userProfile!.lessonsCompleted,
      achievements: Map<String, int>.from(_userProfile!.achievements),
      certificates: List<String>.from(_userProfile!.certificates),
      claimedBadges: List<String>.from(_userProfile!.claimedBadges),
      badgeClaimedAt: Map<String, int>.from(_userProfile!.badgeClaimedAt),
      certificateAwardedAt:
          Map<String, int>.from(_userProfile!.certificateAwardedAt),
    );

    await _profileBox.put('currentUser', _userProfile!.toJson());
    await _syncToFirebase();
    notifyListeners();
  }

  /// The child's own choice of picture (one of [animalAvatars]).
  ///
  /// Saved on this device, and on the class record — both the top-level
  /// `avatar` the teacher's dashboard reads first and `profile.avatar` — so
  /// the teacher sees the new face without anyone editing the student.
  /// `avatarChosen` marks that the child has picked once, so the first-login
  /// "Choose Avatar" screen is not shown again.
  ///
  /// Not awaited, like every other write here: offline, Firestore keeps the
  /// change and sends it once the signal is back.
  Future<void> setAvatar(String preset) async {
    await _ensureInitialized();
    if (_userProfile == null) return;
    _userProfile!.avatar = preset;
    await _profileBox.put('currentUser', _userProfile!.toJson());
    notifyListeners();
    final id = _currentStudentId;
    if (id == null) return;
    try {
      unawaited(FirebaseFirestore.instance
          .collection('students')
          .doc(id)
          .update({
        'avatar': preset,
        'profile.avatar': preset,
        'avatarChosen': true,
      }).catchError((Object e) => debugPrint('Avatar sync failed: $e')));
    } catch (e) {
      debugPrint('Avatar sync unavailable: $e');
    }
  }

  Future<void> syncFromFirebase() async {
    await _ensureInitialized();
    if (_currentStudentId == null) return;
    try {
      // Prioritize fast login: fetch from server with a short timeout, fallback to cache
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(_currentStudentId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data == null) {
          _hasSyncedFromCloud = true;
          return;
        }

        // Restore Profile
        Map<String, dynamic> mergedProfileData = {};

        // Merge with the actual 'profile' map FIRST
        if (data.containsKey('profile') && data['profile'] is Map) {
          final profileData = Map<String, dynamic>.from(data['profile'] as Map);
          mergedProfileData.addAll(profileData);
        }

        // THEN extract root fields and overwrite the nested ones (if root is not empty),
        // because previous versions of the app might have saved empty strings inside the nested profile map.
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          mergedProfileData['name'] = data['name'];
        }
        if (data['gender'] != null && data['gender'].toString().isNotEmpty) {
          mergedProfileData['gender'] = data['gender'];
        }
        if (data['lrn'] != null && data['lrn'].toString().isNotEmpty) {
          mergedProfileData['lrn'] = data['lrn'];
        }
        if (data['parentName'] != null &&
            data['parentName'].toString().isNotEmpty) {
          mergedProfileData['parentName'] = data['parentName'];
        }
        if (data['parentContact'] != null &&
            data['parentContact'].toString().isNotEmpty) {
          mergedProfileData['parentContact'] = data['parentContact'];
        }
        if (data['birthday'] != null &&
            data['birthday'].toString().isNotEmpty) {
          mergedProfileData['birthday'] = data['birthday'];
        }
        // Use Firestore's enrolledAt timestamp as createdAt if available and
        // we don't already have one locally.
        if (mergedProfileData['createdAt'] == null) {
          final enrolled = data['enrolledAt'];
          if (enrolled != null) {
            if (enrolled is Timestamp) {
              mergedProfileData['createdAt'] =
                  enrolled.toDate().toIso8601String();
            } else if (enrolled is String) {
              mergedProfileData['createdAt'] = enrolled;
            }
          } else {
            mergedProfileData['createdAt'] = DateTime.now().toIso8601String();
          }
        }

        if (mergedProfileData.isNotEmpty) {
          _userProfile = UserProfile.fromJson(mergedProfileData);
          await _profileBox.put('currentUser', _userProfile!.toJson());
        }

        // Restore Raw Progress
        final bool rawProgressRestored =
            data.containsKey('rawProgress') && data['rawProgress'] is Map;
        if (rawProgressRestored) {
          await _mergeRawProgressFromCloud(data);
        }
        await _repairMatematikaLevelStars();

        // The star total that just arrived is a cache of finished work, and
        // the finished work itself is on this device — so it is counted
        // rather than trusted, before anything is pushed back up.
        //
        // This used to run only when the document carried `rawProgress`. A
        // document without one — a new account, or one whose uploads were
        // still blocked by the initial-pull guard — therefore replaced the
        // child's total with the cloud's and counted nothing. A child who
        // had played offline was handed back the cloud's stale number for
        // the whole session, and got their own back only a launch later,
        // when a `rawProgress` finally existed for the recount to run
        // beside. That delay is what a star total appearing to grow
        // overnight actually was.
        if (_userProfile != null) {
          final reconciled = reconcileStars(
            shown: _userProfile!.stars,
            counted: recountStarsFromProgress(),
            recordRestored: rawProgressRestored,
          );
          if (reconciled != _userProfile!.stars) {
            debugPrint('Cloud star total ${_userProfile!.stars} '
                'reconciled to $reconciled against the local record');
            _userProfile!.stars = reconciled;
            await _profileBox.put('currentUser', _userProfile!.toJson());
          }
        }

        // Badges first: the certificate is awarded off them, so checking it
        // against yesterday's medals meant a withdrawal arrived an event
        // late. No withdrawals here — see checkAndAwardBadges(allowRevoke).
        await checkAndAwardBadges(allowRevoke: false);
        await checkAndAwardCertificates(allowRevoke: false);
        _syncToFirebase();

        // Restore Creations
        if (data.containsKey('creations') && data['creations'] is List) {
          await _progressBox.put('coloring_creations', data['creations']);
        }

        _hasSyncedFromCloud = true;
        _syncRetryCount = 0;
      } else {
        // Document does not exist, so they are a new student in terms of progress
        _hasSyncedFromCloud = true;
        _syncRetryCount = 0;
      }
    } catch (e) {
      debugPrint('Error syncing from Firebase: $e');
      // Do NOT set _hasSyncedFromCloud to true here, so we retry or block pushes.
      //
      // The 4-second timeout above is short enough that an ordinary bit of
      // mobile-network lag trips it, not just a real outage — and once it
      // does, every push for the rest of the session was silently dropped
      // (see the guard at the top of _syncToFirebase), recoverable only by
      // restarting the app. The live profile listener's own recovery path
      // (`releasingGuard` in _startProfileListener) is supposed to catch
      // this too, but it depends on a fresh server snapshot arriving on its
      // own timing, which is not something a child stuck offline-feeling
      // with a live connection should have to wait out. A few quick,
      // increasingly-spaced retries of this same pull covers the common
      // case — a momentary blip — directly, while a genuinely long outage
      // still ends with the same listener-based recovery once it clears.
      if (_syncRetryCount < _maxSyncRetries) {
        _syncRetryCount++;
        final delay = Duration(seconds: 4 * _syncRetryCount);
        unawaited(Future.delayed(delay, () {
          if (!_hasSyncedFromCloud) syncFromFirebase();
        }));
      }
    }
    notifyListeners();
  }

  /// Remove every progress-related SharedPreferences key. Must cover ALL
  /// modules so no stale local progress leaks into a different account on
  /// the same device.
  ///
  /// Drawn from [moduleKeyPrefixes] rather than its own hand-kept list —
  /// that list once fell out of sync with it (missing 'sundan_' and every
  /// Magbasa sub-prefix except 'magbasa_' itself), so a child switching
  /// accounts on a shared device kept the previous child's Trace It and
  /// Magbasa completions, and their star total counted both.
  Future<void> _clearProgressPrefs() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final prefixes = [
      'mat_', // legacy Matematika prefix, kept for older installs
      ...moduleKeyPrefixes.values.expand((p) => p),
    ];
    final keys = prefs
        .getKeys()
        .where((k) => prefixes.any((p) => k.startsWith(p)))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearLocalData() async {
    await _ensureInitialized();
    _userProfile = null;
    await _profileBox.clear();
    await _progressBox.clear();
    await _clearProgressPrefs();
    _initProgressBox();
    notifyListeners();
  }

  /// Begin a student session. If a DIFFERENT student was previously on this
  /// device, wipe all their local data first so the new account starts clean
  /// (also handles a teacher deleting an account and enrolling a fresh one).
  Future<void> startStudentSession(String id) async {
    await _ensureInitialized();
    final prevId = _prefs?.getString('session_student_id');
    if (prevId != null && prevId != id) {
      await clearLocalData();
    }
    setCurrentStudentId(id);
  }

  /// Full wipe + logout — used when the teacher has deleted the account so no
  /// residual local progress remains for the next (new) account.
  Future<void> logoutAndClearData() async {
    _stopProfileListener();
    await clearLocalData();
    _currentStudentId = null;
    _currentRole = null;
    _hasSyncedFromCloud = false;
    _isAccountDeleted = false;
    _isDisabledByDev = false;
    _forceLogoutPending = false;
    if (_prefs != null) {
      await _prefs!.remove('session_student_id');
      await _prefs!.remove('session_role');
    }
    notifyListeners();
  }

  /// Number of consecutive calendar days ending today that [lastPlayedIso]
  /// and [storedStreak] add up to.
  ///
  /// Compared by calendar date, not elapsed hours: a child who plays at 8pm
  /// and again at 8am the next morning has played on two consecutive days,
  /// even though only 12 hours passed.
  static int computeDailyStreak(String? lastPlayedIso, int storedStreak) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastPlayedIso == null || lastPlayedIso.isEmpty) return 1;

    final last = DateTime.tryParse(lastPlayedIso);
    if (last == null) return 1;

    final lastDay = DateTime(last.year, last.month, last.day);
    final daysApart = today.difference(lastDay).inDays;

    if (daysApart <= 0) {
      // Already played today — the streak stands, and is at least 1.
      return storedStreak < 1 ? 1 : storedStreak;
    }
    if (daysApart == 1) {
      // Played yesterday: the run continues.
      return (storedStreak < 1 ? 0 : storedStreak) + 1;
    }
    // Missed at least one whole day, so the run restarts at today.
    return 1;
  }

  // MATEMATIKA PROGRESS
  /// Records a play session and returns the child's real day streak.
  ///
  /// The streak is derived here from the stored last-played date rather than
  /// supplied by the caller, so it cannot be set to an arbitrary value.
  Future<int> updateMatematikaProgress() async {
    await _ensureInitialized();

    final streak = computeDailyStreak(
      _progressBox.get('matematika_last_played') as String?,
      _progressBox.get('matematika_streak') as int? ?? 0,
    );

    await _progressBox.put('matematika_streak', streak);
    await _progressBox.put(
        'matematika_last_played', DateTime.now().toIso8601String());

    if (_prefs != null) {
      await _prefs!.setInt('matematika_streak', streak);
    }

    await _syncToFirebase();
    notifyListeners();
    return streak;
  }

  /// The rating this Matematika level is currently worth, 0 if the child has
  /// not finished it yet. A replay replaces this rather than adding to it.
  int matematikaLevelStars(int level) =>
      _progressBox.get('mat_level_${level}_stars') as int? ?? 0;

  /// Gives finished Matematika levels back a rating when they have none.
  ///
  /// The per-level ratings were never in the cloud backup — only the module's
  /// running total and which levels were finished. A device restored from
  /// that showed every level ticked but starless, and "0/21" over a module
  /// the child had finished. The exact ratings are gone, so the total they
  /// added up to is shared back out over the finished levels that lack one:
  /// evenly, three at most each, never touching a level that still has its
  /// own rating. The star total itself does not change.
  Future<void> _repairMatematikaLevelStars() async {
    await _repairMatematikaLevelScores();
    final unrated = <int>[];
    int known = 0;
    for (int lvl = 0; lvl < matematikaLevelCount; lvl++) {
      final s = matematikaLevelStars(lvl);
      if (s > 0) {
        known += s;
      } else if (isMatematikaLevelCompleted(lvl)) {
        unrated.add(lvl);
      }
    }
    if (unrated.isEmpty) return;

    int total = _progressBox.get('matematika_stars') as int? ?? 0;
    for (final key in ['mat_total_stars', 'matematika_stars']) {
      final v = _prefs?.getInt(key) ?? 0;
      if (v > total) total = v;
    }
    int left = (total - known).clamp(0, unrated.length * 3);
    if (left == 0) return;

    final base = left ~/ unrated.length;
    int extra = left % unrated.length;
    for (final lvl in unrated) {
      final stars = (base + (extra-- > 0 ? 1 : 0)).clamp(0, 3);
      if (stars == 0) continue;
      final key = 'mat_level_${lvl}_stars';
      await _progressBox.put(key, stars);
      await _prefs?.setInt(key, stars);
    }
    debugPrint('Matematika: restored ratings for ${unrated.length} '
        'finished level(s) from the backed-up total of $total');
  }

  /// The same repair for each level's points, which were lost the same way:
  /// the module's points total (`matematika_total`, the sum of every level's
  /// score) was backed up, the per-level scores were not.
  ///
  /// Shared out by each level's length and never above a clean run (10 per
  /// question): a first version split the total evenly, which handed a
  /// three-question level 55 points — more than it can pay — because the
  /// backed-up total had itself been inflated by replays stacking in older
  /// builds. Runs once per account ([_scoreRepairKey], which travels in the
  /// backup), and rewrites only levels with no score or an impossible one.
  static const String _scoreRepairKey = 'mat_level_score_repair';
  static const int _scoreRepairVersion = 2;

  Future<void> _repairMatematikaLevelScores() async {
    if ((_prefs?.getInt(_scoreRepairKey) ?? 0) >= _scoreRepairVersion) return;

    const perLevel = matematikaGamesPerLevel;
    int cleanRun(int lvl) => perLevel[lvl] * 10;

    final redo = <int>[];
    int known = 0;
    for (int lvl = 0; lvl < matematikaLevelCount; lvl++) {
      final s = matematikaLevelScore(lvl);
      if (!isMatematikaLevelCompleted(lvl)) {
        known += s;
      } else if (s <= 0 || s > cleanRun(lvl)) {
        redo.add(lvl);
      } else {
        known += s;
      }
    }

    if (redo.isNotEmpty) {
      int total = _progressBox.get('matematika_total') as int? ?? 0;
      final fromPrefs = _prefs?.getInt('matematika_total') ?? 0;
      if (fromPrefs > total) total = fromPrefs;
      if (total == 0) total = _prefs?.getInt('mat_total_score') ?? 0;
      int left = total - known;
      final questions = redo.fold<int>(0, (a, l) => a + perLevel[l]);

      final fixed = <String, int>{};
      for (final lvl in redo) {
        int score = 0;
        if (left > 0 && questions > 0) {
          final share = (total - known) * perLevel[lvl] / questions;
          score = (share / 5).round() * 5;
          if (score > cleanRun(lvl)) score = cleanRun(lvl);
          if (score > left) score = left - left % 5;
          if (score < 0) score = 0;
        }
        left -= score;
        final key = 'mat_level_${lvl}_score';
        await _progressBox.put(key, score);
        await _prefs?.setInt(key, score);
        fixed['rawProgress.$key'] = score;
      }

      // The backup merges by taking the larger number, so an impossible score
      // already uploaded would win back over the corrected one on the next
      // pull. Overwritten in the cloud directly.
      final studentId = _currentStudentId;
      if (studentId != null && fixed.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .update(fixed)
            .catchError((e) {
          debugPrint('Matematika score repair: cloud write failed: $e');
        });
      }
    }
    await _prefs?.setInt(_scoreRepairKey, _scoreRepairVersion);
  }

  /// Records the result of finishing a Matematika level and awards [stars] —
  /// the same 1-to-3 rating shown on the level-complete screen.
  ///
  /// That rating is the child's star: it is what lands on the dashboard, in
  /// the module header and in the parents' report, so all three always agree.
  /// Every finished run counts, including replays, because repeating a level
  /// is exactly what a young child should be doing.
  Future<void> awardMatematikaLevelCompletion(
      int level, int stars, int score) async {
    await _ensureInitialized();
    // Padded, not just defaulted. A phone that was last opened when there
    // were seven levels has a seven-long list in it, and the guard below
    // would have refused to record levels eight to ten — silently, for the
    // life of that install.
    final completedLevels = _matematikaLevelFlags();

    if (level >= completedLevels.length) return;

    final starsKey = 'mat_level_${level}_stars';
    final scoreKey = 'mat_level_${level}_score';

    completedLevels[level] = true;
    await _progressBox.put('matematika_levels', completedLevels);

    // A level is worth one rating: the one from the run the child just
    // finished. Replaying it hands back what it was worth before and records
    // the new result in its place, so the total is always the sum of what
    // each level is currently worth — it cannot be inflated by replaying an
    // easy level over and over.
    final previousStars = _progressBox.get(starsKey) as int? ?? 0;
    final previousScore = _progressBox.get(scoreKey) as int? ?? 0;
    final starDelta = stars - previousStars;
    final scoreDelta = score - previousScore;
    await _progressBox.put(starsKey, stars);
    await _progressBox.put(scoreKey, score);

    int currentStars = _progressBox.get('matematika_stars') ?? 0;
    await _progressBox.put('matematika_stars', currentStars + starDelta);

    int currentScore = _progressBox.get('matematika_total') ?? 0;
    await _progressBox.put('matematika_total', currentScore + scoreDelta);

    if (_prefs != null) {
      await _prefs!.setInt('matematika_total', currentScore + scoreDelta);
      await _prefs!.setInt('matematika_stars', currentStars + starDelta);
      await _prefs!.setBool('mat_level_complete_$level', true);
      // The per-level rating lived in Hive alone, and the cloud backup only
      // copies `mat_` keys from SharedPreferences — so on any other device
      // every level read as unrated and the Home card showed no stars for a
      // finished module. Mirrored here so it travels in `rawProgress`.
      await _prefs!.setInt(starsKey, stars);
      await _prefs!.setInt(scoreKey, score);
      // The parents report reads this key directly, so it has to track the
      // same star total as everything else.
      await _prefs!.setInt('mat_total_stars', currentStars + starDelta);
      // Also bank the running points total the module screen restores from,
      // which previously drifted from the figures above.
      final prevTotalScore = _prefs!.getInt('mat_total_score') ?? 0;
      await _prefs!.setInt('mat_total_score', prevTotalScore + scoreDelta);
    }

    // AWARD TO MAIN USER PROFILE — the star shown on the level-complete
    // screen is the star the child actually receives, and a replay swaps it
    // for the new one rather than stacking on top.
    await adjustStars(starDelta);
    await checkAndAwardBadges();
    await checkAndAwardCertificates();

    await _syncToFirebase();
    notifyListeners();
  }

  Future<void> updateMatematikaGameProgress(
      int level, int gameIndex, bool completed) async {
    await _ensureInitialized();
    Map<String, dynamic> games =
        Map<String, dynamic>.from(_progressBox.get('matematika_games') ?? {});

    final gameKey = 'level${level}_game$gameIndex';
    bool isNewGameCompletion = games[gameKey] != true && completed == true;

    games[gameKey] = completed;
    await _progressBox.put('matematika_games', games);

    // If new game completion, we could award stars here if needed,
    // but usually Matematika awards per level in updateMatematikaProgress.
    // Ensure consistency:
    if (isNewGameCompletion) {
      // Logic to ensure level is marked as started/touched
    }

    // Update SharedPreferences
    if (_prefs != null) {
      await _prefs!.setBool('matematika_game_${level}_$gameIndex', completed);
      await _prefs!.setBool('mat_level_${level}_game_$gameIndex',
          completed); // Legacy key for consistency
    }

    await _syncToFirebase();
    await checkAndAwardBadges();
    await checkAndAwardCertificates();
    notifyListeners();
  }

  Map<String, dynamic> getMatematikaProgress() {
    if (!_isInitialized) {
      return {
        'completedLevels': 0,
        'totalLevels': matematikaLevelCount,
        'totalStars': 0,
        'earnedStars': 0,
        'possibleStars': matematikaStarCeiling,
        'totalScore': 0,
        'streak': 0,
        'gamesCompleted': 0,
        'totalGames': matematikaGameCount,
        'levelGamesDone': const <String, List<int>>{},
      };
    }
    int totalStars = _progressBox.get('matematika_stars') ?? 0;
    int totalScore = _progressBox.get('matematika_total') ?? 0;

    // Fallback to old Prefs keys if Hive is empty (for migration/resilience)
    if (totalStars == 0 && _prefs != null) {
      totalStars = _prefs!.getInt('mat_total_stars') ?? 0;
    }
    if (totalScore == 0 && _prefs != null) {
      totalScore = _prefs!.getInt('mat_total_score') ?? 0;
    }

    int streak = _progressBox.get('matematika_streak') ?? 0;
    if (streak == 0 && _prefs != null) {
      streak = _prefs!.getInt('mat_streak') ?? 0;
    }

    int completedCount = 0;
    int gamesCompleted = 0;

    // Which games, not only how many — same reason [getTraceItProgress]
    // keeps the actual done letters rather than a count. A teacher opening
    // a student's report from the dashboard reads this off the record in
    // Firestore, not off whatever happens to be in SharedPreferences on the
    // teacher's own phone; a plain count here would leave nothing for that
    // report's level-by-level view to draw.
    //
    // Keyed by level index as a string, the same shape [getKulayProgress]'s
    // pageDone already uses — not a List<List<int>>. Firestore rejects a
    // value whose own elements are arrays ("nested arrays"), and a level's
    // list of done games is exactly that shape if it sits directly inside
    // the outer list; wrapped in a map instead, each entry is a plain array
    // again, which Firestore has always supported.
    const counts = matematikaGamesPerLevel;
    final levelGamesDone = <String, List<int>>{
      for (int lvl = 0; lvl < counts.length; lvl++) '$lvl': <int>[],
    };

    if (_prefs != null) {
      for (int lvl = 0; lvl < counts.length; lvl++) {
        bool levelComplete = true;
        for (int g = 0; g < counts[lvl]; g++) {
          if (_prefs!.getBool('mat_level_${lvl}_game_$g') == true) {
            gamesCompleted++;
            levelGamesDone['$lvl']!.add(g);
          } else {
            levelComplete = false;
          }
        }
        if (levelComplete) completedCount++;
      }
    }

    // Summed from the per-level ratings rather than read off the running
    // total, because the ratings are what the child sees on every level tab.
    // A badge that disagreed with the tabs would be unexplainable.
    int earnedStars = 0;
    for (int lvl = 0; lvl < matematikaLevelCount; lvl++) {
      earnedStars += (_progressBox.get('mat_level_${lvl}_stars') as int? ?? 0);
    }
    // A device restored from the cloud before the per-level ratings were
    // backed up has none of them, only the running total. Better that total
    // than a finished module showing no stars at all.
    if (earnedStars == 0 && totalStars > 0) {
      earnedStars = totalStars.clamp(0, matematikaStarCeiling);
    }

    return {
      'completedLevels': completedCount,
      'totalLevels': matematikaLevelCount,
      'totalStars': totalStars,
      'earnedStars': earnedStars,
      'possibleStars': matematikaStarCeiling,
      'totalScore': totalScore,
      'streak': streak,
      'gamesCompleted': gamesCompleted,
      'totalGames': matematikaGameCount,
      'levelGamesDone': levelGamesDone,
    };
  }

  // PAMILYA (ANG AKING SARILI / PAMILYA) PROGRESS
  Future<void> updatePamilyaProgress(
      int categoryIndex, int level, int gameIndex, bool completed,
      {int earnedStars = 0}) async {
    await _ensureInitialized();
    if (!_isInitialized) return;

    final gameKey =
        'pamilya_cat_${categoryIndex}_level_${level}_game_$gameIndex';

    // Update Hive
    Map<String, dynamic> games =
        Map<String, dynamic>.from(_progressBox.get('pamilya_games') ?? {});

    // Check if this specific game was already completed
    bool isNewGameCompletion = (games[gameKey] != true) && completed == true;

    games[gameKey] = completed;
    await _progressBox.put('pamilya_games', games);

    // Update SharedPreferences for dashboard consistency.
    //
    // Only the question is recorded here. This used to also write
    // `levelKey = true` on *every* answer, which marked the whole level
    // finished the moment a child answered its first question — so leaving
    // and coming back showed a level they had barely started as complete.
    // A level is finished in [awardPamilyaLevelCompletion], and nowhere else.
    if (_prefs != null) {
      await _prefs!.setBool(gameKey, completed);
    }

    // Points accrue per question; the star is awarded once for the whole
    // level in [awardPamilyaLevelCompletion], at the rating the child sees on
    // the completion screen.
    if (isNewGameCompletion) {
      int currentScore = _progressBox.get('pamilya_total') ?? 0;
      await _progressBox.put('pamilya_total', currentScore + 10);
      if (_prefs != null) {
        await _prefs!.setInt('pamilya_total', currentScore + 10);
      }
    }

    // Update streak regardless of new completion (just playing counts)
    int streak = _progressBox.get('pamilya_streak') ?? 0;
    await _progressBox.put('pamilya_streak', streak + 1);
    await _progressBox.put(
        'pamilya_last_played', DateTime.now().toIso8601String());

    if (_prefs != null) {
      await _prefs!.setInt('pamilya_streak', streak + 1);
    }

    await _syncToFirebase();
    await checkAndAwardBadges();
    await checkAndAwardCertificates();
    notifyListeners();
  }

  /// Records a finished "Ang Aking Sarili" level and awards [stars] — the same
  /// 1-to-3 rating shown on the level-complete screen, which is the child's
  /// star. Every finished run counts, replays included.
  /// The rating this level is currently worth, or 0 if never finished.
  int pamilyaLevelStars(int categoryIndex, int level) {
    final globalIdx = categoryIndex == 0 ? level : 4 + level;
    return (_progressBox.get('pamilya_level_${globalIdx}_stars') as int? ?? 0);
  }

  /// The points banked on this Matematika level's most recent run.
  int matematikaLevelScore(int level) =>
      (_progressBox.get('mat_level_${level}_score') as int? ?? 0);

  Future<void> awardPamilyaLevelCompletion(
      int categoryIndex, int level, int stars) async {
    await _ensureInitialized();
    if (!_isInitialized) return;

    final globalIdx = categoryIndex == 0 ? level : 4 + level;
    List<dynamic> completedLevels =
        List.from(_progressBox.get('pamilya_levels') ?? List.filled(9, false));
    if (globalIdx >= completedLevels.length) return;

    completedLevels[globalIdx] = true;
    await _progressBox.put('pamilya_levels', completedLevels);

    // Same rule as Matematika: one rating per level, replaced on a replay
    // rather than added to. Pamilya kept no per-level record at all before,
    // so every replay stacked another one to three stars onto the total.
    final starsKey = 'pamilya_level_${globalIdx}_stars';
    final previousStars = _progressBox.get(starsKey) as int? ?? 0;
    final starDelta = stars - previousStars;
    await _progressBox.put(starsKey, stars);

    final currentStars = _progressBox.get('pamilya_stars') as int? ?? 0;
    await _progressBox.put('pamilya_stars', currentStars + starDelta);

    if (_prefs != null) {
      await _prefs!.setBool('pamilya_level_$globalIdx', true);
      await _prefs!.setBool('pamilya_cat_${categoryIndex}_level_$level', true);
      await _prefs!.setInt('pamilya_stars', currentStars + starDelta);
      await _prefs!.setInt(starsKey, stars);
    }

    await adjustStars(starDelta);

    await _syncToFirebase();
    await checkAndAwardBadges();
    await checkAndAwardCertificates();
    notifyListeners();
  }

  Map<String, dynamic> getPamilyaProgress() {
    if (!_isInitialized) {
      return {
        'completedLevels': 0,
        'threeStarLevels': 0,
        'totalLevels': 5,
        'totalStars': 0,
        'earnedStars': 0,
        'possibleStars': sariliStarCeiling + familyStarCeiling,
        'sariliStars': 0,
        'sariliPossibleStars': sariliStarCeiling,
        'familyStars': 0,
        'familyPossibleStars': familyStarCeiling,
        'totalScore': 0,
        'streak': 0,
        'gamesCompleted': 0,
        'totalGames': 25,
        'levelDetails': [false, false, false, false, false],
        'gameDetails': {},
      };
    }
    List<dynamic> completedLevels =
        _progressBox.get('pamilya_levels') ?? List.filled(9, false);
    int totalStars = _progressBox.get('pamilya_stars') ?? 0;
    int totalScore = _progressBox.get('pamilya_total') ?? 0;

    // Fallback to old Prefs keys
    if (totalStars == 0 && _prefs != null) {
      totalStars = _prefs!.getInt('pamilya_total_stars') ?? 0;
    }
    if (totalScore == 0 && _prefs != null) {
      totalScore = _prefs!.getInt('pamilya_total_score') ?? 0;
    }

    int streak = _progressBox.get('pamilya_streak') ?? 0;
    if (streak == 0 && _prefs != null) {
      streak = _prefs!.getInt('pamilya_streak') ?? 0;
    }
    Map<String, dynamic> games =
        Map<String, dynamic>.from(_progressBox.get('pamilya_games') ?? {});

    int completedCount = 0;
    for (var completed in completedLevels) {
      if (completed == true) completedCount++;
    }

    int gamesCompleted = games.values.where((v) => v == true).length;

    // Levels cleared at the top rating. The family badge is earned on this,
    // not on how many levels were walked through, so a badge means the child
    // did well rather than merely turned up.
    // Split by half, because the two badges cover different halves: levels
    // 0-3 are "Ang Aking Sarili", levels 4-8 are "Ken Ti Pamiliak".
    int threeStarLevels = 0;
    int sariliStars = 0;
    int familyStars = 0;
    for (int i = 0; i < 9; i++) {
      final levelStars =
          (_progressBox.get('pamilya_level_${i}_stars') as int? ?? 0);
      if (levelStars >= 3) threeStarLevels++;
      if (i < 4) {
        sariliStars += levelStars;
      } else {
        familyStars += levelStars;
      }
    }

    return {
      // Level by level, so the parents' report can show which part of the
      // module a number came from instead of only the total.
      'levelStars': [
        for (int i = 0; i < 9; i++)
          (_progressBox.get('pamilya_level_${i}_stars') as int? ?? 0)
      ],
      'completedLevels': completedCount,
      'threeStarLevels': threeStarLevels,
      'totalLevels': 5,
      'totalStars': totalStars,
      'earnedStars': sariliStars + familyStars,
      'possibleStars': sariliStarCeiling + familyStarCeiling,
      'sariliStars': sariliStars,
      'sariliPossibleStars': sariliStarCeiling,
      'familyStars': familyStars,
      'familyPossibleStars': familyStarCeiling,
      'totalScore': totalScore,
      'streak': streak,
      'gamesCompleted': gamesCompleted,
      'totalGames': 25,
      'levelDetails': completedLevels,
      'gameDetails': games,
    };
  }

  // MAGBASA TAYO PROGRESS
  Future<void> updateMagbasaProgress(
      String category, int activityIndex, bool completed) async {
    await _ensureInitialized();
    if (!_isInitialized) return;

    final key = 'magbasa_${category}_$activityIndex';

    // Check if it was already completed to prevent double-rewarding
    bool wasAlreadyCompleted = _progressBox.get(key) == true;
    if (!wasAlreadyCompleted && _prefs != null) {
      wasAlreadyCompleted =
          _prefs!.getBool('${category}_activity_$activityIndex') == true;
    }

    await _progressBox.put(key, completed);

    Map<String, dynamic> categoryData =
        Map<String, dynamic>.from(_progressBox.get('magbasa_$category') ?? {});
    categoryData['$activityIndex'] = completed;
    await _progressBox.put('magbasa_$category', categoryData);

    // Update SharedPreferences
    if (_prefs != null) {
      await _prefs!.setBool('${category}_activity_$activityIndex', completed);
    }

    if (!wasAlreadyCompleted && completed) {
      // One finished thing, one star. There is no right or wrong answer
      // here, so there is nothing for a 1-to-3 rating to measure — and paying
      // the top rating for it outweighed every module that does grade.
      await addStars(1);
    }

    await _updateMagbasaTotalProgress();
    await _syncToFirebase();
    await checkAndAwardBadges();
    await checkAndAwardCertificates();
    notifyListeners();
  }

  Future<void> _updateMagbasaTotalProgress() async {
    await _ensureInitialized();
    if (!_isInitialized) return;
    int totalCompleted = 0;
    final categories = ['tula', 'kwento', 'kanta'];

    for (var category in categories) {
      Map<String, dynamic> categoryData = Map<String, dynamic>.from(
          _progressBox.get('magbasa_$category') ?? {});
      totalCompleted += categoryData.values.where((v) => v == true).length;
    }

    await _progressBox.put('magbasa_total', totalCompleted);
  }

  Map<String, dynamic> getMagbasaProgress() {
    // Each nested map is explicitly <String, dynamic> — left to infer from
    // an all-int literal like {'completed': 0, 'total': 5}, Dart locks it in
    // as Map<String, int>, and the 'done' list assigned below then throws
    // ("List<int> is not a subtype of int") on every single home-screen
    // load, not just a teacher's.
    Map<String, dynamic> progress = {
      'tula': <String, dynamic>{'completed': 0, 'total': 5},
      'kwento': <String, dynamic>{'completed': 0, 'total': 5},
      'kanta': <String, dynamic>{'completed': 0, 'total': 9},
      'totalCompleted': 0,
      'totalActivities': 19,
    };

    // Which poems/stories/songs, not only how many — same reasoning as
    // [getTraceItProgress]'s per-letter lists: a teacher opening a
    // student's report from the dashboard has no local SharedPreferences
    // of that student's own to read this off of.
    final tulaDone = <int>[];
    final kwentoDone = <int>[];
    final kantaDone = <int>[];

    if (_prefs != null) {
      for (int i = 0; i < 5; i++) {
        if (_prefs!.getBool('tula_activity_$i') == true) {
          progress['tula']['completed'] =
              (progress['tula']['completed'] as int) + 1;
          tulaDone.add(i);
        }
      }
      for (int i = 0; i < 5; i++) {
        if (_prefs!.getBool('kwento_activity_$i') == true) {
          progress['kwento']['completed'] =
              (progress['kwento']['completed'] as int) + 1;
          kwentoDone.add(i);
        }
      }
      for (int i = 0; i < 9; i++) {
        if (_prefs!.getBool('kanta_activity_$i') == true) {
          progress['kanta']['completed'] =
              (progress['kanta']['completed'] as int) + 1;
          kantaDone.add(i);
        }
      }
    }
    progress['tula']['done'] = tulaDone;
    progress['kwento']['done'] = kwentoDone;
    progress['kanta']['done'] = kantaDone;

    progress['totalCompleted'] = (progress['tula']['completed'] as int) +
        (progress['kwento']['completed'] as int) +
        (progress['kanta']['completed'] as int);

    // One finished activity, one star.
    for (final group in ['tula', 'kwento', 'kanta']) {
      final g = progress[group] as Map<String, dynamic>;
      g['stars'] = g['completed'] as int;
      g['possibleStars'] = g['total'] as int;
    }
    progress['stars'] = progress['totalCompleted'] as int;
    progress['possibleStars'] = magbasaStarCeiling;

    return progress;
  }

  // KULAY-SAYA PROGRESS
  Future<void> updateKulayProgress(String activity, bool completed,
      {String? category, int? index}) async {
    await _ensureInitialized();
    if (!_isInitialized) return;

    if (category != null && index != null) {
      final key = 'kulay_page_${category}_$index';
      await _progressBox.put(key, completed);
      // Update SharedPrefs for dashboard consistency
      if (_prefs != null) {
        await _prefs!.setBool(key, completed);
      }
    } else {
      await _progressBox.put('kulay_$activity', completed);
      // Also update prefs if it's one of the base activities
      if (_prefs != null) {
        await _prefs!.setBool('kulay_$activity', completed);
      }
    }

    await _updateKulayTotalProgress();
    await _syncToFirebase();
    await checkAndAwardBadges();
    await checkAndAwardCertificates();
    notifyListeners();
  }

  Future<void> _updateKulayTotalProgress() async {
    if (!_isInitialized) return;
    int totalCompleted = 0;

    // Page completions
    final totals = {'Animals': 3, 'Flowers': 2, 'Fruits': 2, 'Toys': 2};
    for (var cat in totals.keys) {
      for (int i = 0; i < totals[cat]!; i++) {
        if (_progressBox.get('kulay_page_${cat}_$i') == true ||
            (_prefs?.getBool('kulay_page_${cat}_$i') == true)) {
          totalCompleted++;
        }
      }
    }

    int currentScore = _progressBox.get('kulay_total') ?? 0;
    await _progressBox.put('kulay_total', totalCompleted);

    // One finished picture, one star — see the magbasa award for why this
    // is not three.
    if (totalCompleted > currentScore) {
      await addStars(1);
    }
  }

  Map<String, dynamic> getKulayProgress() {
    int totalCompleted = 0;

    // Page completions (check both for resilience)
    final totals = {'Animals': 3, 'Flowers': 2, 'Fruits': 2, 'Toys': 2};
    // Which pages, not only how many — same reasoning as
    // [getTraceItProgress]'s per-letter lists and Matematika's
    // 'levelGamesDone': a teacher opening a student's report from the
    // dashboard has no local SharedPreferences of that student's own.
    final pageDone = <String, List<int>>{};
    for (var cat in totals.keys) {
      final doneForCat = <int>[];
      for (int i = 0; i < totals[cat]!; i++) {
        final key = 'kulay_page_${cat}_$i';
        bool done = false;
        if (_isInitialized) {
          done = _progressBox.get(key) ?? false;
        }
        if (!done && _prefs != null) {
          done = _prefs!.getBool(key) ?? false;
        }

        if (done) {
          totalCompleted++;
          doneForCat.add(i);
        }
      }
      pageDone[cat] = doneForCat;
    }

    return {
      'totalCompleted': totalCompleted,
      'totalActivities': kulayStarCeiling, // 9 pages
      // Travels with the record so a report opened for another child shows
      // their drawings and not this device's.
      'totalCreations': _prefs?.getInt('kulay_total_creations') ?? 0,
      // Colouring has no wrong answer, so each finished page is worth 3.
      'stars': totalCompleted,
      'possibleStars': kulayStarCeiling,
      'pageDone': pageDone,
    };
  }

  // TRACE IT PROGRESS
  /// Records a traced letter and awards [stars] — the 1-to-3 rating from the
  /// letter's own accuracy check, not a flat amount, so a careful trace is
  /// worth more than a rushed one.
  Future<void> updateTraceItProgress(String mode, int index, bool completed,
      {int stars = 0}) async {
    await _ensureInitialized();
    if (!_isInitialized) return;
    final key = 'traceit_${mode}_$index';

    bool wasAlreadyCompleted = _progressBox.get(key) == true;

    await _progressBox.put(key, completed);

    List<dynamic> modeList = _progressBox.get('traceit_$mode') ??
        List.filled(mode == 'numbers' ? 10 : 26, false);
    if (index < modeList.length) {
      modeList[index] = completed;
      await _progressBox.put('traceit_$mode', modeList);
    }

    if (_prefs != null) {
      String prefKey = '';
      if (mode == 'uppercase') {
        const allUpper = [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z'
        ];
        if (index < allUpper.length) {
          prefKey = 'traceit_upper_${allUpper[index]}';
        }
      } else if (mode == 'lowercase') {
        const allLower = [
          'a',
          'b',
          'c',
          'd',
          'e',
          'f',
          'g',
          'h',
          'i',
          'j',
          'k',
          'l',
          'm',
          'n',
          'o',
          'p',
          'q',
          'r',
          's',
          't',
          'u',
          'v',
          'w',
          'x',
          'y',
          'z'
        ];
        if (index < allLower.length) {
          prefKey = 'traceit_lower_${allLower[index]}';
        }
      } else if (mode == 'numbers') {
        const allNums = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
        if (index < allNums.length) {
          prefKey = 'traceit_num_${allNums[index]}';
        }
      }

      if (prefKey.isNotEmpty) {
        if (!wasAlreadyCompleted && _prefs!.getBool(prefKey) == true) {
          wasAlreadyCompleted = true;
        }
        await _prefs!.setBool(prefKey, completed);
      }
    }

    // A character is worth one star, once. Nothing consulted
    // `wasAlreadyCompleted` here, so tracing the same letter again minted
    // another star while the record — one flag per character — stayed where
    // it was. The total climbed past the 62 this module can hold, and the
    // next recount took every extra one back.
    if (completed && stars > 0 && !wasAlreadyCompleted) {
      await addStars(stars);
    }

    await _updateTraceItTotalProgress();
    await _syncToFirebase();
    await checkAndAwardBadges();
    await checkAndAwardCertificates();
    notifyListeners();
  }

  Future<void> _updateTraceItTotalProgress() async {
    if (!_isInitialized) return;
    List<dynamic> uppercase =
        _progressBox.get('traceit_uppercase') ?? List.filled(26, false);
    List<dynamic> lowercase =
        _progressBox.get('traceit_lowercase') ?? List.filled(26, false);
    List<dynamic> numbers =
        _progressBox.get('traceit_numbers') ?? List.filled(10, false);

    int uppercaseCompleted = uppercase.where((v) => v == true).length;
    int lowercaseCompleted = lowercase.where((v) => v == true).length;
    int numbersCompleted = numbers.where((v) => v == true).length;

    int overallTotal =
        uppercaseCompleted + lowercaseCompleted + numbersCompleted;
    await _progressBox.put('traceit_total', overallTotal);
  }

  bool isTraceItActivityCompleted(String mode, int index) {
    if (!_isInitialized) return false;

    if (_prefs != null) {
      String prefKey = '';
      if (mode == 'uppercase') {
        const allUpper = [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z'
        ];
        if (index >= 0 && index < allUpper.length) {
          prefKey = 'traceit_upper_${allUpper[index]}';
        }
      } else if (mode == 'lowercase') {
        const allLower = [
          'a',
          'b',
          'c',
          'd',
          'e',
          'f',
          'g',
          'h',
          'i',
          'j',
          'k',
          'l',
          'm',
          'n',
          'o',
          'p',
          'q',
          'r',
          's',
          't',
          'u',
          'v',
          'w',
          'x',
          'y',
          'z'
        ];
        if (index >= 0 && index < allLower.length) {
          prefKey = 'traceit_lower_${allLower[index]}';
        }
      } else if (mode == 'numbers') {
        const allNums = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
        if (index >= 0 && index < allNums.length) {
          prefKey = 'traceit_num_${allNums[index]}';
        }
      }
      if (prefKey.isNotEmpty && _prefs!.getBool(prefKey) == true) return true;
    }

    return _progressBox.get('traceit_${mode}_$index') ?? false;
  }

  Map<String, dynamic> getTraceItProgress() {
    int uppercaseCompleted = 0;
    int lowercaseCompleted = 0;
    int numbersCompleted = 0;

    // Which characters, not only how many. The counts synced and the letters
    // stayed on the phone, so a report opened for any child but the one
    // signed in here had nothing to draw.
    final upperDone = <String>[];
    final lowerDone = <String>[];
    final numsDone = <String>[];

    if (_prefs != null) {
      const allUpper = [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z'
      ];
      const allLower = [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z'
      ];
      const allNums = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

      for (var l in allUpper) {
        if (_prefs!.getBool('traceit_upper_$l') == true) {
          uppercaseCompleted++;
          upperDone.add(l);
        }
      }
      for (var l in allLower) {
        if (_prefs!.getBool('traceit_lower_$l') == true) {
          lowercaseCompleted++;
          lowerDone.add(l);
        }
      }
      for (var n in allNums) {
        if (_prefs!.getBool('traceit_num_$n') == true) {
          numbersCompleted++;
          numsDone.add(n);
        }
      }
    }

    int totalCompleted =
        uppercaseCompleted + lowercaseCompleted + numbersCompleted;

    // One star per character traced, so here the star count and the
    // completed count are the same number.
    return {
      'uppercase': {
        'completed': uppercaseCompleted,
        'total': 26,
        'stars': uppercaseCompleted,
        'possibleStars': 26,
        'done': upperDone,
      },
      'lowercase': {
        'completed': lowercaseCompleted,
        'total': 26,
        'stars': lowercaseCompleted,
        'possibleStars': 26,
        'done': lowerDone,
      },
      'numbers': {
        'completed': numbersCompleted,
        'total': 10,
        'stars': numbersCompleted,
        'possibleStars': 10,
        'done': numsDone,
      },
      'totalCompleted': totalCompleted,
      'totalActivities': 62,
      'stars': totalCompleted,
      'possibleStars': traceitStarCeiling,
    };
  }

  // TANDAAN (MEMORY) PROGRESS
  //
  // Tandaan keeps its ratings in SharedPreferences rather than Hive, written
  // by the screen itself. Reading them here lets the dashboard card count
  // the same stars as every other module instead of showing nothing.
  Map<String, dynamic> getTandaanProgress() {
    int stars = 0;
    // Rounds played to the end, which is not the same as stars: a round can be
    // finished on a second try and score nothing. The Lessons screen's "Tapos
    // na!" counts these, so the certificate — which asks for every lesson
    // finished, not every star won — has to count them too.
    int rounds = 0;
    if (_prefs != null) {
      for (int cat = 0; cat < 4; cat++) {
        stars += _prefs!.getInt('tandaan_cat_${cat}_stars') ?? 0;
        for (int round = 0; round < 3; round++) {
          if (_prefs!.getBool('tandaan_cat_${cat}_round_$round') == true) {
            rounds++;
          }
        }
      }
    }
    return {
      'stars': stars,
      'possibleStars': tandaanStarCeiling,
      'roundsCompleted': rounds,
      'totalRounds': tandaanRoundCount,
      'categoryStars': [
        for (int cat = 0; cat < 4; cat++)
          (_prefs?.getInt('tandaan_cat_${cat}_stars') ?? 0)
      ],
    };
  }

  /// The six modules on the Lessons screen, and whether each is finished.
  ///
  /// Finished means every activity in it has been played to the end — the same
  /// bar the Lessons screen prints "Tapos na!" against — not that every star
  /// was won. A child who scrapes through all sixty-two letters has finished
  /// Trace It; the stars are a separate reward and the badges already track
  /// them.
  Map<String, bool> get moduleCompletion {
    final p = getAllProgress();
    int i(Map? m, String k) => (m?[k] as int?) ?? 0;

    final magbasa = p['magbasa'] as Map?;
    final kulay = p['kulay'] as Map?;
    final traceit = p['traceit'] as Map?;
    final matematika = p['matematika'] as Map?;
    final pamilya = p['pamilya'] as Map?;
    final tandaan = p['tandaan'] as Map?;

    bool done(int current, int total) => total > 0 && current >= total;

    return {
      'matematika':
          done(i(matematika, 'gamesCompleted'), i(matematika, 'totalGames')),
      // Pamilya is counted in levels here because that is what its own card on
      // the Lessons screen fills its bar with.
      'pamilya': done(i(pamilya, 'completedLevels'), i(pamilya, 'totalLevels')),
      'kulay': done(i(kulay, 'totalCompleted'), i(kulay, 'totalActivities')),
      'traceit':
          done(i(traceit, 'totalCompleted'), i(traceit, 'totalActivities')),
      'magbasa':
          done(i(magbasa, 'totalCompleted'), i(magbasa, 'totalActivities')),
      'tandaan': done(i(tandaan, 'roundsCompleted'), i(tandaan, 'totalRounds')),
    };
  }

  /// How many of the six modules are finished.
  int get modulesCompletedCount =>
      moduleCompletion.values.where((done) => done).length;

  /// How many modules there are, so a caller printing "4/6" need not hardcode.
  int get moduleCount => moduleCompletion.length;

  /// Every lesson finished — the second half of what the certificate asks for.
  bool get allModulesComplete => moduleCompletion.values.every((done) => done);

  /// The twelve badges the Certificate of Completion is awarded from.
  ///
  /// The thirteenth badge, the five-day streak, is deliberately not here: it
  /// rewards showing up rather than finishing anything, and a child who has
  /// done every lesson should not be held back by having missed a day.
  static const List<String> graduateBadgeIds = [
    'firstSteps',
    'alphabet',
    'numbers',
    'colors',
    'shapes',
    'animals',
    'bookworm',
    'starStudent',
    'mathWhiz',
    'familyHero',
    'writingStar',
    'songbird',
  ];

  /// How many of [graduateBadgeIds] the child has claimed, so the Awards
  /// screen can say how far off the certificate still is.
  int get graduateBadgesClaimed => graduateBadgeIds
      .where((id) => _userProfile?.claimedBadges.contains(id) ?? false)
      .length;

  // OVERALL PROGRESS
  Map<String, dynamic> getAllProgress() {
    if (!_isInitialized) {
      return {
        'magbasa': {
          'tula': {'completed': 0, 'total': 5},
          'kwento': {'completed': 0, 'total': 5},
          'kanta': {'completed': 0, 'total': 9},
          'totalCompleted': 0,
          'totalActivities': 19,
        },
        'kulay': {
          'basic': false,
          'mixing': false,
          'objects': false,
          'coloring': false,
          'totalCompleted': 0,
          'totalActivities': 9,
        },
        'traceit': {
          'uppercase': {'completed': 0, 'total': 26},
          'lowercase': {'completed': 0, 'total': 26},
          'numbers': {'completed': 0, 'total': 10},
          'totalCompleted': 0,
          'totalActivities': 62,
        },
        'matematika': {
          'completedLevels': 0,
          'totalLevels': matematikaLevelCount,
          'totalStars': 0,
          'totalScore': 0,
          'streak': 0,
          'gamesCompleted': 0,
          'totalGames': matematikaGameCount,
        },
        'pamilya': {
          'completedLevels': 0,
          'totalLevels': 5,
          'totalStars': 0,
          'totalScore': 0,
          'streak': 0,
          'gamesCompleted': 0,
          'totalGames': 25,
          'levelDetails': [false, false, false, false, false],
          'gameDetails': {},
        },
        'tandaan': {'stars': 0, 'possibleStars': tandaanStarCeiling},
        'totalCompleted': 0,
        'totalActivities': 150,
        'totalStars': 0,
        'totalPossibleStars': totalPossibleStars,
        'overallProgress': 0.0,
      };
    }

    final magbasa = getMagbasaProgress();
    final kulay = getKulayProgress();
    final traceit = getTraceItProgress();
    final matematika = getMatematikaProgress();
    final pamilya = getPamilyaProgress();
    final tandaan = getTandaanProgress();

    final totalCompleted = (magbasa['totalCompleted'] as int) +
        (kulay['totalCompleted'] as int) +
        (traceit['totalCompleted'] as int) +
        (matematika['gamesCompleted'] as int) +
        (pamilya['gamesCompleted'] as int);

    final totalActivities = (magbasa['totalActivities'] as int) +
        (kulay['totalActivities'] as int) +
        (traceit['totalActivities'] as int) +
        (matematika['totalGames'] as int) +
        (pamilya['totalGames'] as int);

    // How far along, in the app's one currency.
    //
    // This used to be finished activities over total activities, with Tandaan
    // Mo! missing from both halves — so a child who had finished it was told
    // they had not started, and the figure could never agree with the star
    // total printed beside it.
    final double starFraction = totalPossibleStars > 0
        ? (displayStars / totalPossibleStars).clamp(0.0, 1.0)
        : 0.0;
    final double percentage = starFraction * 100;

    return {
      'magbasa': magbasa,
      'kulay': kulay,
      'traceit': traceit,
      'matematika': matematika,
      'pamilya': pamilya,
      'tandaan': tandaan,
      'totalCompleted': totalCompleted,
      'totalActivities': totalActivities,
      // The dashboard's fraction and every badge's requirement read these,
      // so the number under the child's star and the number on a badge card
      // are the same currency.
      'totalStars': displayStars,
      'totalPossibleStars': totalPossibleStars,
      // Carried in the progress map so the parents' report, the teacher's
      // dashboard and a sibling's synced record all get them without a
      // second lookup.
      'lastPlayed': lastPlayedIso ?? '',
      'dayStreak': dayStreak,
      // What to sit down with this child about. Carried here so the teacher's
      // dashboard reads it from the record it already loads.
      'practiceMisses': practiceMisses,
      'percentage': percentage,
      'grade': _getGradeFromPercentage(percentage),
      'overallProgress': starFraction,
    };
  }

  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding';
    }
    if (percentage >= 80) {
      return 'Very Satisfactory';
    }
    if (percentage >= 75) {
      return 'Satisfactory';
    }
    if (percentage > 0) {
      return 'Developing';
    }
    return 'Not Started';
  }

  /// Sync this profile to Firestore

  /// Pushes this child's work to the cloud and says whether it landed.
  ///
  /// Called before handing the device to a sibling. Switching clears the local
  /// store, so a `false` here means there is unsent work that switching would
  /// destroy — and the caller must not switch.
  Future<bool> flushToCloud(
      {Duration timeout = const Duration(seconds: 8)}) async {
    await _ensureInitialized();
    // Nothing signed in, so nothing of theirs to lose.
    if (_currentStudentId == null || _userProfile == null) return true;

    // Never pulled from the cloud on this device, so the local store may be
    // empty rather than up to date. `_syncToFirebase` refuses to push in this
    // state for the same reason, and switching would be just as unsafe.
    if (!_hasSyncedFromCloud) return false;

    await _syncToFirebase();

    try {
      // One small write to the same document, awaited. Firestore delivers a
      // document's writes in order, so the server acknowledging this one
      // acknowledges everything queued in front of it.
      await FirebaseFirestore.instance
          .collection('students')
          .doc(_currentStudentId)
          .update({'lastActive': FieldValue.serverTimestamp()}).timeout(
              timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Combines a local value with the cloud's copy of the same raw-progress
  /// key so neither can erase the other: a finished flag beats an unfinished
  /// one, a higher running total beats a lower one, and a list or map (a
  /// level's list of finished games, say) merges the same way element by
  /// element. Anything that doesn't fit those shapes (a name, a timestamp)
  /// falls back to whichever side is non-null, preferring local.
  ///
  /// This is what keeps two devices signed into the same account — one of
  /// them possibly offline for a while — from stomping on each other's
  /// work: whichever syncs first, second, or after being offline, the
  /// finished work from both always survives.
  dynamic _mergeHiveValue(dynamic local, dynamic cloud) {
    if (local == null) return cloud;
    if (cloud == null) return local;
    if (local is bool && cloud is bool) return local || cloud;
    if (local is num && cloud is num) return local > cloud ? local : cloud;
    if (local is List && cloud is List) {
      final len = local.length > cloud.length ? local.length : cloud.length;
      return List.generate(
        len,
        (i) => _mergeHiveValue(
          i < local.length ? local[i] : null,
          i < cloud.length ? cloud[i] : null,
        ),
      );
    }
    if (local is Map && cloud is Map) {
      final merged = <String, dynamic>{};
      for (final k in {...local.keys, ...cloud.keys}) {
        merged[k.toString()] = _mergeHiveValue(local[k], cloud[k]);
      }
      return merged;
    }
    return local;
  }

  /// Merges every key under the cloud document's `rawProgress` into local
  /// storage — Hive for the compound per-module structures, SharedPreferences
  /// for the flat per-activity flags and running totals — using
  /// [_mergeHiveValue] so a completed activity or a higher total on either
  /// side always wins. Called both at login ([syncFromFirebase]) and before
  /// every push ([_syncToFirebase]), so two devices sharing an account stay
  /// merged for the whole session, not just at sign-in.
  Future<void> _mergeRawProgressFromCloud(Map<String, dynamic> data) async {
    if (data['rawProgress'] is! Map) return;
    final rawProgress = Map<String, dynamic>.from(data['rawProgress'] as Map);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;

    for (final entry in rawProgress.entries) {
      final key = entry.key;
      final cloudVal = entry.value;

      final mergedHive = _mergeHiveValue(_progressBox.get(key), cloudVal);
      await _progressBox.put(key, mergedHive);

      final merged = _mergeHiveValue(prefs.get(key), cloudVal);
      if (merged is bool) {
        await prefs.setBool(key, merged);
      } else if (merged is int) {
        await prefs.setInt(key, merged);
      } else if (merged is double) {
        await prefs.setDouble(key, merged);
      } else if (merged is String) {
        await prefs.setString(key, merged);
      }
      // A merged List or Map never came from SharedPreferences (it can't
      // store either) — that result only ever belongs in Hive, put above.
    }
  }

  Future<void> _syncToFirebase() async {
    await _ensureInitialized();
    if (_currentStudentId == null || _userProfile == null) return;

    // GUARD: If we have an ID but haven't synced from Cloud yet,
    // DO NOT push local empty state to prevent data wipe.
    if (!_hasSyncedFromCloud) {
      debugPrint('Sync deferred: Waiting for initial cloud pull...');
      return;
    }

    try {
      // Absorb whatever the cloud already has before pushing — a second
      // device on this same account may have synced since this device's
      // last pull. Cache-only, so it can never wait on the network the way
      // the push below deliberately never does either; a device that has
      // nothing cached yet (its very first sync) has nothing to merge, and
      // this is simply skipped.
      try {
        final cached = await FirebaseFirestore.instance
            .collection('students')
            .doc(_currentStudentId)
            .get(const GetOptions(source: Source.cache));
        final cachedData = cached.data();
        if (cachedData != null) {
          await _mergeRawProgressFromCloud(cachedData);
          _userProfile!.stars = recountStarsFromProgress();
          await _profileBox.put('currentUser', _userProfile!.toJson());
          notifyListeners();
        }
      } catch (e) {
        debugPrint('No cached cloud copy to merge: $e');
      }

      final progressData = getAllProgress();
      final profileData = _userProfile!.toJson();
      // Never push the plaintext LRN to the cloud — only the hashed
      // `lrnHash` (top-level) is stored there. The LRN is kept locally
      // (from what the student typed at login) for certificate display.
      profileData.remove('lrn');

      // Store raw keys from SharedPreferences too for full backup. Drawn
      // from moduleKeyPrefixes for the same reason _clearProgressPrefs is —
      // this list had also fallen out of sync with it (missing 'tandaan_'
      // and every Magbasa/Trace It sub-prefix), so a device's Tandaan and
      // Trace It/Magbasa sub-progress silently never made it into this
      // backup.
      final prefs = await SharedPreferences.getInstance();
      final backupPrefixes = [
        'mat_', // legacy Matematika prefix, kept for older installs
        ...moduleKeyPrefixes.values.expand((p) => p),
      ];
      final keys = prefs
          .getKeys()
          .where((k) => backupPrefixes.any((p) => k.startsWith(p)));

      final Map<String, dynamic> rawProgressData = {};
      for (var key in keys) {
        rawProgressData[key] = prefs.get(key);
      }

      // ALSO add Hive-only global keys that are NOT in SharedPreferences
      final hiveKeys = [
        'pamilya_levels',
        'matematika_levels',
        'pamilya_games',
        'matematika_games',
        'traceit_total',
        'kulay_total',
        'magbasa_total'
      ];
      for (var key in hiveKeys) {
        final val = _progressBox.get(key);
        if (val != null) rawProgressData[key] = val;
      }
      // Matematika's per-level ratings, for installs that earned them before
      // they were mirrored into SharedPreferences.
      for (int lvl = 0; lvl < matematikaLevelCount; lvl++) {
        for (final key in ['mat_level_${lvl}_stars', 'mat_level_${lvl}_score']) {
          final val = _progressBox.get(key);
          if (val is int && val > (rawProgressData[key] as int? ?? 0)) {
            rawProgressData[key] = val;
          }
        }
      }

      List<Map<String, dynamic>> cloudCreations = [];
      final rawCreations = _progressBox.get('coloring_creations');
      if (rawCreations is List) {
        for (var item in rawCreations) {
          if (item is Map) {
            cloudCreations.add({
              'name': item['name'] ?? 'My Artwork',
              'date': item['date'] ?? 0,
              'stars': item['stars'],
              'durationSeconds': item['durationSeconds'] ?? 0,
              'sourcePagePath': item['sourcePagePath'] ?? '',
              'base64Image': item['base64Image'] ?? '',
            });
          }
        }
        cloudCreations
            .sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
        if (cloudCreations.length > 15) {
          cloudCreations = cloudCreations.sublist(0, 15);
        }
      }

      // Send it without waiting for the server to answer.
      //
      // With offline persistence on, Firestore does not complete a write's
      // Future until the server acknowledges the write — and offline that
      // Future never resolves at all. Awaiting it here froze the child
      // mid-game: every caller that does `await _syncToFirebase()` stopped
      // dead, so the badge and certificate checks after it never ran and
      // neither did notifyListeners(). The screen simply stopped responding
      // the moment the signal dropped.
      //
      // The write itself needs no supervision. Firestore stores it locally
      // and delivers it on its own as soon as the network is back, which is
      // exactly the behaviour we want: play now, sync later.
      unawaited(FirebaseFirestore.instance
          .collection('students')
          .doc(_currentStudentId)
          .update({
        'progress': progressData,
        'profile': profileData,
        'rawProgress': rawProgressData,
        'creations': cloudCreations,
        'lastActive': FieldValue.serverTimestamp(),
      }).catchError((Object e) => debugPrint('Deferred sync failed: $e')));
    } catch (e) {
      debugPrint('Error preparing Firebase sync: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  The star ledger
  // ─────────────────────────────────────────────────────────────────────────
  //
  //  Stars are the app's only currency — points are a per-level readout for
  //  the child, never a total anyone has to reason about. So the dashboard
  //  says "37 of 230", and every badge is "all the stars in this area". For
  //  that fraction to mean anything the denominator has to be a real number
  //  and not a guess, which is what these constants are: the most stars each
  //  area can ever hand out, written next to how they are reached.

  /// 5 poems + 5 stories + 9 songs, each worth the full 3 — listening and
  /// reading have no wrong answer.
  /// One star per poem, story or song finished — 5 + 5 + 9.
  ///
  /// Was three each. Listening a poem through is real work for a
  /// three-year-old, but it is not three times a traced letter and it is not
  /// the equal of a seven-question Matematika level; paying it the same put
  /// nearly a third of every star in the app behind sitting still.
  ///
  /// The song count dropped from 13 to 9 (2026-09-03) when the four songs
  /// that never got a recording were removed from the list — see
  /// [_migrateMagbasaKantaLayout]. This ceiling has to move with it or the
  /// denominator overstates what a child could ever actually earn.
  static const int magbasaStarCeiling = 19;

  /// One star per picture coloured — 9 pages.
  ///
  /// Was 13 (4 base activities + 9 pages): 'basic'/'mixing'/'objects'/
  /// 'coloring' were never built into kulay_screen.dart, so those 4 stars
  /// could never be earned — the Colors badge could never reach its top
  /// star, and every dashboard reading this ceiling overstated what a child could
  /// ever actually finish. Same fix as the Magbasa song count below.
  static const int kulayStarCeiling = 9;

  /// One star per letter or number traced: 26 + 26 + 10.
  static const int traceitStarCeiling = 62;

  /// How many questions each Matematika level holds, in order.
  ///
  /// The teacher's report and the games badge both count finished questions,
  /// so a level whose length is not in here is a level a child can never
  /// finish on paper however many times they play it.
  static const List<int> matematikaGamesPerLevel = [
    5, // Bilangin
    5, // I-drag ang Numero
    3, // Itugma
    5, // I-pop ang Balloon
    5, // Marami o Kaunti
    3, // Palaisipan
    5, // Pagkakasunod
  ];

  /// Every question in the module.
  static int get matematikaGameCount =>
      matematikaGamesPerLevel.reduce((a, b) => a + b);

  /// How many levels Matematika has.
  ///
  /// Written down once. It used to be the literal 7 in six different places —
  /// the stored list of finished levels, two defaults for it, the per-level
  /// star loop, the games table and the ceiling below — and a level added
  /// without touching all six is a level whose stars are never counted.
  static const int matematikaLevelCount = 7;

  /// Every level at 3 stars.
  static const int matematikaStarCeiling = matematikaLevelCount * 3;

  /// 4 "Ang Aking Sarili" levels at 3 stars.
  static const int sariliStarCeiling = 4 * 3;

  /// 5 "Ken Ti Pamiliak" levels at 3 stars.
  static const int familyStarCeiling = 5 * 3;

  /// 4 memory categories at 3 stars.
  static const int tandaanStarCeiling = 4 * 3;

  /// 4 memory categories of 3 rounds each — how many there are to *finish*,
  /// which is a separate count from how many stars they can pay out.
  static const int tandaanRoundCount = 4 * 3;

  /// Every star in the app. This is the denominator on the dashboard, so a
  /// new activity has to be added to a ceiling above or the fraction quietly
  /// starts lying.
  static const int totalPossibleStars = magbasaStarCeiling +
      kulayStarCeiling +
      traceitStarCeiling +
      matematikaStarCeiling +
      sariliStarCeiling +
      familyStarCeiling +
      tandaanStarCeiling;

  /// The star total to *show*, never above what the app can actually award.
  ///
  /// Older profiles can carry more than the ceiling: an unreachable karaoke
  /// screen was being counted for 39 stars nobody could earn, and its songs
  /// were already paid for by Let's Read. A child seeing a total above the
  /// one the app admits to would be reading a broken promise, so the display
  /// is capped while the stored total is left alone.
  int get displayStars =>
      totalStars > totalPossibleStars ? totalPossibleStars : totalStars;

  // STARS AND ACHIEVEMENTS
  /// The child's one star total: the profile's when they have one, otherwise
  /// the stars banked on this device before a profile existed.
  ///
  /// Every star readout in the app — each module header and the dashboard —
  /// reads this, so they can never disagree.
  int get totalStars =>
      _userProfile?.stars ?? (_gb?.get(_pendingStarsKey) as int? ?? 0);

  static const String _pendingStarsKey = 'pending_stars';

  /// Version of the star weighting the stored total was written in.
  ///
  /// Bumped whenever what a finished thing is worth changes, which forces the
  /// one-time recount below. A stored total is a running sum of awards made at
  /// the time, so after a change it is a mixture of two currencies and cannot
  /// be corrected by arithmetic — only by counting again.
  static const int _starWeightingVersion = 2;
  static const String _starVersionKey = 'star_weighting_version';

  /// The child's stars, worked out from what they have actually finished.
  ///
  /// Nothing here trusts the stored total. Each module already derives its own
  /// figure from its completion records — which poems were listened to, which
  /// pages coloured, which letters traced, what each graded level scored — so
  /// the sum of those is the truth, and the stored number is only a cache of
  /// it.
  int recountStarsFromProgress() {
    final magbasa = getMagbasaProgress();
    final kulay = getKulayProgress();
    final traceit = getTraceItProgress();
    final matematika = getMatematikaProgress();
    final pamilya = getPamilyaProgress();
    final tandaan = getTandaanProgress();

    int at(Map<String, dynamic> m, String key) => (m[key] as int?) ?? 0;

    return at(magbasa, 'stars') +
        at(kulay, 'stars') +
        at(traceit, 'stars') +
        at(matematika, 'earnedStars') +
        at(pamilya, 'earnedStars') +
        at(tandaan, 'stars');
  }

  /// What the star total should read, given the two accounts of it.
  ///
  /// [shown] is the running total a profile carries — the cloud's copy, or
  /// the one this device has been adding to. [counted] is what the record of
  /// finished work on this device adds up to right now.
  ///
  /// When the record has just been restored it is the whole truth and wins
  /// outright, in both directions: replaying a level legitimately lowers the
  /// total, and a rule that forbade decreases would silently undo that.
  /// Before that, the record may simply not be here yet — a device that has
  /// never pulled has nothing to count — so it may only raise. The asymmetry
  /// is the point: stars earned offline are still on this device, and a
  /// stale cloud copy must never be allowed to erase them.
  static int reconcileStars({
    required int shown,
    required int counted,
    required bool recordRestored,
  }) {
    if (recordRestored) return counted;
    return counted > shown ? counted : shown;
  }

  /// Brings a profile written under an older weighting up to date, once.
  ///
  /// Silent when there is nothing to do, which is every launch after the
  /// first. A child with no profile yet has nothing to migrate — their banked
  /// stars are re-counted when the profile is created.
  Future<void> _migrateStarWeighting() async {
    if (!_isInitialized || _userProfile == null) return;

    final stored = (_progressBox.get(_starVersionKey) as int?) ?? 1;
    if (stored >= _starWeightingVersion) return;

    final counted = recountStarsFromProgress();
    final before = _userProfile!.stars;
    await _progressBox.put(_starVersionKey, _starWeightingVersion);

    if (counted != before) {
      debugPrint('Star weighting v$stored -> v$_starWeightingVersion: '
          '$before recounted as $counted');
      _userProfile!.stars = counted;
      await _profileBox.put('currentUser', _userProfile!.toJson());
      unawaited(_syncToFirebase());
    }
    notifyListeners();
  }

  /// Version of the 'kanta' activity list's slot layout.
  ///
  /// Bumped whenever an entry is removed from (or merged in) the middle of
  /// the list — completion is stored by position (`magbasa_kanta_<index>`),
  /// never by the song's own id, so any change to the list order silently
  /// reattaches every later song's saved "finished" flag to whichever song
  /// now sits at that index unless every later slot is shifted to match.
  /// v1->v2 merged two entries for the same song into one; v2->v3 drops the
  /// four songs that never got a recording.
  static const int _magbasaKantaLayoutVersion = 3;
  static const String _magbasaKantaLayoutVersionKey =
      'magbasa_kanta_layout_version';

  /// The old 14-slot 'kanta' completion list, reduced to the 13 slots the
  /// v2 layout has.
  ///
  /// Slot 0 of the result is true if either of the two old entries that
  /// became one (indices 0 and 1) was — a child who had finished either
  /// copy of the song had finished the song. Every slot after that is
  /// exactly the old slot two higher, kept as plain, easily-tested index
  /// arithmetic and nothing else.
  static List<bool> mergedKantaSlots(List<bool> oldSlots) {
    assert(oldSlots.length == 14);
    return [
      oldSlots[0] || oldSlots[1],
      for (int i = 2; i < oldSlots.length; i++) oldSlots[i],
    ];
  }

  /// The v2, 13-slot 'kanta' completion list, reduced to the 9 slots the v3
  /// layout has, once the four songs that never got a recording — old
  /// slots 3, 5, 8 and 10 — are dropped from the list entirely. Same plain
  /// index arithmetic as [mergedKantaSlots]: drop those four positions and
  /// close the gap, so every other slot stays attached to the song it
  /// always was.
  static List<bool> audiolessRemovedKantaSlots(List<bool> oldSlots) {
    assert(oldSlots.length == 13);
    const removedIndices = {3, 5, 8, 10};
    return [
      for (int i = 0; i < oldSlots.length; i++)
        if (!removedIndices.contains(i)) oldSlots[i],
    ];
  }

  /// 2026-09-03: two layout changes to the 'kanta' song list landed close
  /// together — the 'ania_ti_naganmo'/'ania_ti_naganmo_full' merge (v1->v2)
  /// and dropping the four songs that never got a recording (v2->v3). Runs
  /// whichever steps a given device hasn't seen yet, in order, so a device
  /// that missed both catches up in one pass rather than needing the app
  /// opened once per version.
  Future<void> _migrateMagbasaKantaLayout() async {
    if (!_isInitialized) return;
    final stored =
        (_progressBox.get(_magbasaKantaLayoutVersionKey) as int?) ?? 1;
    if (stored >= _magbasaKantaLayoutVersion) return;

    const category = 'kanta';

    // Hive and SharedPreferences are two copies of the same fact — checked
    // in that priority by isMagbasaActivityCompleted, but for a plain
    // completion flag "checked in this order" and "true if either one is"
    // agree on every case that matters, so the raw slots below are just the
    // two combined.
    List<bool> slots;
    bool hadAnySlot;
    if (stored < 2) {
      final oldSlots = List.generate(
          14,
          (i) =>
              _progressBox.get('magbasa_${category}_$i') == true ||
              _prefs?.getBool('${category}_activity_$i') == true);
      hadAnySlot = oldSlots.any((v) => v) ||
          _progressBox.get('magbasa_$category') != null;
      slots = mergedKantaSlots(oldSlots);
    } else {
      slots = List.generate(
          13,
          (i) =>
              _progressBox.get('magbasa_${category}_$i') == true ||
              _prefs?.getBool('${category}_activity_$i') == true);
      hadAnySlot =
          slots.any((v) => v) || _progressBox.get('magbasa_$category') != null;
    }

    await _progressBox.put(
        _magbasaKantaLayoutVersionKey, _magbasaKantaLayoutVersion);

    // A fresh install, or one that opened for the first time after every
    // change here already shipped, has none of these keys at all — nothing
    // to shift, and no reason to touch the box.
    if (!hadAnySlot) return;

    if (stored < 3) {
      slots = audiolessRemovedKantaSlots(slots);
    }

    // Clear every slot key this device could plausibly still have — the
    // widest of the old layouts, 14 — before writing the new, shorter list.
    // A leftover 'magbasa_kanta_12' from the pre-merge layout would
    // otherwise outlive both migrations and get read back as an extra,
    // wrong song.
    for (int i = 0; i < 14; i++) {
      await _progressBox.delete('magbasa_${category}_$i');
      if (_prefs != null) await _prefs!.remove('${category}_activity_$i');
    }
    final categoryMap = <String, dynamic>{};
    for (int i = 0; i < slots.length; i++) {
      await _progressBox.put('magbasa_${category}_$i', slots[i]);
      if (_prefs != null) {
        await _prefs!.setBool('${category}_activity_$i', slots[i]);
      }
      categoryMap['$i'] = slots[i];
    }
    await _progressBox.put('magbasa_$category', categoryMap);

    debugPrint('Magbasa kanta layout v$stored -> '
        'v$_magbasaKantaLayoutVersion: slots migrated');
    await _updateMagbasaTotalProgress();
    unawaited(_syncToFirebase());
    notifyListeners();
  }

  /// The last day the child did anything, and the run of days ending in it.
  ///
  /// Kept app-wide. Two modules recorded their own last-played date and the
  /// rest recorded none, so a child who spent a week colouring registered as
  /// never having opened the app — and the streak badge, which is fed from
  /// this, never moved for them.
  static const String _lastPlayedKey = 'app_last_played';
  static const String _streakKey = 'app_day_streak';

  /// What the child is still getting wrong, per module.
  ///
  /// Shape: `{'matematika': {'5': 2, '8': 1}}` — the item, and how far it is
  /// from being learnt. A miss adds one, a correct answer takes one away, and
  /// an item that reaches zero leaves the map.
  ///
  /// Self-healing on purpose. A plain tally of every mistake ever made grows
  /// forever and slowly stops describing the child in front of the teacher;
  /// this describes only what is still unsettled.
  static const String _missesKey = 'practice_misses';
  static const int _missCeiling = 5;

  Map<String, Map<String, int>> get practiceMisses {
    final raw = _gb?.get(_missesKey);
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): {
          if (entry.value is Map)
            for (final item in (entry.value as Map).entries)
              item.key.toString(): (item.value as num?)?.toInt() ?? 0
        }
    };
  }

  /// Records one attempt at one item.
  ///
  /// [item] is whatever the child was actually asked — a letter, a number, a
  /// shape. It is shown to the teacher as-is, so it has to read as the thing
  /// on the screen and not as an index into something.
  Future<void> noteAttempt(String module, String item,
      {required bool correct}) async {
    if (_gb == null || item.isEmpty) return;
    final all = Map<String, Map<String, int>>.from(practiceMisses);
    final forModule = Map<String, int>.from(all[module] ?? const {});

    final was = forModule[item] ?? 0;
    final now = correct ? was - 1 : was + 1;
    if (now <= 0) {
      forModule.remove(item);
    } else {
      // Capped so one bad afternoon cannot bury an item the child has since
      // learnt under a score it takes a week of correct answers to work off.
      forModule[item] = now > _missCeiling ? _missCeiling : now;
    }

    if (forModule.isEmpty) {
      all.remove(module);
    } else {
      all[module] = forModule;
    }
    await _progressBox.put(_missesKey, all);
    notifyListeners();
  }

  /// The items to practise, worst first.
  ///
  /// Across every module when [module] is null.
  List<({String module, String item, int weight})> practiceList(
      {String? module, int limit = 8}) {
    final rows = <({String module, String item, int weight})>[];
    for (final m in practiceMisses.entries) {
      if (module != null && m.key != module) continue;
      for (final i in m.value.entries) {
        rows.add((module: m.key, item: i.key, weight: i.value));
      }
    }
    rows.sort((a, b) => b.weight.compareTo(a.weight));
    return rows.take(limit).toList();
  }

  String? get lastPlayedIso => _gb?.get(_lastPlayedKey) as String?;

  /// Consecutive days ending today, or 0 before the child has ever played.
  int get dayStreak {
    final last = lastPlayedIso;
    if (last == null || last.isEmpty) return 0;
    return computeDailyStreak(last, (_gb?.get(_streakKey) as int?) ?? 0);
  }

  /// Records that the child played, now.
  ///
  /// Called wherever a star is earned, because earning one is the same event
  /// as playing — there is no way to earn a star without having done
  /// something, and no activity that finishes without one.
  Future<void> _touchLastPlayed() async {
    if (_gb == null) return;
    final now = DateTime.now().toIso8601String();
    final streak =
        computeDailyStreak(lastPlayedIso, (_gb?.get(_streakKey) as int?) ?? 0);
    await _progressBox.put(_lastPlayedKey, now);
    await _progressBox.put(_streakKey, streak);
  }

  /// Applies a signed change to the child's star total.
  ///
  /// Replaying a level replaces that level's rating instead of adding to it,
  /// so a weaker second run has to be able to hand stars back. The total is
  /// never allowed below zero.
  Future<void> adjustStars(int delta) async {
    await _ensureInitialized();
    if (delta == 0) return;

    if (_userProfile != null) {
      final next = _userProfile!.stars + delta;
      _userProfile!.stars = next < 0 ? 0 : next;
      await _profileBox.put('currentUser', _userProfile!.toJson());
      notifyListeners();
      unawaited(_syncToFirebase());
      return;
    }

    final banked = (_progressBox.get(_pendingStarsKey) as int? ?? 0) + delta;
    await _progressBox.put(_pendingStarsKey, banked < 0 ? 0 : banked);
    notifyListeners();
  }

  Future<void> addStars(int stars) async {
    await _ensureInitialized();
    if (stars <= 0) return;
    await _touchLastPlayed();

    if (_userProfile != null) {
      _userProfile!.stars += stars;
      await _profileBox.put('currentUser', _userProfile!.toJson());
      // Tell the UI now and upload in the background: a slow or unreachable
      // Firebase must never hold up the star the child just earned.
      notifyListeners();
      unawaited(_syncToFirebase());
      return;
    } else {
      // No student profile yet — someone is playing before logging in. Bank
      // the stars on the device instead of dropping them silently, and fold
      // them into the profile as soon as one exists.
      final banked = (_progressBox.get(_pendingStarsKey) as int? ?? 0) + stars;
      await _progressBox.put(_pendingStarsKey, banked);
    }
    notifyListeners();
  }

  /// Moves any stars banked before login onto the profile that just appeared.
  Future<void> _claimPendingStars() async {
    if (_userProfile == null || _gb == null) return;
    final pending = _progressBox.get(_pendingStarsKey) as int? ?? 0;
    if (pending <= 0) return;
    _userProfile!.stars += pending;
    await _progressBox.delete(_pendingStarsKey);
    await _profileBox.put('currentUser', _userProfile!.toJson());
    notifyListeners();
  }

  /// The certificates the child has been awarded.
  List<String> get earnedCertificates => _userProfile?.certificates ?? const [];

  /// Whether [id] has already been awarded, so it is not given twice.
  bool hasCertificate(String id) =>
      _userProfile?.certificates.contains(id) ?? false;

  /// [allowRevoke] false on the login pull, for the reason given on
  /// [checkAndAwardBadges].
  Future<List<String>> checkAndAwardCertificates(
      {bool allowRevoke = true}) async {
    await _ensureInitialized();
    if (_userProfile == null) return [];

    final newlyEarned = <String>[];
    final withdrawn = <String>[];

    // E-Tarabay Graduate — all 12 badges claimed and every lesson finished
    {
      const badgeIds = UserProvider.graduateBadgeIds;
      // Claimed, not three stars: any tier counts once the child has tapped
      // "claim" on it, the same bar every individual badge already uses.
      // Requiring the full three stars specifically asked for a tier this screen never
      // shows once a badge is claimed — a child (and a parent reading the
      // Awards screen) had no way to tell the certificate was still out
      // of reach.
      final allBadges = badgeIds.every(
        (id) => _userProfile!.claimedBadges.contains(id),
      );
      // And every lesson finished. The card has always promised both halves —
      // "Earn all 12 badges" and "Complete every learning module" — but only
      // the badges were ever checked, so a child could hold a Certificate of
      // Completion with modules still unopened. Finished, not fully starred:
      // playing every activity to the end is the bar, which is what the
      // Lessons screen means by "Tapos na!".
      final allModules = allModulesComplete;
      final qualifies = allBadges && allModules;
      // Held while it is true, withdrawn when it stops being true. It
      // used to be added and never taken back, so a child reset to zero kept
      // a certificate saying they had finished everything -- while the twelve
      // badges it is awarded from correctly disappeared.
      if (qualifies && !hasCertificate('e_tarabay_graduate')) {
        newlyEarned.add('e_tarabay_graduate');
      } else if (allowRevoke &&
          !qualifies &&
          hasCertificate('e_tarabay_graduate')) {
        withdrawn.add('e_tarabay_graduate');
      }
    }

    for (final id in newlyEarned) {
      _userProfile!.certificates.add(id);
      _userProfile!.certificateAwardedAt[id] =
          DateTime.now().millisecondsSinceEpoch;
    }
    for (final id in withdrawn) {
      _userProfile!.certificates.remove(id);
      _userProfile!.certificateAwardedAt.remove(id);
    }
    if (newlyEarned.isNotEmpty || withdrawn.isNotEmpty) {
      await _profileBox.put('currentUser', _userProfile!.toJson());
      await _syncToFirebase();
      notifyListeners();
    }

    return newlyEarned;
  }

  // ─── BADGE CLAIMING ─────────────────────────────────────────────

  bool isBadgeClaimed(String badgeId) {
    if (_userProfile == null) return false;
    return _userProfile!.claimedBadges.contains(badgeId);
  }

  /// Badges the child has collected and still holds.
  ///
  /// Deliberately the overlap of "claimed" and "earned" rather than the raw
  /// claimed list: a progress reset used to clear the earned set while
  /// leaving the claimed one behind, and any profile carrying that stale
  /// entry would otherwise keep over-counting forever. Taking the overlap
  /// lets those profiles correct themselves.
  List<String> get collectedBadgeIds {
    final profile = _userProfile;
    if (profile == null) return const [];
    return profile.claimedBadges
        .where((id) => (profile.achievements[id] ?? 0) >= 1)
        .toList();
  }

  Future<void> claimBadge(String badgeId) async {
    await _ensureInitialized();
    if (_userProfile == null) return;
    if ((_userProfile!.achievements[badgeId] ?? 0) < 1) return;
    if (_userProfile!.claimedBadges.contains(badgeId)) return;

    _userProfile!.claimedBadges.add(badgeId);
    _userProfile!.badgeClaimedAt[badgeId] =
        DateTime.now().millisecondsSinceEpoch;
    await _profileBox.put('currentUser', _userProfile!.toJson());
    await _syncToFirebase();
    // Claiming the last of the 12 is exactly the moment the certificate
    // should unlock — waiting for some unrelated activity to happen to
    // trigger the next check left it Locked right after the child had
    // just done the thing that was supposed to earn it.
    await checkAndAwardCertificates();
    notifyListeners();
  }

  // ─── BADGES (ACHIEVEMENTS) ─────────────────────────────────────

  /// Aggregated progress with the day streak folded in, shared by the award
  /// check and the awards screen so both read the same numbers.
  Map<String, dynamic> _badgeInputs() {
    final progress = getAllProgress();
    progress['dayStreak'] = _progressBox.get('matematika_streak') as int? ?? 0;
    return progress;
  }

  /// How far the child has come towards every badge, keyed by badge id.
  /// Used to show "23 / 26" on badges that are still locked.
  Map<String, BadgeProgress> badgeProgressSnapshot() {
    if (!_isInitialized) {
      return {
        for (final def in badgeCatalog) def.id: const BadgeProgress(0, 1)
      };
    }
    final inputs = _badgeInputs();
    return {
      for (final def in badgeCatalog) def.id: def.progressFrom(inputs),
    };
  }

  /// [allowRevoke] false is for the login pull: a device that has just
  /// restored from the cloud can hold less than the child actually finished
  /// (anything the backup never carried), and withdrawing badges off that
  /// partial picture — then uploading the withdrawal — took claimed awards
  /// away from every device at once. Only a replay the child plays here may
  /// step a badge down.
  Future<List<Map<String, dynamic>>> checkAndAwardBadges(
      {bool allowRevoke = true}) async {
    await _ensureInitialized();
    if (_userProfile == null) return [];

    final newlyEarned = <Map<String, dynamic>>[];
    final progress = _badgeInputs();
    bool revoked = false;

    for (final def in badgeCatalog) {
      final had = _userProfile!.achievements[def.id] ?? 0;
      final now = def.progressFrom(progress).tier;

      if (now == had) continue;

      // A badge says what the child's work is worth *now*, not the best it
      // ever was. Replaying a level replaces its rating, so a weaker run can
      // take stars back down — and the medal has to follow, or it claims
      // something no longer true. With three steps that is usually a step
      // down rather than the whole badge going.
      if (now < had) {
        if (!allowRevoke) continue;
        if (now == 0) {
          _userProfile!.achievements.remove(def.id);
        } else {
          _userProfile!.achievements[def.id] = now;
        }
        // A step down is a new thing to be shown and claimed again.
        _userProfile!.claimedBadges.remove(def.id);
        revoked = true;
        continue;
      }

      // Recognition only — no stars. See badge_catalog.dart.
      _userProfile!.achievements[def.id] = now;
      if (had > 0) _userProfile!.claimedBadges.remove(def.id);
      newlyEarned.add({
        'id': def.id,
        'icon': def.icon,
        'color': def.color,
        'tier': now,
      });
    }

    if (newlyEarned.isNotEmpty || revoked) {
      await _profileBox.put('currentUser', _userProfile!.toJson());
      await _syncToFirebase();
      notifyListeners();
    }

    return newlyEarned;
  }

  // RESET PROGRESS
  Future<void> resetAllProgress() async {
    await _ensureInitialized();
    await _progressBox.clear();
    _initProgressBox();
    await _syncToFirebase();
    notifyListeners();
  }

  // GET SPECIFIC PROGRESS
  bool isMagbasaActivityCompleted(String category, int index) {
    if (!_isInitialized) return false;
    if (_prefs != null &&
        _prefs!.getBool('${category}_activity_$index') == true) {
      return true;
    }
    return _progressBox.get('magbasa_${category}_$index') ?? false;
  }

  bool isKulayActivityCompleted(String activity) {
    if (!_isInitialized) return false;
    if (_prefs != null && _prefs!.getBool('kulay_$activity') == true) {
      return true;
    }
    return _progressBox.get('kulay_$activity') ?? false;
  }

  bool isKulayPageCompleted(String category, int index) {
    if (!_isInitialized) return false;
    if (_prefs != null &&
        _prefs!.getBool('kulay_page_${category}_$index') == true) {
      return true;
    }
    return _progressBox.get('kulay_page_${category}_$index') ?? false;
  }

  /// Which Matematika levels are finished, always [matematikaLevelCount]
  /// long however short the stored list is.
  List<dynamic> _matematikaLevelFlags() {
    final stored = _progressBox.get('matematika_levels');
    final flags =
        List<dynamic>.from(stored is List ? stored : const <dynamic>[]);
    while (flags.length < matematikaLevelCount) {
      flags.add(false);
    }
    return flags;
  }

  bool isMatematikaLevelCompleted(int level) {
    if (!_isInitialized) return false;
    final completedLevels = _matematikaLevelFlags();

    if (_prefs != null &&
        _prefs!.getBool('mat_level_complete_$level') == true) {
      return true;
    }

    return level < completedLevels.length ? completedLevels[level] : false;
  }

  bool isMatematikaGameCompleted(int level, int gameIndex) {
    if (!_isInitialized) return false;
    Map<String, dynamic> games =
        Map<String, dynamic>.from(_progressBox.get('matematika_games') ?? {});

    if (_prefs != null) {
      if (_prefs!.getBool('mat_level_${level}_game_$gameIndex') == true) {
        return true;
      }
      if (_prefs!.getBool('matematika_game_${level}_$gameIndex') == true) {
        return true;
      }
    }

    return games['level${level}_game$gameIndex'] ?? false;
  }

  bool isPamilyaLevelCompleted(int categoryIndex, int level) {
    if (!_isInitialized) return false;
    // Map cat-level to a flat index (0-3 for cat 0, 4-8 for cat 1)
    final globalIdx = categoryIndex == 0 ? level : 4 + level;
    List<dynamic> completedLevels =
        _progressBox.get('pamilya_levels') ?? List.filled(9, false);

    final done = globalIdx < completedLevels.length &&
        completedLevels[globalIdx] == true;

    // The stored record is the authority. The preference key used to be set
    // on every answered question, so any profile that played before this was
    // fixed still carries a `true` for levels that were never finished —
    // clear those as they are found, rather than leaving them to report a
    // level complete forever.
    final levelKey = 'pamilya_cat_${categoryIndex}_level_$level';
    if (!done && _prefs?.getBool(levelKey) == true) {
      _prefs!.remove(levelKey);
    }
    return done;
  }

  bool isPamilyaGameCompleted(int categoryIndex, int level, int gameIndex) {
    if (!_isInitialized) return false;
    final gameKey =
        'pamilya_cat_${categoryIndex}_level_${level}_game_$gameIndex';

    // Check Hive
    Map<String, dynamic> games =
        Map<String, dynamic>.from(_progressBox.get('pamilya_games') ?? {});
    if (games.containsKey(gameKey)) return games[gameKey] ?? false;

    // Fallback to SharedPreferences if not in Hive yet
    if (_prefs != null) {
      return _prefs!.getBool(gameKey) ?? false;
    }

    return false;
  }

  @override
  void dispose() {
    _stopProfileListener();
    _configSubscription?.cancel();
    super.dispose();
  }
}
