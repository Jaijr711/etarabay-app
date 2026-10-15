import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'custom_back_button.dart';
import 'question_cloud.dart' show DoodleBackground;
import 'sparkle_decor.dart';

/// The look of the reading screens — poems, stories and songs — from the
/// team's design: notebook doodles behind everything, a grey back button and
/// the title in big round letters, the star count in a gold pill; the
/// reading in a thick coral frame with the dino waving at its corner; then a
/// chunky progress bar and three glossy round buttons.
///
/// Only the look lives here. Each screen keeps its own playback, and hands
/// in what to show and what the buttons do.
class StorybookScaffold extends StatelessWidget {
  final String title;

  /// Back to the list. Called inside the tap, which matters on the web: the
  /// module music is handed back there, and a browser only lets a page start
  /// sound from a tap.
  final VoidCallback onClose;

  /// A line under the header (the poem's "read it all first").
  final Widget? banner;

  /// The reading itself; it fills the middle of the screen.
  final Widget body;

  /// Whether the waving dino stands at the reading's bottom-right corner.
  final bool dino;

  final double progress;

  /// The far end of the progress bar's fill (it starts teal).
  final Color fill;

  /// The big middle button.
  final Color playColor;

  final bool isPlaying;
  final VoidCallback onPlayPause;

  /// One line back. Null leaves its place empty rather than drawing a button
  /// that does nothing.
  final VoidCallback? onBack;
  final VoidCallback? onRestart;

  /// Drawn over everything (the confetti).
  final Widget? overlay;

  const StorybookScaffold({
    super.key,
    required this.title,
    required this.onClose,
    required this.body,
    required this.progress,
    required this.fill,
    required this.playColor,
    required this.isPlaying,
    required this.onPlayPause,
    this.banner,
    this.dino = true,
    this.onBack,
    this.onRestart,
    this.overlay,
  });

  static const navy = Color(0xFF27305E);
  static const dinoAsset = 'assets/images/replay_dino.webp';

  static TextStyle fredoka(double size, Color color, {double weight = 700}) =>
      TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        fontVariations: [FontVariation('wght', weight)],
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.15,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFF),
      appBar: _header(context),
      body: Stack(children: [
        const Positioned.fill(child: DoodleBackground()),
        SafeArea(
          child: Column(children: [
            if (banner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: banner,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: body),
                  if (dino)
                    const Positioned(
                      right: -16,
                      bottom: -22,
                      width: 86,
                      child: IgnorePointer(
                        child: Image(
                          image: AssetImage(dinoAsset),
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 6),
              child: StorybookProgress(progress: progress, fill: fill),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _controls(),
            ),
          ]),
        ),
        if (overlay != null) overlay!,
      ]),
    );
  }

  /// The app's own header, the same as the Magbasa list it was opened
  /// from: a white bar, the back button, the title and the star total.
  PreferredSizeWidget _header(BuildContext context) {
    final stars = Provider.of<UserProvider>(context).displayStars;
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: CustomBackButton(
        iconColor: AppColors.textDark,
        onPressed: onClose,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 17),
            const SizedBox(width: 4),
            Text('$stars',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5A300),
                    fontSize: 14)),
          ]),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _controls() {
    return SizedBox(
      height: 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          onBack == null
              ? const SizedBox(width: 74)
              : GlossyRoundButton(
                  size: 74,
                  top: const Color(0xFFFFB5DD),
                  bottom: const Color(0xFFF06AB5),
                  edge: const Color(0xFFC8478F),
                  icon: Icons.skip_previous_rounded,
                  iconColor: const Color(0xFFFFE6F3),
                  onTap: onBack!,
                  leaves: LeafSide.left,
                ),
          GlossyRoundButton(
            size: 100,
            top: Color.lerp(playColor, Colors.white, 0.28)!,
            bottom: playColor,
            edge: Color.lerp(playColor, Colors.black, 0.3)!,
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            iconColor: Colors.white,
            onTap: onPlayPause,
            leaves: LeafSide.right,
          ),
          onRestart == null
              ? const SizedBox(width: 74)
              : GlossyRoundButton(
                  size: 74,
                  top: const Color(0xFFFFB38A),
                  bottom: const Color(0xFFF2643A),
                  edge: const Color(0xFFC2471F),
                  icon: Icons.replay_rounded,
                  iconColor: const Color(0xFFFFEBE0),
                  onTap: onRestart!,
                  leaves: LeafSide.right,
                ),
        ],
      ),
    );
  }
}

/// The thick coral frame the reading sits in, with its inner light rim, a
/// shine along the top and flowers, stars and sparkles round the edge.
class CoralCard extends StatelessWidget {
  final Widget child;

  /// What fills the inside: white, or the song's sky.
  final Decoration? inside;

  final EdgeInsets padding;

  /// Whether the inside fills a frame sized from outside (the reading
  /// screens), or the frame grows to fit what is inside (a card on a
  /// scrolling page, like the profile).
  final bool fillFrame;

  const CoralCard({
    super.key,
    required this.child,
    this.inside,
    this.padding = EdgeInsets.zero,
    this.fillFrame = true,
  });

  static const _decor = DecorPainter([
    DecorMark.sparkle(0.05, 0.02, 8, Colors.white),
    DecorMark.star(0.17, 0.015, 9, Color(0xFFFFC23A)),
    DecorMark.sparkle(0.95, 0.025, 7, Colors.white),
    DecorMark.flower(0.0, 0.17, 12),
    DecorMark.yellowFlower(1.0, 0.18, 11),
    DecorMark.sparkle(0.985, 0.13, 5, Colors.white),
    DecorMark.flower(0.03, 0.97, 11),
    DecorMark.star(0.13, 0.985, 8, Color(0xFFFFC23A)),
    DecorMark.sparkle(0.015, 0.84, 5, Colors.white),
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF6B70), Color(0xFFF46A80), Color(0xFF9A8FE0)],
              stops: [0, 0.6, 1],
            ),
            border: Border.all(color: const Color(0xFFC94056), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC94056).withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
      // The shine across the top right of the frame.
      Positioned(
        top: 5,
        right: 30,
        width: 60,
        height: 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      // The inside fills the frame whatever the reading's length, so a
      // short poem never leaves the frame's colour showing under it.
      if (fillFrame) Positioned.fill(child: _inside()) else _inside(),
      const Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _decor)),
      ),
    ]);
  }

  Widget _inside() => Padding(
        padding: const EdgeInsets.all(13),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDF1FA), width: 4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: inside ?? const BoxDecoration(color: Colors.white),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      );
}

/// The cream paper box the words sit on, with little stars at its corners.
class ParchmentBox extends StatelessWidget {
  final Widget child;
  const ParchmentBox({super.key, required this.child});

  static const _decor = DecorPainter([
    DecorMark.star(0.02, 0.03, 10, Color(0xFFFFB13B)),
    DecorMark.star(0.98, 0.04, 9, Color(0xFFFFB13B)),
    DecorMark.star(0.015, 0.97, 9, Color(0xFFFFB13B)),
    DecorMark.sparkle(0.96, 0.93, 6, Color(0xFFB59BF0)),
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF3DE),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD7B47A), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A6A3A).withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
      Padding(padding: const EdgeInsets.all(4), child: child),
      const Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _decor)),
      ),
    ]);
  }
}

/// The cloud-shaped strip with a red "i" (the poem's "read it all first").
class StorybookHint extends StatelessWidget {
  final String text;
  const StorybookHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFB9D3EE), width: 2.5),
        boxShadow: [
          const BoxShadow(color: Color(0xFFCFE0F2), offset: Offset(0, 4)),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE5484D),
          ),
          child: const Icon(LucideIcons.info, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(text,
                maxLines: 1,
                style: StorybookScaffold.fredoka(17, const Color(0xFF7A1F1F),
                    weight: 600)),
          ),
        ),
      ]),
    );
  }
}

/// The chunky progress bar: a dark outline, teal running into [fill], and
/// a star riding the end of it.
class StorybookProgress extends StatelessWidget {
  final double progress;
  final Color fill;
  const StorybookProgress(
      {super.key, required this.progress, required this.fill});

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 26,
      child: LayoutBuilder(builder: (_, box) {
        const pad = 3.0;
        final inner = box.maxWidth - pad * 2;
        final fillW = (inner * p).clamp(20.0, inner);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE4E8F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3566), width: 3),
              ),
            ),
          ),
          Positioned(
            left: pad,
            top: pad,
            bottom: pad,
            width: fillW,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(colors: [
                  const Color(0xFF3CC6C0),
                  fill,
                ], stops: const [
                  0.35,
                  1
                ]),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 3, 8, 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          // The star at the end of what has been heard.
          Positioned(
            left: pad + fillW - 15,
            top: -2,
            width: 30,
            height: 30,
            child: const Image(
              image: AssetImage('assets/images/replay_star.webp'),
              filterQuality: FilterQuality.medium,
            ),
          ),
        ]);
      }),
    );
  }
}

enum LeafSide { left, right }

/// A round, glossy 3D button: a gradient face in a white rim, a solid edge
/// under it and a shine across the top, with a sprig of leaves and a flower
/// at its foot. Sinks a little when pressed.
class GlossyRoundButton extends StatefulWidget {
  final double size;
  final Color top, bottom, edge, iconColor;
  final IconData icon;
  final VoidCallback onTap;
  final LeafSide leaves;

  const GlossyRoundButton({
    super.key,
    required this.size,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.leaves = LeafSide.right,
  });

  @override
  State<GlossyRoundButton> createState() => _GlossyRoundButtonState();
}

class _GlossyRoundButtonState extends State<GlossyRoundButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: SizedBox(
        width: s,
        height: s + 6,
        child: Stack(clipBehavior: Clip.none, children: [
          // The sprig, tucked behind the button's foot.
          Positioned(
            left: widget.leaves == LeafSide.left ? -s * 0.22 : null,
            right: widget.leaves == LeafSide.right ? -s * 0.22 : null,
            bottom: -s * 0.06,
            width: s * 0.55,
            height: s * 0.45,
            child: CustomPaint(
                painter: _SprigPainter(widget.leaves == LeafSide.left)),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            top: _down ? 4 : 0,
            left: 0,
            width: s,
            height: s,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: widget.edge, offset: Offset(0, _down ? 2 : 6)),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              padding: EdgeInsets.all(s * 0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.top, widget.bottom],
                  ),
                  border: Border.all(
                      color: widget.edge.withOpacity(0.5), width: 1.5),
                ),
                child: Stack(children: [
                  // The shine.
                  Positioned(
                    left: s * 0.2,
                    right: s * 0.2,
                    top: s * 0.07,
                    height: s * 0.2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s),
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(widget.icon,
                        color: widget.iconColor,
                        size: s * 0.56,
                        shadows: [
                          Shadow(
                            color: widget.edge.withOpacity(0.6),
                            offset: const Offset(0, 2),
                          ),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SprigPainter extends CustomPainter {
  final bool left;
  _SprigPainter(this.left);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (left) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    SparkleDecor.leaf(canvas, Offset(w * 0.2, h * 0.85), w * 0.62, -0.5);
    SparkleDecor.leaf(canvas, Offset(w * 0.25, h * 0.9), w * 0.55, 0.25);
    SparkleDecor.flower(canvas, Offset(w * 0.3, h * 0.78), h * 0.22,
        petals: const Color(0xFFFFC93C), edge: const Color(0xFFC98A10));
  }

  @override
  bool shouldRepaint(_SprigPainter oldDelegate) => oldDelegate.left != left;
}

/// The song card's sky: blue running pale towards the foot, with clouds
/// along the sides and a scatter of stars and sparkles.
class SkyPainter extends CustomPainter {
  const SkyPainter();

  static const _marks = DecorPainter([
    DecorMark.sparkle(0.18, 0.12, 9, Color(0xFFFFD45A)),
    DecorMark.star(0.83, 0.10, 11, Color(0xFFFF7FB8)),
    DecorMark.sparkle(0.88, 0.25, 6, Color(0xFFE08BEF)),
    DecorMark.star(0.12, 0.27, 9, Color(0xFF6ED3A8)),
    DecorMark.star(0.82, 0.30, 8, Color(0xFFFFB13B)),
    DecorMark.sparkle(0.08, 0.38, 6, Color(0xFF5CC98A)),
    DecorMark.star(0.14, 0.45, 8, Color(0xFFB57BF0)),
    DecorMark.sparkle(0.84, 0.44, 8, Color(0xFFFFD45A)),
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF79C3F5), Color(0xFFB9E1FA), Color(0xFFE9F6FD)],
          stops: [0, 0.45, 1],
        ).createShader(Offset.zero & size),
    );
    final cloud = Paint()..color = Colors.white.withOpacity(0.9);
    void puff(double x, double y, double r) =>
        canvas.drawCircle(Offset(x * w, y * h), r * w, cloud);
    // Left, half off the edge.
    puff(0.02, 0.20, 0.10);
    puff(0.13, 0.22, 0.08);
    puff(0.08, 0.16, 0.07);
    // Right.
    puff(0.98, 0.33, 0.11);
    puff(0.87, 0.36, 0.08);
    puff(0.93, 0.28, 0.07);
    // A bank along the foot of the sky, behind the words.
    for (final x in [0.0, 0.18, 0.36, 0.55, 0.74, 0.92]) {
      puff(x, 0.52, 0.11);
    }
    _marks.paint(canvas, size);
  }

  @override
  bool shouldRepaint(SkyPainter oldDelegate) => false;
}
