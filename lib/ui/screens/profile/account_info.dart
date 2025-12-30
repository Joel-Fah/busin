import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/models/actors/student.dart';
import 'package:busin/ui/components/widgets/buttons/primary_button.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:busin/ui/components/widgets/metadata_section.dart';
import 'package:busin/ui/components/widgets/user_avatar.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  static const String routeName = '/account-info';

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _programController = TextEditingController();

  Gender? _selectedGender;
  String? _selectedDepartment;
  String? _selectedProgram;
  bool _isEditMode = false;
  bool _isSaving = false;

  List<String> get _availablePrograms {
    if (_selectedDepartment == null) return [];
    return programsByDepartment[_selectedDepartment] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _matriculeController.dispose();
    _departmentController.dispose();
    _programController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    _phoneController.text = user.phone ?? '';
    _selectedGender = user.gender ?? Gender.preferNotToSay;

    if (user is Student) {
      _addressController.text = user.address ?? '';
      _matriculeController.text = user.matricule ?? '';
      _departmentController.text = user.department ?? '';
      _programController.text = user.program ?? '';

      // Set selected values
      _selectedDepartment = user.department;
      _selectedProgram = user.program;
    }
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _authController.currentUser.value;
      if (user == null) return;

      // Fallback to preferNotToSay if no gender selected
      final genderToSave = _selectedGender ?? Gender.preferNotToSay;

      final Map<String, dynamic> updates = {
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'gender': genderToSave.name,
      };

      if (user is Student) {
        updates.addAll({
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          'matricule': _matriculeController.text.trim().toUpperCase(),
          'department': _selectedDepartment,
          'program': _selectedProgram,
        });
      }

      // Use auth controller's updateUserProfile method
      await _authController.updateUserProfile(updates);

      if (!mounted) return;

      setState(() {
        _isEditMode = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.check_circle, color: lightColor),
            label: Text(l10n.accountInfoPage_updateSuccessful),
            backgroundColor: successColor,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text('${l10n.accountInfoPage_updateFailed} ${e.toString()}'),
            backgroundColor: errorColor,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      // Cancel editing - reload data
      _loadUserData();
    }
    setState(() {
      _isEditMode = !_isEditMode;
    });
    HapticFeedback.lightImpact();
  }

  bool get _hasIncompleteInfo {
    final user = _authController.currentUser.value;
    if (user == null) return false;

    bool hasPhone = user.phone != null && user.phone!.isNotEmpty;

    if (user is Student) {
      bool hasAddress = user.address != null && user.address!.isNotEmpty;
      bool hasMatricule = user.matricule != null && user.matricule!.isNotEmpty;
      return !hasPhone || !hasAddress || !hasMatricule;
    }

    return !hasPhone;
  }

  List<String> get _missingFields {
    final l10n = AppLocalizations.of(context)!;
    final user = _authController.currentUser.value;
    if (user == null) return [];

    List<String> missing = [];

    if (user.phone == null || user.phone!.isEmpty) {
      missing.add(l10n.accountInfoPage_editableField_phoneNumber);
    }

    if (user is Student) {
      if (user.matricule == null || user.matricule!.isEmpty) {
        missing.add(l10n.accountInfoPage_editableField_studentID);
      }
      if (user.address == null || user.address!.isEmpty) {
        missing.add(l10n.accountInfoPage_editableField_streetAddress);
      }
    }

    return missing;
  }

  String get _authProvider {
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return 'Unknown';

    final providerData = fbUser.providerData;
    if (providerData.isEmpty) return 'Email';

    final providerId = providerData.first.providerId;
    if (providerId.contains('google')) return 'Google [@ictuniversity.edu.cm]';
    if (providerId.contains('facebook')) return 'Facebook';
    if (providerId.contains('apple')) return 'Apple';

    return providerId;
  }

  bool get _hasDisplayName {
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    return fbUser?.displayName != null && fbUser!.displayName!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If in edit mode, exit edit mode instead of popping
        if (_isEditMode) {
          _toggleEditMode();
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.contain,
              child: Text(l10n.profilePage_listTile_accountInfo),
            ),
            bottom: _hasIncompleteInfo && !_isEditMode
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(88.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ).copyWith(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditMode = true;
                          });
                          HapticFeedback.lightImpact();
                        },
                        child:
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: warningColor.withValues(alpha: 0.1),
                                    borderRadius: borderRadius * 2.25,
                                    border: Border.all(
                                      color: warningColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: HugeIcon(
                                      icon: warningIcon,
                                      color: warningColor,
                                    ),
                                    title: Row(
                                      spacing: 4.0,
                                      children: [
                                        Text(
                                          l10n.profilePage_accountInfo_subtitle,
                                          style: AppTextStyles.h4.copyWith(
                                            color: warningColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${l10n.accountInfoPage_missingLabel} ${_missingFields.join(', ')}',
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: -0.3, end: 0),
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: HugeIcon(
                  icon: _isEditMode
                      ? HugeIcons.strokeRoundedCancelCircle
                      : HugeIcons.strokeRoundedEdit02,
                  color: _isEditMode ? errorColor : accentColor,
                ),
                onPressed: _isSaving ? null : _toggleEditMode,
                tooltip: _isEditMode ? l10n.cancel : l10n.edit,
              ),
              const Gap(8.0),
            ],
          ),
          body: Obx(() {
            final user = _authController.currentUser.value;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Google Account Info Section (Hidden in edit mode)
                  if (!_isEditMode) ...[
                    _buildSectionHeader(
                      l10n.accountInfoPage_sectionHeader_google,
                    ),
                    const Gap(12.0),
                    _buildRoleBadge(
                      user.role,
                    ).animate().fadeIn(duration: 300.ms, delay: 10.ms),
                    const Gap(12.0),
                    _buildReadOnlyField(
                      label: l10n.accountInfoPage_googleSection_provider,
                      leading: Row(
                        spacing: 4.0,
                        children: [
                          SvgPicture.asset(googleIconColor),
                          Image.asset(ictULogo, width: 24),
                        ],
                      ),
                      value: _authProvider,
                      icon: HugeIcons.strokeRoundedGoogleDoc,
                    ).animate().fadeIn(duration: 300.ms, delay: 50.ms),
                    const Gap(12.0),
                    _buildReadOnlyField(
                      label: l10n.accountInfoPage_googleSection_displayName,
                      value: user.name,
                      icon: HugeIcons.strokeRoundedUser,
                      showNameWarning: !_hasDisplayName,
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                    const Gap(12.0),
                    _buildReadOnlyField(
                      label: l10n.accountInfoPage_googleSection_email,
                      value: user.email,
                      icon: HugeIcons.strokeRoundedMail01,
                    ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
                    const Gap(12.0),
                    _buildReadOnlyField(
                      label: l10n.accountInfoPage_googleSection_accountStatus,
                      value: user.status.label,
                      icon: HugeIcons.strokeRoundedCheckmarkBadge02,
                      valueColor: user.status.isVerified
                          ? successColor
                          : errorColor,
                      backgroundColor: successColor.withValues(alpha: 0.1),
                      borderColor: successColor,
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                    const Gap(32.0),
                  ],

                  // Editable Fields Section
                  _buildSectionHeader(
                    _isEditMode
                        ? l10n.accountInfoPage_sectionHeader_update
                        : l10n.accountInfoPage_sectionHeader_contact,
                  ),
                  const Gap(12.0),
                  _buildEditableField(
                    controller: _phoneController,
                    label: l10n.accountInfoPage_editableField_phoneNumber,
                    icon: HugeIcons.strokeRoundedSmartPhone01,
                    hint: 'e.g., +237 6XX XXX XXX, 6XX XXX XXX',
                    keyboardType: TextInputType.phone,
                    required: true,
                    validator: validatePhone,
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                  const Gap(12),
                  _buildGenderSelector().animate().fadeIn(
                    duration: 300.ms,
                    delay: 325.ms,
                  ),

                  if (user is Student) ...[
                    const Gap(32.0),
                    _buildSectionHeader(
                      _isEditMode
                          ? l10n.accountInfoPage_sectionHeader_studentDetails
                          : l10n.accountInfoPage_sectionHeader_studentInfo,
                    ),
                    const Gap(12.0),
                    _buildEditableField(
                      controller: _matriculeController,
                      label: l10n.accountInfoPage_editableField_studentID,
                      icon: HugeIcons.strokeRoundedIdVerified,
                      hint: 'e.g., ICTU20240001',
                      required: true,
                      validator: validateMatricule,
                      textCapitalization: TextCapitalization.characters,
                    ).animate().fadeIn(duration: 300.ms, delay: 350.ms),
                    const Gap(12.0),
                    _buildDepartmentSelector().animate().fadeIn(
                      duration: 300.ms,
                      delay: 400.ms,
                    ),
                    const Gap(12.0),
                    _buildProgramSelector().animate().fadeIn(
                      duration: 300.ms,
                      delay: 450.ms,
                    ),
                    const Gap(12.0),
                    _buildEditableField(
                      controller: _addressController,
                      label: l10n.accountInfoPage_editableField_streetAddress,
                      icon: HugeIcons.strokeRoundedLocation06,
                      textCapitalization: TextCapitalization.words,
                      hint: 'Enter your street address',
                      maxLines: null,
                      required: true,
                    ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
                  ],

                  const Gap(32),

                  // Save Button (only visible in edit mode)
                  if (_isEditMode)
                    PrimaryButton.icon(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      lightColor,
                                    ),
                                  ),
                                )
                              : const HugeIcon(
                                  icon: HugeIcons.strokeRoundedTick02,
                                  color: lightColor,
                                ),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(color: lightColor),
                          ),
                          onPressed: _isSaving ? null : _saveChanges,
                          bgColor: accentColor,
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 550.ms)
                        .slideY(begin: 0.2, end: 0, duration: 300.ms),

                  // Metadata section
                  if (!_isEditMode) ...[
                    const Gap(24.0),
                    _buildMetadataSection(
                      user,
                    ).animate().fadeIn(duration: 300.ms, delay: 600.ms),
                  ],

                  const Gap(16),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTextStyles.h3);
  }

  Widget _buildRoleBadge(UserRole role) {
    Color badgeColor;
    String badgeLabel;
    String badgeDescription;
    String roleImage;
    final l10n = AppLocalizations.of(context)!;

    switch (role) {
      case UserRole.student:
        badgeColor = infoColor;
        badgeLabel = l10n.accountInfoPage_roleBadge_labelStudent;
        badgeDescription = l10n.accountInfoPage_roleBadge_descriptionStudent;

        // Select image based on gender for students
        if (_selectedGender == Gender.male) {
          roleImage = studentMale;
        } else if (_selectedGender == Gender.female) {
          roleImage = studentFemale;
        } else {
          roleImage = student;
        }
        break;
      case UserRole.staff:
        badgeColor = accentColor;
        badgeLabel = l10n.accountInfoPage_roleBadge_labelStaff;
        badgeDescription = l10n.accountInfoPage_roleBadge_descriptionStaff;
        roleImage = staff;
        break;
      case UserRole.admin:
        badgeColor = successColor;
        badgeLabel = l10n.accountInfoPage_roleBadge_labelAdmin;
        badgeDescription = l10n.accountInfoPage_roleBadge_descriptionAdmin;
        roleImage = admin;
        break;
    }

    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: mediaWidth(context),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: UserAvatar(),
            title: Text(
              badgeLabel,
              style: AppTextStyles.h4.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(right: 120.0),
              child: Text(badgeDescription, style: AppTextStyles.small),
            ),
          ),
        ),
        Positioned(bottom: -8, child: Image.asset(roleImage, width: 150.0)),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required List<List<dynamic>> icon,
    Color? valueColor,
    bool showNameWarning = false,
    Color? backgroundColor,
    Color? borderColor,
    Widget? leading,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (themeController.isDark
                ? lightColor.withValues(alpha: 0.1)
                : greyColor.withValues(alpha: 0.05)),
        borderRadius: borderRadius * 2.25,
        border: Border.all(
          color:
              borderColor ??
              (themeController.isDark
                  ? lightColor.withValues(alpha: 0.2)
                  : greyColor.withValues(alpha: 0.3)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading ??
                  HugeIcon(
                    icon: icon,
                    color:
                        valueColor ??
                        (themeController.isDark
                            ? seedPalette.shade50
                            : seedColor),
                  ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.small),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        color: valueColor ?? null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showNameWarning) ...[
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: infoColor.withValues(alpha: 0.7),
                borderRadius: borderRadius * 1.5,
                border: Border.all(
                  color: infoColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  HugeIcon(icon: infoIcon, color: lightColor),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      l10n.accountInfoPage_googleSection_displayNameWarning,
                      style: AppTextStyles.body.copyWith(
                        color: lightColor,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required List<List<dynamic>> icon,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    int? maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
    Color? backgroundColor,
  }) {
    final hasValue = controller.text.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: _isEditMode ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: _isEditMode
          ? null
          : BoxDecoration(
              color:
                  backgroundColor ??
                  (themeController.isDark
                      ? lightColor.withValues(alpha: 0.1)
                      : greyColor.withValues(alpha: 0.05)),
              borderRadius: borderRadius * 2.25,
              border: Border.all(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.2)
                    : greyColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
      child: _isEditMode
          ? SimpleTextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              minLines: maxLines == null ? 1 : maxLines,
              maxLines: maxLines,
              hintText: hint,
              label: Text(
                label + (required ? ' *' : ''),
                style: AppTextStyles.body,
              ),
              validator:
                  validator ??
                  (required
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n
                                .accountInfoPage_editableField_errorRequired(
                                  label,
                                );
                          }
                          return null;
                        }
                      : null),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: icon,
                  color: themeController.isDark
                      ? seedPalette.shade50
                      : seedColor,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.small),
                      Text(
                        hasValue
                            ? controller.text
                            : l10n.accountInfoPage_editableField_departmentNotProvided,
                        style: AppTextStyles.body.copyWith(
                          fontStyle: hasValue
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGenderSelector() {
    final hasValue = _selectedGender != null;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditMode
            ? (themeController.isDark
                  ? lightColor.withValues(alpha: 0.1)
                  : seedPalette.shade50.withValues(alpha: 0.5))
            : themeController.isDark
            ? Colors.pinkAccent.withValues(alpha: 0.1)
            : Colors.pink.withValues(alpha: 0.1),
        borderRadius: borderRadius * 2.25,
        border: Border.all(
          color: _isEditMode
              ? (themeController.isDark
                    ? seedPalette.shade50.withValues(alpha: 0.4)
                    : seedColor)
              : themeController.isDark
              ? Colors.pinkAccent.shade200
              : Colors.pink.shade200,
        ),
      ),
      child: _isEditMode
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountInfoPage_editableField_gender,
                  style: AppTextStyles.body,
                ),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Gender.values.map((gender) {
                    final isSelected = _selectedGender == gender;
                    return ChoiceChip(
                      label: Text(gender.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? gender : null;
                        });
                        HapticFeedback.selectionClick();
                      },
                      checkmarkColor: lightColor,
                      selectedColor: themeController.isDark
                          ? seedPalette.shade800
                          : seedPalette.shade800,
                      backgroundColor: themeController.isDark
                          ? seedPalette.shade100.withValues(alpha: 0.2)
                          : seedPalette.shade100,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? lightColor
                            : (themeController.isDark ? lightColor : darkColor),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius * 1.75,
                        side: BorderSide(
                          color: isSelected
                              ? seedPalette.shade800
                              : (themeController.isDark
                                    ? seedColor.withValues(alpha: 0.3)
                                    : greyColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          : Row(
              spacing: 16.0,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: themeController.isDark
                      ? Colors.pinkAccent
                      : Colors.pink,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountInfoPage_editableField_gender,
                      style: AppTextStyles.small,
                    ),
                    Text(
                      hasValue
                          ? _selectedGender!.label
                          : l10n.accountInfoPage_editableField_genderNotSpecified,
                      style: AppTextStyles.body.copyWith(
                        fontStyle: hasValue
                            ? FontStyle.normal
                            : FontStyle.italic,
                        color: hasValue
                            ? themeController.isDark
                                  ? Colors.pinkAccent
                                  : Colors.pink
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDepartmentSelector() {
    final hasValue = _selectedDepartment != null;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditMode
            ? (themeController.isDark
                  ? lightColor.withValues(alpha: 0.1)
                  : seedPalette.shade50.withValues(alpha: 0.5))
            : (themeController.isDark
                  ? lightColor.withValues(alpha: 0.1)
                  : greyColor.withValues(alpha: 0.05)),
        borderRadius: borderRadius * 2.25,
        border: Border.all(
          color: _isEditMode
              ? (themeController.isDark
                    ? seedPalette.shade50.withValues(alpha: 0.4)
                    : seedColor)
              : (themeController.isDark
                    ? lightColor.withValues(alpha: 0.2)
                    : greyColor.withValues(alpha: 0.3)),
        ),
      ),
      child: _isEditMode
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountInfoPage_editableField_department,
                  style: AppTextStyles.body,
                ),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: departments.map((department) {
                    final isSelected = _selectedDepartment == department;
                    return ChoiceChip(
                      label: Text(department),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDepartment = selected ? department : null;
                          // Reset program when department changes
                          if (_selectedDepartment != null &&
                              !_availablePrograms.contains(_selectedProgram)) {
                            _selectedProgram = null;
                          }
                        });
                        HapticFeedback.selectionClick();
                      },
                      checkmarkColor: lightColor,
                      selectedColor: themeController.isDark
                          ? seedPalette.shade800
                          : seedPalette.shade800,
                      backgroundColor: themeController.isDark
                          ? seedPalette.shade100.withValues(alpha: 0.2)
                          : seedPalette.shade100,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? lightColor
                            : (themeController.isDark ? lightColor : darkColor),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius * 1.75,
                        side: BorderSide(
                          color: isSelected
                              ? seedPalette.shade800
                              : (themeController.isDark
                                    ? seedColor.withValues(alpha: 0.3)
                                    : greyColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          : Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedBuilding03,
                  color: themeController.isDark
                      ? seedPalette.shade50
                      : seedColor,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountInfoPage_editableField_department,
                        style: AppTextStyles.small,
                      ),
                      Text(
                        hasValue
                            ? _selectedDepartment!
                            : l10n.accountInfoPage_editableField_departmentNotProvided,
                        style: AppTextStyles.body.copyWith(
                          fontStyle: hasValue
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgramSelector() {
    final hasValue = _selectedProgram != null;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditMode
            ? (themeController.isDark
                  ? lightColor.withValues(alpha: 0.1)
                  : seedPalette.shade50.withValues(alpha: 0.5))
            : (themeController.isDark
                  ? lightColor.withValues(alpha: 0.1)
                  : greyColor.withValues(alpha: 0.05)),
        borderRadius: borderRadius * 2.25,
        border: Border.all(
          color: _isEditMode
              ? (themeController.isDark
                    ? seedPalette.shade50.withValues(alpha: 0.4)
                    : seedColor)
              : (themeController.isDark
                    ? lightColor.withValues(alpha: 0.2)
                    : greyColor.withValues(alpha: 0.3)),
        ),
      ),
      child: _isEditMode
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountInfoPage_editableField_program,
                  style: AppTextStyles.body,
                ),
                const Gap(8),
                if (_selectedDepartment == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: infoColor.withValues(alpha: 0.1),
                      borderRadius: borderRadius * 1.5,
                      border: Border.all(
                        color: infoColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(icon: infoIcon, color: infoColor, size: 20),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            l10n.accountInfoPage_editableField_programInstruction,
                            style: AppTextStyles.small.copyWith(
                              color: infoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availablePrograms.map((program) {
                      final isSelected = _selectedProgram == program;
                      return ChoiceChip(
                        label: Text(program),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedProgram = selected ? program : null;
                          });
                          HapticFeedback.selectionClick();
                        },
                        checkmarkColor: lightColor,
                        selectedColor: themeController.isDark
                            ? seedPalette.shade800
                            : seedPalette.shade800,
                        backgroundColor: themeController.isDark
                            ? seedPalette.shade100.withValues(alpha: 0.2)
                            : seedPalette.shade100,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? lightColor
                              : (themeController.isDark
                                    ? lightColor
                                    : darkColor),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: borderRadius * 1.75,
                          side: BorderSide(
                            color: isSelected
                                ? seedPalette.shade800
                                : (themeController.isDark
                                      ? seedColor.withValues(alpha: 0.3)
                                      : greyColor.withValues(alpha: 0.3)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            )
          : Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedBook02,
                  color: themeController.isDark
                      ? seedPalette.shade50
                      : seedColor,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountInfoPage_editableField_program,
                        style: AppTextStyles.small,
                      ),
                      Text(
                        hasValue
                            ? _selectedProgram!
                            : l10n.accountInfoPage_editableField_programNotProvided,
                        style: AppTextStyles.body.copyWith(
                          fontStyle: hasValue
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetadataSection(BaseUser user) {
    final List<MetadataEntry> entries = [];
    final l10n = AppLocalizations.of(context)!;

    if (user.createdAt != null) {
      entries.add(
        MetadataEntry(
          icon: HugeIcons.strokeRoundedCalendarAdd02,
          label: l10n.joined,
          dateTime: user.createdAt!,
        ),
      );
    }

    if (user.lastSignInAt != null) {
      entries.add(
        MetadataEntry(
          icon: HugeIcons.strokeRoundedLogin01,
          label: l10n.lastSignIn,
          dateTime: user.lastSignInAt!,
        ),
      );
    }

    if (user.updatedAt != null) {
      entries.add(
        MetadataEntry(
          icon: HugeIcons.strokeRoundedEdit02,
          label: l10n.lastUpdated,
          dateTime: user.updatedAt!,
        ),
      );
    }

    return MetadataSection(
      entries: entries,
      locale: localeController.locale.languageCode,
    );
  }
}
