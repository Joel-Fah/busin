import 'package:busin/controllers/controllers.dart';
import 'package:busin/ui/components/widgets/custom_list_tile.dart';
import 'package:busin/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/subscription.dart';
import '../../../utils/utils.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});
  static const String routeName = '/subscriptions_tab';

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  BusSubscriptionStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final BusSubscriptionsController busSubscriptionsController =
        Get.find<BusSubscriptionsController>();
    final List<BusSubscription> subscriptions =
        busSubscriptionsController.busSubscriptions;

    // Get the latest subscription
    final BusSubscription? latestSubscription = subscriptions.isNotEmpty
        ? subscriptions.first
        : null;

    // Filter remaining subscriptions
    final List<BusSubscription> filteredSubscriptions = _selectedStatus == null
        ? subscriptions.skip(1).toList()
        : subscriptions
              .skip(1)
              .where((sub) => sub.status == _selectedStatus)
              .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Subscriptions")),
      body: Column(
        spacing: 20.0,
        children: [
          if (latestSubscription != null)
            Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ).copyWith(top: 16.0),
                  child: CustomListTile(
                    onTap: () {},
                    showBorder: true,
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
                          "Start: ${dateFormatter(latestSubscription.startDate)}",
                        ),
                        const Expanded(child: Divider()),
                        Text(
                          "End: ${dateFormatter(latestSubscription.endDate)}",
                        ),
                      ],
                    ),
                    primaryPillLabel:
                        "#" +
                        (subscriptions.indexOf(latestSubscription) + 1)
                            .toString() +
                        " - Active",
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
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedFilterHorizontal,
                          color: themeController.isDark
                              ? lightColor
                              : seedColor,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
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
                                .fadeIn(duration: 220.ms, curve: Curves.easeOut)
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
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 4.0).copyWith(
                        bottom:
                            56 + 80 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredSubscriptions.length,
                      separatorBuilder: (_, __) => const Gap(12.0),
                      itemBuilder: (_, index) {
                        final busSubscription = filteredSubscriptions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: CustomListTile(
                            onTap: () {},
                            topPillsBorderColor: themeController.isDark
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
                                  "Start: ${dateFormatter(busSubscription.startDate)}",
                                ),
                                const Expanded(child: Divider()),
                                Text(
                                  "End: ${dateFormatter(busSubscription.endDate)}",
                                ),
                              ],
                            ),
                            primaryPillLabel: "#${index + 2}",
                          ),
                        );
                      },
                    ).animate()
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
  }
}
