import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import 'pressable.dart';
import '../services/device_performance.dart';

/// What pressing a level tile will do, said on the pill under its name.
enum ModuleCardState { start, resume, done }

/// One level of a module, as a tile two to a row: the picture of what the
/// level asks in a white panel, its number on a round badge, the stars on a
/// capsule under the picture, the name, and a pill that says start, carry
/// on, or finished.
///
/// The levels were one wide card to a row, seven or nine long cards to
/// scroll through. Two to a row the whole module fits in about half the
/// screen, and the pictures — what a child who cannot read yet goes by —
/// are twice the size.
///
/// Same geometry as the approved preview (design C): 20 corners, a 92-tall
/// panel with a 96×90 picture, the badge and the tick hanging 6 off its
/// corners, the star capsule 10 below it. A [wide] tile is the last one of
/// an odd count, across the whole row, so no row is left half empty.
class ModuleLevelTile extends StatelessWidget {
  /// "Level 7" — written on a wide tile, read out on every tile.
  final String label;

  /// The number on the badge: the level's place in its own group.
  final int number;
  final String title;
  final Color color;
  final Widget picture;
  final ModuleCardState state;

  /// The level's stars out of three.
  final int stars;

  /// The next thing to do: drawn with a ring in the tile's colour.
  final bool highlight;

  /// Shown on the pill in place of "Start" / "Continue".
  final String? actionLabel;

  /// Across the whole row, the picture on the left.
  final bool wide;

  final VoidCallback? onTap;

  const ModuleLevelTile({
    super.key,
    required this.label,
    required this.number,
    required this.title,
    required this.color,
    required this.picture,
    required this.state,
    required this.stars,
    this.highlight = false,
    this.actionLabel,
    this.wide = false,
    this.onTap,
  });

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: wide
          ? const EdgeInsets.fromLTRB(8, 8, 12, 8)
          : const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(color.withOpacity(0.18), Colors.white),
            Color.alphaBlend(color.withOpacity(0.10), Colors.white),
          ],
        ),
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282850).withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          // The hard edge underneath, in the tile's own colour: it reads as
          // something that can be pressed down.
          BoxShadow(color: color.withOpacity(0.22), offset: const Offset(0, 3)),
        ],
      ),
      child: wide ? _wideBody(context) : _body(context),
    );

    return Semantics(
      button: true,
      label: '$label, $title',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.97,
        onTap: onTap,
        // The ring is painted over the tile, not added to it, so the ringed
        // tile is exactly as big as the others.
        child: Stack(
          children: [
            tile,
            if (highlight)
              Positioned.fill(
                child: IgnorePointer(child: _Ring(color: color)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(capsule: true),
        const SizedBox(height: 16),
        // Room for two lines on every tile, so the pills of a row line up.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 14 * 1.15 * 2),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: _titleStyle,
          ),
        ),
        const Spacer(),
        const SizedBox(height: 6),
        Center(
          child:
              _ModulePill(state: state, color: color, actionLabel: actionLabel),
        ),
      ],
    );
  }

  Widget _wideBody(BuildContext context) {
    return Row(
      children: [
        _panel(capsule: false, width: 136),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.44,
                  color:
                      Color.lerp(color, Colors.black, 0.18)!.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TileStars(count: stars),
                  _ModulePill(
                      state: state, color: color, actionLabel: actionLabel),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _titleStyle = TextStyle(
    fontSize: 14,
    height: 1.15,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
  );

  /// The white panel the picture sits in, with the badge, the tick and the
  /// stars hung off it.
  Widget _panel({required bool capsule, double? width}) {
    return SizedBox(
      width: width,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                color: Colors.white.withOpacity(0.75),
                alignment: Alignment.bottomCenter,
                child: Container(height: 3, color: color.withOpacity(0.14)),
              ),
            ),
          ),
          Center(child: SizedBox(width: 96, height: 90, child: picture)),
          Positioned(
            left: -6,
            top: -6,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (state == ModuleCardState.done)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E9B4E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF23793C), offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 15, color: Colors.white),
              ),
            ),
          if (capsule)
            Positioned(
              left: 0,
              right: 0,
              bottom: -10,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF282850).withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _TileStars(count: stars),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The tiles of one group, two to a row, each row as tall as its taller
/// tile. An odd one out at the end goes across the whole row.
class ModuleTileGrid extends StatelessWidget {
  final int count;

  /// Builds tile [i]; [wide] when it is the odd one out.
  final Widget Function(int i, bool wide) builder;

  const ModuleTileGrid({super.key, required this.count, required this.builder});

  static const double gap = 10;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < count; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      if (i + 1 == count) {
        rows.add(builder(i, true));
        break;
      }
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: builder(i, false)),
            const SizedBox(width: gap),
            Expanded(child: builder(i + 1, false)),
          ],
        ),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// The ring on the next level: it breathes, so a child's eye finds it.
class _Ring extends StatefulWidget {
  final Color color;

  const _Ring({required this.color});

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ModuleLevelTile._radius),
          border: Border.all(
            color: widget.color.withOpacity(
                1 - 0.55 * Curves.easeInOut.transform(_pulse.value)),
            width: 3,
          ),
        ),
      ),
    );
  }
}

/// Start, Continue, or Done — the same pill on every module's levels.
class _ModulePill extends StatelessWidget {
  final ModuleCardState state;
  final Color color;
  final String? actionLabel;

  const _ModulePill(
      {required this.state, required this.color, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final done = state == ModuleCardState.done;
    final text = done
        ? loc.lessonDone
        : actionLabel ??
            (state == ModuleCardState.resume
                ? loc.lessonContinue
                : loc.lessonStart);
    const doneGreen = Color(0xFF2E9B4E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE3F6E8) : color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check_rounded, size: 13, color: doneGreen),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: done ? doneGreen : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three small stars on the tile: the earned ones gold, the rest a faint
/// grey of the same shape.
class _TileStars extends StatelessWidget {
  final int count;

  const _TileStars({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(
          Icons.star_rounded,
          size: 15,
          color: i < count
              ? const Color(0xFFFFB800)
              : const Color(0xFF1F2340).withOpacity(0.16),
        ),
      ),
    );
  }
}

/// Three stars, the earned ones filled gold.
class ModuleStars extends StatelessWidget {
  final int count;
  final double size;

  const ModuleStars({super.key, required this.count, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final got = i < count;
        return Icon(
          got ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: got ? const Color(0xFFFFB800) : const Color(0xFFC3C8D4),
        );
      }),
    );
  }
}

/// A picture with a soft shadow under it, the way the Lessons cards draw
/// theirs.
class ModulePicture extends StatelessWidget {
  final String asset;
  final double width;
  final double height;

  /// No shadow of its own: for a picture that already carries one.
  final bool shadow;

  const ModulePicture(this.asset,
      {super.key,
      double size = 78,
      double? width,
      double? height,
      this.shadow = true})
      : width = width ?? size,
        height = height ?? size;

  @override
  Widget build(BuildContext context) {
    // Decoded at the size it is shown (with room for DesignScale's
    // enlargement), not the file's: a 512-pixel picture in a 90-pixel box
    // held thirty times the memory it needed.
    final decodeWidth =
        (width * MediaQuery.devicePixelRatioOf(context) * 1.3).ceil();
    Widget image({Color? tint}) => Image.asset(
          asset,
          width: width,
          height: height,
          cacheWidth: decodeWidth,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcIn,
          errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
        );
    // The blurred shadow is a layer of its own for every picture on the
    // screen: skipped on a phone that cannot draw it smoothly.
    if (!shadow || DevicePerformance.lite.value) return image();
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: image(tint: const Color(0x33000000)),
          ),
        ),
        image(),
      ],
    );
  }
}

/// How much of a module the child holds, at the top of its list: a white
/// card with a picture, "5 of 21 stars", and a bar.
///
/// The number counts and the bar fills over three quarters of a second, as
/// the old band did — a child back from a level watches it change instead of
/// finding it already changed.
class ModuleTally extends StatelessWidget {
  final String picture;
  final int done;
  final int total;

  /// Builds the words from the counted-up number, so they count up too.
  final String Function(int done) label;

  const ModuleTally({
    super.key,
    required this.picture,
    required this.done,
    required this.total,
    required this.label,
  });

  static const Duration _fill = Duration(milliseconds: 750);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282850).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(picture,
              width: 42, height: 42, excludeFromSemantics: true),
          const SizedBox(width: 10),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: done.toDouble()),
              duration: _fill,
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label(value.round()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      height: 9,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: Color(0xFFECEEF4)),
                          ),
                          // Full height: without it the fill sat in the
                          // stack's loose constraints and drew zero tall, so
                          // the bar stayed grey at 21 of 21.
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            heightFactor: 1,
                            widthFactor: total == 0
                                ? 0
                                : (value / total).clamp(0.0, 1.0),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(9)),
                                gradient: LinearGradient(colors: [
                                  Color(0xFFFFC93C),
                                  Color(0xFFFF9F1C),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
