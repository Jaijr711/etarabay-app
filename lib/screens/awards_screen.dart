import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/badge_catalog.dart';
import '../widgets/badge_emblem.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/staggered_entrance.dart';
import '../utils/page_transitions.dart';
import 'lessons_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class AwardsScreen extends StatelessWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final achievements = userProvider.userProfile?.achievements ?? {};
    final claimed = userProvider.collectedBadgeIds;
    final loc = AppLocalizations.of(context)!;
    // Drives the "23 / 26" readout on badges that aren't earned yet — for a
    // young child "three more" is a far stronger reason to come back than any
    // number of points.
    final badgeProgress = userProvider.badgeProgressSnapshot();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      extendBody: true,
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          switch (index) {
            case 0:
              context.pushReplacementFadeThrough(const HomeScreen());
              break;
            case 1:
              context.pushReplacementFadeThrough(const LessonsScreen());
              break;
            case 3:
              context.pushReplacementFadeThrough(const SettingsScreen());
              break;
          }
        },
        items: [
          NavItemData(
              icon: LucideIcons.house,
              label: loc.home,
              color: AppColors.navHome,
              assetPath: 'assets/images/home.png'),
          NavItemData(
              icon: LucideIcons.book_open,
              label: loc.lessons,
              color: AppColors.navLessons,
              assetPath: 'assets/images/aral.png'),
          NavItemData(
              icon: LucideIcons.trophy,
              label: loc.awards,
              color: AppColors.navAwards,
              assetPath: 'assets/images/gantimpala.png'),
          NavItemData(
              icon: LucideIcons.settings,
              label: loc.settings,
              color: AppColors.navSettings,
              assetPath: 'assets/images/setting.png'),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_awards.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StaggeredEntrance(
                  index: 0,
                  child: _buildHeader(
                      context, achievements.length, claimed.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badge = _allBadges[index];
                      // 1, 2 or 3 stars on the ring — the same int the
                      // award check writes.
                      final tier = achievements[badge['id']] ?? 0;
                      final isEarned = tier >= 1;
                      final isClaimed = claimed.contains(badge['id']);
                      return StaggeredEntrance(
                        index: index + 1,
                        child: _buildBadgeCard(
                          context,
                          badge: badge,
                          isEarned: isEarned,
                          tier: tier,
                          isClaimed: isClaimed,
                          progress: badgeProgress[badge['id']],
                          userProvider: userProvider,
                        ),
                      );
                    },
                    childCount: _allBadges.length,
                  ),
                ),
              ),
              // Room for the floating bar to sit over nothing.
              //
              // The bar is drawn above the content, not beside it, so the
              // list has to stop short of it. At 40 the last row of medals
              // was half under the pill — and the last row is where the
              // newest, most interesting badge tends to be.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Display data for the badge grid, derived from the shared catalog so the
  /// grid can never show a different symbol or colour than the one the award
  /// logic actually uses.
  static final List<Map<String, dynamic>> _allBadges = [
    for (final def in badgeCatalog)
      {
        'id': def.id,
        'icon': def.icon,
        'color': def.color,
      },
  ];

  String _badgeTitle(BuildContext context, String id) {
    final loc = AppLocalizations.of(context)!;
    switch (id) {
      case 'firstSteps':
        return loc.badgeFirstStepsTitle;
      case 'alphabet':
        return loc.badgeAlphabetTitle;
      case 'numbers':
        return loc.badgeNumbersTitle;
      case 'colors':
        return loc.badgeColorsTitle;
      case 'shapes':
        return loc.badgeShapesTitle;
      case 'animals':
        return loc.badgeAnimalsTitle;
      case 'bookworm':
        return loc.badgeBookwormTitle;
      case 'starStudent':
        return loc.badgeStarStudentTitle;
      case 'mathWhiz':
        return loc.badgeMathWhizTitle;
      case 'familyHero':
        return loc.badgeFamilyHeroTitle;
      case 'writingStar':
        return loc.badgeWritingStarTitle;
      case 'songbird':
        return loc.badgeSongbirdTitle;
      case 'streakFive':
        return loc.badgeStreakFiveTitle;
      default:
        return '';
    }
  }

  String _badgeHint(BuildContext context, String id) {
    final loc = AppLocalizations.of(context)!;
    switch (id) {
      case 'firstSteps':
        return loc.badgeFirstStepsHint;
      case 'alphabet':
        return loc.badgeAlphabetHint;
      case 'numbers':
        return loc.badgeNumbersHint;
      case 'colors':
        return loc.badgeColorsHint;
      case 'shapes':
        return loc.badgeShapesHint;
      case 'animals':
        return loc.badgeAnimalsHint;
      case 'bookworm':
        return loc.badgeBookwormHint;
      case 'starStudent':
        return loc.badgeStarStudentHint;
      case 'mathWhiz':
        return loc.badgeMathWhizHint;
      case 'familyHero':
        return loc.badgeFamilyHeroHint;
      case 'writingStar':
        return loc.badgeWritingStarHint;
      case 'songbird':
        return loc.badgeSongbirdHint;
      case 'streakFive':
        return loc.badgeStreakFiveHint;
      default:
        return '';
    }
  }

  Widget _buildHeader(BuildContext context, int earned, int claimed) {
    final loc = AppLocalizations.of(context)!;
    final headerContent = Container(
      // Was 50 above the title, on top of whatever the SafeArea already
      // reserved for the notch — a band of empty green taller than the title
      // it was making room for.
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, AppColors.success.withOpacity(0.85)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                loc.awards,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final progressSection = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // A trophy here, above a wall of medals. The medal is what
                // this screen is about, so the count wears one.
                const BadgeEmblem(
                  icon: Icons.emoji_events_rounded,
                  color: Color(0xFFFFC542),
                  size: 34,
                ),
                const SizedBox(width: 10),
                // Just how many they have. The "/ 13" is gone: the bar beside
                // it already shows how much of the wall is filled, and 13 is
                // past what a daycare child counts — the fraction only made
                // the number they *can* read harder to find.
                Text(
                  '$claimed',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: claimed / _allBadges.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerContent,
        progressSection,
        // A medal is waiting to be taken.
        //
        // This was 12-pixel grey text — the smallest thing on the screen,
        // saying the most important thing on it. A child who cannot read it
        // had no way of knowing a prize was sitting there. Now it is the
        // brightest strip on the page, and it carries a medal so the message
        // survives without the sentence.
        if (earned > claimed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6DC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD980), width: 2),
              ),
              child: Row(
                children: [
                  const BadgeEmblem(
                    icon: Icons.card_giftcard_rounded,
                    color: Color(0xFFFFB800),
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.awardsWaiting(earned, earned - claimed),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A6A12),
                      ),
                    ),
                  ),
                  // How many are waiting, as dots they can count.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      (earned - claimed).clamp(1, 5),
                      (_) => const Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Icon(Icons.circle,
                            size: 10, color: Color(0xFFFFB800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgeCard(
    BuildContext context, {
    required Map<String, dynamic> badge,
    required bool isEarned,
    required int tier,
    required bool isClaimed,
    required BadgeProgress? progress,
    required UserProvider userProvider,
  }) {
    final color = Color(badge['color'] as int);
    final loc = AppLocalizations.of(context)!;

    if (!isEarned) {
      // A locked badge still shows how close the child is. Started work is
      // visible progress, not a blank lock.
      final started = progress != null && progress.current > 0;
      return GestureDetector(
        // The card had no answer to "how do I get this one?". The sentence
        // that answers it existed all along — every badge has a translated
        // hint — but it was only drawn for badges with no progress rule to
        // show, which is none of them. It could not simply be added to the
        // card either: at two columns the tile holds the emblem, a title that
        // wraps to two lines in Tagalog, a bar and three stars with about
        // thirty pixels to spare. So the card asks, and the tap answers.
        onTap: () => _showHowToEarnDialog(context, badge, progress),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: started
                ? Border.all(color: color.withOpacity(0.35), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // The mark that says the card will answer if you press it.
              //
              // It sits on the emblem rather than under the title because
              // there is no room under the title: the tile is already holding
              // a name that wraps to two lines, a bar and three stars. A
              // tappable card with nothing to say it is tappable is a feature
              // nobody finds.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: started
                          ? color.withOpacity(0.12)
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: started
                          ? BadgeEmblem(
                              icon: badge['icon'] as IconData,
                              color: color,
                              size: 54,
                              locked: true,
                            )
                          : const Icon(LucideIcons.lock,
                              color: Colors.grey, size: 28),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _badgeTitle(context, badge['id'] as String),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: started ? AppColors.textDark : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 5),
                // Marked with a star, because that is exactly what the number
                // is: the stars this badge needs, in the same currency the
                // dashboard counts. Without the star it read as "12 of 21
                // somethings", and the child had no way to know what to go and
                // do about it.
                // Was "9 / 21". The bar above already shows the proportion,
                // so the digits were saying it a second time in a form this age
                // cannot read. Three stars say the same thing countably.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final got = progress.fraction * 3 > i;
                    return Icon(
                      got ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 17,
                      color:
                          got ? const Color(0xFFFFB800) : Colors.grey.shade300,
                    );
                  }),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _badgeHint(context, badge['id'] as String),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (isEarned && !isClaimed) {
      return GestureDetector(
        onTap: () => _showClaimDialog(context, badge, userProvider, tier),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  BadgeEmblem(
                    icon: badge['icon'] as IconData,
                    color: color,
                    size: 62,
                    tier: tier,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _badgeTitle(context, badge['id'] as String),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // A real button, not a hint.
              //
              // This used to be an 11px pill reading "tap to claim" — the
              // smallest text on the card, on a card that looks finished
              // already. A child who has just earned a badge should not have
              // to work out that the card is a button; the button should be
              // the loudest thing on it.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _showClaimDialog(context, badge, userProvider, tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: color.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.claimBadgeButton,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showViewBadgeModal(context, badge),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BadgeEmblem(
                    icon: badge['icon'] as IconData,
                    color: const Color(0xFFFFC542),
                    size: 62,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _badgeTitle(context, badge['id'] as String),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClaimDialog(BuildContext context, Map<String, dynamic> badge,
      UserProvider userProvider, int tier) {
    final color = Color(badge['color'] as int);
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsAlignment: MainAxisAlignment.center,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeEmblem(
              icon: badge['icon'] as IconData,
              color: color,
              size: 88,
              tier: tier,
            ),
            const SizedBox(height: 16),
            Text(
              loc.claimBadge(_badgeTitle(context, badge['id'] as String)),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              loc.claimBadgeBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await userProvider.claimBadge(badge['id'] as String);
              if (context.mounted) {
                Navigator.pop(context);
                _showViewBadgeModal(context, badge);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(loc.claimBadgeButton),
          ),
        ],
      ),
    );
  }

  /// What this badge is for, and how far along the child is.
  ///
  /// Opened by tapping a badge that has not been won yet. The heading is the
  /// badge's own name and the line under it is the hint — one plain sentence
  /// of what to go and do. Under that, the same progress the card shows, plus
  /// the count in figures: the card deliberately leaves those out because a
  /// four-year-old cannot read them, but this card is the one a teacher or a
  /// parent opens to find out what is left.
  void _showHowToEarnDialog(
    BuildContext context,
    Map<String, dynamic> badge,
    BadgeProgress? progress,
  ) {
    final color = Color(badge['color'] as int);
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: BadgeEmblem(
                    icon: badge['icon'] as IconData,
                    color: color,
                    size: 84,
                    locked: true,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _badgeTitle(context, badge['id'] as String),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              // The whole point of this card.
              Text(
                _badgeHint(context, badge['id'] as String),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.current}/${progress.target}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.okButton,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewBadgeModal(BuildContext context, Map<String, dynamic> badge) {
    final color = Color(badge['color'] as int);
    final loc = AppLocalizations.of(context)!;
    // A deeper relative of the badge's colour. A light badge (the amber
    // About Me one) left white words, an amber pill and a gold medal all on
    // yellow, where none of them could be read; the card now darkens towards
    // its foot and the pill, medal and button sit on white instead.
    final hsl = HSLColor.fromColor(color);
    final deep =
        hsl.withLightness((hsl.lightness - 0.16).clamp(0.12, 1.0)).toColor();
    final ink =
        hsl.withLightness((hsl.lightness - 0.26).clamp(0.10, 1.0)).toColor();
    final wordShadow = [
      Shadow(
        color: Colors.black.withOpacity(0.28),
        offset: const Offset(0, 2),
        blurRadius: 3,
      ),
    ];
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, deep],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: deep.withOpacity(0.45),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loc.badgeClaimed,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: ink,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // The moment the badge is won, at the size it deserves — on
                // a white halo, so the gold medal stands off any card colour.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: BadgeEmblem(
                    icon: badge['icon'] as IconData,
                    color: const Color(0xFFFFC542),
                    size: 118,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _badgeTitle(context, badge['id'] as String),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: wordShadow,
                  ),
                ),
                const SizedBox(height: 12),
                // What this one was for. The same sentence the locked card
                // shows before it is won — a child holding a medal should be
                // able to be told what they did to get it.
                Text(
                  _badgeHint(context, badge['id'] as String),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: wordShadow,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: Text(
                      loc.awesome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
