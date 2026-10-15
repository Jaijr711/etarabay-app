import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import 'login_screen.dart';
import 'choose_avatar_screen.dart';
import 'package:confetti/confetti.dart';
import '../widgets/custom_header_app_bar.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/question_cloud.dart' show DoodleBackground;
import '../widgets/storybook.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getMonthName(BuildContext context, int month) {
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
    if (month >= 1 && month <= 12) {
      return (lang == 'fil' || lang == 'ilo') ? fil[month - 1] : en[month - 1];
    }
    return AppLocalizations.of(context)!.monthName(month);
  }

  String _formatBirthday(BuildContext context, DateTime? birthday) {
    if (birthday == null) return AppLocalizations.of(context)!.notSet;
    return '${_getMonthName(context, birthday.month)} ${birthday.day}, ${birthday.year}';
  }

  /// Signs out, but never on one tap.
  ///
  /// This screen is reached by a child tapping their own face on the
  /// dashboard, and the button used to wipe the session immediately. The way
  /// back in is an LRN — which a four-year-old cannot type — so a single
  /// mis-tap locked them out of their own app until an adult arrived.
  ///
  /// The question is deliberately plain rather than playful: it is meant for
  /// whoever is holding the phone, and a child who cannot read it should find
  /// nothing here that looks like a game.
  void _logout(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.logout,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Ends the session; does not erase the child.
    //
    // This used to call `clearLocalData()`, which empties the profile box,
    // the progress box and every progress key in SharedPreferences. On a
    // phone that had been played on offline — the normal case here — that is
    // the child's week, gone on one tap, behind a dialog that only asks
    // whether they want to log out. The parent's account switcher has
    // guarded against exactly this all along: it pushes the work to the
    // cloud first and refuses to switch if it cannot.
    //
    // `logout()` keeps the record where it is. The same child signing back in
    // finds their work, and a *different* child signing in wipes it anyway —
    // `startStudentSession` does that when the id changes, which is the one
    // moment a wipe is actually meant.
    await Provider.of<UserProvider>(context, listen: false).logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PremiumPageRoute(child: const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomHeaderAppBar(
        title: AppLocalizations.of(context)!.myProfile,
        baseColor: AppColors.secondary,
      ),
      body: userProfile == null
          ? Center(child: Text(AppLocalizations.of(context)!.noProfileData))
          : Stack(children: [
              // The notebook doodles of the learning boards.
              const Positioned.fill(child: DoodleBackground()),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                child: Column(
                  children: [
                    // The child: their picture standing up out of a framed
                    // card, their first name under it.
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 64, 12, 0),
                          child: _nameCard(
                            // First name, the way the dashboard greets them.
                            // The full version is in the card below.
                            userProfile.name.trim().split(RegExp(r'\s+')).first,
                          ),
                        ),
                        // Tap the face to choose another picture.
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PremiumPageRoute(child: const ChooseAvatarScreen()),
                          ),
                          child: Stack(clipBehavior: Clip.none, children: [
                            _BirthdayAvatar(userProfile: userProfile),
                            // A pencil, so it reads as something to press.
                            Positioned(
                              right: 2,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF7A59),
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0xFFC9502F),
                                        offset: Offset(0, 3)),
                                  ],
                                ),
                                child: const Icon(LucideIcons.pencil,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),

                    // The record, in the coral frame. The age and gender
                    // pill sits across its top edge, as in the design.
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        CoralCard(
                          fillFrame: false,
                          padding: const EdgeInsets.fromLTRB(12, 30, 12, 16),
                          child: Column(children: [
                            _fieldRow(
                              _buildProfileField(
                                AppLocalizations.of(context)!.fullName,
                                userProfile.name,
                                LucideIcons.user,
                                const Color(0xFFF08A24),
                              ),
                              _buildProfileField(
                                AppLocalizations.of(context)!.birthday,
                                _formatBirthday(context, userProfile.birthday),
                                LucideIcons.cake,
                                const Color(0xFFE85A8A),
                              ),
                            ),
                            _fieldRow(
                              _buildProfileField(
                                AppLocalizations.of(context)!.profileAge,
                                AppLocalizations.of(context)!
                                    .yearsOld(userProfile.age),
                                LucideIcons.calendar,
                                const Color(0xFF3FA36B),
                              ),
                              _buildProfileField(
                                AppLocalizations.of(context)!.gender,
                                userProfile.gender.toLowerCase() == 'male'
                                    ? AppLocalizations.of(context)!.male
                                    : AppLocalizations.of(context)!.female,
                                // mars/venus, as in the edit dialog below —
                                // not the restroom sign it once was.
                                userProfile.gender.toLowerCase() == 'male'
                                    ? LucideIcons.mars
                                    : LucideIcons.venus,
                                const Color(0xFF3F6FD8),
                              ),
                            ),

                            // Everything from here down is a record rather
                            // than something the child owns: a parent's name
                            // and phone number, and the date the account was
                            // made — set apart under its own heading.
                            _recordsHeading(context),

                            if (userProvider.currentStudentId != null)
                              _fieldRow(
                                _buildProfileField(
                                  AppLocalizations.of(context)!.parentNameLabel,
                                  userProfile.parentName.isNotEmpty
                                      ? userProfile.parentName
                                      : AppLocalizations.of(context)!.notSet,
                                  LucideIcons.users,
                                  const Color(0xFFD9558F),
                                ),
                                _buildProfileField(
                                  AppLocalizations.of(context)!
                                      .parentContactLabel,
                                  userProfile.parentContact.isNotEmpty
                                      ? userProfile.parentContact
                                      : AppLocalizations.of(context)!.notSet,
                                  LucideIcons.phone,
                                  const Color(0xFF7A5BD9),
                                ),
                              ),
                            // The whole width, short of where the dino
                            // stands.
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 7, 72, 7),
                              child: _buildProfileField(
                                AppLocalizations.of(context)!.memberSince,
                                _formatBirthday(
                                  context,
                                  userProfile.createdAt ?? DateTime.now(),
                                ),
                                LucideIcons.calendar_check,
                                const Color(0xFF6B78C9),
                              ),
                            ),
                          ]),
                        ),
                        Positioned(
                          top: -20,
                          child: _agePill(context, userProfile),
                        ),
                        const Positioned(
                          right: -12,
                          bottom: -18,
                          width: 92,
                          child: IgnorePointer(
                            child: Image(
                              image: AssetImage(StorybookScaffold.dinoAsset),
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // Two counts, not three — the two things the child
                    // collects. The same star number the dashboard and every
                    // module header show (`displayStars` is what caps an
                    // older profile), and badges collected, not merely
                    // unlocked, as on the home screen and the Awards wall.
                    _statsBar(
                      context,
                      stars: userProvider.displayStars,
                      badges: userProvider.collectedBadgeIds.length,
                    ),

                    const SizedBox(height: 22),

                    // Edit Profile (only when not signed in as a student).
                    if (userProvider.currentStudentId == null) ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showEditProfileDialog(context, userProvider),
                        icon: const Icon(LucideIcons.pencil),
                        label: Text(AppLocalizations.of(context)!.editProfile),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _LogoutButton(
                      label: AppLocalizations.of(context)!.logout,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ]),
    );
  }

  static TextStyle _fredoka(double size, Color color, {double weight = 700}) =>
      TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        fontVariations: [FontVariation('wght', weight)],
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.15,
      );

  static const _navy = StorybookScaffold.navy;

  /// The child's first name on a pale pink card in a blue frame; the
  /// picture stands half out of its top.
  Widget _nameCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C8FE6), Color(0xFF8B7FE0)],
        ),
        border: Border.all(color: const Color(0xFF4E63B8), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 74, 16, 34),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E7EE),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            maxLines: 1,
            style: _fredoka(46, _navy, weight: 650),
          ),
        ),
      ),
    );
  }

  /// "4 years old • 👦 Male", in a lavender pill.
  Widget _agePill(BuildContext context, dynamic userProfile) {
    final loc = AppLocalizations.of(context)!;
    final male = userProfile.gender.toLowerCase() == 'male';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE3FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7D93DC), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB7C3EE), offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        '${loc.yearsOld(userProfile.age)} • '
        '${male ? '👦 ${loc.male}' : '👧 ${loc.female}'}',
        style: _fredoka(17, _navy, weight: 600),
      ),
    );
  }

  /// Two fields side by side.
  Widget _fieldRow(Widget a, Widget b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: a),
          const SizedBox(width: 8),
          Expanded(child: b),
        ],
      ),
    );
  }

  /// The heavy stars-and-badges bar.
  Widget _statsBar(BuildContext context,
      {required int stars, required int badges}) {
    final loc = AppLocalizations.of(context)!;
    final shadow = [
      Shadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2)),
    ];
    Widget count(String image, int n, String label) => Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(image,
                  width: 54, height: 54, filterQuality: FilterQuality.medium),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$n',
                          style: _fredoka(34, Colors.white)
                              .copyWith(height: 1.0, shadows: shadow)),
                      Text(label,
                          style: _fredoka(18, Colors.white, weight: 600)
                              .copyWith(shadows: shadow)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6BE0), Color(0xFF9A6BDF), Color(0xFFE065B6)],
        ),
        border: Border.all(color: const Color(0xFF3A2F7A), width: 3),
        boxShadow: [
          const BoxShadow(color: Color(0xFF2E2563), offset: Offset(0, 5)),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(children: [
        count('assets/images/replay_star.webp', stars, loc.stars),
        count('assets/images/trophy_happy.webp', badges, loc.badges),
      ]),
    );
  }

  /// Marks where the child's page stops and the paperwork starts.
  Widget _recordsHeading(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 2.5,
        decoration: BoxDecoration(
          color: const Color(0xFFC7D0EE),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              AppLocalizations.of(context)!.forParents.toUpperCase(),
              style: _fredoka(17, _navy),
            ),
          ),
          line,
        ],
      ),
    );
  }

  Widget _buildProfileField(
      String label, String value, IconData icon, Color tint) {
    return Row(
      children: [
        // The picture in a round badge, the way the design draws each one.
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(tint, Colors.white, 0.86),
            border: Border.all(color: const Color(0xFF8FA4DF), width: 2.5),
          ),
          child: Icon(icon, color: tint, size: 22),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A long label ("Buong Pangalan") shrinks to fit its column
              // rather than being cut off.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: _fredoka(13.5, _navy, weight: 600),
                ),
              ),
              // A short value — a date, an age — stays on one line, shrinking
              // a little if it must; "September / 23, 2022" broken in two
              // read as two things. A long name still wraps.
              value.length <= 20
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value,
                          maxLines: 1, style: _fredoka(15.5, _navy)),
                    )
                  : Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _fredoka(15, _navy),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProvider provider) {
    final nameController =
        TextEditingController(text: provider.userProfile?.name);
    DateTime? selectedDate = provider.userProfile?.birthday;
    String selectedGender =
        provider.userProfile?.gender.toLowerCase() == 'female'
            ? AppLocalizations.of(context)!.female
            : AppLocalizations.of(context)!.male;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.editProfile,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.fullName,
                  hintText: AppLocalizations.of(context)!.enterName,
                  prefixIcon:
                      const Icon(LucideIcons.user, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.cake, color: AppColors.primary),
                ),
                title: Text(AppLocalizations.of(context)!.birthday,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(_formatBirthday(context, selectedDate),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                trailing: const Icon(LucideIcons.chevron_right),
                onTap: () async {
                  final initialToUse = (selectedDate != null &&
                          !selectedDate!.isBefore(DateTime(1900)) &&
                          !selectedDate!.isAfter(DateTime.now()))
                      ? selectedDate!
                      : DateTime(2015);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialToUse,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.gender,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _GenderOption(
                    label: AppLocalizations.of(context)!.male,
                    icon: LucideIcons.mars,
                    isSelected:
                        selectedGender == AppLocalizations.of(context)!.male,
                    onTap: () => setModalState(() =>
                        selectedGender = AppLocalizations.of(context)!.male),
                  ),
                  const SizedBox(width: 12),
                  _GenderOption(
                    label: AppLocalizations.of(context)!.female,
                    icon: LucideIcons.venus,
                    isSelected:
                        selectedGender == AppLocalizations.of(context)!.female,
                    onTap: () => setModalState(() =>
                        selectedGender = AppLocalizations.of(context)!.female),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await provider.updateUserProfile(
                      name: nameController.text.trim(),
                      gender: selectedGender.toLowerCase(),
                      birthday: selectedDate,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(AppLocalizations.of(context)!.saveChanges,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BirthdayAvatar extends StatefulWidget {
  final dynamic userProfile;

  const _BirthdayAvatar({required this.userProfile});

  @override
  State<_BirthdayAvatar> createState() => _BirthdayAvatarState();
}

class _BirthdayAvatarState extends State<_BirthdayAvatar> {
  late ConfettiController _confettiController;
  bool _isBirthday = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    final birthday = widget.userProfile?.birthday;
    if (birthday != null) {
      final today = DateTime.now();
      if (birthday.month == today.month && birthday.day == today.day) {
        _isBirthday = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _confettiController.play();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildAvatarContent() {
    final avatar = widget.userProfile?.avatar?.toString() ?? '';

    // Network image URL (cached for offline)
    if (avatar.startsWith('http')) {
      return CachedAvatar(imageUrl: avatar, size: 120);
    }

    // Preset character image (male / female)
    if (avatar.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          avatarAssetForPreset(avatar),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }

    // Fallback to initial letter
    return Center(
      child: Text(
        (widget.userProfile?.name != null && widget.userProfile.name.isNotEmpty)
            ? widget.userProfile.name[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3C5BC4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isBirthday)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        // A white disc in a deep blue ring with a pale halo, as the design
        // draws it, standing half out of the name card.
        Container(
          width: 136,
          height: 136,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF3C5BC4), width: 5),
            boxShadow: [
              const BoxShadow(color: Color(0xFFD5DEF7), spreadRadius: 5),
              BoxShadow(
                color: const Color(0xFF3C5BC4).withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(child: _buildAvatarContent()),
        ),
      ],
    );
  }
}

/// Logout as the design draws it: a glossy coral pill with a white rim.
/// It still asks before signing out — see [ProfileScreen._logout].
class _LogoutButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _LogoutButton({required this.label, required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 80),
        offset: Offset(0, _down ? 0.05 : 0),
        child: Container(
          height: 62,
          constraints: const BoxConstraints(minWidth: 200),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFB3382B),
                  offset: Offset(0, _down ? 2 : 5)),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF9384), Color(0xFFEE4B3B)],
              ),
              border: Border.all(color: const Color(0xFFC9392B), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.log_out, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 26,
                  fontVariations: [FontVariation('wght', 700)],
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0xFFA9301F), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
