import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// How much of a module the child holds, at the top of its wall of cards.
///
/// The number and the bar are the first thing on the screen a child comes
/// back to after finishing a level — and they used to *jump*: nineteen where
/// eighteen had been, a bar a little longer than before, both changed in the
/// frame before the child could look at them. The one moment the module has
/// to say "that counted" went by unseen.
///
/// So the number counts and the bar fills, over three quarters of a second,
/// from whatever they were. On the way in from the dashboard they run up from
/// zero, which is the same animation doing an introduction.
///
/// Written once and used by all three modules; the three headers were copies
/// of each other.
class StarTally extends StatelessWidget {
  final int earned;
  final int possible;

  const StarTally({super.key, required this.earned, required this.possible});

  static const Duration _fill = Duration(milliseconds: 750);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 24),
              const SizedBox(width: 6),
              // Counted, not set. A number that lands on nineteen after
              // climbing there is a number a four-year-old watches.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: earned.toDouble()),
                duration: _fill,
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => Text(
                  '${value.round()}/$possible',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: possible == 0 ? 0 : earned / possible,
              ),
              duration: _fill,
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
