import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/auth_service.dart';
import 'developer_dashboard_screen.dart';

/// The hidden developer dashboard's own gate. Reached only by tapping the
/// version number in Settings seven times — there is no visible menu item
/// or link anywhere in the app, by design (see the tap counter in
/// SettingsScreen). Deliberately styled unlike the rest of the app: a
/// child who ever did stumble onto this screen should immediately read it
/// as "not part of the game" rather than another colourful menu to tap
/// through.
class DeveloperLoginScreen extends StatefulWidget {
  const DeveloperLoginScreen({super.key});

  @override
  State<DeveloperLoginScreen> createState() => _DeveloperLoginScreenState();
}

class _DeveloperLoginScreenState extends State<DeveloperLoginScreen> {
  final _authService = AuthService();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = true;
  bool _needsSetup = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    await _authService.ensureAuthenticated();
    final hasPassword = await _authService.hasDeveloperPassword();
    if (!mounted) return;
    setState(() {
      _needsSetup = !hasPassword;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    // Same 6-character floor whether this is the first-run setup or an
    // ordinary login — a login attempt shorter than that can never match
    // a password this screen would ever have accepted when it was set.
    if (password.length < 6) {
      setState(() => _error = 'Kailangan ng 6+ characters.');
      return;
    }

    if (_needsSetup) {
      if (password != _confirmController.text.trim()) {
        setState(() => _error = 'Hindi magkatugma ang password.');
        return;
      }
      setState(() {
        _submitting = true;
        _error = null;
      });
      final ok = await _authService.setDeveloperPassword(password);
      if (!mounted) return;
      if (ok) {
        _enter();
      } else {
        setState(() {
          _submitting = false;
          _error = 'Hindi na-save. Subukan ulit.';
        });
      }
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final valid = await _authService.verifyDeveloperPassword(password);
    if (!mounted) return;
    if (valid) {
      _enter();
    } else {
      setState(() {
        _submitting = false;
        _error = 'Maling password.';
      });
    }
  }

  void _enter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DeveloperDashboardScreen()),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white54))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.terminal,
                            color: Colors.white38, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          _needsSetup
                              ? 'Itakda ang Developer Password'
                              : 'Developer Dashboard',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _field(_passwordController, 'Password'),
                        if (_needsSetup) ...[
                          const SizedBox(height: 12),
                          _field(_confirmController, 'Ulitin ang Password'),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF238636),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_needsSetup ? 'I-save' : 'Pasok'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Bumalik',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF58A6FF)),
        ),
      ),
    );
  }
}
