import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../services/teacher_pin.dart';
import '../utils/page_transitions.dart';
import 'teacher_pin_flow.dart';

/// Whether coming back to the app after being away for [away] asks for the
/// teacher's PIN.
///
/// Half a minute is let go: long enough to pick a photo, answer a message or
/// confirm a fingerprint without being asked again, short enough that a
/// phone put down and picked up later is locked. With no PIN made yet there
/// is nothing to ask for: the dashboard asks the teacher to make one.
bool shouldLockTeacher({
  required String? role,
  required Duration away,
  required bool hasPin,
}) =>
    role == 'teacher' && hasPin && away >= TeacherLockGate.grace;

/// Keeps the children's details behind the teacher's PIN.
///
/// The teacher logs in once with the password and makes a PIN. After that,
/// when the app comes back after the phone was locked or another app was
/// used (or the app is opened again from closed), only the PIN or a
/// fingerprint is asked for; the password is for a forgotten PIN.
/// While the app is in the background a plain cover hides the class from
/// the list of open apps. Sits above the navigator, so every screen is
/// covered, not only the dashboard.
class TeacherLockGate extends StatefulWidget {
  const TeacherLockGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  static const grace = Duration(seconds: 30);

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<TeacherLockGate> createState() => _TeacherLockGateState();
}

class _TeacherLockGateState extends State<TeacherLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _covered = false;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockIfReopened();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A teacher session kept from before the app was closed opens locked:
  /// otherwise closing the app would be a way round the lock.
  Future<void> _lockIfReopened() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('session_role') != 'teacher') return;
    if (await TeacherPin.isSet() && mounted) setState(() => _locked = true);
  }

  Future<void> _lockIfAway(Duration away) async {
    final lock = shouldLockTeacher(
      role: _role,
      away: away,
      hasPin: _role == 'teacher' && await TeacherPin.isSet(),
    );
    if (lock && mounted) setState(() => _locked = true);
  }

  String? get _role =>
      Provider.of<UserProvider>(context, listen: false).currentRole;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final teacher = _role == 'teacher';
    switch (state) {
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        setState(() => _covered = false);
        if (left != null) _lockIfAway(DateTime.now().difference(left));
      case AppLifecycleState.inactive:
        if (teacher && !_covered) setState(() => _covered = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _leftAt ??= DateTime.now();
        if (teacher && !_covered) setState(() => _covered = true);
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _logout() async {
    await Provider.of<UserProvider>(context, listen: false).logout();
    if (!mounted) return;
    setState(() => _locked = false);
    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      PremiumPageRoute(child: const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: _locked,
          child: ExcludeSemantics(excluding: _locked, child: widget.child),
        ),
        if (_locked)
          _TeacherLock(
            onUnlocked: () => setState(() => _locked = false),
            onLogout: _logout,
          )
        else if (_covered)
          const _PrivacyCover(),
      ],
    );
  }
}

/// What the list of open apps shows instead of the class.
class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Image.asset(
          'assets/images/app_logo-transparent.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}

/// The PIN screen, or the password when the PIN is blocked or forgotten.
///
/// The lock sits above the app's navigator, so it brings a navigator of its
/// own: the password field needs an overlay for its cursor and handles, and
/// the buttons one for their tooltips.
class _TeacherLock extends StatelessWidget {
  const _TeacherLock({required this.onUnlocked, required this.onLogout});

  final VoidCallback onUnlocked;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    // The app's navigator owns the hero controller; this one needs none.
    return HeroControllerScope.none(
      child: Navigator(
        onGenerateInitialRoutes: (_, __) => [
          PageRouteBuilder<void>(
            opaque: false,
            pageBuilder: (_, __, ___) => TeacherPinFlow(
              start: PinFlowStart.unlock,
              onDone: onUnlocked,
              onLogout: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}
