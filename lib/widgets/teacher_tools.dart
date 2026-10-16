import 'dart:convert';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
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

  const TeacherTools({
    super.key,
    required this.studentName,
    required this.studentData,
  });

  Future<void> _showResetSpecificActivityDialog(BuildContext context) async {
    final targetStudentId = (studentData['id'] ??
            studentData['studentId'] ??
            studentData['docId'] ??
            '')
        .toString();

    // Named the way the rest of the app names each module, in the
    // teacher's own language — these were Tagalog whatever was chosen.
    final l10n = AppLocalizations.of(context)!;
    final activities = [
      {
        'key': 'matematika',
        'label': l10n.matematika,
        'icon': LucideIcons.calculator,
        'color': Colors.blue
      },
      {
        'key': 'pamilya',
        'label': l10n.sariliProgress,
        'icon': LucideIcons.users,
        'color': Colors.purple
      },
      {
        'key': 'traceit',
        'label': l10n.traceItTitle,
        'icon': LucideIcons.pencil,
        'color': Colors.teal
      },
      {
        'key': 'magbasa',
        'label': l10n.magbasaTitle,
        'icon': LucideIcons.book_open,
        'color': Colors.indigo
      },
      {
        'key': 'tandaan',
        'label': l10n.tandaanTitle,
        'icon': LucideIcons.brain,
        'color': Colors.amber.shade800
      },
      {
        'key': 'kulay',
        'label': l10n.kulaySaya,
        'icon': LucideIcons.palette,
        'color': Colors.pink
      },
    ];

    final selected = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(LucideIcons.list_restart,
                      color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        AppLocalizations.of(context)!.resetSpecificActivity,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .pickActivitiesToReset(studentName),
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: activities.map((act) {
                            final key = act['key'] as String;
                            final isChecked = selected.contains(key);
                            final color = act['color'] as Color;
                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: color,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              secondary:
                                  Icon(act['icon'] as IconData, color: color),
                              title: Text(
                                act['label'] as String,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selected.add(key);
                                  } else {
                                    selected.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final auth = AuthService();
                          final success =
                              await auth.resetStudentSpecificActivities(
                                  targetStudentId, selected.toList());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? l10n.resetActivitiesDone
                                    : l10n.resetActivitiesFailed),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                            if (success) {
                              try {
                                final userProvider = Provider.of<UserProvider>(
                                    context,
                                    listen: false);
                                if (userProvider.currentStudentId ==
                                    targetStudentId) {
                                  await userProvider.resetAllProgressLocally();
                                }
                              } catch (_) {}
                            }
                          }
                        },
                  child: Text(AppLocalizations.of(context)!
                      .resetCount(selected.length)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmResetActivity(BuildContext context) async {
    final targetStudentId = (studentData['id'] ??
            studentData['studentId'] ??
            studentData['docId'] ??
            '')
        .toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.rotate_ccw, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(AppLocalizations.of(context)!.resetAllActivities,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.confirmResetAll(studentName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.resetAll),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final auth = AuthService();
      final success = await auth.resetStudentActivityProgress(targetStudentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Activity progress reset successfully.'
                : 'Failed to reset progress.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          try {
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            if (userProvider.currentStudentId == targetStudentId) {
              await userProvider.resetAllProgressLocally();
            }
          } catch (_) {}
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List creations = studentData['creations'] is List
        ? studentData['creations'] as List
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildArtworksGallery(context, creations),
        const SizedBox(height: 32),

        // Reset Activity Buttons
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            icon: const Icon(LucideIcons.list_restart, size: 20),
            label: Text(
              AppLocalizations.of(context)!.resetSpecificActivity,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showResetSpecificActivityDialog(context),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(LucideIcons.rotate_ccw, size: 18),
            label: Text(
              AppLocalizations.of(context)!.resetAllActivities,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _confirmResetActivity(context),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
      'assets/images/paint9.png': l10n.pageSodaPop,
    };
    return byPage[page] ?? '${creation['name'] ?? 'Artwork'}';
  }

  Widget _buildArtworksGallery(BuildContext context, List creations) {
    if (creations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.image_off, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noArtworksSaved,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: creations.length,
        itemBuilder: (context, index) {
          final creation =
              creations[index] is Map ? creations[index] as Map : {};
          final name = _artworkName(context, creation);
          final base64Img = creation['base64Image'] as String? ?? '';
          final stars = creation['stars'] as int?;

          Widget imageWidget;
          if (base64Img.isNotEmpty) {
            try {
              final bytes = base64Decode(base64Img);
              imageWidget = Image.memory(bytes, fit: BoxFit.cover);
            } catch (_) {
              imageWidget = Container(
                color: Colors.grey.shade200,
                child: const Icon(LucideIcons.image, color: Colors.grey),
              );
            }
          } else {
            imageWidget = Container(
              color: Colors.grey.shade200,
              child: const Icon(LucideIcons.palette, color: AppColors.colors),
            );
          }

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showArtworkPreview(context, name, base64Img, stars),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: imageWidget,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (stars != null && stars > 0)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFB800), size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '$stars Stars',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

    final rows = <({String label, int weight})>[];
    if (raw is Map) {
      for (final module in raw.entries) {
        final items = module.value;
        if (items is! Map) continue;
        for (final item in items.entries) {
          final label =
              _skillName(context, module.key.toString(), item.key.toString());
          if (label == null) continue;
          rows.add((
            label: label,
            weight: (item.value as num?)?.toInt() ?? 0,
          ));
        }
      }
    }
    rows.sort((a, b) => b.weight.compareTo(a.weight));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.life_buoy, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(loc.whatToPractise,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ]),
        const SizedBox(height: 12),
        // Nothing on the list is the good outcome, so it is said rather than
        // left as a gap the teacher has to interpret.
        if (rows.isEmpty)
          Text(loc.nothingToPractise,
              style: TextStyle(
                  fontSize: 13, height: 1.35, color: Colors.grey.shade600))
        else
          for (final row in rows.take(6)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                  child: Text(row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                // Five dots, filled as far as the child is from settling it.
                for (var i = 0; i < 5; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < row.weight
                          ? const Color(0xFFC2334D)
                          : Colors.grey.shade200,
                    ),
                  ),
              ]),
            ),
          ],
      ]),
    );
  }

  /// Turns a stored `module` + `levelN` into the name the child saw.
  ///
  /// Returns null for anything unrecognised — a level removed from a module
  /// later should quietly disappear from the teacher's list, not show up as
  /// a raw key.
  String? _skillName(BuildContext context, String module, String item) {
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
      'sarili' => loc.angAkingSarili,
      _ => loc.atAkingPamilya,
    };
    return '${names[index]} · $moduleName';
  }
}
