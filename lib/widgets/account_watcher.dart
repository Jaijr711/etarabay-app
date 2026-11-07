import 'dart:ui';

import 'package:flutter/material.dart';
import 'fun_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show AudioManager;
import '../models/certificate_model.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../screens/certificates_screen.dart';
import '../services/developer_service.dart';
import '../utils/page_transitions.dart';
import 'app_covers.dart';
import 'certificate_earned_popup.dart';

/// Tells the child, wherever they are, that their account is gone.
///
/// This used to be copied into each screen, and it had reached four of the
/// seven modules: a child deleted mid-game in Kulay-Saya or Tandaan Mo! went
/// on playing, earning stars into a record that no longer existed. The four
/// that did check only popped back to the home screen, and it was the home
/// screen's own copy that put the message up — so the child was thrown out of
/// their game a moment before being told why.
///
/// One watcher over the whole app instead. It sits above every route, so the
/// message arrives on top of whatever the child is doing.
class AccountWatcher extends StatefulWidget {
  const AccountWatcher({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  /// The app's navigator. The dialog needs a context below the Navigator, and
  /// this widget sits above it.
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AccountWatcher> createState() => _AccountWatcherState();
}

class _AccountWatcherState extends State<AccountWatcher> {
  bool _showing = false;
  bool _showingAdminMessage = false;
  bool _showingCertificate = false;

  /// Whether the music is quietened for a cover (see [_coverMusic]).
  bool _musicDucked = false;

  /// Quiet under a cover, back once it lifts.
  void _coverMusic(bool covered) {
    if (covered == _musicDucked) return;
    _musicDucked = covered;
    final music = AudioManager.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      (covered ? music.duckMusic() : music.unduckMusic())
          .catchError((Object e) => debugPrint('Cover music: $e'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // Covers over the whole app — an update it can no longer do without,
    // first, then the developers' maintenance. Nothing else is announced
    // under one: it would only be waiting there when the cover lifts.
    final Widget? cover = userProvider.mustUpdate
        ? UpdateRequiredCover(
            minVersion: userProvider.minVersion!,
            installedVersion: userProvider.installedVersion!)
        : userProvider.blockedByMaintenance
            ? MaintenanceCover(message: userProvider.maintenanceMessage)
            : null;
    _coverMusic(cover != null);
    // Always this Stack, the app first in it: a cover coming or going must
    // never move the app in the tree, or every screen would be rebuilt
    // from nothing and the child's place lost.
    final covered = Stack(children: [
      widget.child,
      if (cover != null) Positioned.fill(child: cover),
    ]);
    if (cover != null) return covered;

    if ((userProvider.isAccountDeleted ||
            userProvider.isDisabledByDev ||
            userProvider.forceLogoutPending) &&
        !_showing) {
      _showing = true;
      final reason = userProvider.isDisabledByDev
          ? _LogoutReason.paused
          : userProvider.forceLogoutPending
              ? _LogoutReason.forced
              : _LogoutReason.deleted;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tell(reason));
    }

    final message = userProvider.pendingAdminMessage;
    if (message != null && !_showingAdminMessage && !_showing) {
      _showingAdminMessage = true;
      final category = userProvider.pendingAdminMessageCategory;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAdminMessage(message, category));
    }

    // The certificate is earned wherever the last thing was done — claiming
    // the twelfth badge, finishing the last lesson — so it is announced from
    // here, over whatever screen that was.
    if (userProvider.certificateCelebrationPending &&
        !_showingCertificate &&
        !_showing &&
        !_showingAdminMessage) {
      _showingCertificate = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _celebrateCertificate());
    }

    return covered;
  }

  Future<void> _celebrateCertificate() async {
    final navigator = widget.navigatorKey.currentState;
    final dialogContext = widget.navigatorKey.currentContext;
    if (navigator == null || dialogContext == null) {
      _showingCertificate = false;
      return;
    }
    final provider = context.read<UserProvider>();
    final view = await showCertificateEarnedPopup(dialogContext,
        name: provider.userProfile?.name ?? '');
    if (!mounted) return;
    await provider.markCertificateCelebrated();
    _showingCertificate = false;
    if (view && mounted) {
      final lang = context.read<LanguageProvider>().currentLanguageCode;
      await navigator.pushPremium(CertificateDetailScreen(
        certificate: allCertificates['e_tarabay_graduate']!,
        langCode: lang,
      ));
    }
  }

  /// The developer dashboard's note to this student, shown over whatever
  /// they're doing — centered and over a blurred backdrop, closer to a
  /// system alert than an in-app dialog, since it can arrive from outside
  /// anything happening on screen.
  Future<void> _showAdminMessage(String message, String category) async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      _showingAdminMessage = false;
      return;
    }

    await showGeneralDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                  ),
                  child:
                      _AdminMessageCard(message: message, category: category),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    await context.read<UserProvider>().acknowledgeAdminMessage();
    _showingAdminMessage = false;
  }

  Future<void> _tell(_LogoutReason reason) async {
    final navigator = widget.navigatorKey.currentState;
    final dialogContext = widget.navigatorKey.currentContext;
    if (navigator == null || dialogContext == null) {
      // No navigator yet — try again on the next frame rather than losing the
      // message entirely.
      _showing = false;
      return;
    }
    final loc = AppLocalizations.of(dialogContext)!;

    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: FunDialog(
          child: FunMessage(
            frame: FunFrame.coral,
            picture: const FunCoin(
                icon: LucideIcons.triangle_alert, tone: Color(0xFFF08A24)),
            // The developer dashboard's kill switch and one-time kick both
            // reuse this same dialog and logout — each ends with "you're
            // signed out, this device knows nothing more about it" — but
            // never with the deleted-account wording, which promises a
            // teacher can help and isn't true for either of the other two.
            message: switch (reason) {
              _LogoutReason.paused => loc.accountPaused,
              _LogoutReason.forced => loc.forceLoggedOut,
              _LogoutReason.deleted => loc.accessExpired,
            },
            buttons: [
              FunPillButton(
                label: loc.okButton,
                colors: FunColors.purple,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    // Everything local goes with the account, so no progress carries over to
    // whoever signs in on this device next.
    await context.read<UserProvider>().logoutAndClearData();
    navigator.pushNamedAndRemoveUntil('/', (route) => false);
    // Reset for whoever signs in on this device next — otherwise a second
    // child sharing this device could never see this dialog again, since
    // it had already fired once for the first child's account.
    _showing = false;
  }
}

enum _LogoutReason { deleted, paused, forced }

/// The card an admin message is shown in — deliberately plainer than a
/// themed AlertDialog, so it reads as coming from outside the app rather
/// than as one more thing the child was already doing.
class _AdminMessageCard extends StatelessWidget {
  const _AdminMessageCard({required this.message, required this.category});

  final String message;
  final String category;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final color = AdminMessageCategory.colorFor(category);
    // The same card as every other message to the child, in the colour of
    // the message's kind.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Material(
          color: Colors.transparent,
          child: FunMessage(
            picture: FunCoin(
                icon: AdminMessageCategory.iconFor(category), tone: color),
            message: message,
            buttons: [
              FunPillButton(
                label: loc.okButton,
                colors: FunColors.of(color),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
