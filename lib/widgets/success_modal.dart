import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'fun_dialog.dart';
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

  // The celebration as the team drew it: a tall oval card with a rainbow
  // rim, a big party popper bursting over its top and two small ones beside
  // it, confetti all around, the title in red-to-orange with a white rim,
  // three smiling stars among sparkles, the breakdown in a rainbow pill, the
  // score in a glossy bubble between a trophy and the cheering mascot, and a
  // Finished button sitting on the card's bottom edge with Repeat under it.
  //
  // It is laid out once at the design's own width and scaled down as a whole
  // to fit a smaller screen, so it looks the same on every phone instead of
  // being rearranged by each one. The pictures are cut from the design.
  static const _popper = 'assets/images/celebrate_popper.webp';
  static const _trophy = 'assets/images/trophy_happy.webp';
  static const _mascot = 'assets/images/mascot_dino.webp';
  static const _stars = [
    'assets/images/star_happy_1.webp',
    'assets/images/star_happy_2.webp',
    'assets/images/star_happy_3.webp',
  ];

  /// The width everything below is measured against.
  static const double _designWidth = 360;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: _designWidth, child: _composition()),
            ),
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

  Widget _composition() {
    const cardWidth = 336.0;
    // How far the Finished button hangs below the card's bottom edge.
    const buttonOverhang = 30.0;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Room above the card for the poppers.
      const SizedBox(height: 92),
      Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        // Confetti scattered around the card, drawn behind it.
        ..._staticConfetti(cardWidth),

        Padding(
          padding: const EdgeInsets.only(bottom: buttonOverhang),
          child: _card(cardWidth),
        ),

        // Poppers: a big one bursting over the top, two small ones beside.
        Positioned(
          top: -112,
          child: Image.asset(_popper, width: 150, height: 150)
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack),
        ),
        Positioned(
          top: -78,
          left: -6,
          child: Transform.flip(
            flipX: true,
            child: Transform.rotate(
              angle: -0.35,
              child: Image.asset(_popper, width: 72, height: 72),
            ),
          ),
        ),
        Positioned(
          top: -78,
          right: -6,
          child: Transform.rotate(
            angle: 0.35,
            child: Image.asset(_popper, width: 72, height: 72),
          ),
        ),

        // The mascot, cheering at the card's right edge.
        Positioned(
          right: -26,
          bottom: buttonOverhang + 64,
          child: Image.asset(_mascot, height: 112)
              .animate()
              .fadeIn(delay: 800.ms)
              .slideX(begin: 0.3),
        ),

        // Finished, sitting on the bottom edge.
        Positioned(
          left: 34,
          right: 34,
          bottom: 0,
          child: _ChunkyButton(
            label: _withoutTrophy(widget.primaryLabel),
            onTap: widget.onPrimaryTap,
            top: const Color(0xFFFF7A98),
            bottom: const Color(0xFFE8405F),
            edge: const Color(0xFFB42A48),
            height: 64,
            fontSize: 28,
            trailing: Image.asset(_trophy, width: 48, height: 48),
          ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),
        ),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: 190,
        child: _ChunkyButton(
          label: widget.secondaryLabel,
          onTap: widget.onSecondaryTap,
          top: const Color(0xFF45DCCB),
          bottom: const Color(0xFF18A8B6),
          edge: const Color(0xFF0F7A85),
          height: 52,
          fontSize: 22,
          icon: Icons.refresh_rounded,
        ).animate().fadeIn(delay: 1300.ms),
      ),
    ]);
  }

  /// The tall oval card: a thick rainbow rim around a white face.
  Widget _card(double width) {
    const rim = 7.0;
    final outer = BorderRadius.all(Radius.elliptical(width / 2, width * 0.42));
    final inner = BorderRadius.all(
        Radius.elliptical(width / 2 - rim, width * 0.42 - rim));
    return Container(
      width: width,
      padding: const EdgeInsets.all(rim),
      decoration: BoxDecoration(
        borderRadius: outer,
        // Blue down the left, orange-red down the right, as drawn.
        gradient: const SweepGradient(
          startAngle: 0,
          endAngle: 6.2832,
          colors: [
            Color(0xFFFF8A3D), // right
            Color(0xFFFF5A5F), // bottom right
            Color(0xFF6C5CE7), // bottom left
            Color(0xFF3D8BF2), // left
            Color(0xFF7CC6F7), // top left
            Color(0xFFFFB25B), // top right
            Color(0xFFFF8A3D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 56),
        decoration: BoxDecoration(
          borderRadius: inner,
          // A soft glow in from the rim.
          gradient: const RadialGradient(
            radius: 0.9,
            colors: [Colors.white, Colors.white, Color(0xFFEFF6FF)],
            stops: [0, 0.75, 1],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _RimmedTitle(widget.title)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF4F5BB5),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 14),
          _starsRow(),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showStarBreakdownDialog(context),
            child: _breakdownPill(),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 18),
          _scoreRow()
              .animate()
              .fadeIn(delay: 800.ms)
              .scale(duration: 400.ms, curve: Curves.easeOutBack),
          if (widget.streak != null) ...[
            const SizedBox(height: 8),
            _streakPill(widget.streak!).animate().fadeIn(delay: 900.ms),
          ],
          if (widget.badges != null && widget.badges!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: widget.badges!.map((b) => _buildBadge(b)).toList(),
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ]),
      ),
    );
  }

  /// Three smiling stars among small sparkles; the ones not earned are grey.
  Widget _starsRow() {
    const size = 88.0;
    Widget star(int index) {
      Widget picture = Image.asset(_stars[index], width: size, height: size);
      if (index >= widget.stars) {
        picture = Opacity(
          opacity: 0.35,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.33, 0.33, 0.33, 0, 0, //
              0.33, 0.33, 0.33, 0, 0, //
              0.33, 0.33, 0.33, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: picture,
          ),
        );
      }
      return GestureDetector(
        onTap: () => _showStarBreakdownDialog(context),
        child: picture
            .animate(delay: (400 + (index * 150)).ms)
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
      );
    }

    return SizedBox(
      width: size * 3 + 24,
      height: size + 22,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, top: 16, child: star(0)),
        Positioned(left: size + 12, top: 4, child: star(1)),
        Positioned(left: (size + 12) * 2, top: 16, child: star(2)),
        // Sparkles, as scattered round the stars in the design.
        for (final s in const [
          (-14.0, 22.0, 12.0, Color(0xFFF2617A)),
          (38.0, 4.0, 9.0, Color(0xFFFFB800)),
          (-4.0, 78.0, 8.0, Color(0xFF34C3C8)),
          (126.0, -6.0, 9.0, Color(0xFFF2617A)),
          (178.0, 2.0, 12.0, Color(0xFFFFB800)),
          (112.0, 96.0, 10.0, Color(0xFFFFB800)),
          (232.0, 10.0, 12.0, Color(0xFF34C3C8)),
          (290.0, 28.0, 9.0, Color(0xFFFFB800)),
          (288.0, 82.0, 10.0, Color(0xFFF2617A)),
        ])
          Positioned(
            left: s.$1,
            top: s.$2,
            child: CustomPaint(
              size: Size.square(s.$3 * 2),
              painter: _SparklePainter(s.$4),
            ),
          ),
      ]),
    );
  }

  /// "3/3 Stars • Perfect Score! / Outstanding!" in a pill with a rainbow rim.
  Widget _breakdownPill() {
    final summary = _getStarDetailSummary(widget.stars);
    final dot = summary.indexOf('•');
    final head = dot < 0 ? summary : summary.substring(0, dot).trim();
    final rest = dot < 0 ? '' : summary.substring(dot + 1).trim();
    // The rest splits after its first sentence: teal, then plum below.
    final cut = RegExp(r'[!.]\s').firstMatch(rest);
    final first = cut == null ? rest : rest.substring(0, cut.start + 1);
    final second = cut == null ? '' : rest.substring(cut.end).trim();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFB79CF0),
          Color(0xFF8ED3F2),
          Color(0xFFF7A6C2),
          Color(0xFFFFC98A),
        ]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(29),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(_trophy, width: 44, height: 44),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: head,
                    style: const TextStyle(color: Color(0xFFE36414))),
                if (first.isNotEmpty)
                  TextSpan(
                      text: ' • $first',
                      style: const TextStyle(color: Color(0xFF0F7C8C))),
                if (second.isNotEmpty)
                  TextSpan(
                      text: '\n$second',
                      style: const TextStyle(color: Color(0xFF8E2A6B))),
              ]),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w900, height: 1.25),
            ),
          ),
        ]),
      ),
    );
  }

  /// A big trophy, the score in a glossy bubble with "Score" under it, and
  /// the streak beside it when there is one. The mascot stands to the right,
  /// on the card's edge.
  Widget _scoreRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(_trophy, width: 92, height: 92),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: _scoreBubble(AppLocalizations.of(context)!.scoreLabel,
              widget.score.toString(), 96),
        ),
        // Room for the mascot, who stands over the card's right edge.
        const SizedBox(width: 44),
      ],
    );
  }

  /// The streak, as a small flame pill under the score — the design has no
  /// place for it in the score's row, where the mascot stands.
  Widget _streakPill(int streak) {
    return Container(
      // The oval card is narrow down here; a long word shrinks to fit the
      // pill rather than running out of the card and being cut.
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB27A), width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_fire_department_rounded,
            color: Colors.deepOrange, size: 22),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${AppLocalizations.of(context)!.streakWord}: $streak',
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD9480F))),
          ),
        ),
      ]),
    );
  }

  /// A number in a glossy bubble, with its label under it.
  Widget _scoreBubble(String label, String value, double size) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 0.9,
            colors: [Color(0xFFFFF4FB), Color(0xFFF7C6E4), Color(0xFF8CC8F7)],
            stops: [0, 0.45, 1],
          ),
          border: Border.all(color: const Color(0xFF5C8FD6), width: 3),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _RimmedNumber(value, fontSize: size * 0.46),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              fontSize: size > 70 ? 24 : 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF9B2D7F))),
    ]);
  }

  /// [label] without a trophy emoji: the button draws its own trophy.
  static String _withoutTrophy(String label) =>
      label.replaceAll('🏆', '').trim();

  /// Coloured paper bits scattered around the card, behind it.
  List<Widget> _staticConfetti(double cardWidth) {
    const bits = [
      (-30.0, -40.0, 0.6, Color(0xFFFF5A5F)),
      (4.0, 40.0, -0.4, Color(0xFF3D8BF2)),
      (-22.0, 160.0, 0.9, Color(0xFF4CD07D)),
      (-28.0, 320.0, -0.7, Color(0xFFFF5A5F)),
      (-18.0, 480.0, 0.3, Color(0xFF4CD07D)),
      (-26.0, 610.0, -0.5, Color(0xFF3D8BF2)),
      (346.0, -36.0, -0.6, Color(0xFF4CD07D)),
      (350.0, 70.0, 0.5, Color(0xFFFF5A5F)),
      (348.0, 230.0, -0.8, Color(0xFF3D8BF2)),
      (352.0, 400.0, 0.4, Color(0xFF4CD07D)),
      (346.0, 600.0, -0.3, Color(0xFFFF5A5F)),
      (120.0, -70.0, 0.8, Color(0xFF3D8BF2)),
      (230.0, -86.0, -0.5, Color(0xFFFFB800)),
    ];
    return [
      for (final b in bits)
        Positioned(
          left: b.$1,
          top: b.$2,
          child: Transform.rotate(
            angle: b.$3,
            child: Container(
              width: 16,
              height: 7,
              decoration: BoxDecoration(
                color: b.$4,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
    ];
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

  /// What the stars mean, in words a child can take in: the count, and
  /// praise for a perfect round. Instructions like "Replay with 0 errors!"
  /// were dropped — a three-year-old cannot act on them, and the parent can
  /// tap the stars for the full rules.
  String _getStarDetailSummary(int stars) {
    final loc = AppLocalizations.of(context)!;
    switch (stars) {
      case 3:
        return loc.starSummary3;
      case 2:
        return loc.starSummary2;
      case 1:
        return loc.starSummary1;
      default:
        return loc.starSummary0;
    }
  }

  void _showStarBreakdownDialog(BuildContext context) {
    final earned = widget.stars;
    showDialog(
      context: context,
      builder: (ctx) => FunDialog(
        child: FunMessage(
          title: AppLocalizations.of(ctx)!.starRequirements,
          body: Column(
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
          buttons: [
            FunPillButton(
              label: AppLocalizations.of(ctx)!.gotIt,
              colors: FunColors.purple,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
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
                  // Wraps rather than running off the card ("Star 3: You got
                  // them all right on your first try").
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!
                          .starNumberTitle('$starNumber', title),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isEarned
                            ? AppColors.textDark
                            : Colors.grey.shade600,
                      ),
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
                      isEarned
                          ? AppLocalizations.of(context)!.starEarned
                          : AppLocalizations.of(context)!.starEmpty,
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

/// The title as drawn: red at the top turning orange, a thick white rim, and
/// a dark red outline round that.
class _RimmedTitle extends StatelessWidget {
  final String text;
  const _RimmedTitle(this.text);

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.02);
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

/// The score: magenta to purple, with a white rim.
class _RimmedNumber extends StatelessWidget {
  final String text;
  final double fontSize;
  const _RimmedNumber(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900);
    return Stack(alignment: Alignment.center, children: [
      Text(text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
          )),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD6338A), Color(0xFF7B3FC4)],
        ).createShader(r),
        child: Text(text, style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

/// A four-pointed sparkle.
class _SparklePainter extends CustomPainter {
  final Color color;
  const _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final w = r * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w * 0.4, c.dy - w * 0.4, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w * 0.4, c.dy + w * 0.4, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w * 0.4, c.dy + w * 0.4, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w * 0.4, c.dy - w * 0.4, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.color != color;
}

/// A rounded button with a solid 3D edge under it.
class _ChunkyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color top, bottom, edge;
  final double height;
  final double fontSize;
  final IconData? icon;
  final Widget? trailing;

  const _ChunkyButton({
    required this.label,
    required this.onTap,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.height,
    required this.fontSize,
    this.icon,
    this.trailing,
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
          boxShadow: [
            BoxShadow(color: edge, offset: const Offset(0, 6)),
            BoxShadow(
                color: edge.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 9)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Stack(clipBehavior: Clip.none, children: [
          // A highlight along the top, so it looks glossy.
          Positioned(
            left: height * 0.2,
            right: height * 0.2,
            top: height * 0.1,
            height: height * 0.22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.28),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
          Center(
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
                          color: edge.withOpacity(0.9),
                          offset: const Offset(0, 2)),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
