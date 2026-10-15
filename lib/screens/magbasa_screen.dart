// ignore_for_file: deprecated_member_use
import '../services/audio_source.dart';
import 'dart:async';
import 'dart:math';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/storybook.dart';
import '../widgets/success_modal.dart';
import '../utils/page_transitions.dart';
import '../data/magbasa_content.dart';
import '../main.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/word_fit.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MagbasaScreen extends StatefulWidget {
  const MagbasaScreen({super.key});

  @override
  State<MagbasaScreen> createState() => _MagbasaScreenState();
}

class _MagbasaScreenState extends State<MagbasaScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // ── Progress ───────────────────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _categoryProgress = {
    'tula': {
      'total': 5,
      'completed': 0,
      'icon': '📖',
      'color': const Color(0xFFFF6B6B),
      'image': 'assets/images/category_tula.webp',
      'activities': [
        {
          'id': 'sipsipat',
          'title': 'Sipsipat',
          'completed': false,
          'type': 'poem',
          'image': 'assets/images/poem1.webp'
        },
        {
          'id': 'adda_asok',
          'title': 'Adda Asok',
          'completed': false,
          'type': 'poem',
          'image': 'assets/images/poem2.webp'
        },
        {
          'id': 'ti_pusak',
          'title': 'Ti Pusak',
          'completed': false,
          'type': 'poem',
          'image': 'assets/images/poem3.webp'
        },
        {
          'id': 'ni_tatang',
          'title': 'Ni Tatang',
          'completed': false,
          'type': 'poem',
          'image': 'assets/images/poem4.webp'
        },
        {
          'id': 'panagsepilio',
          'title': 'Panagsepilio',
          'completed': false,
          'type': 'poem',
          'image': 'assets/images/poem5.webp'
        },
      ]
    },
    'kwento': {
      'total': 5,
      'completed': 0,
      'icon': '📚',
      'color': const Color(0xFFFFB347),
      'image': 'assets/images/category_kwento.webp',
      'activities': [
        {
          'id': 'ni_marti',
          'title': 'Ni Marti ken Kalapati',
          'completed': false,
          'type': 'story',
          'image': 'assets/images/kwento1.webp'
        },
        {
          'id': 'ni_didi',
          'title': 'Ni Didi a Naayat iti Kendi',
          'completed': false,
          'type': 'story',
          'image': 'assets/images/kwento4.webp'
        },
        {
          'id': 'ni_milio',
          'title': 'Ni Milio a Managsepilio',
          'completed': false,
          'type': 'story',
          'image': 'assets/images/kwento2.webp'
        },
        {
          'id': 'ni_neneng',
          'title': 'Ni Neneng a Dina Kayat ti Nateng',
          'completed': false,
          'type': 'story',
          'image': 'assets/images/kwento5.webp'
        },
        {
          'id': 'ni_kikay',
          'title': 'Ni Kikay a di Agsagaysay',
          'completed': false,
          'type': 'story',
          'image': 'assets/images/kwento3.webp'
        },
      ]
    },
    'kanta': {
      'total': 9,
      'completed': 0,
      'icon': '🎵',
      'color': const Color(0xFFA8E6CF),
      'image': 'assets/images/category_kanta.webp',
      'activities': [
        {
          'id': 'ania_ti_naganmo_full',
          'title': 'Ania ti Nagan Mo',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'uppat_a_pato',
          'title': 'Uppat a Pato',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'duat_imak',
          'title': 'Duat\' Imak',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'bassit_a_lawwalawwa',
          'title': 'Bassit a Lawwalawwa',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'maysa_dua_baduya',
          'title': 'Maysa, Dua, Baduya',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'ni_nanangko',
          'title': 'Ni Nanangko',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'da_tarong',
          'title': 'Da Tarong, Kamatis ken Paria',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'nagmulaak_iti_katuday',
          'title': 'Nagmulaak iti Katuday',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
        {
          'id': 'lima_a_tinapay',
          'title': 'Lima a Tinapay ken dua nga Ikan',
          'completed': false,
          'type': 'song',
          'image': 'assets/images/category_kanta.webp'
        },
      ]
    },
  };

  // ── Poem data ──────────────────────────────────────────────────────────────
  Map<String, Map<String, dynamic>> get _poemData {
    return MagbasaContent.getPoemData();
  }

  // ── Story data ─────────────────────────────────────────────────────────────
  Map<String, Map<String, dynamic>> get _storyData {
    return MagbasaContent.getStoryData();
  }

  // ── Song data ──────────────────────────────────────────────────────────────
  Map<String, Map<String, dynamic>> get _songData {
    return MagbasaContent.getSongData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Silence, not a loop. This is the one module whose point is
    // listening to a voice, and a tune underneath competes with the thing
    // the child is meant to be hearing. `dispose` hands the home music back.
    AudioManager.instance.stopMusic();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgress();
    _initSmartResume();
  }

  Future<void> _initSmartResume() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      int retryCount = 0;
      while (!userProvider.isInitialized && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
      }

      // Tab mapping: 0=Tula, 1=Kwento, 2=Kanta
      int targetTab = 0;
      bool found = false;

      // Check categories in order
      List<String> categories = ['tula', 'kwento', 'kanta'];
      for (int i = 0; i < categories.length; i++) {
        String cat = categories[i];
        List activities = _categoryProgress[cat]!['activities'];
        bool catCompleted = true;
        for (int j = 0; j < activities.length; j++) {
          if (!userProvider.isMagbasaActivityCompleted(cat, j)) {
            targetTab = i;
            catCompleted = false;
            found = true;
            break;
          }
        }
        if (found) break;
        if (!catCompleted) {
          targetTab = i;
          break;
        }
      }

      if (mounted) {
        _tabController.animateTo(targetTab);
      }
    } catch (e) {
      debugPrint('Magbasa Smart Resume failed: $e');
    }
  }

  Future<void> _loadProgress() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final category in _categoryProgress.keys) {
        for (int i = 0;
            i < (_categoryProgress[category]!['activities'] as List).length;
            i++) {
          final done = _prefs.getBool('${category}_activity_$i') ?? false;
          (_categoryProgress[category]!['activities'] as List)[i]['completed'] =
              done;
        }
      }
      _updateAllCompletedCounts();
      _isLoading = false;
    });
  }

  void _updateAllCompletedCounts() {
    for (final category in _categoryProgress.keys) {
      int count = 0;
      for (final act in (_categoryProgress[category]!['activities'] as List)) {
        if (act['completed'] == true) count++;
      }
      _categoryProgress[category]!['completed'] = count;
    }
  }

  Future<void> _updateProgress(
      String category, int activityIndex, bool completed) async {
    setState(() {
      (_categoryProgress[category]!['activities'] as List)[activityIndex]
          ['completed'] = completed;
      _updateAllCompletedCounts();
    });
    await _prefs.setBool('${category}_activity_$activityIndex', completed);
    if (completed) {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.updateMagbasaProgress(category, activityIndex, true);
    }
  }

  int _getTotalCompleted() {
    int t = 0;
    _categoryProgress.forEach((_, v) => t += v['completed'] as int);
    return t;
  }

  int _getTotalActivities() {
    int t = 0;
    _categoryProgress.forEach((_, v) => t += v['total'] as int);
    return t;
  }

  double _getCategoryProgress(String category) {
    final total = _categoryProgress[category]!['total'] as int;
    final done = _categoryProgress[category]!['completed'] as int;
    return total > 0 ? done / total : 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    AudioManager.instance.resumeHomeMusic();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalCompleted = _getTotalCompleted();
    final totalActivities = _getTotalActivities();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CustomBackButton(
          iconColor: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.magbasaTitle,
          style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 17),
              const SizedBox(width: 4),
              Text('$totalCompleted/$totalActivities',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5A300),
                      fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FE), Color(0xFFEDF1F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: [
                // Not upper-cased. A child learning to read meets letters
                // in the shape they were taught them in, and TULA is not the
                // shape of the word on any page they will ever open.
                Tab(
                    text: AppLocalizations.of(context)!.tula,
                    icon: const Icon(LucideIcons.book_open)),
                Tab(
                    text: AppLocalizations.of(context)!.kwento,
                    icon: const Icon(LucideIcons.book)),
                Tab(
                    text: AppLocalizations.of(context)!.kanta,
                    icon: const Icon(LucideIcons.music)),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryTab('tula'),
                _buildCategoryTab('kwento'),
                _buildCategoryTab('kanta'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    final data = _categoryProgress[category]!;
    final activities = data['activities'] as List;
    final progress = _getCategoryProgress(category);
    final color = data['color'] as Color;
    final icon = data['icon'] as String;
    final catImage = data['image'] as String;

    String title = category == 'tula'
        ? AppLocalizations.of(context)!.poems
        : category == 'kwento'
            ? AppLocalizations.of(context)!.stories
            : AppLocalizations.of(context)!.songs;

    return Container(
      color: Colors.transparent,
      child: Column(children: [
        // Category header
        Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  catImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(icon, style: const TextStyle(fontSize: 30))),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.02, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // The one count on the screen, and in the same
                    // currency as every other module: a star per piece
                    // finished.
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          size: 20, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text(
                        "${data['completed']}/${data['total']}",
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF5A300)),
                      ),
                    ]),
                  ]),
                ],
              ),
            ),
          ]),
        ),

        // The stories themselves, as pictures.
        //
        // This was a list: an 84-pixel thumbnail, a title, a chevron. A child
        // who cannot read picks by the picture, and the picture was the
        // smallest thing in the row. Two to a row makes it the largest.
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: activities.length,
            itemBuilder: (_, index) {
              final activity = activities[index];
              final id = activity['id'] as String;
              final contentData = category == 'tula'
                  ? _poemData[id]
                  : category == 'kwento'
                      ? _storyData[id]
                      : _songData[id];
              final displayTitle = contentData?['title'] ?? activity['title'];
              return _buildActivityItem(
                title: displayTitle,
                type: activity['type'],
                isCompleted: activity['completed'],
                color: color,
                imagePath: activity['image'],
                onTap: () =>
                    _navigateToActivity(category, index, id, activity['type']),
              );
            },
          ),
        ),
      ]),
    );
  }

  /// One poem, story or song — a picture with its name under it.
  ///
  /// This was a list row: an 84-pixel thumbnail on the left, the title beside
  /// it, a chevron on the right. For a child who cannot read the title, the
  /// picture is the whole of the choice, and it was the smallest thing in the
  /// row. Here it is the card, and the words sit underneath it.
  ///
  /// A finished one keeps its picture and gains a tick, rather than being
  /// greyed out: children go back to the story they liked, and the point of
  /// the mark is to say "you have read this", not "this one is spent".
  Widget _buildActivityItem({
    required String title,
    required String type,
    required bool isCompleted,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final IconData typeIcon = type == 'poem'
        ? LucideIcons.book_open
        : type == 'story'
            ? LucideIcons.book
            : LucideIcons.music;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: isCompleted ? color : Colors.grey.shade200,
                width: isCompleted ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                  color: isCompleted
                      ? color.withOpacity(0.22)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(children: [
            // The picture takes the top of the card and fills it corner to
            // corner — a scene cropped to a square reads better at this size
            // than the whole scene shrunk into a letterbox.
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: color.withOpacity(0.1),
                      child:
                          Center(child: Icon(typeIcon, color: color, size: 44)),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 6)
                        ],
                      ),
                      child: const Icon(LucideIcons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),
              ]),
            ),
            // The name, in the space it needs and no more.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: SizedBox(
                height: 38,
                child: Center(
                  child: WordSafeText(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? color : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _navigateToActivity(
      String category, int index, String id, String type) async {
    // Finished before? Then finishing it again is a repeat, and a repeat is
    // not celebrated — a child hearing a poem for the fifth time is learning
    // it, not achieving something new.
    final done = Provider.of<UserProvider>(context, listen: false)
        .isMagbasaActivityCompleted(category, index);

    Widget screen;
    if (category == 'tula') {
      final data = _poemData[id]!;
      screen = PoemScreen(
          poemTitle: data['title'], poemData: data, alreadyDone: done);
    } else if (category == 'kwento') {
      final data = _storyData[id]!;
      screen = StoryScreen(
          storyTitle: data['title'], storyData: data, alreadyDone: done);
    } else {
      final data = _songData[id]!;
      screen = SongScreen(
          songTitle: data['title'], songData: data, alreadyDone: done);
    }

    final completed = await context.pushPremium<bool>(screen);

    if (completed == true) {
      await _updateProgress(category, index, true);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  POEM SCREEN  — Karaoke-style reading with audio sync
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
//  WHERE A LINE SITS IN A RECORDING
// ─────────────────────────────────────────────────────────────────────────────
//
// A poem with no per-line timestamps still has to highlight the right line as
// the recording plays, and the guess used everywhere here is that a line takes
// time in proportion to how many words are in it.
//
// It matters that there is exactly one of these. The seek and the highlight
// used to work it out separately — the seek dividing the recording evenly
// between non-empty lines, the highlight weighting by words — so stepping back
// one line landed at a position the highlight then resolved to a different
// line. Two measures of the same thing will always drift; one cannot.

/// How long each line takes to say, relative to the others.
///
/// A blank line is a stanza break and takes no time, but it still occupies an
/// index, so it is weighted 1 rather than 0 — a zero-width line would make the
/// two functions below disagree about which side of it a position falls.
List<int> lineWeights(List<String> lines) => [
      for (final l in lines)
        () {
          final words =
              l.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          return words == 0 ? 1 : words;
        }()
    ];

/// The line a position falls in, given as a fraction of the whole recording.
int lineAtFraction(List<int> weights, double fraction) {
  if (weights.isEmpty) return 0;
  final total = weights.fold<int>(0, (a, b) => a + b);
  if (total == 0) return 0;
  final f = fraction.clamp(0.0, 1.0);
  double acc = 0;
  for (int i = 0; i < weights.length; i++) {
    acc += weights[i];
    if (f <= acc / total) return i;
  }
  return weights.length - 1;
}

/// The middle of a line, as a fraction of the whole recording.
///
/// The middle rather than the start, because [lineAtFraction] resolves a
/// boundary to the line before it — so aiming at a line's start lands on its
/// predecessor, which is what made one press of the back button step back two
/// lines.
double fractionAtLine(List<int> weights, int index) {
  if (weights.isEmpty) return 0;
  final total = weights.fold<int>(0, (a, b) => a + b);
  if (total == 0) return 0;
  final i = index.clamp(0, weights.length - 1);
  double before = 0;
  for (int k = 0; k < i; k++) {
    before += weights[k];
  }
  return ((before + weights[i] / 2) / total).clamp(0.0, 1.0);
}

/// Runs a player command, giving up rather than waiting for ever.
///
/// Everything the play button waits for goes through here. A web audio
/// command can fail to answer at all, and an unanswered one on this path
/// leaves a pause button drawn over silence with nothing to correct it.
Future<bool> _safe(Future<void> Function() op) async {
  try {
    await op().timeout(const Duration(seconds: 3));
    return true;
  } catch (e) {
    debugPrint('Player command abandoned: $e');
    return false;
  }
}

/// Stops and throws away a reading's player, in the background.
///
/// `dispose()` cannot await, and this can take its time or fail outright on
/// the web. That is survivable only because the object being torn down is not
/// the one the next screen is using: whatever happens here, it happens alone.
void _retire(AudioPlayer player) {
  () async {
    // Stopped and released — never disposed.
    //
    // On the web, `dispose()` breaks every player created after it. The log
    // from the phone is unambiguous: the first play succeeds, the child goes
    // back, and from then on three separate brand-new players all fail in
    // under a millisecond with `Unsupported operation: _Namespace` — dart:io
    // being reached for an asset that should resolve to a URL. The damage is
    // to the plugin, not to the player being thrown away.
    //
    // A released player holds no source and no audio element, so leaving it
    // for the garbage collector costs a little memory. Disposing it costs
    // every recording for the rest of the session.
    try {
      await player.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await player.release().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }();
}

/// Starts a recording from the beginning, and says whether it started.
///
/// A screen that has drawn a pause button needs to know when nothing is
/// playing, or the child is left looking at a control that does nothing. The
/// timeout is what makes an answer certain: on the web a play can simply not
/// come back.

Future<bool> _play(AudioPlayer player, String assetPath) async {
  try {
    await player
        .play(audioSourceFor(assetPath))
        .timeout(const Duration(seconds: 4));
    return true;
  } catch (e) {
    debugPrint('Could not start $assetPath: $e');
    return false;
  }
}

class PoemScreen extends StatefulWidget {
  final String poemTitle;
  final Map<String, dynamic> poemData;

  /// Whether this reading was already finished before this visit.
  ///
  /// A repeat is not a new achievement, so it is not celebrated and
  /// does not end the visit — the child stays where they are and can
  /// play it again.
  final bool alreadyDone;

  const PoemScreen({
    super.key,
    this.alreadyDone = false,
    required this.poemTitle,
    required this.poemData,
  });

  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _poemColor = Color(0xFFFF6B6B);
  static const Color _karaokeHighlight = Color(0xFFFF6B6B);

  bool _isCompleted = false;
  int _currentLineIndex = 0;
  bool _isPlaying = false;
  bool _wasPlayingBeforePause = false;

  /// True once the recording has been handed to the player.
  ///
  /// Without it, resuming meant calling `play(AssetSource(...))` again, which
  /// loads the file afresh and starts it from the beginning — so pausing a
  /// poem and pressing play restarted it, and every seek made while paused
  /// was discarded.
  bool _audioLoaded = false;

  late AnimationController _pulseController;

  /// This screen's own player, built with it and retired with it.
  ///
  /// It used to be one player shared by every poem, story and song for the
  /// life of the app, which meant each screen inherited the last one's
  /// source, position and pending commands. A player per reading makes the
  /// whole class of fault impossible instead of handled.
  ///
  /// Not final: a player that will not start is thrown away and replaced
  /// rather than argued with. See [_startAudio].
  AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  late ScrollController _scrollController;

  int _totalDurationMs = 0;
  int _currentPositionMs = 0;
  Timer? _fallbackTimer;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  List<String> get _lines {
    final raw = widget.poemData['content'] as List? ?? [];
    return raw.map((e) => e.toString()).toList();
  }

  String? get _audioPath => widget.poemData['audioPath'] as String?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _scrollController = ScrollController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _currentPositionMs = pos.inMilliseconds);
        _syncLineFromPosition();
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDurationMs = dur.inMilliseconds);
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) _onPlaybackComplete();
    });
  }

  void _syncLineFromPosition() {
    if (_totalDurationMs <= 0 || _lines.isEmpty) return;
    final nonEmpty = _lines.where((l) => l.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return;

    final rawTs =
        widget.poemData['lineTimestampsMs'] ?? widget.poemData['timestampsMs'];
    if (rawTs is List && rawTs.isNotEmpty) {
      final timestamps = rawTs.cast<int>();
      final effectivePos =
          _currentPositionMs + 200; // slight lookahead for smooth reading
      int targetIndex = 0;
      for (int i = 0; i < timestamps.length; i++) {
        if (effectivePos >= timestamps[i]) {
          targetIndex = i;
        } else {
          break;
        }
      }
      final clamped = targetIndex.clamp(0, _lines.length - 1);
      if (clamped != _currentLineIndex) {
        setState(() => _currentLineIndex = clamped);
        _scrollToCurrentLine();
      }
      return;
    }

    // Longer lines take proportionally longer to say. The same measure the
    // seek uses — see lineWeights.
    final effectivePos = (_currentPositionMs + 250).clamp(0, _totalDurationMs);
    final target =
        lineAtFraction(lineWeights(_lines), effectivePos / _totalDurationMs);

    if (target != _currentLineIndex) {
      setState(() => _currentLineIndex = target);
      _scrollToCurrentLine();
    }
  }

  /// Keys for the lines, so the scroll can ask where they actually are.
  final Map<int, GlobalKey> _lineKeys = {};

  GlobalKey _lineKey(int index) =>
      _lineKeys.putIfAbsent(index, () => GlobalKey());

  /// Puts the line being read in the middle of the screen.
  ///
  /// This used to be `<a guess at the header> + index * <a guess at the line
  /// height>`. Both guesses are wrong the moment a line wraps, and the result
  /// was the top of the line at the top of the screen rather than the middle.
  void _scrollToCurrentLine() {
    if (!_isPlaying) return;
    final context = _lineKeys[_currentLineIndex]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onPlaybackComplete() {
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
      _currentLineIndex = _lines.length - 1;
    });
    _pulseController.stop();
    // The file is reloaded next time rather than resumed: a completed
    // player has nothing left to resume on some platforms, and a poem the
    // child has finished is exactly the one they ask to hear again.
    _audioLoaded = false;
    // Only the first finish is an achievement. A child hearing a poem for
    // the fifth time is learning it, and the modal would cover the words,
    // hand out stars they already have, and send them back to the list.
    if (widget.alreadyDone) return;

    _confettiController.play();
    _showCompletionDialog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        _wasPlayingBeforePause = true;
        _audioPlayer.pause();
        _pulseController.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) {
        _audioPlayer.resume();
        _pulseController.repeat(reverse: true);
        _wasPlayingBeforePause = false;
      }
    }
  }

  /// Starts this reading's recording, with a clean player if the first fails.
  ///
  /// A play that does not start is not investigated — the screen drops that
  /// player, builds another and asks again. A player constructed a moment ago
  /// cannot be holding anything the previous screen left behind, so the
  /// second attempt is as clean as a fresh launch.
  /// Has this screen started the recording at all yet?
  ///
  /// The first press has nothing to clean up; every press after it may be
  /// looking at a player parked at the end of the file.
  bool _hasStarted = false;

  Future<bool> _startAudio() async {
    // Only a replay needs a clean player. On the first press the screen's own
    // player has never been used, and throwing it away to build an identical
    // one was the most elaborate path in the file for the plainest case.
    if (_hasStarted) _freshPlayer();
    _hasStarted = true;

    if (await _play(_audioPlayer, _audioPath!)) return true;

    debugPrint('Player would not start; replacing it and retrying.');
    _freshPlayer();
    return _play(_audioPlayer, _audioPath!);
  }

  /// Retires this screen's player and builds another, listening again.
  void _freshPlayer() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _retire(_audioPlayer);
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    _fallbackTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    // Retired with the screen. It belongs to this reading and to nothing
    // else, so there is no next poem for it to leave anything behind for.
    _retire(_audioPlayer);
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    setState(() {
      _isPlaying = true;
      _pulseController.repeat(reverse: true);
    });

    if (_isCompleted) {
      setState(() {
        _isCompleted = false;
        _currentLineIndex = 0;
      });
    }

    if (_audioPath != null) {
      try {
        if (_audioLoaded) {
          await _safe(() => _audioPlayer.resume());
        } else {
          if (!await _startAudio()) {
            // The command never came back. The highlight still has to move,
            // or the child is left looking at a pause button doing nothing.
            _startFallbackTimer();
            return;
          }
          _audioLoaded = true;
        }
      } catch (e) {
        debugPrint('Error playing poem audio: $e');
        _startFallbackTimer();
      }
    } else {
      _startFallbackTimer();
    }
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    final nonEmpty = _lines.where((l) => l.trim().isNotEmpty).toList();
    final secPerLine = nonEmpty.isEmpty ? 3 : max(3, 18 ~/ nonEmpty.length);

    _fallbackTimer = Timer.periodic(Duration(seconds: secPerLine), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      if (_currentLineIndex < _lines.length - 1) {
        setState(() => _currentLineIndex++);
      } else {
        timer.cancel();
        _onPlaybackComplete();
      }
    });
  }

  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
      _pulseController.stop();
    });
    _fallbackTimer?.cancel();
    // Pause, not stop. stop() winds the recording back to zero, so what the
    // child pressed as pause was really "start this over". The module music
    // stays down — pausing is part of reading, not the end of it.
    await _safe(() => _audioPlayer.pause());
  }

  /// Back to the first line and off again.
  ///
  /// "Again, from the start" is the thing a three-year-old asks for after a
  /// story, and it was the one thing the bar could not do: seeking a line at
  /// a time back to the beginning is not a gesture they have.
  Future<void> _restart() async {
    await _stopPlayback();
    if (!mounted) return;
    setState(() {
      _currentLineIndex = 0;
      _isCompleted = false;
    });
    if (_audioPath != null) await _safe(() => _audioPlayer.seek(Duration.zero));
    await _startPlayback();
  }

  /// Where line [index] sits in the recording, in milliseconds.
  ///
  /// The middle of the line, not its start. [_syncLineFromPosition] decides
  /// which line is current by walking the boundaries with `<=`, so a position
  /// landing exactly on a boundary resolves to the line *before* the one
  /// asked for. Aiming at the middle puts the answer beyond argument.
  ///
  /// It also measures the same way the sync does — timestamps when the poem
  /// has them, word-weighted otherwise. Two different measures were the
  /// reason stepping back moved somewhere the child had not asked for.

  int _msForLine(int index) {
    final rawTs =
        widget.poemData['lineTimestampsMs'] ?? widget.poemData['timestampsMs'];
    if (rawTs is List && rawTs.isNotEmpty) {
      final ts = rawTs.cast<int>();
      if (index >= 0 && index < ts.length) {
        final start = ts[index];
        final end = index + 1 < ts.length ? ts[index + 1] : _totalDurationMs;
        return ((start + end) ~/ 2).clamp(0, _totalDurationMs);
      }
    }

    return (fractionAtLine(lineWeights(_lines), index) * _totalDurationMs)
        .round()
        .clamp(0, _totalDurationMs);
  }

  Future<void> _seekToLine(int index) async {
    if (_lines.isEmpty) return;

    // Clamped, not refused. The old guard returned on -1, so at the first
    // line the child pressed the button and the app did nothing — which is
    // indistinguishable from the button being broken.
    final back = index < _currentLineIndex;
    int target = index.clamp(0, _lines.length - 1);

    // A blank line is a stanza break, drawn as a gap. Landing on one
    // highlights nothing, so carry on past it in the direction of travel.
    while (target > 0 &&
        target < _lines.length - 1 &&
        _lines[target].trim().isEmpty) {
      target += back ? -1 : 1;
    }
    if (_lines[target].trim().isEmpty) return;

    setState(() => _currentLineIndex = target);

    if (_audioPath != null && _totalDurationMs > 0) {
      await _safe(
          () => _audioPlayer.seek(Duration(milliseconds: _msForLine(target))));
    } else if (_isPlaying) {
      _fallbackTimer?.cancel();
      _startFallbackTimer();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SuccessModal(
        title: AppLocalizations.of(context)!.congratulations,
        subtitle: AppLocalizations.of(context)!.readingFinishedGood,
        score: 50,
        stars: 3,
        primaryLabel: AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop(true);
        },
        secondaryLabel: AppLocalizations.of(context)!.repeat,
        onSecondaryTap: () {
          Navigator.of(dialogContext).pop();
          setState(() {
            _isCompleted = false;
            _currentLineIndex = 0;
          });
          _startPlayback();
        },
      ),
    );
  }

  /// The poem's picture cut out of its page, so it can stand up out of the
  /// top of the card the way the design draws it. The originals stay as
  /// they are for the list's cards.
  static String _artFor(String image) {
    final m = RegExp(r'assets/images/(poem\d+)\.(png|webp)').firstMatch(image);
    return m == null ? image : 'assets/images/${m.group(1)}_art.webp';
  }

  @override
  Widget build(BuildContext context) {
    final content = _lines;
    final art = _artFor(widget.poemData['image'] as String);

    return StorybookScaffold(
      title: widget.poemTitle,
      // The music is handed back here, inside the tap. Chrome will not let a
      // page start audio outside a user gesture, and dispose runs long after
      // the tap is over.
      onClose: () => Navigator.pop(context, _isCompleted),
      banner:
          StorybookHint(AppLocalizations.of(context)!.readFullPoemBeforeBack),
      progress: _totalDurationMs > 0
          ? _currentPositionMs / _totalDurationMs
          : (content.isEmpty ? 0.0 : (_currentLineIndex + 1) / content.length),
      fill: const Color(0xFF4CD68A),
      playColor: const Color(0xFFF2453F),
      isPlaying: _isPlaying,
      onPlayPause: _togglePlay,
      onRestart: _restart,
      onBack: () => _seekToLine(_currentLineIndex - 1),
      overlay: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.pink,
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.white
          ],
          numberOfParticles: 25,
          gravity: 0.15,
        ),
      ),
      body: LayoutBuilder(builder: (_, box) {
        // The picture stands half out of the top of the card.
        final artH = (box.maxHeight * 0.32).clamp(80.0, 210.0);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            top: artH * 0.5,
            child: CoralCard(
              padding: EdgeInsets.fromLTRB(12, artH * 0.5, 12, 8),
              // The only thing that moves.
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(content.length, (index) {
                    final text = content[index];
                    if (text.isEmpty) {
                      return const SizedBox(height: 18); // stanza break
                    }
                    final isCurrent = index == _currentLineIndex && _isPlaying;
                    final isPast = _isPlaying && index < _currentLineIndex;
                    return AnimatedContainer(
                      key: _lineKey(index),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      // A filled band for the line being read, so a child
                      // following along with a finger can find it.
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? _karaokeHighlight.withOpacity(0.22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // One size and weight for every line, so the line
                      // being read never re-wraps and pushes the rest down;
                      // only its colour marks it. Upright, never italic.
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: StorybookScaffold.fredoka(
                          27,
                          isCurrent
                              ? _poemColor
                              : (isPast
                                  ? Colors.grey.shade600
                                  : StorybookScaffold.navy),
                          weight: 650,
                        ),
                        child: Text(text, textAlign: TextAlign.center),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: artH,
            child: IgnorePointer(
              child: Image.asset(
                art,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Center(
                    child: Text('📖', style: TextStyle(fontSize: 64))),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STORY SCREEN  — full single-scroll display
// ─────────────────────────────────────────────────────────────────────────────
class StoryScreen extends StatefulWidget {
  final String storyTitle;
  final Map<String, dynamic> storyData;

  /// Whether this reading was already finished before this visit.
  ///
  /// A repeat is not a new achievement, so it is not celebrated and
  /// does not end the visit — the child stays where they are and can
  /// play it again.
  final bool alreadyDone;

  const StoryScreen({
    super.key,
    this.alreadyDone = false,
    required this.storyTitle,
    required this.storyData,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with WidgetsBindingObserver {
  static const Color _storyColor = Color(0xFFFFB347);
  static const List<String> _dividerEmojis = ['🌟', '🌿', '☀️', '🌙', '🍀'];

  /// This screen's own player, built with it and retired with it.
  ///
  /// It used to be one player shared by every poem, story and song for the
  /// life of the app, which meant each screen inherited the last one's
  /// source, position and pending commands. A player per reading makes the
  /// whole class of fault impossible instead of handled.
  ///
  /// Not final: a player that will not start is thrown away and replaced
  /// rather than argued with. See [_startAudio].
  AudioPlayer _audioPlayer = AudioPlayer();
  late ScrollController _scrollController;
  bool _isPlaying = false;
  int _currentLineIndex = 0;
  int _totalDurationMs = 0;
  int _currentPositionMs = 0;
  Timer? _fallbackTimer;
  bool _isCompleted = false;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  /// True once the recording has been handed to the player.
  ///
  /// Without it, resuming meant calling `play(AssetSource(...))` again, which
  /// loads the file afresh and starts it from the beginning — so pausing a
  /// poem and pressing play restarted it, and every seek made while paused
  /// was discarded.
  bool _audioLoaded = false;

  late ConfettiController _confettiController;

  String? get _audioPath => widget.storyData['audioPath'] as String?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (_audioPath != null) {
      // Held so they can be cancelled. The player outlives this screen now,
      // so a listener left attached would go on firing for every poem and
      // song opened after this story — one more set per story read.
      _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
        if (mounted) setState(() => _totalDurationMs = dur.inMilliseconds);
      });
      _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() {
            _currentPositionMs = pos.inMilliseconds;
            _updateCurrentLineFromPosition();
          });
        }
      });
      _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) _onPlaybackComplete();
      });
    }
  }

  void _updateCurrentLineFromPosition() {
    final content = widget.storyData['content'] as List;
    if (content.isEmpty || _totalDurationMs == 0) return;

    final rawTs = widget.storyData['lineTimestampsMs'] ??
        widget.storyData['timestampsMs'];
    if (rawTs is List && rawTs.isNotEmpty) {
      final timestamps = rawTs.cast<int>();
      final effectivePos = _currentPositionMs + 400;
      int targetIndex = 0;
      for (int i = 0; i < timestamps.length; i++) {
        if (effectivePos >= timestamps[i]) {
          targetIndex = i;
        } else {
          break;
        }
      }
      final clamped = targetIndex.clamp(0, content.length - 1);
      if (clamped != _currentLineIndex) {
        setState(() => _currentLineIndex = clamped);
        _scrollToCurrentLine();
      }
      return;
    }

    final nonEmpCount = content.where((e) => (e as String).isNotEmpty).length;
    if (nonEmpCount == 0) return;

    final progress = (_currentPositionMs / _totalDurationMs).clamp(0.0, 1.0);
    int activeLineIdx = 0;
    int curNonEmp = 0;
    final targetNonEmp =
        ((progress * nonEmpCount).floor()).clamp(0, nonEmpCount - 1);

    for (int i = 0; i < content.length; i++) {
      if ((content[i] as String).isNotEmpty) {
        if (curNonEmp == targetNonEmp) {
          activeLineIdx = i;
          break;
        }
        curNonEmp++;
      }
    }
    if (activeLineIdx != _currentLineIndex) {
      setState(() => _currentLineIndex = activeLineIdx);
      _scrollToCurrentLine();
    }
  }

  /// Keys for the lines, so the scroll can ask where they actually are.
  final Map<int, GlobalKey> _lineKeys = {};

  GlobalKey _lineKey(int index) =>
      _lineKeys.putIfAbsent(index, () => GlobalKey());

  /// Puts the line being read in the middle of the screen.
  ///
  /// This used to be `<a guess at the header> + index * <a guess at the line
  /// height>`. Both guesses are wrong the moment a line wraps, and the result
  /// was the top of the line at the top of the screen rather than the middle.
  void _scrollToCurrentLine() {
    if (!_isPlaying) return;
    final context = _lineKeys[_currentLineIndex]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _togglePlay() async {
    final content = widget.storyData['content'] as List;
    if (_isPlaying) {
      await _safe(() => _audioPlayer.pause());
      _fallbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      // The module music has to go quiet, or the story is narrated over it.
      // The poem and the song both did this; the story never had the call at
      // all, so the two played together for as long as the child listened.
      if (_audioPath != null) {
        // Resume where it was paused. Starting fresh does not come
        // through here — `_startAudio` builds a new player for that, which
        // is at zero by construction.
        if (_audioLoaded) {
          await _safe(() => _audioPlayer.resume());
        } else {
          if (!await _startAudio()) {
            // The command never came back. The highlight still has to move,
            // or the child is left looking at a pause button doing nothing.
            _startFallbackTimer(content);
            return;
          }
          _audioLoaded = true;
        }
        setState(() => _isPlaying = true);
      } else {
        setState(() => _isPlaying = true);
        _startFallbackTimer(content);
      }
    }
  }

  /// Back to the first line and off again. The story has no seek of its
  /// own, so it stops, rewinds and starts through the one control it has.
  Future<void> _restart() async {
    _fallbackTimer?.cancel();
    if (_audioPath != null) await _safe(() => _audioPlayer.seek(Duration.zero));
    if (!mounted) return;
    setState(() {
      _currentLineIndex = 0;
      _isCompleted = false;
      _isPlaying = false;
    });
    await _togglePlay();
  }

  void _startFallbackTimer(List content) {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      if (_currentLineIndex < content.length - 1) {
        setState(() {
          _currentLineIndex++;
          _scrollToCurrentLine();
        });
      } else {
        timer.cancel();
        _onPlaybackComplete();
      }
    });
  }

  /// The story has been read from beginning to end.
  ///
  /// Reached from the recording finishing, or — for a story with no recording
  /// yet — from the timer walking off the last line. Both are the same event
  /// as far as the child is concerned: the reading is over.
  ///
  /// This is now the only thing that earns the star. The app cannot know
  /// whether a three-year-old understood a story, and no app can; what it can
  /// honestly observe is whether the story was read through, so that is what
  /// the star is for.
  /// The panel for the line being read, if this story has one per line.
  ///
  /// Null for a story without them, which leaves its single cover in place.
  String? get _pictureForLine {
    final raw = widget.storyData['linePictures'];
    if (raw is! List || raw.isEmpty) return null;
    final i = _currentLineIndex.clamp(0, raw.length - 1);
    return raw[i]?.toString();
  }

  bool _panelsWarmed = false;

  /// Fetches every page of the story as it opens, so turning a page shows
  /// the next one at once. On the web each picture is downloaded the first
  /// time it is shown, and a page that arrived only when the voice reached
  /// it showed blank for a moment, mid-sentence.
  void _warmPanels() {
    if (_panelsWarmed) return;
    _panelsWarmed = true;
    final raw = widget.storyData['linePictures'];
    if (raw is! List) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final p in raw.whereType<String>().toSet()) {
        precacheImage(AssetImage(p), context, onError: (_, __) {});
      }
    });
  }

  void _onPlaybackComplete() {
    final content = widget.storyData['content'] as List;
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
      _currentLineIndex = content.isEmpty ? 0 : content.length - 1;
    });
    // The file is reloaded next time rather than resumed: a completed
    // player has nothing left to resume on some platforms, and a poem the
    // child has finished is exactly the one they ask to hear again.
    _audioLoaded = false;
    // Only the first finish is an achievement. A child hearing a poem for
    // the fifth time is learning it, and the modal would cover the words,
    // hand out stars they already have, and send them back to the list.
    if (widget.alreadyDone) return;

    _confettiController.play();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SuccessModal(
        title: AppLocalizations.of(context)!.congratulations,
        subtitle: AppLocalizations.of(context)!.readingFinishedGood,
        score: 50,
        stars: 3,
        primaryLabel: AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop(true);
        },
        secondaryLabel: AppLocalizations.of(context)!.repeat,
        onSecondaryTap: () {
          Navigator.of(dialogContext).pop();
          setState(() {
            _isCompleted = false;
            _currentLineIndex = 0;
          });
          _togglePlay();
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        _audioPlayer.pause();
        _fallbackTimer?.cancel();
        setState(() => _isPlaying = false);
      }
    }
  }

  /// Starts this reading's recording, with a clean player if the first fails.
  ///
  /// A play that does not start is not investigated — the screen drops that
  /// player, builds another and asks again. A player constructed a moment ago
  /// cannot be holding anything the previous screen left behind, so the
  /// second attempt is as clean as a fresh launch.
  /// Has this screen started the recording at all yet?
  ///
  /// The first press has nothing to clean up; every press after it may be
  /// looking at a player parked at the end of the file.
  bool _hasStarted = false;

  Future<bool> _startAudio() async {
    // Only a replay needs a clean player. On the first press the screen's own
    // player has never been used, and throwing it away to build an identical
    // one was the most elaborate path in the file for the plainest case.
    if (_hasStarted) _freshPlayer();
    _hasStarted = true;

    if (await _play(_audioPlayer, _audioPath!)) return true;

    debugPrint('Player would not start; replacing it and retrying.');
    _freshPlayer();
    return _play(_audioPlayer, _audioPath!);
  }

  /// Retires this screen's player and builds another, listening again.
  void _freshPlayer() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _retire(_audioPlayer);
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _confettiController.dispose();
    // Retired with the screen; it belongs to this reading alone.
    _retire(_audioPlayer);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.storyData['content'] as List;
    final imagePath = widget.storyData['image'] as String;
    final List<List<String>> paragraphs = _splitIntoParagraphs(content);
    _warmPanels();

    return StorybookScaffold(
      title: widget.storyTitle,
      // Inside the tap, so the module music can come back — see the poem.
      onClose: () => Navigator.pop(context, _isCompleted),
      progress: _totalDurationMs > 0
          ? _currentPositionMs / _totalDurationMs
          : (content.isEmpty ? 0.0 : (_currentLineIndex + 1) / content.length),
      fill: const Color(0xFFFF9B3D),
      playColor: const Color(0xFFF2453F),
      isPlaying: _isPlaying,
      onPlayPause: _togglePlay,
      onRestart: _restart,
      overlay: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.orange,
            Colors.amber,
            Colors.pink,
            Colors.lightGreen,
            Colors.white
          ],
          numberOfParticles: 25,
          gravity: 0.15,
        ),
      ),
      body: CoralCard(
        inside: const BoxDecoration(color: Color(0xFFF3F9FD)),
        child: _pictureForLine != null
            // A story with a panel per line: the panel is the page, its
            // number and caption drawn into it, so it gets the whole card.
            // A clean cut between panels, never a cross-fade — the captions
            // would print over each other for the length of it.
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      _pictureForLine!,
                      key: ValueKey(_pictureForLine),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Text('📚', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                ),
              )
            // A story with one cover: the cover above, the words below on
            // paper, scrolling with the voice.
            : Column(children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('📚', style: TextStyle(fontSize: 80))),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: ParchmentBox(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildStoryContent(paragraphs, content),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }

  List<List<String>> _splitIntoParagraphs(List content) {
    final paragraphs = <List<String>>[];
    var current = <String>[];
    for (final line in content) {
      final text = line as String;
      if (text.isEmpty) {
        if (current.isNotEmpty) {
          paragraphs.add(List.from(current));
          current = [];
        }
      } else {
        current.add(text);
      }
    }
    if (current.isNotEmpty) paragraphs.add(current);
    return paragraphs;
  }

  List<Widget> _buildStoryContent(
      List<List<String>> paragraphs, List fullContent) {
    final widgets = <Widget>[];
    int lineCounter = 0;

    for (int pi = 0; pi < paragraphs.length; pi++) {
      for (final line in paragraphs[pi]) {
        final lineIndex = lineCounter;
        final isCurrent = lineIndex == _currentLineIndex && _isPlaying;
        lineCounter++;

        widgets.add(AnimatedContainer(
          key: _lineKey(lineIndex),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color:
                isCurrent ? _storyColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            // Always drawn, only the colour changes. A border that
            // appeared only on the current line took 3px of width from it,
            // which is enough to wrap a line that only just fits.
            border: Border.all(
                color: isCurrent
                    ? _storyColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: TextStyle(
              // Was 23/20 — the longest reading in the app in its
              // smallest letters.
              // One size and one weight for every line, so the line
              // being read does not re-wrap and shove the rest down. Its
              // colour and the panel behind it are what mark it.
              fontSize: 26,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: isCurrent ? _storyColor : StorybookScaffold.navy,
              letterSpacing: 0.2,
            ),
            child: Text(
              line,
              // Centred like the poem and the song, and still not justified:
              // justification stretches the spaces to straighten both edges,
              // which is what turned "Nakakita ni Marti iti kalapati" into
              // wide uneven gaps. Centring leaves the spaces even.
              textAlign: TextAlign.center,
            ),
          ),
        ));
      }

      if (pi < paragraphs.length - 1) {
        final emoji = _dividerEmojis[pi % _dividerEmojis.length];
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 50, height: 1, color: _storyColor.withOpacity(0.25)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
            Container(
                width: 50, height: 1, color: _storyColor.withOpacity(0.25)),
          ]),
        ));
      }
    }
    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SONG SCREEN  — Karaoke-style lyrics with audio sync
// ─────────────────────────────────────────────────────────────────────────────
class SongScreen extends StatefulWidget {
  final String songTitle;
  final Map<String, dynamic> songData;

  /// Whether this reading was already finished before this visit.
  ///
  /// A repeat is not a new achievement, so it is not celebrated and
  /// does not end the visit — the child stays where they are and can
  /// play it again.
  final bool alreadyDone;

  const SongScreen({
    super.key,
    this.alreadyDone = false,
    required this.songTitle,
    required this.songData,
  });

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isCompleted = false;
  int _currentLineIndex = 0;
  bool _isPlaying = false;
  bool _wasPlayingBeforePause = false;

  /// Keys for the lyric lines, so the scroll can ask where they actually are.
  final Map<int, GlobalKey> _lineKeys = {};

  GlobalKey _lineKey(int index) =>
      _lineKeys.putIfAbsent(index, () => GlobalKey());

  /// Puts the line being sung in the middle of the screen.
  ///
  /// The song had nothing of the kind. The highlight walked down the lyrics
  /// while the page stayed put, so a child following a long song lost the
  /// line off the bottom and had to drag the page while singing.
  void _scrollToCurrentLine() {
    if (!_isPlaying) return;
    final lineContext = _lineKeys[_currentLineIndex]?.currentContext;
    if (lineContext == null) return;
    Scrollable.ensureVisible(
      lineContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// True once the recording has been handed to the player.
  ///
  /// Without it, resuming meant calling `play(AssetSource(...))` again, which
  /// loads the file afresh and starts it from the beginning — so pausing a
  /// poem and pressing play restarted it, and every seek made while paused
  /// was discarded.
  bool _audioLoaded = false;

  late AnimationController _pulseController;

  /// This screen's own player, built with it and retired with it.
  ///
  /// It used to be one player shared by every poem, story and song for the
  /// life of the app, which meant each screen inherited the last one's
  /// source, position and pending commands. A player per reading makes the
  /// whole class of fault impossible instead of handled.
  ///
  /// Not final: a player that will not start is thrown away and replaced
  /// rather than argued with. See [_startAudio].
  AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  int _totalDurationMs = 0;
  int _currentPositionMs = 0;
  Timer? _fallbackTimer;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  static const Color _karaokeHighlight = Color(0xFF6C63FF);

  List<String> get _lyrics {
    final raw = widget.songData['lyrics'] as List? ?? [];
    return raw.map((e) => e.toString()).toList();
  }

  String? get _audioPath => widget.songData['audioPath'] as String?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _currentPositionMs = pos.inMilliseconds);
        _syncLineFromPosition();
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDurationMs = dur.inMilliseconds);
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) _onPlaybackComplete();
    });
  }

  void _syncLineFromPosition() {
    if (_totalDurationMs <= 0 || _lyrics.isEmpty) return;
    final nonEmpty = _lyrics.where((l) => l.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return;

    final rawTs =
        widget.songData['lineTimestampsMs'] ?? widget.songData['timestampsMs'];
    if (rawTs is List && rawTs.isNotEmpty) {
      final timestamps = rawTs.cast<int>();
      int targetIndex = 0;
      for (int i = 0; i < timestamps.length; i++) {
        if (_currentPositionMs >= timestamps[i]) {
          targetIndex = i;
        } else {
          break;
        }
      }
      final clamped = targetIndex.clamp(0, _lyrics.length - 1);
      if (clamped != _currentLineIndex) {
        setState(() => _currentLineIndex = clamped);
        _scrollToCurrentLine();
      }
      return;
    }

    final target = lineAtFraction(
        lineWeights(_lyrics), _currentPositionMs / _totalDurationMs);
    if (target != _currentLineIndex) {
      setState(() => _currentLineIndex = target);
      _scrollToCurrentLine();
    }
  }

  void _onPlaybackComplete() {
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
      _currentLineIndex = _lyrics.length - 1;
    });
    _pulseController.stop();
    // The file is reloaded next time rather than resumed: a completed
    // player has nothing left to resume on some platforms, and a poem the
    // child has finished is exactly the one they ask to hear again.
    _audioLoaded = false;
    // Only the first finish is an achievement. A child hearing a poem for
    // the fifth time is learning it, and the modal would cover the words,
    // hand out stars they already have, and send them back to the list.
    if (widget.alreadyDone) return;

    _confettiController.play();
    _showCompletionDialog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        _wasPlayingBeforePause = true;
        _audioPlayer.pause();
        _pulseController.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) {
        _audioPlayer.resume();
        _pulseController.repeat(reverse: true);
        _wasPlayingBeforePause = false;
      }
    }
  }

  /// Starts this reading's recording, with a clean player if the first fails.
  ///
  /// A play that does not start is not investigated — the screen drops that
  /// player, builds another and asks again. A player constructed a moment ago
  /// cannot be holding anything the previous screen left behind, so the
  /// second attempt is as clean as a fresh launch.
  /// Has this screen started the recording at all yet?
  ///
  /// The first press has nothing to clean up; every press after it may be
  /// looking at a player parked at the end of the file.
  bool _hasStarted = false;

  Future<bool> _startAudio() async {
    // Only a replay needs a clean player. On the first press the screen's own
    // player has never been used, and throwing it away to build an identical
    // one was the most elaborate path in the file for the plainest case.
    if (_hasStarted) _freshPlayer();
    _hasStarted = true;

    if (await _play(_audioPlayer, _audioPath!)) return true;

    debugPrint('Player would not start; replacing it and retrying.');
    _freshPlayer();
    return _play(_audioPlayer, _audioPath!);
  }

  /// Retires this screen's player and builds another, listening again.
  void _freshPlayer() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _retire(_audioPlayer);
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _confettiController.dispose();
    _fallbackTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    // Retired with the screen. It belongs to this reading and to nothing
    // else, so there is no next poem for it to leave anything behind for.
    _retire(_audioPlayer);
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    setState(() {
      _isPlaying = true;
      _pulseController.repeat(reverse: true);
    });

    if (_isCompleted) {
      setState(() {
        _isCompleted = false;
        _currentLineIndex = 0;
      });
    }

    if (_audioPath != null) {
      try {
        if (_audioLoaded) {
          await _safe(() => _audioPlayer.resume());
        } else {
          if (!await _startAudio()) {
            // The command never came back. The highlight still has to move,
            // or the child is left looking at a pause button doing nothing.
            _startFallbackTimer();
            return;
          }
          _audioLoaded = true;
        }
      } catch (e) {
        debugPrint('Error playing song audio: $e');
        _startFallbackTimer();
      }
    } else {
      _startFallbackTimer();
    }
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    final nonEmpty = _lyrics.where((l) => l.trim().isNotEmpty).toList();
    final secPerLine = nonEmpty.isEmpty ? 3 : max(3, 18 ~/ nonEmpty.length);

    _fallbackTimer = Timer.periodic(Duration(seconds: secPerLine), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      if (_currentLineIndex < _lyrics.length - 1) {
        setState(() => _currentLineIndex++);
      } else {
        timer.cancel();
        _onPlaybackComplete();
      }
    });
  }

  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
      _pulseController.stop();
    });
    _fallbackTimer?.cancel();
    // Pause, not stop. stop() winds the recording back to zero, so what the
    // child pressed as pause was really "start this over". The module music
    // stays down — pausing is part of reading, not the end of it.
    await _safe(() => _audioPlayer.pause());
  }

  /// Back to the first line and off again.
  ///
  /// "Again, from the start" is the thing a three-year-old asks for after a
  /// story, and it was the one thing the bar could not do: seeking a line at
  /// a time back to the beginning is not a gesture they have.
  Future<void> _restart() async {
    await _stopPlayback();
    if (!mounted) return;
    setState(() {
      _currentLineIndex = 0;
      _isCompleted = false;
    });
    if (_audioPath != null) await _safe(() => _audioPlayer.seek(Duration.zero));
    await _startPlayback();
  }

  /// Where line [index] sits in the recording, in milliseconds.
  ///
  /// The middle of the line, measured the same way [_syncLineFromPosition]
  /// measures it. See the poem's copy for why the middle and not the start.

  int _msForLine(int index) {
    final rawTs =
        widget.songData['lineTimestampsMs'] ?? widget.songData['timestampsMs'];
    if (rawTs is List && rawTs.isNotEmpty) {
      final ts = rawTs.cast<int>();
      if (index >= 0 && index < ts.length) {
        final start = ts[index];
        final end = index + 1 < ts.length ? ts[index + 1] : _totalDurationMs;
        return ((start + end) ~/ 2).clamp(0, _totalDurationMs);
      }
    }

    return (fractionAtLine(lineWeights(_lyrics), index) * _totalDurationMs)
        .round()
        .clamp(0, _totalDurationMs);
  }

  Future<void> _seekToLine(int index) async {
    if (_lyrics.isEmpty) return;

    final back = index < _currentLineIndex;
    int target = index.clamp(0, _lyrics.length - 1);

    while (target > 0 &&
        target < _lyrics.length - 1 &&
        _lyrics[target].trim().isEmpty) {
      target += back ? -1 : 1;
    }
    if (_lyrics[target].trim().isEmpty) return;

    setState(() => _currentLineIndex = target);

    if (_audioPath != null && _totalDurationMs > 0) {
      await _safe(
          () => _audioPlayer.seek(Duration(milliseconds: _msForLine(target))));
    } else if (_isPlaying) {
      _fallbackTimer?.cancel();
      _startFallbackTimer();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SuccessModal(
        title: AppLocalizations.of(context)!.congratulations,
        subtitle: AppLocalizations.of(context)!.greatSinging,
        score: 50,
        stars: 3,
        primaryLabel: AppLocalizations.of(context)!.done,
        onPrimaryTap: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop(true);
        },
        secondaryLabel: AppLocalizations.of(context)!.repeat,
        onSecondaryTap: () {
          Navigator.of(dialogContext).pop();
          setState(() {
            _isCompleted = false;
            _currentLineIndex = 0;
          });
          _startPlayback();
        },
      ),
    );
  }

  /// The action in the app's language, falling back to English.
  ///
  /// Takes the raw value so an entry still written as a bare string — an
  /// older song, or one added before the translations existed — keeps
  /// working instead of throwing on a cast.
  String _localizedAction(dynamic raw, String lang) {
    if (raw is Map) {
      return (raw[lang] ?? raw['en'] ?? '').toString();
    }
    return raw?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = _lyrics;
    final tune = widget.songData['tune'] as String;
    final loc = AppLocalizations.of(context)!;
    // The action is an instruction to the child — "clap", "sway" — not part
    // of the song, so unlike the lyrics it follows the app's language.
    final action = _localizedAction(
        widget.songData['action'],
        Provider.of<LanguageProvider>(context, listen: false)
            .currentLanguageCode);

    return StorybookScaffold(
      title: widget.songTitle,
      // Inside the tap — see the poem screen's copy.
      onClose: () => Navigator.pop(context, _isCompleted),
      progress: _totalDurationMs > 0
          ? _currentPositionMs / _totalDurationMs
          : (lyrics.isEmpty ? 0.0 : (_currentLineIndex + 1) / lyrics.length),
      fill: const Color(0xFF8B6CF5),
      playColor: const Color(0xFF7A55E8),
      isPlaying: _isPlaying,
      onPlayPause: _togglePlay,
      onRestart: _restart,
      onBack: () => _seekToLine(_currentLineIndex - 1),
      overlay: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.pink,
            Colors.purple,
            Colors.blue,
            Colors.green,
            Colors.yellow
          ],
          numberOfParticles: 25,
          gravity: 0.15,
        ),
      ),
      body: CoralCard(
        child: CustomPaint(
          painter: const SkyPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: LayoutBuilder(builder: (_, box) {
              final icon = (box.maxHeight * 0.26).clamp(64.0, 150.0);
              return Column(children: [
                // The music, smiling — every song's picture in the sky.
                Image.asset('assets/images/reading_music.webp',
                    width: icon,
                    height: icon,
                    filterQuality: FilterQuality.medium),
                const SizedBox(height: 6),
                Text('${loc.tune}: $tune',
                    textAlign: TextAlign.center,
                    style: StorybookScaffold.fredoka(16, StorybookScaffold.navy,
                        weight: 600)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: const Color(0xFF8DB4E6), width: 2.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.waving_hand_rounded,
                        color: Color(0xFF35B8A8), size: 22),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('${loc.action}: $action',
                          style: StorybookScaffold.fredoka(
                              15, StorybookScaffold.navy,
                              weight: 600)),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                // The words on paper; the only thing that moves.
                Expanded(
                  child: ParchmentBox(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 70),
                      child: Column(
                        children: List.generate(lyrics.length, (index) {
                          final isCurrent =
                              index == _currentLineIndex && _isPlaying;
                          final isPast = index < _currentLineIndex;
                          final line = lyrics[index];
                          if (line.trim().isEmpty) {
                            return const SizedBox(height: 10);
                          }
                          return AnimatedContainer(
                            key: _lineKey(index),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? _karaokeHighlight.withOpacity(0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              // Always drawn, only the colour changes: a
                              // border on the current line alone took width
                              // from it and could re-wrap it.
                              border: Border.all(
                                  color: isCurrent
                                      ? _karaokeHighlight.withOpacity(0.45)
                                      : Colors.transparent,
                                  width: 1.5),
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: StorybookScaffold.fredoka(
                                23,
                                isCurrent
                                    ? AppColors.primary
                                    : (isPast
                                        ? Colors.grey.shade600
                                        : StorybookScaffold.navy),
                                weight: 650,
                              ),
                              child: Text(line, textAlign: TextAlign.center),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
