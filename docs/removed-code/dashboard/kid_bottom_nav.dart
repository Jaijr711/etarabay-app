import 'package:flutter/material.dart';

/// One destination in the bottom bar.
class KidNavItem {
  final IconData icon;
  final String label;

  /// Each destination keeps its own colour, so a child who cannot read the
  /// words still learns where they are going by the shape and the colour.
  final Color color;

  const KidNavItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// The bar along the bottom: Home, Lessons, For Parents, Awards, Settings.
///
/// "For Parents" sits in this row like the others but is marked out — it leads
/// out of the child's part of the app, and the lock on it is the screen it
/// opens, not this button.
class KidBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<KidNavItem> items;

  /// Which entry leaves the child's area. Drawn with a ring so it reads as a
  /// door rather than another game.
  final int? guardedIndex;

  const KidBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.guardedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11397A).withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavButton(
                item: items[i],
                selected: i == selectedIndex,
                guarded: i == guardedIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final KidNavItem item;
  final bool selected;
  final bool guarded;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.guarded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        // A full-height target: a three-year-old aims at the word as often as
        // at the picture, and both should work.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? item.color.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: guarded
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: item.color.withOpacity(0.45), width: 2),
                      )
                    : null,
                child: Icon(
                  item.icon,
                  size: 25,
                  color: selected ? item.color : item.color.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? item.color : const Color(0xFF7A8699),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
