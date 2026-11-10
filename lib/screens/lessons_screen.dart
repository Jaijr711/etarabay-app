import 'dart:ui' show ImageFilter;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../widgets/replay_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'matematika_screen.dart';
import 'pamilya_screen.dart';
import 'kulay_screen.dart';
import 'trace_it_screen.dart';
import 'magbasa_screen.dart';
import 'tandaan_screen.dart';
import '../widgets/kid_page_header.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/locked_module_dialog.dart';
import '../widgets/staggered_entrance.dart';
import '../utils/page_transitions.dart';
import 'awards_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import '../widgets/design_scale.dart';
import '../services/device_performance.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SharedPreferences key helpers — must match each feature screen exactly
// ─────────────────────────────────────────────────────────────────────────────

class _KulayKeys {
  static String pageKey(String cat, int i) => 'kulay_page_${cat}_$i';
}

class _MagbasaKeys {
  static String activityKey(String cat, int i) => '${cat}_activity_$i';
}

class _MatematikaKeys {
  static String levelKey(int level, int game) =>
      'mat_level_${level}_game_$game';
}

// ─────────────────────────────────────────────────────────────────────────────
//  LESSONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> with RouteAware {
  // ── Trace It progress ──────────────────────────────────────────────────────
  static const List<String> _allUpper = [
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
  static const List<String> _allLower = [
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
  static const List<String> _allNums = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];
  // ── Trace It progress ──────────────────────────────────────────────────────
  int _traceItDone = 0;
  final int _traceItTotal = 62; // 26 + 26 + 10

  // ── Kulay progress ─────────────────────────────────────────────────────────
  static const Map<String, int> _kulayTotals = {
    'Animals': 3,
    'Flowers': 2,
    'Fruits': 2,
    'Toys': 2,
  };
  int _kulayDone = 0;
  final int _kulayTotal = 9; // 3+2+2+2

  // ── Magbasa progress ───────────────────────────────────────────────────────
  static const Map<String, int> _magbasaTotals = {
    'tula': 5,
    'kwento': 5,
    'kanta': 9,
  };
  int _magbasaDone = 0;
  final int _magbasaTotal = 19; // 5+5+9

  // ── Matematika progress ────────────────────────────────────────────────────
  // The one table, in UserProvider. This screen kept its own copy of it, so
  // three new levels would have left the child's lesson list saying "31 of
  // 31" while fifteen questions sat unplayed underneath.
  static const List<int> _matGameCounts = UserProvider.matematikaGamesPerLevel;
  int _matDone = 0;
  final int _matTotal = UserProvider.matematikaGameCount;

  // ── Tandaan progress ───────────────────────────────────────────────────
  int _tandaanDone = 0;
  final int _tandaanTotal = 12; // 4 categories × 3 rounds

  // ── Pamilya progress (still from UserProvider) ────────────────────────────
  int _pamilyaDone = 0;
  int _pamilyaTotal = UserProvider.pamilyaLevelCount;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // Reload whenever the screen comes back into focus (e.g. after playing a game)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called automatically when returning to this page from a pushed route.
  @override
  void didPopNext() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Trace It ───────────────────────────────────────────────────────────────
    int traceItCount = 0;
    for (final l in _allUpper) {
      if (prefs.getBool('traceit_upper_$l') == true) traceItCount++;
    }
    for (final l in _allLower) {
      if (prefs.getBool('traceit_lower_$l') == true) traceItCount++;
    }
    for (final n in _allNums) {
      if (prefs.getBool('traceit_num_$n') == true) traceItCount++;
    }

    // ── Kulay ────────────────────────────────────────────────────────────────
    int kulayCount = 0;
    for (final cat in _kulayTotals.keys) {
      final total = _kulayTotals[cat]!;
      for (int i = 0; i < total; i++) {
        if (prefs.getBool(_KulayKeys.pageKey(cat, i)) == true) kulayCount++;
      }
    }

    // ── Magbasa ──────────────────────────────────────────────────────────────
    int magbasaCount = 0;
    for (final cat in _magbasaTotals.keys) {
      final total = _magbasaTotals[cat]!;
      for (int i = 0; i < total; i++) {
        if (prefs.getBool(_MagbasaKeys.activityKey(cat, i)) == true) {
          magbasaCount++;
        }
      }
    }

    // ── Matematika ───────────────────────────────────────────────────────────
    int matCount = 0;
    for (int lvl = 0; lvl < _matGameCounts.length; lvl++) {
      for (int g = 0; g < _matGameCounts[lvl]; g++) {
        if (prefs.getBool(_MatematikaKeys.levelKey(lvl, g)) == true) matCount++;
      }
    }

    // ── Tandaan ────────────────────────────────────────────────────────────────
    int tandaanCount = 0;
    for (int cat = 0; cat < 4; cat++) {
      for (int round = 0; round < 3; round++) {
        if (prefs.getBool('tandaan_cat_${cat}_round_$round') == true) {
          tandaanCount++;
        }
      }
    }

    // ── Pamilya (from UserProvider) ───────────────────────────────────────────
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final providerProgress = userProvider.getAllProgress();
    final pamilya = providerProgress['pamilya'] as Map? ?? {};
    final pamilyaDone = pamilya['completedLevels'] ?? 0;
    final pamilyaTotal =
        pamilya['totalLevels'] ?? UserProvider.pamilyaLevelCount;

    setState(() {
      _traceItDone = traceItCount;
      _kulayDone = kulayCount;
      _magbasaDone = magbasaCount;
      _matDone = matCount;
      _tandaanDone = tandaanCount;
      _pamilyaDone = pamilyaDone;
      _pamilyaTotal = pamilyaTotal;
    });
  }

  // ── Totals for header ───────────────────────────────────────────────────────
  int get _totalCompleted =>
      _traceItDone +
      _kulayDone +
      _magbasaDone +
      _matDone +
      _tandaanDone +
      _pamilyaDone;

  int get _totalActivities =>
      _traceItTotal +
      _kulayTotal +
      _magbasaTotal +
      _matTotal +
      _tandaanTotal +
      _pamilyaTotal;

  double get _overallProgress =>
      _totalActivities > 0 ? _totalCompleted / _totalActivities : 0.0;

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  /// [UserProvider.progressVersion] when the counts were last read.
  int? _seenProgressVersion;

  @override
  Widget build(BuildContext context) {
    // Progress that arrives from the cloud after this screen opened, and a
    // module locked or unlocked meanwhile, both show without reopening it.
    final (version, _) = context.select<UserProvider, (int, int)>(
        (p) => (p.progressVersion, p.lockedModules.length));
    _seenProgressVersion ??= version;
    if (version != _seenProgressVersion) {
      _seenProgressVersion = version;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProgress();
      });
    }
    // Render immediately (no full-screen spinner). Progress fields start at 0
    // and update silently once _loadProgress finishes, avoiding a jarring
    // spinner flash during page transitions.
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: KidPageHeader(
        title: AppLocalizations.of(context)!.lessons,
        // The same count as the five stars under the ring.
        subtitle: AppLocalizations.of(context)!
            .kidSubLessons((_overallProgress * 5).ceil().clamp(0, 5)),
        bubble: AppLocalizations.of(context)!.kidBubbleLessons,
        color: AppColors.navLessons,
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          switch (index) {
            case 0:
              context.pushReplacementFadeThrough(const HomeScreen());
              break;
            case 2:
              context.pushReplacementFadeThrough(const AwardsScreen());
              break;
            case 3:
              context.pushReplacementFadeThrough(const SettingsScreen());
              break;
          }
        },
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
            badgeCount: context.watch<UserProvider>().waitingBadgeCount,
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
      body: DesignScale(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_lesson.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // A static translucent overlay instead of a live BackdropFilter
            // blur. The real-time blur re-rendered every frame caused noticeable
            // lag (especially during page transitions); this keeps a soft,
            // readable backdrop at a fraction of the cost.
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.55)),
            ),
            SingleChildScrollView(
              // Extra bottom padding so the last card isn't hidden behind the
              // floating bottom navigation bar (body uses extendBody: true).
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 120 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaggeredEntrance(
                    index: 0,
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 18),
                  StaggeredEntrance(
                    index: 1,
                    child: _buildMatematikaCard(context),
                  ),
                  const SizedBox(height: 18),
                  StaggeredEntrance(
                    index: 2,
                    child: _buildPamilyaCard(context),
                  ),
                  const SizedBox(height: 18),
                  StaggeredEntrance(
                    index: 3,
                    child: _buildKulayCard(context),
                  ),
                  const SizedBox(height: 18),
                  StaggeredEntrance(
                    index: 4,
                    child: _buildTraceItCard(context),
                  ),
                  const SizedBox(height: 18),
                  StaggeredEntrance(
                    index: 5,
                    child: _buildMagbasaCard(context),
                  ),
                  const SizedBox(height: 18),
                  StaggeredEntrance(
                    index: 6,
                    child: _buildTandaanCard(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final done = _overallProgress >= 1.0;
    final value = _overallProgress.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14503A).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/badges/trophy.webp',
              width: 40, height: 40, excludeFromSemantics: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.overallProgress,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6EEE9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                colors: done
                                    ? const [
                                        Color(0xFF34C759),
                                        Color(0xFF6EDC8C)
                                      ]
                                    : const [
                                        Color(0xFF2E9E5B),
                                        Color(0xFF5CCB8A)
                                      ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Five stars, the most this age counts: a full row is a
                    // finish line they can see coming.
                    for (var i = 0; i < 5; i++)
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: _overallProgress * 5 > i
                            ? const Color(0xFFFFB800)
                            : const Color(0xFFDDE1E7),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Individual lesson cards
  // ─────────────────────────────────────────────────────────────────────────

  /// True when the developer dashboard has locked this module for
  /// everyone. Checked right before navigating, not just once at build
  /// time, so a lock applied while this screen is already open still
  /// stops the next tap.
  bool _isLocked(String moduleKey) =>
      Provider.of<UserProvider>(context, listen: false)
          .lockedModules
          .contains(moduleKey);

  void _showLockedMessage() {
    showLockedModuleDialog(context);
  }

  /// The first lesson, in the order shown, that has been started and not
  /// finished: its card is ringed, so a child coming back sees where they
  /// left off.
  String? get _currentModuleKey {
    for (final (key, done, total) in [
      ('matematika', _matDone, _matTotal),
      ('pamilya', _pamilyaDone, _pamilyaTotal),
      ('kulay', _kulayDone, _kulayTotal),
      ('traceit', _traceItDone, _traceItTotal),
      ('magbasa', _magbasaDone, _magbasaTotal),
      ('tandaan', _tandaanDone, _tandaanTotal),
    ]) {
      if (done > 0 && done < total && !_isLocked(key)) return key;
    }
    return null;
  }

  Widget _buildMatematikaCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.matematika,
      subtitle:
          AppLocalizations.of(context)!.lessonActivities(_matDone, _matTotal),
      imagePath: 'assets/images/card1.webp',
      color: AppColors.numbers,
      progress: _matTotal > 0 ? _matDone / _matTotal : 0.0,
      highlight: _currentModuleKey == 'matematika',
      locked: _isLocked('matematika'),
      onTap: () async {
        if (_isLocked('matematika')) return _showLockedMessage();
        await context.pushPremium(const MatematikaScreen());
        // Progress refreshes silently via didPopNext — no spinner flash.
        _loadProgress();
      },
    );
  }

  Widget _buildPamilyaCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.angAkingSariliTitle,
      subtitle: AppLocalizations.of(context)!
          .lessonLevels(_pamilyaDone, _pamilyaTotal),
      imagePath: 'assets/images/card2.webp',
      color: AppColors.family,
      progress: _pamilyaTotal > 0 ? _pamilyaDone / _pamilyaTotal : 0.0,
      highlight: _currentModuleKey == 'pamilya',
      locked: _isLocked('pamilya'),
      onTap: () async {
        if (_isLocked('pamilya')) return _showLockedMessage();
        await context.pushPremium(const PamilyaScreen());
        _loadProgress();
      },
    );
  }

  Widget _buildKulayCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.kulaySaya,
      subtitle: AppLocalizations.of(context)!
          .lessonActivities(_kulayDone, _kulayTotal),
      imagePath: 'assets/images/card3.webp',
      color: AppColors.colors,
      progress: _kulayTotal > 0 ? _kulayDone / _kulayTotal : 0.0,
      highlight: _currentModuleKey == 'kulay',
      locked: _isLocked('kulay'),
      onTap: () async {
        if (_isLocked('kulay')) return _showLockedMessage();
        await context.pushPremium(const KulayScreen());
        _loadProgress();
      },
    );
  }

  Widget _buildTraceItCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.traceItTitle,
      subtitle: AppLocalizations.of(context)!
          .lessonActivities(_traceItDone, _traceItTotal),
      imagePath: 'assets/images/card4.webp',
      color: AppColors.success,
      progress: _traceItTotal > 0 ? _traceItDone / _traceItTotal : 0.0,
      highlight: _currentModuleKey == 'traceit',
      locked: _isLocked('traceit'),
      onTap: () async {
        if (_isLocked('traceit')) return _showLockedMessage();
        await context.pushPremium(const TraceItScreen());
        _loadProgress();
      },
    );
  }

  Widget _buildMagbasaCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.magbasaTitle,
      subtitle: AppLocalizations.of(context)!
          .lessonActivities(_magbasaDone, _magbasaTotal),
      imagePath: 'assets/images/card5.webp',
      color: AppColors.alphabet,
      progress: _magbasaTotal > 0 ? _magbasaDone / _magbasaTotal : 0.0,
      highlight: _currentModuleKey == 'magbasa',
      locked: _isLocked('magbasa'),
      onTap: () async {
        if (_isLocked('magbasa')) return _showLockedMessage();
        await context.pushPremium(const MagbasaScreen());
        _loadProgress();
      },
    );
  }

  Widget _buildTandaanCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.tandaanTitle,
      subtitle: AppLocalizations.of(context)!
          .lessonActivities(_tandaanDone, _tandaanTotal),
      imagePath: 'assets/images/tandaan/home.webp',
      color: AppColors.shapes,
      progress: _tandaanTotal > 0 ? _tandaanDone / _tandaanTotal : 0.0,
      highlight: _currentModuleKey == 'tandaan',
      locked: _isLocked('tandaan'),
      onTap: () async {
        if (_isLocked('tandaan')) return _showLockedMessage();
        await context.pushPremium(const TandaanScreen());
        _loadProgress();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Reusable card widget
  // ─────────────────────────────────────────────────────────────────────────

  /// Celebrates a finished lesson but still lets the child back in — young
  /// children learn by repeating an activity, so completion must not lock it.
  void _showCompletedDialog(String title, VoidCallback onReplay) {
    // The same card as a finished level's "Finished already!", with the
    // lesson's name as its title.
    showLessonFinishedDialog(context, title: title, onRepeat: onReplay);
  }

  Widget _buildLessonCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required double progress,
    required VoidCallback onTap,
    bool locked = false,
    bool highlight = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    final bool isCompleted = progress >= 0.999; // Using float margin
    final tintTop = Color.lerp(color, Colors.white, 0.84)!;
    final tintBottom = Color.lerp(color, Colors.white, 0.70)!;
    final edge = Color.lerp(color, Colors.white, 0.55)!;

    // What pressing it will do, said on a button the child can see is one:
    // start, carry on, finished, or not open yet.
    final String action;
    final Color actionBg;
    final Color actionFg;
    final IconData actionIcon;
    if (locked) {
      action = loc.lessonLocked;
      actionBg = const Color(0xFFE5E7EB);
      actionFg = const Color(0xFF6B7280);
      actionIcon = Icons.lock_rounded;
    } else if (isCompleted) {
      action = loc.lessonDone;
      actionBg = const Color(0xFFFFC531);
      actionFg = const Color(0xFF7A4A00);
      actionIcon = Icons.star_rounded;
    } else {
      action = progress > 0 ? loc.lessonContinue : loc.lessonStart;
      actionBg = Color.lerp(color, Colors.black, 0.12)!;
      actionFg = Colors.white;
      actionIcon = Icons.play_arrow_rounded;
    }

    return GestureDetector(
      // Locked first: a finished module that is locked offered "Finished
      // already! Repeat" and only then said it was locked.
      onTap: locked
          ? _showLockedMessage
          : (isCompleted ? () => _showCompletedDialog(title, onTap) : onTap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.fromLTRB(14, 12, 118, 12),
            decoration: BoxDecoration(
              gradient: locked
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tintTop, tintBottom],
                    ),
              color: locked ? const Color(0xFFF3F4F6) : null,
              borderRadius: BorderRadius.circular(22),
              border: highlight ? Border.all(color: color, width: 3) : null,
              boxShadow: [
                BoxShadow(
                  color: locked
                      ? const Color(0xFFE5E7EB)
                      : highlight
                          ? Color.lerp(color, Colors.black, 0.25)!
                          : edge,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: const Color(0xFF143C28).withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    height: 1.12,
                    fontWeight: FontWeight.w600,
                    color:
                        locked ? const Color(0xFF8A93A3) : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: Colors.white.withOpacity(0.85),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? const Color(0xFF2ECC71) : color),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: actionBg,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: locked
                        ? null
                        : [
                            BoxShadow(
                              color: Color.lerp(actionBg, Colors.black, 0.3)!,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(actionIcon, size: 16, color: actionFg),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: actionFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // The picture: the same box for every lesson, on the right,
          // centred and inside the card, so they all sit alike.
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Opacity(
                  opacity: locked ? 0.45 : 1,
                  child: _lessonPicture(imagePath, color, grey: locked),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A lesson's picture with a soft shadow under it, grey when locked.
  Widget _lessonPicture(String path, Color color, {required bool grey}) {
    Widget image(ColorFilter? filter) {
      final img = Image.asset(
        path,
        width: 100,
        height: 100,
        // Decoded at the size it is shown, not the file's.
        cacheWidth: (100 * MediaQuery.devicePixelRatioOf(context) * 1.3).ceil(),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) =>
            Icon(LucideIcons.sparkles, color: color, size: 40),
      );
      return filter == null
          ? img
          : ColorFiltered(colorFilter: filter, child: img);
    }

    const greyscale = ColorFilter.matrix(<double>[
      0.33, 0.33, 0.33, 0, 0, //
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0, 0, 0, 1, 0,
    ]);
    // No blurred shadow on a phone that cannot draw it smoothly.
    if (DevicePerformance.lite.value) return image(grey ? greyscale : null);
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: image(
                const ColorFilter.mode(Color(0x33000000), BlendMode.srcIn)),
          ),
        ),
        image(grey ? greyscale : null),
      ],
    );
  }
}
