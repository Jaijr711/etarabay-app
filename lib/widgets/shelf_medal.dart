import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'badge_claim_celebration.dart';
import 'badge_emblem.dart';

/// One medal on the awards shelf.
///
/// A medal waiting to be taken wiggles now and then and its "Claim!" tag
/// breathes, so a child who cannot read sees which one to press. One press
/// claims it: the celebration plays, the medal flies back down into this
/// place, and lands here with a bounce.
class ShelfMedal extends StatefulWidget {
  const ShelfMedal({
    super.key,
    required this.icon,
    required this.image,
    required this.color,
    required this.tier,
    required this.title,
    required this.size,
    required this.isEarned,
    required this.ready,
    required this.claimLabel,
    required this.onClaim,
    required this.onOpen,
  });

  final IconData icon;
  final String? image;
  final Color color;
  final int tier;
  final String title;
  final double size;
  final bool isEarned;

  /// Won and not yet taken.
  final bool ready;
  final String claimLabel;

  /// Takes the medal (UserProvider.claimBadge).
  final Future<void> Function() onClaim;

  /// Any other press: look at a taken medal, or how to win one.
  final VoidCallback onOpen;

  /// Where the "Claim!" tag sits on the medal: 'top' (across its top edge)
  /// or 'corner' (tilted on its top right). On the medal, never under it:
  /// a tag under it made the medal taller, and the shelf's wood jumped each
  /// time a tag came or went. Only previews change it.
  @visibleForTesting
  static String tagPlacement = 'top';

  @override
  State<ShelfMedal> createState() => _ShelfMedalState();
}

class _ShelfMedalState extends State<ShelfMedal> with TickerProviderStateMixin {
  late final AnimationController _wiggle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController _land = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  final _emblemKey = GlobalKey();
  bool _hidden = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.ready) _wiggle.repeat();
  }

  @override
  void didUpdateWidget(ShelfMedal old) {
    super.didUpdateWidget(old);
    if (widget.ready && !_wiggle.isAnimating) {
      _wiggle.repeat();
    } else if (!widget.ready && _wiggle.isAnimating) {
      _wiggle.stop();
      _wiggle.value = 0;
    }
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _land.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    if (_busy) return;
    _busy = true;
    final box = _emblemKey.currentContext?.findRenderObject() as RenderBox?;
    final target = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    setState(() => _hidden = true);
    // Taken at once, on the phone; the celebration does not wait on it.
    final taking = widget.onClaim();
    await BadgeClaimCelebration.show(
      context,
      icon: widget.icon,
      image: widget.image,
      color: widget.color,
      tier: widget.tier,
      title: widget.title,
      target: target,
    );
    await taking;
    if (!mounted) return;
    setState(() => _hidden = false);
    _land.forward(from: 0);
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.ready ? _claim : widget.onOpen,
      child: SizedBox(
        width: widget.size + 12,
        child: AnimatedBuilder(
          animation: Listenable.merge([_wiggle, _land]),
          builder: (context, _) {
            final w = _wiggle.value;
            // A short wiggle at the start of each turn, then still.
            final wiggling = widget.ready && w < 0.3;
            final angle = wiggling
                ? math.sin(w / 0.3 * math.pi * 4) * 0.12 * (1 - w / 0.3)
                : 0.0;
            final hop = wiggling ? -math.sin(w / 0.3 * math.pi) * 5 : 0.0;
            final landing = _land.value;
            final landScale = _land.isAnimating
                ? 0.6 + 0.4 * Curves.elasticOut.transform(landing)
                : 1.0;
            final ring = _land.isAnimating ? 1 - landing : 0.0;
            final breathe = 1 + 0.07 * math.sin(w * 2 * math.pi * 2);

            return Opacity(
              opacity: _hidden ? 0 : 1,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // The medal, with the tag laid on it: the same height
                // whether there is a tag or not.
                Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, hop),
                        child: Transform.rotate(
                          angle: angle,
                          child: Transform.scale(
                            scale: landScale,
                            // Only the medal sizes this Stack. The ring and the
                            // glow are laid over it, outside the layout: the
                            // ring used to grow the Stack as it spread, and the
                            // name underneath slid down while the medal landed.
                            child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  // Waiting: a soft gold light behind the
                                  // locked medal, breathing with its tag, so it
                                  // does not read as one still to be won.
                                  if (widget.ready)
                                    Positioned.fill(
                                      child: OverflowBox(
                                        minWidth: 0,
                                        minHeight: 0,
                                        maxWidth: widget.size * 1.5,
                                        maxHeight: widget.size * 1.5,
                                        child: Container(
                                          width: widget.size * 0.9,
                                          height: widget.size * 0.9,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFC21A)
                                                    .withOpacity(0.35 +
                                                        0.3 *
                                                            (breathe - 1) /
                                                            0.07),
                                                blurRadius: widget.size * 0.3,
                                                spreadRadius: widget.size * 0.06,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  KeyedSubtree(
                                    key: _emblemKey,
                                    child: BadgeEmblem(
                                      icon: widget.icon,
                                      image: widget.image,
                                      color: widget.color,
                                      size: widget.size,
                                      // Locked until it is taken: the
                                      // celebration opens that lock, so the
                                      // shelf must not show it open already.
                                      locked: !widget.isEarned || widget.ready,
                                      tier: widget.tier,
                                      sparkle: widget.ready,
                                    ),
                                  ),
                                  // A gold ring spreading out as it lands.
                                  if (ring > 0)
                                    Positioned.fill(
                                      child: OverflowBox(
                                        minWidth: 0,
                                        minHeight: 0,
                                        maxWidth: widget.size * 1.6,
                                        maxHeight: widget.size * 1.6,
                                        child: Container(
                                          width:
                                              widget.size * (1 + 0.6 * landing),
                                          height:
                                              widget.size * (1 + 0.6 * landing),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFFFD23F)
                                                  .withOpacity(ring),
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ]),
                          ),
                        ),
                      ),
                      if (widget.ready)
                        Positioned(
                          top: ShelfMedal.tagPlacement == 'corner' ? -6 : -10,
                          right:
                              ShelfMedal.tagPlacement == 'corner' ? -10 : null,
                          child: Transform.rotate(
                            angle:
                                ShelfMedal.tagPlacement == 'corner' ? 0.22 : 0,
                            child: Transform.scale(
                              scale: breathe,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD23F),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFB300)
                                          .withOpacity(0.35 +
                                              0.25 * (breathe - 1) / 0.07),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.claimLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7A4A00),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                const SizedBox(height: 3),
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: widget.isEarned
                        ? const Color(0xFF5A3A12)
                        : const Color(0xFF8D7B66),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
