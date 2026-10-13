import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/widgets/home_house.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each room of the My Home picture answers for the room drawn there.
///
/// The tap areas are fractions measured on the picture, and the picture's
/// rooms are not in the data's order (the bedroom is drawn top left but is
/// the third room in the data), so a mix-up here would mark a right answer
/// wrong without anything looking broken.
void main() {
  // A point in the picture, as fractions of its width and height.
  const points = <String, (Offset, int)>{
    'bedroom': (Offset(0.29, 0.35), 2),
    'bedroom door': (Offset(0.05, 0.36), 2),
    'kitchen': (Offset(0.70, 0.35), 1),
    'kitchen door': (Offset(0.95, 0.36), 1),
    'living room': (Offset(0.29, 0.65), 0),
    'living room door': (Offset(0.05, 0.66), 0),
    'bathroom': (Offset(0.70, 0.65), 3),
    'bathroom door': (Offset(0.95, 0.66), 3),
    'yard': (Offset(0.50, 0.90), 4),
  };

  testWidgets('every room answers for itself', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          height: 414, // the picture's own shape, so it fills the box
          child: HomeHouse(
            rooms: PamilyaContent.getHomeRooms('en'),
            placed: const {},
            onRoomTap: tapped.add,
          ),
        ),
      ),
    ));

    final box = tester.getRect(find.byType(AspectRatio));
    for (final entry in points.entries) {
      tapped.clear();
      final (at, room) = entry.value;
      await tester
          .tapAt(box.topLeft + Offset(at.dx * box.width, at.dy * box.height));
      expect(tapped, [room], reason: entry.key);
    }
  });

  testWidgets('the roof and the gaps answer for nothing', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          height: 414,
          child: HomeHouse(
            rooms: PamilyaContent.getHomeRooms('en'),
            placed: const {},
            onRoomTap: tapped.add,
          ),
        ),
      ),
    ));
    final box = tester.getRect(find.byType(AspectRatio));
    for (final at in const [Offset(0.5, 0.1), Offset(0.15, 0.9)]) {
      await tester
          .tapAt(box.topLeft + Offset(at.dx * box.width, at.dy * box.height));
    }
    expect(tapped, isEmpty);
  });
}
