import 'for_parents_screen.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_messages.dart';
import '../services/reminder_service.dart';
import '../services/teacher_pin.dart';
import '../services/teacher_privacy.dart';
import '../services/test_account.dart';
import '../services/update_checker.dart';
import '../utils/constants.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/how_to_video.dart';
import '../widgets/teacher_pin_flow.dart';
import '../widgets/update_dialog.dart';
import 'login_screen.dart';
import '../utils/page_transitions.dart';
import 'student_login_card_screen.dart';
import 'teacher_agreement_screen.dart';
import 'teacher_settings_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Which children the list is narrowed to.
///
/// The two tabs beside "All" are registers, not scores — choosing one shows
/// the children it counted and nobody else, so a teacher can read a number
/// and then go straight to the names behind it.
enum _ClassFilter { none, needHelp, unseen }

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  /// A class to show instead of the one in Firestore, for previews of the
  /// screen at every size. Never set in the app.
  @visibleForTesting
  static Stream<QuerySnapshot<Map<String, dynamic>>>? debugStudents;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  // Made when first used, so the screen can be drawn in a preview with no
  // Firebase behind it.
  late final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  /// The class, subscribed to once for the life of this screen.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream;
  _ClassFilter _filter = _ClassFilter.none;
  String _searchQuery = '';

  /// Children swiped off the list this session (see the Dismissible).
  final Set<String> _removedIds = {};

  /// Each child's record as the class stream last delivered it. The report
  /// is opened with the record of that moment, and its edit button kept
  /// showing it: a second edit there sent the first one's changes back.
  final Map<String, Map<String, dynamic>> _latestRecords = {};

  /// Whether the children's Student Numbers are shown in full. Hidden by default, so
  /// the list can be on screen with someone looking over a shoulder.
  bool _showLrn = false;

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
    _studentsStream = TeacherDashboardScreen.debugStudents ??
        _authService.getStudentsStream();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkAgreement().then((agreed) async {
              if (agreed) {
                await _checkPin();
                // The guide once on each phone, once there is a class to
                // look at; the header's ▶ plays it again.
                if (mounted) {
                  await HowToVideo.showOnce(
                      context, 'teacher', HowToVideo.teacherGuide,
                      pausable: true, parts: HowToVideo.teacherGuideParts);
                }
                await _askNotificationsOnce();
              }
              await _checkForUpdate();
            }));
    _loadSeenCertificates();
  }

  /// The privacy agreement comes before the class, once on each phone.
  /// False when the teacher logged out from it instead.
  Future<bool> _checkAgreement() async {
    if (await TeacherPrivacy.hasAgreed()) return mounted;
    if (!mounted) return false;
    final agreed = await Navigator.of(context).push<bool>(
      PremiumPageRoute(child: const TeacherAgreementScreen()),
    );
    if (agreed == true) return mounted;
    if (mounted) await _logout();
    return false;
  }

  /// Then the PIN that will open the dashboard each time the teacher comes
  /// back to the app, made once on each phone.
  Future<void> _checkPin() async {
    if (await TeacherPin.isSet() || !mounted) return;
    await Navigator.of(context).push<void>(
      PremiumPageRoute(
        child: PopScope(
          canPop: false,
          child: Builder(
            builder: (routeContext) => TeacherPinFlow(
              start: PinFlowStart.create,
              onDone: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
      ),
    );
  }

  /// The phone's own "allow notifications?", once on each phone: the
  /// developer's notices to teachers and word of a new version arrive as
  /// notifications, and a teacher's phone was never asked (only the
  /// parents' switch in the child's settings asks).
  Future<void> _askNotificationsOnce() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (prefs.getBool('teacher_notifications_asked') == true) return;
    await prefs.setBool('teacher_notifications_asked', true);
    await ReminderService.instance.requestPermission();
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

    if (confirm == true) await _logout(userProvider);
  }

  Future<void> _logout([UserProvider? userProvider]) async {
    await (userProvider ?? Provider.of<UserProvider>(context, listen: false))
        .logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PremiumPageRoute(child: const LoginScreen()),
      (route) => false,
    );
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
    // The parent's yes to keeping these details. Nothing is enrolled
    // without it.
    bool consented = false;
    // While the record is being saved: one tap, one child.
    bool enrolling = false;
    // The same words as the section header on each step, and translated —
    // these were three English literals reaching a Filipino teacher inside an
    // otherwise translated sentence.
    final stepLabels = [
      AppLocalizations.of(context)!.studentInformation,
      AppLocalizations.of(context)!.parentInformation,
      AppLocalizations.of(context)!.consentStep,
    ];
    // Each step asks one plain question at the top of the sheet.
    final stepQuestions = [
      AppLocalizations.of(context)!.enrollStepChild,
      AppLocalizations.of(context)!.enrollStepParent,
      AppLocalizations.of(context)!.enrollStepConsent,
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
                    _buildSectionHeader(AppLocalizations.of(context)!.gender),
                    _buildGenderPicker(
                      selectedGender: selectedGender,
                      onSelect: (preset) {
                        setSheetState(() {
                          // The boy or girl face stands in until the child
                          // picks their own picture at their first sign-in.
                          selectedAvatar = preset;
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
              case 1:
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
              default:
                return _buildConsentStep(
                  childName: [
                    firstNameController.text.trim(),
                    if (middleNameController.text.trim().isNotEmpty)
                      '${middleNameController.text.trim()[0]}.',
                    lastNameController.text.trim(),
                  ].join(' '),
                  birthday: selectedBirthday == null
                      ? AppLocalizations.of(context)!.notSet
                      : _formatDateWord(context, selectedBirthday!),
                  parentName: parentNameController.text.trim(),
                  parentContact: parentContactController.text.trim(),
                  consented: consented,
                  onChanged: (v) => setSheetState(() => consented = v),
                );
            }
          }

          /// The parent's name and a reachable number, checked on the way
          /// to the consent step.
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
            if (!consented || !validateParent()) return;
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
            // The form stays open until the child is saved. It used to close
            // first, and a failure — no signal, a username taken — lost
            // everything the teacher had typed.
            setSheetState(() => enrolling = true);
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
              parentConsented: consented,
            );
            if (!mounted || !sheetContext.mounted) return;
            if (result['status'] == 'Error') {
              // Say why nothing was added (no signal, a number taken); the
              // form is still there to fix and send again.
              setSheetState(() => enrolling = false);
              _showStatusDialog(
                authMessage(context, result),
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return;
            }
            Navigator.pop(sheetContext);
            // Pending is a record sent and queued: the login card is good.
            if (result['status'] == 'Pending') {
              _showStatusDialog(
                authMessage(context, result),
                LucideIcons.clock,
                Colors.orange.shade800,
              );
            }
            _showEnrollmentSuccess(
              usernameController.text,
              lrnController.text.trim(),
              fullName,
            );
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
            if (currentStep == 1 && !validateParent()) return;
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: currentStep > 0
                            ? AppLocalizations.of(context)!.back
                            : MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                        icon: Icon(currentStep > 0
                            ? LucideIcons.arrow_left
                            : LucideIcons.x),
                        onPressed: () {
                          if (currentStep > 0) {
                            FocusScope.of(sheetStateContext).unfocus();
                            setSheetState(() => currentStep--);
                          } else {
                            Navigator.pop(sheetContext);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.enrollStudent,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      for (var i = 0; i < stepLabels.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(left: 4),
                          width: 20,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i <= currentStep
                                ? AppColors.primary
                                : const Color(0xFFE6E8EF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .stepNumber(currentStep + 1, stepLabels.length)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stepQuestions[currentStep],
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
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
                      // Enrolling waits for the parent's consent.
                      onPressed: isLast
                          ? (consented && !enrolling ? submit : null)
                          : goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLast && enrolling
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
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

  /// The child's login on a card of its own, to hand to a parent.
  void _openLoginCard({
    required String name,
    required String avatar,
    required String username,
    required String password,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StudentLoginCardScreen(
        name: name,
        avatar: avatar,
        username: username,
        password: password,
      ),
    ));
  }

  /// Copies one credential, or puts it on screen to copy by hand where the
  /// browser refuses the clipboard.
  Future<void> _copyValue(String label, String value) async {
    // Awaited. Unawaited, a refusal became an unhandled async error while
    // the "Copied" note went up anyway -- so over plain http, where the
    // browser gives no clipboard, the teacher was told it worked and had
    // nothing to paste.
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
  }

  /// A child's info in three tabs — the child, the parent, the login — so
  /// none of them is a long scroll, with one save at the foot that only
  /// works once something has changed.
  void _showStudentInfoSheet(
      {required String studentId, required Map<String, dynamic> studentData}) {
    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: studentData['name']);
    // The Student Number is made by the app and shown here, not edited.
    final studentNumber = (studentData['lrn'] ?? '').toString();
    // What the child actually types. Equal to the Student Number until a
    // parent changes it; older records predate the split and have only the
    // number.
    final currentPassword =
        (studentData['password'] ?? studentData['lrn'] ?? '').toString();
    final parentChangedPassword =
        currentPassword.isNotEmpty && currentPassword != studentNumber;
    final parentNameController = TextEditingController(
        text: studentData['parentName'] ??
            (studentData['profile']?['parentName'] ?? ''));
    final parentContactController = TextEditingController(
        text: studentData['parentContact'] ??
            (studentData['profile']?['parentContact'] ?? ''));
    // Covered until the teacher taps the eye beside them.
    bool hideContact = true;
    bool hideBirthday = true;
    bool hideLogin = true;
    DateTime? selectedBirthday;
    if (studentData['birthday'] != null) {
      selectedBirthday = DateTime.tryParse(studentData['birthday']);
    }
    final username = (studentData['username'] ?? '').toString();
    String selectedGender =
        studentData['gender'] ?? (studentData['profile']?['gender'] ?? 'Male');
    String selectedAvatar =
        studentData['avatar'] ?? (studentData['profile']?['avatar'] ?? '');
    if (selectedAvatar.isEmpty) {
      selectedAvatar =
          selectedGender.toLowerCase() == 'female' ? 'girl1' : 'boy1';
    }
    int tab = 0;

    // As the sheet opened, so the save knows whether there is anything new.
    final startName = nameController.text;
    final startParent = parentNameController.text;
    final startContact = parentContactController.text;
    final startGender = selectedGender;
    final startBirthday = selectedBirthday;

    void openLoginCard() => _openLoginCard(
          name: nameController.text,
          avatar: selectedAvatar,
          username: username,
          password: currentPassword,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetStateContext, setSheetState) {
          final changed = nameController.text != startName ||
              parentNameController.text != startParent ||
              parentContactController.text != startContact ||
              selectedGender != startGender ||
              selectedBirthday != startBirthday;

          Widget note(IconData icon, String text) => Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 15, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(text,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: AppColors.textLight)),
                    ),
                  ],
                ),
              );

          Widget childTab() => Column(
                key: const ValueKey('child'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(loc.gender),
                  _buildGenderPicker(
                    selectedGender: selectedGender,
                    onSelect: (preset) {
                      setSheetState(() {
                        selectedGender =
                            preset.startsWith('girl') ? 'Female' : 'Male';
                        // The picture is the child's to choose. Only the
                        // stand-in boy or girl face follows the gender; an
                        // animal the child picked stays.
                        if (!isAnimalAvatar(selectedAvatar)) {
                          selectedAvatar = preset;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(loc.studentInformation),
                  _buildCard([
                    _buildTextField(
                      controller: nameController,
                      label: loc.fullName,
                      icon: LucideIcons.user,
                      onChanged: (_) => setSheetState(() {}),
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
                          label: loc.birthday,
                          icon: LucideIcons.cake,
                        ).copyWith(
                          // Covered like the parent's number until asked for.
                          suffixIcon: selectedBirthday == null
                              ? null
                              : IconButton(
                                  tooltip: hideBirthday
                                      ? loc.showLabel
                                      : loc.hideLabel,
                                  onPressed: () => setSheetState(
                                      () => hideBirthday = !hideBirthday),
                                  icon: Icon(
                                      hideBirthday
                                          ? LucideIcons.eye
                                          : LucideIcons.eye_off,
                                      size: 18,
                                      color: Colors.grey.shade500),
                                ),
                        ),
                        child: Text(
                          selectedBirthday == null
                              ? loc.notSet
                              : hideBirthday
                                  ? '•••• ••, ••••'
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
                  note(LucideIcons.info, loc.childPicksPicture),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text(loc.removeStudent),
                            content: Text(loc.confirmRemoveStudent),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text(loc.cancel)),
                              TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text(
                                    loc.remove,
                                    style: const TextStyle(color: Colors.red),
                                  )),
                            ],
                          ),
                        );
                        if (!mounted || confirm != true) return;
                        // The dashboard's own route: from the report, the
                        // sheet and the report both go, and nothing past
                        // the dashboard does.
                        final dashboardRoute = ModalRoute.of(context);
                        final result =
                            await _authService.deleteStudent(studentId);
                        if (!mounted) return;
                        // Offline nothing was sent: the sheet stays, so the
                        // teacher can see the child is still there.
                        if (result['status'] == 'Error') {
                          _showStatusDialog(authMessage(context, result),
                              LucideIcons.circle_alert, Colors.red);
                          return;
                        }
                        setState(() => _removedIds.add(studentId));
                        // Only the sheet used to close, leaving the teacher
                        // on the report of a child who was gone.
                        Navigator.of(context)
                            .popUntil((r) => r == dashboardRoute || r.isFirst);
                        _showStatusDialog(
                          result['status'] == 'Success'
                              ? loc.studentRemoved
                              : authMessage(context, result),
                          LucideIcons.trash_2,
                          result['status'] == 'Success'
                              ? Colors.red
                              : Colors.orange.shade800,
                        );
                      },
                      icon: const Icon(LucideIcons.trash_2,
                          size: 16, color: Color(0xFFC2334D)),
                      label: Text(
                        loc.removeStudentAction,
                        style: const TextStyle(
                          color: Color(0xFFC2334D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );

          Widget parentTab() => Column(
                key: const ValueKey('parent'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(loc.parentInformation),
                  _buildCard([
                    _buildTextField(
                      controller: parentNameController,
                      label: loc.parentNameLabel,
                      icon: LucideIcons.users,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: parentContactController,
                      label: loc.parentContactLabel,
                      icon: LucideIcons.phone,
                      hintText: '09XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      obscure: hideContact,
                      onToggleObscure: () =>
                          setSheetState(() => hideContact = !hideContact),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ]),
                  note(LucideIcons.shield_check, loc.parentNumberUse),
                ],
              );

          Widget loginRow({
            required IconData icon,
            required String label,
            required String value,
            bool secret = false,
            bool copy = true,
            bool first = false,
          }) {
            final hidden = secret && hideLogin;
            Widget square(IconData i, String tip, VoidCallback onTap) =>
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Material(
                    color: const Color(0xFFF1F2F7),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onTap,
                      child: Tooltip(
                        message: tip,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(i, size: 17, color: AppColors.textLight),
                        ),
                      ),
                    ),
                  ),
                );
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: first
                    ? null
                    : const Border(top: BorderSide(color: Color(0xFFF0F1F5))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFD),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 17, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight)),
                        Text(
                          hidden ? _mask(value) : value,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: hidden ? 1.5 : 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (secret)
                    square(
                      hidden ? LucideIcons.eye : LucideIcons.eye_off,
                      hidden ? loc.showLabel : loc.hideLabel,
                      () => setSheetState(() => hideLogin = !hideLogin),
                    ),
                  if (copy)
                    square(LucideIcons.copy, loc.copied,
                        () => _copyValue(label, value)),
                ],
              ),
            );
          }

          Widget loginTab() => Column(
                key: const ValueKey('login'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(loc.toolLogin),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE6E8EF)),
                    ),
                    child: Column(children: [
                      loginRow(
                        icon: LucideIcons.user,
                        label: loc.loginUser,
                        value: username,
                        first: true,
                      ),
                      loginRow(
                        icon: LucideIcons.key_round,
                        label: loc.password,
                        value: currentPassword.isEmpty
                            ? loc.passwordNotSetYet
                            : currentPassword,
                        secret: currentPassword.isNotEmpty,
                      ),
                      if (studentNumber.isNotEmpty)
                        loginRow(
                          icon: LucideIcons.id_card,
                          label: loc.studentNumberField,
                          value: studentNumber,
                          secret: true,
                          copy: false,
                        ),
                    ]),
                  ),
                  // Worth saying before a teacher reads it out: this is no
                  // longer the number they handed over at enrolment.
                  if (parentChangedPassword) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6E0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.info,
                              size: 16, color: Color(0xFF9A6200)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.passwordChangedByParent,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9A6200),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton.icon(
                      onPressed: openLoginCard,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEEEDFD),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(LucideIcons.id_card, size: 18),
                      label: Text(
                        loc.showLoginCard,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              );

          Widget tabs() {
            final items = [
              (LucideIcons.user, loc.childLabel),
              (LucideIcons.users, loc.parentLabelShort),
              (LucideIcons.key_round, loc.tabLogin),
            ];
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EBF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(sheetStateContext).unfocus();
                          setSheetState(() => tab = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: tab == i ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: tab == i
                                ? const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(items[i].$1,
                                  size: 15,
                                  color: tab == i
                                      ? AppColors.primary
                                      : AppColors.textLight),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  items[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: tab == i
                                        ? AppColors.textDark
                                        : AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          Future<void> saveUpdate() async {
            if (nameController.text.trim().isEmpty ||
                parentNameController.text.trim().isEmpty ||
                parentContactController.text.trim().isEmpty) {
              _showStatusDialog(
                loc.fillAllFields,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return;
            }
            if (parentContactController.text.trim().length != 11) {
              _showStatusDialog(
                loc.contactLengthError,
                LucideIcons.triangle_alert,
                Colors.orange,
              );
              return;
            }
            final name = nameController.text.trim();
            final result = await _authService.updateStudent(
              studentId: studentId,
              name: name,
              middleName: AuthService.keptMiddleName(
                  (studentData['middleName'] ?? '').toString(), name),
              lrn: studentNumber,
              gender: selectedGender,
              birthday: selectedBirthday,
              parentName: parentNameController.text.trim(),
              parentContact: parentContactController.text.trim(),
              avatar: selectedAvatar,
            );
            if (!mounted) return;
            // Removed meanwhile: there is nothing left to edit, and the sheet
            // stayed open on a child who was gone.
            if (result['code'] == 'childRemoved') {
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              _showStatusDialog(authMessage(context, result),
                  LucideIcons.user_x, Colors.orange.shade800);
              return;
            }
            // Not saved: the sheet stays with what was typed.
            if (result['status'] == 'Error') {
              _showStatusDialog(
                authMessage(context, result).isNotEmpty
                    ? authMessage(context, result)
                    : loc.authSaveFailed,
                LucideIcons.circle_alert,
                Colors.red,
              );
              return;
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            _showStatusDialog(
              result['status'] == 'Success'
                  ? loc.update
                  : authMessage(context, result),
              LucideIcons.circle_check,
              result['status'] == 'Success'
                  ? AppColors.success
                  : Colors.orange.shade800,
            );
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
                tabs(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: switch (tab) {
                        0 => childTab(),
                        1 => parentTab(),
                        _ => loginTab(),
                      },
                    ),
                  ),
                ),
                _buildWizardFooter(
                  showBack: false,
                  onBack: () {},
                  primary: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      // Nothing to save until something has changed.
                      onPressed: changed ? saveUpdate : null,
                      icon: const Icon(LucideIcons.save, size: 20),
                      label: Text(
                        changed ? loc.saveChanges : loc.noChanges,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE4E1FB),
                        disabledForegroundColor: const Color(0xFF7D76E3),
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

  /// The last enrol step: what is about to be kept, and the parent's yes.
  ///
  /// The number is shown with its middle covered, as everywhere else; the
  /// teacher typed it a moment ago and only needs to recognise it.
  Widget _buildConsentStep({
    required String childName,
    required String birthday,
    required String parentName,
    required String parentContact,
    required bool consented,
    required ValueChanged<bool> onChanged,
  }) {
    final loc = AppLocalizations.of(context)!;
    final contact = parentContact.length > 7
        ? '${parentContact.substring(0, 4)} ••• ${parentContact.substring(parentContact.length - 4)}'
        : parentContact;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(loc.reviewBeforeEnroll),
        _buildCard([
          row(loc.childLabel, childName),
          row(loc.birthday, birthday),
          row(loc.parentLabelShort, parentName),
          row(loc.numberLabel, contact),
        ]),
        const SizedBox(height: 16),
        Material(
          color: consented ? const Color(0xFFF4F3FE) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: consented ? AppColors.primary : const Color(0xFFE6E8EF),
              width: 2,
            ),
          ),
          child: CheckboxListTile(
            value: consented,
            onChanged: (v) => onChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              loc.parentConsentCheck,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.scale, size: 15, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loc.consentLawNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
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
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    final loc = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscure,
      decoration: _inputDecoration(label: label, icon: icon).copyWith(
        hintText: hintText,
        counterText: maxLength != null ? '' : null,
        // A child's private detail, covered until the teacher asks for it.
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                tooltip: obscure ? loc.showLabel : loc.hideLabel,
                onPressed: onToggleObscure,
                icon: Icon(obscure ? LucideIcons.eye : LucideIcons.eye_off,
                    size: 18, color: Colors.grey.shade500),
              ),
      ),
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15),
    );
  }

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

  /// Keeps the shape of the ID visible without the ID itself.
  ///
  /// `DC-2026-0001` becomes `DC-2026-••••`: the teacher can still tell they
  /// typed one, and which year it belongs to.
  static String _mask(String value) {
    if (value.length <= 4) return '•' * value.length;
    final keep = value.length - 4;
    return value.substring(0, keep) + ('•' * 4);
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

  /// Boy or girl. The picture itself is the child's to choose, at their
  /// first sign-in and from their profile, so the teacher sets only this.
  Widget _buildGenderPicker({
    required String selectedGender,
    required Function(String) onSelect,
  }) {
    // Translated labels: these were once English literals in a Filipino
    // sheet.
    final options = [
      (key: 'boy1', label: AppLocalizations.of(context)!.male),
      (key: 'girl1', label: AppLocalizations.of(context)!.female),
    ];

    return Row(
      children: List.generate(options.length, (i) {
        final preset = options[i].key;
        final label = options[i].label;
        final isSelected = preset.startsWith('girl') ==
            (selectedGender.toLowerCase() == 'female');
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
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF4F3FE) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE6E8EF),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                // A small boy or girl face beside the word, as in the
                // design. The child's own picture is chosen by the child.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPresetAvatar(preset, size: 30, iconSize: 15),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),
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
                  AppLocalizations.of(context)!.birthdayToday(names.length),
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
                      icon: LucideIcons.circle_play,
                      tooltip: AppLocalizations.of(context)!.teacherHowToUse,
                      onTap: () => HowToVideo.show(
                          context, HowToVideo.teacherGuide,
                          pausable: true, parts: HowToVideo.teacherGuideParts),
                    ),
                    const SizedBox(width: 8),
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

            // Without the ones just swiped away: the list has to let go of a
            // dismissed card at once, before the class stream catches up.
            final studentDocs = [
              for (final d in snapshot.data!.docs)
                if (!_removedIds.contains(d.id)) d,
            ];

            // Detect students celebrating their birthday today.
            final now = DateTime.now();
            final birthdayStudents = <String>[];
            _takenIds.clear();
            for (final doc in studentDocs) {
              final data = doc.data();
              _latestRecords[doc.id] = data;
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
                // Says that the lock is on, then three registers a teacher
                // can act on. "Falling behind" and "Not playing" are lists,
                // not scores: choosing one shows exactly those children.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProtectedBadge(),
                      const SizedBox(height: 10),
                      _buildFilterTabs(
                        all: studentDocs.length,
                        needHelp: needHelp.length,
                        unseen: unseen.length,
                      ),
                    ],
                  ),
                ),

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
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 8),
                      _buildLrnToggle(),
                    ],
                  ),
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
                                // The removal happens here, before the card
                                // is let go. It was done after, in
                                // onDismissed: offline nothing was removed,
                                // the card was gone anyway, and Flutter
                                // stopped on a dismissed card still in the
                                // list. Now a removal that was not sent
                                // springs the card back and says why.
                                confirmDismiss: (direction) async {
                                  final loc = AppLocalizations.of(context)!;
                                  final sure = await showDialog<bool>(
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
                                  if (sure != true || !mounted) return false;
                                  final result = await _authService
                                      .deleteStudent(studentId);
                                  if (!mounted) return false;
                                  final removed = result['status'] != 'Error';
                                  _showStatusDialog(
                                    result['status'] == 'Success'
                                        ? loc.studentRemoved
                                        : authMessage(this.context, result),
                                    removed
                                        ? LucideIcons.trash_2
                                        : LucideIcons.circle_alert,
                                    result['status'] == 'Success'
                                        ? Colors.red
                                        : removed
                                            ? Colors.orange.shade800
                                            : Colors.red,
                                  );
                                  return removed;
                                },
                                onDismissed: (direction) =>
                                    setState(() => _removedIds.add(studentId)),
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
                                  lrn: (studentData['lrn'] ?? '').toString(),
                                  overallProgress: overallProgress,
                                  stars: stars,
                                  avatar: resolvedAvatar,
                                  hasNewCertificate: hasNewCertificate,
                                  testAccount:
                                      studentData[TestAccount.field] == true,
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
                                        // The record as it is now, not as
                                        // the report was opened.
                                        onEditInfo: () => _showStudentInfoSheet(
                                          studentId: studentId,
                                          studentData:
                                              _latestRecords[studentId] ??
                                                  studentData,
                                        ),
                                        onShowLogin: () {
                                          final now =
                                              _latestRecords[studentId] ??
                                                  studentData;
                                          _openLoginCard(
                                            name: name,
                                            avatar: resolvedAvatar,
                                            username:
                                                (now['username'] ?? username)
                                                    .toString(),
                                            password: (now['password'] ??
                                                    now['lrn'] ??
                                                    '')
                                                .toString(),
                                          );
                                        },
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
                                    studentData: _latestRecords[studentId] ??
                                        studentData,
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

  /// Tells the teacher the class is behind the lock, every time they look.
  Widget _buildProtectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.shield_check,
              size: 16, color: Color(0xFF1F7A45)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.protectedBadge,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F7A45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// All / Falling behind / Not playing, each with how many it holds.
  Widget _buildFilterTabs({
    required int all,
    required int needHelp,
    required int unseen,
  }) {
    final loc = AppLocalizations.of(context)!;
    Widget tab(_ClassFilter filter, String label, int count, Color color) {
      final on = _filter == filter;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _filter = filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: on
                  ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: on ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: on ? color : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: on ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBF2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tab(_ClassFilter.none, loc.allStudentsTab, all, AppColors.primary),
            tab(_ClassFilter.needHelp, loc.needsHelp, needHelp,
                const Color(0xFFC2334D)),
            tab(_ClassFilter.unseen, loc.notSeenRecently, unseen,
                const Color(0xFFA8620A)),
          ],
        ),
      ),
    );
  }

  /// Shows or hides every child's Student Number at once. Only the eye: the
  /// words are too long to sit beside the search box in every language.
  Widget _buildLrnToggle() {
    final loc = AppLocalizations.of(context)!;
    return Tooltip(
      message:
          '${_showLrn ? loc.hideLabel : loc.showLabel}: ${loc.studentNumberField}',
      child: Material(
        color: _showLrn ? const Color(0xFFEEEDFD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _showLrn = !_showLrn),
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showLrn
                    ? const Color(0xFFCFCBF8)
                    : const Color(0xFFE6E8EF),
              ),
            ),
            child: Icon(
              _showLrn ? LucideIcons.eye : LucideIcons.eye_off,
              size: 20,
              color: _showLrn ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }

  /// The last four digits only, enough to tell two children apart.
  static String _maskedLrn(String lrn) =>
      lrn.length <= 4 ? '••••' : '••••••••${lrn.substring(lrn.length - 4)}';

  Widget _buildStudentCard({
    required String name,
    required String username,
    required String lrn,
    required double overallProgress,
    required int stars,
    required String avatar,
    required bool hasNewCertificate,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    bool testAccount = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    final barColor = overallProgress >= 0.7
        ? AppColors.success
        : overallProgress >= 0.4
            ? Colors.orange
            : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: _buildPresetAvatar(avatar, size: 40, iconSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The whole width for the name: with the badge
                          // beside it, a small phone showed "Ana Mendo...".
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  lrn.isEmpty
                                      ? '@$username'
                                      : '${loc.studentNumberField} '
                                          '${_showLrn ? lrn : _maskedLrn(lrn)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                    color: Colors.grey.shade500,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                              if (hasNewCertificate) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: loc.newCertificateBadge,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3D6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.graduation_cap,
                                            size: 12, color: Color(0xFF9A6200)),
                                        const SizedBox(width: 3),
                                        Text(
                                          loc.newBadgeShort,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF9A6200),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              // The developer finished this one for testing:
                              // not to be read as the child's own work.
                              if (testAccount) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: loc.testAccountNote,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEDFD),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.flask_conical,
                                            size: 12, color: Color(0xFF5C52E5)),
                                        const SizedBox(width: 3),
                                        Text(
                                          loc.testAccountTag,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF5C52E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // The one thing on this card that does not open the
                    // report.
                    IconButton(
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      tooltip: loc.editStudent,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F2F7),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(LucideIcons.square_pen,
                          color: AppColors.textLight, size: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(barColor),
                                minHeight: 7,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(overallProgress * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 17),
                      const SizedBox(width: 2),
                      Text(
                        '$stars',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFFB8860B),
                        ),
                      ),
                    ],
                  ),
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
