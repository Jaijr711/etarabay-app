import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../main.dart';
import '../widgets/kid_page_header.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/staggered_entrance.dart';
import '../utils/page_transitions.dart';
import '../services/reminder_service.dart';
import '../widgets/background_permission_dialog.dart';
import '../utils/constants.dart';
import 'lessons_screen.dart';
import 'awards_screen.dart';
import 'developer_login_screen.dart';
import 'home_screen.dart';
import '../widgets/design_scale.dart';
import '../widgets/soft_backdrop.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;

  // Read from the installed package itself rather than typed in here —
  // '1.0.5' sat in this file, unread by anything, while pubspec.yaml moved
  // on through several real releases without it. A number nobody can get
  // wrong by forgetting to edit it is the only kind worth showing a
  // teacher trying to tell two APKs apart.
  String _appVersion = '';

  // The hidden developer dashboard's entry point — no visible menu item
  // anywhere, on purpose (see DeveloperLoginScreen). Seven taps on the
  // version row within three seconds of the first tap; a pause resets the
  // count, so absent-minded taps elsewhere on the page never accumulate.
  int _versionTapCount = 0;
  DateTime? _versionTapWindowStart;

  void _onVersionTapped() {
    final now = DateTime.now();
    if (_versionTapWindowStart == null ||
        now.difference(_versionTapWindowStart!) > const Duration(seconds: 3)) {
      _versionTapWindowStart = now;
      _versionTapCount = 1;
      return;
    }
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _versionTapWindowStart = null;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DeveloperLoginScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      // Off by default, unlike music/sound: this one gates an OS permission
      // request, and showing the switch already on when nothing has ever
      // actually been scheduled or granted would be lying to whoever reads
      // it.
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  /// Turns the daily "come back and play" reminder on or off.
  ///
  /// This is the one notification in the app that can reach a phone with
  /// E-Tarabay closed — see [ReminderService]. Turning it on asks the OS for
  /// permission first: a request that is refused (or that does nothing, on
  /// web) has to leave the switch showing off, not showing on for a feature
  /// that silently never fires.
  Future<void> _toggleNotifications(bool value) async {
    if (!value) {
      setState(() => _notificationsEnabled = false);
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setBool('notifications_enabled', false));
      await ReminderService.instance.cancel();
      return;
    }

    final granted = await ReminderService.instance.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.notifPermissionDenied)),
      );
      return;
    }

    setState(() => _notificationsEnabled = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', true);
    if (!mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final childName =
        Provider.of<UserProvider>(context, listen: false).userProfile?.name ??
            '';
    await ReminderService.instance.schedule(
      languageCode: lang.currentLanguageCode,
      childName: childName,
    );
    if (!mounted) return;
    // A granted OS permission is not the same as the reminder actually
    // reaching the lock screen later — several phone brands still kill a
    // closed app's scheduled alarm unless the app is separately whitelisted
    // in that phone's own Battery/Autostart settings. This is the one
    // moment that whitelisting is most relevant, right after asking for it.
    unawaited(showBackgroundPermissionDialog(context));
  }

  Future<void> _toggleMusic(bool value) async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    setState(() {
      _musicEnabled = value;
    });

    await audioManager.setMusicEnabled(value);

    if (value) {
      await audioManager.startBackgroundMusic(AudioManager.homeMusicAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final audioManager = Provider.of<AudioManager>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      extendBody: true,
      appBar: KidPageHeader(
        title: loc.settingsTitle,
        subtitle: loc.kidSubSettings,
        bubble: loc.kidBubbleSettings,
        color: AppColors.navSettings,
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          switch (index) {
            case 0:
              context.pushReplacementFadeThrough(const HomeScreen());
              break;
            case 1:
              context.pushReplacementFadeThrough(const LessonsScreen());
              break;
            case 2:
              context.pushReplacementFadeThrough(const AwardsScreen());
              break;
          }
        },
        items: [
          NavItemData(
              icon: LucideIcons.house,
              label: loc.home,
              color: AppColors.navHome,
              assetPath: 'assets/images/home.webp'),
          NavItemData(
              icon: LucideIcons.book_open,
              label: loc.lessons,
              color: AppColors.navLessons,
              assetPath: 'assets/images/aral.webp'),
          NavItemData(
              icon: LucideIcons.trophy,
              label: loc.awards,
              color: AppColors.navAwards,
              assetPath: 'assets/images/gantimpala.webp'),
          NavItemData(
              icon: LucideIcons.settings,
              label: loc.settings,
              color: AppColors.navSettings,
              assetPath: 'assets/images/setting.webp'),
        ],
      ),
      body: DesignScale(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_settings.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: SoftBackdrop(),
            ),
            ListView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 120,
              ),
              children: [
                StaggeredEntrance(
                  index: 0,
                  child: _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                          child: Row(
                            children: [
                              const _Icon3D('globe'),
                              const SizedBox(width: 12),
                              Text(loc.language, style: _rowTitle),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                          child: _LanguageSwitch(
                            current: languageProvider.currentLanguageCode,
                            onPick: _setLanguage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEntrance(
                  index: 1,
                  child: _SettingsCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          asset: _soundEnabled ? 'speaker' : 'speaker_off',
                          label: loc.sound,
                          value: _soundEnabled,
                          onChanged: (value) {
                            setState(() => _soundEnabled = value);
                            SharedPreferences.getInstance().then(
                              (prefs) => prefs.setBool('sound_enabled', value),
                            );
                          },
                        ),
                        const Divider(
                            height: 0, indent: 66, color: Color(0xFFEFEAF8)),
                        _ToggleRow(
                          asset: 'music',
                          label: loc.music,
                          value: _musicEnabled,
                          onChanged: _toggleMusic,
                        ),
                        const Divider(
                            height: 0, indent: 66, color: Color(0xFFEFEAF8)),
                        _ToggleRow(
                          asset: _notificationsEnabled ? 'bell' : 'bell_off',
                          label: loc.notifications,
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEntrance(
                  index: 2,
                  child: _SettingsCard(
                    child: InkWell(
                      onTap: _onVersionTapped,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const _Icon3D('info'),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(loc.version, style: _rowTitle)),
                            Text(
                              _appVersion,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Bottom Transparent Logo
                StaggeredEntrance(
                  index: 3,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/app_logo-transparent.png',
                            width: 112,
                            height: 112,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (audioManager.isPlaying) ...[
                          const SizedBox(height: 10),
                          _MusicPill(text: loc.backgroundMusicPlaying),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setLanguage(String code) async {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    await provider.setLanguage(code);
    if (!mounted) return;
    setState(() {});
    // The reminders already booked carry the old language's words until
    // they are booked again, which otherwise waited for the next app start.
    if (_notificationsEnabled) {
      final childName =
          Provider.of<UserProvider>(context, listen: false).userProfile?.name ??
              '';
      unawaited(ReminderService.instance
          .schedule(languageCode: code, childName: childName));
    }
  }

  static const TextStyle _rowTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MUSIC PILL
// ─────────────────────────────────────────────────────────────────────────────
class _MusicPill extends StatelessWidget {
  final String text;

  const _MusicPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.music, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CARD, 3D ICON, LANGUAGE SWITCH, TOGGLE ROW
// ─────────────────────────────────────────────────────────────────────────────

/// A white card for one group of settings.
class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    // Plain white under the picture background. A Material surface picked
    // up the theme's tint and came out grey-lilac.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF46288C).withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// One of Settings' 3D pictures (Fluent Emoji 3D, MIT; the licence is in
/// the app's licence list).
class _Icon3D extends StatelessWidget {
  final String name;
  final bool dim;

  const _Icon3D(this.name, {this.dim = false});

  @override
  Widget build(BuildContext context) {
    final picture = Image.asset(
      'assets/images/settings/$name.webp',
      width: 40,
      height: 40,
      excludeFromSemantics: true,
    );
    if (!dim) return picture;
    return Opacity(
      opacity: 0.5,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: picture,
      ),
    );
  }
}

/// English · Filipino · Ilocano as one three-part button: the chosen one is
/// lifted out in white.
class _LanguageSwitch extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;

  const _LanguageSwitch({required this.current, required this.onPick});

  static const _languages = [
    ('en', 'English'),
    ('fil', 'Filipino'),
    ('ilo', 'Ilocano'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final (code, label) in _languages)
            Expanded(
              child: Semantics(
                button: true,
                selected: code == current,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: code == current ? Colors.white : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: code == current
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFF46288C).withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: code == current
                                ? const Color(0xFF5B2BB5)
                                : const Color(0xFF5B5470),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A setting that is on or off: its picture, its name and a switch. The
/// whole row answers a tap, not just the switch.
class _ToggleRow extends StatelessWidget {
  final String asset;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.asset,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            // Sound and the bell have their own "off" pictures; music fades.
            _Icon3D(asset, dim: !value && asset == 'music'),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: _SettingsScreenState._rowTitle),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
