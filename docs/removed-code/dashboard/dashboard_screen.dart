import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../main.dart'; // AudioManager
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../widgets/birthday_celebration.dart';
import '../widgets/dashboard/illustration_slot.dart';
import '../widgets/dashboard/kid_bottom_nav.dart';
import '../widgets/dashboard/learning_card.dart';
import '../widgets/dashboard/profile_header.dart';
import '../widgets/dashboard/progress_card.dart';
import 'awards_screen.dart';
import 'kulay_screen.dart';
import 'lessons_screen.dart';
import 'magbasa_screen.dart';
import 'matematika_screen.dart';
import 'pamilya_screen.dart';
import 'parents_lock_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'tandaan_screen.dart';
import 'trace_it_screen.dart';

/// The child's dashboard.
///
/// Assembled from the widgets in `lib/widgets/dashboard/`, each of which takes
/// plain values rather than reaching for a provider — so a card can be dropped
/// into a preview, a test or a different screen without dragging the whole app
/// behind it. This screen is the only place that knows where the numbers come
/// from and where a tap goes.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _homeTab = 0;
  static const int _parentsTab = 2;

  int _selectedIndex = _homeTab;

  /// Set once the account-deleted dialog is up, so the guard below cannot
  /// raise a second one on the next rebuild.
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioManager.instance.startBackgroundMusic(AudioManager.homeMusicAsset);
      _checkBirthday();
    });
  }

  /// The child's birthday is the one thing this screen interrupts for.
  void _checkBirthday() {
    if (!mounted) return;
    final profile =
        Provider.of<UserProvider>(context, listen: false).userProfile;
    if (profile == null || profile.birthday == null) return;

    final now = DateTime.now();
    if (profile.birthday!.month == now.month &&
        profile.birthday!.day == now.day) {
      showBirthdayCelebration(context, name: profile.name);
    }
  }

  /// The teacher removed this student while the app was open.
  ///
  /// Carried over from the old home screen unchanged. It is the one piece of
  /// that screen that is not decoration: local progress has to be wiped here
  /// or it carries over to whoever logs in next on the same phone.
  void _showAccountDeletedDialog() {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(LucideIcons.triangle_alert,
              color: Colors.orange, size: 60),
          content: Text(
            AppLocalizations.of(context)!.accessExpired,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  await userProvider.logoutAndClearData();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (Route<dynamic> route) => false);
                },
                child: Text(AppLocalizations.of(context)!.okButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = Provider.of<UserProvider>(context);
    final profile = user.userProfile;

    if (user.isAccountDeleted && !_isLoggingOut) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAccountDeletedDialog());
    }

    if (user.isAccountDeleted && !_isLoggingOut) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAccountDeletedDialog());
    }

    final firstName = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim().split(RegExp(r'\s+')).first
        : loc.hello;

    final progress = user.getAllProgress();
    final lessonsDone = (progress['totalCompleted'] as int?) ?? 0;

    return Scaffold(
      // Sky at the top, grass at the bottom — the world the cards sit in.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBFE3FA),
              Color(0xFFE8F5FE),
              Color(0xFFEFF9F0),
            ],
            stops: [0.0, 0.34, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            children: [
              ProfileHeader(
                name: firstName,
                greeting: loc.helloName(firstName),
                subtitle: loc.letsLearnAndPlay,
                onAvatarTap: () => context.pushPremium(const ProfileScreen()),
                stats: [
                  HeaderStat(
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFFB800),
                    value: '${user.displayStars}',
                    label: loc.stars,
                  ),
                  HeaderStat(
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFF7C3AED),
                    value: '${user.collectedBadgeIds.length}',
                    label: loc.awards,
                  ),
                  HeaderStat(
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF2E9E5B),
                    value: '$lessonsDone',
                    label: loc.lessonsCount,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ProgressCard(
                title: loc.myProgressToday,
                totalSteps: 3,
                completedSteps: _pathSteps(user),
                stats: [
                  ProgressStat(
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF7C3AED),
                    value: '${progress['totalCompleted'] ?? 0}',
                    label: loc.lessonsCount,
                  ),
                  ProgressStat(
                    icon: Icons.check_rounded,
                    color: const Color(0xFF2E9E5B),
                    value: '${_activities(progress)}',
                    label: loc.activitiesCount,
                  ),
                  ProgressStat(
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFF5A623),
                    value: '${user.collectedBadgeIds.length}',
                    label: loc.rewardsCount,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IllustrationSlot(
                    icon: Icons.auto_awesome_rounded,
                    color: Color(0xFFF5A623),
                    size: 26,
                    plate: false,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.whatDoYouWantToLearn,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF11397A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const IllustrationSlot(
                    icon: Icons.auto_awesome_rounded,
                    color: Color(0xFF2C7BE5),
                    size: 26,
                    plate: false,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _LearningGrid(cards: _cards(loc)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: KidBottomNav(
        selectedIndex: _selectedIndex,
        guardedIndex: _parentsTab,
        onTap: _onNavTap,
        items: [
          KidNavItem(
              icon: Icons.home_rounded,
              label: loc.home,
              color: const Color(0xFF2C7BE5)),
          KidNavItem(
              icon: Icons.menu_book_rounded,
              label: loc.lessons,
              color: const Color(0xFF2E9E5B)),
          KidNavItem(
              icon: Icons.people_alt_rounded,
              label: loc.forParents,
              color: const Color(0xFFEC4899)),
          KidNavItem(
              icon: Icons.emoji_events_rounded,
              label: loc.awards,
              color: const Color(0xFFF5A623)),
          KidNavItem(
              icon: Icons.settings_rounded,
              label: loc.settings,
              color: const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  /// How far along the little walker stands.
  ///
  /// Three steps, because three is a number a three-year-old can hold. It
  /// follows the star total rather than a separate counter: the app does not
  /// track a day's work on its own yet, and inventing a number here would put
  /// a figure on screen that nothing else in the app agrees with.
  int _pathSteps(UserProvider user) {
    final stars = user.displayStars;
    if (stars <= 0) return 0;
    if (stars < 10) return 1;
    if (stars < 30) return 2;
    return 3;
  }

  int _activities(Map<String, dynamic> progress) {
    final kulay = progress['kulay'] as Map? ?? {};
    final traceit = progress['traceit'] as Map? ?? {};
    return ((kulay['totalCompleted'] as int?) ?? 0) +
        ((traceit['totalCompleted'] as int?) ?? 0);
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex && index == _homeTab) return;

    // Parents keeps its own route and its own lock — it is a door out of the
    // child's part of the app, not another tab, so the bar does not stay on it.
    if (index == _parentsTab) {
      context.pushPremium(const ParentsLockScreen());
      return;
    }

    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        context.pushReplacementFadeThrough(const LessonsScreen());
        break;
      case 3:
        context.pushReplacementFadeThrough(const AwardsScreen());
        break;
      case 4:
        context.pushReplacementFadeThrough(const SettingsScreen());
        break;
    }
  }

  List<_CardSpec> _cards(AppLocalizations loc) => [
        _CardSpec(
          title: loc.matematika,
          subtitle: loc.sundanMoKayaMo,
          tint: const Color(0xFFD3E9FB),
          accent: const Color(0xFF2C7BE5),
          icon: Icons.looks_one_rounded,
          open: () => context.pushPremium(const MatematikaScreen()),
        ),
        _CardSpec(
          title: loc.traceItTitle,
          subtitle: loc.traceItSubtitle,
          tint: const Color(0xFFFDF3C8),
          accent: const Color(0xFFE08A00),
          icon: Icons.abc_rounded,
          open: () => context.pushPremium(const TraceItScreen()),
        ),
        _CardSpec(
          title: loc.kulaySaya,
          subtitle: loc.magkulayTayo,
          tint: const Color(0xFFFBD9E6),
          accent: const Color(0xFFEC4899),
          icon: Icons.palette_rounded,
          open: () => context.pushPremium(const KulayScreen()),
        ),
        _CardSpec(
          title: loc.angAkingSarili.replaceAll('\n', ' '),
          subtitle: loc.atAkingPamilya,
          tint: const Color(0xFFD5EFD8),
          accent: const Color(0xFF2E9E5B),
          icon: Icons.family_restroom_rounded,
          open: () => context.pushPremium(const PamilyaScreen()),
        ),
        _CardSpec(
          title: loc.magbasaTitle,
          subtitle: loc.alpabetoAtMgaSalita,
          tint: const Color(0xFFE4D9F7),
          accent: const Color(0xFF7C3AED),
          icon: Icons.menu_book_rounded,
          open: () => context.pushPremium(const MagbasaScreen()),
        ),
        _CardSpec(
          title: loc.tandaanTitle,
          subtitle: loc.tandaanSubtitle,
          tint: const Color(0xFFD3E9FB),
          accent: const Color(0xFF1E88C7),
          icon: Icons.grid_view_rounded,
          open: () => context.pushPremium(const TandaanScreen()),
        ),
      ];
}

class _CardSpec {
  final String title;
  final String subtitle;
  final Color tint;
  final Color accent;
  final IconData icon;
  final VoidCallback open;

  const _CardSpec({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.accent,
    required this.icon,
    required this.open,
  });
}

/// Two cards across on a phone, three on anything wide enough to hold them.
class _LearningGrid extends StatelessWidget {
  final List<_CardSpec> cards;

  const _LearningGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 12.0;
        final columns = box.maxWidth >= 620 ? 3 : 2;
        final cellWidth = (box.maxWidth - gap * (columns - 1)) / columns;

        // Very nearly square, which is what makes the card read as a picture
        // with a label under it rather than as a tall card with a small
        // picture on top. Tied to the cell width rather than to the screen,
        // so the proportions hold from a small phone to a tablet.
        final cellHeight = (cellWidth * 1.06).clamp(150.0, 240.0).toDouble();

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: cellWidth / cellHeight,
          children: [
            for (final c in cards)
              LearningCard(
                title: c.title,
                subtitle: c.subtitle,
                tint: c.tint,
                accent: c.accent,
                icon: c.icon,
                onTap: c.open,
              ),
          ],
        );
      },
    );
  }
}
