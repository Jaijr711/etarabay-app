import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'custom_back_button.dart';

/// The top of the child's own pages — Lessons, Awards, Settings, My Profile
/// and My Certificate — with Tarabay keeping them company.
///
/// These used to be thick bands of five unrelated colours carrying one word
/// each, which a child who cannot read yet has no use for. Here the band
/// takes the colour of the page's own button in the bottom bar, and Tarabay
/// says what the page is for in a bubble a grown-up can read aloud.
///
/// On a small phone (under 700 tall) the bubble would cost the first card
/// below it, so the header folds to one row: the title, Tarabay's words as
/// the line beneath it, and a smaller Tarabay — about as tall as the plain
/// band it replaced.
class KidPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const KidPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bubble,
    required this.color,
    this.showBack = false,
  });

  final String title;

  /// A short line under the title. Required, so every page's title sits the
  /// same way: one page without it was a header of a different height.
  final String subtitle;

  /// What Tarabay says.
  final String bubble;

  /// The page's colour: the band is a pale wash of it, the title a deep one.
  final Color color;
  final bool showBack;

  static const double smallPhone = 700;

  /// The band's own height below the status bar, the same on every page
  /// whatever it carries — a back button, a long title — so moving between
  /// them nothing jumps.
  static const double fullHeight = 108;
  static const double compactHeight = 60;

  static const double _radius = 28;

  @override
  Size get preferredSize => const Size.fromHeight(fullHeight + 20);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final compact = mq.size.height < smallPhone;
    final tint = Color.lerp(color, Colors.white, 0.85)!;
    final ink = Color.lerp(color, Colors.black, 0.35)!;

    final back = showBack
        ? Padding(
            padding: const EdgeInsets.only(right: 10),
            // No margin: with the button's usual 8 all round it needed 56
            // high, and the 44-high title row squashed it flat.
            child: CustomBackButton(
              onPressed: () => Navigator.maybePop(context),
              iconColor: ink,
              backgroundColor: Colors.white,
              margin: EdgeInsets.zero,
            ),
          )
        : null;

    final titleText = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: compact ? 20 : 22,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.1,
        ),
      ),
    );

    Widget line(String text, TextStyle style) => Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );

    // Inside the band, feet and all, at one size on every page.
    final mascot = Image.asset(
      'assets/images/mascot_wave.webp',
      height: compact ? 56 : 92,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

    final Widget content;
    if (compact) {
      content = SizedBox(
        height: compactHeight,
        child: Row(
          children: [
            if (back != null) back,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  titleText,
                  const SizedBox(height: 2),
                  // Tarabay's words take the line; there is no room for both.
                  line(
                    bubble,
                    const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            mascot,
          ],
        ),
      );
    } else {
      content = SizedBox(
        height: fullHeight,
        child: Stack(
          children: [
            Positioned(right: 0, bottom: 0, child: mascot),
            Positioned.fill(
              right: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        if (back != null) back,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              titleText,
                              const SizedBox(height: 2),
                              line(
                                subtitle,
                                const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Always at the band's left edge, under the title row.
                  _Bubble(text: bubble),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      header: true,
      child: Container(
        width: double.infinity,
        // Nothing drawn past the band's own edge.
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.fromLTRB(
            16, mq.padding.top + (compact ? 6 : 8), 10, compact ? 8 : 10),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(_radius),
          ),
        ),
        child: content,
      ),
    );
  }
}

/// Tarabay's words, with a tail pointing right at him.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Room for the tail.
      padding: const EdgeInsets.only(right: 8),
      child: CustomPaint(
        painter: const _TailPainter(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A1E3C50),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final path = Path()
      ..moveTo(size.width - 1, mid - 7)
      ..lineTo(size.width + 7, mid)
      ..lineTo(size.width - 1, mid + 7)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => false;
}
