import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/app_localizations.dart';
import 'sparkle_decor.dart';

/// "Finished already!" — what tapping a finished level (or category) shows
/// before offering to play it again.
///
/// The team's design: a white card in a coral-to-blue frame, a gold star coin
/// at the top with the dino cheering beside it, the level's stars, its
/// points, and a teal Repeat and a purple OK under the card. Numbers, About
/// Me / My Family and Tandaan all ask this the same way, so it is drawn once,
/// here.
///
/// It shows what the level is worth now before offering a replay, because a
/// replay replaces that rating rather than adding to it.
Future<void> showReplayDialog(
  BuildContext context, {
  required int stars,
  int? points,
  required VoidCallback onRepeat,
}) =>
    _show(context, stars: stars, points: points, onRepeat: onRepeat);

/// The same card for a whole lesson finished (the lesson tiles): its name as
/// the title, "You finished this lesson! Great job!" under the coin, and the
/// same Repeat and OK. No stars — a lesson is many levels, each with its own.
Future<void> showLessonFinishedDialog(
  BuildContext context, {
  required String title,
  required VoidCallback onRepeat,
}) {
  final loc = AppLocalizations.of(context)!;
  return _show(context,
      title: title,
      headline: loc.lessonFinishedPrompt,
      note: '',
      onRepeat: onRepeat);
}

Future<void> _show(
  BuildContext context, {
  int? stars,
  int? points,
  String? title,
  String? headline,
  String? note,
  required VoidCallback onRepeat,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _ReplayDialog(
      stars: stars,
      points: points,
      title: title,
      headline: headline,
      note: note,
      onRepeat: () {
        Navigator.pop(dialogContext);
        onRepeat();
      },
      onOk: () => Navigator.pop(dialogContext),
    ),
  );
}

class _ReplayDialog extends StatelessWidget {
  /// The level's stars; null leaves the row out.
  final int? stars;
  final int? points;

  /// "Finished already!" unless given.
  final String? title;

  /// "Done already!" unless given.
  final String? headline;

  /// "Playing again replaces this star." unless given; empty leaves it out.
  final String? note;

  final VoidCallback onRepeat;
  final VoidCallback onOk;

  const _ReplayDialog({
    required this.stars,
    required this.points,
    required this.onRepeat,
    required this.onOk,
    this.title,
    this.headline,
    this.note,
  });

  static const coin = 'assets/images/replay_coin.webp';
  static const dino = 'assets/images/replay_dino.webp';
  static const star = 'assets/images/replay_star.webp';

  static const _navy = Color(0xFF2B2A5C);

  /// Laid out at this width and scaled to the phone, so it is the same
  /// picture on every screen.
  static const double _w = 340;

  static TextStyle _fredoka(double size, Color color, {double weight = 700}) =>
      TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        fontVariations: [FontVariation('wght', weight)],
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.05,
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: _w,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _card(loc),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GlossyButton(
                    onTap: onRepeat,
                    width: 190,
                    top: const Color(0xFF52EDEB),
                    bottom: const Color(0xFF11B4C4),
                    edge: const Color(0xFF0B8C9C),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.rotate_ccw,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(loc.ulitin,
                              maxLines: 1,
                              style: _fredoka(26, Colors.white).copyWith(
                                shadows: const [
                                  Shadow(
                                      color: Color(0xFF0B7F8D),
                                      offset: Offset(0, 2)),
                                ],
                              )),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 18),
                  _GlossyButton(
                    onTap: onOk,
                    width: 72,
                    top: const Color(0xFFEA9BF7),
                    bottom: const Color(0xFFB04BE0),
                    edge: const Color(0xFF8A2FB8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(loc.okButton,
                          maxLines: 1,
                          style: _fredoka(24, Colors.white).copyWith(
                            shadows: const [
                              Shadow(
                                  color: Color(0xFF7A2AA3),
                                  offset: Offset(0, 2)),
                            ],
                          )),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// The framed card: coin, title, stars, points and the two lines.
  Widget _card(AppLocalizations loc) {
    return Stack(clipBehavior: Clip.none, children: [
      // The frame: coral at the top running to blue at the foot.
      Container(
        width: _w,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B6E), Color(0xFFE77AA6), Color(0xFF79A3E6)],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFDDEFF7), width: 3),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(coin,
                width: 116, height: 116, filterQuality: FilterQuality.medium),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title ?? loc.finishedAlready,
                maxLines: 1,
                style:
                    _fredoka(31, _navy, weight: 650).copyWith(shadows: const [
                  Shadow(color: Color(0xFFD5CFF3), offset: Offset(0, 3)),
                ]),
              ),
            ),
            if (stars != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _star(i < stars!),
                    ),
                ],
              ),
            ],
            if (points != null) ...[
              const SizedBox(height: 8),
              _PointsText('$points ${loc.pointsLabel}'),
            ],
            const SizedBox(height: 12),
            Text(headline ?? loc.doneAlready,
                textAlign: TextAlign.center,
                style: _fredoka(22, _navy, weight: 600).copyWith(height: 1.2)),
            if ((note ?? loc.replayReplacesStar).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note ?? loc.replayReplacesStar,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A4A5E),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ]),
        ),
      ),
      // Sparkles, little stars and flowers round the edges.
      const Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _decor)),
      ),
      // The dino, cheering at the top right, leaning out over the frame.
      Positioned(
        top: -6,
        right: -18,
        width: 104,
        child: IgnorePointer(
          child: Image.asset(dino, filterQuality: FilterQuality.medium),
        ),
      ),
    ]);
  }

  /// A star earned is the glossy gold one; a star still to win is the same
  /// star, grey and faint.
  Widget _star(bool earned) {
    final img = Image.asset(star,
        width: 66, height: 64, filterQuality: FilterQuality.medium);
    if (earned) return img;
    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: img,
      ),
    );
  }
}

/// "50 Points" in chunky purple with a white rim, as in the design.
class _PointsText extends StatelessWidget {
  final String text;
  const _PointsText(this.text);

  @override
  Widget build(BuildContext context) {
    TextStyle base() => _ReplayDialog._fredoka(38, Colors.white);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(children: [
        // Shadow, then the white rim, then the purple face.
        Transform.translate(
          offset: const Offset(0, 3),
          child: Text(text,
              style: base().copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 8
                    ..strokeJoin = StrokeJoin.round
                    ..color = const Color(0xFF6A3FC4).withOpacity(0.45))),
        ),
        Text(text,
            style: base().copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 7
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.white)),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC07CF6), Color(0xFF7D5BEE)],
          ).createShader(r),
          child: Text(text, style: base()),
        ),
      ]),
    );
  }
}

/// A 3D glossy button: a gradient face in a white rim, a solid edge under it
/// and a shine across the top. Sinks a little when pressed.
class _GlossyButton extends StatefulWidget {
  final VoidCallback onTap;
  final double width;
  final Color top, bottom, edge;
  final Widget child;

  const _GlossyButton({
    required this.onTap,
    required this.width,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.child,
  });

  @override
  State<_GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<_GlossyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const h = 66.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 80),
        offset: Offset(0, _down ? 0.05 : 0),
        child: Container(
          width: widget.width,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: widget.edge, offset: Offset(0, _down ? 2 : 5)),
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.top, widget.bottom],
              ),
            ),
            child: Stack(children: [
              // The shine across the top.
              Positioned(
                left: 14,
                right: 14,
                top: 4,
                height: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: widget.child,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The scattered sparkles, small stars and pink flowers round the card.
const _decor = DecorPainter([
  DecorMark.sparkle(0.07, 0.04, 9, Colors.white),
  DecorMark.sparkle(0.26, 0.05, 8, Color(0xFFFFC94A)),
  // Kept to the margins, clear of the title and the stars.
  DecorMark.sparkle(0.07, 0.34, 8, Color(0xFFB59BF0)),
  DecorMark.sparkle(0.93, 0.33, 9, Color(0xFFB59BF0)),
  DecorMark.sparkle(0.09, 0.71, 7, Color(0xFFB59BF0)),
  DecorMark.sparkle(0.91, 0.70, 8, Color(0xFFB59BF0)),
  DecorMark.sparkle(0.04, 0.84, 6, Colors.white),
  DecorMark.star(0.15, 0.03, 9, Color(0xFFFFB13B)),
  DecorMark.star(0.04, 0.55, 10, Color(0xFFFFB13B)),
  DecorMark.star(0.11, 0.60, 7, Color(0xFFFFC94A)),
  DecorMark.star(0.96, 0.58, 9, Color(0xFF7FD6D2)),
  DecorMark.star(0.03, 0.74, 10, Color(0xFFFFB13B)),
  DecorMark.star(0.12, 0.97, 8, Color(0xFFFFB13B)),
  DecorMark.flower(0.02, 0.21, 11),
  DecorMark.flower(0.03, 0.93, 11),
  DecorMark.flower(0.97, 0.80, 10),
]);
