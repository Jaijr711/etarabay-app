import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SuccessModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final int score;
  final int stars;
  final int? streak;
  final List<String>? badges;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final VoidCallback onSecondaryTap;
  final Color mainColor;

  const SuccessModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.stars,
    this.streak,
    this.badges,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
    this.mainColor = AppColors.primary,
  });

  @override
  State<SuccessModal> createState() => _SuccessModalState();
}

class _SuccessModalState extends State<SuccessModal> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // The celebration as the team drew it: a rainbow-rimmed card, a party
  // popper over it, the title in bold orange-red with a white rim, three
  // smiling stars, the score in a bubble with a trophy and the mascot, and
  // two chunky buttons. The pictures are cut from that design.
  static const _popper = 'assets/images/celebrate_popper.webp';
  static const _trophy = 'assets/images/trophy_happy.webp';
  static const _mascot = 'assets/images/mascot_dino.webp';
  static const _stars = [
    'assets/images/star_happy_1.webp',
    'assets/images/star_happy_2.webp',
    'assets/images/star_happy_3.webp',
  ];

  static const _rainbow = [
    Color(0xFF4FA3F7),
    Color(0xFF7B6CF6),
    Color(0xFFF06BA8),
    Color(0xFFFF9F43),
    Color(0xFF4FA3F7),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      // Room above the card for the popper that hangs over its top edge.
      insetPadding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 78,
        bottom: 24,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The card: a rainbow rim around a white face.
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const SweepGradient(colors: _rainbow),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 62, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              // Scrollable so a long card — stars, the breakdown note,
              // score, streak, a badge list and two buttons — cannot
              // overflow on a short phone.
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RimmedTitle(widget.title)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4F5BB5),
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),

                    // Three smiling stars; the ones not earned are grey.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final earned = index < widget.stars;
                        Widget star = Image.asset(_stars[index],
                            width: 74, height: 74, fit: BoxFit.contain);
                        if (!earned) {
                          star = Opacity(
                            opacity: 0.35,
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.33, 0.33, 0.33, 0, 0, //
                                0.33, 0.33, 0.33, 0, 0, //
                                0.33, 0.33, 0.33, 0, 0, //
                                0, 0, 0, 1, 0,
                              ]),
                              child: star,
                            ),
                          );
                        }
                        return GestureDetector(
                          onTap: () => _showStarBreakdownDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: star
                                .animate(delay: (400 + (index * 150)).ms)
                                .scale(
                                    duration: 400.ms,
                                    curve: Curves.easeOutBack),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // The breakdown, in a pill with a rainbow rim.
                    GestureDetector(
                      onTap: () => _showStarBreakdownDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: _rainbow),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF2),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(_trophy, width: 34, height: 34),
                              const SizedBox(width: 8),
                              Flexible(
                                  child: _summaryText(
                                      _getStarDetailSummary(widget.stars))),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 16),

                    // The score: a trophy, the number in a bubble, the
                    // mascot cheering — and the streak beside it, if any.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(_trophy, width: 62, height: 62),
                        const SizedBox(width: 4),
                        _scoreBubble('Score', widget.score.toString(),
                            const Color(0xFF9B2D7F)),
                        if (widget.streak != null) ...[
                          const SizedBox(width: 8),
                          _scoreBubble(AppLocalizations.of(context)!.streakWord,
                              widget.streak.toString(), Colors.deepOrange),
                        ],
                        const SizedBox(width: 4),
                        Image.asset(_mascot, height: 70),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),

                    // Badges
                    if (widget.badges != null && widget.badges!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children:
                            widget.badges!.map((b) => _buildBadge(b)).toList(),
                      ).animate().fadeIn(delay: 1000.ms),
                    ],
                    const SizedBox(height: 22),

                    Column(
                      children: [
                        _ChunkyButton(
                          label: widget.primaryLabel,
                          onTap: widget.onPrimaryTap,
                          top: const Color(0xFFFF7A98),
                          bottom: const Color(0xFFE8405F),
                          edge: const Color(0xFFB42A48),
                          height: 58,
                          fontSize: 22,
                        ),
                        const SizedBox(height: 14),
                        _ChunkyButton(
                          label: widget.secondaryLabel,
                          onTap: widget.onSecondaryTap,
                          top: const Color(0xFF45DCCB),
                          bottom: const Color(0xFF18A8B6),
                          edge: const Color(0xFF0F7A85),
                          height: 48,
                          fontSize: 19,
                          icon: Icons.refresh_rounded,
                          widthFactor: 0.62,
                        ),
                      ],
                    ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),

          // The party popper over the top edge.
          Positioned(
            top: -58,
            child: Image.asset(_popper, width: 112, height: 112)
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
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
              createParticlePath: drawStar,
            ),
          ),
        ],
      ),
    );
  }

  /// The breakdown line: the star count in orange, the rest in teal.
  Widget _summaryText(String summary) {
    final dot = summary.indexOf('•');
    final head = dot < 0 ? summary : summary.substring(0, dot);
    final tail = dot < 0 ? '' : summary.substring(dot);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: head, style: const TextStyle(color: Color(0xFFE36414))),
        TextSpan(text: tail, style: const TextStyle(color: Color(0xFF0F7C8C))),
      ]),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );
  }

  /// A number in a glossy bubble, with its label under it.
  Widget _scoreBubble(String label, String value, Color ink) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 78,
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD6EC), Color(0xFFC9E8FF), Color(0xFF9FD3FF)],
          ),
          border: Border.all(color: const Color(0xFF7DB6F0), width: 2.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(value,
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: ink)),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(label,
          style:
              TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
    ]);
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.award, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB8860B),
            ),
          ),
        ],
      ),
    );
  }

  /// A custom path to paint a star.
  Path drawStar(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }

  String _getStarDetailSummary(int stars) {
    switch (stars) {
      case 3:
        return '3/3 Stars • Perfect Score! Outstanding!';
      case 2:
        return '2/3 Stars • 1 empty star remaining. Replay with 0 errors!';
      case 1:
        return '1/3 Star • 2 empty stars remaining. Practice to earn all 3!';
      default:
        return '0/3 Stars • Replay to fill your stars!';
    }
  }

  void _showStarBreakdownDialog(BuildContext context) {
    final earned = widget.stars;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 24),
            SizedBox(width: 8),
            Text(
              'Star Requirements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // What the app counts is wrong answers: none is three
            // stars, one is two, more than that is one. The old text
            // promised an accuracy percentage that exists nowhere in
            // the app, so it described a rule nobody could meet on
            // purpose.
            Text(
              AppLocalizations.of(ctx)!.howStarsEarned,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildStarCriterionItem(
              starNumber: 1,
              title: AppLocalizations.of(ctx)!.starOneTitle,
              description: AppLocalizations.of(ctx)!.starOneBody,
              isEarned: earned >= 1,
            ),
            const SizedBox(height: 12),
            _buildStarCriterionItem(
              starNumber: 2,
              title: AppLocalizations.of(ctx)!.starTwoTitle,
              description: AppLocalizations.of(ctx)!.starTwoBody,
              isEarned: earned >= 2,
            ),
            const SizedBox(height: 12),
            _buildStarCriterionItem(
              starNumber: 3,
              title: AppLocalizations.of(ctx)!.starThreeTitle,
              description: AppLocalizations.of(ctx)!.starThreeBody,
              isEarned: earned >= 3,
            ),
            if (earned < 3) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.lightbulb,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(ctx)!.starTip,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.gotIt,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStarCriterionItem({
    required int starNumber,
    required String title,
    required String description,
    required bool isEarned,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isEarned ? const Color(0xFFFFB800) : const Color(0xFFCBD5E1),
          size: 26,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Star $starNumber: $title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isEarned ? AppColors.textDark : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isEarned
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEarned ? 'Earned' : 'Empty',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isEarned
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The title in bold orange-red with a white rim, as in the design.
class _RimmedTitle extends StatelessWidget {
  final String text;
  const _RimmedTitle(this.text);

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.05);
    return Stack(alignment: Alignment.center, children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white,
          shadows: [
            Shadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
      ),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2385A), Color(0xFFFF8A1F)],
        ).createShader(r),
        child: Text(text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

/// A rounded button with a solid 3D edge under it.
class _ChunkyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color top, bottom, edge;
  final double height;
  final double fontSize;
  final IconData? icon;
  final double widthFactor;

  const _ChunkyButton({
    required this.label,
    required this.onTap,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.height,
    required this.fontSize,
    this.icon,
    this.widthFactor = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: edge, width: 2.5),
            boxShadow: [
              BoxShadow(color: edge, offset: const Offset(0, 5)),
              BoxShadow(
                  color: edge.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: fontSize + 4),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                        color: edge.withOpacity(0.8),
                        offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
