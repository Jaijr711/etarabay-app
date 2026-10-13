import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import 'login_screen.dart';
import 'package:confetti/confetti.dart';
import '../widgets/custom_header_app_bar.dart';
import '../widgets/cached_avatar.dart';
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Avatar
                  _BirthdayAvatar(userProfile: userProfile),

                  const SizedBox(height: 20),

                  // Name (Responsive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      // First name, the way the dashboard greets them. The
                      // full version is in the card below, where a record
                      // belongs.
                      child: Text(
                        userProfile.name.trim().split(RegExp(r'\s+')).first,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Age and Gender
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${AppLocalizations.of(context)!.yearsOld(userProfile.age)} • ${userProfile.gender.toLowerCase() == 'male' ? '👦 ${AppLocalizations.of(context)!.male}' : '👧 ${AppLocalizations.of(context)!.female}'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Student Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildProfileField(
                          AppLocalizations.of(context)!.fullName,
                          userProfile.name,
                          LucideIcons.user,
                        ),
                        const Divider(height: 20),
                        _buildProfileField(
                          AppLocalizations.of(context)!.birthday,
                          _formatBirthday(context, userProfile.birthday),
                          LucideIcons.cake,
                        ),
                        const Divider(height: 20),
                        _buildProfileField(
                          AppLocalizations.of(context)!.profileAge,
                          AppLocalizations.of(context)!
                              .yearsOld(userProfile.age),
                          LucideIcons.calendar,
                        ),
                        const Divider(height: 20),
                        _buildProfileField(
                          AppLocalizations.of(context)!.gender,
                          userProfile.gender.toLowerCase() == 'male'
                              ? AppLocalizations.of(context)!.male
                              : AppLocalizations.of(context)!.female,
                          // Was LucideIcons.toilet — a restroom sign, not a
                          // gender symbol. The edit dialog below already uses
                          // mars/venus for the same field; this just did not
                          // match it.
                          userProfile.gender.toLowerCase() == 'male'
                              ? LucideIcons.mars
                              : LucideIcons.venus,
                        ),
                        const Divider(height: 20),

                        // Everything from here down is a record rather
                        // than something the child owns: a parent's name and
                        // phone number, and the date the account was made.
                        // They sat between the birthday and the stars at the
                        // same weight, which put a contact number on a page a
                        // four-year-old opens by tapping their own face.
                        _recordsHeading(context),

                        // Parents Info (if student)
                        if (userProvider.currentStudentId != null) ...[
                          _buildProfileField(
                            AppLocalizations.of(context)!.parentNameLabel,
                            userProfile.parentName.isNotEmpty
                                ? userProfile.parentName
                                : AppLocalizations.of(context)!.notSet,
                            LucideIcons.users,
                          ),
                          const Divider(height: 20),
                          _buildProfileField(
                            AppLocalizations.of(context)!.parentContactLabel,
                            userProfile.parentContact.isNotEmpty
                                ? userProfile.parentContact
                                : AppLocalizations.of(context)!.notSet,
                            LucideIcons.phone,
                          ),
                          const Divider(height: 20),
                        ],

                        // Member Since
                        _buildProfileField(
                          AppLocalizations.of(context)!.memberSince,
                          _formatBirthday(
                            context,
                            userProfile.createdAt ?? DateTime.now(),
                          ),
                          LucideIcons.calendar,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    // Two counts, not three. The lessons tally was a record
                    // — a number the child never chose to collect and cannot
                    // read — sitting between the two things they do.
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          // The same number the dashboard and every module
                          // header show. Read straight from the profile, this
                          // was the one star readout in the app that could
                          // disagree with the rest: an older profile can carry
                          // more stars than the app can now award, and
                          // `displayStars` is what caps it.
                          '${userProvider.displayStars}',
                          AppLocalizations.of(context)!.stars,
                          Icons.star_rounded,
                        ),
                        _buildStatItem(
                          // Collected, not merely unlocked — matches the home
                          // screen and the Awards gallery. See home_screen.
                          '${userProvider.collectedBadgeIds.length}',
                          AppLocalizations.of(context)!.badges,
                          LucideIcons.trophy,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Edit Profile Button (Only if NOT student)
                  if (userProvider.currentStudentId == null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showEditProfileDialog(context, userProvider),
                      icon: const Icon(LucideIcons.pencil),
                      label: Text(AppLocalizations.of(context)!.editProfile),
                      style: OutlinedButton.styleFrom(
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

                  // Logout Button
                  TextButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(LucideIcons.log_out, color: Colors.red),
                    label: Text(AppLocalizations.of(context)!.logout,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  /// Marks where the child's page stops and the paperwork starts.
  Widget _recordsHeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Row(
        children: [
          Icon(LucideIcons.users, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 7),
          Text(
            AppLocalizations.of(context)!.forParents.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
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

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
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
          color: Colors.white,
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
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildAvatarContent(),
        ),
      ],
    );
  }
}
