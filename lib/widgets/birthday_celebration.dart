import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/audio_source.dart';
import 'birthday_cake.dart';
import 'firework.dart';
import 'pop_balloon.dart';

/// Shows a full-screen, centered birthday celebration overlay with confetti,
/// floating balloons and an animated "Happy Birthday [name]!" greeting.
///
/// Used on both the student home screen and the teacher dashboard so the
/// celebration appears the moment a birthday child logs in.
Future<void> showBirthdayCelebration(
  BuildContext context, {
  required String name,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'birthday',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, animation, ___) =>
        BirthdayCelebrationOverlay(name: name, animation: animation),
    // [animation] runs 0 to 1 opening and reverses 1 to 0 on the way out —
    // Navigator.pop plays it backwards automatically. The card's own bounce
    // used to be a one-shot flutter_animate effect that could not join that
    // reverse: it played once on the way in and then simply held still,
    // so tapping OK left the card sitting at full size while everything
    // behind it faded, a flat fade where the entrance had been a bounce.
    // Handing the same [animation] to the overlay lets the card ride it
    // directly, so shrinking away is the entrance played backwards rather
    // than a different, plainer exit.
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

class BirthdayCelebrationOverlay extends StatefulWidget {
  final String name;

  /// The dialog's own open/close animation, 0 to 1. Optional so the widget
  /// still renders — fully open, no ride to give the card — wherever it is
  /// built outside a dialog, such as the design previews.
  final Animation<double>? animation;

  const BirthdayCelebrationOverlay(
      {super.key, required this.name, this.animation});

  @override
  State<BirthdayCelebrationOverlay> createState() =>
      _BirthdayCelebrationOverlayState();
}

class _BirthdayCelebrationOverlayState
    extends State<BirthdayCelebrationOverlay> {
  late final ConfettiController _confetti;
  final AudioPlayer _music = AudioPlayer();

  /// Guards against popping twice — the song finishing and a tap on OK can
  /// land in the same frame, and Navigator does not need to be asked twice.
  bool _dismissed = false;

  static const _balloonColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFB347),
    Color(0xFF6C63FF),
    Color(0xFFFF99C8),
    Color(0xFF95D9C3),
  ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 8));
    _confetti.play();
    // The card closes itself once the song runs out, on top of the OK
    // button and the backdrop tap — a child who does not tap anything
    // still gets the card cleared away instead of the greeting sitting
    // there silently forever.
    _music.onPlayerComplete.listen((_) => _dismiss());
    _playMusic();
  }

  /// The one thing allowed to be heard while this card is up.
  ///
  /// Not ducked — paused. Everywhere else in the app that talks over the
  /// module's own background track turns it down and brings it back, because
  /// two things are meant to be heard at once there. Here, nothing else is
  /// meant to be heard at all: the birthday song is the whole point, so the
  /// module track stops rather than plays underneath it.
  Future<void> _playMusic() async {
    AudioManager.instance.pauseMusic();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('sound_enabled') ?? true)) return;
      if (!mounted) return;

      await _music.play(audioSourceFor('audio/birthday/happy_birthday.mp3'));
    } catch (e) {
      debugPrint('Birthday music: $e');
    }
  }

  /// How this card closes: the OK button, a tap on the backdrop, or the
  /// song running out on its own.
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _music.stop();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _music.dispose();
    // The module's own track was paused, not stopped, so it picks up again
    // from the same place rather than starting over — and this runs however
    // the card actually closed, including a system back gesture that never
    // touched _dismiss.
    AudioManager.instance.resumeMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    // Tapping the dark backdrop outside the card dismisses it — that comes
    // free from barrierDismissible on the dialog itself. Nothing here
    // catches taps beyond that, so a tap lands on the barrier only where
    // this Stack's own content does not claim it first: the card below
    // wraps itself in its own GestureDetector precisely so a tap on the
    // cake or the greeting is claimed there and never falls through to the
    // barrier — every tap on screen used to dismiss the card, cake and
    // greeting included, when this whole Stack carried one onTap that
    // called _dismiss no matter where the finger landed.
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti raining from the top center.
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: true,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.18,
            emissionFrequency: 0.04,
            colors: _balloonColors,
          ),
        ),

        // Bursts of light behind everything else — the confetti and the
        // balloons are the party in the room; this is the sky above it.
        ..._buildFireworks(size),

        // Floating balloons behind the card.
        ..._buildBalloons(size),

        // Centered greeting card.
        Center(
          child: _CardEntrance(
            animation: widget.animation,
            // Opaque and otherwise a no-op: without this, a tap anywhere
            // on the card — the cake, the greeting, the padding around
            // them — fell through to the dialog's barrier underneath and
            // dismissed the card, the same as tapping the dark backdrop
            // outside it. Claiming the tap here stops it going any
            // further; only a tap that actually lands outside the card
            // reaches the barrier now.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFFFF3F9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The greeting, first — the name is what this card exists
                    // to say, so it is the first thing read rather than a
                    // caption sitting under the picture.
                    //
                    // Drawn rather than set in 'FuzzyBubbles': nothing in this
                    // app ever registers that font — no fonts: entry in
                    // pubspec.yaml, and google_fonts is never asked to fetch it
                    // either — so it silently rendered in the platform default
                    // the whole time. Reaching for google_fonts properly would
                    // fix the name but not the habit: that package downloads
                    // the face over the network on first use, and a birthday
                    // that only ever arrives online is worse than one that
                    // isn't pretty enough — see the offline-first rule the rest
                    // of the app is held to. A gradient fill, a soft shadow and
                    // real weight get most of "festive" out of the system font
                    // instead, for nothing over the wire.
                    //
                    // This used to be an AnimatedTextKit / ScaleAnimatedText,
                    // which is built for cycling through a *list* of lines —
                    // each one scales up, then scales back down to nothing and
                    // stays gone, ready for the next line. With only one line
                    // and isRepeatingAnimation left off, "stays gone" is
                    // exactly what happened: the whole animation ran out
                    // before a child had time to read their own name.
                    //
                    // A plain fill, not a ShaderMask gradient: tried once,
                    // it painted the whole line as solid blocks instead of
                    // letters — a gradient mask needs its child rendered to
                    // an offscreen layer first, and something in how the
                    // system font's glyphs get rasterised here did not
                    // survive that trip. A readable pink is a better bet
                    // than an unreadable gradient, and this app's own
                    // pink (the same one the confetti and the balloons
                    // already use) is not a plain choice.
                    Text(
                      loc.birthdayGreeting(widget.name),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        height: 1.2,
                        color: Color(0xFFFF6584),
                        shadows: [
                          Shadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    )
                        // Fade only, not scale: the whole card now bounces
                        // in via _CardEntrance, and this greeting sits
                        // inside it. Scaling it a second time on the same
                        // curve would multiply the two overshoots together
                        // and the text would bounce noticeably harder than
                        // the card carrying it.
                        .animate()
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 18),

                    // The cake, bigger now that it is the second thing on the
                    // card rather than sharing the top with the title chip.
                    const BirthdayCake(size: 168)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: 0,
                          end: -10,
                          duration: 1100.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 22),

                    // Dismiss button.
                    FilledButton.tonal(
                      onPressed: _dismiss,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        loc.okButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // After the card, not before — the balloons allowed to sail
        // across the front of it rather than stay behind with the rest.
        ..._buildFrontBalloons(size),
      ],
    );
  }

  List<Widget> _buildBalloons(Size size) {
    final rnd = math.Random(7);
    // Each balloon gets its own diagonal for the whole rise, not a quick
    // wobble on top of a straight climb — some drift hard left, some hard
    // right, one nearly straight, so six balloons going up together do not
    // read as one balloon repeated six times. Signs alternate and
    // magnitudes vary so no two neighbours drift the same way by the same
    // amount.
    const drifts = [-95.0, 60.0, -35.0, 110.0, -70.0, 30.0];
    return List.generate(6, (i) {
      final left = size.width * (0.06 + 0.15 * i) + rnd.nextDouble() * 14;
      final delay = (i * 260).ms;
      // A spread of rise times, not one shared 6000ms — otherwise every
      // balloon would crest the top edge on the same beat, which reads as
      // one timed event rather than balloons simply floating.
      final rise = (5200 + rnd.nextInt(1800)).ms;
      return Positioned(
        // Bigger than before (72 against 60) — big enough to read from
        // across the card, not just at the edges of the screen.
        left: left.clamp(8.0, size.width - 80),
        bottom: -120,
        // The same drawn balloon "Pop the Balloon" uses, minus the number —
        // there is nothing to count here. Was a flat rounded rectangle with
        // a straight line for a string; this one has the egg-shaped body,
        // the shaded rubber and the curled string that make the popped
        // version read as a balloon in the first place.
        child: PopBalloon(
                color: _balloonColors[i % _balloonColors.length], size: 72)
            .animate(onPlay: (c) => c.repeat())
            .moveY(
              begin: 0,
              end: -(size.height + 160),
              duration: rise,
              delay: delay,
              curve: Curves.easeIn,
            )
            .moveX(
              // The full diagonal runs over the same span as the climb —
              // moveX used to get its own short 1500ms, which only ever
              // wobbled the first quarter of a straight-up flight.
              begin: 0,
              end: drifts[i],
              duration: rise,
              delay: delay,
              curve: Curves.easeInOut,
            ),
      );
    });
  }

  /// One or more balloons from the same rising group, except drawn after
  /// the card so they drift past the front of it instead of staying behind
  /// with the rest — the difference between a flat sheet of decoration and
  /// a scene with something happening in front of and behind the thing a
  /// child is actually reading.
  ///
  /// This used to be exactly one, on its own separate horizontal path,
  /// which read as one fixed prop sliding past rather than a balloon that
  /// belonged with its siblings. Each one now rises the same way the six
  /// behind the card do — same off-screen start, same easeIn climb, same
  /// sideways drift, its own random size — just painted after the card
  /// instead of before it. How many pass in front is itself random each
  /// time the card opens, one to three, rather than always exactly one.
  ///
  /// Placed after the card in the Stack, which is what puts it on top;
  /// everything before the card in painting order stays behind it exactly
  /// as before.
  List<Widget> _buildFrontBalloons(Size size) {
    final rnd = math.Random(41);
    final count = 1 + rnd.nextInt(3);
    return List.generate(count, (i) {
      // A size of its own each time rather than a fixed 92 — a balloon at
      // the same size on every visit reads as a prop placed there on
      // purpose, not as one more balloon that simply happens to be closer.
      final balloonSize = 56.0 + rnd.nextDouble() * 40;
      final left = size.width * 0.2 + rnd.nextDouble() * size.width * 0.6;
      final rise = (5200 + rnd.nextInt(1800)).ms;
      final drift = -60.0 + rnd.nextDouble() * 160;
      // Staggered rather than all starting together, so two or three in
      // front of the card do not rise as one wide block.
      final delay = (i * 900 + rnd.nextInt(600)).ms;
      return Positioned(
        left: left.clamp(8.0, size.width - balloonSize * 1.12 - 8),
        bottom: -120,
        child: PopBalloon(
                color: _balloonColors[(4 + i) % _balloonColors.length],
                size: balloonSize)
            .animate(onPlay: (c) => c.repeat())
            .moveY(
              begin: 0,
              end: -(size.height + 160),
              duration: rise,
              delay: delay,
              curve: Curves.easeIn,
            )
            .moveX(
              begin: 0,
              end: drift,
              duration: rise,
              delay: delay,
              curve: Curves.easeInOut,
            ),
      );
    });
  }

  /// A handful of fireworks lighting up behind the card. Placed before the
  /// balloons and the card in the Stack, so they sit at the back of the
  /// scene rather than over anything a child needs to read.
  List<Widget> _buildFireworks(Size size) {
    final rnd = math.Random(19);
    const positions = [
      Alignment(-0.7, -0.75),
      Alignment(0.75, -0.55),
      Alignment(-0.35, -0.3),
    ];
    return List.generate(positions.length, (i) {
      return Align(
        alignment: positions[i],
        child: Firework(
          color: _balloonColors[i % _balloonColors.length],
          size: 120 + rnd.nextDouble() * 60,
          period: Duration(milliseconds: 1500 + rnd.nextInt(900)),
          // The first one starts the instant the card does, so there is
          // never a stretch of empty sky while a child is still looking —
          // the rest trail in shortly after rather than all at once.
          delay: Duration(milliseconds: i == 0 ? 0 : rnd.nextInt(450)),
        ),
      );
    });
  }
}

/// Rides the dialog's own open/close animation, so the card's pop-in has a
/// pop-out to match — a genuine reverse, not a different, plainer exit
/// playing instead.
///
/// [animation] runs 0 to 1 opening and is the very same value played 1 to 0
/// when the dialog is dismissed, which is what makes this correct in a way a
/// one-shot entrance effect cannot be: there is nothing to separately wire up
/// for the close, because closing is this animation running backwards.
/// Scale only, on purpose — [showBirthdayCelebration]'s own transitionBuilder
/// already fades the confetti, balloons and this card together on the same
/// [animation]; fading the card a second time in here would multiply the two
/// opacities together and make it vanish faster than everything around it.
///
/// The two directions get their own curve. [Curves.easeOutBack] is what
/// makes the entrance bounce — it overshoots past 1 before settling — and
/// wanting that same overshoot on the way out would mean the card grows
/// slightly *before* shrinking away, which reads as a stutter rather than a
/// bounce. [Curves.easeIn] on the way out just shrinks, smoothly.
class _CardEntrance extends StatelessWidget {
  final Animation<double>? animation;
  final Widget child;

  const _CardEntrance({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final anim = animation;
    // No dialog animation to ride — e.g. a design preview that builds this
    // overlay directly. Full size, no motion, rather than erroring.
    if (anim == null) return child;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
      child: child,
    );
  }
}
