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

/// Page where **students** view their submitted reports and create new ones.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  static const String routeName = '/reports';

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportController _reportController = Get.find<ReportController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final langCode = localeController.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(langCode == 'en' ? 'My Reports' : 'Mes Rapports'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewReportSheet(context),
        backgroundColor: accentColor,
        foregroundColor: lightColor,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: lightColor,
          size: 20,
        ),
        label: Text(
          langCode == 'en' ? 'New Report' : 'Nouveau Rapport',
          style: AppTextStyles.body.copyWith(
            color: lightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        final reports = _reportController.reports;

        if (reports.isEmpty) {
          return _buildEmptyState(langCode);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return _ReportCard(report: report, langCode: langCode)
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: (50 * index).ms,
                  curve: Curves.easeOut,
                )
                .slideY(
                  begin: 0.04,
                  end: 0,
                  duration: 350.ms,
                  delay: (50 * index).ms,
                  curve: Curves.easeOut,
                );
          },
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
                  icon: HugeIcons.strokeRoundedFileValidation,
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.2)
                      : darkColor.withValues(alpha: 0.2),
                  size: 80,
                ),
                const Gap(16),
                Text(
                  langCode == 'en'
                      ? 'No reports yet'
                      : 'Aucun rapport pour le moment',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                Text(
                  langCode == 'en'
                      ? 'Submit a report to share your concerns about the bus service.'
                      : 'Soumettez un rapport pour partager vos préoccupations sur le service de bus.',
                  style: AppTextStyles.body.copyWith(
                    color: themeController.isDark
                        ? lightColor.withValues(alpha: 0.6)
                        : darkColor.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 500.ms,
        );
  }

  void _showNewReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewReportSheet(
        authController: _authController,
        reportController: _reportController,
      ),
    );
  }
}

// ─── Report card ─────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.langCode});

  final Report report;
  final String langCode;

  Color get _statusColor {
    switch (report.status) {
      case ReportStatus.pending:
        return warningColor;
      case ReportStatus.inReview:
        return infoColor;
      case ReportStatus.resolved:
        return successColor;
    }
  }

  List<List<dynamic>> get _statusIcon {
    switch (report.status) {
      case ReportStatus.pending:
        return HugeIcons.strokeRoundedClock03;
      case ReportStatus.inReview:
        return HugeIcons.strokeRoundedSearch01;
      case ReportStatus.resolved:
        return HugeIcons.strokeRoundedCheckmarkCircle02;
    }
  }

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedPalette.shade900
            : seedPalette.shade50,
        borderRadius: borderRadius * 2,
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: subject + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  report.displayTitle(langCode),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(8),
              _StatusBadge(
                label: report.status.label(langCode),
                color: _statusColor,
                icon: _statusIcon,
              ),
            ],
          ),
          const Gap(8),

          // Description
          Text(
            report.description,
            style: AppTextStyles.body.copyWith(
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.7)
                  : darkColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(12),

          // Footer: priority + date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: borderRadius,
                ),
                child: Text(
                  report.priority.label(langCode),
                  style: AppTextStyles.small.copyWith(
                    color: _priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateTimeFormatter(report.createdAt),
                style: AppTextStyles.small.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.5)
                      : darkColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Admin response (if resolved)
          if (report.status.isResolved && report.adminResponse != null) ...[
            const Gap(12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.08),
                borderRadius: borderRadius * 1.5,
                border: Border.all(color: successColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedMessage01,
                        color: successColor,
                        size: 14,
                      ),
                      const Gap(6),
                      Text(
                        langCode == 'en'
                            ? 'Admin Response'
                            : 'Réponse de l\'admin',
                        style: AppTextStyles.small.copyWith(
                          color: successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    report.adminResponse!,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                  if (report.resolvedByAdminName != null) ...[
                    const Gap(4),
                    Text(
                      '— ${report.resolvedByAdminName}',
                      style: AppTextStyles.small.copyWith(
                        fontStyle: FontStyle.italic,
                        color: themeController.isDark
                            ? lightColor.withValues(alpha: 0.5)
                            : darkColor.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Status badge ────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 12),
          const Gap(4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Report Bottom Sheet ─────────────────────────────────────────

class _NewReportSheet extends StatefulWidget {
  const _NewReportSheet({
    required this.authController,
    required this.reportController,
  });

  final AuthController authController;
  final ReportController reportController;

  @override
  State<_NewReportSheet> createState() => _NewReportSheetState();
}

class _NewReportSheetState extends State<_NewReportSheet> {
  final _descriptionController = TextEditingController();
  final _customSubjectController = TextEditingController();
  ReportSubject _selectedSubject = ReportSubject.scheduleDelay;

  @override
  void dispose() {
    _descriptionController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    HapticFeedback.mediumImpact();
    await widget.reportController.submitReport(
      studentId: widget.authController.userId,
      studentName: widget.authController.userDisplayName,
      studentPhotoUrl: widget.authController.userProfileImage,
      subject: _selectedSubject,
      customSubject: _selectedSubject == ReportSubject.other
          ? _customSubjectController.text.trim()
          : null,
      description: description,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final langCode = localeController.locale.languageCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          clipBehavior: Clip.none,
          children: [
            // Drag handle
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
                gradient: themeController.isDark ? darkGradient : lightGradient,
                borderRadius: borderRadius * 3.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    langCode == 'en'
                        ? 'Submit a Report'
                        : 'Soumettre un Rapport',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    langCode == 'en'
                        ? 'Tell us about any concern regarding the bus service.'
                        : 'Parlez-nous de toute préoccupation concernant le service de bus.',
                    style: AppTextStyles.body.copyWith(
                      color: themeController.isDark
                          ? lightColor.withValues(alpha: 0.6)
                          : darkColor.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const Gap(20),

                  // Subject selector
                  Text(
                    langCode == 'en' ? 'Subject' : 'Sujet',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReportSubject.values.map((subject) {
                      final isSelected = _selectedSubject == subject;
                      return ChoiceChip(
                        label: Text(
                          subject.label(langCode),
                          style: AppTextStyles.small.copyWith(
                            color: isSelected
                                ? Colors.white
                                : themeController.isDark
                                ? lightColor
                                : seedColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSubject = subject);
                        },
                        selectedColor: accentColor,
                        backgroundColor: themeController.isDark
                            ? seedColor.withValues(alpha: 0.5)
                            : seedPalette.shade50,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: borderRadius * 2,
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      );
                    }).toList(),
                  ),

                  // Custom subject field (only for "Other")
                  if (_selectedSubject == ReportSubject.other) ...[
                    const Gap(16),
                    TextField(
                      controller: _customSubjectController,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: langCode == 'en'
                            ? 'Custom subject title...'
                            : 'Titre du sujet personnalisé...',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: greyColor,
                        ),
                        border: AppInputBorders.border,
                        enabledBorder: AppInputBorders.enabledBorder,
                        focusedBorder: AppInputBorders.focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                  const Gap(16),

                  // Description field
                  Text(
                    langCode == 'en' ? 'Description' : 'Description',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 5,
                    minLines: 3,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: _selectedSubject.hintText(langCode),
                      hintStyle: AppTextStyles.body.copyWith(color: greyColor),
                      border: AppInputBorders.border,
                      enabledBorder: AppInputBorders.enabledBorder,
                      focusedBorder: AppInputBorders.focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const Gap(8),

                  // Priority info
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        size: 14,
                        color: themeController.isDark
                            ? lightColor.withValues(alpha: 0.4)
                            : darkColor.withValues(alpha: 0.4),
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          langCode == 'en'
                              ? 'Priority: ${_selectedSubject.defaultPriority.labelEn}'
                              : 'Priorité : ${_selectedSubject.defaultPriority.labelFr}',
                          style: AppTextStyles.small.copyWith(
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.4)
                                : darkColor.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Submit button
                  Obx(() {
                    final isBusy = widget.reportController.isBusy.value;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isBusy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: lightColor,
                          disabledBackgroundColor: accentColor.withValues(
                            alpha: 0.4,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: borderRadius * 2,
                          ),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: lightColor,
                                ),
                              )
                            : Text(
                                langCode == 'en' ? 'Submit' : 'Soumettre',
                                style: AppTextStyles.body.copyWith(
                                  color: lightColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
