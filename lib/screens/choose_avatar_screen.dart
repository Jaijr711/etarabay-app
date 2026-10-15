import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_header_app_bar.dart';
import '../widgets/question_cloud.dart' show DoodleBackground;

/// The child picks their own picture: twelve animals, each in a coloured
/// ring, as the team drew them.
///
/// Shown once after the first sign-in (straight after the parent makes their
/// PIN, while an adult is still holding the phone), and again whenever the
/// child taps their face on the profile. The choice is saved on the device
/// and on the class record, so the teacher's dashboard shows it too — see
/// [UserProvider.setAvatar].
///
/// Pops with the chosen preset, or null if the child backed out.
class ChooseAvatarScreen extends StatefulWidget {
  /// The first sign-in: there is no back, a picture has to be chosen.
  final bool firstTime;

  const ChooseAvatarScreen({super.key, this.firstTime = false});

  @override
  State<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends State<ChooseAvatarScreen> {
  String? _picked;
  bool _saving = false;

  /// The ring colours, round the grid as in the design.
  static const _rings = [
    Color(0xFF3E5DB8), // dino
    Color(0xFFC0397A), // bunny
    Color(0xFF3E5DB8), // tiger
    Color(0xFF3E5DB8), // koala
    Color(0xFF7A4FC0), // unicorn
    Color(0xFF3E5DB8), // penguin
    Color(0xFF3E5DB8), // lion
    Color(0xFFE8752E), // monkey
    Color(0xFFB23C8E), // giraffe
    Color(0xFF3E5DB8), // panda
    Color(0xFFE8752E), // owl
    Color(0xFF4FA36A), // puppy
  ];

  @override
  void initState() {
    super.initState();
    final current =
        Provider.of<UserProvider>(context, listen: false).userProfile?.avatar;
    if (current != null && isAnimalAvatar(current)) _picked = current;
  }

  Future<void> _save() async {
    final picked = _picked;
    if (picked == null || _saving) return;
    setState(() => _saving = true);
    await Provider.of<UserProvider>(context, listen: false).setAvatar(picked);
    if (!mounted) return;
    Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !widget.firstTime,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomHeaderAppBar(
          title: loc.chooseYourAvatar,
          baseColor: AppColors.secondary,
          showBackButton: !widget.firstTime,
        ),
        body: Stack(children: [
          const Positioned.fill(child: DoodleBackground()),
          SafeArea(
            top: false,
            child: Column(children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: animalAvatars.length,
                  itemBuilder: (_, i) {
                    final preset = animalAvatarPreset(animalAvatars[i]);
                    return _AvatarDisc(
                      preset: preset,
                      ring: _rings[i % _rings.length],
                      selected: preset == _picked,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _picked = preset);
                      },
                    );
                  },
                ),
              ),
              // Shown once something is picked: one more tap to keep it, so a
              // stray touch while scrolling never changes the child's face.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _picked == null
                    ? const SizedBox(height: 24)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                        child: _OkButton(
                          label: loc.okButton,
                          busy: _saving,
                          onTap: _save,
                        ),
                      ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// One animal in its ring; the chosen one swells, glows and gets a tick.
class _AvatarDisc extends StatelessWidget {
  final String preset;
  final Color ring;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarDisc({
    required this.preset,
    required this.ring,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: ring, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xFFFFC542).withOpacity(0.8)
                        : const Color(0xFFDDE3F3),
                    spreadRadius: selected ? 5 : 3,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarAssetForPreset(preset),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2E9E3E),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(LucideIcons.check,
                    color: Colors.white, size: 20),
              ),
            ),
        ]),
      ),
    );
  }
}

/// A glossy green OK, the size of a small hand.
class _OkButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _OkButton(
      {required this.label, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 62,
        constraints: const BoxConstraints(minWidth: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          color: Colors.white,
          boxShadow: [
            const BoxShadow(color: Color(0xFF237A2F), offset: Offset(0, 5)),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6FDB7A), Color(0xFF2E9E3E)],
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white),
                  )
                : const Icon(LucideIcons.check, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 26,
                fontVariations: [FontVariation('wght', 700)],
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(color: Color(0xFF1F6B28), offset: Offset(0, 2)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
