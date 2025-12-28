import 'package:busin/controllers/controllers.dart';
import 'package:busin/ui/components/widgets/custom_list_tile.dart';
import 'package:busin/ui/components/widgets/buttons/primary_button.dart';
import 'package:busin/ui/screens/subscriptions/subscription_new.dart';
import 'package:busin/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/actors/roles.dart';
import '../../../models/subscription.dart';
import '../../../utils/utils.dart';
import '../../components/widgets/home/appbar_list_tile.dart';
import '../../components/widgets/user_avatar.dart';
import '../profile/profile.dart';
import '../subscriptions/subscription_details.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  static const String routeName = '/subscriptions_tab';

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  BusSubscriptionStatus? _selectedStatus;

  String get _currentSemesterLabel {
    final now = DateTime.now();
    Semester semester;
    if (now.month >= 9) {
      semester = Semester.fall;
    } else if (now.month >= 6) {
      semester = Semester.summer;
    } else {
      semester = Semester.spring;
    }
    return '${semester.label.toUpperCase()} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final BusSubscriptionsController busSubscriptionsController =
        Get.find<BusSubscriptionsController>();

    return Obx(() {
      final List<BusSubscription> subscriptions =
          busSubscriptionsController.busSubscriptions;

      if (subscriptions.isEmpty) {
        return _SubscriptionsEmptyState(
          ctaLabel: 'Subscribe now for ${_currentSemesterLabel}',
          onCTA: () async {
            await context.pushNamed(
              removeLeadingSlash(NewSubscriptionPage.routeName),
            );
            // Refresh subscriptions list when returning
            await busSubscriptionsController.refreshCurrentFilters();
          },
        );
      }

      final BusSubscription latestSubscription = subscriptions.first;
      final List<BusSubscription> remaining = subscriptions.length > 1
          ? subscriptions.sublist(1)
          : const [];
      final List<BusSubscription> filteredSubscriptions =
          _selectedStatus == null
          ? remaining
          : remaining.where((sub) => sub.status == _selectedStatus).toList();
      final bool hasActive = subscriptions.any((sub) => sub.isCurrentlyActive);
      final bool hasPending = subscriptions.any(
        (sub) => sub.status == BusSubscriptionStatus.pending,
      );
      final bool hasApproved = subscriptions.any(
        (sub) => sub.status == BusSubscriptionStatus.approved,
      );
      // Allow new subscription only if user doesn't have pending or approved subscriptions
      final bool canSubmitNew = !hasPending && !hasApproved;

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.contain,
            child: const Text('Subscriptions'),
          ),
          actions: [
            if (canSubmitNew)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    overlayColor: accentColor.withValues(alpha: 0.1),
                  ),
                  onPressed: () async {
                    await context.pushNamed(
                      removeLeadingSlash(NewSubscriptionPage.routeName),
                    );
                    // Refresh subscriptions list when returning
                    await busSubscriptionsController.refreshCurrentFilters();
                  },
                  label: const Text('New'),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
                  iconAlignment: IconAlignment.end,
                ),
              ),
          ],
        ),
        body: Column(
          spacing: 20.0,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ).copyWith(top: 16.0),
              child: Column(
                spacing: 12.0,
                children: [
                  CustomListTile(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.pushNamed(
                        removeLeadingSlash(SubscriptionDetailsPage.routeName),
                        pathParameters: {
                          'subscriptionId': latestSubscription.id,
                        },
                      );
                    },
                    showBorder: true,
                    backgroundColor: latestSubscription.status.isRejected
                        ? errorColor.withValues(alpha: 0.05)
                        : latestSubscription.status.isPending
                        ? infoColor.withValues(alpha: 0.05)
                        : null,
                    borderColor: latestSubscription.status.isApproved
                        ? successColor
                        : latestSubscription.status ==
                              BusSubscriptionStatus.pending
                        ? infoColor
                        : errorColor,
                    topPillsBorderColor: themeController.isDark
                        ? seedColor
                        : lightColor,
                    title: Text(
                      latestSubscription.semesterYear,
                      style: Theme.of(context).listTileTheme.titleTextStyle
                          ?.copyWith(color: accentColor),
                    ),
                    subtitle: Row(
                      spacing: 8.0,
                      children: [
                        Text(
                          'Start: ${dateFormatter(latestSubscription.startDate)}',
                        ),
                        const Expanded(child: Divider()),
                        Text(
                          'End: ${dateFormatter(latestSubscription.endDate)}',
                        ),
                      ],
                    ),
                    primaryPillLabel:
                        '#${subscriptions.indexOf(latestSubscription) + 1} - ${latestSubscription.status.label}',
                  ),
                  if (!hasActive && !hasPending && canSubmitNew)
                    _ActiveSubscriptionCTA(
                      message:
                          'You don\'t have any subscription running currently. Maybe, subscribe now to the bus services for the ongoing semester',
                      ctaLabel: 'Subscribe now for ${_currentSemesterLabel}',
                      onPressed: () async {
                        await context.pushNamed(
                          removeLeadingSlash(NewSubscriptionPage.routeName),
                        );
                        // Refresh subscriptions list when returning
                        await busSubscriptionsController
                            .refreshCurrentFilters();
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32.0),
                  ),
                  color: themeController.isDark
                      ? seedPalette.shade900
                      : seedPalette.shade50,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedFilterHorizontal,
                            color: themeController.isDark
                                ? lightColor
                                : seedColor,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              spacing: 8.0,
                              children: BusSubscriptionStatus.values
                                  .map((status) {
                                    return ChoiceChip(
                                      label: Text(status.label),
                                      selected: _selectedStatus == status,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedStatus = selected
                                              ? status
                                              : null;
                                        });
                                      },
                                    );
                                  })
                                  .toList()
                                  .animate(interval: 60.ms)
                                  .fadeIn(
                                    duration: 220.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideX(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 260.ms,
                                    curve: Curves.easeOut,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: filteredSubscriptions.isEmpty
                          ? _EmptyListMessage(
                              message: _selectedStatus == null
                                  ? 'No other subscriptions yet.'
                                  : 'No ${_selectedStatus!.label.toLowerCase()} subscriptions match the filter.',
                            )
                          : ListView.separated(
                                  padding: EdgeInsets.symmetric(vertical: 4.0)
                                      .copyWith(
                                        bottom:
                                            56 +
                                            80 +
                                            MediaQuery.viewPaddingOf(
                                              context,
                                            ).bottom,
                                      ),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredSubscriptions.length,
                                  separatorBuilder: (_, __) => const Gap(12.0),
                                  itemBuilder: (_, index) {
                                    final busSubscription =
                                        filteredSubscriptions[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: CustomListTile(
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          context.pushNamed(
                                            removeLeadingSlash(
                                              SubscriptionDetailsPage.routeName,
                                            ),
                                            pathParameters: {
                                              'subscriptionId':
                                                  busSubscription.id,
                                            },
                                          );
                                        },
                                        topPillsBorderColor:
                                            themeController.isDark
                                            ? seedPalette.shade900
                                            : seedPalette.shade50,
                                        title: Text(
                                          busSubscription.semesterYear,
                                          style: Theme.of(context)
                                              .listTileTheme
                                              .titleTextStyle
                                              ?.copyWith(color: accentColor),
                                        ),
                                        subtitle: Row(
                                          spacing: 8.0,
                                          children: [
                                            Text(
                                              'Start: ${dateFormatter(busSubscription.startDate)}',
                                            ),
                                            const Expanded(child: Divider()),
                                            Text(
                                              'End: ${dateFormatter(busSubscription.endDate)}',
                                            ),
                                          ],
                                        ),
                                        primaryPillLabel:
                                            '#${subscriptions.indexOf(busSubscription) + 1}',
                                      ),
                                    );
                                  },
                                )
                                .animate()
                                .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  duration: 450.ms,
                                  curve: Curves.easeOut,
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ActiveSubscriptionCTA extends StatelessWidget {
  const _ActiveSubscriptionCTA({
    required this.message,
    required this.ctaLabel,
    required this.onPressed,
  });

  final String message;
  final String ctaLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: borderRadius * 4,
        color: accentColor.withValues(alpha: 0.1),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Text(message, style: AppTextStyles.body.copyWith(color: accentColor)),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton.label(onPressed: onPressed, label: ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyListMessage extends StatelessWidget {
  const _EmptyListMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 8.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedPackageSearch, color: greyColor, size: 64.0, strokeWidth: 1,),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: greyColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsEmptyState extends StatelessWidget {
  const _SubscriptionsEmptyState({required this.ctaLabel, required this.onCTA});

  final String ctaLabel;
  final VoidCallback onCTA;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: AppBarListTile(
          onTap: () => context.pushNamed(
            removeLeadingSlash(ProfilePage.routeName),
            pathParameters: {'tag': authController.userProfileImage},
          ),
          leading: UserAvatar(tag: authController.userProfileImage),
          title: authController.userDisplayName,
          subtitle: authController.isVerified
              ? AccountStatus.verified.label
              : AccountStatus.pending.label,
          subtitleColor: authController.isVerified ? successColor : infoColor,
        ),
      ),
      body: SizedBox(
        height: mediaHeight(context),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: mediaHeight(context) / 2,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32.0),
                ),
                color: themeController.isDark
                    ? seedPalette.shade900
                    : seedPalette.shade50,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0)
                    .copyWith(
                      bottom:
                          56 + 40 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                child: ListView(
                  children: [
                    Text(
                      'Seems like it’s your first time around',
                      style: AppTextStyles.body.copyWith(color: accentColor),
                    ),
                    const Gap(8.0),
                    Text(
                      'You don’t have any subscriptions yet',
                      style: AppTextStyles.title,
                    ),
                    const Gap(16.0),
                    Text(
                      'Let’s get you started with a bus subscription so you can ride this semester.',
                      style: AppTextStyles.body.copyWith(
                        color: themeController.isDark
                            ? seedPalette.shade50
                            : greyColor,
                      ),
                    ),
                    const Gap(20.0),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton.label(
                        label: ctaLabel,
                        onPressed: onCTA,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -30.0,
              left: 20.0,
              right: -56.0,
              child: IgnorePointer(
                child: Image.asset(papers)
                    .animate()
                    .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0,
                      end: 0.04,
                      duration: 520.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
