import 'package:e_tarabay/data/pamilya_content.dart';
import 'package:e_tarabay/widgets/family_tree_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each person in the family tree picture answers for the person drawn
/// there.
///
/// The picture puts the siblings at the top and the grandparents at the
/// bottom, the reverse of the data's order, so a mix-up in the measured
/// spots would tell a child the baby is their grandfather.
void main() {
  // A point on each portrait, in the picture's own pixels (900 x 1574), and
  // the relation the data gives that person in English.
  const people = <(Offset, String)>[
    (Offset(125, 232), 'Older Brother'),
    (Offset(450, 232), 'Older Sister'),
    (Offset(790, 232), 'Youngest Sibling'),
    (Offset(233, 625), 'Father'),
    (Offset(658, 625), 'Mother'),
    (Offset(160, 1020), 'Grandfather (father of father)'),
    (Offset(365, 1020), 'Grandmother (mother of father)'),
    (Offset(572, 1020), 'Grandfather (father of mother)'),
    (Offset(782, 1020), 'Grandmother (mother of mother)'),
    // A name, not just a face, counts too.
    (Offset(780, 400), 'Youngest Sibling'),
  ];

  Future<(List<String>, Rect)> pump(WidgetTester tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          height: 525,
          child: FamilyTreePicture(
            generations:
                PamilyaContent.getFamilyTreeData('en')['generations'] as List,
            onMemberTap: (m) => tapped.add(m['relation'] as String),
          ),
        ),
      ),
    ));
    return (tapped, tester.getRect(find.byType(AspectRatio)));
  }

  Offset at(Rect box, Offset px) =>
      box.topLeft + Offset(px.dx / 900 * box.width, px.dy / 1574 * box.height);

  testWidgets('every person answers for themselves', (tester) async {
    final (tapped, box) = await pump(tester);
    for (final (point, relation) in people) {
      tapped.clear();
      await tester.tapAt(at(box, point));
      await tester.pump();
      expect(tapped, [relation], reason: relation);
    }
  });

  testWidgets('the heart and the trunk answer for nobody', (tester) async {
    final (tapped, box) = await pump(tester);
    for (final point in const [Offset(450, 625), Offset(450, 1400)]) {
      await tester.tapAt(at(box, point));
      await tester.pump();
    }
    expect(tapped, isEmpty);
  });
}
