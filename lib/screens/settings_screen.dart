import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../main.dart';
import '../widgets/custom_header_app_bar.dart';
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
      appBar: CustomHeaderAppBar(
        title: loc.settingsTitle,
        baseColor: colorScheme.primary,
        showBackButton: false,
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
              assetPath: 'assets/images/home.png'),
          NavItemData(
              icon: LucideIcons.book_open,
              label: loc.lessons,
              color: AppColors.navLessons,
              assetPath: 'assets/images/aral.png'),
          NavItemData(
              icon: LucideIcons.trophy,
              label: loc.awards,
              color: AppColors.navAwards,
              assetPath: 'assets/images/gantimpala.png'),
          NavItemData(
              icon: LucideIcons.settings,
              label: loc.settings,
              color: AppColors.navSettings,
              assetPath: 'assets/images/setting.png'),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_settings.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 120,
            ),
            children: [
              // Language Section
              StaggeredEntrance(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(loc.language, const Color(0xFF2C7BE5)),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _LanguageTile(
                            label: 'English',
                            code: 'en',
                            isSelected:
                                languageProvider.currentLanguageCode == 'en',
                            onTap: () => _setLanguage('en'),
                          ),
                          const Divider(height: 0, indent: 72),
                          _LanguageTile(
                            label: 'Filipino',
                            code: 'fil',
                            isSelected:
                                languageProvider.currentLanguageCode == 'fil',
                            onTap: () => _setLanguage('fil'),
                          ),
                          const Divider(height: 0, indent: 72),
                          _LanguageTile(
                            label: 'Ilokano',
                            code: 'ilo',
                            isSelected:
                                languageProvider.currentLanguageCode == 'ilo',
                            onTap: () => _setLanguage('ilo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(loc.audio, const Color(0xFF2E9E5B)),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            secondary: const _IconBadge(
                                icon: LucideIcons.volume_2,
                                color: Color(0xFF2E9E5B)),
                            title: Text(loc.sound,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() => _soundEnabled = value);
                              SharedPreferences.getInstance().then(
                                (prefs) =>
                                    prefs.setBool('sound_enabled', value),
                              );
                            },
                          ),
                          const Divider(height: 0, indent: 72),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            secondary: const _IconBadge(
                                icon: LucideIcons.music,
                                color: Color(0xFF2E9E5B)),
                            title: Text(loc.music,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            value: _musicEnabled,
                            onChanged: _toggleMusic,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(loc.notifications, const Color(0xFFF5A623)),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: SwitchListTile(
                        secondary: const _IconBadge(
                            icon: LucideIcons.bell, color: Color(0xFFF5A623)),
                        title: Text(loc.notifications),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredEntrance(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(loc.about, const Color(0xFF7C3AED)),
                    Card.filled(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: _onVersionTapped,
                        leading: const _IconBadge(
                            icon: LucideIcons.info, color: Color(0xFF7C3AED)),
                        title: Text(loc.version),
                        trailing: Text(
                          _appVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bottom Transparent Logo
              StaggeredEntrance(
                index: 4,
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
    );
  }

  Future<void> _setLanguage(String code) async {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    await provider.setLanguage(code);
    setState(() {});
  }

  /// A heading you can find without looking for it.
  ///
  /// These were 13-pixel grey on a blurred photograph — technically present,
  /// practically invisible. The colour is the section's own, so a row and its
  /// heading belong together at a glance.
  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LANGUAGE TILE
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  ({String short, Color color}) get _meta {
    switch (code) {
      case 'fil':
        return (short: 'FIL', color: const Color(0xFFFF6584));
      case 'ilo':
        return (short: 'ILO', color: const Color(0xFFFFB347));
      default:
        return (short: 'EN', color: const Color(0xFF4A90D9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _meta;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              meta.color,
              meta.color.withOpacity(0.75),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: meta.color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            meta.short,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? Icon(LucideIcons.circle_check,
                key: const ValueKey('selected'), color: colorScheme.primary)
            : const SizedBox(key: ValueKey('empty'), width: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ICON BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _IconBadge extends StatelessWidget {
  final IconData icon;

  /// The section's colour. Every badge was the same theme primary before, so
  /// four different settings looked like one long undifferentiated list.
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
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
