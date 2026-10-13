import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/magbasa_content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../utils/page_transitions.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/success_modal.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  KARAOKE GAME SCREEN  — Song selection + Karaoke player
// ─────────────────────────────────────────────────────────────────────────────

class KaraokeGameScreen extends StatefulWidget {
  const KaraokeGameScreen({super.key});

  @override
  State<KaraokeGameScreen> createState() => KaraokeGameScreenState();

  static String progressKey(String songId) => 'karaoke_song_$songId';
}

class KaraokeGameScreenState extends State<KaraokeGameScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  String _currentLang = 'ilo';

  // ── Progress helpers ─────────────────────────────────────────────────────

  bool _isSongCompleted(String songId) {
    return _prefs.getBool(KaraokeGameScreen.progressKey(songId)) ?? false;
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Map<String, Map<String, dynamic>> get _songData {
    MagbasaContent.setLanguage(_currentLang);
    return MagbasaContent.getSongData();
  }

  List<Map<String, dynamic>> get _songActivities {
    MagbasaContent.setLanguage(_currentLang);
    return MagbasaContent.getSongActivities();
  }

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _currentLang = Provider.of<LanguageProvider>(context, listen: false)
        .currentLanguageCode;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.karaokeTitle ?? 'Karaoke',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: CustomBackButton(
          iconColor: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : _buildSongList(),
    );
  }

  Widget _buildSongList() {
    final songs = _songActivities;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final activity = songs[index];
        final id = activity['id'] as String;
        final title = activity['title'] as String;
        final image = activity['image'] as String;
        final completed = _isSongCompleted(id);
        final songDetail = _songData[id];
        final tune = songDetail?['tune'] as String? ?? '';

        return GestureDetector(
          onTap: () async {
            if (songDetail == null) return;
            final result = await context.pushPremium<bool>(
              KaraokePlayerScreen(
                songId: id,
                songTitle: title,
                songData: songDetail,
              ),
            );
            if (result == true && mounted) {
              // Only the first time this song is finished. Singing it again
              // used to pay 3 stars every time, which meant a child could
              // out-earn every other module by replaying one song — and made
              // the "37 of 269" on the dashboard a fraction that could pass
              // its own total. Practising is still encouraged; it just is
              // not paid twice.
              final firstTime = !completed;
              await _prefs.setBool(KaraokeGameScreen.progressKey(id), true);
              setState(() {});
              if (firstTime) _awardStars();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: completed
                    ? [
                        const Color(0xFF2D2D44),
                        const Color(0xFF1A1A2E),
                      ]
                    : [
                        const Color(0xFF252540),
                        const Color(0xFF1A1A2E),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: completed
                    ? AppColors.success.withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFF2D2D44),
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        LucideIcons.music,
                        color: AppColors.secondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tune.isNotEmpty
                            ? '${AppLocalizations.of(context)!.tune}: $tune'
                            : AppLocalizations.of(context)!.listenToSong,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (completed) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                            SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.completed,
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed ? LucideIcons.rotate_ccw : LucideIcons.play,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _awardStars() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.addStars(3);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.mathPoints(3)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KARAOKE PLAYER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class KaraokePlayerScreen extends StatefulWidget {
  final String songId;
  final String songTitle;
  final Map<String, dynamic> songData;

  const KaraokePlayerScreen({
    super.key,
    required this.songId,
    required this.songTitle,
    required this.songData,
  });

  @override
  State<KaraokePlayerScreen> createState() => _KaraokePlayerScreenState();
}

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  late ConfettiController _confettiController;

  bool _isPlaying = false;
  bool _wasPlayingBeforePause = false;
  bool _isCompleted = false;
  bool _isAudioLoaded = false;

  int _currentLineIndex = 0;
  int _totalDurationMs = 0;
  int _currentPositionMs = 0;

  Timer? _fallbackTimer;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  List<String> get _lyrics {
    final raw = widget.songData['lyrics'] as List? ?? [];
    return raw.map((e) => e.toString()).toList();
  }

  String? get _audioPath => widget.songData['audioPath'] as String?;

  static const Color _karaokeBg = Color(0xFF1A1A2E);
  static const Color _karaokeAccent = Color(0xFFFF6584);
  static const Color _karaokeHighlight = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _setupAudioListeners();

    if (_audioPath != null) {
      _preloadAudio();
    } else {
      _isAudioLoaded = true;
    }
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _currentPositionMs = pos.inMilliseconds);
        _syncLineFromPosition();
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _totalDurationMs = dur.inMilliseconds);
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _onPlaybackComplete();
      }
    });
  }

  Future<void> _preloadAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource(_audioPath!));
      setState(() => _isAudioLoaded = true);
    } catch (e) {
      debugPrint('Error preloading audio: $e');
      setState(() => _isAudioLoaded = true);
    }
  }

  void _syncLineFromPosition() {
    if (_totalDurationMs <= 0 || _lyrics.isEmpty) return;
    final nonEmptyLines = _lyrics.where((l) => l.trim().isNotEmpty).toList();
    if (nonEmptyLines.isEmpty) return;

    final rawTs = widget.songData['lineTimestampsMs'] ?? widget.songData['timestampsMs'];
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
      }
      return;
    }

    final msPerLine = _totalDurationMs / nonEmptyLines.length;
    final targetIndex =
        (_currentPositionMs / msPerLine).floor().clamp(0, _lyrics.length - 1);

    if (targetIndex != _currentLineIndex) {
      setState(() => _currentLineIndex = targetIndex);
    }
  }

  void _onPlaybackComplete() {
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
      _currentLineIndex = _lyrics.length - 1;
    });
    _confettiController.play();
    _showCompletionDialog();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    if (!_isAudioLoaded) return;

    setState(() => _isPlaying = true);
    await AudioManager.instance.pauseMusic();

    if (_isCompleted) {
      setState(() {
        _isCompleted = false;
        _currentLineIndex = 0;
      });
    }

    if (_audioPath != null) {
      try {
        await _audioPlayer.play(AssetSource(_audioPath!));
      } catch (e) {
        debugPrint('Error playing audio: $e');
        _startFallbackTimer();
      }
    } else {
      _startFallbackTimer();
    }
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    final nonEmptyLines = _lyrics.where((l) => l.trim().isNotEmpty).toList();
    final secondsPerLine =
        nonEmptyLines.isEmpty ? 3 : max(3, 18 ~/ nonEmptyLines.length);

    _fallbackTimer = Timer.periodic(Duration(seconds: secondsPerLine), (timer) {
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
    setState(() => _isPlaying = false);
    _fallbackTimer?.cancel();
    await _audioPlayer.pause();
    await AudioManager.instance.resumeMusic();
  }

  Future<void> _seekToLine(int index) async {
    if (index < 0 || index >= _lyrics.length) return;
    setState(() => _currentLineIndex = index);

    if (_audioPath != null && _totalDurationMs > 0) {
      final nonEmptyLines = _lyrics.where((l) => l.trim().isNotEmpty).toList();
      final msPerLine = _totalDurationMs / max(1, nonEmptyLines.length);
      final seekPos = Duration(
          milliseconds: (index * msPerLine).round().clamp(0, _totalDurationMs));
      await _audioPlayer.seek(seekPos);
    } else if (_isPlaying) {
      // Restart fallback timer from the new line
      _fallbackTimer?.cancel();
      _startFallbackTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        _wasPlayingBeforePause = true;
        _audioPlayer.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) {
        _audioPlayer.resume();
        _wasPlayingBeforePause = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    _confettiController.dispose();
    AudioManager.instance.resumeMusic();
    super.dispose();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SuccessModal(
        title: AppLocalizations.of(context)!.congratulations,
        subtitle:
            AppLocalizations.of(context)?.greatSinging ?? 'Great singing!',
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _karaokeBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _karaokeBg,
                  const Color(0xFF16213E),
                  _karaokeBg,
                ],
              ),
            ),
          ),

          // Confetti
          Align(
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
                Colors.yellow,
              ],
              numberOfParticles: 25,
              gravity: 0.15,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CustomBackButton(
                        iconColor: Colors.white,
                        onPressed: () => Navigator.pop(context, _isCompleted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_audioPath != null && _totalDurationMs > 0)
                        Text(
                          _formatTime(_currentPositionMs),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Progress bar
                if (_audioPath != null && _totalDurationMs > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _totalDurationMs > 0
                            ? (_currentPositionMs / _totalDurationMs)
                                .clamp(0.0, 1.0)
                            : 0,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_karaokeAccent),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Lyrics area
                Expanded(
                  child: _buildLyricsDisplay(size),
                ),

                // Action hint
                if (widget.songData['action'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _karaokeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _karaokeAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.footprints,
                              color: _karaokeAccent, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${AppLocalizations.of(context)!.action}: ${widget.songData['action']}',
                              style: const TextStyle(
                                color: _karaokeAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Controls
                _buildControls(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsDisplay(Size size) {
    final lyrics = _lyrics;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(lyrics.length, (index) {
            final isCurrent = index == _currentLineIndex;
            final isPast = index < _currentLineIndex;
            final line = lyrics[index];

            // Empty lines get less spacing
            if (line.trim().isEmpty) {
              return const SizedBox(height: 12);
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? _karaokeHighlight.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isCurrent
                    ? Border.all(
                        color: _karaokeHighlight.withOpacity(0.5), width: 1.5)
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: isCurrent ? 26 : (isPast ? 16 : 18),
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? Colors.white
                      : (isPast
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.6)),
                  height: 1.4,
                  shadows: isCurrent
                      ? [
                          Shadow(
                            blurRadius: 12,
                            color: _karaokeHighlight.withOpacity(0.6),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Replay/Repeat
        IconButton(
          onPressed: () {
            setState(() {
              _currentLineIndex = 0;
              _currentPositionMs = 0;
            });
            _audioPlayer.seek(Duration.zero);
            if (!_isPlaying) _togglePlay();
          },
          icon: const Icon(LucideIcons.rotate_ccw, size: 30),
          color: Colors.amber,
          tooltip: 'Replay Song',
        ),
        const SizedBox(width: 16),

        // Previous line
        IconButton(
          onPressed: () => _seekToLine(_currentLineIndex - 1),
          icon: const Icon(LucideIcons.skip_back, size: 36),
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 16),

        // Play/Pause
        GestureDetector(
          onTap: _togglePlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? LucideIcons.pause : LucideIcons.play,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Next line
        IconButton(
          onPressed: () => _seekToLine(_currentLineIndex + 1),
          icon: const Icon(LucideIcons.skip_forward, size: 36),
          color: Colors.white.withOpacity(0.7),
        ),
      ],
    );
  }

  String _formatTime(int ms) {
    final seconds = (ms ~/ 1000) % 60;
    final minutes = (ms ~/ 60000);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
