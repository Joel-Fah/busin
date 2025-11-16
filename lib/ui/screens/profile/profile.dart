import 'dart:math';
import 'dart:ui';

import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/subscriptions_controller.dart';
import 'package:busin/models/scannings.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
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
            padding: EdgeInsets.all(16.0),
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
                                    " (${authController.currentUser.value!.role.name})",
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
                          children: [
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
                                  "Subscriptions",
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
                                    dummyScannings.length.toString(),
                                  ),
                                  style: AppTextStyles.h3,
                                ),
                                subtitle: Text(
                                  "Scannings",
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
                                  "Joined",
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
              ListSubHeading(label: "Your data on BusIn"),
              const Gap(20.0),
              ListTile(
                onTap: () {
                  HapticFeedback.mediumImpact();
                },
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedUserList,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
                title: Text("Account info"),
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
                },
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedAppleVisionPro,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
                title: Text("Appearance"),
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
                },
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedAudit01,
                  color: themeController.isDark ? lightColor : seedColor,
                ),
                title: Text("Legal"),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                  color: themeController.isDark ? lightColor : seedColor,
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

class AppInfoBar extends StatefulWidget {
  const AppInfoBar({super.key});

  @override
  State<AppInfoBar> createState() => _AppInfoBarState();
}

class _AppInfoBarState extends State<AppInfoBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final info = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '©2025 - All rights reserved - ${info.appName} v${info.version}+${info.buildNumber}',
              style: AppTextStyles.small,
            ),
          );
        } else {
          if (snapshot.hasError) {
            if (kDebugMode) {
              print('Error fetching package info: ${snapshot.error}');
            }
          }
          return SizedBox.shrink();
        }
      },
    );
  }
}
