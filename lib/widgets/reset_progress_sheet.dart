import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'report_widgets.dart';

const _red = Color(0xFFC2334D);
const _line = Color(0xFFE6E8EF);

/// Asks which of a child's modules to reset, then resets them.
///
/// One sheet in place of the two dialogs it replaces: chosen modules or all
/// of them, a warning that says exactly what goes (drawings too, when Colour
/// Fun is among them), and a box to tick before the button works. Resolves
/// true when something was reset.
Future<bool> showResetProgressSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
  Set<String> preselect = const {},
}) async {
  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  final choice = await showModalBottomSheet<({bool all, Set<String> keys})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ResetProgressSheet(
      studentName: studentName,
      preselect: preselect,
    ),
  );
  if (choice == null) return false;

  final auth = AuthService();
  final success = choice.all
      ? await auth.resetStudentActivityProgress(studentId)
      : await auth.resetStudentSpecificActivities(
          studentId, choice.keys.toList());
  messenger.showSnackBar(SnackBar(
    content:
        Text(success ? loc.resetActivitiesDone : loc.resetActivitiesFailed),
    backgroundColor: success ? Colors.green : Colors.red,
  ));
  if (success && userProvider.currentStudentId == studentId) {
    try {
      await userProvider.resetAllProgressLocally();
    } catch (_) {}
  }
  return success;
}

/// The sheet itself. Pops `(all:, keys:)` with what to reset, or nothing.
class ResetProgressSheet extends StatefulWidget {
  const ResetProgressSheet({
    super.key,
    required this.studentName,
    this.preselect = const {},
  });

  final String studentName;
  final Set<String> preselect;

  @override
  State<ResetProgressSheet> createState() => _ResetProgressSheetState();
}

class _ResetProgressSheetState extends State<ResetProgressSheet> {
  bool _all = false;
  late final Set<String> _keys = {...widget.preselect};
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final modules = reportModules(loc);
    final count = _all ? modules.length : _keys.length;
    final drawings = _all || _keys.contains('kulay');
    final ready = _understood && count > 0;
    final first = widget.studentName.trim().split(' ').first;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D8E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      const Icon(LucideIcons.rotate_ccw, color: _red, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.toolReset,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        loc.resetSheetSub(first),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _option(
                    selected: !_all,
                    title: loc.resetPickModules,
                    note: loc.resetPickModulesNote,
                    onTap: () => setState(() {
                      _all = false;
                      _understood = false;
                    }),
                  ),
                  if (!_all) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in modules) _moduleChip(m),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  _option(
                    selected: _all,
                    title: loc.resetAllModules,
                    note: loc.resetAllModulesNote,
                    onTap: () => setState(() {
                      _all = true;
                      _understood = false;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.triangle_alert,
                            size: 18, color: _red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            drawings
                                ? loc.resetWarnDrawings(count)
                                : loc.resetWarnKeepDrawings(count),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8E2236),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _understood = !_understood),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _understood ? _red : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _understood
                                    ? _red
                                    : const Color(0xFFB8BECB),
                                width: 2,
                              ),
                            ),
                            child: _understood
                                ? const Icon(LucideIcons.check,
                                    size: 15, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.resetConfirm,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEF0F5))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: ready
                    ? () => Navigator.of(context)
                        .pop((all: _all, keys: Set<String>.of(_keys)))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF6D3DA),
                  disabledForegroundColor: const Color(0xFFC77F8D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(LucideIcons.rotate_ccw, size: 18),
                label: Text(loc.resetCount(count)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required bool selected,
    required String title,
    required String note,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFFFF7F9) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? _red : _line, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _red : const Color(0xFFC9CDD8),
                    width: selected ? 7 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      note,
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moduleChip(ReportModule m) {
    final on = _keys.contains(m.key);
    return Material(
      color: on ? const Color(0xFFFDE8EC) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: on ? _red : _line, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => setState(() {
          on ? _keys.remove(m.key) : _keys.add(m.key);
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: m.colour, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                m.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: on ? _red : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
