import 'package:flutter/material.dart';

/// Keeping words whole.
///
/// Flutter breaks a word that is wider than its line in the middle — on a
/// small phone a tile showed "Bedroo" over "m", and a longer translation
/// does the same to any label sized for English. Nothing in Flutter turns
/// that off, so the text is made small enough instead: the longest word has
/// to fit on one line, and the rest wraps between words as usual.

/// The width of [text]'s widest word in [style].
double widestWordWidth(String text, TextStyle style,
    {TextScaler textScaler = TextScaler.noScaling}) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest;
}

/// [style]'s font size, or less if that is what it takes for every word of
/// [text] to fit [maxWidth] on one line.
double wordSafeFontSize(String text, TextStyle style, double maxWidth,
    {TextScaler textScaler = TextScaler.noScaling}) {
  final size = style.fontSize ?? 14;
  if (!maxWidth.isFinite || maxWidth <= 0) return size;
  final widest = widestWordWidth(text, style.copyWith(fontSize: size),
      textScaler: textScaler);
  if (widest <= maxWidth) return size;
  // Width grows with the font size; the margin covers rounding in layout.
  return (size * maxWidth / widest * 0.97).floorToDouble();
}

/// A [Text] that never breaks a word in the middle: if its longest word is
/// wider than the room it is given, the whole text is set smaller.
///
/// Measures its width with a [LayoutBuilder], so it needs a bounded width
/// and cannot sit where intrinsic sizes are asked for.
class WordSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const WordSafeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (_, box) {
      final size =
          wordSafeFontSize(text, base, box.maxWidth, textScaler: scaler);
      return Text(
        text,
        style: base.copyWith(fontSize: size),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    });
  }
}
