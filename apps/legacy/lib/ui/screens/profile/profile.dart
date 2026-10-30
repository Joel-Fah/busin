import 'dart:math';
import 'dart:ui';

import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/report_controller.dart';
import 'package:busin/controllers/scanning_controller.dart';
import 'package:busin/controllers/subscriptions_controller.dart';
import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/student.dart';
import 'package:busin/ui/components/widgets/sign_out_confirmation.dart';
import 'package:busin/ui/screens/profile/account_info.dart';
import 'package:busin/ui/screens/profile/appearance.dart';
import 'package:busin/ui/screens/profile/legal.dart';
import 'package:busin/ui/screens/profile/reports.dart';
import 'package:busin/ui/screens/profile/reports_admin.dart';
import 'package:busin/ui/screens/profile/check_in_history.dart';
import 'package:busin/ui/screens/profile/semesters/semester.dart';
import 'package:busin/ui/screens/profile/stops/stops.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../controllers/semester_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../components/widgets/list_subheading.dart';
import '../../components/widgets/user_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.tag});

  static const String routeName = "/profile";
  final String tag;

  @override
  Widget build(BuildContext context) {
    // GetX Controllers
    final AuthController authController = Get.find<AuthController>();
    final BusSubscriptionsController busSubscriptionsController =
        Get.find<BusSubscriptionsController>();
    final ScanningController scanningController =
        Get.find<ScanningController>();
    final SemesterController _semesterController =
        Get.find<SemesterController>();

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.contain,
          child: Text(l10n.profilePage_appBar_title),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: -mediaHeight(context) / 3.5,
            left: -150.0,
            right: -150.0,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
              child: Container(
                height: mediaHeight(context),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors
                          .primaries[Random().nextInt(Colors.primaries.length)]
                          .withValues(alpha: 0.1),
                      Colors
                          .primaries[Random().nextInt(Colors.primaries.length)]
                          .withValues(alpha: 0.1),
                      Colors.primaries[Random().nextInt(Colors.accents.length)]
                          .withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.0).copyWith(bottom: 32.0),
            children: [
              Row(
                spacing: 16.0,
                children: [
                  Stack(
                    children: [
                      UserAvatar(tag: tag, radius: 48.0),
                      if (authController.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeController.isDark
                                  ? seedColor
                                  : lightColor,
                              border: Border.all(
                                color: themeController.isDark
                                    ? seedColor
                                    : lightColor,
                                width: 1.0,
                              ),
                            ),
                            padding: EdgeInsets.all(2.0),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                              strokeWidth: 2.0,
                              color: successColor,
                            ),
                          ).animate(delay: 800.ms).fade().moveX().scale(),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: authController.userDisplayName,
                            children: [
                              TextSpan(
                                text:
                                    " (${authController.currentUser.value!.role.getDisplayLabel(context)})",
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.normal,
                                  fontVariations: [FontVariation('wght', 400)],
                                  color: themeController.isDark
                                      ? lightColor.withValues(alpha: 0.5)
                                      : seedColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Wrap(
                          spacing: 24.0,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: authController.isStudent
                              ? [
                                  // Student stats: Subscriptions & Scannings
                                  IntrinsicWidth(
                                    child: ListTile(
                                      minTileHeight: 0.0,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        addThousandSeparator(
                                          busSubscriptionsController
                                              .busSubscriptions
                                              .length
                                              .toString(),
                                        ),
                                        style: AppTextStyles.h3,
                                      ),
                                      subtitle: Text(
                                        busSubscriptionsController
                                                    .busSubscriptions
                                                    .length >
                                                1
                                            ? l10n.subscriptions
                                            : l10n.subscriptions.substring(
                                                0,
                                                l10n.subscriptions.length - 1,
                                              ),
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IntrinsicWidth(
                                    child: ListTile(
                                      minTileHeight: 0.0,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        addThousandSeparator(
                                          scanningController.scannings.length
                                              .toString(),
                                        ),
                                        style: AppTextStyles.h3,
                                      ),
                                      subtitle: Text(
                                        scanningController.scannings.length > 1
                                            ? l10n.scannings
                                            : l10n.scannings.substring(
                                                0,
                                                l10n.scannings.length - 1,
                                              ),
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IntrinsicWidth(
                                    child: ListTile(
                                      minTileHeight: 0.0,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        dateFormatter(
                                          authController
                                                  .currentUser
                                                  .value!
                                                  .createdAt ??
                                              DateTime.now(),
                                        ),
                                        style: AppTextStyles.h3,
                                      ),
                                      subtitle: Text(
                                        l10n.joined,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  // Admin/Staff stats: Reviews done, Scannings done, Joined date
                                  Obx(() {
                                    final currentUserId = authController.userId;
                                    final reviewsCount =
                                        busSubscriptionsController
                                            .busSubscriptions
                                            .where(
                                              (sub) =>
                                                  sub
                                                      .observation
                                                      ?.reviewerUserId ==
                                                  currentUserId,
                                            )
                                            .length;

                                    return IntrinsicWidth(
                                      child: ListTile(
                                        minTileHeight: 0.0,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          addThousandSeparator(
                                            reviewsCount.toString(),
                                          ),
                                          style: AppTextStyles.h3,
                                        ),
                                        subtitle: Text(
                                          reviewsCount > 1
                                              ? 'Reviews'
                                              : 'Review',
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  Obx(() {
                                    final currentUserId = authController.userId;
                                    final scansCount = scanningController
                                        .scannings
                                        .where(
                                          (scan) =>
                                              scan.scannedBy == currentUserId,
                                        )
                                        .length;

                                    return IntrinsicWidth(
                                      child: ListTile(
                                        minTileHeight: 0.0,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          addThousandSeparator(
                                            scansCount.toString(),
                                          ),
                                          style: AppTextStyles.h3,
                                        ),
                                        subtitle: Text(
                                          scansCount > 1
                                              ? l10n.scannings
                                              : l10n.scannings.substring(
                                                  0,
                                                  l10n.scannings.length - 1,
                                                ),
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  IntrinsicWidth(
                                    child: ListTile(
                                      minTileHeight: 0.0,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        dateFormatter(
                                          authController
                                                  .currentUser
                                                  .value!
                                                  .createdAt ??
                                              DateTime.now(),
                                        ),
                                        style: AppTextStyles.h3,
                                      ),
                                      subtitle: Text(
                                        l10n.joined,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(64.0),
              ListSubHeading(label: l10n.profilePage_subHeading_yourData),
              const Gap(20.0),
              Obx(() {
                final user = authController.currentUser.value;
                final hasIncompleteInfo = _hasIncompleteInfo(user);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListTile(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.pushNamed(
                          removeLeadingSlash(AccountInfoPage.routeName),
                        );
                      },
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedUserList,
                        color: themeController.isDark ? lightColor : seedColor,
                      ),
                      title: Text(l10n.profilePage_listTile_accountInfo),
                      subtitle: hasIncompleteInfo
                          ? Text(
                              l10n.profilePage_accountInfo_subtitle,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14.0,
                                color: warningColor,
                              ),
                            )
                          : null,
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowUpRight01,
                        color: themeController.isDark ? lightColor : seedColor,
                      ),
                    ),
                    if (hasIncompleteInfo)
                      Positioned(
                        top: -8.0,
                        right: 8.0,
                        child:
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: warningColor,
                                    borderRadius: borderRadius * 0.75,
                                  ),
                                  child: Row(
                                    spacing: 4.0,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedAlert02,
                                        color: themeController.isDark
                                            ? seedColor
                                            : lightColor,
                                        size: 12.0,
                                      ),
                                      Text(
                                        l10n.profilePage_accountInfo_badge,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 12.0,
                                          color: themeController.isDark
                                              ? seedColor
                                              : lightColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .shimmer(
                                  duration: 2000.ms,
                                  color: lightColor.withValues(alpha: 0.3),
                                ),
                      ),
                  ],
                );
              }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(color: greyColor, thickness: 0.5),
              ),
              ListTile(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.pushNamed(
                    removeLeadingSlash(AppearancePage.routeName),
                  );
                },
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedAppleVisionPro,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
                title: Text(l10n.profilePage_listTile_appearance),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
              ),
              // ── Student: My Reports tile ──
              if (authController.isStudent) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Divider(color: greyColor, thickness: 0.5),
                ),
                Obx(() {
                  final ReportController reportController =
                      Get.find<ReportController>();
                  final pending = reportController.pendingCount.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ListTile(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed(
                            removeLeadingSlash(ReportsPage.routeName),
                          );
                        },
                        leading: HugeIcon(
                          icon: HugeIcons.strokeRoundedComplaint,
                          color: themeController.isDark
                              ? lightColor
                              : seedColor,
                        ),
                        title: Text(l10n.profilePage_listTile_myReports),
                        trailing: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowUpRight01,
                          color: themeController.isDark
                              ? lightColor
                              : seedColor,
                        ),
                      ),
                      if (pending > 0)
                        Positioned(
                          top: -4.0,
                          right: 8.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: infoColor,
                              borderRadius: borderRadius * 0.75,
                            ),
                            child: Text(
                              pending.toString(),
                              style: AppTextStyles.small.copyWith(
                                color: lightColor,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(color: greyColor, thickness: 0.5),
              ),
              ListTile(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.pushNamed(removeLeadingSlash(LegalPage.routeName));
                },
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedAudit01,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
                title: Text(l10n.profilePage_listTile_legal),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
              ),
              if (authController.isAdmin || authController.isStaff) ...[
                const Gap(24.0),
                ListSubHeading(
                  label: l10n.profilePage_subHeading_busManagement,
                ),
                const Gap(20.0),
                ListTile(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.pushNamed(
                      removeLeadingSlash(BusStopsManagementPage.routeName),
                    );
                  },
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedDirections02,
                    color: themeController.isDark ? lightColor : seedColor,
                  ),
                  title: Text(l10n.profilePage_listTile_busStops),
                  subtitle: Text(l10n.profilePage_busStops_subtitle),
                  trailing: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowUpRight01,
                    color: themeController.isDark ? lightColor : seedColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Divider(color: greyColor, thickness: 0.5),
                ),
                ListTile(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.pushNamed(
                      removeLeadingSlash(SemesterManagementPage.routeName),
                    );
                  },
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar02,
                    color: themeController.isDark ? lightColor : seedColor,
                  ),
                  title: Text(l10n.profilePage_listTile_semesters),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.profilePage_semesters_subtitle),
                      // Active semester indicator
                      Obx(() {
                        final active = _semesterController.activeSemester.value;
                        if (active == null) return const SizedBox.shrink();

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: successColor.withValues(alpha: 0.1),
                            borderRadius: borderRadius,
                          ),
                          child: Row(
                            spacing: 8.0,
                            children: [
                              Text(
                                '${active.semester.label} ${active.year}',
                                style: AppTextStyles.small.copyWith(
                                  color: successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: successColor,
                                  thickness: 0.5,
                                ),
                              ),
                              Text(
                                '${dateFormatter(active.startDate)} - ${dateFormatter(active.endDate)}',
                                style: AppTextStyles.small.copyWith(
                                  color: successColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  trailing: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowUpRight01,
                    color: themeController.isDark ? lightColor : seedColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Divider(color: greyColor, thickness: 0.5),
                ),
                // ── Admin: Student Reports tile ──
                Obx(() {
                  final ReportController reportController =
                      Get.find<ReportController>();
                  final pending = reportController.pendingCount.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ListTile(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed(
                            removeLeadingSlash(ReportsAdminPage.routeName),
                          );
                        },
                        leading: HugeIcon(
                          icon: HugeIcons.strokeRoundedComplaint,
                          color: themeController.isDark
                              ? lightColor
                              : seedColor,
                        ),
                        title: Text(l10n.profilePage_listTile_studentReports),
                        subtitle: Text(
                          l10n.profilePage_studentReports_subtitle,
                        ),
                        trailing: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowUpRight01,
                          color: themeController.isDark
                              ? lightColor
                              : seedColor,
                        ),
                      ),
                      if (pending > 0)
                        Positioned(
                          top: -8.0,
                          right: 8.0,
                          child:
                              Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: errorColor,
                                      borderRadius: borderRadius * 0.75,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 4.0,
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons.strokeRoundedAlert02,
                                          color: lightColor,
                                          size: 12.0,
                                        ),
                                        Text(
                                          '$pending ${l10n.profilePage_pendingBadge}',
                                          style: AppTextStyles.small.copyWith(
                                            color: lightColor,
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: 2000.ms,
                                    color: lightColor.withValues(alpha: 0.3),
                                  ),
                        ),
                    ],
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Divider(color: greyColor, thickness: 0.5),
                ),
                // ── Admin: Check-in History tile ──
                ListTile(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.pushNamed(
                      removeLeadingSlash(CheckInHistoryPage.routeName),
                    );
                  },
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckList,
                    color: themeController.isDark ? lightColor : seedColor,
                  ),
                  title: Text(l10n.profilePage_listTile_checkInHistory),
                  subtitle: Text(l10n.profilePage_checkInHistory_subtitle),
                  trailing: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowUpRight01,
                    color: themeController.isDark ? lightColor : seedColor,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(color: greyColor, thickness: 0.5),
              ),
              ListTile(
                onTap: () => showSignOutConfirmation(
                  context,
                  authController: authController,
                  l10n: l10n,
                ),
                splashColor: errorColor.withValues(alpha: 0.2),
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  color: errorColor,
                ),
                title: Text(
                  l10n.profilePage_listTile_signOut,
                  style: Theme.of(
                    context,
                  ).listTileTheme.titleTextStyle?.copyWith(color: errorColor),
                ),
              ),
              const Gap(64.0),
              AppInfoBar(),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper function to check if user has incomplete profile information
bool _hasIncompleteInfo(BaseUser? user) {
  if (user == null) return false;

  bool hasPhone = user.phone != null && user.phone!.isNotEmpty;

  if (user is Student) {
    bool hasAddress = user.address != null && user.address!.isNotEmpty;
    bool hasMatricule = user.matricule != null && user.matricule!.isNotEmpty;
    return !hasPhone || !hasAddress || !hasMatricule;
  }

  return !hasPhone;
}

class AppInfoBar extends StatefulWidget {
  const AppInfoBar({super.key});

  @override
  State<AppInfoBar> createState() => _AppInfoBarState();
}

class _AppInfoBarState extends State<AppInfoBar> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final info = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '©2025 - ${l10n.profilePage_appInfo_rights} - ${info.appName} v${info.version}+${info.buildNumber}',
              style: AppTextStyles.small,
            ),
          );
        } else {
          if (snapshot.hasError) {
            if (kDebugMode) {
              debugPrint('Error fetching package info: ${snapshot.error}');
            }
          }
          return SizedBox.shrink();
        }
      },
    );
  }
}
