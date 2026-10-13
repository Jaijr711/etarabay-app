import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NavItemData {
  final IconData icon;
  final String label;

  /// Artwork for this destination, drawn instead of [icon] when present.
  ///
  /// A modelled picture reads better to a child than a line glyph — it has
  /// depth and a shadow, and looks like something that can be pressed.
  final String? assetPath;

  /// This destination's colour, shown whether or not it is the current one.
  ///
  /// A child who cannot read the label navigates by colour and shape. When
  /// every item was grey until selected, the only difference between four
  /// destinations was a small glyph — and colour, the strongest signal
  /// available, was being spent on "you are here" instead of "this is what
  /// this is".
  final Color color;

  const NavItemData({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.assetPath,
  });
}

class FloatingBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NavItemData> items;

  /// Optional distinct center action button (e.g. "For Parents"). When
  /// provided, it renders raised in the middle, splitting [items] into two
  /// groups around it.
  final VoidCallback? onCenterTap;
  final IconData? centerIcon;
  final String? centerLabel;

  const FloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.onCenterTap,
    this.centerIcon,
    this.centerLabel,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Distinct color for the center (parents) button — differs from the
  // primary tab color so it clearly stands apart from the 4 pages.
  static const Color _centerStart = Color(0xFF7C4DFF);
  static const Color _centerEnd = Color(0xFF9C6BFF);

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(covariant FloatingBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasCenter = widget.centerIcon != null && widget.onCenterTap != null;

    // Split items into two halves around the center button.
    final int half = (widget.items.length / 2).ceil();

    final pill = Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        // Tighter than 8: four pictures and a reserved centre gap were
        // sharing the width, and every pixel spent on padding came off the
        // targets either side of it.
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (!hasCenter)
              for (int i = 0; i < widget.items.length; i++)
                Expanded(child: _buildNavColumn(i))
            else ...[
              for (int i = 0; i < half; i++)
                Expanded(child: _buildNavColumn(i)),
              // Reserved space for the raised center button & label (no overlap).
              const SizedBox(width: 72),
              for (int i = half; i < widget.items.length; i++)
                Expanded(child: _buildNavColumn(i)),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: hasCenter ? 26 : 0,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
      ),
      child: hasCenter
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                pill,
                Positioned(
                  top: -24,
                  child: _buildCenterButton(),
                ),
              ],
            )
          : pill,
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: widget.onCenterTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_centerStart, _centerEnd],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: _centerStart.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(widget.centerIcon, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildNavColumn(int index) {
    final item = widget.items[index];
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      // Claims the whole column height. Without it the Stack below is only as
      // tall as the picture, and the strip either side of it — which looks
      // just as tappable — quietly is not.
      child: SizedBox(
        height: double.infinity,
        child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          final scale = isSelected
              ? 1.0 + 0.12 * (1 - _bounceAnimation.value).clamp(0.0, 1.0)
              : 1.0;

          return Transform.scale(
            scale: scale,
            // The whole column is the target, edge to edge. A margin here
            // made the hit area smaller than it looked, and a miss reads to a
            // child as the app ignoring them rather than as their own aim.
            child: Semantics(
              label: item.label,
              button: true,
              selected: isSelected,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    // A pill around the picture and the word together. The
                    // disc this replaces was sized for a picture on its own
                    // and cropped the label the moment it came back.
                    color: isSelected
                        ? item.color.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: item.color.withOpacity(isSelected ? 0.4 : 0),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(item, isSelected),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            // The word wears the destination's colour too, so
                            // picture and label say the same thing rather
                            // than the label going grey and undoing it.
                            color: isSelected
                                ? item.color
                                : item.color.withOpacity(0.7),
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(NavItemData item, bool isSelected) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Shares the strip with the word again. Still well above the 16
        // this bar started with, and the label under it does the naming.
        final size = 30 + value * 3;

        if (item.assetPath != null) {
          return Opacity(
            // The artwork carries its own colour, so being unchosen is shown
            // by letting it sit back rather than by tinting it.
            opacity: 0.62 + 0.38 * value,
            child: Image.asset(
              item.assetPath!,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                item.icon,
                size: size,
                color: Color.lerp(
                    item.color.withOpacity(0.55), item.color, value),
              ),
            ),
          );
        }

        return Icon(
          item.icon,
          size: size,
          // Fades between the destination's own colour at rest and at full
          // strength when chosen — never to grey, which would take away the
          // one thing that says which door this is.
          color: Color.lerp(item.color.withOpacity(0.55), item.color, value),
        );
      },
    );
  }
}
