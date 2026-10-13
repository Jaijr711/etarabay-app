import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'for_parents_screen.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_back_button.dart';

/// The door between the child's app and the parents' report.
///
/// It used to ask for the child's LRN: twelve digits, typed in full, every
/// time. That is not a secret — it is the number the teacher enrolled them
/// with, and it is printed on the school's own paperwork, so anyone who has
/// seen the form can walk through. It is also twelve digits to remember, which
/// in practice means the parent goes and finds the form.
///
/// A parent sets their own four-digit code the first time they come here, and
/// types four digits after that. The LRN stays as the way back in when the
/// code is forgotten, which is the one job it is actually suited to: a
/// recovery route the school can help with.
class ParentsLockScreen extends StatefulWidget {
  const ParentsLockScreen({super.key, this.setupOnly = false});

  /// Shown straight after a sign-in, to make the code and nothing else.
  ///
  /// The parent is there to hand the phone to their child, not to read a
  /// report, so this returns rather than opening one.
  final bool setupOnly;

  @override
  State<ParentsLockScreen> createState() => _ParentsLockScreenState();
}

enum _Mode { enterPin, setPin, enterLrn }

class _ParentsLockScreenState extends State<ParentsLockScreen> {
  final TextEditingController _first = TextEditingController();
  final TextEditingController _second = TextEditingController();

  _Mode _mode = _Mode.enterPin;
  bool _isLoading = true;
  String? _error;

  /// Per child, so two children on one device do not share a code.
  String get _pinKey => 'parent_pin_${_studentId ?? 'none'}';
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _decideMode();
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  /// Ask for a code, or ask them to make one.
  Future<void> _decideMode() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _studentId = userProvider.currentStudentId;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (!mounted) return;
    setState(() {
      _mode = (stored == null || stored.isEmpty) ? _Mode.setPin : _Mode.enterPin;
      _isLoading = false;
    });
  }

  void _enter() {
    HapticFeedback.heavyImpact();
    if (widget.setupOnly) {
      Navigator.pop(context, true);
      return;
    }
    Navigator.pushReplacement(
      context,
      PremiumPageRoute(child: const ForParentsScreen()),
    );
  }

  void _reject(String message) {
    HapticFeedback.vibrate();
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  Future<void> _submitNewPin() async {
    final a = _first.text.trim();
    final b = _second.text.trim();
    final loc = AppLocalizations.of(context)!;

    if (a.length < 4) return;
    if (a != b) {
      _reject(loc.pinMismatch);
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    // Hashed with the same pepper the LRN uses, so a code is no more readable
    // on the device than the number it replaces.
    await prefs.setString(_pinKey, AuthService.hashLrn(a));
    if (!mounted) return;
    _enter();
  }

  Future<void> _submitPin() async {
    final entered = _first.text.trim();
    final loc = AppLocalizations.of(context)!;
    if (entered.length < 4) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey) ?? '';
    if (!mounted) return;

    if (stored.isNotEmpty && stored == AuthService.hashLrn(entered)) {
      _enter();
      return;
    }
    _reject(loc.wrongPin);
  }

  /// The way back in when the code is forgotten.
  ///
  /// Unchanged from what the whole door used to be, including reading through
  /// Firestore's offline cache, so it still works with no signal. A correct
  /// LRN lets the parent set a new code rather than dropping them straight
  /// into the report — otherwise the forgotten code would stay forgotten.
  Future<void> _submitLrn() async {
    final lrn = _first.text.trim();
    final loc = AppLocalizations.of(context)!;
    if (lrn.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_studentId == null) {
        _reject(loc.invalidLRN);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(_studentId)
          .get();

      if (doc.exists) {
        final storedHash = (doc.data()?['lrnHash'] ?? '').toString();
        final legacyLrn = (doc.data()?['lrn'] ?? '').toString().trim();
        final matches = storedHash.isNotEmpty
            ? storedHash == AuthService.hashLrn(lrn)
            : (legacyLrn.isNotEmpty && legacyLrn == lrn);
        if (matches) {
          if (!mounted) return;
          _first.clear();
          _second.clear();
          setState(() {
            _mode = _Mode.setPin;
            _isLoading = false;
            _error = null;
          });
          return;
        }
      }
      _reject(loc.invalidLRN);
    } catch (e) {
      debugPrint('Error verifying LRN: $e');
      _reject(loc.invalidLRN);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final settingUp = _mode == _Mode.setPin;
    final byLrn = _mode == _Mode.enterLrn;

    return PopScope(
      // Nothing to go back to at sign-in: the code is made here or the phone
      // reaches the child with For Parents unlocked.
      canPop: !widget.setupOnly,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.setupOnly
            ? null
            : CustomBackButton(
                iconColor: AppColors.textDark,
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(settingUp ? LucideIcons.shield : LucideIcons.lock,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                loc.parents,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                byLrn
                    ? loc.enterLRN
                    : (settingUp ? loc.setParentPin : loc.enterParentPin),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
              if (settingUp) ...[
                const SizedBox(height: 10),
                Text(
                  loc.setParentPinNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 32),

              _field(
                controller: _first,
                // Follows the mode, like the heading above it. This said
                // "Enter your code" while the heading said "Set a code", to a
                // parent who had never set one.
                label: byLrn
                    ? loc.lRN
                    : (settingUp ? loc.newParentPin : loc.enterParentPin),
                digitsOnly: !byLrn,
                error: _error,
                onSubmit: _go,
              ),

              if (settingUp) ...[
                const SizedBox(height: 16),
                _field(
                  controller: _second,
                  label: loc.confirmParentPin,
                  digitsOnly: true,
                  onSubmit: _go,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _go,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          // Three modes, three different jobs. The old
                          // label belonged to a screen that only ever did
                          // one of them, so a parent typing four digits was
                          // being asked to "Verify Student Number".
                          settingUp
                              ? loc.save
                              : (byLrn ? loc.verifyLRN : loc.openReport),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              // Only offered once a code exists to be forgotten.
              if (_mode == _Mode.enterPin) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _mode = _Mode.enterLrn;
                    _first.clear();
                    _error = null;
                  }),
                  child: Text(loc.forgotPin,
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _go() {
    switch (_mode) {
      case _Mode.setPin:
        _submitNewPin();
      case _Mode.enterPin:
        _submitPin();
      case _Mode.enterLrn:
        _submitLrn();
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool digitsOnly,
    String? error,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
      obscureText: true,
      maxLength: digitsOnly ? 4 : null,
      inputFormatters:
          digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: (_) => onSubmit?.call(),
      style: const TextStyle(letterSpacing: 8, fontSize: 20),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: digitsOnly ? '••••' : '••••••••••••',
        hintStyle: const TextStyle(letterSpacing: 2),
        errorText: error,
        prefixIcon: const Icon(LucideIcons.key_round),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
