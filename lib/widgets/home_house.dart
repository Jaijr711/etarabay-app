import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'object_picture.dart';

/// The house, the way a child draws one: a roof, two floors and a lawn.
///
/// The rooms used to be four plain white cards in a box with a small green
/// card under it for the yard. Every room looked the same until a child
/// read its caption, and the yard looked like a button rather than a place.
///
/// Now it is a dollhouse seen from the front. Bedroom and bathroom are
/// upstairs, living room and kitchen downstairs, each with its own wall and
/// floor colour and a large picture of what is in it. The yard is the grass
/// the house stands on, full width, with a tree and flowers.
class HomeHouse extends StatelessWidget {
  /// The rooms in the data's order: living room, kitchen, bedroom,
  /// bathroom, and the yard last. Each has a name, an emoji and a colour.
  final List<Map<String, dynamic>> rooms;

  /// The item emoji already put in each room, by room index.
  final Map<int, List<String>> placed;

  final ValueChanged<int> onRoomTap;

  const HomeHouse({
    super.key,
    required this.rooms,
    required this.placed,
    required this.onRoomTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.length < 4) return const SizedBox.shrink();
    final hasYard = rooms.length > 4;

    // Room order in the data: living room, kitchen, bedroom, bathroom, yard.
    Widget floor(int left, int right) => Expanded(
          child: Row(children: [
            Expanded(child: _roomCell(left)),
            const SizedBox(width: 4),
            Expanded(child: _roomCell(right)),
          ]),
        );

    return LayoutBuilder(builder: (_, box) {
      final roofH = box.maxHeight * 0.14;
      final yardH = hasYard ? box.maxHeight * 0.20 : 0.0;
      final wallsH =
          (box.maxHeight - roofH - yardH).clamp(0.0, double.infinity);
      // The roof overhangs the walls a little, as roofs do.
      final eave = box.maxWidth * 0.045;

      return Column(children: [
        SizedBox(
          height: roofH,
          width: double.infinity,
          child: CustomPaint(painter: _RoofPainter()),
        ),
        SizedBox(
          height: wallsH,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: eave),
            child: Container(
              padding: const EdgeInsets.all(4),
              color: _HouseColors.frame,
              child: Column(children: [
                floor(2, 3), // upstairs: bedroom, bathroom
                // The floor between the two storeys.
                const SizedBox(height: 6),
                floor(0, 1), // downstairs: living room, kitchen
              ]),
            ),
          ),
        ),
        if (hasYard)
          SizedBox(
            height: yardH,
            width: double.infinity,
            child: _yardCell(4),
          ),
      ]);
    });
  }

  /// The room's name on a white label, readable on any wall colour.
  Widget _roomLabel(String name, Color color, double fontSize) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name,
              maxLines: 1,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
      );

  /// What has been put in a room, with a tick, in its top corner.
  Widget _placedBadge(List<String> placed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.check, size: 13, color: Colors.green),
          const SizedBox(width: 2),
          for (final e in placed) ObjectPicture(emoji: e, size: 16),
        ]),
      );

  /// One room inside the house. Tapping it is the answer.
  Widget _roomCell(int i) {
    final room = rooms[i];
    final roomColor = room['color'] as Color;
    final look = _HouseColors.rooms[i % _HouseColors.rooms.length];
    final placed = this.placed[i] ?? const <String>[];
    final filled = placed.isNotEmpty;

    return GestureDetector(
      onTap: () => onRoomTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: look.wall,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? Colors.green : look.wall,
            width: filled ? 3 : 0,
          ),
        ),
        child: LayoutBuilder(builder: (_, c) {
          final picture = (c.maxWidth * 0.48)
              .clamp(0.0, c.maxHeight * 0.46)
              .clamp(20.0, 96.0);
          return Stack(children: [
            // The floor: wood, tiles or carpet, so the room has a bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: c.maxHeight * 0.17,
              child: ColoredBox(color: look.floor),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ObjectPicture(
                        emoji: room['emoji'] as String, size: picture),
                    SizedBox(height: c.maxHeight * 0.04),
                    _roomLabel(room['name'] as String, roomColor,
                        (c.maxHeight * 0.11).clamp(11.0, 16.0)),
                  ],
                ),
              ),
            ),
            if (filled)
              Positioned(top: 4, right: 4, child: _placedBadge(placed)),
          ]);
        }),
      ),
    );
  }

  /// The yard: the lawn the house stands on, with a tree and flowers.
  Widget _yardCell(int i) {
    final room = rooms[i];
    final roomColor = room['color'] as Color;
    final placed = this.placed[i] ?? const <String>[];
    final filled = placed.isNotEmpty;

    return GestureDetector(
      onTap: () => onRoomTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_HouseColors.grassLight, _HouseColors.grass],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
          border: Border.all(
            color: filled ? Colors.green.shade800 : Colors.transparent,
            width: 3,
          ),
        ),
        child: LayoutBuilder(builder: (_, c) {
          final plant = (c.maxHeight * 0.62).clamp(20.0, 80.0);
          return Stack(children: [
            Positioned(
              left: c.maxWidth * 0.04,
              bottom: c.maxHeight * 0.08,
              child: ObjectPicture(emoji: '🌳', size: plant),
            ),
            Positioned(
              right: c.maxWidth * 0.04,
              bottom: c.maxHeight * 0.1,
              child: Row(children: [
                ObjectPicture(emoji: '🌷', size: plant * 0.55),
                ObjectPicture(emoji: '🌼', size: plant * 0.5),
                ObjectPicture(emoji: '🌷', size: plant * 0.55),
              ]),
            ),
            Center(
              child: _roomLabel(room['name'] as String, roomColor,
                  (c.maxHeight * 0.2).clamp(12.0, 17.0)),
            ),
            if (filled)
              Positioned(top: 4, right: 4, child: _placedBadge(placed)),
          ]);
        }),
      ),
    );
  }
}

/// The house's paint: the frame, each room's wall and floor, the grass.
class _HouseColors {
  static const frame = Color(0xFFB4835A);
  static const grass = Color(0xFF6CC24A);
  static const grassLight = Color(0xFFA8E07E);

  /// In the data's room order: living room, kitchen, bedroom, bathroom.
  static const rooms = [
    (wall: Color(0xFFFFF0C2), floor: Color(0xFFD9A066)), // wood
    (wall: Color(0xFFFFE1CC), floor: Color(0xFFE9C29A)), // tiles
    (wall: Color(0xFFDDEBFF), floor: Color(0xFFAFCBF2)), // carpet
    (wall: Color(0xFFD6F5EE), floor: Color(0xFF9EDCCD)), // bath tiles
  ];
}

/// The roof of "Aming Tahanan", with a chimney.
class _RoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chimney first, so the roof slope covers where it meets the tiles.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.72, h * 0.18, w * 0.075, h * 0.7),
      Paint()..color = const Color(0xFF9E6B4A),
    );

    final roof = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFE07A5F));

    // A couple of tile lines, so the roof is not a flat triangle.
    final tile = Paint()
      ..color = const Color(0xFFC96248)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final t in [0.45, 0.72]) {
      canvas.drawLine(
        Offset(w * 0.5 - (w * 0.5) * t, h * t),
        Offset(w * 0.5 + (w * 0.5) * t, h * t),
        tile,
      );
    }
  }

  @override
  bool shouldRepaint(_RoofPainter oldDelegate) => false;
}
