import '../widgets/biometric_setup.dart';
import 'developer_login_screen.dart';
import 'teacher_login_screen.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_messages.dart';
import '../services/biometric_service.dart';
import 'login_screen.dart';
import '../main.dart';
import '../utils/page_transitions.dart';
import '../utils/constants.dart';
import '../widgets/custom_header_app_bar.dart';
import '../widgets/staggered_entrance.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // Read from the installed package itself — see the matching note in
  // settings_screen.dart.
  String _appVersion = '';

  // The hidden developer dashboard's entry point — see the matching note
  // in settings_screen.dart. This is the teacher-side settings screen, a
  // separate widget from the student one, so it needs its own copy of the
  // tap counter to reach the same DeveloperLoginScreen.
  int _versionTapCount = 0;
  DateTime? _versionTapWindowStart;

  void _onVersionTapped() {
    final now = DateTime.now();
    if (_versionTapWindowStart == null ||
        now.difference(_versionTapWindowStart!) > const Duration(seconds: 3)) {
      _versionTapWindowStart = now;
      _versionTapCount = 1;
      return;
    }
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _versionTapWindowStart = null;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DeveloperLoginScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBiometric();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  Future<void> _loadBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled =
        await BiometricService.isEnabled(BiometricService.teacherKey);
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled && available;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      // Off by default — see the matching note in settings_screen.dart.
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _toggleMusic(bool value) async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    setState(() => _musicEnabled = value);
    await audioManager.setMusicEnabled(value);
  }

  Future<void> _setLanguage(String code) async {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    await provider.setLanguage(code);
    setState(() {});
  }

  void _showSnack(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Account: change credentials + biometric ───────────────────────────────

  /// Prompt for the current password, then let the teacher set a new username
  /// and/or password. Writes only the hash to Firestore.
  Future<void> _changeCredentialsDialog() async {
    final currentCtrl = TextEditingController();
    final newUserCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    String? error;
    bool busy = false;

    final currentUsername = await _authService.getTeacherUsername();
    if (currentUsername != null) newUserCtrl.text = currentUsername;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            InputDecoration deco(String label, IconData icon,
                    {Widget? suffix}) =>
                InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 20),
                  suffixIcon: suffix,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                );

            Future<void> save() async {
              final current = currentCtrl.text.trim();
              final newUser = newUserCtrl.text.trim();
              final newPass = newPassCtrl.text.trim();
              final confirm = confirmCtrl.text.trim();

              if (current.isEmpty) {
                setDialogState(() =>
                    error = AppLocalizations.of(context)!.enterCurrentPassword);
                return;
              }
              if (newPass.isNotEmpty && newPass != confirm) {
                setDialogState(() => error =
                    AppLocalizations.of(context)!.newPasswordsDoNotMatch);
                return;
              }
              if (newUser.isEmpty && newPass.isEmpty) {
                setDialogState(() =>
                    error = AppLocalizations.of(context)!.nothingToChange);
                return;
              }

              setDialogState(() {
                busy = true;
                error = null;
              });

              final ok = await _authService.verifyTeacherPassword(current);
              if (!ok) {
                setDialogState(() {
                  busy = false;
                  error =
                      AppLocalizations.of(context)!.currentPasswordIncorrect;
                });
                return;
              }

              final result = await _authService.updateTeacherCredentials(
                username: newUser,
                newPassword: newPass,
              );

              if (result['status'] != 'Success') {
                setDialogState(() {
                  busy = false;
                  error = authMessage(context, result).isNotEmpty
                      ? authMessage(context, result)
                      : AppLocalizations.of(context)!.authSaveFailed;
                });
                return;
              }

              // Keep biometric in sync: if enabled, re-store the new password so
              // fingerprint login keeps working.
              if (_biometricEnabled) {
                await BiometricService.saveCredentials(
                  slot: BiometricService.teacherKey,
                  username: newUser.isNotEmpty
                      ? newUser
                      : (currentUsername ?? TeacherCredentials.username),
                  password: newPass.isNotEmpty ? newPass : current,
                );
              }

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              // The dialog closing says nothing about the screen behind it,
              // and the message is read from that one.
              if (!mounted) return;
              _showSnack(AppLocalizations.of(context)!.credentialsUpdated,
                  LucideIcons.circle_check, AppColors.success);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                const Icon(LucideIcons.key_round, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.changeLogin,
                      style: const TextStyle(fontSize: 18)),
                ),
              ]),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: deco(
                        AppLocalizations.of(context)!.currentPassword,
                        LucideIcons.lock),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newUserCtrl,
                    decoration: deco('Username', LucideIcons.user),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscure,
                    decoration: deco(AppLocalizations.of(context)!.newPassword,
                        LucideIcons.lock_keyhole,
                        suffix: IconButton(
                          icon: Icon(
                              obscure ? LucideIcons.eye_off : LucideIcons.eye,
                              size: 18),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        )),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscure,
                    decoration: deco(
                        AppLocalizations.of(context)!.confirmNewPassword,
                        LucideIcons.lock_keyhole),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.blankToKeepPassword,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: busy ? null : save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Enable/disable biometric login. Turning ON requires the current password
  /// (to verify + store for future logins) plus a live biometric scan.
  Future<void> _toggleBiometric(bool value) async {
    final loc = AppLocalizations.of(context)!;
    final on = await setBiometricEnabled(
      context: context,
      enable: value,
      slot: BiometricService.teacherKey,
      passwordLabel: loc.confirmYourPassword,
      numericPassword: false,
      verify: _authService.verifyTeacherPassword,
      wrongPasswordMessage: loc.passwordIncorrect,
      credentials: (_) async => {
        'username': await _authService.getTeacherUsername() ??
            TeacherCredentials.username,
      },
      notify: _showSnack,
    );
    if (!mounted) return;
    setState(() => _biometricEnabled = on);
  }

  Future<void> _confirmResetAllStudents() async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.triangle_alert, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(loc.resetAllStudents,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(loc.confirmResetAllStudents),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.confirm,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _authService.deleteAllStudents();
      if (!mounted) return;
      final ok = result['status'] == 'Success';
      _showSnack(
        authMessage(context, result),
        ok ? LucideIcons.circle_check : LucideIcons.circle_alert,
        ok ? AppColors.success : Colors.red,
      );
    }
  }

  Future<void> _logout() async {
    final loc = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logout,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.confirmLogout),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.logout,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await userProvider.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PremiumPageRoute(child: const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      appBar: CustomHeaderAppBar(
        title: loc.settingsTitle,
        baseColor: AppColors.primary,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_settings.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 120,
            ),
            children: [
              StaggeredEntrance(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(loc.language),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _LanguageTile(
                            code: 'en',
                            label: 'English',
                            isSelected:
                                languageProvider.currentLanguageCode == 'en',
                            onTap: () => _setLanguage('en'),
                          ),
                          const Divider(height: 0, indent: 72),
                          _LanguageTile(
                            code: 'fil',
                            label: 'Filipino',
                            isSelected:
                                languageProvider.currentLanguageCode == 'fil',
                            onTap: () => _setLanguage('fil'),
                          ),
                          const Divider(height: 0, indent: 72),
                          _LanguageTile(
                            code: 'ilo',
                            label: 'Ilokano',
                            isSelected:
                                languageProvider.currentLanguageCode == 'ilo',
                            onTap: () => _setLanguage('ilo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(AppLocalizations.of(context)!.sectionAudio),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary:
                                const _IconBadge(icon: LucideIcons.volume_2),
                            title: Text(loc.sound),
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() => _soundEnabled = value);
                              SharedPreferences.getInstance().then(
                                (prefs) =>
                                    prefs.setBool('sound_enabled', value),
                              );
                            },
                          ),
                          const Divider(height: 0, indent: 72),
                          SwitchListTile(
                            secondary:
                                const _IconBadge(icon: LucideIcons.music),
                            title: Text(loc.music),
                            value: _musicEnabled,
                            onChanged: _toggleMusic,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(loc.notifications),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: SwitchListTile(
                        secondary: const _IconBadge(icon: LucideIcons.bell),
                        title: Text(loc.notifications),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                          SharedPreferences.getInstance().then(
                            (prefs) =>
                                prefs.setBool('notifications_enabled', value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                        AppLocalizations.of(context)!.sectionAccount),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            leading:
                                const _IconBadge(icon: LucideIcons.key_round),
                            title:
                                Text(AppLocalizations.of(context)!.changeLogin),
                            subtitle: Text(
                                AppLocalizations.of(context)!.changeLoginNote),
                            trailing: Icon(LucideIcons.chevron_right,
                                color: Colors.grey.shade400, size: 18),
                            onTap: _changeCredentialsDialog,
                          ),
                          if (_biometricAvailable) ...[
                            const Divider(height: 0, indent: 72),
                            SwitchListTile(
                              secondary: const _IconBadge(
                                  icon: LucideIcons.fingerprint_pattern),
                              title: Text(
                                  AppLocalizations.of(context)!.biometricLogin),
                              subtitle: Text(AppLocalizations.of(context)!
                                  .skipPasswordNextTime),
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                        AppLocalizations.of(context)!.sectionClassroom),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const _IconBadge(
                                icon: LucideIcons.trash_2, danger: true),
                            title: Text(
                              AppLocalizations.of(context)!.resetAllStudents,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600),
                            ),
                            trailing: const Icon(LucideIcons.chevron_right,
                                color: Colors.red, size: 18),
                            onTap: _confirmResetAllStudents,
                          ),
                          const Divider(height: 0, indent: 72),
                          ListTile(
                            leading:
                                const _IconBadge(icon: LucideIcons.log_out),
                            title: Text(AppLocalizations.of(context)!.logout),
                            trailing: Icon(LucideIcons.chevron_right,
                                color: Colors.grey.shade400, size: 18),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(AppLocalizations.of(context)!.about),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: _onVersionTapped,
                        leading: const _IconBadge(icon: LucideIcons.info),
                        title: Text(loc.version),
                        trailing: Text(
                          _appVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bottom Transparent Logo
              StaggeredEntrance(
                index: 6,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/app_logo-transparent.png',
                      width: 112,
                      height: 112,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  ({String short, Color color}) get _meta {
    switch (code) {
      case 'fil':
        return (short: 'FIL', color: const Color(0xFFFF6584));
      case 'ilo':
        return (short: 'ILO', color: const Color(0xFFFFB347));
      default:
        return (short: 'EN', color: const Color(0xFF4A90D9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [meta.color, meta.color.withValues(alpha: 0.75)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: meta.color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            meta.short,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      trailing: isSelected
          ? const Icon(LucideIcons.circle_check, color: AppColors.primary)
          : const SizedBox(width: 24),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final bool danger;
  const _IconBadge({required this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : AppColors.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
