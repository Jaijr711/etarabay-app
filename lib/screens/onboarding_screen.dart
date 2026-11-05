import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import '../utils/page_transitions.dart';

/// The pages shown once, the first time the app is opened.
///
/// The language comes first, so every page after it is already in the
/// family's language. Each page has its own bright color with the green
/// mascot as the guide, and a white sheet below holding the words.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageColors = [
    AppColors.primary,
    Color(0xFF22A6A4),
    AppColors.secondary,
    AppColors.navAwards,
  ];
  static const _lastPage = 3;

  static const _languages = [
    ['en', 'English'],
    ['fil', 'Filipino'],
    ['ilo', 'Ilocano'],
  ];

  /// Room kept at the bottom of every sheet for the dots and the button.
  static const _controlsHeight = 76.0;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementPremium(const LoginScreen());
  }

  void _next() {
    if (_currentPage == _lastPage) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(duration: 450.ms, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly listen to language changes so the entire screen updates instantly
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _pageColors[_currentPage];
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
                _buildLanguagePage(l10n, languageProvider),
                _buildIntroPage(
                  color: _pageColors[1],
                  image: 'assets/images/laro.webp',
                  buddy: 'assets/images/mascot_dino.webp',
                  title: l10n.nextLevelLearningTitle,
                  description: l10n.nextLevelLearningDesc,
                ),
                _buildIntroPage(
                  color: _pageColors[2],
                  image: 'assets/images/card5.webp',
                  buddy: 'assets/images/mascot_wave.webp',
                  title: l10n.learnAnywhereTitle,
                  description: l10n.learnAnywhereDesc,
                ),
                _buildIntroPage(
                  color: _pageColors[3],
                  image: 'assets/images/trophy_happy.webp',
                  buddy: 'assets/images/mascot_wave.webp',
                  title: l10n.trackProgressTitle,
                  description: l10n.trackProgressDesc,
                ),
              ],
            ),

            // Skip, for a parent or teacher who has seen these pages before.
            if (_currentPage < _lastPage)
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xD9FFFFFF),
                        foregroundColor: AppColors.textLight,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        l10n.skip,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),

            // Navigation Controls, on the white sheet of every page.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomInset),
                    child: Row(
                      children: [
                        // Page Indicator
                        Row(
                          children: List.generate(_pageColors.length, (index) {
                            final on = _currentPage == index;
                            return AnimatedContainer(
                              duration: 300.ms,
                              margin: const EdgeInsets.only(right: 6),
                              height: 9,
                              width: on ? 26 : 9,
                              decoration: BoxDecoration(
                                color: on ? color : const Color(0xFFDCD9EC),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        // Next/Finish Button
                        ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _lastPage
                                    ? l10n.getStarted
                                    : l10n.next,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ],
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

  /// One page: the colored sky on top and the white sheet below it.
  Widget _buildPage({
    required Color color,
    required Widget sky,
    required Widget sheet,
    String? buddy,
  }) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: color,
            child: Stack(
              children: [
                const Align(
                  alignment: Alignment(-0.78, 0.05),
                  child: _Sparkle(size: 24),
                ),
                const Align(
                  alignment: Alignment(0.82, 0.15),
                  child: _Sparkle(size: 16),
                ),
                SafeArea(bottom: false, child: sky),
              ],
            ),
          ),
        ),
        // The sky's color behind the sheet's rounded corners.
        ColoredBox(
          color: color,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (buddy != null)
                      Positioned(
                        top: -66,
                        right: 16,
                        child: Image.asset(buddy, width: 84),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          24, 24, 24, 24 + _controlsHeight + bottomInset),
                      child: sheet,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A gentle up-and-down float, left still when animations are turned off.
  Widget _bob(Widget child) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 1500.ms, curve: Curves.easeInOut);
  }

  Widget _buildLanguagePage(
      AppLocalizations l10n, LanguageProvider languageProvider) {
    return _buildPage(
      color: _pageColors[0],
      sky: Column(
        children: [
          const SizedBox(height: 60), // Space for Skip
          _speechBubble(l10n).animate().fadeIn(duration: 400.ms).slideY(
                begin: 0.2,
              ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final size = (box.maxHeight * 0.88)
                  .clamp(0.0, box.maxWidth * 0.5)
                  .toDouble();
              return Center(
                child: _bob(
                  Image.asset('assets/images/mascot_wave.webp',
                      width: size, height: size),
                ),
              );
            }),
          ),
        ],
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chooseLanguage.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          for (final language in _languages) ...[
            _buildLanguageOption(languageProvider, language[0], language[1]),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _speechBubble(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.welcomeTo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'E-Tarabay!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const CustomPaint(size: Size(22, 11), painter: _BubbleTail()),
      ],
    );
  }

  Widget _buildLanguageOption(
      LanguageProvider languageProvider, String code, String name) {
    final isSelected = languageProvider.currentLanguageCode == code;

    return Material(
      color: isSelected ? AppColors.primary : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFFECEAF7),
          width: 2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => languageProvider.setLanguage(code),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF1F0FB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildIntroPage({
    required Color color,
    required String image,
    required String buddy,
    required String title,
    required String description,
  }) {
    return _buildPage(
      color: color,
      buddy: buddy,
      sky: Padding(
        padding: const EdgeInsets.only(top: 48), // Space for Skip
        child: LayoutBuilder(builder: (context, box) {
          final size =
              (box.maxHeight * 0.8).clamp(0.0, box.maxWidth * 0.62).toDouble();
          return Center(
            child: _bob(Image.asset(image, width: size, height: size))
                .animate()
                .scale(begin: const Offset(0.85, 0.85), duration: 450.ms)
                .fadeIn(),
          );
        }),
      ),
      sheet: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // Clear of the mascot sitting on the sheet's corner.
            padding: const EdgeInsets.only(right: 76),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: AppColors.textDark,
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textLight,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/star_gold.webp', width: size);
  }
}

/// The little point under the speech bubble, aimed at the mascot.
class _BubbleTail extends CustomPainter {
  const _BubbleTail();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
