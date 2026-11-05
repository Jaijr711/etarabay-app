import 'dart:math';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/teacher_pin.dart';
import '../utils/constants.dart';
import 'pin_key.dart';

/// Where the PIN screens begin.
enum PinFlowStart {
  /// Coming back to the app: the PIN, a fingerprint, or the password.
  unlock,

  /// The first time on this phone: make a PIN and enter it again.
  create,

  /// From Settings: the current PIN, then a new one.
  change,
}

enum _Step { enter, password, create, confirm }

/// The teacher's PIN screens: a band with the shield on top, four boxes for
/// the digits and a large keypad below, as in the chosen design.
///
/// After five wrong tries, or for "Forgot the PIN?", the teacher's account
/// password is asked instead and a new PIN is made. [onDone] is called once
/// the dashboard may open (or the new PIN is saved).
class TeacherPinFlow extends StatefulWidget {
  const TeacherPinFlow({
    super.key,
    required this.start,
    required this.onDone,
    this.onLogout,
    this.onCancel,
  });

  final PinFlowStart start;
  final VoidCallback onDone;
  final Future<void> Function()? onLogout;

  /// Shows a close button, for changing the PIN from Settings.
  final VoidCallback? onCancel;

  @override
  State<TeacherPinFlow> createState() => _TeacherPinFlowState();
}

class _TeacherPinFlowState extends State<TeacherPinFlow> {
  static const _errorColor = Color(0xFFC2334D);

  late _Step _step =
      widget.start == PinFlowStart.create ? _Step.create : _Step.enter;
  String _entered = '';
  String _first = '';
  String? _message;
  bool _error = false;
  int _shake = 0;
  int _tries = 0;
  bool _blocked = false;
  bool _busy = false;
  bool _biometric = false;

  final _password = TextEditingController();
  bool _obscure = true;
  bool _checkingPassword = false;
  bool _wrongPassword = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() {
      if (_wrongPassword) setState(() => _wrongPassword = false);
    });
    if (widget.start != PinFlowStart.create) _load();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bool isSet;
    final int tries;
    final bool biometric;
    try {
      isSet = await TeacherPin.isSet();
      tries = await TeacherPin.tries();
      biometric = widget.start == PinFlowStart.unlock &&
          await BiometricService.isAvailable();
    } catch (e) {
      // The PIN cannot be read here: make one, as after the login.
      debugPrint('Could not read the PIN: $e');
      if (mounted) setState(() => _step = _Step.create);
      return;
    }
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _tries = tries;
      _blocked = tries >= TeacherPin.maxTries;
      _biometric = biometric;
      if (_blocked) _message = loc.pinBlocked;
      // No PIN yet: make one, as straight after the login. The password
      // is only for a forgotten or blocked PIN.
      if (!isSet) _step = _Step.create;
    });
    if (_step == _Step.enter && _biometric && !_blocked) _useBiometric();
  }

  Future<void> _useBiometric() async {
    if (_busy) return;
    final loc = AppLocalizations.of(context)!;
    if (await BiometricService.authenticate(loc.lockReason) && mounted) {
      widget.onDone();
    }
  }

  void _digit(String d) {
    if (_busy || _entered.length >= TeacherPin.length) return;
    if (_step == _Step.enter && _blocked) return;
    setState(() {
      _entered += d;
      _error = false;
      if (!_blocked) _message = null;
    });
    if (_entered.length == TeacherPin.length) _complete();
  }

  void _delete() {
    if (_busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  /// The fourth digit is in. Whatever happens, the keypad works again
  /// afterwards: a failure here once left it dead and the teacher stuck.
  Future<void> _complete() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      // Long enough to see the fourth box fill before anything changes.
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      await _completeStep(loc);
    } catch (e) {
      debugPrint('PIN step failed: $e');
      if (mounted) {
        setState(() {
          _entered = '';
          _error = true;
          _shake++;
          _message = loc.couldNotLoad;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeStep(AppLocalizations loc) async {
    switch (_step) {
      case _Step.enter:
        final result = await TeacherPin.check(_entered);
        final tries = await TeacherPin.tries();
        if (!mounted) return;
        if (result == PinCheck.ok) {
          if (widget.start == PinFlowStart.change) {
            setState(() {
              _step = _Step.create;
              _entered = '';
            });
          } else {
            widget.onDone();
          }
          return;
        }
        setState(() {
          _tries = tries;
          _blocked = result == PinCheck.blocked;
          _error = true;
          _shake++;
          _entered = '';
          _message = _blocked
              ? loc.pinBlocked
              : loc.pinWrong(TeacherPin.maxTries - tries);
        });
      case _Step.create:
        setState(() {
          _first = _entered;
          _entered = '';
          _step = _Step.confirm;
        });
      case _Step.confirm:
        if (_entered == _first) {
          await TeacherPin.save(_entered);
          if (!mounted) return;
          widget.onDone();
          return;
        }
        setState(() {
          _first = '';
          _entered = '';
          _step = _Step.create;
          _error = true;
          _shake++;
          _message = loc.teacherPinMismatch;
        });
      case _Step.password:
        break;
    }
  }

  Future<void> _checkPassword() async {
    final password = _password.text;
    if (password.isEmpty || _checkingPassword) return;
    setState(() => _checkingPassword = true);
    final ok = await AuthService().verifyTeacherPassword(password);
    if (!mounted) return;
    setState(() {
      _checkingPassword = false;
      if (ok) {
        _password.clear();
        _step = _Step.create;
        _entered = '';
        _message = null;
        _error = false;
      } else {
        _wrongPassword = true;
      }
    });
  }

  void _toPassword() => setState(() {
        _step = _Step.password;
        _entered = '';
      });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      child: _step == _Step.password ? _buildPassword(loc) : _buildPad(loc),
    );
  }

  /// The top of every PIN screen: the shield on a white disc, the title and
  /// one line under it, on the app's gradient with the same soft circles as
  /// the privacy agreement, and room above for the status bar and notch.
  Widget _band(
      {required String title, required String subtitle, bool compact = false}) {
    final disc = compact ? 46.0 : 56.0;
    Widget circle(double size) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x17FFFFFF),
          ),
        );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -46, top: -36, child: circle(160)),
          Positioned(left: -30, bottom: -54, child: circle(120)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  28, compact ? 12 : 22, 28, compact ? 18 : 26),
              // The whole width of the band, so the block is centred in the
              // band and not just within its own widest line: a short
              // subtitle left the shield and title sitting to the left.
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      width: disc,
                      height: disc,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0x33FFFFFF),
                            width: 6,
                            strokeAlign: BorderSide.strokeAlignOutside),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332D1E66),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(LucideIcons.shield_check,
                          color: AppColors.primary, size: compact ? 22 : 27),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: compact ? 21 : 24,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Padding, not a width cap: the keypad below is measured with
                    // IntrinsicHeight, which a ConstrainedBox's maxWidth does not
                    // reach, so a two-line subtitle came out a line taller than
                    // measured and the page overflowed.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 13 : 14,
                          height: 1.35,
                          color: const Color(0xE6FFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.onCancel != null)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: IconButton(
                    onPressed: widget.onCancel,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x33FFFFFF),
                    ),
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPad(AppLocalizations loc) {
    final title = switch (_step) {
      _Step.enter => widget.start == PinFlowStart.change
          ? loc.currentPinTitle
          : loc.pinTitle,
      _Step.create => loc.createPinTitle,
      _ => loc.confirmPinTitle,
    };
    final subtitle = _step == _Step.enter ? loc.lockBody : loc.createPinBody;
    final showTries = _step == _Step.enter;
    final bottom = MediaQuery.of(context).padding.bottom;

    Widget? footer;
    if (_step == _Step.enter) {
      footer = TextButton(
        onPressed: _toPassword,
        child: Text(
          _blocked ? loc.usePassword : loc.teacherForgotPin,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, box) {
      // A small phone has no room for full-size keys: the last row fell off
      // the bottom of a 568-tall screen. Everything a little smaller there.
      // The full-size pad needs about 720 to show everything, the link
      // for a forgotten PIN included.
      final compact = box.maxHeight < 720;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                _band(title: title, subtitle: subtitle, compact: compact),
                SizedBox(height: compact ? 12 : 26),
                _Shake(
                  trigger: _shake,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < TeacherPin.length; i++)
                        _box(i, compact: compact),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                SizedBox(
                  height: compact ? 28 : 38,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _message ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _errorColor,
                      ),
                    ),
                  ),
                ),
                if (showTries)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < TeacherPin.maxTries; i++)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _tries
                                ? _errorColor
                                : const Color(0xFFE6E8EF),
                          ),
                        ),
                    ],
                  ),
                const Spacer(),
                SizedBox(height: compact ? 4 : 16),
                _keypad(loc, compact: compact),
                SizedBox(height: compact ? 40 : 48, child: footer),
                SizedBox(height: 8 + bottom),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _box(int i, {bool compact = false}) {
    final filled = i < _entered.length;
    final current =
        i == _entered.length && !(_step == _Step.enter && _blocked) && !_busy;
    final Color border;
    final Color fill;
    if (_error || (_step == _Step.enter && _blocked)) {
      border = const Color(0xFFF2A9B6);
      fill = const Color(0xFFFFF5F7);
    } else if (filled) {
      border = AppColors.primary;
      fill = Colors.white;
    } else {
      border = current ? const Color(0xFFB9B3F6) : const Color(0xFFE6E8EF);
      fill = const Color(0xFFF8F9FC);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: compact ? 44 : 50,
      height: compact ? 50 : 58,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 2),
      ),
      child: filled
          ? Center(
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  color: AppColors.textDark,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _keypad(AppLocalizations loc, {bool compact = false}) {
    final keyWidth = compact ? 76.0 : 86.0;
    final keyHeight = compact ? 46.0 : 58.0;
    // Faded only while blocked, which means something. While a PIN is being
    // checked the keys stay as they are and _digit ignores them — fading
    // them for that blinked the whole keypad at every fourth digit.
    final blocked = _step == _Step.enter && _blocked;
    Widget digit(String d) => PinKey(
          width: keyWidth,
          height: keyHeight,
          label: d,
          onTap: blocked ? null : () => _digit(d),
          dimmed: blocked,
          background: const Color(0xFFF1F2F7),
          pressedColor: const Color(0xFFE2E4EE),
          child: Text(
            d,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: compact ? 22 : 25,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        );

    final fingerprint = _step == _Step.enter && _biometric && !_blocked
        ? PinKey(
            width: keyWidth,
            height: keyHeight,
            label: loc.useBiometric,
            onTap: _useBiometric,
            background: const Color(0xFFEEEDFD),
            pressedColor: const Color(0xFFDCD9FB),
            child: const Icon(LucideIcons.fingerprint_pattern,
                size: 28, color: AppColors.primary),
          )
        : SizedBox(width: keyWidth, height: keyHeight);

    final delete = PinKey(
      width: keyWidth,
      height: keyHeight,
      label: loc.deleteDigit,
      onTap: blocked ? null : _delete,
      dimmed: blocked,
      background: Colors.transparent,
      pressedColor: const Color(0xFFF1F2F7),
      child:
          const Icon(LucideIcons.delete, size: 26, color: AppColors.textLight),
    );

    Widget row(List<Widget> keys) => Padding(
          padding: EdgeInsets.only(bottom: compact ? 7 : 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                keys[i],
              ],
            ],
          ),
        );

    return Column(
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([fingerprint, digit('0'), delete]),
      ],
    );
  }

  Widget _buildPassword(AppLocalizations loc) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: 16 + bottom + insets),
      children: [
        _band(title: loc.lockTitle, subtitle: loc.passwordToResetPin),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _password,
                obscureText: _obscure,
                autofocus: true,
                onSubmitted: (_) => _checkPassword(),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: loc.teacherPasswordField,
                  errorText: _wrongPassword ? loc.passwordIncorrect : null,
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? loc.showLabel : loc.hideLabel,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? LucideIcons.eye : LucideIcons.eye_off,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _checkingPassword ? null : _checkPassword,
                  child: _checkingPassword
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(loc.unlockButton),
                ),
              ),
              if (widget.onLogout != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _checkingPassword ? null : widget.onLogout,
                  child: Text(
                    loc.logout,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shakes its child sideways each time [trigger] changes: a wrong PIN.
class _Shake extends StatefulWidget {
  const _Shake({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(_Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        !MediaQuery.of(context).disableAnimations) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            sin(_controller.value * pi * 4) * 8 * (1 - _controller.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
