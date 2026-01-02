import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/utils/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/analytics_controller.dart';
import '../../../ui/screens/profile/semesters/semester.dart';
import '../../../ui/screens/profile/stops/stops.dart';
import '../../../ui/screens/profile/subscriptions_admin.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import '../../components/widgets/analytics_card.dart';
import '../../components/widgets/loading_indicator.dart';
import '../../components/widgets/stat_card.dart';
import '../../components/widgets/user_avatar.dart';
import '../profile/profile.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final AnalyticsController _analyticsController =
      Get.find<AnalyticsController>();

  @override
  void initState() {
    super.initState();
    _refreshAnalytics();
  }

  Future<void> _refreshAnalytics() async {
    await _analyticsController.refreshAnalytics();
  }

  String _getTrendText(double change, String period) {
    if (change == 0) return '0% $period';
    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}% $period';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.contain,
          child: Text(l10n.analyticsTab_appBar_title),
        ),
        actions: [
          Obx(() {
            return IconButton(
              tooltip: _analyticsController.showGraphical.value
                  ? l10n.analyticsTab_appBar_actionNumView
                  : l10n.analyticsTab_appBar_actionGraphView,
              onPressed: () => _analyticsController.toggleView(),
              icon: HugeIcon(
                icon: _analyticsController.showGraphical.value
                    ? HugeIcons.strokeRoundedMenu03
                    : HugeIcons.strokeRoundedAnalytics02,
              ),
            );
          }),
          Obx(() {
            return _analyticsController.isBusy.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.refresh,
                    onPressed: _refreshAnalytics,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
                  );
          }),
          GestureDetector(
            onTap: () => context.pushNamed(
              removeLeadingSlash(ProfilePage.routeName),
              pathParameters: {'tag': authController.userProfileImage},
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 4.0),
              child: Tooltip(
                message: l10n.userProfile,
                child: UserAvatar(
                  tag: authController.userProfileImage,
                  radius: 24.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAnalytics,
        child: Obx(() {
          if (_analyticsController.isBusy.value &&
              _analyticsController.totalSubscriptions == 0) {
            return const Center(child: LoadingIndicator());
          }

          if (_analyticsController.errorMessage.value != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    color: errorColor,
                    size: 48.0,
                  ),
                  const Gap(16.0),
                  Text(l10n.analyticsTab_loadingError, style: AppTextStyles.h3),
                  const Gap(8.0),
                  Text(
                    _analyticsController.errorMessage.value!,
                    style: AppTextStyles.body.copyWith(color: errorColor),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16.0),
                  ElevatedButton.icon(
                    onPressed: _refreshAnalytics,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 120.0),
            children: [
              // Quick Stats Grid with Trends
              _buildQuickStatsGrid(),

              // Subscription Status Overview
              Obx(
                () => _analyticsController.showGraphical.value
                    ? _buildSubscriptionStatusChart()
                    : _buildSubscriptionStatusSection(),
              ),
              const Gap(24.0),

              // Semester Analytics for Current Year
              _buildSemesterAnalyticsSection(),
              const Gap(24.0),

              // Distribution Charts
              Obx(
                () => _analyticsController.showGraphical.value
                    ? _buildDistributionCharts()
                    : _buildDistributionSection(),
              ),
              const Gap(24.0),

              // Recent Activity
              _buildRecentActivitySection(),
              const Gap(24.0),

              // Top Bus Stops
              Obx(
                () => _analyticsController.showGraphical.value
                    ? _buildTopBusStopsChart()
                    : _buildTopBusStopsSection(),
              ),
              const Gap(24.0),

              // Quick Actions
              _buildQuickActionsSection(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final data = _analyticsController.analyticsData.value;

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 1,
        children: [
          StatCard(
            title: _analyticsController.totalStudents > 1
                ? "${l10n.roleStudent}s"
                : l10n.roleStudent,
            value: '${_analyticsController.totalStudents}',
            icon: HugeIcons.strokeRoundedUserMultiple,
            color: infoColor,
            trend: _getTrendText(data.studentsWeeklyChange, l10n.week),
            subtitle:
                '${l10n.monthly}: ${_getTrendText(data.studentsMonthlyChange, '')}',
          ),
          StatCard(
            title: _analyticsController.totalSubscriptions > 1
                ? "${l10n.subscriptions}"
                : l10n.subscriptions.substring(
                    0,
                    l10n.subscriptions.length - 1,
                  ),
            value: '${_analyticsController.totalSubscriptions}',
            icon: HugeIcons.strokeRoundedTicket01,
            color: accentColor,
            trend: _getTrendText(data.subscriptionsWeeklyChange, l10n.week),
            subtitle:
                '${l10n.monthly}: ${_getTrendText(data.subscriptionsMonthlyChange, '')}',
            onTap: () {
              context.pushNamed(
                removeLeadingSlash(SubscriptionsAdminPage.routeName),
              );
            },
          ),
          StatCard(
            title: _analyticsController.totalSemesters > 1
                ? "${l10n.semester}s"
                : l10n.semester,
            value: '${_analyticsController.totalSemesters}',
            icon: HugeIcons.strokeRoundedCalendar02,
            color: successColor,
            onTap: () {
              context.pushNamed(
                removeLeadingSlash(SemesterManagementPage.routeName),
              );
            },
          ),
          StatCard(
            title: l10n.busStops,
            value: '${_analyticsController.totalBusStops}',
            icon: HugeIcons.strokeRoundedLocation06,
            color: warningColor,
            onTap: () {
              context.pushNamed(
                removeLeadingSlash(BusStopsManagementPage.routeName),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildSubscriptionStatusSection() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final pending = _analyticsController.pendingSubscriptions;
      final approved = _analyticsController.approvedSubscriptions;
      final rejected = _analyticsController.rejectedSubscriptions;
      final expired = _analyticsController.expiredSubscriptions;
      final total = _analyticsController.totalSubscriptions;

      return AnalyticsCard(
        title: l10n.analyticsTab_subStatusSection_title,
        subtitle: l10n.analyticsTab_subStatusSection_subtitle,
        icon: HugeIcons.strokeRoundedAnalytics01,
        child: Column(
          children: [
            _AnimatedProgressBar(
              label: l10n.analyticsTab_subStatusSection_pendingReview,
              value: pending,
              total: total,
              color: infoColor,
            ),
            _AnimatedProgressBar(
              label: l10n.subscriptionApproved,
              value: approved,
              total: total,
              color: successColor,
            ),
            _AnimatedProgressBar(
              label: l10n.subscriptionRejected,
              value: rejected,
              total: total,
              color: errorColor,
            ),
            _AnimatedProgressBar(
              label: l10n.subscriptionExpired,
              value: expired,
              total: total,
              color: greyColor,
            ),
            const Gap(16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: infoColor.withValues(alpha: 0.1),
                borderRadius: borderRadius * 1.5,
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: infoColor,
                    size: 20.0,
                  ),
                  const Gap(8.0),
                  Expanded(
                    child: Text(
                      '${l10n.analyticsTab_subStatusSection_approvalRate} ${_analyticsController.approvalRate.toStringAsFixed(1)}%',
                      style: AppTextStyles.body.copyWith(
                        color: infoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSubscriptionStatusChart() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final pending = _analyticsController.pendingSubscriptions;
      final approved = _analyticsController.approvedSubscriptions;
      final rejected = _analyticsController.rejectedSubscriptions;
      final expired = _analyticsController.expiredSubscriptions;
      final total = _analyticsController.totalSubscriptions;

      if (total == 0) {
        return AnalyticsCard(
          title: l10n.analyticsTab_subStatusSection_title,
          subtitle: l10n.analyticsTab_subStatusSection_subtitle,
          icon: HugeIcons.strokeRoundedAnalytics01,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                l10n.analyticsTab_emptyData,
                style: AppTextStyles.body.copyWith(color: greyColor),
              ),
            ),
          ),
        );
      }

      return AnalyticsCard(
        title: l10n.analyticsTab_subStatusSection_title,
        subtitle: l10n.analyticsTab_subStatusSection_subtitle,
        icon: HugeIcons.strokeRoundedAnalytics01,
        child: Column(
          children: [
            SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        if (pending > 0)
                          PieChartSectionData(
                            value: pending.toDouble(),
                            title:
                                '${((pending / total) * 100).toStringAsFixed(0)}%',
                            color: infoColor,
                            radius: 50,
                            titleStyle: AppTextStyles.small.copyWith(
                              color: lightColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (approved > 0)
                          PieChartSectionData(
                            value: approved.toDouble(),
                            title:
                                '${((approved / total) * 100).toStringAsFixed(0)}%',
                            color: successColor,
                            radius: 50,
                            titleStyle: AppTextStyles.small.copyWith(
                              color: lightColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (rejected > 0)
                          PieChartSectionData(
                            value: rejected.toDouble(),
                            title:
                                '${((rejected / total) * 100).toStringAsFixed(0)}%',
                            color: errorColor,
                            radius: 50,
                            titleStyle: AppTextStyles.small.copyWith(
                              color: lightColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (expired > 0)
                          PieChartSectionData(
                            value: expired.toDouble(),
                            title:
                                '${((expired / total) * 100).toStringAsFixed(0)}%',
                            color: greyColor,
                            radius: 50,
                            titleStyle: AppTextStyles.small.copyWith(
                              color: lightColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeInOutCubic,
                ),
            const Gap(16.0),
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _ChartLegendItem(
                  color: infoColor,
                  label: l10n.subscriptionPending,
                  value: pending.toString(),
                ),
                _ChartLegendItem(
                  color: successColor,
                  label: l10n.subscriptionApproved,
                  value: approved.toString(),
                ),
                _ChartLegendItem(
                  color: errorColor,
                  label: l10n.subscriptionRejected,
                  value: rejected.toString(),
                ),
                _ChartLegendItem(
                  color: greyColor,
                  label: l10n.subscriptionExpired,
                  value: expired.toString(),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSemesterAnalyticsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final semesterAnalytics =
          _analyticsController.analyticsData.value.semesterAnalytics;
      final currentYear = DateTime.now().year;

      if (semesterAnalytics.isEmpty) {
        return AnalyticsCard(
          title: l10n.analyticsTab_semesterSection_title,
          subtitle: l10n.analyticsTab_semesterSection_subtitle,
          icon: HugeIcons.strokeRoundedCalendar04,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${l10n.analyticsTab_semesterSection_empty} $currentYear',
                style: AppTextStyles.body.copyWith(color: greyColor),
              ),
            ),
          ),
        );
      }

      return AnalyticsCard(
        title: l10n.analyticsTab_semesterSection_title,
        subtitle: l10n.analyticsTab_semesterSection_subtitle,
        icon: HugeIcons.strokeRoundedCalendar04,
        child: Column(
          children: semesterAnalytics.entries.map((entry) {
            final semester = entry.key;
            final data = entry.value;
            final total = data['total'] as int;
            final pending = data['pending'] as int;
            final approved = data['approved'] as int;
            final rejected = data['rejected'] as int;
            final year = data['year'] as int?;
            final startDate = data['startDate'] as DateTime?;
            final endDate = data['endDate'] as DateTime?;

            // Format date range
            String dateRange = '';
            if (startDate != null && endDate != null) {
              final startFormatted = '${_getMonthAbbreviation(startDate.month)} ${startDate.year}';
              final endFormatted = '${_getMonthAbbreviation(endDate.month)} ${endDate.year}';
              dateRange = '$startFormatted - $endFormatted';
            } else if (year != null) {
              dateRange = year.toString();
            }

            return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: themeController.isDark
                        ? darkColor.withValues(alpha: 0.3)
                        : lightColor.withValues(alpha: 0.5),
                    borderRadius: borderRadius * 1.5,
                    border: Border.all(
                      color: _getSemesterColor(semester).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: _getSemesterColor(
                                semester,
                              ).withValues(alpha: 0.15),
                              borderRadius: borderRadius,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar02,
                              color: _getSemesterColor(semester),
                              size: 20.0,
                            ),
                          ),
                          const Gap(12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  semester.toUpperCase(),
                                  style: AppTextStyles.h3.copyWith(
                                    color: _getSemesterColor(semester),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (dateRange.isNotEmpty)
                                  Text(
                                    dateRange,
                                    style: AppTextStyles.small.copyWith(
                                      color: greyColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  'Total: $total subscriptions',
                                  style: AppTextStyles.small,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(
                            label: l10n.subscriptionPending,
                            value: pending.toString(),
                            color: infoColor,
                          ),
                          _MiniStat(
                            label: l10n.subscriptionApproved,
                            value: approved.toString(),
                            color: successColor,
                          ),
                          _MiniStat(
                            label: l10n.subscriptionRejected,
                            value: rejected.toString(),
                            color: errorColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.1, end: 0, delay: 100.ms);
          }).toList(),
        ),
      );
    });
  }

  /// Helper method to get month abbreviation
  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }

  Widget _buildDistributionSection() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final bySemester =
          _analyticsController.analyticsData.value.subscriptionsBySemester;
      final byYear =
          _analyticsController.analyticsData.value.subscriptionsByYear;

      return Column(
        children: [
          AnalyticsCard(
            title: l10n.analyticsTab_semesterSection_chartTitle,
            icon: HugeIcons.strokeRoundedCalendar02,
            child: bySemester.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.analyticsTab_emptyData,
                        style: AppTextStyles.body.copyWith(color: greyColor),
                      ),
                    ),
                  )
                : Column(
                    children: bySemester.entries.map((entry) {
                      final semester = entry.key;
                      final count = entry.value;
                      final color = _getSemesterColor(semester);

                      return InfoRow(
                        label: semester.toUpperCase(),
                        value: count.toString(),
                        icon: HugeIcons.strokeRoundedCalendar02,
                        color: color,
                      );
                    }).toList(),
                  ),
          ),
          const Gap(16.0),
          AnalyticsCard(
            title: l10n.analyticsTab_subByYear_title,
            icon: HugeIcons.strokeRoundedCalendarSetting01,
            child: byYear.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.analyticsTab_emptyData,
                        style: AppTextStyles.body.copyWith(color: greyColor),
                      ),
                    ),
                  )
                : Column(
                    children: byYear.entries.map((entry) {
                      final year = entry.key;
                      final count = entry.value;

                      return InfoRow(
                        label: year.toString(),
                        value: count.toString(),
                        icon: HugeIcons.strokeRoundedCalendar01,
                        color: accentColor,
                      );
                    }).toList(),
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildDistributionCharts() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final bySemester =
          _analyticsController.analyticsData.value.subscriptionsBySemester;
      final byYear =
          _analyticsController.analyticsData.value.subscriptionsByYear;

      return Column(
        children: [
          if (bySemester.isNotEmpty)
            AnalyticsCard(
              title: l10n.analyticsTab_semesterSection_chartTitle,
              icon: HugeIcons.strokeRoundedCalendar02,
              child: SizedBox(
                height: 200,
                child:
                    BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                bySemester.values
                                    .reduce((a, b) => a > b ? a : b)
                                    .toDouble() *
                                1.2,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < bySemester.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          bySemester.keys
                                              .elementAt(index)
                                              .substring(0, 3)
                                              .toUpperCase(),
                                          style: AppTextStyles.small,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40.0,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: AppTextStyles.small,
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: bySemester.entries.map((entry) {
                              final index = bySemester.keys.toList().indexOf(
                                entry.key,
                              );
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    color: _getSemesterColor(entry.key),
                                    width: 20,
                                    borderRadius: borderRadius * 4.0,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 800.ms,
                          curve: Curves.easeInOutCubic,
                        ),
              ),
            ),
          const Gap(16.0),
          if (byYear.isNotEmpty)
            AnalyticsCard(
              title: l10n.analyticsTab_subByYear_title,
              icon: HugeIcons.strokeRoundedCalendarSetting01,
              child: SizedBox(
                height: 200,
                child:
                    BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                byYear.values
                                    .reduce((a, b) => a > b ? a : b)
                                    .toDouble() *
                                1.2,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < byYear.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          byYear.keys
                                              .elementAt(index)
                                              .toString(),
                                          style: AppTextStyles.small,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: AppTextStyles.small,
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: byYear.entries.map((entry) {
                              final index = byYear.keys.toList().indexOf(
                                entry.key,
                              );
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    color: accentColor,
                                    width: 24,
                                    borderRadius: borderRadius * 4.0,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 800.ms,
                          curve: Curves.easeInOutCubic,
                        ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildRecentActivitySection() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final recentSubscriptions =
          _analyticsController.analyticsData.value.recentSubscriptions;

      return AnalyticsCard(
        title: l10n.analyticsTab_recentActivitySection_title,
        subtitle: l10n.analyticsTab_recentActivitySection_subtitle,
        icon: HugeIcons.strokeRoundedClock01,
        action: TextButton(
          onPressed: () {
            context.pushNamed(
              removeLeadingSlash(SubscriptionsAdminPage.routeName),
            );
          },
          child: Row(
            spacing: 4.0,
            children: [
              Text(l10n.viewAll, style: AppTextStyles.body),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowUpRight01, size: 20.0),
            ],
          ),
        ),
        child: recentSubscriptions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.analyticsTab_recentActivitySection_noData,
                    style: AppTextStyles.body.copyWith(color: greyColor),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentSubscriptions.take(5).length,
                separatorBuilder: (context, index) =>
                    const Divider(thickness: 0),
                itemBuilder: (context, index) {
                  final subscription = recentSubscriptions[index];
                  final status = subscription['status'] as String?;
                  final semester = subscription['semester'] as String?;
                  final year = subscription['year'] as int?;
                  final createdAt = subscription['createdAt'];

                  DateTime? date;
                  if (createdAt != null) {
                    if (createdAt is Timestamp) {
                      date = createdAt.toDate();
                    }
                  }

                  String _getSubscriptionDisplayLabel(String? status) {
                    switch (status?.toLowerCase()) {
                      case 'pending':
                        return l10n.subscriptionPending;
                      case 'approved':
                        return l10n.subscriptionApproved;
                      case 'rejected':
                        return l10n.subscriptionRejected;
                      case 'expired':
                        return l10n.subscriptionExpired;
                      default:
                        return l10n.naLabel;
                    }
                  }

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          status ?? '',
                        ).withValues(alpha: 0.15),
                        borderRadius: borderRadius,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTicket01,
                        color: _getStatusColor(status ?? ''),
                        size: 20.0,
                      ),
                    ),
                    title: Text(
                      '${semester?.toUpperCase() ?? l10n.naLabel} $year',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      date != null ? dateFormatter(date) : l10n.naLabel,
                      style: AppTextStyles.small,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          status ?? '',
                        ).withValues(alpha: 0.15),
                        borderRadius: borderRadius,
                      ),
                      child: Text(
                        _getSubscriptionDisplayLabel(status).toUpperCase(),
                        style: AppTextStyles.small.copyWith(
                          color: _getStatusColor(status ?? ''),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _buildTopBusStopsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final topStops = _analyticsController.analyticsData.value.topBusStops;

      return AnalyticsCard(
        title: l10n.analyticsTab_topBusStopsSection_title,
        subtitle: l10n.analyticsTab_topBusStopsSection_subtitle,
        icon: HugeIcons.strokeRoundedLocation03,
        action: TextButton(
          onPressed: () {
            context.pushNamed(
              removeLeadingSlash(BusStopsManagementPage.routeName),
            );
          },
          child: Row(
            spacing: 4.0,
            children: [
              Text(
                l10n.analyticsTab_topBusStopsSection_ctaLabel,
                style: AppTextStyles.body,
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowUpRight01, size: 20.0),
            ],
          ),
        ),
        child: topStops.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.analyticsTab_topBusStopsSection_noData,
                    style: AppTextStyles.body.copyWith(color: greyColor),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topStops.length,
                separatorBuilder: (context, index) => const Gap(8.0),
                itemBuilder: (context, index) {
                  final stop = topStops[index];
                  final name = stop['name'] as String;
                  final count = stop['count'] as int;
                  final rank = index + 1;

                  return Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: themeController.isDark
                              ? darkColor.withValues(alpha: 0.3)
                              : lightColor.withValues(alpha: 0.5),
                          borderRadius: borderRadius * 1.5,
                          border: Border.all(
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.1)
                                : darkColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getRankColor(
                                  rank,
                                ).withValues(alpha: 0.15),
                                borderRadius: borderRadius,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '#$rank',
                                style: AppTextStyles.body.copyWith(
                                  color: _getRankColor(rank),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Gap(12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$count ${l10n.subscriptions.replaceFirst(l10n.subscriptions[0], l10n.subscriptions[0].toLowerCase())}',
                                    style: AppTextStyles.small.copyWith(
                                      color: themeController.isDark
                                          ? lightColor.withValues(alpha: 0.6)
                                          : darkColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation06,
                              color: _getRankColor(rank),
                              size: 20.0,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.2, end: 0, delay: (index * 100).ms);
                },
              ),
      );
    });
  }

  Widget _buildTopBusStopsChart() {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final topStops = _analyticsController.analyticsData.value.topBusStops;

      if (topStops.isEmpty) {
        return AnalyticsCard(
          title: l10n.analyticsTab_topBusStopsSection_title,
          subtitle: l10n.analyticsTab_topBusStopsSection_subtitle,
          icon: HugeIcons.strokeRoundedLocation03,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                l10n.analyticsTab_topBusStopsSection_noData,
                style: AppTextStyles.body.copyWith(color: greyColor),
              ),
            ),
          ),
        );
      }

      return AnalyticsCard(
        title: l10n.analyticsTab_topBusStopsSection_title,
        subtitle: l10n.analyticsTab_topBusStopsSection_subtitle,
        icon: HugeIcons.strokeRoundedLocation03,
        action: TextButton(
          onPressed: () {
            context.pushNamed(
              removeLeadingSlash(BusStopsManagementPage.routeName),
            );
          },
          child: Row(
            spacing: 4.0,
            children: [
              Text(
                l10n.analyticsTab_topBusStopsSection_ctaLabel,
                style: AppTextStyles.body,
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowUpRight01, size: 20.0),
            ],
          ),
        ),
        child: SizedBox(
          height: 250.0,
          child:
              BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: topStops.first['count'].toDouble() * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < topStops.length) {
                                final name = topStops[index]['name'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    name.length > 8
                                        ? '${name.substring(0, 8)}...'
                                        : name,
                                    style: AppTextStyles.small,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: AppTextStyles.small,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: topStops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (stop['count'] as int).toDouble(),
                              color: _getRankColor(index + 1),
                              width: 24,
                              borderRadius: borderRadius * 4.0,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeInOutCubic,
                  ),
        ),
      );
    });
  }

  Widget _buildQuickActionsSection() {
    final l10n = AppLocalizations.of(context)!;
    return AnalyticsCard(
      title: l10n.analyticsTab_quickActionsSection_title,
      subtitle: l10n.analyticsTab_quickActionsSection_subtitle,
      icon: HugeIcons.strokeRoundedDashboardSpeed02,
      child: Column(
        children: [
          _QuickActionTile(
            icon: HugeIcons.strokeRoundedTicket02,
            title: l10n.analyticsTab_quickActionsSection_subscriptions,
            subtitle:
                l10n.analyticsTab_quickActionsSection_subscriptionsSubtitle,
            color: infoColor,
            onTap: () {
              context.pushNamed(
                removeLeadingSlash(SubscriptionsAdminPage.routeName),
              );
            },
          ),
          const Gap(8.0),
          _QuickActionTile(
            icon: HugeIcons.strokeRoundedLocation04,
            title: l10n.analyticsTab_quickActionsSection_busStops,
            subtitle: l10n.analyticsTab_quickActionsSection_busStopsSubtitle,
            color: accentColor,
            onTap: () {
              context.pushNamed(
                removeLeadingSlash(BusStopsManagementPage.routeName),
              );
            },
          ),
          const Gap(8.0),
          _QuickActionTile(
            icon: HugeIcons.strokeRoundedCalendar04,
            title: l10n.analyticsTab_quickActionsSection_semesters,
            subtitle: l10n.analyticsTab_quickActionsSection_semestersSubtitle,
            color: successColor,
            onTap: () {
              context.pushNamed(
                removeLeadingSlash(SemesterManagementPage.routeName),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return infoColor;
      case 'approved':
        return successColor;
      case 'rejected':
        return errorColor;
      case 'expired':
        return greyColor;
      default:
        return greyColor;
    }
  }

  Color _getSemesterColor(String semester) {
    switch (semester.toLowerCase()) {
      case 'fall':
        return warningColor;
      case 'spring':
        return successColor;
      case 'summer':
        return infoColor;
      default:
        return accentColor;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return accentColor;
    }
  }
}

// Custom animated progress bar widget
class _AnimatedProgressBar extends StatefulWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _AnimatedProgressBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final percentage = widget.total > 0 ? (widget.value / widget.total) : 0.0;
    _animation = Tween<double>(begin: 0.0, end: percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.total != widget.total) {
      final percentage = widget.total > 0 ? (widget.value / widget.total) : 0.0;
      _animation = Tween<double>(begin: _animation.value, end: percentage)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.body.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.8)
                      : darkColor.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${widget.value} / ${widget.total}',
                style: AppTextStyles.small.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.6)
                      : darkColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: borderRadius,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _animation.value,
                  minHeight: 8.0,
                  borderRadius: borderRadius,
                  trackGap: 4.0,
                  backgroundColor: widget.color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius * 1.5,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: borderRadius * 1.5,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: borderRadius,
                    ),
                    child: HugeIcon(icon: icon, color: color, size: 20.0),
                  ),
                  const Gap(12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.small.copyWith(
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.6)
                                : darkColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: color,
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, duration: 400.ms);
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius * 0.5,
          ),
        ),
        const Gap(6.0),
        Text(
          '$label: $value',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            color: themeController.isDark
                ? lightColor.withValues(alpha: 0.7)
                : darkColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
