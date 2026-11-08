import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

/// Why a login did not go through, as the sheet tells it.
enum LoginProblem {
  /// The phone could not reach the server. Nothing to do with the password.
  connection,
  usernameNotFound,
  wrongStudentNumber,

  /// "Daycare Teacher" typed into the child's login.
  teacherOnChildLogin,
  emptyFields,
  wrongTeacherPassword,

  /// The teacher's first login on this phone, with no signal.
  needsInternet,

  /// The fingerprint's saved password no longer works.
  passwordChanged,

  /// Not a problem: how a newcomer logs in, from the link under the button.
  howTo,
}

/// What a parent or teacher sees when a login fails: what happened, in
/// plain words, and what they can do about it.
///
/// It replaced a red snackbar that said one sentence for three seconds and
/// nothing about what to do. "Could not reach the server" on a new phone
/// left a parent typing the same right password over and over.
class LoginProblemSheet extends StatelessWidget {
  const LoginProblemSheet({
    super.key,
    required this.problem,
    this.code,
    this.detail,
    this.onRetry,
  });

  final LoginProblem problem;

  /// A short mark of where a connection failed (N1, N2, N3), for the
  /// developer reading a parent's screenshot. Shown on [LoginProblem.connection]
  /// only.
  final String? code;

  /// The error itself, shown when the code is tapped, for a screenshot.
  final String? detail;

  /// Shown as "Try again" on the problems another try can fix.
  final VoidCallback? onRetry;

  static Future<void> show(
    BuildContext context,
    LoginProblem problem, {
    String? code,
    String? detail,
    VoidCallback? onRetry,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            LoginProblemSheet(
                problem: problem, code: code, detail: detail, onRetry: onRetry),
      );

  bool get _canRetry =>
      onRetry != null &&
      (problem == LoginProblem.connection ||
          problem == LoginProblem.needsInternet);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final look = _look(loc);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottom),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: look.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(look.icon, size: 36, color: look.color),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                look.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                look.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: AppColors.textLight,
                ),
              ),
              if (problem == LoginProblem.howTo) ...[
                const SizedBox(height: 16),
                const _SampleCard(),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem == LoginProblem.howTo
                          ? loc.loginProblemSteps
                          : loc.loginProblemTryThis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < look.steps.length; i++)
                      _Step(number: i + 1, text: look.steps[i], color: look.color),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_canRetry) ...[
                _BigButton(
                  label: loc.loginProblemRetry,
                  icon: LucideIcons.rotate_cw,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    onRetry!();
                  },
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    loc.loginProblemOk,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ] else
                _BigButton(
                  label: loc.loginProblemOk,
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).pop(),
                ),
              if (problem == LoginProblem.connection && code != null)
                _CodeLine(code: loc.loginProblemCode(code!), detail: detail),
            ],
          ),
        ),
      ),
    );
  }

  _Look _look(AppLocalizations loc) => switch (problem) {
        LoginProblem.connection => _Look(
            LucideIcons.wifi_off,
            const Color(0xFFF08C00),
            loc.loginProblemConnectionTitle,
            loc.loginProblemConnectionBody,
            [
              loc.loginProblemConnectionStep1,
              loc.loginProblemConnectionStep2,
              loc.loginProblemConnectionStep3,
              loc.loginProblemConnectionStep4,
            ],
          ),
        LoginProblem.usernameNotFound => _Look(
            LucideIcons.user_search,
            const Color(0xFF2C7BE5),
            loc.loginProblemUsernameTitle,
            loc.loginProblemUsernameBody,
            [loc.loginProblemUsernameStep1, loc.loginProblemUsernameStep2],
          ),
        LoginProblem.wrongStudentNumber => _Look(
            LucideIcons.key_round,
            const Color(0xFFE5484D),
            loc.loginProblemNumberTitle,
            loc.loginProblemNumberBody,
            [
              loc.loginProblemNumberStep1,
              loc.loginProblemNumberStep2,
              loc.loginProblemNumberStep3,
            ],
          ),
        LoginProblem.teacherOnChildLogin => _Look(
            LucideIcons.school,
            AppColors.navSettings,
            loc.loginProblemTeacherHereTitle,
            loc.loginProblemTeacherHereBody,
            [loc.loginProblemTeacherHereStep1(loc.teacherLoginButton)],
          ),
        LoginProblem.emptyFields => _Look(
            LucideIcons.pencil_line,
            const Color(0xFF2E9E5B),
            loc.loginProblemEmptyTitle,
            loc.loginProblemEmptyBody,
            [
              loc.loginProblemEmptyStep1(loc.loginButton),
              loc.loginProblemEmptyStep2,
            ],
          ),
        LoginProblem.wrongTeacherPassword => _Look(
            LucideIcons.lock_keyhole,
            const Color(0xFFE5484D),
            loc.loginProblemTeacherWrongTitle,
            loc.loginProblemTeacherWrongBody,
            [
              loc.loginProblemTeacherWrongStep1,
              loc.loginProblemTeacherWrongStep2,
            ],
          ),
        LoginProblem.needsInternet => _Look(
            LucideIcons.wifi,
            const Color(0xFFF08C00),
            loc.loginProblemNeedsInternetTitle,
            loc.loginProblemNeedsInternetBody,
            [loc.loginProblemNeedsInternetStep1],
          ),
        LoginProblem.passwordChanged => _Look(
            LucideIcons.fingerprint_pattern,
            AppColors.navSettings,
            loc.loginProblemPasswordChangedTitle,
            loc.loginProblemPasswordChangedBody,
            [loc.loginProblemPasswordChangedStep1],
          ),
        LoginProblem.howTo => _Look(
            LucideIcons.book_open,
            AppColors.primary,
            loc.loginProblemHowToTitle,
            loc.loginProblemHowToBody,
            [
              loc.loginProblemHowToStep1,
              loc.loginProblemHowToStep2,
              loc.loginProblemHowToStep3(loc.loginButton),
            ],
          ),
      };
}

/// The small grey code, which opens to the error itself when tapped.
class _CodeLine extends StatefulWidget {
  const _CodeLine({required this.code, this.detail});
  final String code;
  final String? detail;

  @override
  State<_CodeLine> createState() => _CodeLineState();
}

class _CodeLineState extends State<_CodeLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    const grey = TextStyle(fontSize: 11, color: Color(0xFFB0B8C4));
    final detail = widget.detail;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: detail == null ? null : () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          children: [
            Text(widget.code, textAlign: TextAlign.center, style: grey),
            if (_open && detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(detail,
                    textAlign: TextAlign.center, style: grey),
              ),
          ],
        ),
      ),
    );
  }
}

/// A login card like the one the teacher hands over, with where each line
/// goes. A newcomer has seen the card, not this screen.
class _SampleCard extends StatelessWidget {
  const _SampleCard();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Widget line(String label, String value, String box) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textLight)),
                      Text(value,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrow_right,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              SizedBox(
                width: 96,
                child: Text(box,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.id_card, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(loc.loginCardTitle,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
          ]),
          line(loc.loginUser, 'ana1234', loc.loginHowToFirstBox),
          line(loc.password, 'DC-2026-0001', loc.loginHowToSecondBox),
        ],
      ),
    );
  }
}

class _Look {
  const _Look(this.icon, this.color, this.title, this.body, this.steps);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<String> steps;
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, required this.color});
  final int number;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
}
