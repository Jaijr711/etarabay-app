import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../services/device_performance.dart';

/// The moment a child earns the Certificate of Completion: the celebration
/// card, with their certificate on it.
///
/// The certificate used to be added in silence — the child finished every
/// module and claimed every badge, and nothing on screen said so. This is
/// design A of the five drawn for choosing (test/previews/
/// certificate_popup_preview.dart), laid out at the same 360 width and
/// scaled down whole on a smaller screen, as the level card is.
///
/// Returns true when the child chose to see the certificate.
Future<bool> showCertificateEarnedPopup(
  BuildContext context, {
  required String name,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'certificate',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => CertificateEarnedPopup(name: name),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
  return result ?? false;
}

class CertificateEarnedPopup extends StatefulWidget {
  /// The child's name as the certificate prints it. Only the first word is
  /// used in the greeting, which has room for one name.
  final String name;

  /// The falling confetti. Off only in the design preview, where its random
  /// burst made every picture of the card a little different.
  final bool confetti;
  const CertificateEarnedPopup(
      {super.key, required this.name, this.confetti = true});

  @override
  State<CertificateEarnedPopup> createState() => _CertificateEarnedPopupState();
}

class _CertificateEarnedPopupState extends State<CertificateEarnedPopup> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));

  static const _popper = 'assets/images/celebrate_popper.webp';
  static const _mascot = 'assets/images/mascot_dino.webp';

  @override
  void initState() {
    super.initState();
    if (widget.confetti && !DevicePerformance.animationsOff) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final first = widget.name.trim().split(RegExp(r'\s+')).first;
    const cardWidth = 336.0;
    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (_, c) =>
                Stack(children: _staticConfetti(c.maxWidth, c.maxHeight, 3)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 360,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 96),
                  Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        _rainbowCard(
                          cardWidth,
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            _RimmedTitle(loc.certEarnedTitle(first),
                                    fontSize: 38)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2),
                            const SizedBox(height: 10),
                            Text(
                              loc.certEarnedBody,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.15,
                                  color: Color(0xFF4F5BB5),
                                  fontWeight: FontWeight.w900),
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 18),
                            Transform.rotate(
                              angle: -0.05,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.22),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: MiniCertificate(
                                      name: widget.name, width: 250),
                                ),
                              ),
                            ).animate().fadeIn(delay: 400.ms).scale(
                                begin: const Offset(0.8, 0.8),
                                duration: 450.ms,
                                curve: Curves.easeOutBack),
                            const SizedBox(height: 26),
                            _ChunkyButton(
                              label: loc.certEarnedView,
                              onTap: () => Navigator.of(context).pop(true),
                              top: const Color(0xFF5BE08A),
                              bottom: const Color(0xFF22B45A),
                              edge: const Color(0xFF168344),
                              height: 58,
                              fontSize: 22,
                            )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideY(begin: 0.3),
                            const SizedBox(height: 10),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).pop(false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 4),
                                child: Text(loc.notNow,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF7A84A6))),
                              ),
                            ),
                          ]),
                        ),
                        Positioned(
                          top: -112,
                          child: Image.asset(_popper, width: 150, height: 150)
                              .animate()
                              .scale(
                                  duration: 500.ms, curve: Curves.easeOutBack),
                        ),
                        Positioned(
                          top: -78,
                          left: -6,
                          child: Transform.flip(
                            flipX: true,
                            child: Transform.rotate(
                                angle: -0.35,
                                child: Image.asset(_popper,
                                    width: 72, height: 72)),
                          ),
                        ),
                        Positioned(
                          top: -78,
                          right: -6,
                          child: Transform.rotate(
                              angle: 0.35,
                              child:
                                  Image.asset(_popper, width: 72, height: 72)),
                        ),
                        Positioned(
                          right: -30,
                          top: 300,
                          child: Image.asset(_mascot, height: 104)
                              .animate()
                              .fadeIn(delay: 800.ms)
                              .slideX(begin: 0.3),
                        ),
                      ]),
                ]),
              ),
            ),
          ),
        ),
        if (widget.confetti)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
      ]),
    );
  }

  Widget _rainbowCard(double width, Widget child) {
    const rim = 7.0;
    return Container(
      width: width,
      padding: const EdgeInsets.all(rim),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        gradient: const SweepGradient(colors: [
          Color(0xFFFF8A3D),
          Color(0xFFFF5A5F),
          Color(0xFF6C5CE7),
          Color(0xFF3D8BF2),
          Color(0xFF7CC6F7),
          Color(0xFFFFB25B),
          Color(0xFFFF8A3D),
        ]),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44 - rim),
          gradient: const RadialGradient(
            radius: 0.9,
            colors: [Colors.white, Colors.white, Color(0xFFEFF6FF)],
            stops: [0, 0.75, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Bits of confetti in fixed places around the edges, never over the words.
List<Widget> _staticConfetti(double width, double height, int seed) {
  final r = math.Random(seed);
  const colors = [
    Color(0xFFFF5A5F),
    Color(0xFFFFB25B),
    Color(0xFF3D8BF2),
    Color(0xFF6C5CE7),
    Color(0xFF2ECC71),
    Color(0xFFFFD23F),
  ];
  final spots = <Offset>[];
  while (spots.length < 34) {
    final p = Offset(r.nextDouble() * width, r.nextDouble() * height);
    final edge = p.dx < 34 || p.dx > width - 34;
    if (edge || p.dy < 130 || p.dy > height - 110) spots.add(p);
  }
  return [
    for (int i = 0; i < spots.length; i++)
      Positioned(
        left: spots[i].dx,
        top: spots[i].dy,
        child: Transform.rotate(
          angle: r.nextDouble() * math.pi,
          child: Container(
            width: 7 + r.nextDouble() * 6,
            height: 12 + r.nextDouble() * 8,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
  ];
}

/// The real certificate with the child's name on its line, at any width.
class MiniCertificate extends StatelessWidget {
  final String name;
  final double width;
  const MiniCertificate({super.key, required this.name, required this.width});

  @override
  Widget build(BuildContext context) {
    // The background's own size and the name's line, as the certificate
    // screen measures them (certificates_screen.dart).
    const w = 1492.0, h = 1054.0;
    return SizedBox(
      width: width,
      height: width * h / w,
      child: FittedBox(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(children: [
            Positioned.fill(
              child: Image.asset('assets/images/E-TarabayCertificate.webp',
                  fit: BoxFit.fill),
            ),
            Positioned(
              left: w * 0.19,
              width: w * 0.62,
              top: h * 0.36 - 45,
              height: 90,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19416B))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The level card's title: red-to-orange letters with a white rim.
class _RimmedTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  const _RimmedTitle(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.02);
    Text stroke(double width, Color color) => Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeJoin = StrokeJoin.round
              ..color = color,
          ),
        );
    return Stack(alignment: Alignment.center, children: [
      stroke(13, const Color(0xFFB0303A)),
      stroke(8, Colors.white),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2385A), Color(0xFFFF7A1A), Color(0xFFFFA21F)],
        ).createShader(r),
        child: Text(text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

/// The level card's glossy, chunky button.
class _ChunkyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color top, bottom, edge;
  final double height;
  final double fontSize;

  const _ChunkyButton({
    required this.label,
    required this.onTap,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: edge, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
