import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import AudioManager
import 'login_screen.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'onboarding_screen.dart';
import '../utils/page_transitions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startBackgroundMusic();
    _checkUserLoggedIn();
  }

  Future<void> _startBackgroundMusic() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    await audioManager.startBackgroundMusic(AudioManager.homeMusicAsset);
  }

  Future<void> _checkUserLoggedIn() async {
    // Leave as soon as the app is ready, with a short floor so the logo is
    // seen rather than flashed. This was a flat three seconds on every open
    // — on a fast phone that was three seconds of nothing, and on a slow one
    // it came on top of the provider's own load (waited for below).
    final shown = Stopwatch()..start();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Smart Login: Ensure UserProvider is fully initialized before checking
    // session — polled briefly, never more than about three seconds.
    int retryCount = 0;
    while (!userProvider.isInitialized && retryCount < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }
    const minShown = Duration(milliseconds: 900);
    if (shown.elapsed < minShown) {
      await Future.delayed(minShown - shown.elapsed);
    }

    if (!mounted) return;

    if (!mounted) return;

    // Fallback: Manually check prefs if provider still hasn't loaded role
    String? role = userProvider.currentRole;
    String? studentId = userProvider.currentStudentId;

    if (role == null) {
      role = prefs.getString('session_role');
      studentId = prefs.getString('session_student_id');
      if (role != null) {
        if (role == 'student') {
          userProvider.setCurrentStudentId(studentId);
        }
        userProvider.setCurrentRole(role);
      }
    }

    if (!hasSeenOnboarding) {
      Navigator.of(context).pushReplacementPremium(const OnboardingScreen());
    } else if (role == 'student' && studentId != null) {
      Navigator.of(context).pushReplacementPremium(const HomeScreen());
    } else if (role == 'teacher') {
      Navigator.of(context)
          .pushReplacementPremium(const TeacherDashboardScreen());
    } else {
      Navigator.of(context).pushReplacementPremium(const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            'assets/images/app_logo-transparent.png',
            width: 240,
            height: 240,
            fit: BoxFit.contain,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(
                  begin: 1.0,
                  end: 1.05,
                  duration: 1500.ms,
                  curve: Curves.easeInOut),
        ),
      ),
    );
  }
}
