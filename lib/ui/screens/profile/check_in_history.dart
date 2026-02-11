import 'dart:math';

import 'package:busin/controllers/check_in_controller.dart';
import 'package:busin/models/check_in.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Admin page showing check-in history with trend charts.
class CheckInHistoryPage extends StatefulWidget {
  const CheckInHistoryPage({super.key});

  static const String routeName = '/checkin_history';

  @override
  State<CheckInHistoryPage> createState() => _CheckInHistoryPageState();
}

class _CheckInHistoryPageState extends State<CheckInHistoryPage> {
  final CheckInController _checkInController = Get.find<CheckInController>();

  @override
  Widget build(BuildContext context) {
    final langCode = localeController.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langCode == 'en' ? 'Check-in History' : 'Historique des Check-ins',
        ),
      ),
      body: Obx(() {
        final history = _checkInController.history;

        if (history.isEmpty) {
          return _buildEmptyState(langCode);
        }

        return ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 32),
          children: [
            // ── Trend chart ──
            _TrendChart(history: history, langCode: langCode)
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .slideY(
                  begin: -0.05,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
            const Gap(24),

            // ── Summary stats ──
            _SummaryRow(history: history, langCode: langCode)
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.04, end: 0, duration: 350.ms, delay: 100.ms),
            const Gap(24),

            // ── Daily list ──
            Text(
              langCode == 'en' ? 'Daily Lists' : 'Listes Quotidiennes',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(12),
            ...history.asMap().entries.map((entry) {
              final index = entry.key;
              final list = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DayCard(checkInList: list, langCode: langCode)
                    .animate()
                    .fadeIn(
                      duration: 300.ms,
                      delay: (50 * index + 200).ms,
                      curve: Curves.easeOut,
                    )
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: 350.ms,
                      delay: (50 * index + 200).ms,
                      curve: Curves.easeOut,
                    ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState(String langCode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar03,
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.2)
                  : darkColor.withValues(alpha: 0.2),
              size: 80,
            ),
            const Gap(16),
            Text(
              langCode == 'en'
                  ? 'No check-in history'
                  : 'Aucun historique de check-in',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              langCode == 'en'
                  ? 'Start scanning students to build attendance records.'
                  : 'Commencez à scanner les étudiants pour créer des registres.',
              style: AppTextStyles.body.copyWith(color: greyColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trend Chart ─────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.history, required this.langCode});

  final List<CheckInList> history;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    // Take up to the last 14 days, reversed to chronological order
    final data = history.take(14).toList().reversed.toList();

    if (data.isEmpty) return const SizedBox.shrink();

    final maxStudents = data.fold<int>(
      0,
      (prev, e) => max(prev, e.totalStudents),
    );
    final maxY = (maxStudents + 5).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedPalette.shade900
            : seedPalette.shade50,
        borderRadius: borderRadius * 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langCode == 'en' ? 'Attendance Trend' : 'Tendance de Présence',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            langCode == 'en'
                ? 'Last ${data.length} days'
                : 'Les ${data.length} derniers jours',
            style: AppTextStyles.small.copyWith(color: greyColor, fontSize: 12),
          ),
          const Gap(20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: max(1, maxY / 5),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: greyColor.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: max(1, maxY / 5),
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTextStyles.small.copyWith(
                          color: greyColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every 2nd label to avoid clutter
                        if (data.length > 7 && i % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        final d = data[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: AppTextStyles.small.copyWith(
                              color: greyColor,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Total students line
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.totalStudents.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: data.length <= 14,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: accentColor,
                            strokeWidth: 0,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Morning entries line
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.morningCount.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: warningColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [6, 4],
                  ),
                  // Evening entries line
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.eveningCount.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: infoColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [6, 4],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final labels = [
                          langCode == 'en' ? 'Total' : 'Total',
                          langCode == 'en' ? 'Morning' : 'Matin',
                          langCode == 'en' ? 'Evening' : 'Soir',
                        ];
                        return LineTooltipItem(
                          '${labels[spot.barIndex]}: ${spot.y.toInt()}',
                          AppTextStyles.small.copyWith(
                            color: lightColor,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const Gap(12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: accentColor,
                label: langCode == 'en' ? 'Total' : 'Total',
              ),
              const Gap(16),
              _LegendDot(
                color: warningColor,
                label: langCode == 'en' ? 'Morning' : 'Matin',
                dashed: true,
              ),
              const Gap(16),
              _LegendDot(
                color: infoColor,
                label: langCode == 'en' ? 'Evening' : 'Soir',
                dashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: borderRadius),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: greyColor, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Summary Row ─────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.history, required this.langCode});

  final List<CheckInList> history;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final totalDays = history.length;
    final totalEntries = history.fold<int>(
      0,
      (sum, l) => sum + l.entries.length,
    );
    final avgStudents = totalDays > 0
        ? (history.fold<int>(0, (sum, l) => sum + l.totalStudents) / totalDays)
              .round()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: HugeIcons.strokeRoundedCalendar03,
            value: totalDays.toString(),
            label: langCode == 'en' ? 'Days' : 'Jours',
            color: accentColor,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            icon: HugeIcons.strokeRoundedCheckList,
            value: addThousandSeparator(totalEntries.toString()),
            label: langCode == 'en' ? 'Total Scans' : 'Total Scans',
            color: successColor,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            icon: HugeIcons.strokeRoundedUserMultiple,
            value: avgStudents.toString(),
            label: langCode == 'en' ? 'Avg / Day' : 'Moy / Jour',
            color: infoColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: borderRadius * 2,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: 20),
          const Gap(6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.small.copyWith(color: greyColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Day Card ────────────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  const _DayCard({required this.checkInList, required this.langCode});

  final CheckInList checkInList;
  final String langCode;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final list = widget.checkInList;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        list.date.year == today.year &&
        list.date.month == today.month &&
        list.date.day == today.day;

    return Container(
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedPalette.shade900
            : seedPalette.shade50,
        borderRadius: borderRadius * 2,
        border: isToday
            ? Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          // Header — tap to expand
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: borderRadius * 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? accentColor.withValues(alpha: 0.15)
                          : greyColor.withValues(alpha: 0.1),
                      borderRadius: borderRadius * 1.5,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      color: isToday ? accentColor : greyColor,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? (widget.langCode == 'en'
                                    ? 'Today'
                                    : 'Aujourd\'hui')
                              : dateFormatter(list.date),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${list.totalStudents} student${list.totalStudents != 1 ? 's' : ''}',
                              style: AppTextStyles.small.copyWith(
                                color: greyColor,
                                fontSize: 12,
                              ),
                            ),
                            const Gap(12),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedSun03,
                              size: 12,
                              color: warningColor,
                            ),
                            const Gap(2),
                            Text(
                              '${list.morningCount}',
                              style: AppTextStyles.small.copyWith(
                                color: warningColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(8),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedMoon02,
                              size: 12,
                              color: infoColor,
                            ),
                            const Gap(2),
                            Text(
                              '${list.eveningCount}',
                              style: AppTextStyles.small.copyWith(
                                color: infoColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  HugeIcon(
                    icon: _isExpanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    color: greyColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Expanded entries
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        color: themeController.isDark
                            ? lightColor.withValues(alpha: 0.1)
                            : darkColor.withValues(alpha: 0.1),
                      ),
                      ...list.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '#${entry.arrivalOrder}',
                                  style: AppTextStyles.small.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Gap(8),
                              CircleAvatar(
                                radius: 14,
                                backgroundImage:
                                    entry.studentPhotoUrl != null &&
                                        entry.studentPhotoUrl!.isNotEmpty
                                    ? NetworkImage(entry.studentPhotoUrl!)
                                    : null,
                                child:
                                    entry.studentPhotoUrl == null ||
                                        entry.studentPhotoUrl!.isEmpty
                                    ? Text(
                                        entry.studentName.isNotEmpty
                                            ? entry.studentName[0].toUpperCase()
                                            : '?',
                                        style: AppTextStyles.body.copyWith(
                                          color: lightColor,
                                          fontSize: 10,
                                        ),
                                      )
                                    : null,
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  entry.studentName,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatTime(entry.scannedAt),
                                style: AppTextStyles.small.copyWith(
                                  color: greyColor,
                                  fontSize: 11,
                                ),
                              ),
                              const Gap(6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: entry.period == CheckInPeriod.morning
                                      ? warningColor.withValues(alpha: 0.15)
                                      : infoColor.withValues(alpha: 0.15),
                                  borderRadius: borderRadius * 0.5,
                                ),
                                child: HugeIcon(
                                  icon: entry.period == CheckInPeriod.morning
                                      ? HugeIcons.strokeRoundedSun03
                                      : HugeIcons.strokeRoundedMoon02,
                                  size: 10,
                                  color: entry.period == CheckInPeriod.morning
                                      ? warningColor
                                      : infoColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
