import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/users_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/actors/base_user.dart';
import '../../../models/actors/student.dart';
import '../../../models/actors/roles.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import '../../components/widgets/user_avatar.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final UsersController _usersController = Get.find<UsersController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter users based on search query
  List<BaseUser> _getFilteredUsers() {
    final users = _usersController.users;

    if (_searchQuery.value.isEmpty) {
      return users;
    }

    final query = _searchQuery.value.toLowerCase();

    return users.where((user) {
      // Search by name
      final name = user.name.toLowerCase();
      if (name.contains(query)) return true;

      // Search by email
      final email = user.email.toLowerCase();
      if (email.contains(query)) return true;

      // Search by matricule (student ID) if available
      if (user is Student) {
        final matricule = user.matricule?.toLowerCase() ?? '';
        if (matricule.contains(query)) return true;
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeController.isDark ? seedColor : lightColor,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.contain,
          child: Text(l10n.peopleTab_appBar_title),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: SearchBar(
              controller: _searchController,
              onChanged: (value) => _searchQuery.value = value,
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: themeController.isDark ? seedPalette.shade50 : seedColor,
                strokeWidth: 2.0,
              ),
              trailing: [
                // Clear search
                Obx(() {
                  if (_searchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery.value = '';
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: themeController.isDark
                          ? seedPalette.shade50
                          : seedColor,
                    ),
                  );
                }),
              ],
              hintText: 'Search by name, email or ID...',
            ),
          ),
        ),
        actions: [
          // View mode toggle
          Obx(() {
            final isStudentView =
                _usersController.currentViewMode.value.isStudent;
            final userCount = _usersController.users.length;

            return Container(
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: themeController.isDark
                    ? darkColor.withValues(alpha: 0.3)
                    : lightColor.withValues(alpha: 0.2),
                borderRadius: borderRadius * 2.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewToggleButton(
                    label: isStudentView && userCount > 1
                        ? "${l10n.roleStudent}s"
                        : l10n.roleStudent,
                    icon: HugeIcons.strokeRoundedStudentCard,
                    isSelected: isStudentView,
                    count: isStudentView ? userCount : null,
                    onTap: () =>
                        _usersController.switchViewMode(UserRole.student),
                  ),
                  _ViewToggleButton(
                    label: l10n.roleStaff,
                    icon: HugeIcons.strokeRoundedUserMultiple,
                    isSelected: !isStudentView,
                    count: !isStudentView ? userCount : null,
                    onTap: () =>
                        _usersController.switchViewMode(UserRole.staff),
                  ),
                ],
              ),
            );
          }),
          // Refresh button
          Obx(() {
            return _usersController.isBusy.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 24.0,
                      width: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : IconButton(
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
                    onPressed: () => _usersController.refreshUsers(),
                    tooltip: l10n.refresh,
                  );
          }),
        ],
      ),
      body: Obx(() {
        if (_usersController.isBusy.value && _usersController.users.isEmpty) {
          return _buildLoadingState();
        }

        if (_usersController.errorMessage.value != null) {
          return _buildErrorState();
        }

        if (_usersController.users.isEmpty) {
          return _buildEmptyState();
        }

        return _buildUsersList();
      }),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const Gap(16.0),
          Text(
            l10n.peopleTab_loadingState,
            style: AppTextStyles.body.copyWith(
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.6)
                  : darkColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: errorColor,
              size: 48.0,
            ),
            const Gap(16.0),
            Text(
              l10n.peopleTab_loadError,
              style: AppTextStyles.h3.copyWith(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8.0),
            Text(
              _usersController.errorMessage.value ??
                  l10n.peopleTab_loadError_unknown,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const Gap(24.0),
            ElevatedButton.icon(
              onPressed: () => _usersController.refreshUsers(),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                color: lightColor,
              ),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: lightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final isStudentView =
        _usersController.currentViewMode.value == UserRole.student;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: isStudentView
                  ? HugeIcons.strokeRoundedStudentCard
                  : HugeIcons.strokeRoundedUserMultiple,
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.3)
                  : darkColor.withValues(alpha: 0.3),
              size: 64.0,
            ),
            const Gap(16.0),
            Text(
              isStudentView
                  ? l10n.peopleTab_emptyStudents_title
                  : l10n.peopleTab_emptyStaff_title,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8.0),
            Text(
              isStudentView
                  ? l10n.peopleTab_emptyStudents_subtitle
                  : l10n.peopleTab_emptyStaff_subtitle,
              style: AppTextStyles.body.copyWith(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.6)
                    : darkColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return Obx(() {
      final filteredUsers = _getFilteredUsers();

      if (filteredUsers.isEmpty && _searchQuery.value.isNotEmpty) {
        return _buildEmptySearchState();
      }

      return RefreshIndicator(
        onRefresh: () => _usersController.refreshUsers(),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0).copyWith(
            bottom: MediaQuery.paddingOf(context).bottom + 88.0
          ),
          itemCount: filteredUsers.length,
          separatorBuilder: (context, index) => Divider(
            height: 1.0,
            indent: 72.0,
            color: themeController.isDark
                ? lightColor.withValues(alpha: 0.1)
                : darkColor.withValues(alpha: 0.1),
          ),
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _UserListTile(
                  user: user,
                  usersController: _usersController,
                  authController: _authController,
                  onPromote: _handlePromoteUser,
                )
                .animate()
                .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                .slideX(
                  begin: 0.2,
                  end: 0,
                  duration: 400.ms,
                  delay: (index * 50).ms,
                );
          },
        ),
      );
    });
  }

  Widget _buildEmptySearchState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 80.0,
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.2)
                  : darkColor.withValues(alpha: 0.2),
            ),
            const Gap(16.0),
            Text(
              l10n.peopleTab_emptySearchState_title,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8.0),
            Text(
              l10n.peopleTab_emptySearchState_subtitle,
              style: AppTextStyles.body.copyWith(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.6)
                    : darkColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle promoting a staff member to admin or demoting admin to staff
  Future<void> _handlePromoteUser(BaseUser user) async {
    final l10n = AppLocalizations.of(context)!;
    // Check if current user is admin
    if (!_authController.isAdmin) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(l10n.peopleTab_handlePromote_onlyAdmin),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    final isCurrentlyStaff = user.role == UserRole.staff;
    final newRole = isCurrentlyStaff ? UserRole.admin : UserRole.staff;

    // Show confirmation dialog
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _buildPromotionConfirmationModal(user: user, newRole: newRole),
    );

    if (confirmed == true && mounted) {
      try {
        // Update user role
        await _usersController.updateUserRole(user.id, newRole);

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
                label: Text(
                  isCurrentlyStaff
                      ? '${user.name} ${l10n.peopleTab_handlePromote_successPromote}'
                      : '${user.name} ${l10n.peopleTab_handlePromote_successDemote}',
                ),
                backgroundColor: successColor,
              ),
            );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
                label: Text('${l10n.error} ${e.toString()}'),
                backgroundColor: errorColor,
              ),
            );
        }
      }
    }
  }

  Widget _buildPromotionConfirmationModal({
    required BaseUser user,
    required UserRole newRole,
  }) {
    final isPromoting = newRole == UserRole.admin;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Container(
              width: 72.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: borderRadius * 2.0,
              ),
            ),
          ),
          const Gap(20.0),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ).copyWith(bottom: MediaQuery.paddingOf(context).bottom),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: themeController.isDark ? darkGradient : lightGradient,
                borderRadius: borderRadius * 3.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isPromoting
                              ? successColor.withValues(alpha: 0.15)
                              : warningColor.withValues(alpha: 0.15),
                          borderRadius: borderRadius * 2.5,
                        ),
                        child: HugeIcon(
                          icon: isPromoting
                              ? HugeIcons.strokeRoundedArrowUp01
                              : HugeIcons.strokeRoundedArrowDown01,
                          color: isPromoting ? successColor : warningColor,
                          size: 28.0,
                        ),
                      ),
                      const Gap(16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPromoting
                                  ? l10n.peopleTab_promoteModal_titlePromote
                                  : l10n.peopleTab_promoteModal_titleDemote,
                              style: AppTextStyles.h3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.name,
                              style: AppTextStyles.body.copyWith(
                                color: themeController.isDark
                                    ? lightColor.withValues(alpha: 0.7)
                                    : darkColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(24.0),

                  // Warning/Info box
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isPromoting
                          ? infoColor.withValues(alpha: 0.1)
                          : warningColor.withValues(alpha: 0.1),
                      borderRadius: borderRadius * 2.5,
                      border: Border.all(
                        color: isPromoting
                            ? infoColor.withValues(alpha: 0.3)
                            : warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedInformationCircle,
                              color: isPromoting ? infoColor : warningColor,
                              size: 20.0,
                            ),
                            const Gap(8.0),
                            Text(
                              l10n.peopleTab_promoteModal_infoWarningTitle,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPromoting ? infoColor : warningColor,
                              ),
                            ),
                          ],
                        ),
                        const Gap(12.0),
                        Text(
                          isPromoting
                              ? l10n.peopleTab_promoteModal_infoWarningSubtitlePromote
                              : l10n.peopleTab_promoteModal_infoWarningSubtitleDemote,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8.0),
                        ..._buildAccessList(isPromoting),
                      ],
                    ),
                  ),
                  const Gap(24.0),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            side: BorderSide(
                              color: themeController.isDark
                                  ? lightColor.withValues(alpha: 0.3)
                                  : darkColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const Gap(12.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPromoting
                                ? successColor
                                : warningColor,
                            foregroundColor: lightColor,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: Text(
                            isPromoting
                                ? l10n.peopleTab_promoteModal_ctaPromote
                                : l10n.peopleTab_promoteModal_ctaDemote,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccessList(bool isPromoting) {
    final l10n = AppLocalizations.of(context)!;
    final accesses = isPromoting
        ? [
            l10n.peopleTab_accessList_promote1,
            l10n.peopleTab_accessList_promote2,
            l10n.peopleTab_accessList_promote3,
            l10n.peopleTab_accessList_promote4,
            l10n.peopleTab_accessList_promote5,
            l10n.peopleTab_accessList_promote6,
          ]
        : [
            l10n.peopleTab_accessList_demote1,
            l10n.peopleTab_accessList_demote2,
            l10n.peopleTab_accessList_demote3,
            l10n.peopleTab_accessList_demote4,
            l10n.peopleTab_accessList_demote5,
          ];

    return accesses.map((access) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(
              icon: isPromoting
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedCancelCircle,
              color: isPromoting ? successColor : errorColor,
              size: 16.0,
            ),
            const Gap(8.0),
            Expanded(
              child: Text(
                access,
                style: AppTextStyles.small.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.8)
                      : darkColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// View toggle button widget
class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accentColor : Colors.transparent,
      borderRadius: borderRadius * 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius * 2.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: isSelected ? lightColor : accentColor,
                size: 18.0,
              ),
              const Gap(6.0),
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: isSelected ? lightColor : accentColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13.0,
                ),
              ),
              // Count badge
              if (count != null && count! > 0) ...[
                const Gap(4.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? lightColor.withValues(alpha: 0.2)
                        : accentColor.withValues(alpha: 0.15),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: isSelected
                          ? lightColor.withValues(alpha: 0.3)
                          : accentColor.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTextStyles.small.copyWith(
                      color: isSelected ? lightColor : accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// User list tile widget
class _UserListTile extends StatefulWidget {
  const _UserListTile({
    required this.user,
    required this.usersController,
    required this.authController,
    required this.onPromote,
  });

  final BaseUser user;
  final UsersController usersController;
  final AuthController authController;
  final Future<void> Function(BaseUser) onPromote;

  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
  int? _subscriptionCount;
  int? _scanCount;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (_isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Load subscription count for students
      if (widget.user.role == UserRole.student) {
        final subCount = await widget.usersController.getUserSubscriptionCount(
          widget.user.id,
        );
        // For students: scan count = number of times their QR was scanned
        final scanCount = await widget.usersController.getUserScanCount(
          widget.user.id,
        );

        if (mounted) {
          setState(() {
            _subscriptionCount = subCount;
            _scanCount = scanCount;
            _isLoadingStats = false;
          });
        }
      } else {
        // For staff/admin: scan count = number of scans they performed
        final scanCount = await widget.usersController.getStaffScanCount(
          widget.user.id,
        );

        if (mounted) {
          setState(() {
            _scanCount = scanCount;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUserAdmin = widget.authController.isAdmin;
    final isPendingStaffOrAdmin =
        (widget.user.role == UserRole.staff ||
            widget.user.role == UserRole.admin) &&
        widget.user.status == AccountStatus.pending;
    final canPromote =
        isCurrentUserAdmin &&
        widget.user.status == AccountStatus.verified &&
        (widget.user.role == UserRole.staff ||
            widget.user.role == UserRole.admin);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0.0,
        vertical: 8.0,
      ),
      // Leading: User Avatar
      leading: UserAvatar(user: widget.user, radius: 24.0),
      // Title: User Name
      title: Text(
        widget.user.name,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Subtitle: Wrap of stats
      subtitle: Column(
        spacing: 2.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.email,
            style: AppTextStyles.body.copyWith(
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.6)
                  : darkColor.withValues(alpha: 0.6),
              fontSize: 13.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Wrap(
            spacing: 12.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Role badge (for staff/admin differentiation)
              if (widget.user.role != UserRole.student) _buildRoleBadge(),
              // Date joined
              _buildStatChip(
                icon: HugeIcons.strokeRoundedCalendar03,
                label: formatRelativeDateTime(widget.user.createdAt!),
                color: accentColor,
              ),
              // Subscription count (if available and is student)
              if (widget.user.role == UserRole.student &&
                  _subscriptionCount != null &&
                  _subscriptionCount! > 0)
                _buildStatChip(
                  icon: HugeIcons.strokeRoundedTicket01,
                  label: localeController.locale.languageCode == 'en'
                      ? '$_subscriptionCount sub${_subscriptionCount! > 1 ? 's' : ''}'
                      : '$_subscriptionCount abo${_subscriptionCount! > 1 ? 's' : ''}',
                  color: successColor,
                ),
              // Scan count (if available)
              if (_scanCount != null && _scanCount! > 0)
                _buildStatChip(
                  icon: HugeIcons.strokeRoundedQrCode,
                  label: '$_scanCount scan${_scanCount! > 1 ? 's' : ''}',
                  color: infoColor,
                ),
              // Loading indicator for stats
              if (_isLoadingStats)
                const SizedBox(
                  height: 16.0,
                  width: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
            ],
          ),
        ],
      ),
      // Trailing: Action buttons for pending users or status indicator
      trailing: isCurrentUserAdmin && isPendingStaffOrAdmin
          ? _buildApprovalActions()
          : _buildStatusIndicator(),
      onTap: () {
        // TODO: Navigate to user detail page
      },
      // Long press to promote/demote (only for admin on verified staff/admin)
      onLongPress: canPromote ? () => widget.onPromote(widget.user) : null,
    );
  }

  Widget _buildApprovalActions() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reject button
        IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancelCircle,
            color: errorColor,
            size: 20.0,
          ),
          onPressed: () => _handleReject(),
          tooltip: l10n.subscriptionDetailPage_adminAction_reject,
          padding: const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
        ),
        const Gap(4.0),
        // Approve button
        IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            color: successColor,
            size: 20.0,
          ),
          onPressed: () => _handleApprove(),
          tooltip: l10n.subscriptionDetailPage_adminAction_approve,
          padding: const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
        ),
      ],
    );
  }

  Future<void> _handleApprove() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Update user status to verified
      await widget.usersController.updateUserStatus(
        widget.user.id,
        AccountStatus.verified,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
              label: Text(
                '${widget.user.name} ${l10n.peopleTab_handleApprove_success}',
              ),
              backgroundColor: successColor,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                '${l10n.peopleTab_handleApprove_error} ${e.toString()}',
              ),
              backgroundColor: errorColor,
            ),
          );
      }
    }
  }

  Future<void> _handleReject() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Update user status to suspended (rejected)
      await widget.usersController.updateUserStatus(
        widget.user.id,
        AccountStatus.suspended,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
              label: Text(
                '${widget.user.name} ${l10n.peopleTab_handleReject_success}',
              ),
              backgroundColor: successColor,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                '${l10n.peopleTab_handleReject_error} ${e.toString()}',
              ),
              backgroundColor: errorColor,
            ),
          );
      }
    }
  }

  Widget _buildRoleBadge() {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = widget.user.role == UserRole.admin;
    final baseColor = isAdmin ? seedPalette.shade500 : accentColor;
    final icon = isAdmin
        ? HugeIcons.strokeRoundedUserStar01
        : HugeIcons.strokeRoundedUserMultiple;
    final label = isAdmin ? l10n.roleAdmin : l10n.roleStaff;

    // Adjust colors based on theme for better visibility
    final bgColor = themeController.isDark
        ? baseColor.withValues(alpha: 0.25)
        : baseColor.withValues(alpha: 0.15);

    final borderColor = themeController.isDark
        ? baseColor.withValues(alpha: 0.6)
        : baseColor.withValues(alpha: 0.4);

    final contentColor = themeController.isDark
        ? baseColor.withValues(alpha: 0.95)
        : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius * 0.8,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: contentColor, size: 12.0),
          const Gap(4.0),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: contentColor,
              fontWeight: FontWeight.w600,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required List<List<dynamic>> icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: color, size: 14.0),
        const Gap(4.0),
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: themeController.isDark
                ? lightColor.withValues(alpha: 0.7)
                : darkColor.withValues(alpha: 0.7),
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final color = widget.user.status == AccountStatus.verified
        ? successColor
        : widget.user.status == AccountStatus.pending
        ? warningColor
        : errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: borderRadius,
      ),
      child: Text(
        widget.user.status.label,
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11.0,
        ),
      ),
    );
  }
}
