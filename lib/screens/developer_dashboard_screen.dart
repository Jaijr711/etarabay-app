import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/auth_service.dart';
import '../services/developer_service.dart';

/// One row per student record, live. "Online" is inferred from
/// `lastActive` — this app has no separate presence system, so a device
/// counts as online if it wrote that heartbeat recently, the same signal
/// [DeveloperService] pulls it from.
const _onlineWindow = Duration(seconds: 90);

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

class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  final _service = DeveloperService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: const Text('Developer Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lock),
            tooltip: 'Module locks',
            onPressed: _showModuleLocks,
          ),
          IconButton(
            icon: const Icon(LucideIcons.megaphone),
            tooltip: 'Broadcast to everyone',
            onPressed: _showBroadcastDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Maghanap ng pangalan o Student Number...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(LucideIcons.search,
                    color: Colors.white38, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.x,
                            color: Colors.white38, size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.watchAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white54));
                }

                var docs = snapshot.data!.docs;
                if (_query.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final lrn = (data['lrn'] ?? '').toString().toLowerCase();
                    return name.contains(_query) || lrn.contains(_query);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty
                          ? 'Walang student record.'
                          : 'Walang tugma.',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  );
                }

                // Online first, then alphabetical — the whole point of this
                // screen is "who's on right now", so that's what should be at
                // the top without scrolling for it.
                final now = DateTime.now();
                bool isOnline(Map<String, dynamic> data) {
                  final ts = data['lastActive'];
                  if (ts is! Timestamp) return false;
                  return now.difference(ts.toDate()) < _onlineWindow;
                }

                final sorted = docs.toList()
                  ..sort((a, b) {
                    final aOnline = isOnline(a.data());
                    final bOnline = isOnline(b.data());
                    if (aOnline != bOnline) return aOnline ? -1 : 1;
                    final aName = (a.data()['name'] ?? '').toString();
                    final bName = (b.data()['name'] ?? '').toString();
                    return aName.toLowerCase().compareTo(bName.toLowerCase());
                  });

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final doc = sorted[i];
                    final data = doc.data();
                    final online = isOnline(data);
                    final disabled = data['disabledByDev'] == true;
                    final name = (data['name'] ?? doc.id).toString();
                    final lrn = (data['lrn'] ?? '').toString();
                    final lastActive = data['lastActive'];
                    final progress = data['progress'];
                    final overallProgress = progress is Map
                        ? (progress['overallProgress'] as num?)?.toDouble()
                        : null;

                    return _StudentRow(
                      studentId: doc.id,
                      name: name,
                      lrn: lrn,
                      online: online,
                      disabled: disabled,
                      lastActive: lastActive is Timestamp ? lastActive : null,
                      overallProgress: overallProgress,
                      service: _service,
                      authService: _authService,
                    );
                  },
                );
              },
            ),
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
          backgroundColor: const Color(0xFF161B22),
          title: const Text('Broadcast sa lahat',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Makikita ng LAHAT ng students ang mensaheng ito.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _CategoryPicker(
                selected: category,
                onSelected: (c) => setDialogState(() => category = c),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mensahe...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636)),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                _service.broadcastMessage(text, category: category);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('I-broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  void _showModuleLocks() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      // Six switches plus the header no longer fit every phone's height —
      // without this the sheet clipped to the un-scrollable content size and
      // the last module (Tandaan Mo!) was left stranded off-screen.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _service.watchConfig(),
          builder: (context, snapshot) {
            final locked = (snapshot.data?.data()?['lockedModules'] as List?)
                    ?.map((e) => e.toString())
                    .toSet() ??
                <String>{};
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Module Locks',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text(
                        'Isasara ang modyul na ito para sa LAHAT ng students, saan man sila.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: _moduleLabels.entries.map((entry) {
                            final isLocked = locked.contains(entry.key);
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.value,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                isLocked ? 'Naka-lock' : 'Bukas',
                                style: TextStyle(
                                  color: isLocked
                                      ? Colors.redAccent
                                      : const Color(0xFF3FB950),
                                  fontSize: 12,
                                ),
                              ),
                              value: isLocked,
                              onChanged: (value) =>
                                  _service.setModuleLocked(entry.key, value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.studentId,
    required this.name,
    required this.lrn,
    required this.online,
    required this.disabled,
    required this.lastActive,
    required this.overallProgress,
    required this.service,
    required this.authService,
  });

  final String studentId;
  final String name;
  final String lrn;
  final bool online;
  final bool disabled;
  final Timestamp? lastActive;
  final double? overallProgress;
  final DeveloperService service;
  final AuthService authService;

  String get _lastActiveLabel {
    if (online) return 'Online ngayon';
    final ts = lastActive;
    if (ts == null) return 'Hindi pa kailanman';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Kanina lang';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ang nakalipas';
    if (diff.inHours < 24) return '${diff.inHours}h ang nakalipas';
    return '${diff.inDays}d ang nakalipas';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              disabled ? Colors.redAccent.withOpacity(0.4) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? const Color(0xFF3FB950) : Colors.white24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (disabled) ...[
                          const SizedBox(width: 8),
                          const Text('PAUSED',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                    if (lrn.isNotEmpty)
                      Text(lrn,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.send,
                    color: Colors.white54, size: 20),
                tooltip: 'Send message',
                onPressed: () => _showSendMessage(context),
              ),
              IconButton(
                icon: Icon(
                  disabled ? LucideIcons.play : LucideIcons.pause,
                  color: disabled ? const Color(0xFF3FB950) : Colors.redAccent,
                  size: 20,
                ),
                tooltip: disabled ? 'Resume account' : 'Pause account',
                onPressed: () => _confirmToggleDisabled(context),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.ellipsis_vertical,
                    color: Colors.white54, size: 20),
                color: const Color(0xFF161B22),
                onSelected: (value) {
                  switch (value) {
                    case 'kick':
                      _confirmForceLogout(context);
                      break;
                    case 'reset':
                      _confirmResetProgress(context);
                      break;
                    case 'delete':
                      _confirmDelete(context);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'kick',
                    child: Text('Force Logout',
                        style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset Progress',
                        style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Account',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Text(_lastActiveLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              if (overallProgress != null) ...[
                const SizedBox(width: 14),
                const Icon(LucideIcons.trophy, size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Text('${(overallProgress! * 100).clamp(0, 100).round()}%',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showSendMessage(BuildContext context) {
    final controller = TextEditingController();
    String category = AdminMessageCategory.announcement;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Text('Message kay $name',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryPicker(
                selected: category,
                onSelected: (c) => setDialogState(() => category = c),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mensahe...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636)),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                service.sendMessage(studentId, text, category: category);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('I-send'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggleDisabled(BuildContext context) {
    final willDisable = !disabled;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(
          willDisable ? 'I-pause ang account?' : 'I-resume ang account?',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          willDisable
              ? '$name ay ma-si-sign-out sa susunod na sync, hanggang i-resume mo ulit.'
              : '$name ay makaka-access na ulit ng app.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  willDisable ? Colors.redAccent : const Color(0xFF238636),
            ),
            onPressed: () {
              service.setDisabled(studentId, willDisable);
              Navigator.of(dialogContext).pop();
            },
            child: Text(willDisable ? 'I-pause' : 'I-resume'),
          ),
        ],
      ),
    );
  }

  void _confirmForceLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Force logout?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          '$name ay ma-si-sign-out sa susunod na sync. Puwede silang mag-login ulit agad — hindi ito pause.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              service.forceLogout(studentId);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('I-logout'),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Reset progress?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Buburahin ang LAHAT ng progress, stars, at badges ni $name. Hindi na ito maibabalik.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              authService.resetStudentActivityProgress(studentId);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('I-reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Delete account?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Buburahin nang tuluyan ang account ni $name. Hindi na ito maibabalik.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              authService.deleteStudent(studentId);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('I-delete'),
          ),
        ],
      ),
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
              color: isSelected ? color.withOpacity(0.22) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? color : Colors.white24, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AdminMessageCategory.iconFor(c),
                    size: 15, color: isSelected ? color : Colors.white54),
                const SizedBox(width: 6),
                Text(_labels[c] ?? c,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.white54,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
