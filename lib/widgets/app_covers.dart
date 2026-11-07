import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';
import 'fun_dialog.dart';

/// The whole app, covered: by the developers' maintenance switch, or by a
/// minimum version this copy is older than. Drawn by AccountWatcher over
/// every route, so whatever was on screen stays under it — progress and
/// all — and is there again the moment the cover lifts.
///
/// The app's own look: its logo at the top, soft colour behind, and one
/// card in the style of its dialogs.
class _Cover extends StatelessWidget {
  const _Cover({required this.tone, required this.child});

  /// The colour the backdrop leans to.
  final Color tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Opaque to touches as well as to the eye: nothing under it is played
    // while it is up.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Material(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEEF0FF), Color(0xFFFDEFF6)],
            ),
          ),
          child: Stack(children: [
            // Soft rounds of colour, as on the app's other full screens.
            _Blob(
                alignment: const Alignment(-1.3, -0.95),
                size: 260,
                color: tone),
            const _Blob(
                alignment: Alignment(1.4, -0.35),
                size: 200,
                color: Color(0xFFFF99C8)),
            const _Blob(
                alignment: Alignment(-1.2, 1.1),
                size: 230,
                color: Color(0xFFFFC83D)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/images/app_logo-transparent.png',
                          width: 150, height: 150),
                      const SizedBox(height: 6),
                      child,
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(
      {required this.alignment, required this.size, required this.color});

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(0.22),
              color.withOpacity(0),
            ]),
          ),
        ),
      );
}

/// "Sandali lang!" over a child's app while the developers fix something,
/// with the note they wrote. It goes by itself when they switch it off.
class MaintenanceCover extends StatefulWidget {
  const MaintenanceCover({super.key, required this.message});

  /// What the developers wrote; may be empty.
  final String message;

  @override
  State<MaintenanceCover> createState() => _MaintenanceCoverState();
}

class _MaintenanceCoverState extends State<MaintenanceCover>
    with SingleTickerProviderStateMixin {
  // A slowly turning gear and three dots taking turns, so the screen never
  // looks stuck.
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final message = widget.message.trim();
    return _Cover(
      tone: const Color(0xFF7C3AED),
      child: FunMessage(
        picture: RotationTransition(
          turns: _clock,
          child: const FunCoin(
              icon: Icons.settings_rounded, tone: Color(0xFF7C3AED)),
        ),
        title: loc.maintenanceTitle,
        body: Column(children: [
          if (message.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), offset: Offset(0, 3)),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: FunMessage.navy),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _Dots(clock: _clock),
          const SizedBox(height: 10),
          Text(
            loc.maintenanceNote,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, height: 1.35, color: Colors.grey.shade700),
          ),
        ]),
      ),
    );
  }
}

/// Three dots rising in turn.
class _Dots extends StatelessWidget {
  const _Dots({required this.clock});

  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFF7C3AED), Color(0xFFFF6B9A), Color(0xFFFFB020)];
    return AnimatedBuilder(
      animation: clock,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(
                  0,
                  -5 *
                      math.max(0,
                          math.sin((clock.value * 6 - i / 3) * 2 * math.pi))),
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration:
                    BoxDecoration(color: colors[i], shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

/// Over everyone's app, the teacher's too, when the developers no longer
/// allow this version: the one way on is the website's update.
class UpdateRequiredCover extends StatefulWidget {
  const UpdateRequiredCover(
      {super.key, required this.minVersion, required this.installedVersion});

  final String minVersion;
  final String installedVersion;

  @override
  State<UpdateRequiredCover> createState() => _UpdateRequiredCoverState();
}

class _UpdateRequiredCoverState extends State<UpdateRequiredCover> {
  /// Set when the browser would not open: the address, to type in.
  bool _showAddress = false;

  Future<void> _update() async {
    final opened = await UpdateChecker.instance.openUpdatePage(UpdateInfo(
      versionName: widget.minVersion,
      pageUrl: UpdateChecker.updatePageUrl(widget.installedVersion),
    ));
    if (!opened && mounted) setState(() => _showAddress = true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _Cover(
      tone: const Color(0xFF2F7FD6),
      child: FunMessage(
        picture: const FunCoin(
            icon: Icons.system_update_rounded, tone: Color(0xFF2F7FD6)),
        title: loc.updateAvailableTitle,
        message: loc.updateRequiredBody(widget.minVersion),
        body: Column(children: [
          // Where this phone is, and where it has to get to.
          Row(children: [
            Expanded(
              child: _VersionBox(
                  label: loc.updateThisPhone,
                  version: widget.installedVersion,
                  tone: const Color(0xFF9A6200),
                  fill: const Color(0xFFFFF3D6)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded,
                  color: FunMessage.navy, size: 22),
            ),
            Expanded(
              child: _VersionBox(
                  label: loc.updateNeeded,
                  version: widget.minVersion,
                  tone: const Color(0xFF1F7A45),
                  fill: const Color(0xFFE3F6EA)),
            ),
          ]),
          if (_showAddress) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                loc.updateOpenWebsite(UpdateChecker.downloadPageUrl),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FunMessage.navy),
              ),
            ),
          ],
        ]),
        buttons: [
          FunPillButton(
            label: loc.updateDownloadNow,
            icon: Icons.system_update_rounded,
            colors: FunColors.green,
            onTap: _update,
          ),
        ],
      ),
    );
  }
}

class _VersionBox extends StatelessWidget {
  const _VersionBox(
      {required this.label,
      required this.version,
      required this.tone,
      required this.fill});

  final String label;
  final String version;
  final Color tone;
  final Color fill;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: tone)),
          const SizedBox(height: 2),
          Text('v$version',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: tone)),
        ]),
      );
}
