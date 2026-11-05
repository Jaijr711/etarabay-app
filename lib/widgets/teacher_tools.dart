import 'dart:convert';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'report_widgets.dart';
import 'reset_progress_sheet.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// What a teacher can do about a child that a parent cannot.
///
/// Sits at the foot of the parent's own report, so a teacher opening a child
/// reads exactly the page the parent reads and then finds their own tools
/// under it — rather than a second, separate summary free to disagree with
/// the first.
class TeacherTools extends StatelessWidget {
  final String studentName;
  final Map<String, dynamic> studentData;

  /// Opens the child's info, from the dashboard that owns it.
  final VoidCallback? onEditInfo;

  /// Opens the child's login card.
  final VoidCallback? onShowLogin;

  const TeacherTools({
    super.key,
    required this.studentName,
    required this.studentData,
    this.onEditInfo,
    this.onShowLogin,
  });

  String get _studentId => (studentData['id'] ??
          studentData['studentId'] ??
          studentData['docId'] ??
          '')
      .toString();

  Future<void> _reset(BuildContext context) async {
    final done = await showResetProgressSheet(
      context,
      studentId: _studentId,
      studentName: studentName,
    );
    // Back to the class, where the child's card shows the fresh figures;
    // this page was drawn from the record before the reset.
    if (done && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final List oldCreations = studentData['creations'] is List
        ? studentData['creations'] as List
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fetched when the teacher opens this child, not carried in the
        // live class list, where every child's drawings came down again
        // with every answer they gave.
        FutureBuilder<List>(
          future: _cloudCreations(_studentId, oldCreations),
          builder: (context, snap) =>
              _buildArtworksGallery(context, snap.data ?? oldCreations),
        ),
        const SizedBox(height: 22),
        ReportSectionHeader(
          title: loc.teacherToolsHeader,
          icon: LucideIcons.wrench,
        ),
        const SizedBox(height: 10),
        if (onEditInfo != null)
          _tool(
            icon: LucideIcons.square_pen,
            title: loc.toolEditInfo,
            note: loc.toolEditInfoNote,
            onTap: onEditInfo!,
          ),
        if (onShowLogin != null)
          _tool(
            icon: LucideIcons.id_card,
            title: loc.toolLogin,
            note: loc.toolLoginNote,
            onTap: onShowLogin!,
          ),
        _tool(
          icon: LucideIcons.rotate_ccw,
          title: loc.toolReset,
          note: loc.toolResetNote,
          danger: true,
          onTap: () => _reset(context),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _tool({
    required IconData icon,
    required String title,
    required String note,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    const red = Color(0xFFC2334D);
    final colour = danger ? red : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE6E8EF)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: danger
                        ? const Color(0xFFFDE8EC)
                        : const Color(0xFFEEEDFD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: colour),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: danger ? red : AppColors.textDark,
                        ),
                      ),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevron_right,
                    size: 18, color: Color(0xFFB8BECB)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// An artwork's title in the teacher's language, from the page it was
  /// colored on. The name saved with it is in whatever language the child
  /// had on at the time.
  String _artworkName(BuildContext context, Map creation) {
    final l10n = AppLocalizations.of(context)!;
    final page = '${creation['sourcePagePath'] ?? ''}';
    final byPage = <String, String>{
      'assets/images/paint1.png': l10n.pagePuppy,
      'assets/images/paint2.png': l10n.pageKuting,
      'assets/images/paint3.png': l10n.pageElepante,
      'assets/images/paint_elephant.webp': l10n.pageElepante,
      'assets/images/paint4.png': l10n.pageFlowerBasket,
      'assets/images/paint_daisy.webp': l10n.pageFlowerBasket,
      'assets/images/paint5.png': l10n.pageRose,
      'assets/images/paint6.png': l10n.pageMansanas,
      'assets/images/paint7.png': l10n.pageSaging,
      'assets/images/paint8.png': l10n.pageTeddyBear,
      'assets/images/paint_racecar.png': l10n.pageRaceCar,
    };
    return byPage[page] ?? '${creation['name'] ?? 'Artwork'}';
  }

  Future<List> _cloudCreations(String studentId, List fallback) async {
    if (studentId.isEmpty) return fallback;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .collection('extra')
          .doc('creations')
          .get();
      final list = doc.data()?['list'];
      return list is List ? list : fallback;
    } catch (_) {
      return fallback;
    }
  }

  Widget _buildArtworksGallery(BuildContext context, List creations) {
    final loc = AppLocalizations.of(context)!;
    final header = ReportSectionHeader(
      title: loc.childWorksHeader,
      icon: LucideIcons.image,
      count: creations.isEmpty ? null : creations.length,
    );

    if (creations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: reportCardDecoration(radius: 16),
            child: Row(
              children: [
                Icon(LucideIcons.image_off,
                    color: Colors.grey.shade400, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.noArtworksSaved,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: creations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final creation =
                  creations[index] is Map ? creations[index] as Map : {};
              final name = _artworkName(context, creation);
              final base64Img = creation['base64Image'] as String? ?? '';
              final stars = (creation['stars'] as num?)?.toInt() ?? 0;

              Widget image;
              try {
                image = base64Img.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFF1F2F7),
                        child:
                            Icon(LucideIcons.palette, color: AppColors.colors),
                      )
                    : Image.memory(base64Decode(base64Img), fit: BoxFit.cover);
              } catch (_) {
                image = const ColoredBox(
                  color: Color(0xFFF1F2F7),
                  child: Icon(LucideIcons.image, color: Colors.grey),
                );
              }

              return Tooltip(
                message: name,
                child: GestureDetector(
                  onTap: () =>
                      _showArtworkPreview(context, name, base64Img, stars),
                  child: Container(
                    width: 84,
                    clipBehavior: Clip.antiAlias,
                    decoration: reportCardDecoration(radius: 14),
                    child: Column(
                      children: [
                        SizedBox(width: 84, height: 84, child: image),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: i < stars
                                      ? const Color(0xFFF5A623)
                                      : const Color(0xFFD9DCE4),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showArtworkPreview(
      BuildContext context, String name, String base64Img, int? stars) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: base64Img.isNotEmpty
                    ? Image.memory(
                        base64Decode(base64Img),
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        width: 260,
                        height: 260,
                        color: Colors.grey.shade100,
                        child: const Icon(LucideIcons.palette,
                            size: 60, color: Colors.grey),
                      ),
              ),
              if (stars != null && stars > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    stars,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB800),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The skills this child is still getting wrong, worst first.
///
/// Its own widget because it belongs directly under the summary card, where
/// a teacher is already looking, rather than below the whole module
/// breakdown with the reset controls.
class PracticeList extends StatelessWidget {
  final Map<String, dynamic> progress;

  const PracticeList({super.key, required this.progress});

  @override
  Widget build(BuildContext context) => _practiceCard(context, progress);

  /// Stored by module and index rather than by name: a record holding "Mas
  /// Marami o Mas Kaunti" stops meaning anything when the teacher reads the
  /// app in Ilocano.
  Widget _practiceCard(BuildContext context, Map<String, dynamic> progress) {
    final loc = AppLocalizations.of(context)!;
    final raw = progress['practiceMisses'];

    final rows = <({_Skill skill, int weight})>[];
    if (raw is Map) {
      for (final module in raw.entries) {
        final items = module.value;
        if (items is! Map) continue;
        for (final item in items.entries) {
          final skill =
              _skillName(context, module.key.toString(), item.key.toString());
          if (skill == null) continue;
          rows.add((
            skill: skill,
            weight: (item.value as num?)?.toInt() ?? 0,
          ));
        }
      }
    }
    rows.sort((a, b) => b.weight.compareTo(a.weight));
    final shown = rows.take(6).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionHeader(
            title: loc.whatToPractise,
            icon: LucideIcons.target,
            count: shown.isEmpty ? null : shown.length,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: reportCardDecoration(),
            child: shown.isEmpty
                // Nothing on the list is the good outcome, so it is said
                // rather than left as a gap the teacher has to interpret.
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(loc.nothingToPractise,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Colors.grey.shade600)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        _row(loc, shown[i].skill, shown[i].weight,
                            first: i == 0),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppLocalizations loc, _Skill skill, int weight,
      {required bool first}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: Color(0xFFF0F1F5))),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(color: skill.colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text(skill.module,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // How many more times it went wrong than right, lately.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8EC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              loc.practiceMisses(weight),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC2334D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Turns a stored `module` + `levelN` into the name the child saw, the
  /// module it is in, and that module's colour.
  ///
  /// Returns null for anything unrecognised — a level removed from a module
  /// later should quietly disappear from the teacher's list, not show up as
  /// a raw key.
  _Skill? _skillName(BuildContext context, String module, String item) {
    final loc = AppLocalizations.of(context)!;
    final index = int.tryParse(item.replaceFirst('level', ''));
    if (index == null) return null;

    final names = switch (module) {
      'matematika' => [
          loc.counting,
          loc.dragNumber,
          loc.lineMatch,
          loc.popBalloon,
          loc.moreOrLess,
          loc.numberPuzzle,
          loc.numberSequence,
        ],
      'sarili' => [
          loc.allAboutMe,
          loc.myEmotions,
          loc.dailyRoutines,
          loc.myPreferences,
        ],
      'pamilya' => [
          loc.familyMembers,
          loc.familyRoles,
          loc.familyActivities,
          loc.familyTree,
          loc.myHome,
        ],
      _ => const <String>[],
    };
    if (index < 0 || index >= names.length) return null;

    final moduleName = switch (module) {
      'matematika' => loc.matematika,
      'sarili' => loc.angAkingSarili.replaceAll('\n', ' '),
      _ => loc.atAkingPamilya,
    };
    final colour = module == 'matematika'
        ? const Color(0xFF2C7BE5)
        : const Color(0xFF2E9E5B);
    return (name: names[index], module: moduleName, colour: colour);
  }
}

typedef _Skill = ({String name, String module, Color colour});
