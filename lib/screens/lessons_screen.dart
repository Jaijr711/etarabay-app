import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
import '../widgets/custom_header_app_bar.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/locked_module_dialog.dart';
import '../widgets/staggered_entrance.dart';
import '../utils/page_transitions.dart';
import 'awards_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

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
  int _pamilyaTotal = 5;

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
    final pamilyaTotal = pamilya['totalLevels'] ?? 5;

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

  @override
  Widget build(BuildContext context) {
    // Render immediately (no full-screen spinner). Progress fields start at 0
    // and update silently once _loadProgress finishes, avoiding a jarring
    // spinner flash during page transitions.
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: CustomHeaderAppBar(
        title: AppLocalizations.of(context)!.lessons,
        baseColor: AppColors.primary,
        showBackButton: false,
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
            assetPath: 'assets/images/home.png',
          ),
          NavItemData(
            icon: LucideIcons.book_open,
            label: AppLocalizations.of(context)!.lessons,
            color: AppColors.navLessons,
            assetPath: 'assets/images/aral.png',
          ),
          NavItemData(
            icon: LucideIcons.trophy,
            label: AppLocalizations.of(context)!.awards,
            color: AppColors.navAwards,
            assetPath: 'assets/images/gantimpala.png',
          ),
          NavItemData(
            icon: LucideIcons.settings,
            label: AppLocalizations.of(context)!.settings,
            color: AppColors.navSettings,
            assetPath: 'assets/images/setting.png',
          ),
        ],
      ),
      body: Stack(
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
                const SizedBox(height: 20),
                StaggeredEntrance(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          context, AppLocalizations.of(context)!.matematika),
                      _buildMatematikaCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredEntrance(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context,
                          AppLocalizations.of(context)!.angAkingSariliTitle),
                      _buildPamilyaCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredEntrance(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          context, AppLocalizations.of(context)!.kulaySaya),
                      _buildKulayCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredEntrance(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          context, AppLocalizations.of(context)!.traceItTitle),
                      _buildTraceItCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredEntrance(
                  index: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          context, AppLocalizations.of(context)!.magbasaTitle),
                      _buildMagbasaCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredEntrance(
                  index: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          context, AppLocalizations.of(context)!.tandaanTitle),
                      _buildTandaanCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: _overallProgress.clamp(0.0, 1.0),
                    strokeWidth: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _overallProgress >= 1.0
                          ? const Color(0xFF34C759)
                          : AppColors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // The number inside the ring used to read "56%". The ring
                // already says it, in a form a child can see rather than
                // read, so what sits in the middle is a star instead — the
                // thing they are actually collecting.
                Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: _overallProgress >= 1.0
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFFB800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.overallProgress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                // "23/150 completed" became five stars.
                //
                // Five is at the top of what this age counts, so a full row
                // is a finish line they can see coming. The fraction was two
                // numbers, one of them 150 — a figure with no meaning to a
                // three-year-old beyond "a lot".
                Row(
                  children: List.generate(5, (i) {
                    final got = _overallProgress * 5 > i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(
                        got ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 24,
                        color: got
                            ? const Color(0xFFFFB800)
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Section title
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
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

  Widget _buildMatematikaCard(BuildContext context) {
    return _buildLessonCard(
      context: context,
      title: AppLocalizations.of(context)!.matematika,
      subtitle:
          '$_matDone/$_matTotal ${AppLocalizations.of(context)!.activities}',
      imagePath: 'assets/images/card1.png',
      color: AppColors.numbers,
      progress: _matTotal > 0 ? _matDone / _matTotal : 0.0,
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
      subtitle:
          '$_pamilyaDone/$_pamilyaTotal ${AppLocalizations.of(context)!.levels}',
      imagePath: 'assets/images/card2.png',
      color: AppColors.family,
      progress: _pamilyaTotal > 0 ? _pamilyaDone / _pamilyaTotal : 0.0,
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
      subtitle:
          '$_kulayDone/$_kulayTotal ${AppLocalizations.of(context)!.activities}',
      imagePath: 'assets/images/card3.png',
      color: AppColors.colors,
      progress: _kulayTotal > 0 ? _kulayDone / _kulayTotal : 0.0,
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
      subtitle:
          '$_traceItDone/$_traceItTotal ${AppLocalizations.of(context)!.activities}',
      imagePath: 'assets/images/card4.png',
      color: AppColors.success,
      progress: _traceItTotal > 0 ? _traceItDone / _traceItTotal : 0.0,
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
      subtitle:
          '$_magbasaDone/$_magbasaTotal ${AppLocalizations.of(context)!.activities}',
      imagePath: 'assets/images/card5.png',
      color: AppColors.alphabet,
      progress: _magbasaTotal > 0 ? _magbasaDone / _magbasaTotal : 0.0,
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
      subtitle:
          '$_tandaanDone/$_tandaanTotal ${AppLocalizations.of(context)!.activities}',
      imagePath: 'assets/images/intro4.png',
      color: AppColors.shapes,
      progress: _tandaanTotal > 0 ? _tandaanDone / _tandaanTotal : 0.0,
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 44),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.lessonFinishedPrompt,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              onReplay();
            },
            icon: const Icon(LucideIcons.rotate_ccw, size: 20),
            label: Text(AppLocalizations.of(context)!.ulitin,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.okButton,
                style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required double progress,
    required VoidCallback onTap,
  }) {
    final bool isCompleted = progress >= 0.999; // Using float margin

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: isCompleted ? () => _showCompletedDialog(title, onTap) : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Big friendly picture instead of a small line icon —
                  // daycare kids recognize the game by its picture.
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isCompleted ? Colors.green : color)
                          .withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (isCompleted ? Colors.green : color)
                            .withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(LucideIcons.sparkles, color: color, size: 34),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade700
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Was the Tagalog "TAPOS NA!" typed into the
                          // code, so it stayed Tagalog in English and in
                          // Ilokano. The app already has this sentence.
                          isCompleted
                              ? AppLocalizations.of(context)!.finishedAlready
                              : subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCompleted
                                ? Colors.green
                                : Colors.grey.shade600,
                            fontWeight: isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFBEB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 26,
                      ),
                    )
                  else
                    Icon(
                      LucideIcons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : color),
                  // Thick enough to read across the room. This bar is the
                  // only thing on the card that says how far along they are.
                  minHeight: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
