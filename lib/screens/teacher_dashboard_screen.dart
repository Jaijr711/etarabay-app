import 'for_parents_screen.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/badge_catalog.dart';
import '../models/certificate_model.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_messages.dart';
import '../services/update_checker.dart';
import '../utils/constants.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/update_dialog.dart';
import 'login_screen.dart';
import '../utils/page_transitions.dart';
import 'teacher_settings_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Which children the list is narrowed to.
///
/// The two figures beside the roll are registers, not scores — tapping one
/// shows the children it counted and nobody else, so a teacher can read a
/// number and then go straight to the names behind it.
enum _ClassFilter { none, needHelp, unseen }

/// One row of the class-wide "recent achievements" feed — a badge claimed or
/// a certificate awarded, by whom, and when. Built fresh from every loaded
/// student doc on each snapshot rather than stored anywhere of its own.
class _RecentAchievement {
  const _RecentAchievement({
    required this.studentName,
    required this.id,
    required this.isCertificate,
    required this.atMillis,
  });

  final String studentName;
  final String id;
  final bool isCertificate;
  final int atMillis;
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  /// The class, subscribed to once for the life of this screen.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream;
  _ClassFilter _filter = _ClassFilter.none;
  String _searchQuery = '';

  /// Which certificates this teacher has already opened a report to look
  /// at, kept locally rather than in Firestore — there is one teacher
  /// account per class, so this device's own record of "already seen" is
  /// the only one that needs to exist. Keyed 'seen_certs_<studentId>'.
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    // Made once. Called from build it returned a new Stream on every
    // setState, so StreamBuilder resubscribed, reported waiting, and the
    // builder answered with the loading skeleton -- wiping the search box
    // mid-word, every word.
    _studentsStream = _authService.getStudentsStream();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    _loadSeenCertificates();
  }

  Future<void> _loadSeenCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _prefs = prefs);
  }

  bool _isCertificateSeen(String studentId, String certId) =>
      _prefs?.getStringList('seen_certs_$studentId')?.contains(certId) ?? false;

  /// Called the moment a teacher opens a student's report — that is the
  /// look a "new certificate" badge exists to prompt, so it is also the
  /// moment the badge should stop asking for it.
  Future<void> _markCertificatesSeen(
      String studentId, List<String> certIds) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    await prefs.setStringList('seen_certs_$studentId', certIds);
    if (mounted) setState(() {});
  }

  /// Once per app open — see the matching note on HomeScreen's
  /// _checkForUpdate. A teacher's dashboard is exactly where this belongs
  /// too: whoever is managing the class is the one who would actually act
  /// on it.
  Future<void> _checkForUpdate() async {
    final update = await UpdateChecker.instance.checkForUpdate();
    if (update != null && mounted) {
      showUpdateAvailableDialog(context, update);
    }
  }

  /// Back button on the dashboard prompts to log out (there is no previous
  /// route since the dashboard replaced the login screen).
  String _formatDateWord(BuildContext context, DateTime date) {
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const fil = [
      'Enero',
      'Pebrero',
      'Marso',
      'Abril',
      'Mayo',
      'Hunyo',
      'Hulyo',
      'Agosto',
      'Setyembre',
      'Oktubre',
      'Nobyembre',
      'Disyembre'
    ];
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final mName = (date.month >= 1 && date.month <= 12)
        ? ((lang == 'fil' || lang == 'ilo')
            ? fil[date.month - 1]
            : en[date.month - 1])
        : 'Month ${date.month}';
    return '$mName ${date.day}, ${date.year}';
  }

  Future<void> _confirmLogout() async {
    final loc = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(LucideIcons.log_out, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(loc.logout,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(loc.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.logout,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await userProvider.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PremiumPageRoute(child: const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusDialog(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        backgroundColor: color == Colors.transparent ? Colors.black87 : color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Student numbers already in use, kept from the class stream.
  ///
  /// The number is also the password, so handing the same one to two children
  /// gives them each other's account.
  final Set<String> _takenIds = <String>{};

  void _showEnrollSheet() {
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final lrnController = TextEditingController();
    final usernameController = TextEditingController();
    final parentNameController = TextEditingController();
    final parentContactController = TextEditingController();
    DateTime? selectedBirthday;
    String selectedGender = 'Male';
    String selectedAvatar = 'boy1';
    int currentStep = 0;
    // The same words as the section header on each step, and translated —
    // these were three English literals reaching a Filipino teacher inside an
    // otherwise translated sentence.
    final stepLabels = [
      AppLocalizations.of(context)!.studentInformation,
      AppLocalizations.of(context)!.parentInformation,
    ];

    String? randomSuffix;
    void updateUsername() {
      final first =
          firstNameController.text.trim().toLowerCase().replaceAll(' ', '');
      if (first.isNotEmpty) {
        randomSuffix ??= (Random().nextInt(9000) + 1000).toString();
        usernameController.text = '$first$randomSuffix';
      } else {
        randomSuffix = null;
        usernameController.text = '';
      }
    }

    firstNameController.addListener(updateUsername);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetStateContext, setSheetState) {
          // Per-step content.
          Widget stepContent() {
            switch (currentStep) {
              case 0:
                return Column(
                  key: const ValueKey(0),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        AppLocalizations.of(context)!.chooseAvatar),
                    _buildAvatarPicker(
                      selectedAvatar: selectedAvatar,
                      onSelect: (preset) {
                        setSheetState(() {
                          selectedAvatar = preset;
                          // The picker is the only place this is asked now.
                          // It used to set the picture and leave the gender on
                          // its default of 'Male'.
                          selectedGender =
                              preset.startsWith('girl') ? 'Female' : 'Male';
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        AppLocalizations.of(context)!.studentInformation),
                    _buildCard([
                      _buildTextField(
                        controller: firstNameController,
                        label: AppLocalizations.of(context)!.firstName,
                        icon: LucideIcons.user,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: middleNameController,
                        label: AppLocalizations.of(context)!.middleName,
                        icon: LucideIcons.user,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: lastNameController,
                        label: AppLocalizations.of(context)!.lastName,
                        icon: LucideIcons.user,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final initialToUse = (selectedBirthday != null &&
                                  !selectedBirthday!.isBefore(DateTime(1900)) &&
                                  !selectedBirthday!.isAfter(DateTime.now()))
                              ? selectedBirthday!
                              : DateTime.now()
                                  .subtract(const Duration(days: 365 * 4));
                          final picked = await showDatePicker(
                            context: sheetStateContext,
                            initialDate: initialToUse,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedBirthday = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.birthday,
                            icon: LucideIcons.cake,
                          ),
                          child: Text(
                            selectedBirthday == null
                                ? AppLocalizations.of(context)!.notSet
                                : _formatDateWord(context, selectedBirthday!),
                            style: TextStyle(
                              color: selectedBirthday == null
                                  ? Colors.grey.shade500
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                );
              default:
                return Column(
                  key: const ValueKey(1),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        AppLocalizations.of(context)!.parentInformation),
                    _buildCard([
                      _buildTextField(
                        controller: parentNameController,
                        label: AppLocalizations.of(context)!.parentNameLabel,
                        icon: LucideIcons.users,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: parentContactController,
                        label: AppLocalizations.of(context)!.parentContactLabel,
                        icon: LucideIcons.phone,
                        hintText: '09XXXXXXXXX',
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ]),
                  ],
                );
            }
          }

          /// The parent's name and a reachable number.
          ///
          /// Called from the Enrol button, which is now the only way off this
          /// step.
          bool validateParent() {
            if (parentNameController.text.trim().isEmpty ||
                parentContactController.text.trim().isEmpty) {
              _showStatusDialog(
                AppLocalizations.of(context)!.fillAllFields,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return false;
            }
            if (parentContactController.text.trim().length != 11) {
              _showStatusDialog(
                AppLocalizations.of(context)!.contactLengthError,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return false;
            }
            return true;
          }

          Future<void> submit() async {
            // The parent step is now the last one, so its check runs here.
            // It used to run on the way out of it, and there is no way out of
            // the last step but this button.
            if (!validateParent()) return;
            // Minted at the end rather than on the way past a step that only
            // displayed it.
            if (lrnController.text.trim().isEmpty) {
              final minted = AuthService.mintStudentNumber(_takenIds);
              if (minted.isEmpty) {
                // Every number for this year is in use. Enrolling anyway would
                // give this child someone else's password.
                _showStatusDialog(
                  AppLocalizations.of(context)!.noStudentNumbersLeft,
                  LucideIcons.triangle_alert,
                  Colors.orange,
                );
                return;
              }
              lrnController.text = minted;
            }
            if (usernameController.text.trim().isEmpty) updateUsername();
            final passValidation =
                AuthService.validateDcPasswordFormat(lrnController.text.trim());
            if (!passValidation['isValid']) {
              _showStatusDialog(
                authMessage(context, passValidation).isNotEmpty
                    ? authMessage(context, passValidation)
                    : AppLocalizations.of(context)!.fillAllFields,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return;
            }
            Navigator.pop(sheetContext);
            final mid = middleNameController.text.trim();
            final fullName = mid.isNotEmpty
                ? '${firstNameController.text.trim()} $mid ${lastNameController.text.trim()}'
                : '${firstNameController.text.trim()} ${lastNameController.text.trim()}';
            final result = await _authService.enrollStudent(
              name: fullName,
              middleName: mid,
              lrn: lrnController.text.trim(),
              gender: selectedGender,
              username: usernameController.text,
              birthday: selectedBirthday,
              parentName: parentNameController.text.trim(),
              parentContact: parentContactController.text.trim(),
              avatar: selectedAvatar,
            );
            if (!context.mounted) return;
            if (result['status'] == 'Success') {
              _showEnrollmentSuccess(
                usernameController.text,
                lrnController.text.trim(),
                fullName,
              );
            }
          }

          void goNext() {
            // Validate the current step before advancing.
            if (currentStep == 0) {
              if (firstNameController.text.trim().isEmpty ||
                  lastNameController.text.trim().isEmpty) {
                _showStatusDialog(
                  AppLocalizations.of(context)!.fillAllFields,
                  LucideIcons.triangle_alert,
                  Colors.orange,
                );
                return;
              }
            }
            FocusScope.of(sheetStateContext).unfocus();
            setSheetState(() => currentStep++);
          }

          final isLast = currentStep == stepLabels.length - 1;

          return Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.enrollStudent,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLocalizations.of(context)!.stepOf(
                                  currentStep + 1,
                                  stepLabels.length,
                                  stepLabels[currentStep]),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                _buildStepBreadcrumb(
                  labels: stepLabels,
                  current: currentStep,
                  onTap: (i) {
                    // Only allow jumping to already-visited steps.
                    if (i <= currentStep) {
                      FocusScope.of(sheetStateContext).unfocus();
                      setSheetState(() => currentStep = i);
                    }
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: stepContent(),
                    ),
                  ),
                ),
                _buildWizardFooter(
                  showBack: currentStep > 0,
                  onBack: () {
                    FocusScope.of(sheetStateContext).unfocus();
                    setSheetState(() => currentStep--);
                  },
                  primary: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLast ? submit : goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        isLast
                            ? AppLocalizations.of(context)!.enroll
                            : AppLocalizations.of(context)!.next,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEnrollmentSuccess(String username, String lrn, String studentName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.circle_check,
                  color: AppColors.success, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.studentEnrolled,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .studentEnrolledSuccessfully(studentName),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.loginCredentials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(LucideIcons.user,
                              size: 16, color: AppColors.textLight),
                          const SizedBox(width: 12),
                          // No fixed width: the Ilokano label ("Agus-usar:")
                          // measures 130 logical pixels at this font size —
                          // nearly double the 65px this used to be capped
                          // to — and would wrap onto a second line rather
                          // than overflow outright, throwing the row's
                          // height off between locales. Sizing to content
                          // means every locale's label just sits at
                          // whatever width it actually needs.
                          Text(AppLocalizations.of(context)!.userLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 13)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(LucideIcons.copy,
                                size: 16, color: AppColors.primary),
                            onPressed: () async {
                              // Awaited, like the sheet's. This dialog is the
                              // one moment the teacher has to hand these two
                              // strings over, so a silent failure here costs
                              //
                              // Both strings are read now, while the context
                              // is certainly good: this dialog can be closed
                              // while the browser is still deciding.
                              final loc = AppLocalizations.of(context)!;
                              final ok = loc.usernameCopied;
                              final field = loc.userLabel;
                              try {
                                await Clipboard.setData(
                                    ClipboardData(text: username));
                                if (!mounted) return;
                                _showStatusDialog(
                                    ok, LucideIcons.copy, AppColors.primary);
                              } catch (_) {
                                if (!mounted) return;
                                _showCopyByHand(field, username);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(LucideIcons.lock,
                              size: 16, color: AppColors.textLight),
                          const SizedBox(width: 12),
                          // Content-sized to match the label above it — see
                          // the note there.
                          Text(AppLocalizations.of(context)!.passwordLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 13)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lrn,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(LucideIcons.copy,
                                size: 16, color: AppColors.primary),
                            onPressed: () async {
                              // Awaited, like the sheet's. This dialog is the
                              // one moment the teacher has to hand these two
                              // strings over, so a silent failure here costs
                              //
                              // Both strings are read now, while the context
                              // is certainly good: this dialog can be closed
                              // while the browser is still deciding.
                              final loc = AppLocalizations.of(context)!;
                              final ok = loc.passwordCopied;
                              final field = loc.passwordLabel;
                              try {
                                await Clipboard.setData(
                                    ClipboardData(text: lrn));
                                if (!mounted) return;
                                _showStatusDialog(
                                    ok, LucideIcons.copy, AppColors.primary);
                              } catch (_) {
                                if (!mounted) return;
                                _showCopyByHand(field, lrn);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.done,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showStudentInfoSheet(
      {required String studentId, required Map<String, dynamic> studentData}) {
    final nameController = TextEditingController(text: studentData['name']);
    final lrnController = TextEditingController(text: studentData['lrn']);
    // What the child actually types. Equal to the Student Number until a
    // parent changes it; older records predate the split and have only the
    // number.
    final currentPassword =
        (studentData['password'] ?? studentData['lrn'] ?? '').toString();
    final parentChangedPassword = currentPassword.isNotEmpty &&
        currentPassword != (studentData['lrn'] ?? '').toString();
    final parentNameController = TextEditingController(
        text: studentData['parentName'] ??
            (studentData['profile']?['parentName'] ?? ''));
    final parentContactController = TextEditingController(
        text: studentData['parentContact'] ??
            (studentData['profile']?['parentContact'] ?? ''));
    DateTime? selectedBirthday;
    if (studentData['birthday'] != null) {
      selectedBirthday = DateTime.tryParse(studentData['birthday']);
    }
    final username = studentData['username'] ?? '';
    String selectedGender =
        studentData['gender'] ?? (studentData['profile']?['gender'] ?? 'Male');
    String selectedAvatar =
        studentData['avatar'] ?? (studentData['profile']?['avatar'] ?? '');
    if (selectedAvatar.isEmpty) {
      selectedAvatar =
          selectedGender.toLowerCase() == 'female' ? 'girl1' : 'boy1';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetStateContext, setSheetState) {
          Widget stepContent() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(AppLocalizations.of(context)!.chooseAvatar),
                _buildAvatarPicker(
                  selectedAvatar: selectedAvatar,
                  onSelect: (preset) {
                    setSheetState(() {
                      selectedAvatar = preset;
                      // The only place the gender is asked here now.
                      selectedGender =
                          preset.startsWith('girl') ? 'Female' : 'Male';
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionHeader(
                    AppLocalizations.of(context)!.studentInformation),
                _buildCard([
                  _buildTextField(
                    controller: nameController,
                    label: AppLocalizations.of(context)!.fullName,
                    icon: LucideIcons.badge,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final initialToUse = (selectedBirthday != null &&
                              !selectedBirthday!.isBefore(DateTime(1900)) &&
                              !selectedBirthday!.isAfter(DateTime.now()))
                          ? selectedBirthday!
                          : DateTime.now()
                              .subtract(const Duration(days: 365 * 4));
                      final picked = await showDatePicker(
                        context: sheetStateContext,
                        initialDate: initialToUse,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedBirthday = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        label: AppLocalizations.of(context)!.birthday,
                        icon: LucideIcons.cake,
                      ),
                      child: Text(
                        selectedBirthday == null
                            ? AppLocalizations.of(context)!.notSet
                            : "${selectedBirthday!.month}/${selectedBirthday!.day}/${selectedBirthday!.year}",
                        style: TextStyle(
                          color: selectedBirthday == null
                              ? Colors.grey.shade500
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionHeader(
                    AppLocalizations.of(context)!.parentInformation),
                _buildCard([
                  _buildTextField(
                    controller: parentNameController,
                    label: AppLocalizations.of(context)!.parentNameLabel,
                    icon: LucideIcons.users,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: parentContactController,
                    label: AppLocalizations.of(context)!.parentContactLabel,
                    icon: LucideIcons.phone,
                    hintText: '09XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionHeader(
                    AppLocalizations.of(context)!.loginCredentials),
                _buildCard([
                  _buildTextField(
                    controller: lrnController,
                    label: AppLocalizations.of(context)!.lRNPassword,
                    icon: LucideIcons.key_round,
                    hintText: lrnController.text.isEmpty
                        ? AppLocalizations.of(context)!.passwordNotSetYet
                        : null,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _buildCredentialRow(
                    rebuild: setSheetState,
                    label: AppLocalizations.of(context)!.userLabel,
                    value: username,
                    icon: LucideIcons.user,
                    color: AppColors.primary,
                  ),
                  Divider(
                    height: 24,
                    indent: 40,
                    color: Colors.grey.shade200,
                  ),
                  _buildCredentialRow(
                    rebuild: setSheetState,
                    label: AppLocalizations.of(context)!.passwordLabel,
                    secret: true,
                    value: currentPassword.isEmpty
                        ? AppLocalizations.of(context)!.passwordNotSetYet
                        : currentPassword,
                    icon: LucideIcons.lock,
                    color: AppColors.textDark,
                  ),
                  // Worth saying before a teacher reads it out: this is no
                  // longer the number they handed over at enrolment.
                  if (parentChangedPassword) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(LucideIcons.info,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.passwordChangedByParent,
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: Colors.grey.shade600),
                        ),
                      ),
                    ]),
                  ],
                ]),
                const SizedBox(height: 20),
                _buildSectionHeader(
                    AppLocalizations.of(context)!.manageStudent),
                // One button now: the report is reached by tapping the
                // card, not from in here.
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    label: AppLocalizations.of(context)!.remove,
                    icon: LucideIcons.trash_2,
                    color: Colors.red,
                    isFilled: false,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title:
                              Text(AppLocalizations.of(context)!.removeStudent),
                          content: Text(AppLocalizations.of(context)!
                              .confirmRemoveStudent),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child:
                                    Text(AppLocalizations.of(context)!.cancel)),
                            TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(
                                  AppLocalizations.of(context)!.remove,
                                  style: const TextStyle(color: Colors.red),
                                )),
                          ],
                        ),
                      );
                      if (!mounted) return;
                      if (confirm == true) {
                        await _authService.deleteStudent(studentId);
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        _showStatusDialog(
                          AppLocalizations.of(context)!.remove,
                          LucideIcons.trash_2,
                          Colors.red,
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          }

          Future<void> saveUpdate() async {
            if (nameController.text.trim().isEmpty ||
                lrnController.text.trim().isEmpty ||
                parentNameController.text.trim().isEmpty ||
                parentContactController.text.trim().isEmpty) {
              _showStatusDialog(
                AppLocalizations.of(context)!.fillAllFields,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return;
            }
            if (parentContactController.text.trim().length != 11) {
              _showStatusDialog(
                AppLocalizations.of(context)!.contactLengthError,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return;
            }
            try {
              final updateMsg = AppLocalizations.of(context)!.update;
              await _authService.updateStudent(
                studentId: studentId,
                name: nameController.text.trim(),
                lrn: lrnController.text.trim(),
                gender: selectedGender,
                birthday: selectedBirthday,
                parentName: parentNameController.text.trim(),
                parentContact: parentContactController.text.trim(),
                avatar: selectedAvatar,
              );
              if (!mounted) return;
              Navigator.of(context).pop();
              _showStatusDialog(
                updateMsg,
                LucideIcons.circle_check,
                AppColors.success,
              );
            } catch (e) {
              if (!mounted) return;
              _showStatusDialog(
                "${AppLocalizations.of(context)!.error}: ${e.toString()}",
                LucideIcons.circle_alert,
                Colors.red,
              );
            }
          }

          return Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildPresetAvatar(selectedAvatar,
                          size: 56, iconSize: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameController.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: stepContent(),
                  ),
                ),
                _buildWizardFooter(
                  showBack: false,
                  onBack: () {},
                  primary: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: saveUpdate,
                      icon: const Icon(LucideIcons.save, size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.update,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Breadcrumb step indicator for the enroll/edit wizards. Numbered circles
  /// connected by lines, with a label under each. Tapping a step jumps to it.
  Widget _buildStepBreadcrumb({
    required List<String> labels,
    required int current,
    required ValueChanged<int> onTap,
  }) {
    final items = <Widget>[];
    for (int i = 0; i < labels.length; i++) {
      final isActive = i == current;
      final isDone = i < current;
      final circleColor =
          (isActive || isDone) ? AppColors.primary : Colors.grey.shade300;
      items.add(
        GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration:
                      BoxDecoration(color: circleColor, shape: BoxShape.circle),
                  child: Center(
                    child: isDone
                        ? const Icon(LucideIcons.check,
                            size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: isActive ? AppColors.primary : Colors.grey.shade500,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (i < labels.length - 1) {
        items.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(top: 14, left: 2, right: 2),
              color: i < current ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: items),
    );
  }

  /// Sticky footer with an optional Back button and a primary action that
  /// stays above the keyboard so the user never has to scroll to reach it.
  Widget _buildWizardFooter({
    required bool showBack,
    required VoidCallback onBack,
    required Widget primary,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBack) ...[
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(LucideIcons.arrow_left, size: 18),
              label: Text(AppLocalizations.of(context)!.back),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: primary),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: _inputDecoration(label: label, icon: icon).copyWith(
        hintText: hintText,
        counterText: maxLength != null ? '' : null,
      ),
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15),
    );
  }

  /// Which credential rows are currently revealed, by label.
  ///
  /// Per row rather than one flag, so showing the username does not also
  /// show the password.
  final Set<String> _revealed = {};

  /// Puts a credential on screen to be copied by hand.
  ///
  /// The browser refuses the clipboard outside a secure context, which is
  /// every plain-http address that is not localhost -- including the one this
  /// app is served from on the school's own network. Saying "Copied" there
  /// was worse than saying nothing.
  void _showCopyByHand(String label, String value) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(label, style: const TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context)!.copyByHand,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              value,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
    );
  }

  /// One credential, with an eye if it is secret and a copy button.
  ///
  /// [rebuild] is the redraw of whatever is showing this. Drawn inside a
  /// modal sheet -- its own route -- the screen's `setState` flips the reveal
  /// and redraws nothing the teacher can see.
  Widget _buildCredentialRow({
    void Function(VoidCallback)? rebuild,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool secret = false,
  }) {
    final hidden = secret && !_revealed.contains(label);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Row(children: [
                Text(
                  hidden ? _mask(value) : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: hidden ? 1.5 : null,
                  ),
                ),
                if (secret) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => (rebuild ?? setState)(() {
                      if (!_revealed.remove(label)) _revealed.add(label);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                          hidden ? LucideIcons.eye : LucideIcons.eye_off,
                          size: 15,
                          color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () async {
              // Awaited. Unawaited, a refusal became an unhandled async error
              // while the "Copied" dialog went up anyway -- so over plain
              // http, where the browser gives no clipboard, the teacher was
              // told it worked and had nothing to paste.
              try {
                await Clipboard.setData(ClipboardData(text: value));
                if (!mounted) return;
                _showStatusDialog(
                  AppLocalizations.of(context)!.copied,
                  LucideIcons.copy,
                  AppColors.primary,
                );
              } catch (_) {
                if (!mounted) return;
                _showCopyByHand(label, value);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.copy,
                  size: 16, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  /// Keeps the shape of the ID visible without the ID itself.
  ///
  /// `DC-2026-0001` becomes `DC-2026-••••`: the teacher can still tell they
  /// typed one, and which year it belongs to.
  static String _mask(String value) {
    if (value.length <= 4) return '•' * value.length;
    final keep = value.length - 4;
    return value.substring(0, keep) + ('•' * 4);
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isFilled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: isFilled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18, color: color),
              label: Text(label, style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
    );
  }

  Widget _buildPresetAvatar(String preset,
      {required double size, required double iconSize}) {
    // If it's a network URL, show the cached image
    if (preset.startsWith('http')) {
      return CachedAvatar(imageUrl: preset, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarTintForPreset(preset),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        avatarAssetForPreset(preset),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }

  Widget _buildAvatarPicker({
    required String selectedAvatar,
    required Function(String) onSelect,
  }) {
    // These were English literals, so this pair never went through the ARB
    // files while the chips underneath it did -- one selector in Filipino and
    // the one above it not.
    final options = [
      {'key': 'boy1', 'label': AppLocalizations.of(context)!.male},
      {'key': 'girl1', 'label': AppLocalizations.of(context)!.female},
    ];

    return Row(
      children: List.generate(options.length, (i) {
        final preset = options[i]['key']!;
        final label = options[i]['label']!;
        final isSelected = _isSameGenderAvatar(selectedAvatar, preset);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == options.length - 1 ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => onSelect(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade200,
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildPresetAvatar(preset, size: 64, iconSize: 32),
                        if (isSelected)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(LucideIcons.check,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? AppColors.primary : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Treats any boy*/girl* avatar as the same gender selection.
  bool _isSameGenderAvatar(String selected, String preset) {
    final s = selected.toLowerCase();
    if (preset.startsWith('girl')) {
      return s.startsWith('girl') || s == 'female';
    }
    return !(s.startsWith('girl') || s == 'female');
  }

  Widget _buildBirthdayBanner(List<String> names) {
    final label = names.length == 1
        ? names.first
        : '${names.take(2).join(', ')}${names.length > 2 ? ' +${names.length - 2}' : ''}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF99C8), Color(0xFFFFB347)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF99C8).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // A plain notice, not a way into the full celebration: the cake,
      // balloons and fireworks are the child's own moment on their device,
      // not a design shown here too — the teacher just needs to know whose
      // day it is.
      child: Row(
        children: [
          const Text('🎂', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names.length == 1
                      ? 'Birthday today!'
                      : '${names.length} birthdays today!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🎉 $label',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        // Shorter, and without "Manage your classroom" under the title —
        // a teacher who has just signed in as the teacher knows what this is.
        preferredSize: const Size.fromHeight(92),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _confirmLogout,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.arrow_left,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.teacherDashboard,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _HeaderIconButton(
                      icon: LucideIcons.settings,
                      tooltip: AppLocalizations.of(context)!.settingsTitle,
                      onTap: () => context.pushPremium(
                        const TeacherSettingsScreen(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEnrollSheet,
        elevation: 4,
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.user_plus, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.enrollStudent,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF3FF), Color(0xFFFDEFF5)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _studentsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.couldNotLoad));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShimmer();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final studentDocs = snapshot.data!.docs;

            // Detect students celebrating their birthday today.
            final now = DateTime.now();
            final birthdayStudents = <String>[];
            _takenIds.clear();
            for (final doc in studentDocs) {
              final data = doc.data();
              final held = data['lrn']?.toString();
              if (held != null && held.isNotEmpty) _takenIds.add(held);
              final bdayRaw = data['birthday'] ??
                  (data['profile'] as Map<String, dynamic>?)?['birthday'];
              if (bdayRaw is String && bdayRaw.isNotEmpty) {
                final bday = DateTime.tryParse(bdayRaw);
                if (bday != null &&
                    bday.month == now.month &&
                    bday.day == now.day) {
                  final name = data['name']?.toString();
                  if (name != null && name.isNotEmpty) {
                    birthdayStudents.add(name);
                  }
                }
              }
            }

            // Who needs sitting with, and what to teach next.
            //
            // This used to total every star in the class. A number like 847
            // is not a fact about anything a teacher can act on, and the
            // class average said "63%" without saying which child was at 8%.
            final needHelp = <String>{};
            final unseen = <String>{};

            // Behind *the class*, not behind finishing the whole app.
            //
            // This used to be `overall < 0.25`, which in a young class flags
            // everybody including whoever is leading it — a count that always
            // equals the class size tells a teacher nothing. Half of what the
            // middle of the class has reached is a gap a teacher can see in
            // the room, and it moves as the year does.
            final reached = <double>[
              for (final doc in studentDocs)
                (((doc.data()['progress']
                            as Map<String, dynamic>?)?['overallProgress'] ??
                        0.0) as num)
                    .toDouble()
            ]..sort();
            final median = reached.isEmpty ? 0.0 : reached[reached.length ~/ 2];

            for (final doc in studentDocs) {
              final data = doc.data();
              final progress = data['progress'] as Map<String, dynamic>?;
              final overall = (progress?['overallProgress'] ?? 0.0).toDouble();

              // Only a child who has actually started. One who has not is not
              // struggling with the work — they have not met it yet, and that
              // is what "Not seen" is for.
              if (overall > 0 && overall < median / 2) needHelp.add(doc.id);

              final last = data['lastActive'];
              if (last is Timestamp) {
                if (DateTime.now().difference(last.toDate()).inDays >= 7) {
                  unseen.add(doc.id);
                }
              } else {
                // No timestamp at all means they have never synced.
                unseen.add(doc.id);
              }
            }

            // Who just earned what, across the whole class — the one thing
            // this dashboard could not show before: it could open any child
            // and see their badges, but never learn of a new one without
            // going looking for it.
            final recentAchievements = <_RecentAchievement>[];
            for (final doc in studentDocs) {
              final data = doc.data();
              final name = (data['name'] ?? '').toString();
              if (name.isEmpty) continue;
              final profile = data['profile'] as Map<String, dynamic>?;
              final badgeClaimedAt =
                  profile?['badgeClaimedAt'] as Map<String, dynamic>?;
              badgeClaimedAt?.forEach((id, at) {
                final millis = (at as num?)?.toInt();
                if (millis != null) {
                  recentAchievements.add(_RecentAchievement(
                    studentName: name,
                    id: id,
                    isCertificate: false,
                    atMillis: millis,
                  ));
                }
              });
              final certAwardedAt =
                  profile?['certificateAwardedAt'] as Map<String, dynamic>?;
              certAwardedAt?.forEach((id, at) {
                final millis = (at as num?)?.toInt();
                if (millis != null) {
                  recentAchievements.add(_RecentAchievement(
                    studentName: name,
                    id: id,
                    isCertificate: true,
                    atMillis: millis,
                  ));
                }
              });
            }
            recentAchievements.sort((a, b) => b.atMillis.compareTo(a.atMillis));
            final topAchievements = recentAchievements.take(8).toList();

            final q = _searchQuery.trim().toLowerCase();
            var filteredDocs = q.isEmpty
                ? studentDocs
                : studentDocs.where((d) {
                    final data = d.data();
                    final n = (data['name'] ?? '').toString().toLowerCase();
                    final u = (data['username'] ?? '').toString().toLowerCase();
                    return n.contains(q) || u.contains(q);
                  }).toList();

            // A tapped figure narrows the list to the children it counted, so
            // the number is a way in rather than something to read and act on
            // from memory.
            if (_filter == _ClassFilter.needHelp) {
              filteredDocs =
                  filteredDocs.where((d) => needHelp.contains(d.id)).toList();
            } else if (_filter == _ClassFilter.unseen) {
              filteredDocs =
                  filteredDocs.where((d) => unseen.contains(d.id)).toList();
            }

            return Column(
              children: [
                // Three figures a teacher can act on. The last two are
                // registers, not scores: tapping one shows exactly those
                // children and nobody else.
                Padding(
                  // The top gap used to come from the header's own padding.
                  // The header is shorter now and the cards were touching it.
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: IntrinsicHeight(
                    child: Row(
                      // All three take the height of the tallest. Without it
                      // each is as tall as its own text, and the two whose
                      // labels wrap stand taller than the one that does not.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: LucideIcons.users,
                            value: '${studentDocs.length}',
                            label: AppLocalizations.of(context)!.studentsLabel,
                            color: AppColors.primary,
                            index: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filter =
                                _filter == _ClassFilter.needHelp
                                    ? _ClassFilter.none
                                    : _ClassFilter.needHelp),
                            child: _buildStatCard(
                              icon: LucideIcons.life_buoy,
                              value: '${needHelp.length}',
                              label: AppLocalizations.of(context)!.needsHelp,
                              color: const Color(0xFFC2334D),
                              index: 1,
                              active: _filter == _ClassFilter.needHelp,
                              tappable: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filter =
                                _filter == _ClassFilter.unseen
                                    ? _ClassFilter.none
                                    : _ClassFilter.unseen),
                            child: _buildStatCard(
                              icon: LucideIcons.moon,
                              value: '${unseen.length}',
                              label:
                                  AppLocalizations.of(context)!.notSeenRecently,
                              color: const Color(0xFFA8620A),
                              index: 2,
                              active: _filter == _ClassFilter.unseen,
                              tappable: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Who just earned what, class-wide.
                if (topAchievements.isNotEmpty)
                  _buildRecentAchievements(topAchievements),

                // Birthday notification banner
                if (birthdayStudents.isNotEmpty)
                  _buildBirthdayBanner(birthdayStudents),

                // What the shortened list has in common. A two-word
                // label on a counter cannot carry it; this is the moment the
                // teacher needs it, and it is also the way back out.
                if (_filter != _ClassFilter.none)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Material(
                      color: (_filter == _ClassFilter.needHelp
                              ? const Color(0xFFC2334D)
                              : const Color(0xFFA8620A))
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            setState(() => _filter = _ClassFilter.none),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(children: [
                            Icon(LucideIcons.list_filter,
                                size: 14,
                                color: _filter == _ClassFilter.needHelp
                                    ? const Color(0xFFC2334D)
                                    : const Color(0xFFA8620A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _filter == _ClassFilter.needHelp
                                    ? AppLocalizations.of(context)!
                                        .filterBehindNote
                                    : AppLocalizations.of(context)!
                                        .filterQuietNote,
                                style: TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                    color: Colors.grey.shade700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(LucideIcons.x,
                                size: 14, color: Colors.grey.shade500),
                          ]),
                        ),
                      ),
                    ),
                  ),

                // Sits on the list it filters, and nothing else.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: _buildSearchBar(),
                ),

                // Student List
                Expanded(
                  child: filteredDocs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.search,
                                  size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.noStudentsMatch,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          // Room at the foot for the Enrol button, which
                          // floats over this list and was sitting on the last
                          // child's name.
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final studentDoc = filteredDocs[index];
                            final studentId = studentDoc.id;
                            final studentData = studentDoc.data();
                            final name = studentData['name'] ??
                                AppLocalizations.of(context)!.unknownStudent;
                            final username = studentData['username'] ?? '';
                            final progress = studentData['progress']
                                as Map<String, dynamic>?;
                            final profile =
                                studentData['profile'] as Map<String, dynamic>?;
                            final gender = profile?['gender']?.toString() ?? '';
                            final avatar = studentData['avatar'] ??
                                (profile?['avatar']?.toString() ?? '');
                            final resolvedAvatar = avatar.isNotEmpty
                                ? avatar
                                : (gender.toLowerCase() == 'female'
                                    ? 'girl1'
                                    : 'boy1');

                            final overallProgress = progress != null
                                ? (progress['overallProgress'] ?? 0.0)
                                    .toDouble()
                                : 0.0;
                            final stars =
                                profile != null ? (profile['stars'] ?? 0) : 0;
                            final certificates =
                                (profile?['certificates'] as List?)
                                        ?.map((e) => e.toString())
                                        .toList() ??
                                    const <String>[];
                            final hasNewCertificate = certificates
                                .any((c) => !_isCertificateSeen(studentId, c));

                            return StaggeredEntrance(
                              index: index,
                              delayMs: 60,
                              child: Dismissible(
                                key: Key(studentId),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      title: Text(AppLocalizations.of(context)!
                                          .removeStudent),
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .confirmRemoveStudent),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .cancel)),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .remove,
                                                style: const TextStyle(
                                                    color: Colors.red))),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) async {
                                  final removeMsg =
                                      AppLocalizations.of(context)!.remove;
                                  await _authService.deleteStudent(studentId);
                                  if (!mounted) return;
                                  _showStatusDialog(
                                    removeMsg,
                                    LucideIcons.trash_2,
                                    Colors.red,
                                  );
                                },
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade300,
                                        Colors.red,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.trash_2,
                                          color: Colors.white, size: 28),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context)!.remove,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                child: _buildStudentCard(
                                  name: name,
                                  username: username,
                                  overallProgress: overallProgress,
                                  stars: stars,
                                  avatar: resolvedAvatar,
                                  hasNewCertificate: hasNewCertificate,
                                  // The card is the report. It is what a
                                  // teacher opens twenty times a day.
                                  onTap: () {
                                    if (hasNewCertificate) {
                                      _markCertificatesSeen(
                                          studentId, certificates);
                                    }
                                    context.pushPremium(
                                      ForParentsScreen(
                                        viewStudentId: studentId,
                                        viewStudentName: name,
                                        viewStudentData: {
                                          'id': studentId,
                                          'studentId': studentId,
                                          ...studentData,
                                        },
                                      ),
                                    );
                                  },
                                  onEdit: () => _showStudentInfoSheet(
                                    studentId: studentId,
                                    studentData: studentData,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: StaggeredEntrance(
        index: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.users,
                size: 48,
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noStudentsEnrolled,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.tapToEnroll,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchStudents,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              Icon(LucideIcons.search, size: 20, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 18, color: Colors.grey.shade500),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    FocusScope.of(context).unfocus();
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Looked up by id from the recent-achievements feed — keyed once here
  /// rather than a linear search per row.
  static final Map<String, BadgeDef> _badgeById = {
    for (final b in badgeCatalog) b.id: b,
  };

  IconData _achievementIcon(_RecentAchievement entry) {
    if (entry.isCertificate) {
      return allCertificates[entry.id]?.icon ?? LucideIcons.award;
    }
    return _badgeById[entry.id]?.icon ?? LucideIcons.award;
  }

  Color _achievementColor(_RecentAchievement entry) {
    if (entry.isCertificate) {
      return allCertificates[entry.id]?.primaryColor ?? AppColors.primary;
    }
    final def = _badgeById[entry.id];
    return def != null ? Color(def.color) : AppColors.primary;
  }

  String _achievementTitle(_RecentAchievement entry) {
    if (entry.isCertificate) {
      final cert = allCertificates[entry.id];
      if (cert == null) return entry.id;
      final langCode = Provider.of<LanguageProvider>(context, listen: false)
          .currentLanguageCode;
      switch (langCode) {
        case 'fil':
          return cert.titleFil;
        case 'ilo':
          return cert.titleIlo;
        default:
          return cert.title;
      }
    }
    return _badgeTitle(context, entry.id);
  }

  String _badgeTitle(BuildContext context, String id) {
    final loc = AppLocalizations.of(context)!;
    switch (id) {
      case 'firstSteps':
        return loc.badgeFirstStepsTitle;
      case 'alphabet':
        return loc.badgeAlphabetTitle;
      case 'numbers':
        return loc.badgeNumbersTitle;
      case 'colors':
        return loc.badgeColorsTitle;
      case 'shapes':
        return loc.badgeShapesTitle;
      case 'animals':
        return loc.badgeAnimalsTitle;
      case 'bookworm':
        return loc.badgeBookwormTitle;
      case 'starStudent':
        return loc.badgeStarStudentTitle;
      case 'mathWhiz':
        return loc.badgeMathWhizTitle;
      case 'familyHero':
        return loc.badgeFamilyHeroTitle;
      case 'writingStar':
        return loc.badgeWritingStarTitle;
      case 'songbird':
        return loc.badgeSongbirdTitle;
      case 'streakFive':
        return loc.badgeStreakFiveTitle;
      default:
        return id;
    }
  }

  String _relativeTime(int millis) {
    final loc = AppLocalizations.of(context)!;
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(millis));
    if (diff.inMinutes < 1) return loc.justNow;
    if (diff.inMinutes < 60) return loc.timeAgo(diff.inMinutes);
    if (diff.inHours < 24) return loc.hoursAgo(diff.inHours);
    return loc.daysAgo(diff.inDays);
  }

  /// Badges claimed and certificates awarded, newest first, across every
  /// student loaded on this snapshot — capped by the caller (see
  /// `topAchievements`) since this is a glance, not a log.
  Widget _buildRecentAchievements(List<_RecentAchievement> entries) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.sparkles, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 7),
          Text(loc.recentAchievements,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ]),
        const SizedBox(height: 9),
        for (final entry in entries) ...[
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _achievementColor(entry).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_achievementIcon(entry),
                  size: 14, color: _achievementColor(entry)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.achievementEarnedBy(
                    entry.studentName, _achievementTitle(entry)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(_relativeTime(entry.atMillis),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ]),
          const SizedBox(height: 9),
        ],
      ]),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int index,
    bool active = false,
    bool tappable = false,
  }) {
    return StaggeredEntrance(
      index: index,
      delayMs: 40,
      child: Stack(clipBehavior: Clip.none, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            // A filtering card that is on has to say so: a teacher looking at
            // five names must be able to tell that the other twenty are hidden,
            // or they will read the short list as the whole class.
            border: Border.all(
                color: active ? color : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(active ? 0.24 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            // Icons and numbers on one line across all three cards. Centred,
            // a one-line card's icon sat lower than a two-line card's and the
            // row still did not read as a set.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Shown only while the filter is off. Once it is on, the coloured
        // border and tinted ground say it far louder than this could.
        if (tappable && !active)
          Positioned(
            top: 5,
            right: 5,
            child: Icon(LucideIcons.list_filter,
                size: 11, color: color.withOpacity(0.45)),
          ),
      ]),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String username,
    required double overallProgress,
    required int stars,
    required String avatar,
    required bool hasNewCertificate,
    required VoidCallback onTap,
    required VoidCallback onEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                    child: _buildPresetAvatar(avatar, size: 42, iconSize: 21),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        // Three-part Filipino names wrapped to two lines and
                        // pushed the star chip out of line with them.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (hasNewCertificate) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.graduation_cap,
                                  size: 13, color: Color(0xFFB8860B)),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!
                                    .newCertificateBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB8860B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: overallProgress),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      overallProgress >= 0.7
                                          ? AppColors.success
                                          : overallProgress >= 0.4
                                              ? Colors.orange
                                              : AppColors.primary,
                                    ),
                                    minHeight: 6,
                                  );
                                },
                              ),
                            ),
                          ),
                          // The percentage that used to sit here was the
                          // third drawing of one number: this bar, that text,
                          // and the star chip beside them all come from the
                          // same total.
                        ],
                      ),
                    ],
                  ),
                ),

                // Stars
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$stars',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // The one thing on this card that does not open the report.
                // It used to be what tapping the card did, which is why the
                // report had to hide behind the child's face.
                IconButton(
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: AppLocalizations.of(context)!.editStudent,
                  icon: Icon(LucideIcons.square_pen,
                      color: Colors.grey.shade400, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER ICON BUTTON (glassy, for the dashboard top bar)
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
