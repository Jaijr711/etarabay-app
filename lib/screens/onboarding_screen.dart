import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import '../utils/page_transitions.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementPremium(const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly listen to language changes so the entire screen updates instantly
    Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildWelcomeStep(),
              _buildIntroStep(
                title: AppLocalizations.of(context)!.nextLevelLearningTitle,
                description:
                    AppLocalizations.of(context)!.nextLevelLearningDesc,
                icon: LucideIcons.rocket,
                color: AppColors.primary,
              ),
              _buildIntroStep(
                title: AppLocalizations.of(context)!.learnAnywhereTitle,
                description: AppLocalizations.of(context)!.learnAnywhereDesc,
                icon: LucideIcons.globe,
                color: AppColors.secondary,
              ),
              _buildIntroStep(
                title: AppLocalizations.of(context)!.trackProgressTitle,
                description: AppLocalizations.of(context)!.trackProgressDesc,
                icon: LucideIcons.chart_column,
                color: AppColors.success,
              ),
              _buildLanguageStep(),
            ],
          ),

          // Navigation Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicator
                Row(
                  children: List.generate(5, (index) {
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Next/Finish Button
                if (_currentPage < 4)
                  IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(LucideIcons.arrow_right),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ).animate(key: ValueKey(_currentPage)).scale(delay: 200.ms)
                else
                  ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(AppLocalizations.of(context)!.getStarted),
                  ).animate().fadeIn().scale(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.languages,
            size: 80,
            color: AppColors.primary,
          ).animate(onPlay: (c) => c.repeat()).shake(delay: 2.seconds),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.chooseLanguage,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 40),
          _buildLanguageOption('English', 'en', '🇺🇸'),
          const SizedBox(height: 16),
          _buildLanguageOption('Ilokano', 'ilo', '🇵🇭'),
          const SizedBox(height: 16),
          _buildLanguageOption('Filipino', 'fil', '🇵🇭'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code, String flag) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSelected = languageProvider.currentLanguageCode == code;

    return GestureDetector(
      onTap: () => languageProvider.setLanguage(code),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(LucideIcons.circle_check, color: AppColors.primary),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2);
  }

  Widget _buildIntroStep({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 3),
                ),
                child: Icon(icon, size: 80, color: color),
              ).animate().scale(duration: 500.ms).fadeIn(),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 100), // Space for controls
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              'assets/images/app_logo.jpg',
              fit: BoxFit.contain,
            ).animate().scale(duration: 500.ms).fadeIn(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 120, // Fix height so the text doesn't cause shifting
            child: Center(
              child: AnimatedTextKit(
                repeatForever: true,
                animatedTexts: [
                  FadeAnimatedText(
                    'Welcome to\nE-Tarabay',
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    duration: const Duration(seconds: 3),
                  ),
                  FadeAnimatedText(
                    'Maligayang Pagdating sa\nE-Tarabay',
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    duration: const Duration(seconds: 3),
                  ),
                  FadeAnimatedText(
                    'Naragsak a Isasangbay iti\nE-Tarabay',
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    duration: const Duration(seconds: 3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.onboardingQuote,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 100), // Space for controls
        ],
      ),
    );
  }
}
