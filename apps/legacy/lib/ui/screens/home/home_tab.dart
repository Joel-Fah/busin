import 'package:busin/controllers/controllers.dart';
import 'package:busin/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;


    // GetX Controllers
    final AuthController authController = Get.find<AuthController>();
    final BusSubscriptionsController busSubscriptionsController =
        Get.find<BusSubscriptionsController>();
    final ScanningController scanningController =
        Get.find<ScanningController>();

    return Obx(() {
      final subscriptions = busSubscriptionsController.busSubscriptions;
      final BusSubscription? lastBusSubscription = subscriptions.isNotEmpty
          ? subscriptions.last
          : null;

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
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 56.0,
                      ).copyWith(
                        bottom:
                            56 + 80 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                  children: [
                    Text(
                          l10n.homeTab_title,
                          style: AppTextStyles.title.copyWith(fontSize: 48.0),
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
                    if (lastBusSubscription != null)
                      CustomListTile(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.pushNamed(
                                removeLeadingSlash(
                                  SubscriptionDetailsPage.routeName,
                                ),
                                pathParameters: {
                                  'subscriptionId': lastBusSubscription.id,
                                },
                              );
                            },
                            title: Text(
                              lastBusSubscription.semesterYear,
                              style: Theme.of(context)
                                  .listTileTheme
                                  .titleTextStyle
                                  ?.copyWith(color: accentColor),
                            ),
                            subtitle: Row(
                              spacing: 8.0,
                              children: [
                                Text(
                                  '${l10n.homeTab_subscriptionTile_start} ${dateFormatter(lastBusSubscription.startDate)}',
                                ),
                                const Expanded(child: Divider()),
                                Text(
                                  '${l10n.homeTab_subscriptionTile_end} ${dateFormatter(lastBusSubscription.endDate)}',
                                ),
                              ],
                            ),
                            primaryPillLabel: '#${subscriptions.length}',
                            secondaryPillLabel: l10n.subscriptions,
                          )
                          .animate()
                          .fadeIn(duration: 340.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          )
                    else
                      _EmptyStateCard(
                        icon: HugeIcons.strokeRoundedBookmarkRemove02,
                        title: l10n.homeTab_emptySubscriptionCard_title,
                        message: l10n.homeTab_emptySubscriptionCard_message,
                      ),
                    const Gap(20.0),
                    // Last Scanning Activity
                    Obx(() {
                      final scannings = scanningController.scannings;
                      final lastScan = scanningController.lastScan.value;

                      if (lastScan != null) {
                        return CustomListTile(
                              onTap: () {
                                // TODO: Navigate to scannings page
                              },
                              primaryPillLabel: '#${scannings.length}',
                              secondaryPillLabel: l10n.scannings,
                              title: Text(
                                lastScan.hasLocation
                                    ? maskCoordinates(lastScan.locationString)
                                    : l10n.homeTab_scanningsTile_titleUnavailable,
                                style: Theme.of(context)
                                    .listTileTheme
                                    .titleTextStyle
                                    ?.copyWith(color: accentColor),
                              ),
                              subtitle: Text(
                                dateTimeFormatter(lastScan.scannedAt),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 450.ms,
                              curve: Curves.easeOut,
                            );
                      } else {
                        return _EmptyStateCard(
                              icon: HugeIcons.strokeRoundedQrCode,
                              title: l10n.homeTab_emptyScanningsCard_title,
                              message: l10n.homeTab_emptyScanningsCard_message,
                            )
                            .animate()
                            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 450.ms,
                              curve: Curves.easeOut,
                            );
                      }
                    }),
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
    });
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: borderRadius * 2,
        color: themeController.isDark
            ? seedPalette.shade800.withValues(alpha: 0.4)
            : seedPalette.shade100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, size: 32.0, color: accentColor),
          const Gap(12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                const Gap(4.0),
                Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: themeController.isDark
                        ? seedPalette.shade50
                        : greyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
