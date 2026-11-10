import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../widgets/fun_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/badge_catalog.dart';
import '../widgets/badge_emblem.dart';
import 'package:provider/provider.dart';
import '../widgets/shelf_medal.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/kid_page_header.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/staggered_entrance.dart';
import '../utils/page_transitions.dart';
import 'lessons_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import '../widgets/design_scale.dart';
import '../widgets/soft_backdrop.dart';

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
      // Held at the top like Lessons and Settings, not scrolled away with the
      // medals or played in with them.
      appBar: KidPageHeader(
        title: loc.awards,
        subtitle: loc.kidSubAwards(claimed.length),
        bubble: loc.kidBubbleAwards,
        color: AppColors.navAwards,
      ),
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
              assetPath: 'assets/images/home.webp'),
          NavItemData(
              icon: LucideIcons.book_open,
              label: loc.lessons,
              color: AppColors.navLessons,
              assetPath: 'assets/images/aral.webp'),
          NavItemData(
              icon: LucideIcons.trophy,
              label: loc.awards,
              color: AppColors.navAwards,
              assetPath: 'assets/images/gantimpala.webp'),
          NavItemData(
              icon: LucideIcons.settings,
              label: loc.settings,
              color: AppColors.navSettings,
              assetPath: 'assets/images/setting.webp'),
        ],
      ),
      body: DesignScale(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_awards.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: SoftBackdrop(),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: StaggeredEntrance(
                    index: 0,
                    child: _buildProgress(
                        context, achievements.length, claimed.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: StaggeredEntrance(
                      index: 1,
                      child: _buildCabinet(
                        context,
                        achievements: achievements,
                        claimed: claimed,
                        badgeProgress: badgeProgress,
                        userProvider: userProvider,
                      ),
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
        'image': def.image,
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

  /// The medal count and bar, and the medal waiting to be taken: the top of
  /// the scrolling list, under the fixed header.
  Widget _buildProgress(BuildContext context, int earned, int claimed) {
    final loc = AppLocalizations.of(context)!;
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
                // The same 3D family as the medals below it.
                Image.asset(
                  'assets/images/badges/trophy.webp',
                  width: 36,
                  height: 36,
                  excludeFromSemantics: true,
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
        progressSection,
        // A medal is waiting to be taken.
        //
        // This was 12-pixel grey text — the smallest thing on the screen,
        // saying the most important thing on it. A child who cannot read it
        // had no way of knowing a prize was sitting there. Now it is the
        // brightest strip on the page, and it carries a medal so the message
        // survives without the sentence.
        //
        // Always there, saying something else when nothing is waiting: it
        // used to vanish with the last medal taken, and the whole cabinet
        // under it jumped up.
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
                BadgeEmblem(
                  icon: earned > claimed
                      ? Icons.card_giftcard_rounded
                      : Icons.star_rounded,
                  color: const Color(0xFFFFB800),
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    earned > claimed
                        ? loc.awardsWaiting(earned, earned - claimed)
                        : claimed >= _allBadges.length
                            ? loc.awardsAllClaimed
                            : loc.awardsKeepPlaying,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A6A12),
                    ),
                  ),
                ),
                // How many are waiting, as dots they can count.
                if (earned > claimed)
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

  /// How wide a medal is on the shelf: three to a shelf inside the
  /// cabinet's wooden frame, as big as that allows.
  static double _shelfMedalSize(double screenWidth) {
    // Page gutters 32, the frame 12, the cabinet's own padding 20.
    final perItem = (screenWidth - 32 - 12 - 20) / 3;
    return math.min(perItem - 14, 88);
  }

  /// The awards as a trophy cabinet: three medals to a wooden shelf, the
  /// twelve the certificate counts first, and the five-day streak on a shelf
  /// of its own, since it rewards showing up rather than finishing anything.
  Widget _buildCabinet(
    BuildContext context, {
    required Map<String, int> achievements,
    required List<String> claimed,
    required Map<String, BadgeProgress> badgeProgress,
    required UserProvider userProvider,
  }) {
    final loc = AppLocalizations.of(context)!;
    // Measured outside the scaled page, so taken back to the width the
    // shelves are laid out at.
    final medal = _shelfMedalSize(
        DesignScale.layoutWidth(MediaQuery.sizeOf(context).width));

    Widget itemFor(Map<String, dynamic> badge) {
      final id = badge['id'] as String;
      return _buildShelfItem(
        context,
        badge: badge,
        tier: achievements[id] ?? 0,
        isClaimed: claimed.contains(id),
        progress: badgeProgress[id],
        userProvider: userProvider,
        medal: medal,
      );
    }

    final course = [
      for (final b in _allBadges)
        if (UserProvider.graduateBadgeIds.contains(b['id'])) b
    ];
    final special = [
      for (final b in _allBadges)
        if (!UserProvider.graduateBadgeIds.contains(b['id'])) b
    ];

    final shelves = <Widget>[
      for (var i = 0; i < course.length; i += 3)
        _buildShelf([
          for (final b in course.skip(i).take(3)) itemFor(b),
        ]),
      if (special.isNotEmpty)
        _buildShelf(
          [for (final b in special) itemFor(b)],
          label: loc.badgeSpecialShelf,
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBEBD5), Color(0xFFF4DDBD)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFB87A43), width: 6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF50280A).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < shelves.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            shelves[i],
          ],
        ],
      ),
    );
  }

  /// One wooden shelf with its medals standing on it.
  Widget _buildShelf(List<Widget> items, {String? label}) {
    return Column(
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A4A00),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
        const SizedBox(height: 2),
        Container(
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC98B4E), Color(0xFF9A6232)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF50280A).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A medal on the shelf. One press takes a won medal, with its
  /// celebration (see [ShelfMedal]); a taken one opens its card, and one not
  /// yet won says how to win it.
  Widget _buildShelfItem(
    BuildContext context, {
    required Map<String, dynamic> badge,
    required int tier,
    required bool isClaimed,
    required BadgeProgress? progress,
    required UserProvider userProvider,
    required double medal,
  }) {
    final loc = AppLocalizations.of(context)!;
    final id = badge['id'] as String;
    final isEarned = tier >= 1;
    return ShelfMedal(
      key: ValueKey(id),
      icon: badge['icon'] as IconData,
      image: badge['image'] as String?,
      color: Color(badge['color'] as int),
      tier: tier,
      title: _badgeTitle(context, id),
      size: medal,
      isEarned: isEarned,
      ready: isEarned && !isClaimed,
      claimLabel: loc.claimShort,
      onClaim: () => userProvider.claimBadge(id),
      onOpen: isEarned
          ? () => _showViewBadgeModal(context, badge)
          : () => _showHowToEarnDialog(context, badge, progress),
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
      builder: (dialogContext) => FunDialog(
        child: FunMessage(
          picture: BadgeEmblem(
            icon: badge['icon'] as IconData,
            image: badge['image'] as String,
            color: color,
            size: 92,
            locked: true,
          ),
          title: _badgeTitle(context, badge['id'] as String),
          // The whole point of this card.
          message: _badgeHint(context, badge['id'] as String),
          body: progress == null
              ? null
              : Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 14,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.current}/${progress.target}',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 22,
                      fontVariations: const [FontVariation('wght', 700)],
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ]),
          buttons: [
            FunPillButton(
              label: loc.okButton,
              colors: FunColors.of(color),
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewBadgeModal(BuildContext context, Map<String, dynamic> badge) {
    final color = Color(badge['color'] as int);
    // How many stars it has reached, for the ribbon under the picture.
    final tier = Provider.of<UserProvider>(context, listen: false)
            .userProfile
            ?.achievements[badge['id']] ??
        0;
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
                    image: badge['image'] as String,
                    // The award's own colour on the coin's face; the rim is
                    // already gold.
                    color: Color(badge['color'] as int),
                    size: 118,
                    tier: tier,
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
