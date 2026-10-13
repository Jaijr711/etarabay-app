import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  // Helper method to calculate achievement progress based on actual module progress
  Map<String, dynamic> _calculateAchievementProgress(
      UserProvider userProvider) {
    final progress = userProvider.getAllProgress();

    // Get progress from each module
    final magbasaProgress = progress['magbasa'] as Map? ?? {};
    final traceItProgress = progress['traceit'] as Map? ?? {};
    final kulayProgress = progress['kulay'] as Map? ?? {};
    final matematikaProgress = progress['matematika'] as Map? ?? {};
    final pamilyaProgress = progress['pamilya'] as Map? ?? {};

    // Calculate achievements based on actual progress
    return {
      // First Steps: Complete any 1 activity
      'firstSteps': progress['totalCompleted'] ?? 0,

      // Alphabet: Complete all Magbasa Tayo activities
      'alphabet': magbasaProgress['totalCompleted'] ?? 0,

      // Numbers: Complete all Matematika games
      'numbers': matematikaProgress['gamesCompleted'] ?? 0,

      // Colors: Complete all Kulay-Saya activities
      'colors': kulayProgress['totalCompleted'] ?? 0,

      // Shapes: Complete all Trace It uppercase letters
      'shapes': traceItProgress['uppercase']?['completed'] ?? 0,

      // Animals: Complete all Trace It lowercase letters
      'animals': traceItProgress['lowercase']?['completed'] ?? 0,

      // Bookworm: Complete all stories in Magbasa Tayo
      'bookworm': magbasaProgress['kwento']?['completed'] ?? 0,

      // Star Student: Complete all Ang Aking Sarili games
      'starStudent': pamilyaProgress['gamesCompleted'] ?? 0,

      // Math Whiz: Complete all Matematika levels
      'mathWhiz': matematikaProgress['completedLevels'] ?? 0,

      // Family Hero: Complete all Ang Aking Sarili levels
      'familyHero': pamilyaProgress['completedLevels'] ?? 0,

      // Writing Star: Complete all Trace It numbers
      'writingStar': traceItProgress['numbers']?['completed'] ?? 0,

      // Songbird: Complete all songs in Magbasa Tayo
      'songbird': magbasaProgress['kanta']?['completed'] ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final achievements = _calculateAchievementProgress(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.achievements,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FF),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Stars Counter
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 40, color: Color(0xFFFFB800)),
                  const SizedBox(width: 10),
                  // A plain count, matching the dashboard's stat row: the
                  // child's whole star pile is one number wherever they meet
                  // it. The out-of totals live on the module cards and on
                  // each badge, where they say what is still to be won.
                  Text(
                    '${userProvider.displayStars}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.stars,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            // Achievements Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementFirstSteps,
                    emoji: '👣',
                    color: AppColors.alphabet,
                    progress: achievements['firstSteps'] ?? 0,
                    total: 1,
                    description:
                        AppLocalizations.of(context)!.achievementFirstStepsDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title:
                        AppLocalizations.of(context)!.achievementAlphabetMaster,
                    emoji: '🔤',
                    color: AppColors.alphabet,
                    progress: achievements['alphabet'] ?? 0,
                    total: 12,
                    description: AppLocalizations.of(context)!
                        .achievementAlphabetMasterDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title:
                        AppLocalizations.of(context)!.achievementNumberWizard,
                    emoji: '🔢',
                    color: AppColors.numbers,
                    progress: achievements['numbers'] ?? 0,
                    total: 20,
                    description: AppLocalizations.of(context)!
                        .achievementNumberWizardDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementColorArtist,
                    emoji: '🎨',
                    color: AppColors.colors,
                    progress: achievements['colors'] ?? 0,
                    total: 4,
                    description: AppLocalizations.of(context)!
                        .achievementColorArtistDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title:
                        AppLocalizations.of(context)!.achievementShapeCreator,
                    emoji: '⬛',
                    color: AppColors.shapes,
                    progress: achievements['shapes'] ?? 0,
                    total: 26,
                    description: AppLocalizations.of(context)!
                        .achievementShapeCreatorDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title:
                        AppLocalizations.of(context)!.achievementAnimalFriend,
                    emoji: '🐶',
                    color: AppColors.animals,
                    progress: achievements['animals'] ?? 0,
                    total: 26,
                    description: AppLocalizations.of(context)!
                        .achievementAnimalFriendDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementBookworm,
                    emoji: '📚',
                    color: AppColors.body,
                    progress: achievements['bookworm'] ?? 0,
                    total: 4,
                    description:
                        AppLocalizations.of(context)!.achievementBookwormDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementStarStudent,
                    emoji: '⭐',
                    color: Colors.amber,
                    progress: achievements['starStudent'] ?? 0,
                    total: 20,
                    description: AppLocalizations.of(context)!
                        .achievementStarStudentDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementMathWhiz,
                    emoji: '🧮',
                    color: AppColors.numbers,
                    progress: achievements['mathWhiz'] ?? 0,
                    total: 7,
                    description:
                        AppLocalizations.of(context)!.achievementMathWhizDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementFamilyHero,
                    emoji: '👨‍👩‍👧',
                    color: AppColors.family,
                    progress: achievements['familyHero'] ?? 0,
                    total: 5,
                    description:
                        AppLocalizations.of(context)!.achievementFamilyHeroDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementWritingStar,
                    emoji: '✏️',
                    color: Colors.orange,
                    progress: achievements['writingStar'] ?? 0,
                    total: 10,
                    description: AppLocalizations.of(context)!
                        .achievementWritingStarDesc,
                  ),
                  _buildAchievementCard(
                    context,
                    title: AppLocalizations.of(context)!.achievementSongbird,
                    emoji: '🎵',
                    color: AppColors.colors,
                    progress: achievements['songbird'] ?? 0,
                    total: 10,
                    description:
                        AppLocalizations.of(context)!.achievementSongbirdDesc,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required String title,
    required String emoji,
    required Color color,
    required int progress,
    required int total,
    required String description,
  }) {
    final percentage = progress / total;
    final isCompleted = percentage >= 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isCompleted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 24)),
                    ),
                    if (isCompleted)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(
                          LucideIcons.circle_check,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompleted ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isCompleted
                          ? const Color(0xFFFFB800)
                          : const Color(0xFFCBD5E1),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted ? 'Completed!' : '$progress / $total',
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted ? Colors.green : AppColors.textLight,
                    fontWeight:
                        isCompleted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
