import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show AudioManager;
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'pressable.dart';

/// A short film of a game being played right — the real screen, a hand,
/// and a voice — shown before a child who cannot read plays it.
///
/// It takes the whole screen and has one control, Laktawan. There is
/// nothing to pause and nothing to scrub: a three-year-old who taps the
/// picture would only stop it. When it ends it closes by itself and the
/// game is there.
///
/// The teacher's guide is the one exception ([pausable]): minutes long and
/// told in words on the picture, it stops at a tap so it can be read.
class HowToVideo {
  HowToVideo._();

  /// Off in the test suite, where a first visit must not open a player.
  static bool autoPlay = true;

  /// How a player is made; a test hands in one that needs no platform.
  @visibleForTesting
  static VideoPlayerController Function(String asset) controllerFor =
      VideoPlayerController.asset;

  /// The teacher's guide to the app: silent, its words in Filipino on the
  /// picture, for every language.
  static const teacherGuide = 'assets/videos/teacher_fil.mp4';

  /// Where each part of [teacherGuide] starts, as the recorder printed
  /// them: a teacher back for one thing goes straight to it.
  static const teacherGuideParts = <(String, Duration)>[
    ('Pagpasok', Duration.zero),
    ('Kasunduan sa Privacy', Duration(milliseconds: 22900)),
    ('PIN', Duration(milliseconds: 38900)),
    ('Talaan ng Guro', Duration(milliseconds: 54900)),
    ('Magpatala ng Mag-aaral', Duration(milliseconds: 96000)),
    ('I-edit ang detalye', Duration(milliseconds: 124100)),
    ('Progreso ng bata', Duration(milliseconds: 141000)),
    ('Pag-aayos', Duration(milliseconds: 170500)),
  ];

  /// The videos recorded in English so far. Every other language, and any
  /// video not recorded in English yet, plays the Filipino one.
  static const Set<String> _inEnglish = {};

  /// The video [stem] (as in `level3`, `kulay`) in the child's language.
  static String assetFor(BuildContext context, String stem) {
    final english = context.read<LanguageProvider>().currentLanguage == 'en' &&
        _inEnglish.contains(stem);
    return 'assets/videos/${stem}_${english ? 'en' : 'fil'}.mp4';
  }

  static bool _showing = false;

  /// Plays [asset] now, and returns when it has closed. With [pausable], a
  /// tap on the picture pauses it and another plays it on; with [parts], a
  /// list of them to jump to sits beside Laktawan.
  static Future<void> show(BuildContext context, String asset,
      {bool pausable = false,
      List<(String, Duration)> parts = const []}) async {
    if (_showing) return;
    _showing = true;
    // Quietened rather than paused: a paused web player needs a touch to
    // start again, which a closing screen does not have. Not waited on for
    // long either way: a music player slow to answer must not hold the film
    // back, or the game that waits for it to close.
    await _briefly(AudioManager.instance.duckMusic());
    try {
      if (!context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) =>
            _HowToPage(asset: asset, pausable: pausable, parts: parts),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ));
    } finally {
      _showing = false;
      await _briefly(AudioManager.instance.unduckMusic());
    }
  }

  static Future<void> _briefly(Future<void> music) =>
      music.timeout(const Duration(milliseconds: 500), onTimeout: () {});

  /// Plays [asset] if the child signed in — or this phone, with nobody
  /// signed in as a child — has not been shown the video [id] before, and
  /// says whether it did. It counts as seen from the moment it starts, so a
  /// child who leaves halfway is not shown it again unasked.
  static Future<bool> showOnce(BuildContext context, String id, String asset,
      {bool pausable = false,
      List<(String, Duration)> parts = const []}) async {
    if (!await claimFirstTime(id, child: childOf(context)) ||
        !context.mounted) {
      return false;
    }
    await show(context, asset, pausable: pausable, parts: parts);
    return true;
  }

  /// The child signed in, whose first visits these are: two children on one
  /// phone each get the film of a game the first time they play it, not
  /// only whoever played it first. Null for the teacher.
  static String? childOf(BuildContext context) {
    try {
      return Provider.of<UserProvider>(context, listen: false).currentStudentId;
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// True, once per [child] (or once per phone without one), for the video
  /// [id] — marking it seen — and false from then on, or always while
  /// [autoPlay] is off.
  static Future<bool> claimFirstTime(String id, {String? child}) async {
    if (!autoPlay) return false;
    final key = child == null ? 'howto_seen_$id' : 'howto_seen_${child}_$id';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return false;
    await prefs.setBool(key, true);
    return true;
  }
}

class _HowToPage extends StatefulWidget {
  const _HowToPage(
      {required this.asset, this.pausable = false, this.parts = const []});

  final String asset;
  final bool pausable;
  final List<(String, Duration)> parts;

  @override
  State<_HowToPage> createState() => _HowToPageState();
}

class _HowToPageState extends State<_HowToPage> with WidgetsBindingObserver {
  late final VideoPlayerController _video =
      HowToVideo.controllerFor(widget.asset);
  bool _closed = false;
  Timer? _overdue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    try {
      await _video.initialize().timeout(const Duration(seconds: 5));
      if (!mounted) return;
      _video.addListener(_onTick);
      await _video.setVolume(1);
      await _video.play();
      if (mounted) setState(() {});
      _watchForStall();
    } catch (e) {
      // No video is never a black screen to be stuck on.
      debugPrint('How-to video unavailable: $e');
      _close();
    }
  }

  /// A video that stalls part way never reaches its end: a little past
  /// what is left of it, the game comes back regardless.
  void _watchForStall() {
    _overdue?.cancel();
    final v = _video.value;
    final left = v.duration > Duration.zero
        ? v.duration - v.position
        : const Duration(seconds: 40);
    _overdue = Timer(left + const Duration(seconds: 3), _close);
  }

  /// Paused by a tap — not merely between loading and playing.
  bool _paused = false;

  /// A tap on the picture, when it can be paused: stop, or play on.
  Future<void> _togglePause() async {
    if (!_video.value.isInitialized || _closed) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      // Paused for as long as it takes to read: not a stall.
      _overdue?.cancel();
      await _video.pause();
    } else {
      await _video.play();
      _watchForStall();
    }
  }

  /// The list of parts. The video waits while it is open, then goes on from
  /// the part chosen — or from where it was, as it was, if none is.
  Future<void> _openParts() async {
    if (!_video.value.isInitialized || _closed) return;
    final wasPlaying = !_paused;
    _overdue?.cancel();
    await _video.pause();
    if (!mounted) return;
    final at = _video.value.position;
    var current = 0;
    for (var i = 0; i < widget.parts.length; i++) {
      if (at >= widget.parts[i].$2) current = i;
    }
    final chosen = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PartsSheet(parts: widget.parts, current: current),
    );
    if (!mounted || _closed) return;
    if (chosen != null) {
      await _video.seekTo(chosen);
      if (!mounted) return;
      setState(() => _paused = false);
    }
    if (chosen != null || wasPlaying) {
      await _video.play();
      _watchForStall();
    }
  }

  void _onTick() {
    final v = _video.value;
    if (v.hasError) {
      _close();
    } else if (v.duration > Duration.zero && v.position >= v.duration) {
      _close();
    }
  }

  /// Away from the app — a call, the home button — the video is over.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _close();
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    _video.pause();
    // The list of parts first, if it is open: this closes the video.
    final nav = Navigator.of(context);
    nav.popUntil((route) => route is! ModalBottomSheetRoute);
    nav.pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overdue?.cancel();
    _video.removeListener(_onTick);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ready = _video.value.isInitialized;
    return Scaffold(
      backgroundColor: const Color(0xFF14122F),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              if (widget.parts.isNotEmpty && ready)
                Semantics(
                  button: true,
                  label: loc.videoParts,
                  child: Pressable(
                    onTap: _openParts,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x40FFFFFF)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.format_list_numbered_rounded,
                            size: 22, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          loc.videoParts,
                          style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ]),
                    ),
                  ),
                ),
              const Spacer(),
              Semantics(
                button: true,
                label: loc.skip,
                child: Pressable(
                  onTap: _close,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0xFFB9B4DA), offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        loc.skip,
                        style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF26215C)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.skip_next_rounded,
                          size: 26, color: Color(0xFF26215C)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              // Taps on the picture go nowhere, unless this one can pause.
              child: widget.pausable
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _togglePause,
                      child: _picture(ready),
                    )
                  : AbsorbPointer(child: _picture(ready)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _picture(bool ready) => Center(
        child: ready
            ? AspectRatio(
                aspectRatio: _video.value.aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(fit: StackFit.expand, children: [
                    VideoPlayer(_video),
                    if (widget.pausable && _paused)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: Icon(Icons.play_circle_fill_rounded,
                              size: 88, color: Colors.white),
                        ),
                      ),
                  ]),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      );
}

/// The parts of the teacher's guide, each with where it starts, the one
/// playing marked. A tap answers with where to go on from.
class _PartsSheet extends StatelessWidget {
  const _PartsSheet({required this.parts, required this.current});

  final List<(String, Duration)> parts;
  final int current;

  static const _violet = AppColors.primary;
  static const _ink = Color(0xFF26215C);

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2DFF2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                loc.videoParts,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
              ),
            ),
          ),
          for (var i = 0; i < parts.length; i++)
            Material(
              color: i == current ? const Color(0xFFEEEDFD) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(parts[i].$2),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == current ? _violet : const Color(0xFFEEEDFD),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: i == current ? Colors.white : _violet),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        parts[i].$1,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: _ink),
                      ),
                    ),
                    Text(
                      _clock(parts[i].$2),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: Color(0xFF8B87AD)),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// The red "▶ Panoorin" pill in a game's header: the video again, whenever
/// the child is lost.
class PanoorinPill extends StatelessWidget {
  const PanoorinPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.watchHowToPlay;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5484D),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0xFFA8282C), offset: Offset(0, 2)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}
