import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_source.dart';

/// The app's short sounds — the ones that answer a tap.
///
/// Kept apart from [AudioManager], which owns the single looping music
/// player: a sound effect borrowing that player would stop the music to play
/// itself, and the music would then have to be started again from nothing.
///
/// This is also the first thing to read the **Sound** switch in Settings.
/// `sound_enabled` was written by both settings screens and read by no code
/// at all, so the switch moved and nothing happened.
class Sfx {
  Sfx._();

  /// A balloon letting go, in Matematika's "Pop the Balloon".
  static const String pop = 'audio/sfx/pop.wav';

  /// The chime for the [n]th star landing on the level-complete card, 1 to 3.
  ///
  /// C, E and G — a major chord taken one note at a time, so one star is the
  /// start of something rather than a lonely note, two stars is consonant
  /// rather than a mistake, and three stars is the phrase finishing. A child
  /// of four is not reading the sentence on that card; this is how they are
  /// told the difference.
  static String starChime(int n) => 'audio/sfx/star_${n.clamp(1, 3)}.wav';

  /// Three players, used in turn. A child popping balloons as fast as they
  /// can tap would otherwise cut each pop off with the next one, and the
  /// board would sound slower than their finger.
  static final List<AudioPlayer> _players = [
    AudioPlayer(playerId: 'sfx0'),
    AudioPlayer(playerId: 'sfx1'),
    AudioPlayer(playerId: 'sfx2'),
  ];
  static int _next = 0;
  static bool _contextConfigured = false;

  /// Every player defaults to requesting *exclusive* Android audio focus on
  /// play — meant for one app owning the only sound on the phone, not for a
  /// second player in the same process. A pop mid-game would win that
  /// request and the music player, having just lost focus at the OS level,
  /// stayed silent afterward: nothing in this app was listening for a focus
  /// change to know it should ask again. This tells every sound-effect
  /// player to mix in instead of contending for focus at all, so a pop can
  /// never take the music down with it.
  static Future<void> _ensureContextConfigured() async {
    if (_contextConfigured) return;
    _contextConfigured = true;
    final ctx = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
        .build();
    for (final player in _players) {
      try {
        await player.setAudioContext(ctx);
      } catch (e) {
        debugPrint('Sfx: could not set audio context: $e');
      }
    }
  }

  /// Under the music, which sits at 0.3. A pop that arrives at full scale is
  /// startling on a phone held close to a small face.
  static const double _volume = 0.7;

  /// Play [asset] and forget about it.
  ///
  /// Returns nothing on purpose: this is called from a tap handler, where a
  /// Future would only ever be dropped, and no sound is ever worth holding up
  /// what the child sees. Every failure is swallowed for the same reason —
  /// silence is a far better outcome here than a broken game.
  static void play(String asset) {
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool('sound_enabled') ?? true)) return;

        await _ensureContextConfigured();

        final player = _players[_next];
        _next = (_next + 1) % _players.length;
        // Keeps the decoded source around between plays, so the second pop
        // is as quick off the mark as the first.
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_volume);
        await player.play(audioSourceFor(asset));
      } catch (e) {
        debugPrint('Sfx: $e');
      }
    }();
  }
}
