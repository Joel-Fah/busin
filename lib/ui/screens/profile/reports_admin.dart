import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/report_controller.dart';
import 'package:busin/models/report.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Admin page to view, triage, and resolve student reports.
class ReportsAdminPage extends StatefulWidget {
  const ReportsAdminPage({super.key});

  static const String routeName = '/reports_admin';

  @override
  State<ReportsAdminPage> createState() => _ReportsAdminPageState();
}

class _ReportsAdminPageState extends State<ReportsAdminPage>
    with SingleTickerProviderStateMixin {
  final ReportController _reportController = Get.find<ReportController>();
  final AuthController _authController = Get.find<AuthController>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = localeController.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langCode == 'en' ? 'Student Reports' : 'Rapports Étudiants',
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: SizedBox(
            height: 56,
            child: TabBar(
              controller: _tabController,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: greyColor,
              tabs: [
                Tab(
                  child: Obx(() {
                    final count = _reportController.reports
                        .where((r) => r.status.isPending)
                        .length;
                    return _TabLabel(
                      label: langCode == 'en' ? 'Pending' : 'En attente',
                      count: count,
                      color: warningColor,
                    );
                  }),
                ),
                Tab(
                  child: Obx(() {
                    final count = _reportController.reports
                        .where((r) => r.status.isInReview)
                        .length;
                    return _TabLabel(
                      label: langCode == 'en' ? 'In Review' : 'En cours',
                      count: count,
                      color: infoColor,
                    );
                  }),
                ),
                Tab(
                  child: Text(
                    langCode == 'en' ? 'Resolved' : 'Résolus',
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsList(
            filter: (r) => r.status.isPending,
            emptyMessage: langCode == 'en'
                ? 'No pending reports'
                : 'Aucun rapport en attente',
            langCode: langCode,
            authController: _authController,
            reportController: _reportController,
          ),
          _ReportsList(
            filter: (r) => r.status.isInReview,
            emptyMessage: langCode == 'en'
                ? 'No reports in review'
                : 'Aucun rapport en cours',
            langCode: langCode,
            authController: _authController,
            reportController: _reportController,
          ),
          _ReportsList(
            filter: (r) => r.status.isResolved,
            emptyMessage: langCode == 'en'
                ? 'No resolved reports'
                : 'Aucun rapport résolu',
            langCode: langCode,
            authController: _authController,
            reportController: _reportController,
          ),
        ],
      ),
    );
  }
}

// ─── Tab label with count badge ──────────────────────────────────────

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(fontSize: 14)),
        if (count > 0) ...[
          const Gap(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: borderRadius),
            child: Text(
              count.toString(),
              style: AppTextStyles.small.copyWith(
                color: lightColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Filtered list of reports ────────────────────────────────────────

class _ReportsList extends StatelessWidget {
  const _ReportsList({
    required this.filter,
    required this.emptyMessage,
    required this.langCode,
    required this.authController,
    required this.reportController,
  });

  final bool Function(Report) filter;
  final String emptyMessage;
  final String langCode;
  final AuthController authController;
  final ReportController reportController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filtered = reportController.reports.where(filter).toList();

      if (filtered.isEmpty) {
        return Center(
          child: Text(
            emptyMessage,
            style: AppTextStyles.body.copyWith(color: greyColor),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (context, index) {
          final report = filtered[index];
          return _AdminReportCard(
                report: report,
                langCode: langCode,
                authController: authController,
                reportController: reportController,
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: (40 * index).ms,
                curve: Curves.easeOut,
              )
              .slideY(
                begin: 0.04,
                end: 0,
                duration: 350.ms,
                delay: (40 * index).ms,
                curve: Curves.easeOut,
              );
        },
      );
    });
  }
}

// ─── Admin Report Card ───────────────────────────────────────────────

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({
    required this.report,
    required this.langCode,
    required this.authController,
    required this.reportController,
  });

  final Report report;
  final String langCode;
  final AuthController authController;
  final ReportController reportController;

  Color get _priorityColor {
    switch (report.priority) {
      case ReportPriority.low:
        return successColor;
      case ReportPriority.medium:
        return infoColor;
      case ReportPriority.high:
        return warningColor;
      case ReportPriority.critical:
        return errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedPalette.shade900
            : seedPalette.shade50,
        borderRadius: borderRadius * 3.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info + priority badge
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    report.studentPhotoUrl != null &&
                        report.studentPhotoUrl!.isNotEmpty
                    ? NetworkImage(report.studentPhotoUrl!)
                    : null,
                child:
                    report.studentPhotoUrl == null ||
                        report.studentPhotoUrl!.isEmpty
                    ? Text(
                        report.studentName.isNotEmpty
                            ? report.studentName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.body.copyWith(
                          color: lightColor,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const Gap(10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.studentName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateTimeFormatter(report.createdAt),
                      style: AppTextStyles.small.copyWith(
                        color: greyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: _priorityColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  report.priority.label(langCode),
                  style: AppTextStyles.small.copyWith(
                    color: _priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12.0),

          // Subject
          Text(
            report.displayTitle(langCode),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8.0),

          // Description
          Text(
            report.description,
            style: AppTextStyles.body.copyWith(
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.7)
                  : darkColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(12.0),

          // Admin response (if resolved)
          if (report.status.isResolved && report.adminResponse != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.08),
                borderRadius: borderRadius * 1.5,
              ),
              child: Text(
                '${langCode == 'en' ? 'Response' : 'Réponse'}: ${report.adminResponse}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: successColor,
                ),
              ),
            ),
            const Gap(8),
          ],

          // Action buttons
          if (!report.status.isResolved)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (report.status.isPending)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      reportController.markInReview(report.id);
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: infoColor,
                      size: 16,
                    ),
                    label: Text(
                      langCode == 'en' ? 'Review' : 'Examiner',
                      style: AppTextStyles.small.copyWith(
                        color: infoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Gap(8),
                TextButton.icon(
                  onPressed: () => _showResolveDialog(context),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: successColor,
                    size: 16,
                  ),
                  label: Text(
                    langCode == 'en' ? 'Resolve' : 'Résoudre',
                    style: AppTextStyles.small.copyWith(
                      color: successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context) {
    final responseController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: ListView(
              shrinkWrap: true,
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: borderRadius * 2,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: themeController.isDark
                        ? darkGradient
                        : lightGradient,
                    borderRadius: borderRadius * 3.75,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langCode == 'en'
                            ? 'Resolve Report'
                            : 'Résoudre le Rapport',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${report.displayTitle(langCode)} — ${report.studentName}',
                        style: AppTextStyles.body.copyWith(
                          color: greyColor,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(16),
                      TextField(
                        controller: responseController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 2,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: langCode == 'en'
                              ? 'Add a response for the student (optional)...'
                              : 'Ajouter une réponse pour l\'étudiant (optionnel)...',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: greyColor,
                          ),
                          border: AppInputBorders.border,
                          enabledBorder: AppInputBorders.enabledBorder,
                          focusedBorder: AppInputBorders.focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const Gap(20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            reportController.resolveReport(
                              reportId: report.id,
                              adminId: authController.userId,
                              adminName: authController.userDisplayName,
                              response:
                                  responseController.text.trim().isNotEmpty
                                  ? responseController.text.trim()
                                  : null,
                            );
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successColor,
                            foregroundColor: lightColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius * 2,
                            ),
                          ),
                          child: Text(
                            langCode == 'en'
                                ? 'Mark as Resolved'
                                : 'Marquer comme Résolu',
                            style: AppTextStyles.body.copyWith(
                              color: lightColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
