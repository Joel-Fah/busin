import 'package:busin/controllers/check_in_controller.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/models/check_in.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Draggable scrollable bottom sheet showing today's check-in list.
/// Opened from the scanner page in place of the restart icon.
class CheckInSheet extends StatefulWidget {
  const CheckInSheet({super.key});

  /// Show the sheet from any context.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckInSheet(),
    );
  }

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  final CheckInController _checkInController = Get.find<CheckInController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxInt _selectedTab = 0.obs; // 0=All, 1=Morning, 2=Closing

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CheckInEntry> _filtered(List<CheckInEntry> entries) {
    // Apply period filter
    List<CheckInEntry> filtered = entries;
    if (_selectedTab.value == 1) {
      filtered = filtered
          .where((e) => e.period == CheckInPeriod.morning)
          .toList();
    } else if (_selectedTab.value == 2) {
      filtered = filtered
          .where((e) => e.period == CheckInPeriod.evening)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final q = _searchQuery.value.toLowerCase();
      filtered = filtered
          .where((e) => e.studentName.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeController.isDark ? seedColor : lightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: greyColor.withValues(alpha: 0.4),
                  borderRadius: borderRadius * 2,
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.checkInSheet_title,
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Obx(() {
                            final total = _checkInController.todayTotalStudents;
                            return Text(
                              l10n.checkInSheet_subtitle(total),
                              style: AppTextStyles.body.copyWith(
                                color: greyColor,
                                fontSize: 13,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Period indicator (not reactive — based on time of day)
                    Builder(
                      builder: (context) {
                        final period = _checkInController.currentPeriod;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: borderRadius * 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: period == CheckInPeriod.morning
                                    ? HugeIcons.strokeRoundedSun03
                                    : HugeIcons.strokeRoundedMoon02,
                                color: accentColor,
                                size: 16,
                              ),
                              const Gap(6),
                              Text(
                                period == CheckInPeriod.morning
                                    ? l10n.checkInSheet_morningTab
                                    : l10n.checkInSheet_closingTab,
                                style: AppTextStyles.small.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Gap(12),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  controller: _searchController,
                  onChanged: (v) => _searchQuery.value = v,
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: themeController.isDark
                        ? seedPalette.shade50
                        : seedColor,
                    strokeWidth: 2,
                  ),
                  trailing: [
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
                          icon: HugeIcons.strokeRoundedCancelCircle,
                          color: themeController.isDark
                              ? lightColor
                              : seedColor,
                          size: 18,
                        ),
                      );
                    }),
                  ],
                  hintText: l10n.checkInSheet_searchHint,
                ),
              ),
              const Gap(8),

              // Period tabs (All / Morning / Closing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final selected = _selectedTab.value;
                  return Row(
                    spacing: 8,
                    children: [
                      _PeriodChip(
                        label: l10n.checkInSheet_allTab,
                        isSelected: selected == 0,
                        onTap: () => _selectedTab.value = 0,
                      ),
                      _PeriodChip(
                        label: l10n.checkInSheet_morningTab,
                        isSelected: selected == 1,
                        onTap: () => _selectedTab.value = 1,
                        icon: HugeIcons.strokeRoundedSun03,
                      ),
                      _PeriodChip(
                        label: l10n.checkInSheet_closingTab,
                        isSelected: selected == 2,
                        onTap: () => _selectedTab.value = 2,
                        icon: HugeIcons.strokeRoundedMoon02,
                      ),
                    ],
                  );
                }),
              ),
              const Gap(8),

              // List
              Expanded(
                child: Obx(() {
                  // Read observables to trigger rebuild
                  _searchQuery.value;
                  _selectedTab.value;
                  final entries = _checkInController.todayEntries;

                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckList,
                              color: themeController.isDark
                                  ? lightColor.withValues(alpha: 0.2)
                                  : darkColor.withValues(alpha: 0.2),
                              size: 64,
                            ),
                            const Gap(16),
                            Text(
                              l10n.checkInSheet_emptyTitle,
                              style: AppTextStyles.body.copyWith(
                                color: greyColor,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              l10n.checkInSheet_emptySubtitle,
                              style: AppTextStyles.small.copyWith(
                                color: greyColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filtered = _filtered(entries);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.checkInSheet_noMatch,
                        style: AppTextStyles.body.copyWith(color: greyColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                        .copyWith(
                          bottom: MediaQuery.paddingOf(context).bottom + 16,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _CheckInEntryTile(entry: entry)
                          .animate()
                          .fadeIn(
                            duration: 250.ms,
                            delay: (30 * index).ms,
                            curve: Curves.easeOut,
                          )
                          .slideX(
                            begin: 0.05,
                            end: 0,
                            duration: 300.ms,
                            delay: (30 * index).ms,
                            curve: Curves.easeOut,
                          );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Entry tile ──────────────────────────────────────────────────────

class _CheckInEntryTile extends StatelessWidget {
  const _CheckInEntryTile({required this.entry});

  final CheckInEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Arrival number
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${entry.arrivalOrder}',
              style: AppTextStyles.small.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage:
                entry.studentPhotoUrl != null &&
                    entry.studentPhotoUrl!.isNotEmpty
                ? NetworkImage(entry.studentPhotoUrl!)
                : null,
            child:
                entry.studentPhotoUrl == null || entry.studentPhotoUrl!.isEmpty
                ? Text(
                    entry.studentName.isNotEmpty
                        ? entry.studentName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.body.copyWith(
                      color: lightColor,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const Gap(10),
          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatTime(entry.scannedAt),
                  style: AppTextStyles.small.copyWith(
                    color: greyColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Period badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: entry.period == CheckInPeriod.morning
                  ? warningColor.withValues(alpha: 0.15)
                  : infoColor.withValues(alpha: 0.15),
              borderRadius: borderRadius,
            ),
            child: Text(
              entry.period == CheckInPeriod.morning
                  ? AppLocalizations.of(context)!.checkInSheet_morningTab
                  : AppLocalizations.of(context)!.checkInSheet_closingTab,
              style: AppTextStyles.small.copyWith(
                color: entry.period == CheckInPeriod.morning
                    ? warningColor
                    : infoColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : (themeController.isDark
                    ? seedColor.withValues(alpha: 0.5)
                    : seedPalette.shade50),
          borderRadius: borderRadius * 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null)
              HugeIcon(
                icon: icon!,
                size: 14,
                color: isSelected ? lightColor : greyColor,
              ),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: isSelected ? lightColor : greyColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
