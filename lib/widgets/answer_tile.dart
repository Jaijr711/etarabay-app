import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'object_picture.dart';
import 'pressable.dart';
import '../utils/word_fit.dart';

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
///
/// Given the board's [labels] too, each tile takes a colour by its place among
/// them — teal, cream, green, lavender — so the answers look like the bright
/// buttons in the design rather than four white boxes.
class AnswerTileGroup extends InheritedWidget {
  final double fontSize;

  /// The board's answers in order, for the tiles' colours. Empty: plain tiles.
  final List<String> labels;

  const AnswerTileGroup({
    super.key,
    required this.fontSize,
    this.labels = const [],
    required super.child,
  });

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AnswerTileGroup>()?.fontSize;

  /// The colour slot for [label] on this board, or null for a plain tile.
  static int? toneOf(BuildContext context, String label) {
    final group = context.dependOnInheritedWidgetOfExactType<AnswerTileGroup>();
    final i = group?.labels.indexOf(label) ?? -1;
    return i < 0 ? null : i;
  }

  @override
  bool updateShouldNotify(AnswerTileGroup oldWidget) =>
      oldWidget.fontSize != fontSize || !listEquals(oldWidget.labels, labels);
}

/// One colour scheme for a tile: its face, its rim (and the 3D edge under
/// it), its words, and the two small decorations in its corners.
class _Tone {
  final Color face, rim, ink;
  final IconData cornerA, cornerB;
  final Color cornerColorA, cornerColorB;
  const _Tone(this.face, this.rim, this.ink, this.cornerA, this.cornerColorA,
      this.cornerB, this.cornerColorB);
}

const _tones = [
  _Tone(
      Color(0xFF9EE6EF),
      Color(0xFF2FA3B5),
      Color(0xFF0D4B5A),
      Icons.local_florist_rounded,
      Color(0xFFF28AB2),
      Icons.local_florist_rounded,
      Color(0xFFFFC94A)), // teal
  _Tone(
      Color(0xFFFFEAA6),
      Color(0xFFE0679A),
      Color(0xFF8C1F4F),
      Icons.local_florist_rounded,
      Color(0xFFF07AA0),
      Icons.star_rounded,
      Color(0xFFFFB800)), // cream and pink
  _Tone(
      Color(0xFFA8E063),
      Color(0xFFF0892A),
      Color(0xFF1E5A17),
      Icons.eco_rounded,
      Color(0xFF3E8E2F),
      Icons.bolt_rounded,
      Color(0xFFFFC107)), // green and orange
  _Tone(
      Color(0xFFDCCBFF),
      Color(0xFF8B61D6),
      Color(0xFF3D2283),
      Icons.favorite_rounded,
      Color(0xFFFF7FA8),
      Icons.star_rounded,
      Color(0xFFFFB800)), // lavender
];

const _rightTone = _Tone(
    Color(0xFFC9F3C1),
    Color(0xFF2E9E3E),
    Color(0xFF14561E),
    Icons.check_circle_rounded,
    Color(0xFF2E9E3E),
    Icons.star_rounded,
    Color(0xFFFFB800));
const _wrongTone = _Tone(
    Color(0xFFFFD3D5),
    Color(0xFFE5484D),
    Color(0xFFA31220),
    Icons.cancel_rounded,
    Color(0xFFE5484D),
    Icons.close_rounded,
    Color(0xFFE5484D));

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
    // The font the tiles are drawn in, so they are measured in it too.
    String? fontFamily,
  }) {
    final list = labels.toList();
    var size = groupFontSize(list);
    if (cellW <= 0 || cellH <= 0 || list.isEmpty) return size;
    // A coloured tile's rim is 3 px each side.
    const border = 6.0;
    bool fits(double s) {
      for (final label in list) {
        final hasPicture = leadingEmoji(label) != null;
        final stacked = hasPicture && cellH >= 96;
        var w = cellW - 24 - border;
        // 5 more for a coloured tile's 3D edge under its face.
        var h = cellH - (stacked ? 20 : 16) - border - 5;
        if (stacked) {
          h -= (cellH * 0.56).clamp(40.0, 92.0) + 4;
        } else if (hasPicture) {
          w -= (cellH * 0.62).clamp(28.0, 64.0) + 10;
        }
        if (w <= 0 || h <= 0) return false;
        // The heaviest weight a tile uses, so none is wider than measured.
        final style = TextStyle(
            fontFamily: fontFamily,
            fontSize: s,
            fontWeight: FontWeight.w900,
            height: 1.1);
        final words = withoutLeadingEmoji(label);
        // Every word whole on one line. Checking the laid-out lines missed
        // this: once a word is broken each piece fits, so "Bedroo" / "m"
        // passed on a small phone.
        if (widestWordWidth(words, style, textScaler: textScaler) > w) {
          return false;
        }
        final painter = TextPainter(
          text: TextSpan(text: words, style: style),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout(maxWidth: w);
        final tooTall = painter.height > h;
        painter.dispose();
        if (tooTall) return false;
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

    // On a board that hands out colours, the tile is a bright, chunky button
    // with a 3D edge — still green when right and red when wrong.
    final toneIndex = AnswerTileGroup.toneOf(context, label);
    final _Tone? tone = toneIndex == null
        ? null
        : (selected && correct == true)
            ? _rightTone
            : (selected && correct == false)
                ? _wrongTone
                : _tones[toneIndex % _tones.length];

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
          final style = TextStyle(
            // The board's shared size when there is one, so every answer
            // reads the same size; otherwise sized from this tile's own
            // length, as before.
            fontSize: AnswerTileGroup.maybeOf(context) ??
                (text.length <= 5 ? 44 : (short ? 28 : 20)),
            color: tone?.ink ?? textColor,
            fontWeight: tone != null
                ? FontWeight.w900
                : (selected ? FontWeight.bold : FontWeight.w600),
            height: 1.1,
          );
          // And never a word broken in two, whatever the board worked out.
          // Measured in the font the text inherits, as it will be drawn.
          final fontSize = wordSafeFontSize(
              text, DefaultTextStyle.of(context).style.merge(style), width,
              textScaler: MediaQuery.textScalerOf(context));
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: style.copyWith(fontSize: fontSize),
              ),
            ),
          );
        });

        final Widget content = emoji == null
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
                  ));

        if (tone != null) {
          final corner = (height * 0.16).clamp(12.0, 20.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: double.infinity,
            // Room under the face for the 3D edge.
            margin: const EdgeInsets.only(bottom: 5),
            constraints: BoxConstraints(minHeight: minHeight),
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: stacked ? 10 : 8),
            decoration: BoxDecoration(
              color: tone.face,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tone.rim, width: 3),
              boxShadow: [
                // The solid edge underneath that makes it a button.
                BoxShadow(color: tone.rim, offset: const Offset(0, 5)),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: content),
              // Small flowers, stars and leaves in two corners, kept in the
              // padding so they never sit on the words.
              Positioned(
                top: -6,
                left: -8,
                child: IgnorePointer(
                    child: Icon(tone.cornerA,
                        size: corner, color: tone.cornerColorA)),
              ),
              Positioned(
                bottom: -6,
                right: -8,
                child: IgnorePointer(
                    child: Icon(tone.cornerB,
                        size: corner, color: tone.cornerColorB)),
              ),
            ]),
          );
        }

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
          child: content,
        );
      }),
    );
  }
}
