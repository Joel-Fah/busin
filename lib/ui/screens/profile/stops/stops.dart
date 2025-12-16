import 'package:busin/ui/screens/profile/stops/stops_new.dart';
import 'package:busin/ui/screens/profile/stops/stops_edit.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../controllers/bus_stops_controller.dart';
import '../../../../models/value_objects/bus_stop_selection.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/utils.dart';
import '../../../components/widgets/bus_stop_card.dart';
import '../../../components/widgets/default_snack_bar.dart';
import '../../../components/widgets/loading_indicator.dart';

class BusStopsManagementPage extends StatefulWidget {
  static const String routeName = '/bus-stops';

  const BusStopsManagementPage({super.key});

  @override
  State<BusStopsManagementPage> createState() => _BusStopsManagementPageState();
}

class _BusStopsManagementPageState extends State<BusStopsManagementPage> {
  final BusStopsController _busStopController = Get.find<BusStopsController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Stops'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => _busStopController.fetchBusStops(),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
            ),
            IconButton.filled(
              tooltip: "New stop",
              style: IconButton.styleFrom(
                backgroundColor: accentColor
              ),
              onPressed: () =>
                  context.pushNamed(removeLeadingSlash(NewStopPage.routeName)),
              icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0).copyWith(bottom: 80.0),
          child: Column(
            children: [
              // Search bar
              SearchBar(
                controller: _searchController,
                onChanged: (value) => _busStopController.searchBusStops(value),
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: themeController.isDark
                      ? seedPalette.shade50
                      : seedColor,
                  strokeWidth: 2.0,
                ),
                trailing: [
                  Obx(() {
                    if (_busStopController.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _busStopController.searchBusStops('');
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
                hintText: 'Filter bus stops...',
              ),
              const Gap(16.0),

              // Stats section
              Obx(() {
                final total = _busStopController.busStops.length;
                final withImage = _busStopController.busStops
                    .where((s) => s.hasImage)
                    .length;
                final withMap = _busStopController.busStops
                    .where((s) => s.hasMapEmbed)
                    .length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      icon: HugeIcons.strokeRoundedLocation01,
                      label: 'Total Stops',
                      value: total.toString(),
                      color: accentColor,
                    ),
                    _StatItem(
                      icon: HugeIcons.strokeRoundedImage02,
                      label: 'With Images',
                      value: withImage.toString(),
                      color: successColor,
                    ),
                    _StatItem(
                      icon: HugeIcons.strokeRoundedMaps,
                      label: 'With Maps',
                      value: withMap.toString(),
                      color: infoColor,
                    ),
                  ],
                );
              }),

              const Gap(36.0),

              // Bus stops list
              Obx(() {
                if (_busStopController.isLoading.value &&
                    _busStopController.busStops.isEmpty) {
                  return Center(
                    child: LoadingIndicator(),
                  );
                }

                if (_busStopController.error.value.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedAlert02,
                            color: errorColor,
                            size: 64,
                          ),
                          const Gap(16.0),
                          Text(
                            'Error loading bus stops',
                            style: AppTextStyles.h3,
                          ),
                          const Gap(8.0),
                          Text(
                            _busStopController.error.value,
                            style: AppTextStyles.body.copyWith(
                              color: themeController.isDark
                                  ? seedPalette.shade50.withValues(alpha: 0.7)
                                  : greyColor.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Gap(16.0),
                          TextButton.icon(
                            onPressed: () => _busStopController.fetchBusStops(),
                            style: TextButton.styleFrom(
                              overlayColor: accentColor.withValues(alpha: 0.1),
                            ),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedRefresh,
                              size: 18,
                            ),
                            label: const Text(
                              'Retry',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredStops = _busStopController.filteredBusStops;

                if (filteredStops.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(busStop, width: 200.0),
                        const Gap(16.0),
                        Text(
                          _busStopController.searchQuery.value.isEmpty
                              ? 'No bus stops yet'
                              : 'No bus stops found',
                          style: AppTextStyles.h3,
                        ),
                        const Gap(8.0),
                        Text(
                          _busStopController.searchQuery.value.isEmpty
                              ? 'Add your first bus stop'
                              : 'Try a different search query',
                          style: AppTextStyles.body.copyWith(color: greyColor),
                        ),
                      ],
                    ),
                  );
                }

                return Expanded(
                  child: OverflowBox(
                    maxWidth: mediaWidth(context),
                    child: PageView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredStops.length,
                      physics: const BouncingScrollPhysics(),
                      controller: PageController(),
                      itemBuilder: (context, index) {
                        final stop = filteredStops[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: BusStopCard(
                            index: index,
                            stop: stop,
                            onEdit: () => _showEditDialog(stop),
                            onDelete: () => _showDeleteDialog(stop),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BusStop stop) {
    context.pushNamed(
      removeLeadingSlash(EditStopPage.routeName),
      pathParameters: {'stopId': stop.id},
    );
  }

  void _showDeleteDialog(BusStop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        ),
        child: ListView(
          shrinkWrap: true,
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
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: borderRadius * 3,
                gradient: themeController.isDark ? darkGradient : lightGradient
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with warning icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.1),
                          borderRadius: borderRadius * 1.5,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          color: errorColor,
                          size: 24,
                        ),
                      ),
                      const Gap(12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Bus Stop',
                              style: AppTextStyles.h3,
                            ),
                            Text(
                              'This action cannot be undone',
                              style: AppTextStyles.small.copyWith(color: errorColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(24.0),

                  // Stop information
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: errorColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      borderRadius: borderRadius * 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: errorColor,
                              size: 20,
                            ),
                            const Gap(8.0),
                            Expanded(
                              child: Text(
                                stop.name,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: errorColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Gap(12.0),
                        Divider(
                          color: errorColor.withValues(alpha: 0.2),
                          height: 1,
                        ),
                        const Gap(12.0),
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedImage02,
                          label: 'Image',
                          value: stop.hasImage ? 'Yes' : 'No',
                          valueColor: stop.hasImage ? lightColor : lightColor.withValues(alpha: 0.5),
                        ),
                        const Gap(8.0),
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedMaps,
                          label: 'Map',
                          value: stop.hasMapEmbed ? 'Yes' : 'No',
                          valueColor: stop.hasMapEmbed ? lightColor : lightColor.withValues(alpha: 0.5),
                        ),
                        const Gap(8.0),
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          label: 'Created',
                          value: dateTimeFormatter(stop.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24.0),

                  // Warning message
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: warningColor.withValues(alpha: 0.1),
                      borderRadius: borderRadius * 1.75,
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAlert01,
                          color: warningColor,
                          size: 20,
                        ),
                        const Gap(12.0),
                        Expanded(
                          child: Text(
                            'All data associated with this stop will be permanently deleted.',
                            style: AppTextStyles.small.copyWith(
                              color: warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24.0),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            side: BorderSide(
                              color: themeController.isDark
                                  ? seedPalette.shade100
                                  : seedColor,
                            ),
                          ),
                          child: Text('Cancel', style: AppTextStyles.body.copyWith(
                            color: themeController.isDark ? lightColor : seedColor
                          ),),
                        ),
                      ),
                      const Gap(12.0),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final success = await _busStopController.deleteBusStop(stop.id);

                            if (context.mounted) {
                              context.pop();

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  buildSnackBar(
                                    prefixIcon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                      color: lightColor,
                                    ),
                                    label: Text('Bus stop "${stop.name}" deleted'),
                                    backgroundColor: successColor,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  buildSnackBar(
                                    prefixIcon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedAlert02,
                                      color: lightColor,
                                    ),
                                    label: const Text('Failed to delete bus stop'),
                                    backgroundColor: errorColor,
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: errorColor,
                            foregroundColor: lightColor,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            color: lightColor,
                          ),
                          label: const Text('Delete', style: AppTextStyles.body,),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Stats item widget
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
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: borderRadius * 1.75,
          ),
          child: HugeIcon(icon: icon, color: color, size: 20.0),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: themeController.isDark ? seedPalette.shade50 : greyColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          color: themeController.isDark ? lightColor : seedColor,
        ),
        const Gap(12.0),
        Text(label, style: AppTextStyles.body),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
