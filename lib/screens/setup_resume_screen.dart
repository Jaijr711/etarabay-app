import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/parent_pin.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import 'choose_avatar_screen.dart';
import 'home_screen.dart';
import 'parents_lock_screen.dart';
import 'privacy_notice_screen.dart';

/// Marks a child's first sign-in on this phone as not yet set up: the
/// privacy notice, the parent's code and the first picture are still to come.
/// Set by the login just before those steps and cleared once they are done.
///
/// The session is saved before them, so an app closed halfway through used
/// to open straight on Home next time: the notice never read, no parent's
/// code, no picture chosen.
String setupPendingKeyFor(String studentId) => 'setup_pending_$studentId';

/// Finishes the setup steps a first sign-in left undone, then goes Home.
class SetupResumeScreen extends StatefulWidget {
  final String studentId;
  const SetupResumeScreen({super.key, required this.studentId});

  @override
  State<SetupResumeScreen> createState() => _SetupResumeScreenState();
}

class _SetupResumeScreenState extends State<SetupResumeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (!await PrivacyNotice.isAcknowledged(prefs)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        PremiumPageRoute(
            child: const PrivacyNoticeScreen(requireAcknowledge: true)),
      );
    }
    if (!mounted) return;
    if (!await ParentPin.isSet(prefs)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        PremiumPageRoute(child: const ParentsLockScreen(setupOnly: true)),
      );
    }
    if (!mounted) return;
    final avatar = context.read<UserProvider>().userProfile?.avatar ?? '';
    if (!isAnimalAvatar(avatar)) {
      await Navigator.push<String>(
        context,
        PremiumPageRoute<String>(
            child: const ChooseAvatarScreen(firstTime: true)),
      );
    }
    await prefs.remove(setupPendingKeyFor(widget.studentId));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PremiumPageRoute(child: const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
