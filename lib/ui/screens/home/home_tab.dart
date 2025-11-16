import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/controllers.dart';
import 'package:busin/models/scannings.dart';
import 'package:busin/models/subscription.dart';
import 'package:busin/ui/screens/profile/profile.dart';
import 'package:busin/ui/screens/subscriptions/subscription_details.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/actors/roles.dart';
import '../../../utils/constants.dart';
import '../../components/widgets/home/appbar_list_tile.dart';
import '../../components/widgets/custom_list_tile.dart';
import '../../components/widgets/user_avatar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  static const String routeName = '/home_tab';

  @override
  Widget build(BuildContext context) {
    // GetX Controllers
    final AuthController authController = Get.find<AuthController>();
    final BusSubscriptionsController busSubscriptionsController =
        Get.find<BusSubscriptionsController>();
    final BusSubscription lastBusSubscription =
        busSubscriptionsController.busSubscriptions.last;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
                color: themeController.isDark
                    ? seedPalette.shade900
                    : seedPalette.shade50,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 56.0)
                    .copyWith(
                      bottom:
                          56 + 80 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                children: [
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Activity",
                            style: AppTextStyles.title.copyWith(fontSize: 48.0),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              overlayColor: accentColor.withValues(alpha: 0.1),
                            ),
                            iconAlignment: IconAlignment.end,
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowUpRight02,
                            ),
                            label: Text(
                              "View all",
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.06,
                        end: 0,
                        duration: 360.ms,
                        curve: Curves.easeOut,
                      ),
                  const Gap(20.0)
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 380.ms,
                        curve: Curves.easeOut,
                      ),
                  CustomListTile(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed(
                            removeLeadingSlash(
                              SubscriptionDetailsPage.routeName,
                            ),
                            pathParameters: {
                              "subscriptionId": lastBusSubscription.id,
                            },
                          );
                        },
                        title: Text(
                          lastBusSubscription.semesterYear,
                          style: Theme.of(context).listTileTheme.titleTextStyle
                              ?.copyWith(color: accentColor),
                        ),
                        subtitle: Row(
                          spacing: 8.0,
                          children: [
                            Text(
                              "Start: ${dateFormatter(lastBusSubscription.startDate)}",
                            ),
                            Expanded(child: Divider()),
                            Text(
                              "End: ${dateFormatter(lastBusSubscription.endDate)}",
                            ),
                          ],
                        ),
                        primaryPillLabel:
                            "#" +
                            (busSubscriptionsController.busSubscriptions
                                        .indexOf(lastBusSubscription) +
                                    1)
                                .toString(),
                        secondaryPillLabel: "Subscriptions",
                      )
                      .animate()
                      .fadeIn(duration: 340.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                  const Gap(20.0),
                  CustomListTile(
                        onTap: () {},
                        primaryPillLabel:
                            "#" +
                            (dummyScannings.indexOf(dummyScannings.last) + 1)
                                .toString(),
                        secondaryPillLabel: "Scannings",
                        title: Text(
                          dummyScannings.last.location,
                          style: Theme.of(context).listTileTheme.titleTextStyle
                              ?.copyWith(color: accentColor),
                        ),
                        subtitle: Row(
                          spacing: 8.0,
                          children: [
                            Text(
                              "On: ${dateTimeFormatter(dummyScannings.last.scanTime)}",
                            ),
                            Expanded(child: Divider()),
                            Text(dummyScannings.last.location),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 450.ms,
                        curve: Curves.easeOut,
                      ),
                ],
              ),
            ),
            Positioned(
              top: -20.0,
              left: 20.0,
              right: -56.0,
              child: IgnorePointer(
                child: Image.asset(bus)
                    .animate()
                    .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                    .slideX(
                      begin: 0,
                      end: -0.04,
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
