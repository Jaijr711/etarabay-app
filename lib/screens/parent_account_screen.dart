import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/biometric_setup.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_back_button.dart';

/// Parent-controlled management of the child's login. The parent (not the
/// child) can change the child's password (LRN), optionally the username, and
/// enable fingerprint/face login on this device.
///
/// Design decision: the username stays the teacher-owned roster identity — if
/// the parent changes it, the change is written straight back to Firestore so
/// the teacher dashboard stays in sync.
class ParentAccountScreen extends StatefulWidget {
  const ParentAccountScreen({super.key});

  @override
  State<ParentAccountScreen> createState() => _ParentAccountScreenState();
}

class _ParentAccountScreenState extends State<ParentAccountScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  String? _studentId;
  bool _loading = true;
  bool _saving = false;
  bool _obscure = true;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _studentId = userProvider.currentStudentId;

    final available = await BiometricService.isAvailable();
    final enabled =
        await BiometricService.isEnabled(BiometricService.studentKey);

    String? username;
    if (_studentId != null) {
      username = await _authService.getStudentUsername(_studentId!);
    }

    if (!mounted) return;
    setState(() {
      _usernameCtrl.text = username ?? '';
      _biometricAvailable = available;
      _biometricEnabled = enabled && available;
      _loading = false;
    });
  }

  void _snack(String msg, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveCredentials() async {
    if (_studentId == null) return;
    final username = _usernameCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (username.isEmpty) {
      _snack(AppLocalizations.of(context)!.usernameEmpty, LucideIcons.circle_alert, Colors.red);
      return;
    }
    if (newPass.isNotEmpty && newPass != confirm) {
      _snack(AppLocalizations.of(context)!.passwordsDoNotMatch, LucideIcons.circle_alert, Colors.red);
      return;
    }
    if (newPass.isNotEmpty && newPass.length < 4) {
      _snack(AppLocalizations.of(context)!.authPasswordTooShort, LucideIcons.circle_alert,
          Colors.red);
      return;
    }

    setState(() => _saving = true);
    final result = await _authService.updateStudentCredentials(
      studentId: _studentId!,
      username: username,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['status'] != 'Success') {
      _snack(result['message']?.toString() ?? 'Could not save changes.',
          LucideIcons.circle_alert, Colors.red);
      return;
    }

    // Keep biometric in sync with any new credentials.
    if (_biometricEnabled) {
      await BiometricService.saveCredentials(
        slot: BiometricService.studentKey,
        username: username,
        password: newPass.isNotEmpty
            ? newPass
            : ((await BiometricService.getCredentials(
                    BiometricService.studentKey))?['password'] ??
                ''),
        extra: {'name': Provider.of<UserProvider>(context, listen: false)
                .userProfile
                ?.name ??
            ''},
      );
    }

    _newPassCtrl.clear();
    _confirmCtrl.clear();
    _snack(AppLocalizations.of(context)!.credentialsUpdated, LucideIcons.circle_check, AppColors.success);
  }


  /// Changing the code that opens this report.
  ///
  /// It is set the first time a parent comes through the lock screen, and
  /// until now there was no way to change it afterwards — the only credential
  /// on this screen that is actually the parent's own was the one they could
  /// not touch.
  ///
  /// The current code is asked for first. Anyone who can reach this screen has
  /// already entered it once, but a phone left unlocked on a table has not.
  Future<void> _changeParentCode() async {
    final loc = AppLocalizations.of(context)!;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.changeCode, style: const TextStyle(fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: currentCtrl,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: loc.currentCode,
              counterText: '',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtrl,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: loc.newCode,
              counterText: '',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: Text(loc.save),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (newCtrl.text.trim().length < 4) return;

    final prefs = await SharedPreferences.getInstance();
    // Same key and same hashing as the lock screen writes.
    final key = 'parent_pin_${_studentId ?? 'none'}';
    final stored = prefs.getString(key) ?? '';
    if (!mounted) return;

    if (stored.isNotEmpty &&
        stored != AuthService.hashLrn(currentCtrl.text.trim())) {
      _snack(loc.wrongPin, LucideIcons.circle_alert, Colors.red);
      return;
    }

    await prefs.setString(key, AuthService.hashLrn(newCtrl.text.trim()));
    if (!mounted) return;
    _snack(loc.codeChanged, LucideIcons.circle_check, AppColors.success);
  }

  Future<void> _toggleBiometric(bool value) async {
    final id = _studentId;
    if (id == null) return;

    final loc = AppLocalizations.of(context)!;
    final on = await setBiometricEnabled(
      context: context,
      enable: value,
      slot: BiometricService.studentKey,
      passwordLabel: loc.confirmChildStudentNumber,
      numericPassword: true,
      verify: (password) =>
          _authService.verifyStudentPassword(id, password),
      wrongPasswordMessage: loc.studentNumberIncorrect,
      credentials: (_) async => {
        'username': _usernameCtrl.text.trim(),
        // The child's name rides along so the login screen can greet them
        // by it without another round trip.
        'extra': {
          'name': Provider.of<UserProvider>(context, listen: false)
                  .userProfile
                  ?.name ??
              '',
        },
      },
      notify: _snack,
    );
    if (!mounted) return;
    setState(() => _biometricEnabled = on);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CustomBackButton(
          iconColor: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.accountSecurity,
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _studentId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.noSessionLogInFirst,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // The parent's own code first: it is the one thing on
                    // this screen that belongs to them, and the one they came
                    // looking for.
                    _card(
                      title: AppLocalizations.of(context)!.yourCode,
                      icon: LucideIcons.lock,
                      children: [
                        Text(AppLocalizations.of(context)!.yourCodeNote,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _changeParentCode,
                            icon: const Icon(LucideIcons.key_round, size: 18),
                            label: Text(AppLocalizations.of(context)!.changeCode),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.4)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _card(
                      title: AppLocalizations.of(context)!.childLogin,
                      icon: LucideIcons.key_round,
                      children: [
                        TextField(
                          controller: _usernameCtrl,
                          decoration: _deco('Username', LucideIcons.user),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPassCtrl,
                          obscureText: _obscure,
                          keyboardType: TextInputType.number,
                          decoration: _deco(
                            AppLocalizations.of(context)!.newPasswordStudentNumber,
                            LucideIcons.lock,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? LucideIcons.eye_off
                                      : LucideIcons.eye,
                                  size: 18),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          keyboardType: TextInputType.number,
                          decoration: _deco(
                              'Confirm new password', LucideIcons.lock),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.childLoginNote} '
                          '${AppLocalizations.of(context)!.blankToKeepPassword}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveCredentials,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(AppLocalizations.of(context)!.saveChanges,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_biometricAvailable)
                      _card(
                        title: AppLocalizations.of(context)!.securityHeader,
                        icon: LucideIcons.shield,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.fingerprint_pattern,
                                  color: AppColors.primary, size: 20),
                            ),
                            title: Text(AppLocalizations.of(context)!.biometricLogin),
                            subtitle: Text(AppLocalizations.of(context)!.childLoginNote),
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                          ),
                        ],
                      )
                    else
                      _card(
                        title: AppLocalizations.of(context)!.securityHeader,
                        icon: LucideIcons.shield,
                        children: [
                          Row(children: [
                            Icon(LucideIcons.info,
                                size: 18, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .biometricUnavailable,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ]),
                        ],
                      ),
                  ],
                ),
    );
  }

  InputDecoration _deco(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
