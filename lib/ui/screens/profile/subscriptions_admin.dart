import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/subscriptions_controller.dart';
import '../../../models/actors/base_user.dart';
import '../../../models/subscription.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import '../../components/widgets/default_snack_bar.dart';
import '../../components/widgets/loading_indicator.dart';
import '../subscriptions/subscription_details.dart';

class SubscriptionsAdminPage extends StatefulWidget {
  static const String routeName = '/subscriptions-admin';

  const SubscriptionsAdminPage({super.key});

  @override
  State<SubscriptionsAdminPage> createState() => _SubscriptionsAdminPageState();
}

class _SubscriptionsAdminPageState extends State<SubscriptionsAdminPage> {
  final BusSubscriptionsController _subscriptionsController =
      Get.find<BusSubscriptionsController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  final RxString _searchQuery = ''.obs;
  final RxnString _selectedStatus = RxnString();
  final RxnString _selectedYear = RxnString();
  final RxnString _selectedSemester = RxnString();

  // Expansion states
  final RxBool _approvedExpanded = false.obs;
  final RxBool _rejectedExpanded = false.obs;

  // User cache for performance optimization
  final Map<String, BaseUser?> _userCache = {};
  final RxBool _isLoadingUsers = false.obs;

  @override
  void initState() {
    super.initState();
    _subscriptionsController.startWatchingAll();
    _preloadUsers();
  }

  /// Preload user information for all subscriptions to avoid multiple Firebase calls
  Future<void> _preloadUsers() async {
    _isLoadingUsers.value = true;
    try {
      final subscriptions = _subscriptionsController.busSubscriptions;
      final uniqueStudentIds = subscriptions
          .map((sub) => sub.studentId)
          .toSet()
          .toList();

      // Load users in parallel
      await Future.wait(
        uniqueStudentIds.map((studentId) async {
          if (!_userCache.containsKey(studentId)) {
            final user = await _authController.getUserById(studentId);
            _userCache[studentId] = user;
          }
        }),
      );
    } catch (e) {
      print('[SubscriptionsAdmin] Error preloading users: $e');
    } finally {
      _isLoadingUsers.value = false;
    }
  }

  /// Get user from cache or load from Firebase if not cached
  Future<BaseUser?> _getCachedUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final user = await _authController.getUserById(userId);
    _userCache[userId] = user;
    return user;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusSubscription> _filterSubscriptions(
    List<BusSubscription> subscriptions,
  ) {
    var filtered = subscriptions;

    // Search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((sub) {
        return sub.semester.label.toLowerCase().contains(query) ||
            sub.year.toString().contains(query) ||
            sub.studentId.toLowerCase().contains(query);
      }).toList();
    }

    // Status filter
    if (_selectedStatus.value != null) {
      final status = BusSubscriptionStatus.values.firstWhere(
        (s) => s.nameLower == _selectedStatus.value,
      );
      filtered = filtered.where((sub) => sub.status == status).toList();
    }

    // Year filter
    if (_selectedYear.value != null) {
      filtered = filtered
          .where((sub) => sub.year.toString() == _selectedYear.value)
          .toList();
    }

    // Semester filter
    if (_selectedSemester.value != null) {
      filtered = filtered
          .where((sub) => sub.semester.label == _selectedSemester.value)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Subscriptions'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => _subscriptionsController.startWatchingAll(),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
            ),
          ],
        ),
        body: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
          children: [
            // Search bar with filter
            SearchBar(
              controller: _searchController,
              onChanged: (value) => _searchQuery.value = value,
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: themeController.isDark
                    ? seedPalette.shade50
                    : seedColor,
                strokeWidth: 2.0,
              ),
              trailing: [
                // Filter button
                IconButton(
                  onPressed: _showFilterMenu,
                  icon: Obx(() {
                    final hasFilters =
                        _selectedStatus.value != null ||
                        _selectedYear.value != null ||
                        _selectedSemester.value != null;
                    return Badge(
                      isLabelVisible: hasFilters,
                      backgroundColor: accentColor,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFilterHorizontal,
                        color: themeController.isDark
                            ? seedPalette.shade50
                            : seedColor,
                      ),
                    );
                  }),
                ),
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
              hintText: 'Search subscriptions...',
            ),
            const Gap(16.0),

            // Stats section
            Obx(() {
              final subscriptions = _subscriptionsController.busSubscriptions;
              final pending = subscriptions
                  .where((s) => s.status == BusSubscriptionStatus.pending)
                  .length;
              final approved = subscriptions
                  .where((s) => s.status == BusSubscriptionStatus.approved)
                  .length;
              final rejected = subscriptions
                  .where((s) => s.status == BusSubscriptionStatus.rejected)
                  .length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    icon: HugeIcons.strokeRoundedLoading03,
                    label: 'Pending',
                    value: pending.toString(),
                    color: infoColor,
                  ),
                  _StatItem(
                    icon: HugeIcons.strokeRoundedCheckmarkBadge02,
                    label: 'Approved',
                    value: approved.toString(),
                    color: successColor,
                  ),
                  _StatItem(
                    icon: HugeIcons.strokeRoundedCancelCircle,
                    label: 'Rejected',
                    value: rejected.toString(),
                    color: errorColor,
                  ),
                ],
              );
            }),

            const Gap(24.0),

            // Subscriptions list
            Obx(() {
              if (_subscriptionsController.isBusy.value &&
                  _subscriptionsController.busSubscriptions.isEmpty) {
                return const Center(child: LoadingIndicator());
              }

              if (_subscriptionsController.errorMessage.value != null) {
                return _ErrorWidget(
                  message: _subscriptionsController.errorMessage.value!,
                  onRetry: () =>
                      _subscriptionsController.startWatchingAll(),
                );
              }

              final allSubscriptions = _filterSubscriptions(
                _subscriptionsController.busSubscriptions,
              );

              if (allSubscriptions.isEmpty) {
                return _EmptyWidget(
                  hasSearch:
                      _searchQuery.value.isNotEmpty ||
                      _selectedStatus.value != null ||
                      _selectedYear.value != null ||
                      _selectedSemester.value != null,
                );
              }

              // Group subscriptions by status
              final pending = allSubscriptions
                  .where((s) => s.status == BusSubscriptionStatus.pending)
                  .toList();
              final approved = allSubscriptions
                  .where((s) => s.status == BusSubscriptionStatus.approved)
                  .toList();
              final rejected = allSubscriptions
                  .where((s) => s.status == BusSubscriptionStatus.rejected)
                  .toList();

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Pending subscriptions (always visible)
                  if (pending.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Pending Review',
                      count: pending.length,
                      color: infoColor,
                    ),
                    const Gap(28.0),
                    ...pending.map(
                      (sub) => _SubscriptionCard(
                        subscription: sub,
                        cachedUser: _userCache[sub.studentId],
                        onTap: () => _showSubscriptionDetails(sub),
                        onApprove: () => _approveSubscription(sub),
                        onReject: () => _showRejectDialog(sub),
                      ),
                    ),
                    const Gap(4.0),
                  ] else ...[
                    _EmptyStateCard(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      message: 'No pending subscriptions',
                      color: infoColor,
                    ),
                    const Gap(24.0),
                  ],

                  // Approved subscriptions (collapsible)
                  if (approved.isNotEmpty) ...[
                    _ExpandableSection(
                      title: 'Approved',
                      count: approved.length,
                      color: successColor,
                      isExpanded: _approvedExpanded,
                      children: approved
                          .map(
                            (sub) => _SubscriptionCard(
                              subscription: sub,
                              cachedUser: _userCache[sub.studentId],
                              onTap: () => _showSubscriptionDetails(sub),
                              isReviewComplete: true,
                            ),
                          )
                          .toList(),
                    ),
                    const Gap(24.0),
                  ],

                  // Rejected subscriptions (collapsible)
                  if (rejected.isNotEmpty) ...[
                    _ExpandableSection(
                      title: 'Rejected',
                      count: rejected.length,
                      color: errorColor,
                      isExpanded: _rejectedExpanded,
                      children: rejected
                          .map(
                            (sub) => _SubscriptionCard(
                              subscription: sub,
                              cachedUser: _userCache[sub.studentId],
                              onTap: () => _showSubscriptionDetails(sub),
                              isReviewComplete: true,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Animate(
        effects: [FadeEffect(), MoveEffect()],
        child: ListView(
          shrinkWrap: true,
          physics: AlwaysScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          children: [
            // Handle
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

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ).copyWith(bottom: MediaQuery.paddingOf(context).bottom),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius * 3.75,
                  gradient: themeController.isDark
                      ? darkGradient
                      : lightGradient,
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filter Subscriptions', style: AppTextStyles.h2),
                    const Gap(24.0),

                    // Status filter
                    Text(
                      'Status',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8.0),
                    Obx(
                      () => Wrap(
                        spacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedStatus.value == null,
                            onSelected: (selected) {
                              if (selected) _selectedStatus.value = null;
                            },
                          ),
                          ...BusSubscriptionStatus.values.map((status) {
                            return FilterChip(
                              label: Text(status.name),
                              selected:
                                  _selectedStatus.value == status.nameLower,
                              onSelected: (selected) {
                                _selectedStatus.value = selected
                                    ? status.nameLower
                                    : null;
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const Gap(16.0),

                    // Year filter
                    Text(
                      'Year',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8.0),
                    Obx(() {
                      final years =
                          _subscriptionsController.busSubscriptions
                              .map((s) => s.year.toString())
                              .toSet()
                              .toList()
                            ..sort((a, b) => b.compareTo(a));

                      return Wrap(
                        spacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedYear.value == null,
                            onSelected: (selected) {
                              if (selected) _selectedYear.value = null;
                            },
                          ),
                          ...years.map((year) {
                            return FilterChip(
                              label: Text(year),
                              selected: _selectedYear.value == year,
                              onSelected: (selected) {
                                _selectedYear.value = selected ? year : null;
                              },
                            );
                          }),
                        ],
                      );
                    }),
                    const Gap(16.0),

                    // Semester filter
                    Text(
                      'Semester',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8.0),
                    Obx(() {
                      final semesters = _subscriptionsController
                          .busSubscriptions
                          .map((s) => s.semester.label)
                          .toSet()
                          .toList();

                      return Wrap(
                        spacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedSemester.value == null,
                            onSelected: (selected) {
                              if (selected) _selectedSemester.value = null;
                            },
                          ),
                          ...semesters.map((semester) {
                            return FilterChip(
                              label: Text(semester),
                              selected: _selectedSemester.value == semester,
                              onSelected: (selected) {
                                _selectedSemester.value = selected
                                    ? semester
                                    : null;
                              },
                            );
                          }),
                        ],
                      );
                    }),
                    const Gap(24.0),

                    // Clear filters button
                    Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          _selectedStatus.value = null;
                          _selectedYear.value = null;
                          _selectedSemester.value = null;
                          Navigator.of(context).pop();
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedFilterRemove,
                          color: lightColor,
                        ),
                        label: const Text('Clear Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionDetails(BusSubscription subscription) {
    context.pushNamed(
      removeLeadingSlash(SubscriptionDetailsPage.routeName),
      pathParameters: {'subscriptionId': subscription.id},
    );
  }

  void _approveSubscription(BusSubscription subscription) async {
    try {
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _subscriptionsController.approveSubscription(
        subscriptionId: subscription.id,
        reviewerId: currentUser.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildSnackBar(
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: lightColor,
            ),
            label: Text(
              'Subscription approved successfully',
              style: AppTextStyles.body.copyWith(color: lightColor),
            ),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildSnackBar(
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: lightColor,
            ),
            label: Text(
              'Failed to approve subscription: $e',
              style: AppTextStyles.body.copyWith(color: lightColor),
            ),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BusSubscription subscription) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Form(
        key: formKey,
        child: Animate(
          effects: [FadeEffect(), MoveEffect()],
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
              const Gap(16.0),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ).copyWith(bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius * 3.75,
                    gradient: themeController.isDark
                        ? darkGradient
                        : lightGradient,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius * 3,
                          gradient: themeController.isDark
                              ? darkGradient
                              : lightGradient,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: errorColor.withValues(alpha: 0.1),
                                    borderRadius: borderRadius * 2,
                                  ),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedAlert02,
                                    color: errorColor,
                                    size: 28,
                                  ),
                                ),
                                const Gap(12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reject Subscription',
                                        style: AppTextStyles.h3,
                                      ),
                                      const Gap(4.0),
                                      Text(
                                        'Provide a reason for rejection',
                                        style: AppTextStyles.small.copyWith(
                                          color: themeController.isDark
                                              ? seedPalette.shade50.withValues(
                                                  alpha: 0.7,
                                                )
                                              : greyColor.withValues(
                                                  alpha: 0.7,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16.0),

                            // Subscription info with student name
                            FutureBuilder<BaseUser?>(
                              future: _getCachedUser(subscription.studentId),
                              builder: (context, snapshot) {
                                final displayName =
                                    snapshot.data?.name ??
                                    subscription.studentId;

                                return Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: themeController.isDark
                                        ? seedColor.withValues(alpha: 0.05)
                                        : seedPalette.shade50.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: borderRadius * 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedUser,
                                            size: 20,
                                            color: themeController.isDark
                                                ? seedPalette.shade50
                                                : seedColor,
                                          ),
                                          const Gap(8.0),
                                          Expanded(
                                            child:
                                                snapshot.connectionState ==
                                                    ConnectionState.waiting
                                                ? Container(
                                                        height: 20,
                                                        width: double.infinity,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              themeController
                                                                  .isDark
                                                              ? seedColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    )
                                                              : seedPalette
                                                                    .shade50
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                          borderRadius:
                                                              borderRadius *
                                                              1.5,
                                                        ),
                                                      )
                                                      .animate(
                                                        onPlay: (controller) =>
                                                            controller.repeat(),
                                                      )
                                                      .shimmer(
                                                        duration:
                                                            const Duration(
                                                              milliseconds:
                                                                  1500,
                                                            ),
                                                        color:
                                                            themeController
                                                                .isDark
                                                            ? lightColor
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  )
                                                            : lightColor
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                      )
                                                : Text(
                                                    displayName,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const Gap(8.0),
                                      Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedMail01,
                                            size: 20,
                                            color: themeController.isDark
                                                ? seedPalette.shade50
                                                      .withValues(alpha: 0.7)
                                                : greyColor.withValues(
                                                    alpha: 0.7,
                                                  ),
                                          ),
                                          const Gap(8.0),
                                          Expanded(
                                            child: Text(
                                              subscription.studentId,
                                              style: AppTextStyles.small
                                                  .copyWith(
                                                    color:
                                                        themeController.isDark
                                                        ? seedPalette.shade50
                                                              .withValues(
                                                                alpha: 0.7,
                                                              )
                                                        : greyColor.withValues(
                                                            alpha: 0.7,
                                                          ),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(8.0),
                                      Divider(
                                        height: 1,
                                        color: themeController.isDark
                                            ? seedColor.withValues(alpha: 0.2)
                                            : greyColor.withValues(alpha: 0.2),
                                      ),
                                      const Gap(8.0),
                                      Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons
                                                .strokeRoundedCalendar03,
                                            size: 20,
                                            color: themeController.isDark
                                                ? seedPalette.shade50
                                                      .withValues(alpha: 0.7)
                                                : greyColor.withValues(
                                                    alpha: 0.7,
                                                  ),
                                          ),
                                          const Gap(8.0),
                                          Text(
                                            '${subscription.semester.label} ${subscription.year}',
                                            style: AppTextStyles.small.copyWith(
                                              color: themeController.isDark
                                                  ? seedPalette.shade50
                                                        .withValues(alpha: 0.7)
                                                  : greyColor.withValues(
                                                      alpha: 0.7,
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Gap(24.0),

                      // Reason input
                      SimpleTextFormField(
                        controller: reasonController,
                        hintText: "Enter the reason for rejection...",
                        label: Text('Rejection Reason'),
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a reason for rejection';
                          }

                          // At least 10 characters
                          if (value.trim().length < 10) {
                            return 'Reason must be at least 10 characters long';
                          }
                          return null;
                        },
                      ),
                      const Gap(24.0),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: themeController.isDark
                                    ? seedColor.withValues(alpha: 0.2)
                                    : seedPalette.shade50,
                                foregroundColor: themeController.isDark
                                    ? lightColor
                                    : seedColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const Gap(12.0),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: errorColor,
                                foregroundColor: lightColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                              ),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                try {
                                  final currentUser =
                                      _authController.currentUser.value;
                                  if (currentUser == null) {
                                    throw Exception('User not authenticated');
                                  }

                                  await _subscriptionsController
                                      .rejectSubscription(
                                        subscriptionId: subscription.id,
                                        reviewerId: currentUser.id,
                                        reason: reasonController.text.trim(),
                                      );

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      buildSnackBar(
                                        prefixIcon: HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedCheckmarkCircle02,
                                          color: lightColor,
                                        ),
                                        label: Text(
                                          'Subscription rejected',
                                          style: AppTextStyles.body.copyWith(
                                            color: lightColor,
                                          ),
                                        ),
                                        backgroundColor: errorColor,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      buildSnackBar(
                                        prefixIcon: HugeIcon(
                                          icon: HugeIcons.strokeRoundedAlert02,
                                          color: lightColor,
                                        ),
                                        label: Text(
                                          'Failed to reject subscription: $e',
                                          style: AppTextStyles.body.copyWith(
                                            color: lightColor,
                                          ),
                                        ),
                                        backgroundColor: errorColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancelCircle,
                                color: lightColor,
                              ),
                              label: const Text('Reject'),
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
        ),
      ),
    );
  }
}

// Stat item widget
class _StatItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8.0,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: borderRadius * 1.5,
          ),
          child: HugeIcon(icon: icon, color: color),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
            Text(
              label,
              style: AppTextStyles.small.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

// Error widget
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: errorColor,
            size: 64,
          ),
          const Gap(16.0),
          Text('Error loading subscriptions', style: AppTextStyles.h3),
          const Gap(8.0),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: themeController.isDark
                  ? seedPalette.shade50.withValues(alpha: 0.7)
                  : greyColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16.0),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
            ),
            onPressed: onRetry,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 18,
              color: lightColor,
            ),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Empty widget
class _EmptyWidget extends StatelessWidget {
  final bool hasSearch;

  const _EmptyWidget({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(newSubscription, width: 200.0),
          const Gap(16.0),
          Text(
            hasSearch ? 'No subscriptions found' : 'No subscriptions yet',
            style: AppTextStyles.h3,
          ),
          const Gap(8.0),
          Text(
            hasSearch
                ? 'Try adjusting your filters'
                : 'Subscriptions will appear here',
            style: AppTextStyles.body.copyWith(color: greyColor),
          ),
        ],
      ),
    );
  }
}

// Empty state card
class _EmptyStateCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String message;
  final Color color;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: borderRadius * 2.5,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: color, size: 28),
          const Gap(16.0),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: borderRadius * 2,
          ),
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Gap(8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius * 2,
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.small.copyWith(
              color: lightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Expandable section
class _ExpandableSection extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final RxBool isExpanded;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.count,
    required this.color,
    required this.isExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: borderRadius * 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: borderRadius * 2,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: isExpanded.value
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    color: color,
                    size: 20,
                  ),
                  const Gap(16.0),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: borderRadius * 2,
                    ),
                    child: Text(
                      count.toString(),
                      style: AppTextStyles.small.copyWith(
                        color: lightColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded.value) ...[const Gap(16.0), ...children],
        ],
      ),
    );
  }
}

// Subscription card
class _SubscriptionCard extends StatelessWidget {
  final BusSubscription subscription;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isReviewComplete;
  final BaseUser? cachedUser;

  const _SubscriptionCard({
    required this.subscription,
    required this.onTap,
    this.onApprove,
    this.onReject,
    this.isReviewComplete = false,
    this.cachedUser,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = subscription.status == BusSubscriptionStatus.approved
        ? successColor
        : subscription.status == BusSubscriptionStatus.rejected
        ? errorColor
        : infoColor;

    final statusLabel = subscription.status == BusSubscriptionStatus.approved
        ? 'Approved'
        : subscription.status == BusSubscriptionStatus.rejected
        ? 'Rejected'
        : 'Pending';

    final displayName = cachedUser?.name ?? subscription.studentId;

    return Stack(
      alignment: Alignment.topLeft,
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 24.0),
          decoration: BoxDecoration(
            color: themeController.isDark
                ? seedColor.withValues(alpha: 0.4)
                : seedPalette.shade50.withValues(alpha: 0.5),
            border: Border.all(color: statusColor, width: 1.5),
            borderRadius: borderRadius * 2.0,
          ),
          child: Column(
            children: [
              // Header with ListTile
              ListTile(
                contentPadding: const EdgeInsets.all(10.0),
                onTap: onTap,
                leading: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: borderRadius * 1.5,
                  ),
                  child: HugeIcon(
                    icon: subscription.status == BusSubscriptionStatus.approved
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : subscription.status == BusSubscriptionStatus.rejected
                        ? HugeIcons.strokeRoundedCancelCircle
                        : HugeIcons.strokeRoundedLoading03,
                    color: statusColor,
                  ),
                ),
                title: Text(
                  displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "#${subscription.studentId}",
                    style: AppTextStyles.small.copyWith(
                      color: themeController.isDark
                          ? seedPalette.shade50.withValues(alpha: 0.7)
                          : greyColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  height: 1,
                  color: statusColor.withValues(alpha: 0.2),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          label: 'Semester',
                          value: subscription.semester.label,
                        ),
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedCalendar04,
                          label: 'Year',
                          value: subscription.year.toString(),
                        ),
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedLocation06,
                          label: 'Stop',
                          value: subscription.stop?.name ?? 'N/A',
                        ),
                      ],
                    ),

                    // Action buttons for pending subscriptions
                    if (!isReviewComplete &&
                        onApprove != null &&
                        onReject != null) ...[
                      const Gap(16.0),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: errorColor,
                                side: BorderSide(color: errorColor, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                              ),
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancelCircle,
                              ),
                              label: const Text('Reject'),
                            ),
                          ),
                          const Gap(12.0),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: onApprove,
                              style: FilledButton.styleFrom(
                                backgroundColor: successColor,
                                foregroundColor: lightColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                              ),
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                color: lightColor,
                              ),
                              label: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Top pills like CustomListTile
        Positioned(
          top: -14.0,
          left: 8.0,
          child: Row(
            spacing: 6.0,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: borderRadius * 2.0,
                  border: Border.all(
                    color: themeController.isDark ? darkColor : lightColor,
                    width: 2.0,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.small.copyWith(
                    color: lightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: themeController.isDark
                      ? seedColor.withValues(alpha: 0.8)
                      : seedPalette.shade100,
                  borderRadius: borderRadius * 2.0,
                  border: Border.all(
                    color: themeController.isDark ? darkColor : lightColor,
                    width: 2.0,
                  ),
                ),
                child: Text(
                  '${subscription.semester.label} ${subscription.year}',
                  style: AppTextStyles.small.copyWith(
                    color: themeController.isDark ? lightColor : seedColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Info row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final List<List<dynamic>> icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        spacing: 8.0,
        children: [
          HugeIcon(icon: icon, size: 20.0),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.small.copyWith(color: Colors.grey),
                ),
                Text(value, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
