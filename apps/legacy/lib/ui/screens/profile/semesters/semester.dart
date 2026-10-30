import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../controllers/semester_controller.dart';
import '../../../../models/semester_config.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/utils.dart';
import '../../../components/widgets/default_snack_bar.dart';
import '../../../components/widgets/loading_indicator.dart';
import 'semester_form.dart';

class SemesterManagementPage extends StatefulWidget {
  const SemesterManagementPage({super.key});

  static const String routeName = '/semester';

  @override
  State<SemesterManagementPage> createState() => _SemesterManagementPageState();
}

class _SemesterManagementPageState extends State<SemesterManagementPage> {
  final SemesterController _semesterController = Get.find<SemesterController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.contain,
          child: Text(l10n.semestersPage_appBar_title),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => _semesterController.fetchSemesters(),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
          ),
          if (authController.isAdmin)
            IconButton.filled(
              tooltip: l10n.semestersPage_appBar_actionsAdd,
              style: IconButton.styleFrom(backgroundColor: accentColor),
              onPressed: () => context.pushNamed(
                removeLeadingSlash(SemesterFormPage.routeName),
              ),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Obx(() {
            final active = _semesterController.activeSemester.value;
            if (active == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.1),
                  borderRadius: borderRadius * 2.5,
                  border: Border.all(color: successColor, width: 1.5),
                ),
                child: ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar02,
                    color: successColor,
                  ),
                  subtitle: Text(
                    l10n.semestersPage_appBar_activeSemester,
                    style: AppTextStyles.small.copyWith(color: successColor),
                  ),
                  title: Text(
                    '${active.semester.label} ${active.year}',
                    style: AppTextStyles.h3.copyWith(color: successColor),
                  ),
                  trailing: Text(
                    '${dateFormatter(active.startDate)} - ${dateFormatter(active.endDate)}',
                    style: AppTextStyles.body.copyWith(color: successColor),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _semesterController.fetchSemesters(),
        child: ListView(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: infoColor.withValues(alpha: 0.1),
                borderRadius: borderRadius * 2.5,
              ),
              child: Row(
                spacing: 8.0,
                children: [
                  HugeIcon(icon: infoIcon, color: infoColor),
                  Expanded(
                    child: Text(
                      l10n.semestersPage_infoBubble,
                      style: AppTextStyles.body.copyWith(color: infoColor),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16.0),

            // Stats section
            Obx(() {
              final total = _semesterController.semesters.length;
              final currentYear = DateTime.now().year;
              final thisYear = _semesterController.semesters
                  .where((s) => s.year == currentYear)
                  .length;
              final upcoming = _semesterController.semesters
                  .where((s) => s.startDate.isAfter(DateTime.now()))
                  .length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8.0,
                children: [
                  _StatItem(
                    icon: HugeIcons.strokeRoundedLayers01,
                    label: l10n.semestersPage_statItem_total,
                    value: total.toString(),
                    color: warningColor,
                  ),
                  _StatItem(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    label: currentYear.toString(),
                    value: thisYear.toString(),
                    color: successColor,
                  ),
                  _StatItem(
                    icon: HugeIcons.strokeRoundedForward02,
                    label: l10n.semestersPage_statItem_upcoming,
                    value: upcoming.toString(),
                    color: infoColor,
                  ),
                ],
              );
            }),
            const Gap(24.0),

            // Semesters list
            Obx(() {
              if (_semesterController.isLoading.value &&
                  _semesterController.semesters.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 36.0),
                    child: LoadingIndicator(),
                  ),
                );
              }

              if (_semesterController.error.value.isNotEmpty) {
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
                      Text(
                        l10n.semestersPage_loadingError,
                        style: AppTextStyles.h3,
                      ),
                      const Gap(8.0),
                      Text(
                        _semesterController.error.value,
                        style: AppTextStyles.body.copyWith(color: errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(16.0),
                      FilledButton.icon(
                        onPressed: () => _semesterController.fetchSemesters(),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                        ),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              if (_semesterController.semesters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 36.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedLayers01,
                          color: greyColor,
                          size: 48.0,
                        ),
                        const Gap(16.0),
                        Text(
                          l10n.semestersPage_emptyList_title,
                          style: AppTextStyles.h3,
                        ),
                        const Gap(4.0),
                        Text(
                          l10n.semestersPage_emptyList_subtitle,
                          style: AppTextStyles.body.copyWith(color: greyColor),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16.0),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius * 2.0,
                            ),
                          ),
                          onPressed: () => context.pushNamed(
                            removeLeadingSlash(SemesterFormPage.routeName),
                          ),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedAdd01,
                          ),
                          label: Text(
                            l10n.semestersPage_appBar_actionsAdd,
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _semesterController.semesters.length,
                separatorBuilder: (context, index) => const Gap(16.0),
                itemBuilder: (context, index) {
                  final semester = _semesterController.semesters[index];
                  return _SemesterCard(
                    semester: semester,
                    onEdit: () => _handleEdit(semester),
                    onDelete: () => _handleDelete(semester),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handleEdit(SemesterConfig semester) {
    context.pushNamed(
      removeLeadingSlash(SemesterFormPage.routeName),
      extra: semester,
    );
  }

  Future<void> _handleDelete(SemesterConfig semester) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showDeleteBottomSheet(semester);
    if (confirmed != true) return;

    final success = await _semesterController.deleteSemester(semester.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.check_circle, color: lightColor),
            label: Text(l10n.semestersPage_handleDelete_successful),
            backgroundColor: successColor,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text(
              _semesterController.error.value.isNotEmpty
                  ? _semesterController.error.value
                  : l10n.semestersPage_handleDelete_failed,
            ),
            backgroundColor: errorColor,
          ),
        );
    }
  }

  Future<bool?> _showDeleteBottomSheet(SemesterConfig semester) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<bool>(
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
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: borderRadius * 3,
                gradient: themeController.isDark ? darkGradient : lightGradient,
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
                              l10n.semestersPage_handleDelete_title,
                              style: AppTextStyles.h3,
                            ),
                            Text(
                              l10n.semestersPage_handleDelete_subtitle,
                              style: AppTextStyles.small.copyWith(
                                color: errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(24.0),

                  // Semester information
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
                              icon: HugeIcons.strokeRoundedCalendar02,
                              color: errorColor,
                              size: 20,
                            ),
                            const Gap(8.0),
                            Expanded(
                              child: Text(
                                '${semester.semester.label} ${semester.year}',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: errorColor,
                                ),
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
                          icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                          label: l10n.semestersPage_detailRow_startDate,
                          value: dateFormatter(semester.startDate),
                        ),
                        const Gap(8.0),
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedCalendarCheckOut01,
                          label: l10n.semestersPage_detailRow_endDate,
                          value: dateFormatter(semester.endDate),
                        ),
                        const Gap(8.0),
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedTimer02,
                          label: l10n.semestersPage_detailRow_duration,
                          value: '${semester.durationInDays} ${l10n.days}',
                        ),
                        const Gap(8.0),
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          label: l10n.status,
                          value: semester.isActive
                              ? l10n.semestersPage_detailRow_statusActive
                              : DateTime.now().isAfter(semester.endDate)
                              ? l10n.semestersPage_detailRow_statusEnded
                              : l10n.semestersPage_detailRow_statusUpcoming,
                          valueColor: semester.isActive
                              ? successColor
                              : DateTime.now().isAfter(semester.endDate)
                              ? lightColor.withValues(alpha: 0.5)
                              : infoColor,
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
                            l10n.semestersPage_deleteModal_warning,
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
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            side: BorderSide(
                              color: themeController.isDark
                                  ? seedPalette.shade100
                                  : seedColor,
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: AppTextStyles.body.copyWith(
                              color: themeController.isDark
                                  ? lightColor
                                  : seedColor,
                            ),
                          ),
                        ),
                      ),
                      const Gap(12.0),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: errorColor,
                            foregroundColor: lightColor,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            color: lightColor,
                          ),
                          label: Text(l10n.delete, style: AppTextStyles.body),
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
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: borderRadius * 1.5,
          ),
          child: HugeIcon(icon: icon, color: color),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
            Text(
              label,
              style: AppTextStyles.small.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final SemesterConfig semester;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SemesterCard({
    required this.semester,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = semester.isActive;
    final isPast = DateTime.now().isAfter(semester.endDate);

    Color statusColor;
    String statusLabel;
    List<List<dynamic>> statusIcon;

    if (isActive) {
      statusColor = successColor;
      statusLabel = l10n.semestersPage_detailRow_statusActive;
      statusIcon = HugeIcons.strokeRoundedCalendar02;
    } else if (isPast) {
      statusColor = Colors.transparent;
      statusLabel = l10n.semestersPage_detailRow_statusEnded;
      statusIcon = HugeIcons.strokeRoundedUnavailable;
    } else {
      statusColor = infoColor;
      statusLabel = l10n.semestersPage_detailRow_statusUpcoming;
      statusIcon = HugeIcons.strokeRoundedForward02;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? successColor
              : isPast
              ? greyColor
              : infoColor,
          width: isActive ? 2.0 : 1.0,
        ),
        borderRadius: borderRadius * 2.5,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ).copyWith(right: 0.0),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: (borderRadius * 2.5).topLeft,
                topRight: (borderRadius * 2.5).topRight,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: HugeIcon(icon: statusIcon, color: statusColor),
              title: Text(
                '${semester.semester.label} ${semester.year}',
                style: AppTextStyles.h3,
              ),
              subtitle: Text(
                statusLabel,
                style: AppTextStyles.small.copyWith(color: statusColor),
              ),
              trailing: authController.isAdmin
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.edit,
                          onPressed: onEdit,
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            color: themeController.isDark
                                ? seedPalette.shade100
                                : seedColor,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.delete,
                          onPressed: onDelete,
                          style: IconButton.styleFrom(
                            overlayColor: errorColor.withValues(alpha: 0.1),
                          ),
                          color: errorColor,
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoRow(
                  icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                  label: l10n.semestersPage_detailRow_startDate,
                  value: dateFormatter(semester.startDate),
                ),
                _InfoRow(
                  icon: HugeIcons.strokeRoundedCalendarCheckOut01,
                  label: l10n.semestersPage_detailRow_endDate,
                  value: dateFormatter(semester.endDate),
                ),
                _InfoRow(
                  icon: HugeIcons.strokeRoundedTimer02,
                  label: l10n.semestersPage_detailRow_duration,
                  value: '${semester.durationInDays} ${l10n.days}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final List<List<dynamic>> icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8.0,
      children: [
        HugeIcon(icon: icon, size: 20.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.small.copyWith(color: Colors.grey),
            ),
            Text(value, style: AppTextStyles.body),
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
          size: 20.0,
        ),
        const Gap(12.0),
        Text(label, style: AppTextStyles.body),
        const Spacer(),
        Text(value, style: AppTextStyles.body.copyWith(color: valueColor)),
      ],
    );
  }
}
