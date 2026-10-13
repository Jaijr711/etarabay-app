import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'object_picture.dart';

/// The house in My Home: an illustrated cut-away house whose rooms are tapped.
///
/// It was drawn in code before — a roof, coloured boxes and a strip of grass —
/// and the rooms still had to be read to be told apart. The picture shows each
/// room furnished (a bed under the stars, a stove and fridge, a sofa, a bath
/// with a duck), so a child who cannot read yet still knows which is which.
///
/// Each room is tappable over its card and its door; the yard over the bush.
/// The picture's own labels are English, so in Filipino and Ilokano the room
/// names from the data are laid over them.
class HomeHouse extends StatelessWidget {
  /// The rooms in the data's order: living room, kitchen, bedroom,
  /// bathroom, and the yard last. Each has a name, an emoji and a colour.
  final List<Map<String, dynamic>> rooms;

  /// The item emoji already put in each room, by room index.
  final Map<int, List<String>> placed;

  final ValueChanged<int> onRoomTap;

  /// Whether to cover the picture's English labels with [rooms]' names.
  final bool ownLabels;

  const HomeHouse({
    super.key,
    required this.rooms,
    required this.placed,
    required this.onRoomTap,
    this.ownLabels = false,
  });

  static const asset = 'assets/images/home_house.webp';
  static const _aspect = 900 / 1241;

  /// Where each room's card is in the picture, as fractions of its width and
  /// height, in the data's room order. Measured on the picture itself.
  static const _cards = [
    Rect.fromLTRB(0.098, 0.514, 0.484, 0.788), // living room, bottom left
    Rect.fromLTRB(0.508, 0.216, 0.898, 0.493), // kitchen, top right
    Rect.fromLTRB(0.098, 0.216, 0.484, 0.493), // bedroom, top left
    Rect.fromLTRB(0.508, 0.514, 0.898, 0.788), // bathroom, bottom right
    Rect.fromLTRB(0.317, 0.820, 0.678, 0.998), // yard, the bush
  ];

  /// The word "Yard" on the bush.
  static const _yardLabel = Rect.fromLTRB(0.43, 0.922, 0.56, 0.978);

  static const _labelPaper = Color(0xFFFFF0DA);
  static const _labelInk = Color(0xFF6B2A1A);

  /// The card widened to take in its door, so a tap on the door counts.
  static Rect _tapArea(int i) {
    final c = _cards[i];
    if (i == 4) return c;
    return c.left < 0.3
        ? Rect.fromLTRB(0.015, c.top, c.right, c.bottom)
        : Rect.fromLTRB(c.left, c.top, 0.985, c.bottom);
  }

  /// The strip along the bottom of a room's card where its name is written.
  static Rect _labelArea(int i) {
    if (i == 4) return _yardLabel;
    final c = _cards[i];
    return Rect.fromLTRB(
      c.left + c.width * 0.04,
      c.top + c.height * 0.835,
      c.right - c.width * 0.04,
      c.bottom - c.height * 0.025,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = rooms.length < _cards.length ? rooms.length : _cards.length;

    return Center(
      child: AspectRatio(
        aspectRatio: _aspect,
        child: LayoutBuilder(builder: (_, box) {
          final size = box.biggest;
          Rect scaled(Rect r) => Rect.fromLTRB(
              r.left * size.width,
              r.top * size.height,
              r.right * size.width,
              r.bottom * size.height);

          return Stack(children: [
            Positioned.fill(
              child: Image.asset(asset,
                  fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
            if (ownLabels)
              for (int i = 0; i < count; i++)
                Positioned.fromRect(
                  rect: scaled(_labelArea(i)),
                  child: _label(i, scaled(_labelArea(i)).height),
                ),
            for (int i = 0; i < count; i++)
              if ((placed[i] ?? const []).isNotEmpty) ...[
                Positioned.fromRect(
                  rect: scaled(_cards[i]),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            size.width * (i == 4 ? 0.06 : 0.035)),
                        border: Border.all(color: Colors.green, width: 4),
                      ),
                    ),
                  ),
                ),
                // Bottom right, just above the name: the room's round icon
                // sits at the top and the badge must not cover it.
                Positioned(
                  left: scaled(_cards[i]).right - 6,
                  top: scaled(_labelArea(i)).top - 3,
                  child: FractionalTranslation(
                    translation: const Offset(-1, -1),
                    child: _placedBadge(placed[i]!),
                  ),
                ),
              ],
            // The tap areas last, over everything else.
            for (int i = 0; i < count; i++)
              Positioned.fromRect(
                rect: scaled(_tapArea(i)),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onRoomTap(i),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  /// A room's name in the chosen language, over the picture's English one.
  Widget _label(int i, double height) {
    final yard = i == 4;
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: height * 0.2),
      decoration: BoxDecoration(
        color: yard ? const Color(0xFF5FAE2E) : _labelPaper,
        borderRadius: BorderRadius.circular(height * 0.3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          rooms[i]['name'] as String,
          maxLines: 1,
          style: TextStyle(
            fontSize: height * 0.62,
            fontWeight: FontWeight.w900,
            color: yard ? const Color(0xFFFFF6C8) : _labelInk,
          ),
        ),
      ),
    );
  }

  /// What has been put in a room, with a tick.
  Widget _placedBadge(List<String> items) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.check, size: 14, color: Colors.green),
          const SizedBox(width: 2),
          for (final e in items) ObjectPicture(emoji: e, size: 18),
        ]),
      );
}
