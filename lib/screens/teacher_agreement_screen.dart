import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/teacher_privacy.dart';
import 'privacy_notice_screen.dart';
import '../utils/constants.dart';

/// The teacher's promise to keep the children's details to themselves.
///
/// Shown before the dashboard the first time a teacher uses this phone, and
/// it cannot be backed out of: the dashboard opens on "agree", and "log out"
/// is the only other way off it. It pops `true` once agreed and `false` for
/// log out. From Settings it opens [readOnly], with who agreed and when.
class TeacherAgreementScreen extends StatefulWidget {
  const TeacherAgreementScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  State<TeacherAgreementScreen> createState() => _TeacherAgreementScreenState();
}

class _TeacherAgreementScreenState extends State<TeacherAgreementScreen> {
  static const _green = Color(0xFF1F7A45);
  static const _line = Color(0xFFE6E8EF);

  final _nameController = TextEditingController();
  bool _checked = false;
  bool _saving = false;
  ({String name, DateTime date})? _agreed;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    if (widget.readOnly) {
      TeacherPrivacy.agreement().then((a) {
        if (mounted) setState(() => _agreed = a);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canAgree =>
      _checked && _nameController.text.trim().length > 1 && !_saving;

  Future<void> _agree() async {
    setState(() => _saving = true);
    await TeacherPrivacy.record(_nameController.text);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _formatDate(DateTime d) =>
      MaterialLocalizations.of(context).formatMediumDate(d);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).padding.bottom;
    // Each promise with the sign and colour that says what it is about.
    final promises = [
      (LucideIcons.eye_off, AppColors.primary, loc.privacyPromise1),
      (LucideIcons.book_open, const Color(0xFF22A6A4), loc.privacyPromise2),
      (LucideIcons.lock, AppColors.secondary, loc.privacyPromise3),
      (
        LucideIcons.triangle_alert,
        const Color(0xFFE08A00),
        loc.privacyPromise4
      ),
    ];

    return PopScope(
      canPop: widget.readOnly,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        // One scroll for all of it: on a small phone the promises are read
        // first and the signature is reached by scrolling, never hidden.
        body: ListView(
          padding: EdgeInsets.only(bottom: 16 + bottom),
          children: [
            _buildBand(loc),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.privacyAgreementIntro,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final p in promises) ...[
                    _buildPromise(p.$1, p.$2, p.$3),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  _buildSignature(loc),
                  if (widget.readOnly) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PrivacyNoticeScreen())),
                        icon: const Icon(LucideIcons.shield_check, size: 17),
                        label: Text(loc.privacyNoticeTitle),
                      ),
                    ),
                  ],
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 12),
                    _buildAgreeBox(loc),
                    const SizedBox(height: 14),
                    _buildContinue(loc),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBand(AppLocalizations loc) {
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Two soft circles in the corner, as on the app's other headers.
          Positioned(
            right: -40,
            top: -30,
            child: _circle(150),
          ),
          Positioned(
            right: 60,
            bottom: -50,
            child: _circle(100),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.shield_check,
                            color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      if (widget.readOnly)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          icon: const Icon(LucideIcons.x, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc.privacyAgreementTitle,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.privacyAgreementSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x55FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scale,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          loc.lawPill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x14FFFFFF),
        ),
      );

  Widget _buildPromise(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (widget.readOnly && _agreed != null) ...[
            const SizedBox(width: 8),
            const Icon(LucideIcons.circle_check, size: 20, color: _green),
          ],
        ],
      ),
    );
  }

  /// A name signed over a line, with the day it will be recorded on.
  Widget _buildSignature(AppLocalizations loc) {
    final agreed = _agreed;
    final Widget body;
    if (widget.readOnly) {
      body = Row(
        children: [
          const Icon(LucideIcons.circle_check, size: 20, color: _green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              agreed == null
                  ? '—'
                  : loc.agreedOn(agreed.name, _formatDate(agreed.date)),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.signature,
                  size: 16, color: AppColors.textLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.signatureLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const Icon(LucideIcons.calendar,
                  size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: loc.signatureHint,
              hintStyle: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Color(0xFFB8BECB),
              ),
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 10, bottom: 6),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          // The line the name is signed on.
          Container(height: 1.5, color: const Color(0xFFCBD0DC)),
        ],
      );
    }
    return CustomPaint(
      foregroundPainter:
          const _DashedBorder(color: Color(0xFFB8BECB), radius: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: body,
      ),
    );
  }

  Widget _buildAgreeBox(AppLocalizations loc) {
    return Material(
      color: _checked ? const Color(0xFFF4F3FE) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _checked ? AppColors.primary : _line,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _checked = !_checked),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _checked ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color:
                        _checked ? AppColors.primary : const Color(0xFFB8BECB),
                    width: 2,
                  ),
                ),
                child: _checked
                    ? const Icon(LucideIcons.check,
                        size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.agreeCheck,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinue(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _canAgree ? _agree : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              // Not yet, rather than grey and dead.
              disabledBackgroundColor: const Color(0xFFE4E1FB),
              disabledForegroundColor: const Color(0xFF7D76E3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          loc.enterDashboard,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrow_right, size: 20),
                    ],
                  ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: _canAgree || _saving
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    loc.agreeToContinueHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton.icon(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: Icon(LucideIcons.log_out,
                size: 16, color: Colors.grey.shade600),
            label: Text(
              loc.logout,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dashed rounded outline, for the signature box.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
