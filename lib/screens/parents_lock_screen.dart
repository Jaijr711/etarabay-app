import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'for_parents_screen.dart';
import 'privacy_notice_screen.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/parent_pin.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/pin_key.dart';

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
  const ParentsLockScreen(
      {super.key, this.setupOnly = false, this.verifyOnly = false});

  /// Shown straight after a sign-in, to make the code and nothing else.
  ///
  /// The parent is there to hand the phone to their child, not to read a
  /// report, so this returns rather than opening one.
  final bool setupOnly;

  /// Asks for the code before something only a parent should do — signing
  /// the child out — and returns true once it is right, rather than opening
  /// the report. Leaving returns nothing.
  final bool verifyOnly;

  @override
  State<ParentsLockScreen> createState() => _ParentsLockScreenState();
}

enum _Mode { enterPin, setPin, confirmPin, enterLrn }

const _teal = Color(0xFF1EA39B);
const _tealDark = Color(0xFF17514D);
const _mint = Color(0xFFF2FBF9);
const _errorColor = Color(0xFFD23A5A);

class _ParentsLockScreenState extends State<ParentsLockScreen> {
  /// Only the Student Number is typed on the phone's keyboard; the code has
  /// its own keypad.
  final TextEditingController _first = TextEditingController();

  /// The digits on the keypad so far, and the code typed at the first step
  /// of making one, waiting to be typed again.
  String _entered = '';
  String _newPin = '';

  /// Bumped on every wrong code, to shake the circles.
  int _shake = 0;
  bool _done = false;

  _Mode _mode = _Mode.enterPin;
  bool _isLoading = true;
  String? _error;

  String? _studentId;

  /// No code yet on this phone and no parent just signed in: whoever is
  /// holding it proves they have the login card before making one.
  bool _firstCode = false;

  @override
  void initState() {
    super.initState();
    _decideMode();
  }

  @override
  void dispose() {
    _first.dispose();
    super.dispose();
  }

  /// Ask for a code, or ask them to make one.
  Future<void> _decideMode() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _studentId = userProvider.currentStudentId;

    final prefs = await SharedPreferences.getInstance();
    // The one code the parent made at sign-in. This screen used to keep its
    // own per-child copy, which the sign-in never wrote — so a parent who
    // had just made a code was asked to make another.
    final isSet = await ParentPin.isSet(prefs);
    if (!mounted) return;
    // At sign-in the parent has just typed the child's password, so they
    // make the code straight away. Anywhere else a phone without a code is
    // one whose sign-in was cut short, or one updated from a version that
    // kept the code elsewhere — and the hands on it may be the child's,
    // so the Student Number comes first.
    _firstCode = !isSet && !widget.setupOnly;
    setState(() {
      _mode = isSet
          ? _Mode.enterPin
          : (widget.setupOnly ? _Mode.setPin : _Mode.enterLrn);
      _isLoading = false;
    });
  }

  /// Once the Student Number is right: the privacy notice, if this phone's
  /// parent has not read it yet — the sign-in that shows it may be the very
  /// step that was cut short — then the new code.
  Future<void> _afterLrn() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await PrivacyNotice.isAcknowledged(prefs)) {
      if (!mounted) return;
      await Navigator.of(context).push(PremiumPageRoute(
          child: const PrivacyNoticeScreen(requireAcknowledge: true)));
    }
    if (!mounted) return;
    _switchTo(_Mode.setPin);
    setState(() => _isLoading = false);
  }

  void _enter() {
    HapticFeedback.heavyImpact();
    setState(() => _done = true);
    if (widget.setupOnly || widget.verifyOnly) {
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
      _entered = '';
      _shake++;
    });
  }

  void _digit(String d) {
    if (_isLoading || _entered.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == 4) _go();
  }

  void _delete() {
    if (_isLoading || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _switchTo(_Mode mode) => setState(() {
        _mode = mode;
        _entered = '';
        _newPin = '';
        _error = null;
        _first.clear();
      });

  /// Made in two steps: the code, then the same code again. A mismatch
  /// starts over from the first step rather than leaving the parent to guess
  /// which of the two was the slip.
  Future<void> _submitNewPin() async {
    final loc = AppLocalizations.of(context)!;
    if (_entered.length < 4) return;

    if (_mode == _Mode.setPin) {
      setState(() {
        _newPin = _entered;
        _entered = '';
        _mode = _Mode.confirmPin;
      });
      return;
    }
    final a = _newPin;
    if (_entered != a) {
      _newPin = '';
      _mode = _Mode.setPin;
      _reject(loc.pinMismatch);
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    // Hashed with the same pepper the LRN uses, so a code is no more readable
    // on the device than the number it replaces.
    await ParentPin.write(prefs, a);
    if (!mounted) return;
    _enter();
  }

  Future<void> _submitPin() async {
    final entered = _entered;
    final loc = AppLocalizations.of(context)!;
    if (entered.length < 4) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final matches = await ParentPin.matches(prefs, entered);
    if (!mounted) return;

    if (matches) {
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
          await _afterLrn();
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
    final bottom = MediaQuery.of(context).padding.bottom;

    final String bubble;
    final String title;
    final String subtitle;
    switch (_mode) {
      case _Mode.enterPin:
        final name = _childName(context);
        title = loc.enterParentPin;
        if (widget.verifyOnly) {
          bubble = loc.parentPinBubbleLogout;
          subtitle = name == null
              ? loc.parentPinLogoutSubPlain
              : loc.parentPinLogoutSub(name);
        } else {
          bubble = loc.parentPinBubbleEnter;
          subtitle = name == null
              ? loc.parentPinEnterSubPlain
              : loc.parentPinEnterSub(name);
        }
      case _Mode.setPin:
        bubble = loc.parentPinBubbleSet;
        title = loc.setParentPin;
        subtitle = loc.setParentPinNote;
      case _Mode.confirmPin:
        bubble = loc.parentPinBubbleConfirm;
        title = loc.confirmParentPin;
        subtitle = loc.parentPinConfirmSub;
      case _Mode.enterLrn:
        bubble =
            _firstCode ? loc.parentPinBubbleFirst : loc.parentPinBubbleForgot;
        title = loc.enterLRN;
        subtitle = _firstCode ? loc.parentPinFirstSub : loc.parentPinForgotSub;
    }

    return PopScope(
      // Nothing to go back to at sign-in: the code is made here or the phone
      // reaches the child with For Parents unlocked.
      canPop: !widget.setupOnly,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7F5EF), Color(0xFFE9E4FF)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: widget.setupOnly
                ? null
                : CustomBackButton(
                    iconColor: AppColors.textDark,
                    backgroundColor: const Color(0xBFFFFFFF),
                    onPressed: () => Navigator.pop(context),
                  ),
          ),
          body: LayoutBuilder(builder: (context, box) {
            // The full-size scene and keys need about 600 below the app bar;
            // a small phone gets a smaller Tarabay and shorter keys.
            final compact = box.maxHeight < 600;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          _scene(bubble, compact: compact),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                  22, compact ? 14 : 20, 22, 8 + bottom),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: compact ? 19 : 21,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  if (_mode == _Mode.enterLrn)
                                    ..._lrnForm(loc)
                                  else
                                    ..._pinPad(loc, compact: compact),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// The child's first name, for "to see Ana's report".
  String? _childName(BuildContext context) {
    final name = Provider.of<UserProvider>(context, listen: false)
            .userProfile
            ?.name
            .trim() ??
        '';
    if (name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  /// Tarabay keeping watch: a speech bubble, the mascot and a lock badge
  /// that turns to a tick once the door opens.
  Widget _scene(String bubble, {required bool compact}) {
    final height = compact ? 118.0 : 160.0;
    final mascot = compact ? 104.0 : 140.0;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 20,
            top: compact ? 0 : 8,
            right: mascot + 26,
            // As wide as its words, up to the mascot.
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A1E3C50),
                        blurRadius: 10,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Text(
                  bubble,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: compact ? 14.5 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: compact ? 14 : 26,
            child: const Row(
              children: [
                Icon(Icons.star_rounded, size: 20, color: Color(0xFFF5B301)),
                SizedBox(width: 6),
                Icon(Icons.star_rounded, size: 13, color: Color(0xFFF5B301)),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: -12,
            child: Image.asset(
              'assets/images/mascot_wave.webp',
              height: mascot,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 20,
            bottom: compact ? 4 : 10,
            child: Container(
              width: compact ? 36 : 42,
              height: compact ? 36 : 42,
              decoration: BoxDecoration(
                color: _teal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                _done ? LucideIcons.check : LucideIcons.lock,
                size: compact ? 16 : 19,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pinPad(AppLocalizations loc, {required bool compact}) {
    final making = _mode == _Mode.setPin || _mode == _Mode.confirmPin;
    return [
      SizedBox(height: compact ? 8 : 12),
      if (making) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepBar(true),
            const SizedBox(width: 6),
            _stepBar(_mode == _Mode.confirmPin),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
      ],
      _Shake(
        trigger: _shake,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++) _circle(i, compact: compact),
          ],
        ),
      ),
      SizedBox(
        height: compact ? 26 : 32,
        child: Center(
          child: Text(
            _error ?? '',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _errorColor,
            ),
          ),
        ),
      ),
      const Spacer(),
      _keypad(loc, compact: compact),
      ConstrainedBox(
        // Room for the link even when its words take two lines.
        constraints: BoxConstraints(minHeight: compact ? 40 : 46),
        // Only offered once a code exists to be forgotten.
        child: _mode == _Mode.enterPin
            ? TextButton(
                onPressed: _isLoading ? null : () => _switchTo(_Mode.enterLrn),
                child: Text(
                  loc.forgotPin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF178C85),
                  ),
                ),
              )
            : null,
      ),
    ];
  }

  Widget _stepBar(bool on) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 6,
        decoration: BoxDecoration(
          color: on ? _teal : const Color(0xFFE4E3F0),
          borderRadius: BorderRadius.circular(3),
        ),
      );

  Widget _circle(int i, {required bool compact}) {
    final filled = i < _entered.length;
    final size = compact ? 28.0 : 32.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? _teal
            : (_error != null
                ? const Color(0xFFFFEFF2)
                : const Color(0xFFEEF7F5)),
      ),
      child: filled
          ? Icon(LucideIcons.check,
              size: compact ? 15 : 17, color: Colors.white)
          : null,
    );
  }

  Widget _keypad(AppLocalizations loc, {required bool compact}) {
    final height = compact ? 42.0 : 50.0;
    // Always live: _digit and _delete ignore taps while a code is checked,
    // so the keys need not fade (and blink back) to say so.
    Widget digit(String d) => PinKey(
          height: height,
          label: d,
          onTap: () => _digit(d),
          background: _mint,
          pressedColor: const Color(0xFFD9F1EC),
          child: Text(
            d,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: compact ? 21 : 23,
              fontWeight: FontWeight.w600,
              color: _tealDark,
            ),
          ),
        );
    final delete = PinKey(
      height: height,
      label: loc.deleteDigit,
      onTap: _delete,
      background: Colors.transparent,
      pressedColor: _mint,
      child: const Icon(LucideIcons.delete, size: 24, color: _teal),
    );
    Widget row(List<Widget> keys) => Padding(
          padding: EdgeInsets.only(bottom: compact ? 7 : 9),
          child: Row(
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                Expanded(child: keys[i]),
              ],
            ],
          ),
        );
    return Column(
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([SizedBox(height: height), digit('0'), delete]),
      ],
    );
  }

  /// The way back in: the Student Number on the teacher's login card.
  List<Widget> _lrnForm(AppLocalizations loc) {
    return [
      const SizedBox(height: 22),
      TextField(
        controller: _first,
        obscureText: true,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _go(),
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 2),
        decoration: InputDecoration(
          hintText: loc.lRN,
          hintStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
          errorText: _error,
          filled: true,
          fillColor: _mint,
          prefixIcon: const Icon(LucideIcons.id_card, color: _teal, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _teal, width: 2),
          ),
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _go,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  loc.verifyLRN,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
        ),
      ),
      const SizedBox(height: 4),
      // Nothing to remember before the first code is made.
      if (!_firstCode)
        TextButton(
          onPressed: _isLoading ? null : () => _switchTo(_Mode.enterPin),
          child: Text(
            loc.parentPinRemembered,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF178C85),
            ),
          ),
        ),
      const Spacer(),
    ];
  }

  void _go() {
    switch (_mode) {
      case _Mode.setPin:
      case _Mode.confirmPin:
        _submitNewPin();
      case _Mode.enterPin:
        _submitPin();
      case _Mode.enterLrn:
        _submitLrn();
    }
  }
}

/// Shakes its child sideways each time [trigger] changes: a wrong code.
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
