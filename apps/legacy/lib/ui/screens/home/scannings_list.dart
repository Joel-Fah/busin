import 'package:busin/controllers/scanning_controller.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/ui/components/widgets/custom_list_tile.dart';
import 'package:busin/utils/routes.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/scannings.dart';
import '../../../utils/constants.dart';

class ScanningsListPage extends StatefulWidget {
  const ScanningsListPage({super.key});

  static const String routeName = '/scannings_list';

  @override
  State<ScanningsListPage> createState() => _ScanningsListPageState();
}

class _ScanningsListPageState extends State<ScanningsListPage> {
  final ScanningController _scanningController = Get.find<ScanningController>();

  static List<String> _dayNames(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      l10n.weekday_monday,
      l10n.weekday_tuesday,
      l10n.weekday_wednesday,
      l10n.weekday_thursday,
      l10n.weekday_friday,
      l10n.weekday_saturday,
      l10n.weekday_sunday,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scannings)),
      body: Obx(() {
        final scannings = _scanningController.scannings;
        final isLoading = _scanningController.isBusy.value;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (scannings.isEmpty) {
          return _buildEmptyState();
        }

        // Group scannings by date
        final groupedScannings = _groupScanningsByDate(scannings);

        return RefreshIndicator(
          onRefresh: () async {
            await _scanningController.refreshLastScan(authController.userId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupedScannings.length,
            itemBuilder: (context, index) {
              final entry = groupedScannings.entries.elementAt(index);
              final date = entry.key;
              final scans = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 16.0,
                        ),
                        child: Text(
                          _formatDateHeader(date, l10n),
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0),

                  // Scannings for this date
                  ...scans.asMap().entries.map((scanEntry) {
                    final scanIndex = scanEntry.key;
                    final scan = scanEntry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildScanCard(scan, scanIndex),
                    );
                  }),

                  const Gap(16.0),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildScanCard(Scanning scan, int index) {
    final l10n = AppLocalizations.of(context)!;

    return CustomListTile(
          backgroundColor: themeController.isDark
              ? seedPalette.shade800.withValues(alpha: 0.2)
              : null,
          onTap: () {
            // TODO: Navigate to scan details
          },
          primaryPillLabel: '#${index + 1}',
          title: Text(
            scan.hasLocation
                ? maskCoordinates(scan.locationString)
                : l10n.homeTab_scanningsTile_titleUnavailable,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(4.0),
              Text(
                dateTimeFormatter(scan.scannedAt),
                style: AppTextStyles.small.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.6)
                      : darkColor.withValues(alpha: 0.6),
                ),
              ),
              if (scan.notes != null && scan.notes!.isNotEmpty) ...[
                const Gap(8.0),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: themeController.isDark
                        ? seedPalette.shade800.withValues(alpha: 0.3)
                        : seedPalette.shade50,
                    borderRadius: borderRadius,
                  ),
                  child: Row(
                    spacing: 8.0,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        size: 14.0,
                        color: infoColor,
                      ),
                      Expanded(
                        child: Text(
                          scan.notes!,
                          style: AppTextStyles.small.copyWith(
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.8)
                                : darkColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child:
            Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedQrCode,
                      color: themeController.isDark
                          ? lightColor.withValues(alpha: 0.2)
                          : darkColor.withValues(alpha: 0.2),
                      size: 80.0,
                    ),
                    const Gap(24.0),
                    Text(
                      l10n.homeTab_emptyScanningsCard_title,
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(8.0),
                    Text(
                      l10n.homeTab_emptyScanningsCard_message,
                      style: AppTextStyles.body.copyWith(
                        color: themeController.isDark
                            ? lightColor.withValues(alpha: 0.6)
                            : darkColor.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
      ),
    );
  }

  /// Group scannings by date (ignoring time)
  Map<DateTime, List<Scanning>> _groupScanningsByDate(
    List<Scanning> scannings,
  ) {
    final Map<DateTime, List<Scanning>> grouped = {};

    for (final scan in scannings) {
      final date = DateTime(
        scan.scannedAt.year,
        scan.scannedAt.month,
        scan.scannedAt.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(scan);
    }

    // Sort dates descending (most recent first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  /// Format date header based on how recent it is
  String _formatDateHeader(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return l10n.today;
    } else if (date == yesterday) {
      return l10n.yesterday;
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      // Within last week - show day name
      return _getDayName(date);
    } else {
      // Older - show full date
      return dateFormatter(date);
    }
  }

  /// Get day name from DateTime
  String _getDayName(DateTime date) {
    return _dayNames(context)[date.weekday - 1];
  }
}
