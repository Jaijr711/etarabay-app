import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/app_version.dart';
import '../services/auth_service.dart';
import '../services/developer_roster.dart';
import '../services/developer_service.dart';

/// Every module a student can be locked out of, keyed exactly as
/// UserProvider.moduleKeyPrefixes and the lessons screen's own lock check
/// expect — see lessons_screen.dart's `_isLocked`.
const _moduleLabels = {
  'matematika': 'Matematika',
  'pamilya': 'Ang Aking Sarili',
  'kulay': 'Kulay-Saya',
  'traceit': 'Trace It',
  'magbasa': 'Magbasa',
  'tandaan': 'Tandaan Mo!',
};

// A light admin panel in the app's own violet: the one screen in the app
// built for reading a lot at once, not for a child's thumb.
const _violet = Color(0xFF5C52E5);
const _ink = Color(0xFF1E1B4B);
const _soft = Color(0xFF6B6690);
const _faint = Color(0xFFA19DBF);
const _line = Color(0xFFE6E4F2);
const _bg = Color(0xFFF6F7FB);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFDC2626);
const _amber = Color(0xFFD97706);
const _blue = Color(0xFF2563EB);

/// What a child sees under "Sandali lang!" unless the developer writes
/// something else.
const _defaultMaintenanceMessage =
    'Inaayos namin ang E-Tarabay. Balik ka mamaya!';

const _filterLabels = {
  DevFilter.all: 'Lahat',
  DevFilter.online: 'Online',
  DevFilter.today: 'Ngayon',
  DevFilter.away: '7+ araw wala',
  DevFilter.paused: 'Naka-pause',
  DevFilter.outdated: 'Luma ang app',
};

const _filterTones = {
  DevFilter.all: _violet,
  DevFilter.online: _green,
  DevFilter.today: _blue,
  DevFilter.away: _amber,
  DevFilter.paused: _red,
  DevFilter.outdated: _amber,
};

const _emptyLabels = {
  DevFilter.all: 'Wala pang batang naka-enroll.',
  DevFilter.online: 'Walang online ngayon.',
  DevFilter.today: 'Wala pang naglaro ngayong araw.',
  DevFilter.away: 'Walang 7+ araw na wala.',
  DevFilter.paused: 'Walang naka-pause.',
  DevFilter.outdated: 'Walang lumang app.',
};

const _sortLabels = {
  DevSort.onlineFirst: 'Online muna',
  DevSort.name: 'Pangalan',
  DevSort.progressLow: 'Progreso (mababa muna)',
  DevSort.lastActive: 'Huling aktibo',
};

/// The panel's own look, laid over the app's theme so its fonts carry on:
/// white surfaces, thin borders, violet for what can be pressed.
ThemeData _panelTheme(BuildContext context) {
  final base = Theme.of(context);
  final scheme = ColorScheme.fromSeed(seedColor: _violet).copyWith(
    primary: _violet,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: _ink,
    error: _red,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  // A button's own text style replaces the theme's whole, family and all:
  // the app's font, carried over by hand.
  final family = base.textTheme.labelLarge?.fontFamily;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width));
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: _bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Same as the buttons below: these replace the theme's style whole.
      titleTextStyle: TextStyle(
          fontFamily: family,
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(
          fontFamily: family, color: _soft, fontSize: 14, height: 1.4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: _line,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _line),
      ),
      textStyle: const TextStyle(color: _ink, fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: _faint),
      labelStyle: const TextStyle(color: _soft),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(_line),
      enabledBorder: border(_line),
      focusedBorder: border(_violet, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        shape: shape,
        textStyle: TextStyle(
            fontFamily: family, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _soft,
        shape: shape,
        textStyle: TextStyle(
            fontFamily: family, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _line, space: 1),
  );
}

class DeveloperDashboardScreen extends StatelessWidget {
  const DeveloperDashboardScreen({super.key});

  /// The students, the developer config and this phone's version to show
  /// instead of Firestore's and the platform's, for previews and tests.
  /// Never set in the app.
  @visibleForTesting
  static Stream<List<DevRecord>>? debugStudents;
  @visibleForTesting
  static Stream<Map<String, dynamic>?>? debugConfig;
  @visibleForTesting
  static String? debugOwnVersion;
  @visibleForTesting
  static DateTime Function()? debugNow;
  @visibleForTesting
  static AuthService? debugAuthService;
  @visibleForTesting
  static Stream<Map<String, dynamic>?>? debugNotifications;

  // The theme goes round the whole panel, so every sheet and dialog opened
  // from inside it is drawn in it too.
  @override
  Widget build(BuildContext context) =>
      Theme(data: _panelTheme(context), child: const _Panel());
}

class _Panel extends StatefulWidget {
  const _Panel();

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  // Made when first used, so the screen can be drawn in a preview with no
  // Firebase behind it.
  late final _service = DeveloperService();
  late final _authService =
      DeveloperDashboardScreen.debugAuthService ?? AuthService();
  final _searchController = TextEditingController();
  String _query = '';
  DevFilter _filter = DevFilter.all;
  DevSort _sort = DevSort.onlineFirst;

  /// Subscribed to once for the life of the screen: made in build, a new
  /// stream on every setState — every card tapped — showed the spinner.
  late final Stream<List<DevRecord>> _students;
  late final StreamSubscription<Map<String, dynamic>?> _configSub;
  Map<String, dynamic>? _config;

  /// The same config, for the settings page: a route of its own, outside
  /// this state's rebuilds.
  final _configView = ValueNotifier<Map<String, dynamic>?>(null);
  List<DevRecord> _latest = const [];

  /// This phone's own version: the highest minimum it may set, so the
  /// developer can never lock their own phone out of the dashboard.
  String? _ownVersion;

  DateTime get _now =>
      DeveloperDashboardScreen.debugNow?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _students = DeveloperDashboardScreen.debugStudents ??
        _service.watchAllStudents().map((s) => [
              for (final d in s.docs) DevRecord(d.id, d.data()),
            ]);
    _configSub = (DeveloperDashboardScreen.debugConfig ??
            _service.watchConfig().map((s) => s.data()))
        .listen((data) {
      _configView.value = data;
      if (mounted) setState(() => _config = data);
    });
    final own = DeveloperDashboardScreen.debugOwnVersion;
    if (own != null) {
      _ownVersion = own;
    } else {
      AppVersion.current().then((v) {
        if (mounted) setState(() => _ownVersion = v);
      });
    }
  }

  @override
  void dispose() {
    _configSub.cancel();
    _configView.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _maintenanceOn => _config?['maintenanceOn'] == true;
  String? get _minVersion {
    final v = (_config?['minVersion'] ?? '').toString().trim();
    return v.isEmpty ? null : v;
  }

  Set<String> get _locked =>
      (_config?['lockedModules'] as List?)?.map((e) => e.toString()).toSet() ??
      <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Developer',
                style: TextStyle(
                    color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('E-Tarabay · admin',
                style: TextStyle(
                    color: _soft, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          _BarButton(
            icon: LucideIcons.send,
            label: 'Ipadala',
            tooltip: 'Ipadala',
            onTap: _showSend,
          ),
          _BarButton(
            icon: LucideIcons.settings,
            label: 'Setting',
            tooltip: 'Mga setting ng app',
            onTap: _openSettings,
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1)),
      ),
      body: StreamBuilder<List<DevRecord>>(
        stream: _students,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('May mali: ${snapshot.error}',
                    style: const TextStyle(color: _red)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = _latest = snapshot.data!;
          final now = _now;
          // Over everyone, not the list as narrowed: the numbers stay the
          // same overview whatever is picked or searched.
          final counts = countRoster(all, now);
          final newest = newestVersion(all);
          final shown = filterAndSort(all,
              now: now, filter: _filter, sort: _sort, query: _query);
          return CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(children: [
                if (_maintenanceOn) ...[
                  _maintenanceBanner(),
                  const SizedBox(height: 12),
                ],
                _search(),
                const SizedBox(height: 10),
                _filterChips(counts),
                _sortRow(shown.length),
              ]),
            ),
            if (shown.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(_query.isNotEmpty
                    ? 'Walang tugma.'
                    : _emptyLabels[_filter]!),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _StudentRow(
                    record: shown[i],
                    now: now,
                    newestVersion: newest,
                    service: _service,
                    authService: _authService,
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  // ── The panel's top ────────────────────────────────────────────────────

  /// Who to show, with how many each: one row the thumb can slide, where
  /// six big cards used to push the list off the first screen.
  Widget _filterChips(DevRosterCounts counts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final f in DevFilter.values) ...[
          _FilterChip(
            label: _filterLabels[f]!,
            count: counts.of(f),
            tone: _filterTones[f]!,
            selected: _filter == f,
            // The one picked, tapped again, goes back to everyone.
            onTap: () => setState(() => _filter =
                _filter == f && f != DevFilter.all ? DevFilter.all : f),
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }

  /// Maintenance, the minimum version, the module locks and the password:
  /// set now and then, so on a page of their own rather than above the list.
  void _openSettings() {
    final theme = Theme.of(context);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Theme(data: theme, child: _AppSettingsPage(panel: this)),
    ));
  }

  Widget _search() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: _ink),
      onChanged: (v) => setState(() => _query = v.trim()),
      decoration: InputDecoration(
        hintText: 'Pangalan o Student Number',
        prefixIcon: const Icon(LucideIcons.search, color: _soft, size: 19),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x, color: _soft, size: 18),
                onPressed: () => setState(() {
                  _searchController.clear();
                  _query = '';
                }),
              ),
      ),
    );
  }

  Widget _sortRow(int shown) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(children: [
        Text('$shown na bata',
            style: const TextStyle(
                color: _soft, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        // Its label, the longest of them, gives way before the count does.
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<DevSort>(
              initialValue: _sort,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (_) => [
                for (final s in DevSort.values)
                  PopupMenuItem(
                    value: s,
                    child: Row(children: [
                      Icon(LucideIcons.check,
                          size: 16,
                          color: s == _sort ? _violet : Colors.transparent),
                      const SizedBox(width: 8),
                      Flexible(child: Text(_sortLabels[s]!)),
                    ]),
                  ),
              ],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(LucideIcons.arrow_up_down,
                      size: 15, color: _violet),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Ayos: ${_sortLabels[_sort]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _violet,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Maintenance ────────────────────────────────────────────────────────

  Widget _maintenanceBanner() {
    final since = _config?['maintenanceSince'];
    final at = since is Timestamp ? since.toDate() : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5D08A)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: _amber.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(LucideIcons.wrench, size: 18, color: _amber),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Naka-maintenance ang app ng mga bata',
                  style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              if (at != null)
                Text('Mula ${TimeOfDay.fromDateTime(at).format(context)}',
                    style: const TextStyle(
                        color: Color(0xFFB45309), fontSize: 12)),
            ],
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF92400E)),
          onPressed: () => _service.setMaintenance(
              false,
              (_config?['maintenanceMessage'] ?? _defaultMaintenanceMessage)
                  .toString()),
          child: const Text('I-off'),
        ),
      ]),
    );
  }

  void _showMaintenance() {
    final message = TextEditingController(
        text: (_config?['maintenanceMessage'] ?? '').toString().trim().isEmpty
            ? _defaultMaintenanceMessage
            : _config!['maintenanceMessage'].toString());
    var on = _maintenanceOn;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => _SheetBody(
          title: 'Maintenance (inaayos ang app)',
          subtitle: 'Matatakpan ang app ng lahat ng batang naka-login, saan '
              'man sila, hanggang i-off mo. Bukas pa rin ang Talaan ng Guro. '
              'Walang mabubura sa progreso.',
          children: [
            _SwitchCard(
              title: 'Takpan ang app ng mga bata',
              subtitle: on ? 'Naka-on' : 'Naka-off',
              tone: _amber,
              value: on,
              onChanged: (v) => setSheet(() => on = v),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Mensahe sa mga bata'),
            TextField(
              controller: message,
              maxLines: 3,
              style: const TextStyle(color: _ink),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style:
                    on ? FilledButton.styleFrom(backgroundColor: _amber) : null,
                onPressed: () async {
                  final text = message.text.trim();
                  // Switching it on reaches every child at once: asked once
                  // more first.
                  if (on && !_maintenanceOn) {
                    final sure = await _confirm(
                      sheetContext,
                      title: 'I-on ang maintenance?',
                      body: 'Matatakpan agad ang app ng lahat ng batang '
                          'naka-login (${_latest.length} na record).',
                      action: 'I-on',
                      color: _amber,
                    );
                    if (sure != true) return;
                  }
                  await _service.setMaintenance(
                      on, text.isEmpty ? _defaultMaintenanceMessage : text);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('I-save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Versions ───────────────────────────────────────────────────────────

  void _showVersions() {
    final byVersion = <String, int>{};
    var unknown = 0;
    for (final r in _latest) {
      final v = r.appVersion;
      if (v == null) {
        unknown++;
      } else {
        byVersion[v] = (byVersion[v] ?? 0) + 1;
      }
    }
    final versions = byVersion.keys.toList()
      ..sort((a, b) => AppVersion.compare(b, a));
    final total = _latest.isEmpty ? 1 : _latest.length;
    final field = TextEditingController(text: _minVersion ?? '');
    String? error;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> save() async {
            final v = field.text.trim();
            if (!RegExp(r'^\d+(\.\d+){0,3}$').hasMatch(v)) {
              setSheet(() => error = 'Hal. 1.2.57');
              return;
            }
            final own = _ownVersion;
            if (own != null && AppVersion.compare(v, own) > 0) {
              setSheet(() => error = 'Mas mataas ito sa bersyon ng phone na '
                  'ito ($own). I-update muna ang phone mo.');
              return;
            }
            final below = _latest
                .where((r) =>
                    r.appVersion != null &&
                    AppVersion.compare(r.appVersion!, v) < 0)
                .length;
            final sure = await _confirm(
              sheetContext,
              title: 'Pilitin ang update sa $v?',
              body: 'Hindi magagamit ang app sa mga phone na mas luma sa $v '
                  '(guro kasama) hanggang mag-update. $below na bata ang '
                  'kailangang mag-update. Ang mga phone na walang tala '
                  '($unknown) ay nasa bersyong hindi pa ito alam.',
              action: 'Pilitin',
              color: _red,
            );
            if (sure != true) return;
            await _service.setMinVersion(v);
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          }

          return _SheetBody(
            title: 'Bersyon ng app',
            subtitle: 'Ayon sa huling sync ng bawat bata. Ang phone na ito: '
                '${_ownVersion ?? '—'}.',
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  for (final v in versions)
                    _VersionLine(
                        label: 'v$v',
                        note: v == versions.first ? 'pinakabago' : 'luma',
                        count: byVersion[v]!,
                        share: byVersion[v]! / total,
                        tone: v == versions.first ? _green : _amber),
                  _VersionLine(
                      label: 'Walang tala',
                      note: 'lumang app',
                      count: unknown,
                      share: unknown / total,
                      tone: _faint),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: _FieldLabel('Pinakamababang bersyon')),
                _Pill(
                  text: _minVersion == null ? 'Naka-off' : 'Naka-on',
                  tone: _minVersion == null ? _soft : _red,
                ),
              ]),
              Text(
                _minVersion == null
                    ? 'Lahat ng bersyon ay magagamit.'
                    : '$_minVersion pataas lang ang magagamit.',
                style: const TextStyle(color: _soft, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: field,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: _ink),
                decoration: InputDecoration(
                  hintText: 'hal. 1.2.57',
                  errorText: error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                if (_minVersion != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        minimumSize: const Size(0, 46),
                        side: const BorderSide(color: _line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await _service.setMinVersion(null);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      child: const Text('I-off'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _red),
                    onPressed: save,
                    child: const Text('I-save'),
                  ),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  // ── Module locks ───────────────────────────────────────────────────────

  void _showModuleLocks() {
    showModalBottomSheet<void>(
      context: context,
      // Six switches plus the header no longer fit every phone's height —
      // without this the sheet clipped to the un-scrollable content size and
      // the last module (Tandaan Mo!) was left stranded off-screen.
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        // Live: a switch flipped here shows at once, from the config the
        // panel already listens to.
        child: _LiveConfig(
          panel: this,
          builder: (locked) => _SheetBody(
            title: 'Mga module',
            subtitle: 'Isasara ang aralin na ito para sa lahat ng bata, '
                'saan man sila.',
            children: [
              for (final entry in _moduleLabels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SwitchCard(
                    title: entry.value,
                    subtitle:
                        locked.contains(entry.key) ? 'Naka-lock' : 'Bukas',
                    tone: _red,
                    offTone: _green,
                    value: locked.contains(entry.key),
                    onChanged: (value) =>
                        _service.setModuleLocked(entry.key, value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────

  /// A message inside every child's app, or a notification on the
  /// teachers' phones.
  void _showSend() {
    final notifications = DeveloperDashboardScreen.debugNotifications ??
        _service.watchNotifications();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetBody(
        title: 'Ipadala',
        subtitle: 'Para sa isang bata lang: pindutin ang tatlong tuldok sa '
            'tabi ng pangalan niya sa listahan.',
        children: [
          _ChoiceCard(
            icon: LucideIcons.megaphone,
            title: 'Mensahe sa lahat ng bata',
            subtitle: 'Lalabas sa loob ng app ng bawat bata.',
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showBroadcastDialog();
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder<Map<String, dynamic>?>(
            stream: notifications,
            builder: (context, snap) {
              final sent = (snap.data?['teacher'] as Map?)?['sentAt'];
              return _ChoiceCard(
                icon: LucideIcons.bell_ring,
                title: 'Notif sa mga teacher',
                subtitle: sent is Timestamp
                    ? 'Huling naipadala: ${_when(sent.toDate())}'
                    : 'Sa notification bar ng phone ng bawat teacher.',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showNotifDialog(
                    context,
                    heading: 'Notif sa mga teacher',
                    note: 'Lalabas sa notification bar ng bawat phone na '
                        'naka-sign in ang teacher, kahit sarado ang app.',
                    send: _service.sendTeacherNotif,
                    done: 'Naipadala ang notif sa mga teacher.',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final controller = TextEditingController();
    String category = AdminMessageCategory.announcement;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Mensahe sa lahat ng bata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Makikita ito ng lahat ng bata sa loob ng app.'),
              const SizedBox(height: 14),
              _CategoryPicker(
                selected: category,
                onSelected: (c) => setDialogState(() => category = c),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: _ink),
                decoration: const InputDecoration(hintText: 'Mensahe...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kanselahin'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                _service.broadcastMessage(text, category: category);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Ipadala'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Password ───────────────────────────────────────────────────────────

  void _showChangePassword() {
    final current = TextEditingController();
    final next = TextEditingController();
    final again = TextEditingController();
    String? error;
    var busy = false;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) {
          Future<void> save() async {
            final n = next.text.trim();
            if (n.length < 6) {
              setDialog(() => error = 'Kailangan ng 6 o higit pang letra.');
              return;
            }
            if (n != again.text.trim()) {
              setDialog(() => error = 'Hindi magkatugma ang bagong password.');
              return;
            }
            setDialog(() {
              busy = true;
              error = null;
            });
            final ok =
                await _authService.verifyDeveloperPassword(current.text.trim());
            if (!ok) {
              setDialog(() {
                busy = false;
                error = 'Mali ang kasalukuyang password.';
              });
              return;
            }
            // The teacher login checks the teacher's password first: one
            // the same as it would never reach this dashboard again.
            if (await _authService.checkTeacherPassword(n) == true) {
              setDialog(() {
                busy = false;
                error = 'Kapareho ito ng password ng guro. Pumili ng iba.';
              });
              return;
            }
            final saved = await _authService.setDeveloperPassword(n);
            if (!dialogContext.mounted) return;
            if (saved) {
              Navigator.pop(dialogContext);
            } else {
              setDialog(() {
                busy = false;
                error = 'Hindi na-save. Kailangan ng internet.';
              });
            }
          }

          Widget box(TextEditingController c, String label) => TextField(
                controller: c,
                obscureText: true,
                style: const TextStyle(color: _ink),
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon:
                      const Icon(LucideIcons.lock, size: 18, color: _soft),
                ),
              );
          return AlertDialog(
            title: const Text('Palitan ang developer password'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              box(current, 'Kasalukuyang password'),
              const SizedBox(height: 10),
              box(next, 'Bagong password'),
              const SizedBox(height: 10),
              box(again, 'Ulitin ang bagong password'),
              if (error != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(LucideIcons.circle_alert, size: 16, color: _red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(error!,
                        style: const TextStyle(color: _red, fontSize: 12.5)),
                  ),
                ]),
              ],
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Kanselahin'),
              ),
              FilledButton(
                onPressed: busy ? null : save,
                child: const Text('I-save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The module locks, kept live inside the sheet: it rebuilds whenever the
/// panel's config does.
class _LiveConfig extends StatefulWidget {
  const _LiveConfig({required this.panel, required this.builder});

  final _PanelState panel;
  final Widget Function(Set<String> locked) builder;

  @override
  State<_LiveConfig> createState() => _LiveConfigState();
}

class _LiveConfigState extends State<_LiveConfig> {
  late final StreamSubscription<Map<String, dynamic>?> _sub;

  /// Read off this sheet's own subscription, never the panel's — the two
  /// can answer in either order, and the panel's might still be the last.
  late Set<String> _locked = widget.panel._locked;

  @override
  void initState() {
    super.initState();
    final stream = DeveloperDashboardScreen.debugConfig ??
        widget.panel._service.watchConfig().map((s) => s.data());
    _sub = stream.listen((data) {
      if (!mounted) return;
      setState(() => _locked =
          (data?['lockedModules'] as List?)?.map((e) => e.toString()).toSet() ??
              <String>{});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_locked);
}

/// A yes-or-no before something that reaches many phones at once.
/// Does [work] and says how it went. Each of these reaches a child's
/// phone, and it used to be fired and forgotten: offline, or refused,
/// nothing said so, and a "deleted" child was still there.
Future<void> _report(
    BuildContext context, Future<Object?> Function() work, String done) async {
  final messenger = ScaffoldMessenger.of(context);
  const later = 'Naipadala na; matatapos ito pagbalik ng internet.';
  String say;
  try {
    final result = await work().timeout(const Duration(seconds: 12));
    if (result is Map && result['status'] != 'Success') {
      say = switch (result['code']) {
        'needsInternet' => 'Walang internet. Walang nabago.',
        'finishesOnline' => later,
        'childRemoved' => 'Wala na ang record ng batang ito.',
        _ => 'Hindi natuloy. Subukan ulit.',
      };
    } else {
      say = done;
    }
  } on TimeoutException {
    say = later;
  } catch (e) {
    debugPrint('Developer action failed: $e');
    say = 'Hindi natuloy. Subukan ulit.';
  }
  messenger.showSnackBar(SnackBar(content: Text(say)));
}

/// Writes a phone notification: an optional title, the message, and when
/// it arrives. Each phone looks for it in the background, so it is not
/// instant, and says so.
void _showNotifDialog(BuildContext context,
    {required String heading,
    required String note,
    required Future<void> Function(String title, String body) send,
    required String done}) {
  final title = TextEditingController();
  final body = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(heading),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note),
            const SizedBox(height: 14),
            TextField(
              controller: title,
              maxLength: 40,
              style: const TextStyle(color: _ink),
              decoration: const InputDecoration(
                  labelText: 'Pamagat', hintText: 'E-Tarabay'),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: body,
              autofocus: true,
              maxLines: 3,
              maxLength: 120,
              style: const TextStyle(color: _ink),
              decoration: const InputDecoration(hintText: 'Mensahe...'),
            ),
            const Row(children: [
              Icon(LucideIcons.clock, size: 14, color: _soft),
              SizedBox(width: 6),
              Expanded(
                child: Text('Darating ito sa loob ng mga 15–30 minuto.',
                    style: TextStyle(color: _soft, fontSize: 12.5)),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Kanselahin'),
        ),
        FilledButton(
          onPressed: () {
            final text = body.text.trim();
            if (text.isEmpty) return;
            final heading = title.text.trim();
            Navigator.of(dialogContext).pop();
            _report(
                context,
                () => send(heading.isEmpty ? 'E-Tarabay' : heading, text),
                done);
          },
          child: const Text('Ipadala'),
        ),
      ],
    ),
  );
}

/// "8 Nob, 3:42 PM".
String _when(DateTime at) {
  const months = [
    'Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun', //
    'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis',
  ];
  final t = at.toLocal();
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]}, $hour:$minute '
      '${t.hour < 12 ? 'AM' : 'PM'}';
}

Future<bool?> _confirm(BuildContext context,
    {required String title,
    required String body,
    required String action,
    required Color color}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Kanselahin'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(action),
        ),
      ],
    ),
  );
}

// ── Pieces ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: _ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: Color(0xFFEEEDFD), shape: BoxShape.circle),
            child: const Icon(LucideIcons.users, color: _violet, size: 24),
          ),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _soft, fontSize: 14)),
        ]),
      );
}

/// A small coloured label: a status, a version.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone, this.icon});

  final String text;
  final Color tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 4),
        ],
        Text(text,
            style: TextStyle(
                color: tone, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// An app-bar action with its name under it: the two at the top are the
/// panel's way to everything that is not one child.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: _violet),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: _ink, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

/// One filter: a name and how many it holds. Filled when chosen.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = count == 0 && !selected;
    return Material(
      color: selected ? _violet : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? _violet : _line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: TextStyle(
                    color: selected
                        ? Colors.white
                        : empty
                            ? _faint
                            : _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                    color: selected
                        ? Colors.white.withOpacity(0.85)
                        : empty
                            ? _faint
                            : tone,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

/// The settings the developer changes now and then, each with where it
/// stands. Live: a change made in its sheet shows here at once.
class _AppSettingsPage extends StatelessWidget {
  const _AppSettingsPage({required this.panel});

  final _PanelState panel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mga setting ng app',
            style: TextStyle(
                color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1)),
      ),
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: panel._configView,
        builder: (context, _, __) {
          final locked = panel._locked;
          final min = panel._minVersion;
          final on = panel._maintenanceOn;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  _SettingsRow(
                    icon: LucideIcons.wrench,
                    title: 'Maintenance',
                    subtitle: 'Takpan ang app ng mga bata habang may inaayos.',
                    status: on ? 'Naka-on' : 'Naka-off',
                    tone: on ? _amber : _soft,
                    onTap: panel._showMaintenance,
                  ),
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: LucideIcons.smartphone,
                    title: 'Pinakamababang bersyon',
                    subtitle: 'Pilitin mag-update ang mga lumang app.',
                    status: min == null ? 'Malaya' : '≥ $min',
                    tone: min == null ? _soft : _red,
                    onTap: panel._showVersions,
                  ),
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: LucideIcons.lock,
                    title: 'Mga module',
                    subtitle: 'Isara ang isang aralin para sa lahat.',
                    status: locked.isEmpty
                        ? 'Lahat bukas'
                        : '${locked.length} sarado',
                    tone: locked.isEmpty ? _soft : _red,
                    onTap: panel._showModuleLocks,
                  ),
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: LucideIcons.key_round,
                    title: 'Developer password',
                    subtitle: 'Ang tina-type mo sa teacher login.',
                    status: 'Palitan',
                    tone: _violet,
                    onTap: panel._showChangePassword,
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One setting: what it is, what it does, and where it stands now.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: _violet),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(color: _soft, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(status,
              style: TextStyle(
                  color: tone, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          const Icon(LucideIcons.chevron_right, size: 18, color: _faint),
        ]),
      ),
    );
  }
}

/// A switch in a bordered card, for the sheets.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.value,
    required this.onChanged,
    this.offTone = _soft,
  });

  final String title;
  final String subtitle;
  final Color tone;
  final Color offTone;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(
        color: value ? tone.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? tone.withOpacity(0.5) : _line),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: _ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: TextStyle(
                      color: value ? tone : offTone,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: tone,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}

/// One thing a sheet offers to do, tapped as a whole.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: _violet),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(color: _soft, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevron_right, size: 18, color: _faint),
          ]),
        ),
      ),
    );
  }
}

/// A sheet's title, what it does, and what is in it.
class _SheetBody extends StatelessWidget {
  const _SheetBody(
      {required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: _soft, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A line of the versions sheet: a version, how many phones are on it, and
/// a bar of its share.
class _VersionLine extends StatelessWidget {
  const _VersionLine({
    required this.label,
    required this.note,
    required this.count,
    required this.share,
    required this.tone,
  });

  final String label;
  final String note;
  final int count;
  final double share;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Row(children: [
          Text(label,
              style: const TextStyle(
                  color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(note, style: TextStyle(color: tone, fontSize: 12)),
          const Spacer(),
          Text('$count',
              style: const TextStyle(
                  color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
            minHeight: 6,
            color: tone,
            backgroundColor: _line,
          ),
        ),
      ]),
    );
  }
}

// ── A student ────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.record,
    required this.now,
    required this.newestVersion,
    required this.service,
    required this.authService,
  });

  final DevRecord record;
  final DateTime now;

  /// The newest version any phone reports; behind it reads as old.
  final String? newestVersion;
  final DeveloperService service;
  final AuthService authService;

  String get studentId => record.id;
  String get name => record.name;
  bool get disabled => record.paused;

  static const _avatarTones = [
    Color(0xFF5C52E5),
    Color(0xFF0EA5E9),
    Color(0xFFDB2777),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
  ];

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String get _lastActiveLabel {
    final at = record.lastActive;
    if (at == null) return 'Hindi pa kailanman';
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Kanina lang';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ang nakalipas';
    if (diff.inHours < 24) return '${diff.inHours}h ang nakalipas';
    return '${diff.inDays}d ang nakalipas';
  }

  @override
  Widget build(BuildContext context) {
    final online = record.isOnline(now);
    final progress = record.progress;
    final version = record.appVersion;
    final old = record.isOutdated(newestVersion);
    final tone = _avatarTones[name.hashCode.abs() % _avatarTones.length];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: disabled ? _red.withOpacity(0.35) : _line),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: tone.withOpacity(0.12), shape: BoxShape.circle),
            child: Text(_initials,
                style: TextStyle(
                    color: tone, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
              if (record.lrn.isNotEmpty)
                Text(record.lrn,
                    style: const TextStyle(color: _faint, fontSize: 12)),
              const SizedBox(height: 4),
              // Where the child stands, in one line: seen when, how far,
              // which version.
              Text.rich(
                TextSpan(
                  style: const TextStyle(color: _soft, fontSize: 12.5),
                  children: [
                    TextSpan(
                      text: online ? 'Online ngayon' : _lastActiveLabel,
                      style: TextStyle(
                          color: online ? _green : _soft,
                          fontWeight: online ? FontWeight.w700 : null),
                    ),
                    const TextSpan(text: ' · '),
                    TextSpan(
                      text: progress == null
                          ? 'Walang progreso'
                          : '${(progress * 100).clamp(0, 100).round()}%',
                      style: TextStyle(
                          color: progress == null ? _faint : _ink,
                          fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' · '),
                    TextSpan(
                      text: version == null ? 'v —' : 'v$version',
                      style: TextStyle(
                          color: version == null
                              ? _faint
                              : old
                                  ? _amber
                                  : _soft,
                          fontWeight: old ? FontWeight.w700 : null),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (disabled || record.testAccount || old)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    if (disabled)
                      const _Pill(
                          text: 'Naka-pause',
                          tone: _red,
                          icon: LucideIcons.circle_pause),
                    if (record.testAccount)
                      const _Pill(
                          text: 'Pang-test',
                          tone: _violet,
                          icon: LucideIcons.flask_conical),
                    if (old)
                      const _Pill(
                          text: 'Luma ang app',
                          tone: _amber,
                          icon: LucideIcons.smartphone),
                  ]),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mga aksyon',
          icon:
              const Icon(LucideIcons.ellipsis_vertical, color: _soft, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'message':
                _showSendMessage(context);
              case 'notif':
                _showNotifDialog(
                  context,
                  heading: 'Notif kay $name',
                  note: 'Lalabas sa notification bar ng phone ng bata, '
                      'kahit sarado ang app. Kailangang naka-on ang '
                      'Notifications sa Settings ng bata.',
                  send: (title, body) =>
                      service.sendChildNotif(studentId, title, body),
                  done: 'Naipadala ang notif kay $name.',
                );
              case 'pause':
                _confirmToggleDisabled(context);
              case 'kick':
                _confirmForceLogout(context);
              case 'complete':
                _confirmCompleteAll(context);
              case 'reset':
                _confirmResetProgress(context);
              case 'delete':
                _confirmDelete(context);
            }
          },
          // Grouped by what they do: talk to the child, their account,
          // testing, and what cannot be undone.
          itemBuilder: (context) => [
            _item('message', LucideIcons.message_circle, 'Mensahe sa app'),
            _item('notif', LucideIcons.bell_ring, 'Notif sa phone'),
            const PopupMenuDivider(),
            _item('pause', disabled ? LucideIcons.play : LucideIcons.pause,
                disabled ? 'I-resume ang account' : 'I-pause ang account'),
            _item('kick', LucideIcons.log_out, 'I-logout'),
            const PopupMenuDivider(),
            _item('complete', LucideIcons.flask_conical,
                'Tapusin lahat (pang-test)'),
            const PopupMenuDivider(),
            _item('reset', LucideIcons.rotate_ccw, 'I-reset ang progress',
                danger: true),
            _item('delete', LucideIcons.trash_2, 'Burahin ang account',
                danger: true),
          ],
        ),
      ]),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label,
      {bool danger = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 17, color: danger ? _red : _soft),
        const SizedBox(width: 10),
        Flexible(
            child: Text(label, style: TextStyle(color: danger ? _red : _ink))),
      ]),
    );
  }

  void _showSendMessage(BuildContext context) {
    final controller = TextEditingController();
    String category = AdminMessageCategory.announcement;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Mensahe kay $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryPicker(
                selected: category,
                onSelected: (c) => setDialogState(() => category = c),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: _ink),
                decoration: const InputDecoration(hintText: 'Mensahe...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kanselahin'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.of(dialogContext).pop();
                _report(
                    context,
                    () => service.sendMessage(studentId, text,
                        category: category),
                    'Naipadala ang mensahe kay $name.');
              },
              child: const Text('Ipadala'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ask(BuildContext context,
      {required String title,
      required String body,
      required String action,
      required Color color,
      required VoidCallback onYes}) async {
    if (await _confirm(context,
            title: title, body: body, action: action, color: color) ==
        true) {
      onYes();
    }
  }

  void _confirmToggleDisabled(BuildContext context) {
    final willDisable = !disabled;
    _ask(
      context,
      title: willDisable ? 'I-pause ang account?' : 'I-resume ang account?',
      body: willDisable
          ? '$name ay ma-si-sign-out sa susunod na sync, hanggang i-resume mo ulit.'
          : '$name ay makaka-access na ulit ng app.',
      action: willDisable ? 'I-pause' : 'I-resume',
      color: willDisable ? _red : _green,
      onYes: () => _report(
          context,
          () => service.setDisabled(studentId, willDisable),
          willDisable ? 'Naka-pause na si $name.' : 'Bukas na ulit si $name.'),
    );
  }

  void _confirmForceLogout(BuildContext context) {
    _ask(
      context,
      title: 'I-logout si $name?',
      body: '$name ay ma-si-sign-out sa susunod na sync. Puwede silang '
          'mag-login ulit agad — hindi ito pause.',
      action: 'I-logout',
      color: _amber,
      onYes: () => _report(context, () => service.forceLogout(studentId),
          'Mala-logout si $name sa susunod na sync.'),
    );
  }

  void _confirmCompleteAll(BuildContext context) {
    _ask(
      context,
      title: 'Tapusin lahat (pang-test)?',
      body: 'Matatapos ang lahat ng aralin ni $name, buo ang bituin. Ang '
          'matitira na lang ay pindutin ang "Kunin" sa bawat badge, saka '
          'ang certificate.\n\nPara lang sa test account: may tatak itong '
          '"Pang-test" sa Talaan ng Guro hanggang i-reset ang progress.',
      action: 'Tapusin lahat',
      color: _violet,
      onYes: () => _report(
          context,
          () => service.completeAllForTesting(studentId),
          'Tapos na lahat ni $name. Kunin na lang ang mga badge.'),
    );
  }

  void _confirmResetProgress(BuildContext context) {
    _ask(
      context,
      title: 'I-reset ang progress ni $name?',
      body: 'Buburahin ang LAHAT ng progress, stars, at badges ni $name. '
          'Hindi na ito maibabalik.',
      action: 'I-reset',
      color: _red,
      onYes: () => _report(
          context,
          () => authService.resetStudentActivityProgress(studentId),
          'Na-reset ang progress ni $name.'),
    );
  }

  void _confirmDelete(BuildContext context) {
    _ask(
      context,
      title: 'Burahin ang account ni $name?',
      body: 'Buburahin nang tuluyan ang account ni $name. Hindi na ito '
          'maibabalik.',
      action: 'Burahin',
      color: _red,
      onYes: () => _report(context, () => authService.deleteStudent(studentId),
          'Na-delete na si $name.'),
    );
  }
}

/// Three chips — Announcement, Warning, Reminder — used by both the
/// broadcast and the per-student send dialogs so a developer picks the
/// same way in either place.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _labels = {
    AdminMessageCategory.announcement: 'Anunsyo',
    AdminMessageCategory.warning: 'Babala',
    AdminMessageCategory.reminder: 'Paalala',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AdminMessageCategory.all.map((c) {
        final isSelected = c == selected;
        final color = AdminMessageCategory.colorFor(c);
        return GestureDetector(
          onTap: () => onSelected(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? color : _line, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AdminMessageCategory.iconFor(c),
                    size: 15, color: isSelected ? color : _soft),
                const SizedBox(width: 6),
                Text(_labels[c] ?? c,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : _soft,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
