import '../widgets/teacher_tools.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import 'parent_account_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Keys used by TraceItScreen.
class _TraceItKeys {
  static String upperKey(String l) => 'traceit_upper_$l';
  static String lowerKey(String l) => 'traceit_lower_$l';
  static String numKey(String n) => 'traceit_num_$n';
}

/// Keys used by KulayScreen — must match kulay_screen.dart exactly.
class _KulayKeys {
  static String pageKey(String cat, int i) => 'kulay_page_${cat}_$i';
  static const String totalCreations = 'kulay_total_creations';
  static const String lastColored = 'kulay_last_colored';
}

/// Keys used by MagbasaScreen — must match magbasa_screen.dart exactly.
class _MagbasaKeys {
  static String activityKey(String cat, int i) => '${cat}_activity_$i';
}

class _MatematikaKeys {
  static String levelKey(int level, int game) =>
      'mat_level_${level}_game_$game';
}

// ─────────────────────────────────────────────────────────────────────────────
//  FOR PARENTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ForParentsScreen extends StatefulWidget {
  const ForParentsScreen({
    super.key,
    this.viewStudentId,
    this.viewStudentName,
    this.viewStudentData,
  });

  /// Opens the report for a child who is not signed in on this device.
  ///
  /// Used by the teacher, so they read exactly what the parent reads rather
  /// than a second report built to drift out of step with this one.
  final String? viewStudentId;
  final String? viewStudentName;

  /// The teacher's copy of the record. Its presence is what turns on the
  /// tools panel — a parent visiting has no record to hand and no business
  /// resetting anything.
  final Map<String, dynamic>? viewStudentData;

  /// Whether this is somebody looking in, rather than the parent at home.
  bool get isVisiting => viewStudentId != null;

  @override
  State<ForParentsScreen> createState() => _ForParentsScreenState();
}

class _ForParentsScreenState extends State<ForParentsScreen> {
  // ── Trace It data ─────────────────────────────────────────────────────────
  final Set<String> _traceDoneUpper = {};
  final Set<String> _traceDoneLower = {};
  final Set<String> _traceDoneNums = {};

  bool _traceUpperExpanded = false;
  bool _traceLowerExpanded = false;
  bool _traceNumsExpanded = false;

  static const List<String> _allUpper = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ];
  static const List<String> _allLower = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z'
  ];
  static const List<String> _allNums = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];

  // ── Kulay data ───────────────────────────────────────────────────────────
  // category name → completed page indices
  final Map<String, Set<int>> _kulayDone = {
    'Animals': {},
    'Flowers': {},
    'Fruits': {},
    'Toys': {},
  };
  // category name → total pages
  final Map<String, int> _kulayTotal = {
    'Animals': 3,
    'Flowers': 2,
    'Fruits': 2,
    'Toys': 2,
  };
  // category name → pages list (name, difficulty)
  static const Map<String, List<Map<String, String>>> _kulayPages = {
    'Animals': [
      {'name': 'Puppy', 'difficulty': 'Easy'},
      {'name': 'Kuting', 'difficulty': 'Easy'},
      {'name': 'Elepante', 'difficulty': 'Medium'},
    ],
    'Flowers': [
      {'name': 'Flower', 'difficulty': 'Medium'},
      {'name': 'Rose', 'difficulty': 'Hard'},
    ],
    'Fruits': [
      {'name': 'Mansanas', 'difficulty': 'Easy'},
      {'name': 'Saging', 'difficulty': 'Easy'},
    ],
    'Toys': [
      {'name': 'Teddy Bear', 'difficulty': 'Medium'},
      {'name': 'Soda', 'difficulty': 'Easy'},
    ],
  };
  static const Map<String, Color> _kulayColors = {
    'Animals': Colors.orange,
    'Flowers': Colors.pink,
    'Fruits': Colors.red,
    'Toys': Colors.brown,
  };
  static const Map<String, IconData> _kulayIcons = {
    'Animals': LucideIcons.paw_print,
    'Flowers': LucideIcons.flower,
    'Fruits': LucideIcons.apple,
    'Toys': LucideIcons.blocks,
  };

  int _kulayTotalCreations = 0;
  String _kulayLastColored = '—';

  // ── Magbasa data ─────────────────────────────────────────────────────────
  static const Map<String, int> _magbasaTotals = {
    'tula': 5,
    'kwento': 5,
    'kanta': 9,
  };
  static const Map<String, IconData> _magbasaIcons = {
    'tula': LucideIcons.book_open,
    'kwento': LucideIcons.book_marked,
    'kanta': LucideIcons.music,
  };
  static const Map<String, Color> _magbasaColors = {
    'tula': Color(0xFFFF6B6B),
    'kwento': Color(0xFFFFB347),
    'kanta': Color(0xFF26A96C),
  };
  // category → completed indices
  final Map<String, Set<int>> _magbasaDone = {
    'tula': {},
    'kwento': {},
    'kanta': {},
  };

  // ── Matematika data ──────────────────────────────────────────────────────
  /// The seven Matematika levels, in the reader's own language.
  ///
  /// These were seven Ilocano strings written out here and again in
  /// matematika_screen.dart, while a translated key for each already existed —
  /// so a Filipino parent opening this report read Ilocano level names.
  List<String> _matLevelTitles(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      loc.counting,
      loc.dragNumber,
      loc.lineMatch,
      loc.popBalloon,
      loc.moreOrLess,
      loc.numberPuzzle,
      loc.numberSequence,
    ];
  }

  static const List<int> _matLevelGameCounts = [5, 5, 3, 5, 5, 3, 5];
  // level → completed game indices
  final List<Set<int>> _matDone = List.generate(7, (_) => {});

  @override
  void initState() {
    super.initState();
    _loadAllProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.addListener(_onUserProviderChanged);
        if (widget.isVisiting) {
          // No household on a visitor's phone, and nothing here is theirs to
          // change — just the one child's record.
          _showSibling({
            'id': widget.viewStudentId!,
            'name': widget.viewStudentName ?? '',
          });
        } else {
          _loadHousehold();
        }
      }
    });
  }

  void _onUserProviderChanged() {
    if (mounted) {
      _loadAllProgress();
    }
  }

  @override
  void dispose() {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.removeListener(_onUserProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Load progress from SharedPreferences
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadAllProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Trace It
    for (final l in _allUpper) {
      if (prefs.getBool(_TraceItKeys.upperKey(l)) == true) {
        _traceDoneUpper.add(l);
      }
    }
    for (final l in _allLower) {
      if (prefs.getBool(_TraceItKeys.lowerKey(l)) == true) {
        _traceDoneLower.add(l);
      }
    }
    for (final n in _allNums) {
      if (prefs.getBool(_TraceItKeys.numKey(n)) == true) _traceDoneNums.add(n);
    }

    // Kulay
    for (final cat in _kulayDone.keys) {
      final total = _kulayTotal[cat] ?? 0;
      for (int i = 0; i < total; i++) {
        if (prefs.getBool(_KulayKeys.pageKey(cat, i)) == true) {
          _kulayDone[cat]!.add(i);
        }
      }
    }
    _kulayTotalCreations = prefs.getInt(_KulayKeys.totalCreations) ?? 0;
    _kulayLastColored = prefs.getString(_KulayKeys.lastColored) ?? '—';

    // Magbasa
    for (final cat in _magbasaDone.keys) {
      final total = _magbasaTotals[cat] ?? 0;
      for (int i = 0; i < total; i++) {
        if (prefs.getBool(_MagbasaKeys.activityKey(cat, i)) == true) {
          _magbasaDone[cat]!.add(i);
        }
      }
    }

    // Matematika
    for (int lvl = 0; lvl < _matLevelGameCounts.length; lvl++) {
      for (int g = 0; g < _matLevelGameCounts[lvl]; g++) {
        if (prefs.getBool(_MatematikaKeys.levelKey(lvl, g)) == true) {
          _matDone[lvl].add(g);
        }
      }
    }

    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Render immediately — progress loads from SharedPreferences and fills in
    // silently via setState, so there's no full-screen spinner flash when
    // transitioning to this page.
    const headerStart = Color(0xFF7C4DFF);
    const headerEnd = Color(0xFF9C6BFF);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      body: Column(
        children: [
          // Gradient header (mirrors the teacher dashboard, different color)
          Container(
            // The bottom was 0, so the title sat hard against the curve
            // with the 30-pixel corner closing in beside it.
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [headerStart, headerEnd],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x267C4DFF),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          // The same size as the cog beside it. These were
                          // 24 and 22 in equal padding, so the two glass
                          // squares did not match.
                          child: const Icon(LucideIcons.arrow_left,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // A teacher gets the child's name; the parent
                              // knows whose report they opened, and a teacher
                              // has twenty of them.
                              widget.isVisiting
                                  ? (widget.viewStudentName ?? '')
                                  : AppLocalizations.of(context)!.forParents,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.isVisiting
                                  ? AppLocalizations.of(context)!.pupilReport
                                  : AppLocalizations.of(context)!
                                      .forParentsSubtitle,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Hidden from a visitor: it edits the login of the
                      // child signed in on *this* device, which is not the
                      // child a teacher is looking at.
                      // A visiting teacher gets the space, not the button:
                      // the row keeps its shape and a long name stops short of
                      // the corner instead of running into it.
                      if (widget.isVisiting)
                        const SizedBox(width: 42)
                      else
                        GestureDetector(
                          onTap: () {
                            context.pushPremium(const ParentAccountScreen());
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(LucideIcons.user_cog,
                                color: Colors.white, size: 22),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildSummary(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  OVERVIEW TAB
  // ─────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────
  //  KULAY-SAYA TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildKulayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header summary card
        Builder(builder: (context) {
          final (earned, possible) = _moduleStars('kulay');
          return _gradedHeader(
            icon: LucideIcons.palette,
            title: AppLocalizations.of(context)!.kulaySayaProgress,
            subtitle: AppLocalizations.of(context)!.magkulayTayo,
            earned: earned,
            possible: possible,
            gradient: const [Color(0xFFEC4899), Color(0xFFF9A8D4)],
          );
        }),
        const SizedBox(height: 16),

        // Last colored
        _infoRow(LucideIcons.clock, AppLocalizations.of(context)!.recentColor,
            _kulayLastColored),
        const SizedBox(height: 16),

        // Per-category breakdown
        _sectionHeader(AppLocalizations.of(context)!.categoryProgressHeader,
            LucideIcons.grid_3x3),
        const SizedBox(height: 12),

        ..._kulayDone.keys.map((catName) {
          final catDone = _kulayDoneFor(catName);
          final done = catDone.length;
          final total = _kulayTotal[catName] ?? 0;
          final color = _kulayColors[catName] ?? Colors.grey;
          final icon = _kulayIcons[catName] ?? LucideIcons.image;
          final pages = _kulayPages[catName] ?? [];
          final progress = total > 0 ? done / total : 0.0;

          // Difficulty breakdown
          int easyDone = 0, medDone = 0, hardDone = 0;
          for (int i = 0; i < pages.length; i++) {
            if (catDone.contains(i)) {
              final d = pages[i]['difficulty'] ?? '';
              if (d == 'Easy') {
                easyDone++;
              } else if (d == 'Medium') {
                medDone++;
              } else if (d == 'Hard') {
                hardDone++;
              }
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(children: [
              // Category header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: Center(child: Icon(icon, color: color, size: 22))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_catLabel(catName),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                      minHeight: 7))),
                          const SizedBox(width: 10),
                          Text('$done/$total',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color)),
                        ]),
                      ])),
                ]),
              ),

              // Individual pages
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  ...List.generate(pages.length, (i) {
                    final isDone = catDone.contains(i);
                    final diff = pages[i]['difficulty'] ?? '';
                    final diffColor = diff == 'Easy'
                        ? Colors.green
                        : diff == 'Medium'
                            ? Colors.orange
                            : Colors.red;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDone
                            ? color.withOpacity(0.06)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDone
                                ? color.withOpacity(0.3)
                                : Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        Icon(
                            isDone
                                ? LucideIcons.circle_check
                                : LucideIcons.circle,
                            color: isDone ? color : Colors.grey.shade400,
                            size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(pages[i]['name'] ?? '',
                                style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDone ? color : Colors.grey.shade700,
                                    fontWeight: isDone
                                        ? FontWeight.w600
                                        : FontWeight.normal))),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: diffColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(_diffLabel(diff),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: diffColor,
                                    fontWeight: FontWeight.w600))),
                      ]),
                    );
                  }),

                  // Difficulty summary chips — Wrap, not Row: at 10pt bold,
                  // "Katamtaman 12" alone runs to 150px, and all three
                  // chips together can need ~390px, well past what a
                  // 320-360px phone has left after the card's own padding.
                  // A Row that wide throws a RenderFlex overflow; Wrap
                  // just carries the third chip onto its own line instead.
                  if (done > 0) ...[
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (easyDone > 0)
                        _diffChip(
                            '${_diffLabel('Easy')} $easyDone', Colors.green),
                      if (medDone > 0)
                        _diffChip(
                            '${_diffLabel('Medium')} $medDone', Colors.orange),
                      if (hardDone > 0)
                        _diffChip(
                            '${_diffLabel('Hard')} $hardDone', Colors.red),
                    ]),
                  ],
                ]),
              ),
            ]),
          );
        }),

        // My Creations section
        const SizedBox(height: 4),
        _sectionHeader(AppLocalizations.of(context)!.savedArtworksHeader,
            LucideIcons.images),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ],
          ),
          child: Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Center(
                    child:
                        Icon(LucideIcons.image, color: Colors.teal, size: 26))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(AppLocalizations.of(context)!.totalSaved,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                      '$_shownCreations ${AppLocalizations.of(context)!.artworks}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                ])),
            if (_shownCreations > 0)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(14)),
                  child: Text('${_shownCreations}x',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TRACE IT TAB
  // ─────────────────────────────────────────────────────────────────────────

  /// Characters traced, from whichever child's record is being shown.
  ///
  /// Falls back to this device's own list for a record saved before the
  /// letters were carried in the progress map.
  Set<String> _tracedFrom(String group, Set<String> local) {
    final trace = _shownProgress['traceit'];
    if (trace is Map) {
      final part = trace[group];
      if (part is Map && part['done'] is List) {
        return {for (final c in part['done'] as List) c.toString()};
      }
    }
    return _siblingProgress == null ? local : const {};
  }

  /// Which Matematika games in [lvl] are done, from whichever child's
  /// record is being shown — same reasoning as [_tracedFrom]: a teacher
  /// opening a student's report from the dashboard has no local
  /// SharedPreferences of that student's own, so [_matDone] (built from
  /// this phone's local storage in [_loadAllProgress]) is only the right
  /// answer for the signed-in child's own report.
  Set<int> _matDoneFor(int lvl) {
    final mat = _shownProgress['matematika'];
    if (mat is Map) {
      final levelGamesDone = mat['levelGamesDone'];
      if (levelGamesDone is Map) {
        final entry = levelGamesDone['$lvl'];
        if (entry is List) {
          return {for (final g in entry) (g as num).toInt()};
        }
      }
    }
    return _siblingProgress == null ? _matDone[lvl] : const {};
  }

  /// Which Kulay-Saya pages in [cat] are coloured, from whichever child's
  /// record is being shown — same reasoning as [_matDoneFor].
  Set<int> _kulayDoneFor(String cat) {
    final kulay = _shownProgress['kulay'];
    if (kulay is Map) {
      final pageDone = kulay['pageDone'];
      if (pageDone is Map) {
        final entry = pageDone[cat];
        if (entry is List) {
          return {for (final i in entry) (i as num).toInt()};
        }
      }
    }
    return _siblingProgress == null ? (_kulayDone[cat] ?? const {}) : const {};
  }

  /// Which poems/stories/songs in [cat] ('tula', 'kwento' or 'kanta') are
  /// finished, from whichever child's record is being shown — same
  /// reasoning as [_matDoneFor].
  Set<int> _magbasaDoneFor(String cat) {
    final magbasa = _shownProgress['magbasa'];
    if (magbasa is Map) {
      final group = magbasa[cat];
      if (group is Map) {
        final entry = group['done'];
        if (entry is List) {
          return {for (final i in entry) (i as num).toInt()};
        }
      }
    }
    return _siblingProgress == null
        ? (_magbasaDone[cat] ?? const {})
        : const {};
  }

  /// Finished drawings, from whichever child's record is being shown.
  int get _shownCreations {
    final kulay = _shownProgress['kulay'];
    if (kulay is Map && kulay['totalCreations'] != null) {
      return (kulay['totalCreations'] as num).toInt();
    }
    return _siblingProgress == null ? _kulayTotalCreations : 0;
  }

  Widget _buildTraceItTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header summary
        Builder(builder: (context) {
          final (earned, possible) = _moduleStars('traceit');
          return _gradedHeader(
            icon: LucideIcons.pencil_line,
            title: AppLocalizations.of(context)!.traceItTitle,
            subtitle: AppLocalizations.of(context)!.traceItSubtitle,
            earned: earned,
            possible: possible,
            gradient: const [Color(0xFFE08A00), Color(0xFFF5C06B)],
          );
        }),
        const SizedBox(height: 20),

        // ── Uppercase ────────────────────────────────────────────────────────
        _tracingSection(
          title: AppLocalizations.of(context)!.uppercaseLettersTitle,
          icon: LucideIcons.case_upper,
          color: Colors.indigo,
          total: _allUpper.length,
          done: _tracedFrom('uppercase', _traceDoneUpper).length,
          letters: _allUpper,
          completedSet: _tracedFrom('uppercase', _traceDoneUpper),
          isExpanded: _traceUpperExpanded,
          onToggle: () =>
              _refreshReport(() => _traceUpperExpanded = !_traceUpperExpanded),
        ),
        const SizedBox(height: 14),

        // ── Lowercase ───────────────────────────────────────────────────────
        _tracingSection(
          title: AppLocalizations.of(context)!.lowercaseLettersTitle,
          icon: LucideIcons.case_lower,
          color: Colors.purple,
          total: _allLower.length,
          done: _tracedFrom('lowercase', _traceDoneLower).length,
          letters: _allLower,
          completedSet: _tracedFrom('lowercase', _traceDoneLower),
          isExpanded: _traceLowerExpanded,
          onToggle: () =>
              _refreshReport(() => _traceLowerExpanded = !_traceLowerExpanded),
        ),
        const SizedBox(height: 14),

        // ── Numbers ──────────────────────────────────────────────────────────
        _tracingSection(
          title: AppLocalizations.of(context)!.numbersTitle,
          icon: LucideIcons.hash,
          color: Colors.teal,
          total: _allNums.length,
          done: _tracedFrom('numbers', _traceDoneNums).length,
          letters: _allNums,
          completedSet: _tracedFrom('numbers', _traceDoneNums),
          isExpanded: _traceNumsExpanded,
          onToggle: () =>
              _refreshReport(() => _traceNumsExpanded = !_traceNumsExpanded),
          isNumbers: true,
        ),
        const SizedBox(height: 20),

        // Tips for parents
        // Advice for a parent at home. A teacher opened this
        // to see what to teach.
        if (!widget.isVisiting) ...[
          _sectionHeader(AppLocalizations.of(context)!.parentTipsHeader,
              LucideIcons.lightbulb),
          const SizedBox(height: 10),
          _tipCard(
              LucideIcons.pencil_line,
              AppLocalizations.of(context)!.tipPencilGripTitle,
              AppLocalizations.of(context)!.tipPencilGripBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.repeat,
              AppLocalizations.of(context)!.tipRepeatTitle,
              AppLocalizations.of(context)!.tipRepeatBody),
          const SizedBox(height: 8),
          _tipCard(
              Icons.star_rounded,
              AppLocalizations.of(context)!.tipPraiseTitle,
              AppLocalizations.of(context)!.tipPraiseBody),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MAGBASA TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMagbasaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Builder(builder: (context) {
          final (earned, possible) = _moduleStars('magbasa');
          return _gradedHeader(
            icon: LucideIcons.book_open,
            title: AppLocalizations.of(context)!.magbasaTitle,
            subtitle: AppLocalizations.of(context)!.alpabetoAtMgaSalita,
            earned: earned,
            possible: possible,
            gradient: const [Color(0xFF7C3AED), Color(0xFFA98BF5)],
          );
        }),
        const SizedBox(height: 16),

        _sectionHeader(AppLocalizations.of(context)!.categoryProgressHeader,
            LucideIcons.grid_3x3),
        const SizedBox(height: 12),

        ..._magbasaDone.keys.map((cat) {
          final catDone = _magbasaDoneFor(cat);
          final done = catDone.length;
          final total = _magbasaTotals[cat] ?? 0;
          final color = _magbasaColors[cat] ?? Colors.grey;
          final icon = _magbasaIcons[cat] ?? LucideIcons.book_open;
          final label = _magbasaCatLabel(cat);
          final progress = total > 0 ? done / total : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Center(child: Icon(icon, color: color, size: 22))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 7))),
                        const SizedBox(width: 10),
                        Text('$done/$total',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ]),
                    ])),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(total, (i) {
                  final isDone = catDone.contains(i);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDone
                          ? color.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isDone ? color : Colors.grey.shade300,
                          width: isDone ? 1.5 : 1),
                    ),
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDone ? color : Colors.grey.shade500)),
                          if (isDone)
                            Icon(LucideIcons.check, size: 8, color: color),
                        ])),
                  );
                }),
              ),
            ]),
          );
        }),

        const SizedBox(height: 4),
        // Advice for a parent at home. A teacher opened this
        // to see what to teach.
        if (!widget.isVisiting) ...[
          _sectionHeader(AppLocalizations.of(context)!.parentTipsHeader,
              LucideIcons.lightbulb),
          const SizedBox(height: 10),
          _tipCard(
              LucideIcons.book_open,
              AppLocalizations.of(context)!.tipTulaTitle,
              AppLocalizations.of(context)!.tipTulaBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.book_marked,
              AppLocalizations.of(context)!.tipKwentoTitle,
              AppLocalizations.of(context)!.tipKwentoBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.music,
              AppLocalizations.of(context)!.tipKantaTitle,
              AppLocalizations.of(context)!.tipKantaBody),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MATEMATIKA TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMatematikaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Builder(builder: (context) {
          final (earned, possible) = _moduleStars('matematika');
          return _gradedHeader(
            icon: LucideIcons.calculator,
            title: AppLocalizations.of(context)!.matematika,
            subtitle: AppLocalizations.of(context)!.letsCount,
            earned: earned,
            possible: possible,
            gradient: const [Color(0xFF2C7BE5), Color(0xFF6BA6F0)],
          );
        }),
        const SizedBox(height: 16),

        _sectionHeader(AppLocalizations.of(context)!.gameProgressHeader,
            LucideIcons.grid_3x3),
        const SizedBox(height: 12),

        ...List.generate(_matLevelTitles(context).length, (lvl) {
          final done = _matDoneFor(lvl).length;
          final total = _matLevelGameCounts[lvl];
          final progress = total > 0 ? done / total : 0.0;
          const color = Colors.teal;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Center(
                        child: Text('${lvl + 1}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color)))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_matLevelTitles(context)[lvl],
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            color),
                                    minHeight: 7))),
                        const SizedBox(width: 10),
                        Text('$done/$total',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ]),
                    ])),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(total, (g) {
                  final isDone = _matDoneFor(lvl).contains(g);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDone
                          ? color.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isDone ? color : Colors.grey.shade300,
                          width: isDone ? 1.5 : 1),
                    ),
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text('${g + 1}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color)),
                          if (isDone)
                            const Icon(LucideIcons.check,
                                size: 8, color: color),
                        ])),
                  );
                }),
              ),
            ]),
          );
        }),

        const SizedBox(height: 4),
        // Advice for a parent at home. A teacher opened this
        // to see what to teach.
        if (!widget.isVisiting) ...[
          _sectionHeader(AppLocalizations.of(context)!.parentTipsHeader,
              LucideIcons.lightbulb),
          const SizedBox(height: 10),
          _tipCard(
              LucideIcons.calculator,
              AppLocalizations.of(context)!.tipCountingTitle,
              AppLocalizations.of(context)!.tipCountingBody),
          const SizedBox(height: 8),
          _tipCard(
              Icons.star_rounded,
              AppLocalizations.of(context)!.tipPraiseMatTitle,
              AppLocalizations.of(context)!.tipPraiseMatBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.gamepad_2,
              AppLocalizations.of(context)!.tipGameFunTitle,
              AppLocalizations.of(context)!.tipGameFunBody),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Reusable widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _tracingSection({
    required String title,
    required IconData icon,
    required Color color,
    required int total,
    required int done,
    required List<String> letters,
    required Set<String> completedSet,
    required bool isExpanded,
    required VoidCallback onToggle,
    bool isNumbers = false,
  }) {
    final progress = total > 0 ? done / total : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        // Header row (tappable to expand)
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(20))
                  : BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Icon(icon, color: color, size: 22))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: color))),
                      Text('$done/$total',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 7)),
                    const SizedBox(height: 4),
                    Text(
                        AppLocalizations.of(context)!
                            .percentComplete((progress * 100).toInt()),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500)),
                  ])),
              const SizedBox(width: 8),
              Icon(
                  isExpanded
                      ? LucideIcons.chevron_up
                      : LucideIcons.chevron_down,
                  color: color),
            ]),
          ),
        ),

        // Expandable letter grid
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: letters.map((l) {
                final isDone = completedSet.contains(l);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isNumbers ? 48 : 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        isDone ? color.withOpacity(0.15) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? color : Colors.grey.shade300,
                      width: isDone ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(l,
                            style: TextStyle(
                              fontSize: isNumbers ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: isDone ? color : Colors.grey.shade500,
                            )),
                        if (isDone)
                          Icon(LucideIcons.check, size: 8, color: color),
                      ])),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  /// The children signed in on this device, most recent first.
  ///
  /// The same list the login screen's face picker reads. A parent with one
  /// child never sees any of this.
  List<Map<String, String>> _household = [];

  /// The sibling being shown, or null for the child who is signed in.
  ///
  /// Their progress comes from their own cloud record rather than from
  /// UserProvider, because switching the session would wipe the signed-in
  /// child's local work.
  Map<String, dynamic>? _siblingProgress;
  String? _siblingId;
  String _siblingName = '';
  bool _loadingSibling = false;

  Future<void> _loadHousehold() async {
    // Read before the await: after it, this screen may already be gone.
    final me =
        Provider.of<UserProvider>(context, listen: false).currentStudentId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('known_students') ?? const [];
    final others = <Map<String, String>>[];
    for (final entry in raw) {
      if (jsonDecode(entry) case final Map m) {
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty || id == me) continue;
        others.add({
          'id': id,
          'name': (m['name'] ?? '').toString(),
          'avatar': (m['avatar'] ?? '').toString(),
        });
      }
    }
    if (!mounted) return;
    setState(() => _household = others);
  }

  /// Reads one sibling's synced progress. Their record holds the same map
  /// `getAllProgress()` produces, so the summary renders unchanged.
  Future<void> _showSibling(Map<String, String> child) async {
    setState(() {
      _loadingSibling = true;
      _siblingId = child['id'];
      _siblingName = child['name'] ?? '';
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(child['id'])
          .get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _siblingProgress = (data?['progress'] as Map?)?.cast<String, dynamic>();
        _loadingSibling = false;
      });
    } catch (e) {
      debugPrint('Could not load sibling progress: $e');
      if (!mounted) return;
      setState(() {
        _siblingProgress = null;
        _loadingSibling = false;
      });
    }
  }

  void _showSignedInChild() {
    setState(() {
      _siblingId = null;
      _siblingProgress = null;
      _siblingName = '';
    });
  }

  /// The progress being shown — the sibling's if one is selected.
  Map<String, dynamic> get _shownProgress =>
      _siblingProgress ?? Provider.of<UserProvider>(context).getAllProgress();

  /// Stars earned and stars available for one module.
  ///
  /// Read off the same ledger the child's dashboard reads, so the figure at
  /// the top of a parent's report and the figure under the child's star are
  /// the same number.
  (int, int) _moduleStars(String key) {
    final m = _shownProgress[key];
    if (m is! Map) return (0, 0);
    final earned = ((m['stars'] ?? m['earnedStars'] ?? 0) as num).toInt();
    return (earned, (m['possibleStars'] as int?) ?? 0);
  }

  /// One level of a graded module: its name, its stars, and how it went.
  ///
  /// Three filled stars is a clean run; fewer means the child got there but
  /// needed more than one go. Empty means not opened — said in words, because
  /// three grey stars and "never tried" look the same to someone skimming.
  Widget _levelStarRow(String title, int stars, Color color) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (stars == 0) ...[
              const SizedBox(height: 2),
              Text(loc.notStartedYet,
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (int i = 0; i < 3; i++)
            Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color:
                    i < stars ? const Color(0xFFFFB800) : Colors.grey.shade300),
        ]),
      ]),
    );
  }

  /// Header shared by the two graded reports: stars earned out of available.
  Widget _gradedHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int earned,
    required int possible,
    required List<Color> gradient,
  }) {
    final loc = AppLocalizations.of(context)!;
    return _gradientCard(
      gradient: gradient,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
        const SizedBox(height: 14),
        Text(loc.starsOfPossible(earned, possible),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: possible > 0 ? earned / possible : 0,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 10,
          ),
        ),
      ]),
    );
  }

  Widget _buildSariliTab() {
    final loc = AppLocalizations.of(context)!;
    final p = Provider.of<UserProvider>(context).getPamilyaProgress();
    final levels = (p['levelStars'] as List?)?.cast<int>() ?? const <int>[];
    final earned = (p['earnedStars'] as int?) ?? 0;
    final possible = (p['possibleStars'] as int?) ?? 0;

    // Levels 0-3 are "About Myself"; 4-8 are "And My Family". The report
    // keeps them apart because a parent reads them as two different subjects.
    const sariliColor = Color(0xFF14A0A0);
    const familyColor = Color(0xFF2E9E5B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _gradedHeader(
          icon: LucideIcons.house_heart,
          title: loc.sariliProgress,
          subtitle: loc.atAkingPamilya,
          earned: earned,
          possible: possible,
          gradient: const [sariliColor, familyColor],
        ),
        const SizedBox(height: 16),
        _sectionHeader(
            loc.angAkingSarili.replaceAll('\n', ' '), LucideIcons.smile),
        const SizedBox(height: 12),
        for (int i = 0; i < 4; i++)
          _levelStarRow(
              loc.level(i + 1), i < levels.length ? levels[i] : 0, sariliColor),
        const SizedBox(height: 8),
        _sectionHeader(loc.atAkingPamilya, LucideIcons.users),
        const SizedBox(height: 12),
        for (int i = 4; i < 9; i++)
          _levelStarRow(
              loc.level(i - 3), i < levels.length ? levels[i] : 0, familyColor),
      ]),
    );
  }

  Widget _buildTandaanTab() {
    final loc = AppLocalizations.of(context)!;
    final p = Provider.of<UserProvider>(context).getTandaanProgress();
    final cats = (p['categoryStars'] as List?)?.cast<int>() ?? const <int>[];
    final earned = (p['stars'] as int?) ?? 0;
    final possible = (p['possibleStars'] as int?) ?? 0;

    const color = Color(0xFF1E88C7);
    final names = [
      loc.animals,
      loc.fruits,
      loc.shapes,
      loc.letters,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _gradedHeader(
          icon: LucideIcons.grid_3x3,
          title: loc.tandaanProgress,
          subtitle: loc.memoryPairs,
          earned: earned,
          possible: possible,
          gradient: const [color, Color(0xFF4ECDC4)],
        ),
        const SizedBox(height: 16),
        _sectionHeader(loc.categoryProgressHeader, LucideIcons.layers),
        const SizedBox(height: 12),
        for (int i = 0; i < names.length; i++)
          _levelStarRow(names[i], i < cats.length ? cats[i] : 0, color),
      ]),
    );
  }

  /// The six modules, in the order the child meets them at home.
  ///
  /// Each entry is a name, the report to open, and the colour the module uses
  /// everywhere else — so a parent recognises Colour Fun by the same pink the
  /// child does.
  List<({String name, Color colour, String module, Widget Function() report})>
      _modules(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      (
        name: loc.matematika,
        colour: const Color(0xFF2C7BE5),
        module: 'matematika',
        report: _buildMatematikaTab
      ),
      (
        name: loc.angAkingSarili.replaceAll('\n', ' '),
        colour: const Color(0xFF2E9E5B),
        module: 'pamilya',
        report: _buildSariliTab
      ),
      (
        name: loc.kulaySaya,
        colour: const Color(0xFFEC4899),
        module: 'kulay',
        report: _buildKulayTab
      ),
      (
        name: loc.traceItTitle,
        colour: const Color(0xFFE08A00),
        module: 'traceit',
        report: _buildTraceItTab
      ),
      (
        name: loc.magbasaTitle,
        colour: const Color(0xFF7C3AED),
        module: 'magbasa',
        report: _buildMagbasaTab
      ),
      (
        name: loc.tandaanTitle,
        colour: const Color(0xFF1E88C7),
        module: 'tandaan',
        report: _buildTandaanTab
      ),
    ];
  }

  /// How far through a module the child is, 0 to 1.
  ///
  /// Read off the star ledger rather than counted separately, so the figure a
  /// parent is shown is the same one the child is collecting.
  double _moduleFraction(Map<String, dynamic> all, String key) {
    final m = all[key];
    if (m is! Map) return 0;
    final possible = (m['possibleStars'] as int?) ?? 0;
    if (possible <= 0) return 0;
    final earned = ((m['stars'] ?? m['earnedStars'] ?? 0) as num).toDouble();
    return (earned / possible).clamp(0.0, 1.0);
  }

  /// The answer, without swiping.
  Widget _buildSummary() {
    final loc = AppLocalizations.of(context)!;
    final all = _shownProgress;
    final mods = _modules(context);

    final ordered = [
      for (final m in mods) (m: m, f: _moduleFraction(all, m.module))
    ]..sort((a, b) => a.f.compareTo(b.f));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Only when there is more than one child on this device.
        if (_household.isNotEmpty) ...[
          _childSwitcher(),
          const SizedBox(height: 16),
        ],
        if (_loadingSibling)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _parentSummary(),
          const SizedBox(height: 16),

          // Only on a sibling's page, and only for a parent: a teacher is
          // looking at somebody else's child and has no business signing
          // them in on their own phone.
          if (_siblingId != null && widget.viewStudentData == null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _switchToChild,
                icon: const Icon(LucideIcons.repeat, size: 18),
                label: Text(AppLocalizations.of(context)!
                    .switchToChild(_siblingName.split(' ').first)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // The teacher's question is "how is this one doing, and what do I
          // do about it". The card above answers the first half; this answers
          // the second, so it sits with it rather than below six module bars.
          if (widget.viewStudentData != null) ...[
            PracticeList(progress: _shownProgress),
            const SizedBox(height: 4),
          ],

          // Weakest first. That ordering is the whole of what the two
          // "strongest" and "needs help" cards used to say, so they are gone:
          // the module to help with is the top row, and the one going well is
          // the bottom one. Two cards of prose become the order of a list.
          _sectionHeader(loc.weakestFirst, LucideIcons.layers),
          const SizedBox(height: 12),
          for (final entry in ordered)
            _moduleRow(
              entry.m.name,
              entry.m.colour,
              entry.f,
              // Open for anyone now. These used to read this device's own
              // files — its traced letters, its artwork tally — so a sibling's
              // name would have sat over the signed-in child's work; both now
              // come from the record being shown.
              () => _openReport(entry.m.name, entry.m.report),
            ),
        ],

        // A teacher reads the page above exactly as the parent does, and
        // finds what only a teacher can do underneath it.
        if (widget.viewStudentData != null) ...[
          const SizedBox(height: 8),
          // Artwork and the reset controls: things a teacher goes looking
          // for, not things they need on arrival.
          TeacherTools(
            studentName: widget.viewStudentName ?? '',
            studentData: widget.viewStudentData!,
          ),
        ],

        const SizedBox(height: 12),
        // Seven cards telling a daycare teacher to encourage their child to
        // colour. Written for somebody at home, and in the teacher's way.
        if (!widget.isVisiting) ...[
          _sectionHeader(AppLocalizations.of(context)!.parentTipsHeader,
              LucideIcons.lightbulb),
          const SizedBox(height: 10),
          _tipCard(
              LucideIcons.palette,
              AppLocalizations.of(context)!.tipKulayTitle,
              AppLocalizations.of(context)!.tipKulayBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.pencil_line,
              AppLocalizations.of(context)!.tipTraceItTitle,
              AppLocalizations.of(context)!.tipTraceItBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.book_open,
              AppLocalizations.of(context)!.tipMagbasaTitle,
              AppLocalizations.of(context)!.tipMagbasaBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.calculator,
              AppLocalizations.of(context)!.tipMatematikaTitle,
              AppLocalizations.of(context)!.tipMatematikaBody),
          const SizedBox(height: 8),
          _tipCard(
              LucideIcons.alarm_clock,
              AppLocalizations.of(context)!.tipStudyTimeTitle,
              AppLocalizations.of(context)!.tipStudyTimeBody),
        ],
      ]),
    );
  }

  /// The children on this device, so a parent with two can read both.
  ///
  /// Tapping one shows their summary. It does not sign anyone in or out:
  /// switching the session would wipe the signed-in child's local work, which
  /// is far too much to do for the sake of looking at a page.

  /// "Played today", "yesterday", "4 days ago" — and the run, when there is
  /// one worth mentioning.
  ///
  /// Said in days rather than a date. A parent reads "3 days ago" without
  /// working anything out; a date makes them count.
  String _whenLastPlayed(String iso, int streak) {
    final loc = AppLocalizations.of(context)!;
    if (iso.isEmpty) return loc.notPlayedYet;

    final last = DateTime.tryParse(iso);
    if (last == null) return loc.notPlayedYet;

    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;

    final when = days <= 0
        ? loc.playedToday
        : (days == 1 ? loc.playedYesterday : loc.playedDaysAgo(days));

    // A run of one is just "played today" again, so it is left unsaid.
    if (streak >= 2 && days <= 1) return '$when · ${loc.dayRun(streak)}';
    return when;
  }

  /// Takes a child off this device, after asking.
  ///
  /// Only forgets them: their account and their work are in their own record,
  /// and a teacher signing them in here brings the face back. The wording says
  /// that, because "Remove" beside a child's face reads as something far
  /// larger than it is.
  Future<void> _forgetChild(Map<String, String> child) async {
    final loc = AppLocalizations.of(context)!;
    final name = (child['name'] ?? '').split(' ').first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.removeFromDevice,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(loc.removeFromDeviceNote(name),
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2334D),
                foregroundColor: Colors.white),
            child: Text(loc.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('known_students') ?? const [];
    final kept = <String>[
      for (final entry in raw)
        if (jsonDecode(entry) case final Map m when m['id'] != child['id'])
          entry
    ];
    await prefs.setStringList('known_students', kept);

    // The parent's code stays. It is theirs, not this child's — deleting
    // it here used to shut them out of their other child's report.

    if (!mounted) return;
    // If they were the one being shown, fall back to the signed-in child.
    if (_siblingId == child['id']) _showSignedInChild();
    await _loadHousehold();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.childRemoved)),
    );
  }

  /// Signs the sibling in, so the parent does not have to.
  ///
  /// Refused while the current child has work that is only on this phone:
  /// switching clears the local store, and in an app meant to be played with
  /// no connection that can be a whole afternoon.
  Future<void> _switchToChild() async {
    final loc = AppLocalizations.of(context)!;
    final name = _siblingName.split(' ').first;
    final id = _siblingId;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.switchToChild(name),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(loc.switchToChildNote(name),
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: Text(loc.switchAccount),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loadingSibling = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // The outgoing child's work has to be in the cloud before the local store
    // is cleared. This is the whole risk of switching, so it is checked first
    // and the switch does not happen if it fails.
    final safe = await userProvider.flushToCloud();
    if (!mounted) return;

    if (!safe) {
      setState(() => _loadingSibling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.switchNeedsConnection)),
      );
      return;
    }

    await userProvider.startStudentSession(id);
    userProvider.setCurrentRole('student');
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Widget _childSwitcher() {
    final me = Provider.of<UserProvider>(context).userProfile;
    final entries = <({String? id, String name, String avatar})>[
      (id: null, name: me?.name ?? '', avatar: me?.avatar ?? ''),
      for (final c in _household)
        (id: c['id'], name: c['name'] ?? '', avatar: c['avatar'] ?? ''),
    ];

    return SizedBox(
      // Room for the remove badge, which sits above the top of the face.
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final e = entries[i];
          final selected = e.id == _siblingId;
          return GestureDetector(
            onTap: () {
              if (selected) return;
              if (e.id == null) {
                _showSignedInChild();
              } else {
                _showSibling({
                  'id': e.id!,
                  'name': e.name,
                  'avatar': e.avatar,
                });
              }
            },
            // Hold to take a child off this phone. Not the signed-in child:
            // forgetting the account you are currently using would leave the
            // app showing a report for somebody it no longer knows.
            onLongPress: e.id == null
                ? null
                : () => _forgetChild({
                      'id': e.id!,
                      'name': e.name,
                      'avatar': e.avatar,
                    }),
            child: SizedBox(
              width: 72,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : Colors.grey.shade300,
                        width: selected ? 2.5 : 1.5,
                      ),
                    ),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: avatarTintForPreset(e.avatar),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        avatarAssetForPreset(e.avatar),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const Icon(
                            LucideIcons.user,
                            size: 26,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  // The way a parent finds this. The hold still works for
                  // anyone who tries it, but nobody discovers a hold.
                  if (e.id != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _forgetChild({
                          'id': e.id!,
                          'name': e.name,
                          'avatar': e.avatar,
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 4),
                            ],
                          ),
                          child: const Icon(LucideIcons.x,
                              size: 12, color: Color(0xFFC2334D)),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 5),
                Text(
                  e.name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  /// One module, with the way into its own report.
  Widget _moduleRow(
      String name, Color colour, double fraction, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colour.withOpacity(0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(colour),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 38,
                child: Text('${(fraction * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600)),
              ),
              // No arrow when there is nowhere to go — an arrow that does
              // nothing is worse than none.
              if (onTap != null)
                Icon(LucideIcons.chevron_right,
                    size: 18, color: Colors.grey.shade400)
              else
                const SizedBox(width: 18),
            ]),
          ),
        ),
      ),
    );
  }

  /// Opens one module's report on its own page.
  ///
  /// The reports are unchanged — this only replaces swiping through seven
  /// tabs to reach one of them.
  /// Rebuilds the report the parent is currently looking at.
  ///
  /// A pushed route is built once, so a `setState` on this screen — which is
  /// underneath it — never reaches it. The expanders in the tracing report
  /// were toggling their flag and rebuilding a page nobody could see.
  void Function(VoidCallback)? _rebuildOpenReport;

  /// Toggles something a report shows, and refreshes both.
  void _refreshReport(VoidCallback change) {
    setState(change);
    _rebuildOpenReport?.call(() {});
  }

  void _openReport(String title, Widget Function() body) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            appBar: AppBar(
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0.5,
            ),
            // Its own rebuild, so what the parent taps is what redraws.
            body: StatefulBuilder(builder: (_, rebuild) {
              _rebuildOpenReport = rebuild;
              return body();
            }),
          ),
        ))
        // The page is gone; a later toggle must not reach for it.
        .then((_) => _rebuildOpenReport = null);
  }

  Widget _gradientCard({required List<Color> gradient, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  /// Stars, badges and the overall grade, at the top of the report.
  Widget _parentSummary() {
    final userProvider = Provider.of<UserProvider>(context);

    // Everything here follows whoever is selected above.
    final progress = _shownProgress;
    final grade = (progress['grade'] ?? '').toString();
    final percent = (progress['percentage'] as num?)?.toDouble() ?? 0;
    final stars = _siblingId != null
        ? ((progress['totalStars'] as num?)?.toInt() ?? 0)
        : userProvider.displayStars;
    final whose = _siblingId != null
        ? _siblingName
        : (userProvider.userProfile?.name ?? '');
    final avatar = _siblingId != null
        ? (_household.firstWhere((c) => c['id'] == _siblingId,
                orElse: () => const {})['avatar'] ??
            '')
        : (userProvider.userProfile?.avatar ?? '');
    final streak = (progress['dayStreak'] as num?)?.toInt() ?? 0;
    final lastPlayed = (progress['lastPlayed'] ?? '').toString();

    return _gradientCard(
      gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Whose report this is, with their face. On a device with two
          // children the face is the one line a parent reads at a glance;
          // everything else on the card is a number.
          if (whose.isNotEmpty) ...[
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  avatarAssetForPreset(avatar),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => const Icon(LucideIcons.user,
                      size: 22, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(whose,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      // The first question a parent asks, and the only line
                      // here they can act on tonight.
                      Text(_whenLastPlayed(lastPlayed, streak),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
            ]),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: _summaryFigure(
                  icon: Icons.star_rounded,
                  value: '$stars',
                  of: '${UserProvider.totalPossibleStars}',
                  label: AppLocalizations.of(context)!.stars,
                ),
              ),
              // A sibling's badges are not in the synced record, and a zero
              // would read as "none earned" rather than "not known".
              if (_siblingId == null) ...[
                Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withOpacity(0.35)),
                Expanded(
                  child: _summaryFigure(
                    icon: Icons.workspace_premium_rounded,
                    value: '${userProvider.collectedBadgeIds.length}',
                    of: null,
                    label: AppLocalizations.of(context)!.awards,
                  ),
                ),
              ],
            ],
          ),
          if (grade.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  grade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.28),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryFigure({
    required IconData icon,
    required String value,
    required String? of,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (of != null)
              Text(
                ' / $of',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  // ── Localized label helpers (keep map keys English for progress lookup) ────
  String _catLabel(String cat) {
    final loc = AppLocalizations.of(context)!;
    switch (cat) {
      case 'Animals':
        return loc.catAnimals;
      case 'Flowers':
        return loc.catFlowers;
      case 'Fruits':
        return loc.catFruits;
      case 'Toys':
        return loc.catToys;
      default:
        return cat;
    }
  }

  String _diffLabel(String d) {
    final loc = AppLocalizations.of(context)!;
    switch (d) {
      case 'Easy':
        return loc.diffEasy;
      case 'Medium':
        return loc.diffMedium;
      case 'Hard':
        return loc.diffHard;
      default:
        return d;
    }
  }

  String _magbasaCatLabel(String cat) {
    final loc = AppLocalizations.of(context)!;
    switch (cat) {
      case 'tula':
        return loc.poemLabel;
      case 'kwento':
        return loc.storyLabel;
      case 'kanta':
        return loc.songLabel;
      default:
        return cat;
    }
  }

  Widget _diffChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _tipCard(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.amber.shade800),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(body,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
        ])),
      ]),
    );
  }
}
