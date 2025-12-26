import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../controllers/users_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/actors/base_user.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeController.isDark ? seedColor : lightColor,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            'People',
          ),
        ),
        actions: [
          // View mode toggle
          Obx(() {
            final isStudentView = _usersController.currentViewMode.value.isStudent;
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
                    label: 'Students',
                    icon: HugeIcons.strokeRoundedStudentCard,
                    isSelected: isStudentView,
                    count: isStudentView ? userCount : null,
                    onTap: () => _usersController.switchViewMode(UserRole.student),
                  ),
                  _ViewToggleButton(
                    label: 'Staff',
                    icon: HugeIcons.strokeRoundedUserMultiple,
                    isSelected: !isStudentView,
                    count: !isStudentView ? userCount : null,
                    onTap: () => _usersController.switchViewMode(UserRole.staff),
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
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh,
                    ),
                    onPressed: () => _usersController.refreshUsers(),
                    tooltip: 'Refresh',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const Gap(16.0),
          Text(
            'Loading users...',
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
              'Error Loading Users',
              style: AppTextStyles.h3.copyWith(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8.0),
            Text(
              _usersController.errorMessage.value ?? 'Unknown error',
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
              label: const Text('Retry'),
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
    final isStudentView = _usersController.currentViewMode.value == UserRole.student;
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
              isStudentView ? 'No Students Yet' : 'No Staff Yet',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8.0),
            Text(
              isStudentView
                  ? 'There are no students registered yet'
                  : 'There are no staff members registered yet',
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
    return RefreshIndicator(
      onRefresh: () => _usersController.refreshUsers(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _usersController.users.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 72.0,
          color: themeController.isDark
              ? lightColor.withValues(alpha: 0.1)
              : darkColor.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final user = _usersController.users[index];
          return _UserListTile(
            user: user,
            usersController: _usersController,
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
      color: isSelected
          ? accentColor
          : Colors.transparent,
      borderRadius: borderRadius * 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius * 2.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
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

// User list tile widget (WhatsApp style)
class _UserListTile extends StatefulWidget {
  const _UserListTile({
    required this.user,
    required this.usersController,
  });

  final BaseUser user;
  final UsersController usersController;

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
      final subCount = await widget.usersController.getUserSubscriptionCount(widget.user.id);
      final scanCount = await widget.usersController.getUserScanCount(widget.user.id);

      if (mounted) {
        setState(() {
          _subscriptionCount = subCount;
          _scanCount = scanCount;
          _isLoadingStats = false;
        });
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
    final authController = Get.find<AuthController>();
    final isCurrentUserAdmin = authController.isAdmin;
    final isPendingStaffOrAdmin = (widget.user.role == UserRole.staff ||
                                   widget.user.role == UserRole.admin) &&
                                   widget.user.status == AccountStatus.pending;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      // Leading: User Avatar
      leading: UserAvatar(
        user: widget.user,
        tag: 'user_${widget.user.id}',
        radius: 24.0,
      ),
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
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Wrap(
          spacing: 12.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Role badge (for staff/admin differentiation)
            if (widget.user.role != UserRole.student)
              _buildRoleBadge(),
            // Date joined
            _buildStatChip(
              icon: HugeIcons.strokeRoundedCalendar03,
              label: _formatDate(widget.user.createdAt),
              color: accentColor,
            ),
            // Subscription count (if available and is student)
            if (widget.user.role == UserRole.student &&
                _subscriptionCount != null &&
                _subscriptionCount! > 0)
              _buildStatChip(
                icon: HugeIcons.strokeRoundedTicket01,
                label: '$_subscriptionCount sub${_subscriptionCount! > 1 ? 's' : ''}',
                color: successColor,
              ),
            // Scan count (if available)
            if (_scanCount != null && _scanCount! > 0)
              _buildStatChip(
                icon: HugeIcons.strokeRoundedQrCode,
                label: '$_scanCount scan${_scanCount! > 1 ? 's' : ''}',
                color: seedColor,
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
      ),
      // Trailing: Action buttons for pending users or status indicator
      trailing: isCurrentUserAdmin && isPendingStaffOrAdmin
          ? _buildApprovalActions()
          : _buildStatusIndicator(),
      onTap: () {
        // TODO: Navigate to user detail page
      },
    );
  }

  Widget _buildApprovalActions() {
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
          tooltip: 'Reject',
          padding: const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(
            minWidth: 36.0,
            minHeight: 36.0,
          ),
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
          tooltip: 'Approve',
          padding: const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(
            minWidth: 36.0,
            minHeight: 36.0,
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove() async {
    try {
      // Update user status to verified
      await widget.usersController.updateUserStatus(
        widget.user.id,
        AccountStatus.verified,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.user.name} has been approved!'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve user: ${e.toString()}'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    try {
      // Update user status to suspended (rejected)
      await widget.usersController.updateUserStatus(
        widget.user.id,
        AccountStatus.suspended,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.user.name} has been rejected.'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject user: ${e.toString()}'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildRoleBadge() {
    final isAdmin = widget.user.role == UserRole.admin;
    final baseColor = isAdmin ? seedPalette.shade500 : accentColor;
    final icon = isAdmin
        ? HugeIcons.strokeRoundedUserStar01
        : HugeIcons.strokeRoundedUserMultiple;
    final label = isAdmin ? 'Admin' : 'Staff';

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
      padding: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius * 0.8,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            color: contentColor,
            size: 12.0,
          ),
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
        HugeIcon(
          icon: icon,
          color: color,
          size: 14.0,
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

