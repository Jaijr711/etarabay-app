import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/reminder_service.dart';
import '../utils/constants.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/locked_module_dialog.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/certificate_emblem.dart';
import '../widgets/birthday_celebration.dart';
import '../services/update_checker.dart';
import '../widgets/update_dialog.dart';
import '../utils/page_transitions.dart';
import 'matematika_screen.dart';
import 'pamilya_screen.dart';
import 'kulay_screen.dart';
import 'trace_it_screen.dart';
import 'magbasa_screen.dart';
import 'tandaan_screen.dart';
import 'lessons_screen.dart';
import 'awards_screen.dart';
import 'certificates_screen.dart';
import 'settings_screen.dart';
import 'parents_lock_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start background music safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioManager>(context, listen: false)
          .startBackgroundMusic(AudioManager.homeMusicAsset);
      _checkBirthday();
      _checkForUpdate();
    });
  }

  /// Once per app open — there is no Play Store to raise this on its own,
  /// so a sideloaded install has to ask. Silent on any failure: a child
  /// mid-lesson should never see a network error over something that
  /// isn't blocking anything they are doing.
  Future<void> _checkForUpdate() async {
    final update = await UpdateChecker.instance.checkForUpdate();
    if (update != null && mounted) {
      showUpdateAvailableDialog(context, update);
    }
  }

  // The birthday check used to run exactly once, in initState — so a child
  // whose birthday was set *after* the home screen was first built (a parent
  // correcting a typo, or a teacher filling it in later) never saw the
  // celebration until the app was fully closed and reopened. Home is never
  // popped and rebuilt on its own; a parent backing out of Profile after an
  // edit returns to the very same, already-built screen. This re-checks
  // every time that return actually happens.
  //
  // The other gap this closes: a teacher correcting a birthday — or a
  // parent fixing a typo — writes straight to Firestore, and the profile
  // listener in UserProvider pulls that down and calls notifyListeners()
  // the moment it arrives, online. Home already rebuilds on that (its
  // build method reads UserProvider with listen: true), which is what
  // makes didChangeDependencies fire again here too — the same hook that
  // already re-checks on return from another screen now also re-checks
  // the instant the correction actually lands, with the child sitting on
  // Home the whole time and never having to leave it.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
    _checkBirthday();
  }

  @override
  void didPopNext() {
    _checkBirthday();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Stops two calls racing each other before either has written the "shown
  /// today" marker. initState, didPopNext and didChangeDependencies can all
  /// call [_checkBirthday] within the same few milliseconds — on first
  /// launch, in particular, the postFrameCallback and the first
  /// didChangeDependencies land close enough together that both could read
  /// "not shown yet" before the first one finishes writing it, and the
  /// child would meet the card twice, stacked.
  bool _checkingBirthday = false;

  Future<void> _checkBirthday() async {
    if (_checkingBirthday) return;
    _checkingBirthday = true;
    try {
      await _checkBirthdayUnguarded();
    } finally {
      _checkingBirthday = false;
    }
  }

  Future<void> _checkBirthdayUnguarded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.userProfile;
    if (profile == null || profile.birthday == null) return;

    final now = DateTime.now();
    if (profile.birthday!.month == now.month &&
        profile.birthday!.day == now.day) {
      // Once for the day, not once per visit. _checkBirthday now runs on
      // every return to Home (see didPopNext above, and the note on why) —
      // so without this, a birthday child bouncing to Lessons and back, or
      // to their own Profile and back, met the card fresh every single time
      // rather than once. The marker is the date itself, not a plain flag:
      // a flag would need clearing somewhere, and would still say "shown"
      // on the child's next birthday a year later if that clearing ever
      // missed a spot. A stale date compares unequal on its own.
      final today = '${now.year}-${now.month}-${now.day}';
      final shownKey = 'birthday_shown_${userProvider.currentStudentId}';
      if (prefs.getString(shownKey) != today) {
        await prefs.setString(shownKey, today);
        if (!mounted) return;
        showBirthdayCelebration(context, name: profile.name);
      }
    }

    // Books next year's greeting too — the confetti above only covers a
    // birthday that lands while this screen happens to be open. There is no
    // month-and-day recurrence to hand this to once and forget: see the note
    // on ReminderService.scheduleBirthday for why this has to run again on
    // every visit rather than being set once.
    //
    // Gated on the Notifications toggle, unlike the in-app confetti above —
    // that needs no OS permission and always shows; this puts something on
    // the lock screen, and only the Settings switch has ever asked for that
    // permission. Defaults to off, not on: this key is only ever written
    // true by that switch, and scheduling before the permission had been
    // requested was silently dropped by Android 13+ with nothing to show
    // for it — no error, no notification either.
    if (!(prefs.getBool('notifications_enabled') ?? false)) return;
    if (!mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    unawaited(ReminderService.instance.scheduleBirthday(
      birthday: profile.birthday!,
      childName: profile.name,
      languageCode: lang.currentLanguageCode,
    ));
  }

  // Get real stats from UserProvider with null safety
  Map<String, dynamic> _getStats(UserProvider userProvider) {
    if (!userProvider.isInitialized) {
      return {
        'lessons': 0,
        'stars': 0,
        'possibleStars': UserProvider.totalPossibleStars,
        'awards': 0
      };
    }
    final progress = userProvider.getAllProgress();
    return {
      'lessons': progress['totalCompleted'] ?? 0,
      // One plain number here — the child's whole star pile. The fraction
      // belongs on each module card below, where it can say which module
      // still has stars left in it.
      'stars': userProvider.displayStars,
      'possibleStars': UserProvider.totalPossibleStars,
      // Awards the child has actually collected, not the ones merely unlocked.
      //
      // `achievements` counts badges the moment their rule is met; the child
      // still has to open Awards and tap to claim each one. Counting the
      // unclaimed ones here made the home screen say "2" while the Awards
      // gallery showed one trophy — the same word reporting two numbers.
      // The "you have awards waiting" line in Awards is what announces the
      // unclaimed ones.
      'awards': userProvider.collectedBadgeIds.length,
    };
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home - no navigation needed
        break;
      case 1:
        context.pushReplacementFadeThrough(const LessonsScreen());
        break;
      case 2:
        context.pushReplacementFadeThrough(const AwardsScreen());
        break;
      case 3:
        context.pushReplacementFadeThrough(const SettingsScreen());
        break;
    }
  }

  /// "Good morning, Juan!" — or afternoon, or evening, read off the clock
  /// on whatever device the child is holding.
  ///
  /// Three bands rather than a finer split: a preschooler does not
  /// distinguish 10am from noon, and the boundaries here — before 12,
  /// before 6pm, the rest — are the same ones the greeting card industry
  /// settled on for the same reason.
  String _timeGreeting(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return loc.greetMorning;
    if (hour < 18) return loc.greetAfternoon;
    return loc.greetEvening;
  }

  String _formatDisplayName(String fullName, String middleName) {
    final trimmedFull = fullName.trim();
    final trimmedMid = middleName.trim();
    if (trimmedFull.isEmpty) return 'Student';

    if (trimmedMid.isNotEmpty) {
      final initial = '${trimmedMid[0].toUpperCase()}.';
      final midRegExp = RegExp(RegExp.escape(trimmedMid), caseSensitive: false);

      if (midRegExp.hasMatch(trimmedFull)) {
        return trimmedFull
            .replaceAll(midRegExp, initial)
            .replaceAll(RegExp(r'\s+'), ' ');
      }

      final words = trimmedFull.split(RegExp(r'\s+'));
      if (words.length == 1) {
        return '${words.first} $initial';
      }
      final firstPart = words.first;
      final lastPart = words.sublist(1).join(' ');
      return '$firstPart $initial $lastPart';
    }

    final words = trimmedFull.split(RegExp(r'\s+'));
    if (words.length >= 3) {
      final midIndex = words.length - 2;
      final initial = '${words[midIndex][0].toUpperCase()}.';
      words[midIndex] = initial;
      return words.join(' ');
    }

    return trimmedFull;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final stats = _getStats(userProvider);

    // Get user info with null safety
    final profile = userProvider.userProfile;
    // No stranger's name on the child's own screen. "Noel" showed whenever
    // the profile was missing -- before the first load, and from the moment a
    // teacher deleted the account, which is exactly when a deleted account
    // still looked to the child like it worked.
    String rawName = profile?.name ?? '';
    String midName = profile?.middleName ?? '';
    String userName = _formatDisplayName(rawName, midName);
    int userAge = profile?.age ?? 2;
    final avatar = profile?.avatar ?? '';

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _PlayfulBackground()),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header Section
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Row
                      Row(
                        children: [
                          // Profile Avatar
                          GestureDetector(
                            onTap: () {
                              context.pushPremium(const ProfileScreen());
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _buildHomeAvatar(avatar, userName),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // The name a child answers to, on one line.
                          //
                          // The full name was printed here with nowhere to
                          // wrap but downwards: "John Lloyd F. Briones" took
                          // three lines and pushed the header to nearly 300
                          // pixels — most of the screen above the games, spent
                          // on a legal name for a four-year-old called John.
                          //
                          // The full version is still on the profile screen,
                          // one tap away on the avatar beside this.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // "Good morning" (etc), by the clock.
                                // The child's own name is what they actually
                                // recognise, so it stays the big, bold thing
                                // right under this — this is a small line
                                // above it, not a second place the name
                                // could have been squeezed into and clipped.
                                Text(
                                  _timeGreeting(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight.withOpacity(0.8),
                                  ),
                                ),
                                // Shrunk to fit rather than cut off: on a
                                // narrow phone "J…" is no name at all, and the
                                // child's name is the one thing on this card
                                // they can read.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    userName.trim().split(RegExp(r'\s+')).first,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    // Flexible so a narrow screen shortens
                                    // the age chip instead of overflowing.
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .homeAge(userAge),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // The performance grade used to sit
                                    // here: "Outstanding" or "Very
                                    // Satisfactory" over a three-pixel bar.
                                    // Neither the word nor the bar means
                                    // anything to a three-year-old, and the
                                    // judgement is not theirs to carry.
                                    //
                                    // It is now shown nowhere. The provider
                                    // still works it out — getAllProgress()
                                    // carries 'grade' — so putting it on the
                                    // parents' or the teacher's screen is a
                                    // matter of reading it there.
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // The star total, as a gold medal.
                          //
                          // The star is the app's currency and the only thing
                          // a child collects on purpose, so it is the biggest
                          // thing on this card after their name. Upright —
                          // star over number — rather than side by side, so
                          // it takes the row's height instead of the name's
                          // width: the name was being squeezed to one letter
                          // on narrow phones.
                          Container(
                            constraints: const BoxConstraints(minWidth: 66),
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFF8E1), Color(0xFFFFE08A)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFFD25E), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFB800).withOpacity(0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 32,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x55B07800),
                                      blurRadius: 3,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${stats['stars']}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF8A5A00),
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Certificates over the parents' door: two small,
                          // quiet squares stacked in the corner, so together
                          // they are no wider than one of them.
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Certificates. A rosette here said "award",
                              // which is the other screen; this opens the
                              // certificates, so it shows one — with the
                              // count as a small badge on its corner.
                              GestureDetector(
                                onTap: () {
                                  context
                                      .pushPremium(const CertificatesScreen());
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.success.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.success
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: const CertificateEmblem(
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Container(
                                        constraints:
                                            const BoxConstraints(minWidth: 18),
                                        height: 18,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          border: Border.all(
                                              color: Colors.white, width: 1.5),
                                        ),
                                        child: Text(
                                          '${userProvider.earnedCertificates.length}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // The parents' door.
                              //
                              // It used to be the raised centre button of the
                              // bottom bar — lifted, purple, plated in white:
                              // the most prominent shape on the screen, for
                              // the one destination a child is not meant to
                              // notice. Small and quiet in the corner instead.
                              // The lock behind it is unchanged — this only
                              // stops the door advertising itself.
                              GestureDetector(
                                onTap: () => context
                                    .pushPremium(const ParentsLockScreen()),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Icon(
                                    LucideIcons.users,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // The six doors. To a child this is the whole dashboard:
                // everything above is a name and a star, and everything below
                // is for a grown-up. Giving them the height the stats strip
                // used to take makes each card about a fifth taller.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardHeight = (constraints.maxHeight - 24) / 3;

                        final allProgress = userProvider.getAllProgress();

                        // How far into a module the child is, as a number
                        // of stars they can count on one hand.
                        //
                        // This read "⭐ 9/21" before. Every card counting the
                        // same currency was the right fix at the time, but the
                        // form was still wrong: a fraction is two numbers and
                        // a divide, and the totals run to 69. A daycare child
                        // counts to about five. Three stars they can count;
                        // "9/21" is a pattern they can only learn to ignore.
                        //
                        // Zero means not started and shows nothing at all — an
                        // empty row on every card would say "you have failed at
                        // six things" before they begin.
                        int starBadge(String module) {
                          final m = allProgress[module] as Map? ?? {};
                          final earned =
                              (m['stars'] ?? m['earnedStars'] ?? 0) as int;
                          final possible = (m['possibleStars'] ?? 0) as int;
                          if (earned <= 0 || possible <= 0) return 0;
                          final filled = (earned * 3 / possible).ceil();
                          return filled > 3 ? 3 : filled;
                        }

                        final matBadge = starBadge('matematika');
                        final pamilyaBadge = starBadge('pamilya');
                        final kulayBadge = starBadge('kulay');
                        final traceBadge = starBadge('traceit');
                        final magbasaBadge = starBadge('magbasa');
                        final tandaanBadge = starBadge('tandaan');

                        return Column(
                          children: [
                            SizedBox(
                              height: cardHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 0,
                                      child: _buildCard(
                                        title: AppLocalizations.of(context)!
                                            .matematika,
                                        subtitle: AppLocalizations.of(context)!
                                            .letsCount,
                                        imagePath: 'assets/images/card1.webp',
                                        color: AppColors.numbers,
                                        badgeStars: matBadge,
                                        onTap: () {
                                          if (_isLocked('matematika')) {
                                            return _showLockedMessage();
                                          }
                                          context.pushPremium(
                                            const MatematikaScreen(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 1,
                                      child: _buildCard(
                                        title: AppLocalizations.of(context)!
                                            .angAkingSarili,
                                        subtitle: AppLocalizations.of(context)!
                                            .atAkingPamilya,
                                        imagePath: 'assets/images/card2.webp',
                                        color: AppColors.family,
                                        badgeStars: pamilyaBadge,
                                        onTap: () {
                                          if (_isLocked('pamilya')) {
                                            return _showLockedMessage();
                                          }
                                          context.pushPremium(
                                            const PamilyaScreen(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: cardHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 2,
                                      child: _buildCard(
                                        title: AppLocalizations.of(context)!
                                            .kulaySaya,
                                        subtitle: AppLocalizations.of(context)!
                                            .magkulayTayo,
                                        imagePath: 'assets/images/card3.webp',
                                        color: AppColors.colors,
                                        badgeStars: kulayBadge,
                                        onTap: () {
                                          if (_isLocked('kulay')) {
                                            return _showLockedMessage();
                                          }
                                          context.pushPremium(
                                            const KulayScreen(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 3,
                                      child: _buildCard(
                                        title: AppLocalizations.of(context)!
                                            .traceItTitle,
                                        subtitle: AppLocalizations.of(context)!
                                            .traceItSubtitle,
                                        imagePath: 'assets/images/card4.webp',
                                        color: AppColors.success,
                                        badgeStars: traceBadge,
                                        onTap: () {
                                          if (_isLocked('traceit')) {
                                            return _showLockedMessage();
                                          }
                                          context.pushPremium(
                                            const TraceItScreen(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: cardHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 4,
                                      child: _buildCard(
                                        title: AppLocalizations.of(context)!
                                            .magbasaTitle,
                                        subtitle: AppLocalizations.of(context)!
                                            .alpabetoAtMgaSalita,
                                        imagePath: 'assets/images/card5.webp',
                                        color: AppColors.alphabet,
                                        badgeStars: magbasaBadge,
                                        onTap: () {
                                          if (_isLocked('magbasa')) {
                                            return _showLockedMessage();
                                          }
                                          context.pushPremium(
                                            const MagbasaScreen(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 5,
                                      child: _buildCard(
                                        title: AppLocalizations.of(context)!
                                            .tandaanTitle,
                                        subtitle: AppLocalizations.of(context)!
                                            .tandaanSubtitle,
                                        color: AppColors.shapes,
                                        badgeStars: tandaanBadge,
                                        onTap: () {
                                          if (_isLocked('tandaan')) {
                                            return _showLockedMessage();
                                          }
                                          context.pushPremium(
                                            const TandaanScreen(),
                                          );
                                        },
                                        child: _buildTandaanThumbnail(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Modern Bottom Navigation Bar
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        items: [
          NavItemData(
            icon: LucideIcons.house,
            label: AppLocalizations.of(context)!.home,
            color: AppColors.navHome,
            assetPath: 'assets/images/home.webp',
          ),
          NavItemData(
            icon: LucideIcons.book_open,
            label: AppLocalizations.of(context)!.lessons,
            color: AppColors.navLessons,
            assetPath: 'assets/images/aral.webp',
          ),
          NavItemData(
            icon: LucideIcons.trophy,
            label: AppLocalizations.of(context)!.awards,
            color: AppColors.navAwards,
            assetPath: 'assets/images/gantimpala.webp',
          ),
          NavItemData(
            icon: LucideIcons.settings,
            label: AppLocalizations.of(context)!.settings,
            color: AppColors.navSettings,
            assetPath: 'assets/images/setting.webp',
          ),
        ],
      ),
    );
  }

  /// True when the developer dashboard has locked this module for
  /// everyone. Checked right before navigating, same as the identical
  /// guard in lessons_screen.dart's own module cards — this screen has its
  /// own separate set of the same six cards, so a lock has to be enforced
  /// here too or the home screen's shortcuts open a "locked" module anyway.
  bool _isLocked(String moduleKey) =>
      Provider.of<UserProvider>(context, listen: false)
          .lockedModules
          .contains(moduleKey);

  void _showLockedMessage() {
    showLockedModuleDialog(context);
  }

  /// A module card: the picture on a tinted panel, its name under it.
  ///
  /// [imagePath] draws a picture; [child] draws a widget in the same place,
  /// for the one module whose thumbnail is generated rather than uploaded.
  /// Exactly one of them is given.
  Widget _buildCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? imagePath,
    Widget? child,
    int badgeStars = 0,
  }) {
    assert(imagePath != null || child != null);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          // Paler and thinner than it was. At 3 pixels of 60% colour the
          // outline was competing with the picture inside it, and six of them
          // on one screen read as six boxes rather than six things to do.
          border: Border.all(color: color.withOpacity(0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(builder: (_, box) {
          // Every size below is a fraction of the card, so the proportions
          // hold from a small phone to a tablet instead of only on the one
          // handset they were typed for.
          final h = box.maxHeight;

          return Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imagePath != null) ...[
                      Container(color: color.withOpacity(0.16)),
                      // Faint stars behind the picture, as the reference has.
                      // Low contrast on purpose: this is texture on the panel,
                      // and anything brighter would compete with the picture.
                      Positioned.fill(
                          child: CustomPaint(painter: _PanelStars())),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    ] else
                      child!,
                    if (badgeStars > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _cardStars(badgeStars, color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: h * 0.235,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: h * 0.095,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: _darken(color),
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: h * 0.068,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          // Grey, not the module's colour. Two coloured
                          // lines of different weights read as one block
                          // of colour; grey lets the name come first.
                          color: const Color(0xFF6B7688),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildTandaanThumbnail() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft mint gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F7FA), Color(0xFFB2DFDB)],
            ),
          ),
        ),
        // Decorative soft circles
        Positioned(
          top: -20,
          left: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.shapes.withOpacity(0.12),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.animals.withOpacity(0.12),
            ),
          ),
        ),
        Positioned(
          top: 30,
          right: 20,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.colors.withOpacity(0.15),
            ),
          ),
        ),
        // Floating memory cards
        Center(
          child: Transform.rotate(
            angle: -0.15,
            child: _thumbCard(
              color: AppColors.shapes,
              child: const Icon(LucideIcons.circle_question_mark,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        Positioned(
          left: 38,
          top: 42,
          child: Transform.rotate(
            angle: 0.12,
            child: _thumbCard(
              color: AppColors.animals,
              child: const Text('🐶', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
        Positioned(
          right: 36,
          top: 38,
          child: Transform.rotate(
            angle: -0.08,
            child: _thumbCard(
              color: AppColors.colors,
              child: const Text('🍎', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
        Positioned(
          left: 52,
          bottom: 44,
          child: Transform.rotate(
            angle: 0.18,
            child: _thumbCard(
              color: AppColors.alphabet,
              child: const Text('Aa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ),
          ),
        ),
        Positioned(
          right: 48,
          bottom: 40,
          child: Transform.rotate(
            angle: -0.1,
            child: _thumbCard(
              color: AppColors.primary.withOpacity(0.7),
              child: const Icon(LucideIcons.circle_question_mark,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
        // Sparkles
        Positioned(
          top: 50,
          left: 28,
          child: _sparkle(Colors.amber),
        ),
        Positioned(
          bottom: 55,
          right: 22,
          child: _sparkle(AppColors.shapes),
        ),
      ],
    );
  }

  Widget _thumbCard({required Color color, required Widget child}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }

  Widget _sparkle(Color color) {
    return Icon(LucideIcons.sparkles, color: color.withOpacity(0.5), size: 14);
  }

  /// Up to three stars on a module card.
  ///
  /// Three because three is a number this age can hold in their head, and
  /// because the empty ones say "there is more here" without a word.
  Widget _cardStars(int filled, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final got = i < filled;
          return Icon(
            got ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 13,
            color: got ? const Color(0xFFFFB800) : Colors.grey.shade300,
          );
        }),
      ),
    );
  }

  Color _darken(Color c, [double amount = 0.3]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _buildHomeAvatar(String avatar, String userName) {
    if (avatar.startsWith('http')) {
      return CachedAvatar(imageUrl: avatar, size: 50);
    }
    if (avatar.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          avatarAssetForPreset(avatar),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'N';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PLAYFUL BEACH-STYLE BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────
class _PlayfulBackground extends StatelessWidget {
  const _PlayfulBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_home.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// The scattering of faint stars on a module card's picture panel.
///
/// Drawn rather than placed as icons so it costs nothing per card and the
/// stars keep their positions in proportion however wide the panel ends up.
/// Kept at low contrast on purpose: this is the texture of the panel, and
/// anything brighter would compete with the picture sitting on it.
class _PanelStars extends CustomPainter {
  /// x, y and radius, all as fractions of the panel.
  static const List<List<double>> _spots = [
    [0.12, 0.16, 0.055],
    [0.86, 0.13, 0.075],
    [0.90, 0.78, 0.048],
    [0.16, 0.84, 0.040],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
    final unit = size.shortestSide;
    for (final s in _spots) {
      _star(canvas, paint, Offset(size.width * s[0], size.height * s[1]),
          unit * s[2]);
    }
  }

  void _star(Canvas canvas, Paint paint, Offset centre, double r) {
    // Five points, with the inner radius a little under half the outer so
    // they stay plump rather than spidery at this size.
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * 0.46;
      // Quarter turn back, so a point sits at the top.
      final angle = -math.pi / 2 + i * math.pi / points;
      final p = Offset(centre.dx + radius * math.cos(angle),
          centre.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PanelStars old) => false;
}
