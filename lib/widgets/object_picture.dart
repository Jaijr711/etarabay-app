import 'package:flutter/material.dart';

import 'shape_glyph.dart';

/// The things a child counts in Matematika, drawn as pictures.
///
/// The games store their objects as emoji, and emoji are a different drawing
/// on every phone — the apple a child counts on one device is not the apple
/// they count on another, and none of them match the app's own artwork.
///
/// This maps each emoji to a file in `assets/images/objects/`. Until that file
/// exists the emoji is drawn exactly as before, so the games keep working and
/// pictures can be added one at a time rather than all at once.
class ObjectPicture extends StatelessWidget {
  /// The emoji stored in the game data, e.g. '🍎'.
  final String emoji;

  /// Width and height to draw into.
  final double size;

  const ObjectPicture({super.key, required this.emoji, required this.size});

  /// Where the picture for [emoji] lives, or null if it has no file yet.
  ///
  /// Straight in `assets/images/`, beside the rest of the app's artwork —
  /// that is where the files actually get dropped, and the folder is already
  /// declared in pubspec, so a new picture needs no configuration at all.
  static String? assetFor(String emoji) {
    final name = _fileNames[_normalise(emoji)];
    return name == null ? null : 'assets/images/$name.png';
  }

  /// Some artwork arrives as .jpg rather than .png.
  ///
  /// Whoever draws a picture should not have to remember which extension the
  /// code expects, so the widget tries the png first and falls back to the
  /// jpg before it gives up and draws the emoji.
  static String? _alternateFor(String emoji) {
    final name = _fileNames[_normalise(emoji)];
    return name == null ? null : 'assets/images/$name.jpg';
  }

  /// Strips the invisible characters that make the same picture two keys.
  ///
  /// Several objects are written in the game data with a variation selector
  /// after them — the sofa is stored as U+1F6CB followed by U+FE0F, which
  /// tells the font to draw it in colour. It looks identical and is a
  /// different string, so a map keyed on the bare character missed it and the
  /// artwork silently never appeared for the sofa, the bed, the sun and the
  /// heart. Nothing broke; the picture just never arrived, which is the
  /// hardest kind of fault to notice.
  static String _normalise(String emoji) =>
      emoji.trim().replaceAll('️', '').replaceAll('︎', '');

  /// Every object any board draws, and the file each one wants.
  ///
  /// Started as Matematika's fourteen; it now covers Tandaan's pairs and the
  /// people, rooms and things in Ang Aking Sarili as well. A board looks its
  /// object up here, so one file lands everywhere that object appears — the
  /// same dog in the memory game and in the family questions.
  ///
  /// Keyed by the emoji itself so the game data does not have to change: drop
  /// `apple.png` in and every apple in every level becomes that picture.
  static const Map<String, String> _fileNames = {
    '🍎': 'apple',
    '🍌': 'banana',
    '🍇': 'grapes',
    '🍒': 'cherries',
    '🐟': 'fish',
    '🐦': 'bird',
    '🐭': 'mouse',
    '🐶': 'dog',
    '🐱': 'cat',
    '🌸': 'flower',
    '🎈': 'balloon',
    '🚗': 'car',
    '⭐': 'star',
    '⚽': 'ball',

    // People — the family, and the child themselves
    '👧': 'girl',
    '👦': 'boy',
    '👨': 'tatay',
    '👩': 'nanay',
    '👴': 'lolo',
    '👵': 'lola',
    '🧑': 'kuya',
    '👶': 'sanggol',
    '👤': 'tao',

    // Food
    '🍚': 'kanin',
    '🍳': 'itlog',
    '🍛': 'ulam',
    '🍖': 'karne',
    '🍦': 'sorbetes',
    '🍪': 'biskwit',
    '🎂': 'cake',
    '🍊': 'dalandan',
    '🍓': 'strawberry',
    '🍍': 'pinya',

    // Animals
    '🐮': 'kalabaw_mukha',
    '🐷': 'baboy',
    '🐔': 'manok',
    '🐰': 'kuneho',
    '🐓': 'tandang',
    '🐃': 'kalabaw',

    // Colours — these have uploaded artwork. The five plain shapes that do
    // not (square, triangle, heart, diamond, cross) are drawn by ShapeGlyph
    // instead and are deliberately absent here.
    '🔴': 'pula',
    '🔵': 'asul',
    '🟢': 'berde',
    '🟡': 'dilaw',

    // Around the house
    '🛏': 'kama',
    '🛋': 'sopa',
    '📺': 'telebisyon',
    '🚿': 'shower',
    '🧼': 'sabon',
    '🪥': 'sipilyo',
    '🏠': 'bahay',
    '🏡': 'bahay_hardin',
    '📱': 'telepono',
    '💧': 'tubig',

    // Play and things
    '🧸': 'teddy',
    // Named for the game the picture shows, not the emoji standing in
    // for it: the running figure is a game of taguan, the dartboard is
    // tumbang preso. Naming them after the emoji sent anyone replacing
    // the artwork to the wrong file.
    '🪀': 'piko',
    '🏃': 'taguan',
    '🧩': 'puzzle',
    '🎯': 'tumbang_preso',
    '🎮': 'laro',
    '🎁': 'regalo',
    '🎉': 'salubong',
    '📚': 'aklat',
    '📖': 'bukas_aklat',

    // Feelings, sky and garden
    '😴': 'tulog',
    '😢': 'iyak',
    '👊': 'kamao',
    '☀': 'araw',
    '🌅': 'bukang_liwayway',
    '🌙': 'buwan',
    '🌈': 'bahaghari',
    '⚡': 'kidlat',
    '🌿': 'dahon',
    '🌷': 'bulaklak_tulip',
  };

  /// The names to give the files, for anyone adding artwork.
  static List<String> get expectedFileNames =>
      _fileNames.values.toSet().toList()..sort();

  /// How much of its box an emoji's drawing actually fills.
  ///
  /// An emoji is text, and text carries leading — the line box is taller than
  /// the picture inside it, so a `FittedBox` that fits the line box leaves the
  /// apple itself smaller than the space given. A PNG has no leading and fills
  /// the box completely, which made every picture come out noticeably larger
  /// than the emoji it replaced, and a board with one picture among emoji look
  /// mismatched.
  ///
  /// Measured from a real emoji rather than guessed, so it stays right on
  /// whatever font the phone happens to use. Measured once and kept.
  static double? _fill;

  static double get _emojiFill {
    if (_fill != null) return _fill!;

    const probe = 100.0;
    final painter = TextPainter(
      text: const TextSpan(text: '🍎', style: TextStyle(fontSize: probe)),
      textDirection: TextDirection.ltr,
    )..layout();

    // A FittedBox scales the whole line box down to fit, so the drawing ends
    // up at `fontSize / the larger side of that box`. Both sides matter: some
    // emoji fonts give a glyph more advance width than line height, and
    // dividing by height alone would then correct the wrong way.
    final largest =
        painter.width > painter.height ? painter.width : painter.height;
    _fill = largest <= 0 ? 1.0 : (probe / largest).clamp(0.5, 1.0);
    return _fill!;
  }

  @override
  Widget build(BuildContext context) {
    // A plain shape is drawn, not fetched. There is nothing to illustrate
    // about a square, and as an emoji it was the one thing in the app whose
    // appearance changed with the phone — which matters most in the memory
    // game, where the child's task is to match two of them exactly.
    final drawn = ShapeGlyph.forEmoji(emoji, size: size * _emojiFill);
    if (drawn != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: drawn),
      );
    }

    final path = assetFor(emoji);

    if (path != null) {
      // Drawn into the same square the emoji's picture occupied, so swapping
      // one in changes what a child sees and not how big it is.
      final side = size * _emojiFill;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Image.asset(
            path,
            width: side,
            height: side,
            fit: BoxFit.contain,
            // A missing or misnamed file falls back to the emoji rather than
            // to a broken-image box. A three-year-old counting objects must
            // never be shown a grey square where a thing should be.
            // png, then jpg, then the emoji. Each step only happens when
            // the one before it is genuinely missing, so a child never sees
            // the grey broken-image box while artwork is being swapped in.
            errorBuilder: (_, __, ___) {
              final jpg = _alternateFor(emoji);
              if (jpg == null) return _emoji();
              return Image.asset(
                jpg,
                width: side,
                height: side,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _emoji(),
              );
            },
          ),
        ),
      );
    }
    return _emoji();
  }

  Widget _emoji() {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(emoji, style: const TextStyle(fontSize: 44)),
      ),
    );
  }
}
