import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';
import 'fun_dialog.dart';

/// What the update needs from the phone, kept apart so the cards can be
/// drawn and tested without one.
class UpdateOps {
  const UpdateOps({
    required this.download,
    required this.canInstall,
    required this.openInstallSettings,
    required this.install,
    required this.openWebsite,
  });

  /// The new APK, in the app's own cache. [onPreparing] is called when the
  /// download is done and the APK is being built from a patch.
  final Future<File> Function(
      UpdateInfo update,
      void Function(int received, int total) onProgress,
      Future<void> cancel,
      void Function() onPreparing) download;

  /// Whether Android lets this app hand an APK to its installer.
  final Future<bool> Function() canInstall;

  /// Android's "Install unknown apps" switch for this app.
  final Future<void> Function() openInstallSettings;

  /// Android's own "Update this app?" screen for [path].
  final Future<void> Function(String path) install;

  final Future<bool> Function(UpdateInfo update) openWebsite;

  static const _channel = MethodChannel('etarabay/install');

  static final UpdateOps phone = UpdateOps(
    download: _patchOrWhole,
    canInstall: () async =>
        await _channel.invokeMethod<bool>('canInstall') ?? false,
    openInstallSettings: () => _channel.invokeMethod('openInstallSettings'),
    install: (path) => _channel.invokeMethod('install', {'path': path}),
    openWebsite: UpdateChecker.instance.openUpdatePage,
  );

  /// The small patch first: a few MB, built into the new APK from the one
  /// installed. Anything wrong with it (no patch for this version, an
  /// installed APK that is not the release's, too little space) and the
  /// whole APK is downloaded instead, without the parent having to do a
  /// thing.
  static Future<File> _patchOrWhole(
      UpdateInfo update,
      void Function(int received, int total) onProgress,
      Future<void> cancel,
      void Function() onPreparing) async {
    var cancelled = false;
    unawaited(cancel.then((_) => cancelled = true));
    if (update.patch != null) {
      try {
        final installed = await _channel.invokeMethod<String>('installedApk');
        if (installed != null) {
          return await UpdateChecker.instance.buildFromPatch(update, installed,
              onProgress: onProgress, onPreparing: onPreparing, cancel: cancel);
        }
      } catch (e) {
        if (cancelled) rethrow;
        debugPrint('UpdateFlow: patch not used: $e');
      }
    }
    return UpdateChecker.instance
        .downloadApk(update, onProgress: onProgress, cancel: cancel);
  }
}

enum UpdateStage { downloading, preparing, needsPermission, ready, failed }

/// A size for a parent: "1.8 MB" for a small patch (never "0 MB"), whole
/// numbers from 10 MB up.
String megabytes(int bytes) {
  final mb = bytes / 1048576;
  return mb < 10 ? '${mb.toStringAsFixed(1)} MB' : '${mb.round()} MB';
}

/// The update, done inside the app: download into its own cache, one
/// permission the first time, then Android's installer. Nothing is left in
/// Downloads, where the browser used to leave 117 MB at every update.
class UpdateFlow {
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Runs the update for [update]. Where the app cannot install (the web,
  /// or a release with no APK) it opens the website instead, as before.
  static Future<void> start(BuildContext context, UpdateInfo update,
      {UpdateOps? ops}) async {
    final o = ops ?? UpdateOps.phone;
    if (!supported || update.apkUrl == null) {
      await o.openWebsite(update);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateFlowDialog(update: update, ops: o),
    );
  }
}

class UpdateFlowDialog extends StatefulWidget {
  const UpdateFlowDialog({
    super.key,
    required this.update,
    required this.ops,
    @visibleForTesting this.debugStage,
    @visibleForTesting this.debugProgress,
  });

  final UpdateInfo update;
  final UpdateOps ops;

  /// For previews: shows one card as it is, with nothing started.
  final UpdateStage? debugStage;
  final double? debugProgress;

  @override
  State<UpdateFlowDialog> createState() => _UpdateFlowDialogState();
}

class _UpdateFlowDialogState extends State<UpdateFlowDialog>
    with WidgetsBindingObserver {
  UpdateStage _stage = UpdateStage.downloading;
  int _received = 0;
  int _total = 0;
  Completer<void> _cancel = Completer<void>();
  File? _file;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final debug = widget.debugStage;
    if (debug != null) {
      _stage = debug;
      _total = widget.update.downloadSize;
      _received = (_total * (widget.debugProgress ?? 0)).round();
    } else {
      _begin();
    }
  }

  /// The permission first, then the download. The other way round, a
  /// parent downloaded 117 MB, was sent to Android's settings, and came
  /// back to a restarted app (some Androids restart it when that switch
  /// changes) that downloaded it all again.
  Future<void> _begin() async {
    if (!await _allowed()) {
      if (mounted) setState(() => _stage = UpdateStage.needsPermission);
      return;
    }
    await _download();
  }

  Future<bool> _allowed() async {
    try {
      return await widget.ops.canInstall();
    } catch (_) {
      return true; // Older Androids ask in the installer itself.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_cancel.isCompleted) _cancel.complete();
    super.dispose();
  }

  /// Back from Android's settings: if the switch is now on, go on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _stage == UpdateStage.needsPermission &&
        widget.debugStage == null) {
      _file == null ? _begin() : _installIfAllowed();
    }
  }

  Future<void> _download() async {
    setState(() {
      _stage = UpdateStage.downloading;
      _received = 0;
      _total = widget.update.downloadSize;
    });
    _cancel = Completer<void>();
    try {
      _file = await widget.ops.download(
          widget.update,
          (r, t) {
            if (!mounted) return;
            setState(() {
              _received = r;
              if (t > 0) _total = t;
            });
          },
          _cancel.future,
          () {
            if (mounted) setState(() => _stage = UpdateStage.preparing);
          });
    } catch (e) {
      debugPrint('UpdateFlow: $e');
      if (!mounted || _cancel.isCompleted) return;
      setState(() => _stage = UpdateStage.failed);
      return;
    }
    if (!mounted) return;
    await _installIfAllowed();
  }

  Future<void> _installIfAllowed() async {
    final file = _file;
    if (file == null) return;
    final allowed = await _allowed();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _stage = UpdateStage.needsPermission);
      return;
    }
    setState(() => _stage = UpdateStage.ready);
    try {
      await widget.ops.install(file.path);
    } catch (e) {
      debugPrint('UpdateFlow: install: $e');
      if (mounted) setState(() => _stage = UpdateStage.failed);
    }
  }

  void _close() {
    if (!_cancel.isCompleted) _cancel.complete();
    Navigator.of(context).pop();
  }

  static String _mb(int bytes) => megabytes(bytes);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: FunDialog(
          child: switch (_stage) {
        UpdateStage.downloading => FunMessage(
            picture: const FunCoin(
                icon: Icons.downloading_rounded, tone: Color(0xFF2F7FD6)),
            title: loc.updateDownloadingTitle,
            message: loc.updateDownloadingBody,
            body: _Progress(
              value: _total > 0 ? _received / _total : null,
              label: _total > 0
                  ? loc.updateProgress('${(_received * 100 / _total).floor()}',
                      _mb(_received), _mb(_total))
                  : _mb(_received),
            ),
            buttons: [
              FunPillButton(
                label: loc.updateCancel,
                colors: FunColors.grey,
                onTap: _close,
              ),
            ],
          ),
        UpdateStage.preparing => FunMessage(
            picture: const FunCoin(
                icon: Icons.build_circle_rounded, tone: Color(0xFF2F7FD6)),
            title: loc.updatePreparingTitle,
            message: loc.updatePreparingBody,
            body: const _Progress(value: null, label: ''),
          ),
        UpdateStage.needsPermission => FunMessage(
            picture: const FunCoin(
                icon: Icons.verified_user_rounded, tone: Color(0xFF7C3AED)),
            title: loc.updatePermissionTitle,
            message: loc.updatePermissionBody,
            buttonsInRow: false,
            buttons: [
              FunPillButton(
                label: loc.updateOpenSettings,
                icon: Icons.settings_rounded,
                colors: FunColors.green,
                onTap: () => widget.ops.openInstallSettings(),
              ),
              FunPillButton(
                label: loc.updateCancel,
                colors: FunColors.grey,
                onTap: _close,
              ),
            ],
          ),
        UpdateStage.ready => FunMessage(
            picture: const FunCoin(
                icon: Icons.system_update_rounded, tone: Color(0xFF2E9E5B)),
            title: loc.updateReadyTitle,
            message: loc.updateReadyBody,
            buttons: [
              FunPillButton(
                label: loc.updateClose,
                colors: FunColors.grey,
                onTap: _close,
              ),
              FunPillButton(
                label: loc.updateInstallAgain,
                colors: FunColors.green,
                onTap: _installIfAllowed,
              ),
            ],
          ),
        UpdateStage.failed => FunMessage(
            picture: const FunCoin(
                icon: Icons.wifi_off_rounded, tone: Color(0xFFE5484D)),
            title: loc.updateFailedTitle,
            message: loc.updateFailedBody,
            buttonsInRow: false,
            buttons: [
              FunPillButton(
                label: loc.updateRetry,
                icon: Icons.refresh_rounded,
                colors: FunColors.green,
                onTap: _download,
              ),
              FunPillButton(
                label: loc.updateWebsite,
                colors: FunColors.blue,
                onTap: () {
                  _close();
                  widget.ops.openWebsite(widget.update);
                },
              ),
              FunPillButton(
                label: loc.updateClose,
                colors: FunColors.grey,
                onTap: _close,
              ),
            ],
          ),
      }),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.label});
  final double? value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 16,
            backgroundColor: Colors.white,
            color: const Color(0xFF2E9E5B),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FunMessage.navy)),
      ]);
}
