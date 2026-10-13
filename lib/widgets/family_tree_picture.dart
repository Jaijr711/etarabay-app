import 'package:flutter/material.dart';

/// The family tree board: an illustrated tree whose family members are tapped.
///
/// It was a tree painted in code with emoji faces standing on it. The picture
/// draws each person — the grandparents waving, a father holding a baby — on
/// branches that show who belongs to whom, so the tree explains itself.
///
/// Its own labels are English, so in Filipino and Ilokano the short names
/// from the data ("Lolo", "Tatay", "Kuya") are laid over them. The last
/// member tapped gets a ring, so a child can see who the tip is about.
class FamilyTreePicture extends StatefulWidget {
  /// The data's generations, in its order: grandparents (four), parents
  /// (two), siblings (three). Each has a colour and a list of members, and
  /// each member a 'relation' such as "Lolo (ama ni Tatay)".
  final List generations;

  final ValueChanged<Map<String, dynamic>> onMemberTap;

  /// Whether to cover the picture's English labels with the data's names.
  final bool ownLabels;

  const FamilyTreePicture({
    super.key,
    required this.generations,
    required this.onMemberTap,
    this.ownLabels = false,
  });

  static const asset = 'assets/images/family_tree.webp';

  @override
  State<FamilyTreePicture> createState() => _FamilyTreePictureState();
}

/// Where one person is in the picture, in its own pixels (900 x 1574).
class _Spot {
  final Rect tap; // face and name together
  final Offset face; // centre of the round portrait
  final double radius;
  final Rect label; // the written name under it
  const _Spot(this.tap, this.face, this.radius, this.label);
}

class _FamilyTreePictureState extends State<FamilyTreePicture> {
  static const _w = 900.0;
  static const _h = 1574.0;

  /// In the data's order: the four grandparents (father's side first), the
  /// two parents, the three siblings. Measured on the picture itself.
  static const _spots = <_Spot>[
    // Grandparents, along the bottom branch.
    _Spot(Rect.fromLTRB(52, 925, 258, 1172), Offset(160, 1020), 88,
        Rect.fromLTRB(52, 1128, 248, 1170)),
    _Spot(Rect.fromLTRB(262, 925, 470, 1172), Offset(365, 1020), 88,
        Rect.fromLTRB(258, 1128, 470, 1170)),
    _Spot(Rect.fromLTRB(474, 925, 678, 1172), Offset(572, 1020), 88,
        Rect.fromLTRB(478, 1128, 672, 1170)),
    _Spot(Rect.fromLTRB(682, 925, 898, 1172), Offset(782, 1020), 88,
        Rect.fromLTRB(682, 1128, 898, 1170)),
    // Parents, in the middle.
    _Spot(Rect.fromLTRB(135, 530, 332, 778), Offset(233, 625), 92,
        Rect.fromLTRB(175, 730, 292, 772)),
    _Spot(Rect.fromLTRB(560, 530, 757, 778), Offset(658, 625), 92,
        Rect.fromLTRB(597, 730, 720, 772)),
    // Siblings, at the top.
    _Spot(Rect.fromLTRB(15, 140, 238, 420), Offset(125, 232), 90,
        Rect.fromLTRB(15, 336, 240, 380)),
    _Spot(Rect.fromLTRB(345, 140, 555, 420), Offset(450, 232), 90,
        Rect.fromLTRB(352, 336, 550, 380)),
    _Spot(Rect.fromLTRB(688, 140, 892, 420), Offset(790, 232), 90,
        Rect.fromLTRB(705, 336, 866, 420)),
  ];

  int? _selected;

  @override
  Widget build(BuildContext context) {
    // Flattened to match [_spots]: each member with its generation's colour.
    final people = <(Map<String, dynamic>, Color)>[
      for (final g in widget.generations)
        for (final m in (g['members'] as List))
          (m as Map<String, dynamic>, g['color'] as Color),
    ];
    final count = people.length < _spots.length ? people.length : _spots.length;

    return Center(
      child: AspectRatio(
        aspectRatio: _w / _h,
        child: LayoutBuilder(builder: (_, box) {
          final sx = box.maxWidth / _w;
          final sy = box.maxHeight / _h;
          Rect scaled(Rect r) => Rect.fromLTRB(
              r.left * sx, r.top * sy, r.right * sx, r.bottom * sy);

          return Stack(children: [
            Positioned.fill(
              child: Image.asset(FamilyTreePicture.asset,
                  fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
            if (widget.ownLabels)
              for (int i = 0; i < count; i++)
                Positioned.fromRect(
                  rect: scaled(_spots[i].label),
                  // One text size for every name, from a one-line label's
                  // height: the youngest's label covers two lines.
                  child: _label(people[i].$1, people[i].$2, 44 * sy),
                ),
            if (_selected != null && _selected! < count)
              _ring(_spots[_selected!], sx),
            for (int i = 0; i < count; i++)
              Positioned.fromRect(
                rect: scaled(_spots[i].tap),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _selected = i);
                    widget.onMemberTap(people[i].$1);
                  },
                ),
              ),
          ]);
        }),
      ),
    );
  }

  /// A glowing ring around the portrait of the person last tapped. The
  /// picture keeps its shape, so one scale serves both directions.
  Widget _ring(_Spot spot, double scale) {
    // Two rings and no fill: a shadow, even an "outer" one, filled the
    // circle and tinted the face yellow.
    const gold = Color(0xFFFFD54F);
    final r = spot.radius * scale + 10;
    return Positioned(
      left: spot.face.dx * scale - r,
      top: spot.face.dy * scale - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold.withOpacity(0.45), width: 6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A member's short name ("Lolo (ama ni Tatay)" → "Lolo") over the
  /// picture's English one, in their generation's colour.
  Widget _label(Map<String, dynamic> member, Color color, double lineHeight) {
    final name = (member['relation'] as String).split('(').first.trim();
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: lineHeight * 0.15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(lineHeight * 0.5),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          name,
          maxLines: 1,
          style: TextStyle(
            fontSize: lineHeight * 0.66,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
