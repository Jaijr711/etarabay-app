import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../main.dart'; // Import AudioManager
import 'login_screen.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'onboarding_screen.dart';
import '../utils/page_transitions.dart';

/// The opening of the app: the E-Tarabay train animation.
///
/// The video plays once, then the app moves on to wherever the child left
/// off. A tap anywhere skips it. If the video cannot play on this device (or
/// takes too long to start), the logo is shown instead, exactly as before the
/// video existed, so the app never stalls on its own opening.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// A white fade over each edge of the video, so it melts into the white
/// page instead of ending on a visible line.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade();

  static const _white = Colors.white;
  static const _clear = Color(0x00FFFFFF);

  Widget _strip(Alignment from, Alignment to) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: from,
            end: to,
            colors: const [_white, _clear],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final v = (box.maxHeight * 0.035).clamp(10.0, 28.0);
      final h = (box.maxWidth * 0.035).clamp(8.0, 20.0);
      return Stack(children: [
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: v,
            child: _strip(Alignment.topCenter, Alignment.bottomCenter)),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: v,
            child: _strip(Alignment.bottomCenter, Alignment.topCenter)),
        Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: h,
            child: _strip(Alignment.centerLeft, Alignment.centerRight)),
        Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: h,
            child: _strip(Alignment.centerRight, Alignment.centerLeft)),
      ]);
    });
  }
}

class _SplashScreenState extends State<SplashScreen> {
  static const _videoAsset = 'assets/images/app_animation.mp4';

  /// Longest the video may take to start before the logo is used instead.
  static const _videoStartLimit = Duration(seconds: 3);

  VideoPlayerController? _video;
  bool _videoFailed = false;
  bool _leaving = false;
  bool _musicStarted = false;

  /// Resolves once it is known where to go next (session and onboarding).
  late final Future<Widget> _destination = _workOutDestination();

  @override
  void initState() {
    super.initState();
    // Started now, so it is settled long before the video is over.
    unawaited(_destination);
    _startVideo();
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    super.dispose();
  }

  Future<void> _startVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    _video = controller;
    try {
      await controller.initialize().timeout(_videoStartLimit);
      // Browsers refuse to start a video with sound before the child has
      // touched the page, so on the web it plays muted. In the app the
      // train's own sound plays and the music waits until it is over.
      await controller.setVolume(kIsWeb ? 0 : 1);
      if (kIsWeb) _startBackgroundMusic();
      controller.addListener(_onVideoTick);
      await controller.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Splash video unavailable, showing the logo: $e');
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _startBackgroundMusic();
      // The logo's own short pause, then on — as the splash always did.
      await Future.delayed(const Duration(milliseconds: 900));
      _leave();
    }
  }

  void _onVideoTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    if (v.value.hasError) {
      _leave();
      return;
    }
    final d = v.value.duration;
    if (d > Duration.zero &&
        v.value.position >= d - const Duration(milliseconds: 80)) {
      _leave();
    }
  }

  void _startBackgroundMusic() {
    if (_musicStarted) return;
    _musicStarted = true;
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.startBackgroundMusic(AudioManager.homeMusicAsset);
  }

  /// Moves on once the video is over (or skipped) and the destination is known.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _video?.pause();
    _startBackgroundMusic();
    final next = await _destination;
    if (!mounted) return;
    Navigator.of(context).pushReplacementPremium(next);
  }

  Future<Widget> _workOutDestination() async {
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

    if (!hasSeenOnboarding) return const OnboardingScreen();
    if (role == 'student' && studentId != null) return const HomeScreen();
    if (role == 'teacher') return const TeacherDashboardScreen();
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    final playing = !_videoFailed && v != null && v.value.isInitialized;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Ten seconds is a long wait on the fifth open of the day.
          onTap: playing ? _leave : null,
          child: SizedBox.expand(
            child: playing
                ? Center(
                    child: AspectRatio(
                      aspectRatio: v.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(v),
                          // On a screen taller or wider than the video, its
                          // edge falls inside the screen: a block dropping in
                          // from the top appeared out of nothing along a
                          // straight line, and some Android decoders draw a
                          // thin stripe at the frame's edge. A short fade to
                          // the page's white on all four sides hides both.
                          const IgnorePointer(child: _EdgeFade()),
                        ],
                      ),
                    ),
                  )
                : Center(
                    // Shown while the video starts, and instead of it when
                    // it cannot play here.
                    child: Image.asset(
                      'assets/images/app_logo-transparent.png',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                    )
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .scaleXY(
                            begin: 1.0,
                            end: 1.05,
                            duration: 1500.ms,
                            curve: Curves.easeInOut),
                  ),
          ),
        ),
      ),
    );
  }
}
