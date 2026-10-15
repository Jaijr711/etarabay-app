import 'parents_lock_screen.dart';
import '../services/parent_pin.dart';
import 'choose_avatar_screen.dart';
import 'dart:convert';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_messages.dart';
import '../services/biometric_service.dart';
import 'home_screen.dart';
import 'teacher_login_screen.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricEnabled = false;
  String _biometricName = '';

  /// Children who have signed in on this device, most recent first.

  static const String _knownKey = 'known_students';

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  /// Records a child on this device so their face is offered next time.
  ///
  /// Name and avatar only — no credential is kept. Tapping the face restores
  /// the session by id, which is the same thing the splash screen does for
  /// the child who was last signed in.
  Future<void> _rememberChild(String id, String name, String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_knownKey) ?? const [];
    final kept = <String>[
      jsonEncode({'id': id, 'name': name, 'avatar': avatar}),
    ];
    for (final entry in raw) {
      if (jsonDecode(entry) case final Map m when m['id'] != id) {
        kept.add(entry);
      }
    }
    // A classroom tablet is shared by a handful of children, not a hundred.
    await prefs.setStringList(_knownKey, kept.take(8).toList(growable: false));
  }

  /// One tap back into a child's own app.

  Future<void> _initBiometric() async {
    final enabled =
        await BiometricService.isEnabled(BiometricService.studentKey);
    final available = await BiometricService.isAvailable();
    if (!mounted) return;
    final creds = enabled
        ? await BiometricService.getCredentials(BiometricService.studentKey)
        : null;
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled && available;
      _biometricName = creds?['name'] ?? '';
    });
  }

  Future<void> _biometricLogin() async {
    final creds =
        await BiometricService.getCredentials(BiometricService.studentKey);
    if (creds == null) return;
    final ok = await BiometricService.authenticate('Log in to continue');
    if (!ok || !mounted) return;
    _usernameController.text = creds['username'] ?? '';
    _passwordController.text = creds['password'] ?? '';
    _loginStudent();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginStudent() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog(AppLocalizations.of(context)!.enterUsernamePassword);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.loginStudent(username, password);

    if (!mounted) return;

    if (result['status'] == 'Success') {
      // Store the student data locally for session
      final studentData = result['studentData'] as Map<String, dynamic>;
      final studentId = result['studentId'] as String;

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Set session data. startStudentSession wipes any previous student's
      // local data if this is a different account (so a deleted-then-recreated
      // student, or a different student on this device, starts clean).
      await userProvider.startStudentSession(studentId);
      userProvider.setCurrentRole('student');
      if (!mounted) return;

      // Make sure a profile exists locally right away (fast, offline) using the
      // data the login already returned — so the home screen has something to
      // show immediately without waiting on the network.
      if (userProvider.userProfile == null) {
        final profile = studentData['profile'] as Map<String, dynamic>?;
        // Birthday might be at the top-level studentData or inside the profile
        // sub-map. Check both so newly enrolled students don't show "Not set".
        DateTime? bday;
        final bdayStr = profile?['birthday'] ?? studentData['birthday'];
        if (bdayStr != null) {
          bday = DateTime.tryParse(bdayStr.toString());
        }

        await userProvider.createUserProfile(
          profile?['name'] ?? studentData['name'] ?? username,
          profile?['gender'] ?? studentData['gender'] ?? 'Male',
          birthday: bday,
          parentName: profile?['parentName'] ?? studentData['parentName'],
          parentContact:
              profile?['parentContact'] ?? studentData['parentContact'],
          lrn: profile?['lrn'] ?? studentData['lrn'],
        );
      }

      if (!mounted) return;
      // Offer this child's face next time rather than their ID.
      final profileMap = studentData['profile'] as Map<String, dynamic>?;
      await _rememberChild(
        studentId,
        (profileMap?['name'] ?? studentData['name'] ?? username).toString(),
        (profileMap?['avatar'] ?? studentData['avatar'] ?? '').toString(),
      );
      if (!mounted) return;
      // Keep the typed LRN locally for certificate display (cloud stays hashed).
      await userProvider.setSessionLrn(password);
      if (!mounted) return;

      // The one moment an adult is certainly holding this phone. After it,
      // the phone is the child's. A parent who has already made their code —
      // signing in their second child, say — goes straight through.
      final prefs = await SharedPreferences.getInstance();
      if (!await ParentPin.isSet(prefs)) {
        if (!mounted) return;
        await Navigator.push(
          context,
          PremiumPageRoute(child: const ParentsLockScreen(setupOnly: true)),
        );
      }
      if (!mounted) return;

      // A new account picks its picture next, while the parent who just made
      // the PIN is still there to help. Asked once: `avatarChosen` is set on
      // the class record when they pick, and a child who already has one of
      // the animals (the teacher may have chosen it) is not asked at all.
      final avatarNow =
          (profileMap?['avatar'] ?? studentData['avatar'] ?? '').toString();
      if (studentData['avatarChosen'] != true && !isAnimalAvatar(avatarNow)) {
        final picked = await Navigator.push<String>(
          context,
          PremiumPageRoute<String>(
              child: const ChooseAvatarScreen(firstTime: true)),
        );
        if (!mounted) return;
        if (picked != null) {
          // The face offered on this phone next time.
          await _rememberChild(
            studentId,
            (profileMap?['name'] ?? studentData['name'] ?? username).toString(),
            picked,
          );
          if (!mounted) return;
        }
      }

      // Navigate to home immediately — no blocking spinner. The full progress
      // sync runs in the background and the UI updates silently once it lands
      // (UserProvider notifies listeners when the data arrives).
      Navigator.pushReplacement(
        context,
        PremiumPageRoute(child: const HomeScreen()),
      );

      userProvider
          .syncFromFirebase()
          .timeout(const Duration(seconds: 8))
          .catchError((e) => debugPrint('Background Firebase sync failed: $e'));
    } else {
      setState(() => _isLoading = false);
      _showErrorDialog(authMessage(context, result).isNotEmpty
          ? authMessage(context, result)
          : AppLocalizations.of(context)!.loginError);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.circle_alert, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _modernInputDecoration({
    required String label,
    required String iconAsset,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
      // A drawn icon rather than a line glyph — the children recognise the
      // picture before they can read the label beside it.
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 10),
        child: Image.asset(iconAsset, width: 40, height: 40),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  /// A gold star for either end of the Log In button.
  Widget _buttonStar() => Image.asset(
        'assets/images/star_gold.webp',
        width: 33,
        height: 26,
        fit: BoxFit.contain,
      );

  /// One field of the form, with the soft lift the design gives every box.
  ///
  /// The shadow has to sit on a wrapper rather than the field itself:
  /// InputDecoration fills its own rounded shape and has nowhere to hang a
  /// shadow, so a bare TextField would sit flat on the artwork.
  Widget _fieldBox({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The keyboard opening used to shrink the Scaffold's body, and the
      // background — sized to that body — visibly resized with it. The
      // background has no reason to move at all when the keyboard opens, so
      // resizeToAvoidBottomInset is off and the scroll view below carries
      // its own bottom padding for the keyboard instead.
      resizeToAvoidBottomInset: false,
      // SizedBox.expand forces the Stack itself to the full screen. Without
      // it, a Stack with no stretched child sizes to its content instead —
      // once the form column below stopped being stretched tall (the
      // keyboard-squish fix), the background shrank to match it, leaving
      // the Scaffold's own background showing below.
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Illustrated background — sun, rainbow, trees, two children on
            // the grass. It carries the E-Tarabay logo, the "Welcome Back!"
            // greeting and the line under it as part of the artwork, so the
            // form below draws none of those three as text.
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_bg_student.webp',
                fit: BoxFit.cover,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // A plain scrollable column, sized to its content rather than
                // stretched to fill the screen. Bottom padding equal to the
                // keyboard's own height stands in for the resize Scaffold no
                // longer does — scrolling a focused field up clear of the
                // keyboard, without the background resizing to get there.
                //
                // No SafeArea around this one: the artwork's clear band is
                // measured from the very top of the picture, which is also
                // where the full-bleed background starts. Insetting the form
                // by the status bar would push it that far down the grass.
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drops the form into the empty sky the artwork leaves
                        // between its greeting and the treetops — the same
                        // 42% of the picture's height the design puts it at.
                        SizedBox(height: constraints.maxHeight * 0.417),

                        // Username field
                        _fieldBox(
                          child: TextField(
                            controller: _usernameController,
                            decoration: _modernInputDecoration(
                              label: AppLocalizations.of(context)!.username,
                              iconAsset: 'assets/images/icon_username.webp',
                              suffix: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Image.asset(
                                  'assets/images/star_gold.webp',
                                  width: 33,
                                  height: 26,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password field (Student Number)
                        _fieldBox(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _modernInputDecoration(
                              label: AppLocalizations.of(context)!
                                  .studentNumberField,
                              iconAsset:
                                  'assets/images/icon_student_number.webp',
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? LucideIcons.eye_off
                                      : LucideIcons.eye,
                                  color: const Color(0xFF7100FF),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _loginStudent(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Gradient Login Button — a short pill with a star on
                        // each side, not a full-width bar. Centred rather than
                        // stretched, so the two stars stay beside the word.
                        Center(
                          child: SizedBox(
                            width: 179,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5C52E5),
                                    Color(0xFF4F46E5),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5C52E5)
                                        .withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _loginStudent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buttonStar(),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .loginButton,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          _buttonStar(),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Biometric quick-login
                        if (_biometricEnabled) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: _biometricLogin,
                              icon: const Icon(
                                LucideIcons.fingerprint_pattern,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              label: Text(
                                _biometricName.isNotEmpty
                                    ? 'Sign in as $_biometricName'
                                    : 'Use fingerprint / face',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Room at the foot of the scroll so the fixed
                        // "Continue as Teacher" link below never sits over
                        // the last thing on the page.
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                );
              },
            ),

            // A quiet link, not a button — a parent signing their child in
            // should never feel this is meant for them. Pinned to the very
            // bottom of the screen rather than sitting in the scrolling form,
            // so it reads as separate from the login itself.
            //
            // Plain shadowed text over the artwork tested as too easy to
            // miss entirely — a small dark chip gives it a shape to spot
            // without the size, colour or weight of an actual call to
            // action like "Log In".
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Center(
                  child: InkWell(
                    onTap: () {
                      context.pushPremium(
                        const TeacherLoginScreen(),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.graduation_cap,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.teacherLoginButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
}
