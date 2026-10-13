import 'package:flutter/material.dart';

import 'object_picture.dart';
import 'pressable.dart';

/// One answer a child taps, in "Ang Aking Sarili" and "Ken Ti Pamiliak".
///
/// Pulled out of the screen so it can be looked at on its own — the tile is
/// the thing a three-year-old spends the whole module touching, and it was
/// the one piece of the board that could not be rendered without the entire
/// provider stack behind it.
///
/// Two rules run through the design:
///
///   * **The picture leads.** A child who cannot read the word can read the
///     drawing, so when there is room the picture goes on top at picture size
///     and the word sits under it as a caption. In a short tile they sit side
///     by side instead, because a stacked picture in 60 pixels is a stamp.
///   * **Everything grows into the room it has.** The tile measures itself
///     and sizes the drawing and the text from its own height, rather than
///     from constants that were tuned when a strip of level tabs was eating
///     the top of the screen.
/// One text size for every answer on a board.
///
/// Each tile used to size its own words from its own length, so a question
/// could show "Father" at 44 beside "Grandmother only" at 20 — the answers
/// looked unequal, as if one mattered more. The board wraps its tiles in this
/// with a size worked out from its longest answer ([AnswerTile.groupFontSize]),
/// and every tile under it uses that size.
class AnswerTileGroup extends InheritedWidget {
  final double fontSize;

  const AnswerTileGroup({
    super.key,
    required this.fontSize,
    required super.child,
  });

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AnswerTileGroup>()?.fontSize;

  @override
  bool updateShouldNotify(AnswerTileGroup oldWidget) =>
      oldWidget.fontSize != fontSize;
}

class AnswerTile extends StatelessWidget {
  /// The size every answer on a board shares, from the longest of them.
  /// Pictures are left out of the count: they are drawn, not typed.
  static double groupFontSize(Iterable<String> labels) {
    var longest = 0;
    for (final l in labels) {
      final n = withoutLeadingEmoji(l).length;
      if (n > longest) longest = n;
    }
    if (longest <= 5) return 40;
    if (longest <= shortLabelLimit) return 26;
    if (longest <= 32) return 20;
    return 17;
  }

  /// The largest size, up to [groupFontSize], at which EVERY answer fits the
  /// tile the board gives it — measured, so no tile has to shrink its own
  /// words afterwards and fall out of step with the others. [cellW] and
  /// [cellH] are one grid cell; the slot for the words inside it follows the
  /// same padding, picture and layout rules as [build].
  static double fitFontSize(
    Iterable<String> labels, {
    required double cellW,
    required double cellH,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final list = labels.toList();
    var size = groupFontSize(list);
    if (cellW <= 0 || cellH <= 0 || list.isEmpty) return size;
    const border = 4.0;
    bool fits(double s) {
      for (final label in list) {
        final hasPicture = leadingEmoji(label) != null;
        final stacked = hasPicture && cellH >= 96;
        var w = cellW - 24 - border;
        var h = cellH - (stacked ? 20 : 16) - border;
        if (stacked) {
          h -= (cellH * 0.56).clamp(40.0, 92.0) + 4;
        } else if (hasPicture) {
          w -= (cellH * 0.62).clamp(28.0, 64.0) + 10;
        }
        if (w <= 0 || h <= 0) return false;
        final painter = TextPainter(
          text: TextSpan(
            text: withoutLeadingEmoji(label),
            // Bold is the wider of the two weights a tile uses.
            style: TextStyle(
                fontSize: s, fontWeight: FontWeight.bold, height: 1.1),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout(maxWidth: w);
        // A single word wider than the slot would be broken mid-word.
        final tooWide = painter.computeLineMetrics().any((l) => l.width > w + 0.5);
        final tooTall = painter.height > h;
        painter.dispose();
        if (tooWide || tooTall) return false;
      }
      return true;
    }

    while (size > 11 && !fits(size)) {
      size -= 1;
    }
    return size;
  }

  /// The answer as the content stores it — "👧 Babae", or a whole sentence.
  final String label;

  /// True once this is the tile the child pressed.
  final bool selected;

  /// Null until the answer has been graded; then true or false.
  final bool? correct;

  final VoidCallback onTap;

  /// Never smaller than this, whatever the grid hands it.
  final double minHeight;

  const AnswerTile({
    super.key,
    required this.label,
    required this.selected,
    required this.correct,
    required this.onTap,
    this.minHeight = 54,
  });

  /// Longest answer that still reads comfortably at half the board's width.
  static const int shortLabelLimit = 16;

  /// The picture at the front of [label], or null when it starts with a word.
  ///
  /// Whatever sits before the first space with no letters or digits in it.
  static String? leadingEmoji(String label) {
    final trimmed = label.trim();
    final space = trimmed.indexOf(' ');
    if (space <= 0) return null;
    final head = trimmed.substring(0, space);
    if (RegExp(r'[A-Za-z0-9]').hasMatch(head)) return null;
    return head;
  }

  /// [label] with that picture taken off the front.
  static String withoutLeadingEmoji(String label) {
    final trimmed = label.trim();
    final space = trimmed.indexOf(' ');
    if (space <= 0) return trimmed;
    final head = trimmed.substring(0, space);
    if (RegExp(r'[A-Za-z0-9]').hasMatch(head)) return trimmed;
    return trimmed.substring(space + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    // The whole tile carries the verdict: green for right, red for wrong. No
    // badge, no icon — at three years old the colour of the thing you just
    // pressed is read instantly, while a small symbol inside it is one more
    // shape to work out.
    const wrongColor = Color(0xFFE5484D);
    final bool answered = selected && correct != null;

    late final Color borderColor;
    late final Color bgColor;
    late final Color textColor;
    if (selected && correct == true) {
      borderColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.12);
      textColor = Colors.green.shade800;
    } else if (selected && correct == false) {
      borderColor = wrongColor;
      bgColor = wrongColor.withOpacity(0.14);
      textColor = const Color(0xFFA31220);
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.white;
      textColor = Colors.grey.shade800;
    }

    final emoji = leadingEmoji(label);
    final text = withoutLeadingEmoji(label);
    final short = label.trim().length <= shortLabelLimit;

    return Pressable(
      onTap: onTap,
      // A big tile needs less squeeze than a small one to read as a press.
      scale: 0.96,
      child: LayoutBuilder(builder: (_, box) {
        final height = box.maxHeight.isFinite && box.maxHeight > 0
            ? box.maxHeight
            : minHeight;
        // Stacked once there is room for a picture that still looks like a
        // picture. Below that the two sit in a row.
        final stacked = emoji != null && height >= 96;
        // Generous on purpose: the artwork is drawn with air around the
        // figure, so a picture measured at "half the tile" arrives on screen
        // looking like a third of it.
        final picture = stacked
            ? (height * 0.56).clamp(40.0, 92.0)
            : (height * 0.62).clamp(28.0, 64.0);

        // A word gets to be big; a sentence stays at reading size. FittedBox
        // only ever shrinks, so the base size has to be set high enough for
        // the short case to actually fill its tile.
        //
        // The SizedBox is what makes a long answer readable. A Text handed
        // straight to a FittedBox is measured with no width limit, so it lays
        // out as ONE line however long it is and the FittedBox then shrinks
        // that whole line to the tile's width — "Pinoprotektahan at inaalagaan
        // nito ang aming pamilya nang may pagmamahal" arrived at about nine
        // pixels tall while "Maingay ito" beside it sat at twenty-eight. Bound
        // to the slot's width the sentence wraps instead, and the FittedBox is
        // left with only the job it is good at: shrinking a block that is
        // still too tall. Every translation gets this — an answer short in
        // Filipino can be half a line longer in Ilocano.
        final Widget words = LayoutBuilder(builder: (_, slot) {
          final width = slot.maxWidth.isFinite && slot.maxWidth > 0
              ? slot.maxWidth
              : box.maxWidth;
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  // The board's shared size when there is one, so every
                  // answer reads the same size; otherwise sized from this
                  // tile's own length, as before.
                  fontSize: AnswerTileGroup.maybeOf(context) ??
                      (text.length <= 5 ? 44 : (short ? 28 : 20)),
                  color: textColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          );
        });

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding:
              EdgeInsets.symmetric(horizontal: 12, vertical: stacked ? 10 : 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: answered ? 3 : 2),
            // Even unpressed, a tile sits slightly above the card: a flat
            // outline reads as a label, and a label does not invite a
            // three-year-old to push it.
            boxShadow: [
              BoxShadow(
                color: answered
                    ? borderColor.withOpacity(0.30)
                    : Colors.black.withOpacity(0.06),
                blurRadius: answered ? 14 : 6,
                offset: Offset(0, answered ? 5 : 3),
              ),
            ],
          ),
          child: emoji == null
              ? Center(child: words)
              : (stacked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ObjectPicture(emoji: emoji, size: picture),
                        const SizedBox(height: 4),
                        Flexible(child: words),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ObjectPicture(emoji: emoji, size: picture),
                        const SizedBox(width: 10),
                        Flexible(child: words),
                      ],
                    )),
        );
      }),
    );
  }
}
