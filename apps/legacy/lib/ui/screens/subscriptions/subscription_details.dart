import 'dart:ui';

import 'package:busin/generated/assets.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:busin/utils/utils.dart';
import 'package:busin/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/subscriptions_controller.dart';
import '../../../models/actors/base_user.dart';
import '../../../models/subscription.dart';
import '../../../models/value_objects/bus_stop_selection.dart';
import '../../components/widgets/default_snack_bar.dart';
import '../../components/widgets/loading_indicator.dart';
import '../../components/widgets/metadata_section.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  static const String routeName = '/subscription-details';

  final String subscriptionId;

  const SubscriptionDetailsPage({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final BusSubscriptionsController busSubscriptionController =
        Get.find<BusSubscriptionsController>();
    final subscription = busSubscriptionController.getSubscriptionById(
      subscriptionId,
    );

    if (subscription == null) {
      return Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.contain,
            child: Text(l10n.subscriptionDetailPage_appBar_title),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: errorColor,
                size: 64,
              ),
              const Gap(16.0),
              Text(
                l10n.subscriptionDetailPage_nullContent_title,
                style: AppTextStyles.h3,
              ),
              const Gap(8.0),
              Text(
                l10n.subscriptionDetailPage_nullContent_message,
                style: AppTextStyles.body.copyWith(color: greyColor),
              ),
            ],
          ),
        ),
      );
    }

    return _SubscriptionDetailsContent(
      subscriptionId: subscriptionId,
      initialSubscription: subscription,
    );
  }
}

class _SubscriptionDetailsContent extends StatefulWidget {
  final String subscriptionId;
  final BusSubscription initialSubscription;

  const _SubscriptionDetailsContent({
    required this.subscriptionId,
    required this.initialSubscription,
  });

  @override
  State<_SubscriptionDetailsContent> createState() =>
      _SubscriptionDetailsContentState();
}

class _SubscriptionDetailsContentState
    extends State<_SubscriptionDetailsContent> {
  late BusSubscription subscription;
  final BusSubscriptionsController _controller =
      Get.find<BusSubscriptionsController>();
  final AuthController _authController = Get.find<AuthController>();
  final _fabKey = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    subscription = widget.initialSubscription;
  }

  Future<void> _handleRefresh() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final refreshedSubscription = await _controller.refreshSubscription(
        widget.subscriptionId,
      );
      if (refreshedSubscription != null && mounted) {
        setState(() {
          subscription = refreshedSubscription;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                '${l10n.subscriptionDetailPage_handleRefresh_error} ${e.toString()}',
              ),
              backgroundColor: errorColor,
            ),
          );
      }
    }
  }

  Future<void> _handleApprove(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Close the FAB first
    final state = _fabKey.currentState;
    if (state != null) {
      state.toggle();
    }

    try {
      await _controller.approveSubscription(
        subscriptionId: subscription.id,
        reviewerId: _authController.userId,
      );

      if (mounted) {
        // Refresh the subscription to get updated data
        await _handleRefresh();

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: successColor,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: lightColor,
              ),
              label: Text(l10n.subscriptionDetailPage_handleApprove_success),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: errorColor,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: lightColor,
              ),
              label: Text(
                '${l10n.subscriptionDetailPage_handleApprove_error} ${e.toString()}',
              ),
            ),
          );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Close the FAB first
    final state = _fabKey.currentState;
    if (state != null) {
      state.toggle();
    }

    // Show rejection reason dialog
    final reason = await _showRejectReasonDialog(context);
    if (reason == null || reason.isEmpty) {
      // User cancelled or didn't provide a reason
      return;
    }

    try {
      await _controller.rejectSubscription(
        subscriptionId: subscription.id,
        reviewerId: _authController.userId,
        reason: reason,
      );

      if (mounted) {
        // Refresh the subscription to get updated data
        await _handleRefresh();

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: warningColor,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancelCircle,
                color: lightColor,
              ),
              label: Text(l10n.subscriptionDetailPage_handleReject_success),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: errorColor,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: lightColor,
              ),
              label: Text(
                '${l10n.subscriptionDetailPage_handleReject_error} ${e.toString()}',
              ),
            ),
          );
      }
    }
  }

  Future<String?> _showRejectReasonDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController reasonController = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: themeController.isDark ? seedPalette.shade900 : lightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: greyColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCancelCircle,
                    color: errorColor,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      l10n.subscriptionDetailPage_rejectDialog_title,
                      style: AppTextStyles.h3,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Text(
                l10n.subscriptionDetailPage_rejectDialog_instruction,
                style: AppTextStyles.body.copyWith(
                  color: themeController.isDark
                      ? seedPalette.shade50.withValues(alpha: 0.5)
                      : greyColor,
                ),
              ),
              const Gap(20),
              SimpleTextFormField(
                controller: reasonController,
                autofocus: true,
                hintText: l10n.subscriptionDetailPage_rejectDialog_reasonLabel,
                label: Text(
                  l10n.subscriptionDetailPage_rejectDialog_reasonLabel,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.subscriptionDetailPage_rejectDialog_reasonValidatorEmpty;
                  }

                  // At least 10 characters
                  if (value.trim().length < 10) {
                    return l10n.subscriptionDetailPage_rejectDialog_reasonValidatorLength;
                  }
                  return null;
                },
              ),
              const Gap(20),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        overlayColor: greyColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final reason = reasonController.text.trim();
                        if (reason.isNotEmpty) {
                          context.pop(reason);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        foregroundColor: lightColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.subscriptionDetailPage_rejectDialog_ctaReject,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(subscription.status);
    final statusLabel = _getStatusLabel(subscription.status);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // Image with SliverAppBar - Dynamic title behavior
            SliverAppBar(
              expandedHeight: 500,
              pinned: true,
              stretch: true,
              toolbarHeight: 80.0,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final top = constraints.biggest.height;
                  final isExpanded = top > kToolbarHeight + 70;

                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    title: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isExpanded ? 0.0 : 1.0,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          left: 56.0,
                          right: 16.0,
                          top: 40.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                subscription.semesterYear,
                                style: Theme.of(
                                  context,
                                ).appBarTheme.titleTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: borderRadius,
                              ),
                              child: Text(
                                statusLabel,
                                style: AppTextStyles.small.copyWith(
                                  color: lightColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _showFullScreenImage(context, subscription),
                          child: Hero(
                            tag: subscription.id,
                            child: subscription.hasProof
                                ? CachedNetworkImage(
                                    imageUrl: subscription.proofOfPaymentUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: themeController.isDark
                                          ? seedPalette.shade900
                                          : seedPalette.shade50,
                                      child: Center(
                                        child: SvgPicture.asset(
                                          themeController.isDark
                                              ? Assets.logoWhite
                                              : Assets.logoCyan,
                                          width: 80.0,
                                          height: 80.0,
                                          colorFilter: ColorFilter.mode(
                                            themeController.isDark
                                                ? lightColor
                                                : darkColor,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildImagePlaceholder(colorScheme),
                                  )
                                : _buildImagePlaceholder(colorScheme),
                          ),
                        ),
                        // Gradient overlay
                        IgnorePointer(
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  seedColor.withValues(alpha: 0.95),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Large title at bottom when expanded
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isExpanded ? 1.0 : 0.0,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: borderRadius * 1.75,
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: AppTextStyles.body.copyWith(
                                        color: lightColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    subscription.semesterYear,
                                    style: AppTextStyles.title.copyWith(
                                      color: lightColor,
                                      fontSize: 72.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons (Apple style)
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: _ActionButton(
                  //           icon: HugeIcons.strokeRoundedEdit02,
                  //           label: 'Edit',
                  //           onTap: () {
                  //             // TODO: Navigate to edit page
                  //           },
                  //         ),
                  //       ),
                  //       const Gap(8.0),
                  //       Expanded(
                  //         child: _ActionButton(
                  //           icon: subscription.isCurrentlyActive
                  //               ? HugeIcons.strokeRoundedPauseCircle
                  //               : HugeIcons.strokeRoundedPlayCircle,
                  //           label: subscription.isCurrentlyActive
                  //               ? 'Pause'
                  //               : 'Activate',
                  //           onTap: () {
                  //             // TODO: Handle activation
                  //           },
                  //         ),
                  //       ),
                  //       const Gap(8.0),
                  //       Expanded(
                  //         child: _ActionButton(
                  //           foregroundColor: themeController.isDark ? lightColor : seedColor,
                  //           gradient: LinearGradient(
                  //             begin: Alignment.bottomRight,
                  //             end: Alignment.topLeft,
                  //             colors: themeController.isDark
                  //                 ? [seedPalette.shade600, seedPalette.shade700]
                  //                 : [seedPalette.shade100, seedPalette.shade200],
                  //           ),
                  //           icon: HugeIcons.strokeRoundedShare08,
                  //           label: 'Share',
                  //           onTap: () {
                  //             // TODO: Share subscription
                  //           },
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const Gap(16.0),

                  // Review info (if available)
                  if (subscription.observation != null)
                    _SectionContainer(
                      backgroundColor: subscription.status.isRejected
                          ? errorColor.withValues(alpha: 0.1)
                          : successColor.withValues(alpha: 0.1),
                      child: DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          color: subscription.status.isRejected
                              ? errorColor
                              : successColor,
                          strokeWidth: 1.5,
                          strokeCap: StrokeCap.round,
                          dashPattern: const [4, 6, 8, 10],
                          radius: Radius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: subscription.status.isRejected
                                        ? HugeIcons.strokeRoundedCancelCircle
                                        : HugeIcons
                                              .strokeRoundedCheckmarkCircle02,
                                    color: subscription.status.isRejected
                                        ? errorColor
                                        : successColor,
                                  ),
                                  const Gap(12.0),
                                  Text(
                                    subscription.status.isRejected
                                        ? l10n.subscriptionDetailPage_rejectDialog_reasonLabel
                                        : l10n.subscriptionDetailPage_reviewInfo_sectionTitle,
                                    style: AppTextStyles.h4.copyWith(
                                      color: subscription.status.isRejected
                                          ? errorColor
                                          : successColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (subscription.observation!.message !=
                                  null) ...[
                                const Gap(12.0),
                                Text(
                                  subscription.observation!.message!,
                                  style: AppTextStyles.body,
                                ),
                              ],
                              const Gap(8.0),
                              Divider(
                                thickness: 0.5,
                                color: subscription.status.isRejected
                                    ? errorColor
                                    : successColor,
                              ),
                              Text(
                                '${l10n.subscriptionDetailPage_reviewInfo_reviewedOn} ${dateFormatter(subscription.observation!.observedAt)}',
                                style: AppTextStyles.small.copyWith(
                                  color: subscription.status.isRejected
                                      ? errorColor
                                      : successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Student info section (Admin only)
                  Obx(() {
                    final authController = Get.find<AuthController>();
                    final isAdmin = authController.isAdmin;

                    if (!isAdmin) return const SizedBox.shrink();

                    return Column(
                      children: [
                        const Gap(16.0),
                        _StudentInfoSection(studentId: subscription.studentId),
                      ],
                    );
                  }),

                  const Gap(16.0),

                  // Status & Dates section
                  _SectionContainer(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          label: l10n
                              .subscriptionDetailPage_statusDates_startLabel,
                          value: dateFormatter(subscription.startDate),
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedCalendar04,
                          label:
                              l10n.subscriptionDetailPage_statusDates_endLabel,
                          value: dateFormatter(subscription.endDate),
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedHourglass,
                          label: l10n
                              .subscriptionDetailPage_statusDates_durationLabel,
                          value: _formatDuration(subscription.timeRemaining),
                          valueColor: accentColor,
                        ),
                      ],
                    ),
                  ),

                  const Gap(16.0),

                  // Bus stop section
                  if (subscription.hasStop)
                    _BusStopSection(stop: subscription.stop!),

                  const Gap(16.0),

                  // Weekly schedules
                  if (subscription.schedules.isNotEmpty)
                    _SectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedCalendar02,
                                  color: themeController.isDark
                                      ? lightColor
                                      : darkColor,
                                ),
                                const Gap(12.0),
                                Text(
                                  l10n.subscriptionDetailPage_weeklySchedule_title,
                                  style: AppTextStyles.h3,
                                ),
                              ],
                            ),
                          ),
                          ...subscription.schedules.asMap().entries.map((
                            entry,
                          ) {
                            return Column(
                              children: [
                                if (entry.key > 0) _Divider(),
                                _ScheduleRow(schedule: entry.value),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                  const Gap(16.0),

                  // Metadata
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: MetadataSection(
                      locale: localeController.locale.languageCode,
                      entries: [
                        MetadataEntry(
                          icon: HugeIcons.strokeRoundedCalendarAdd02,
                          label: l10n.createdAt,
                          dateTime: subscription.createdAt,
                        ),
                        MetadataEntry(
                          icon: HugeIcons.strokeRoundedEdit02,
                          label: l10n.lastUpdated,
                          dateTime: subscription.updatedAt,
                        ),
                      ],
                    ),
                  ),
                  _authController.isAdmin &&
                          subscription.status == BusSubscriptionStatus.pending
                      ? const Gap(120.0)
                      : const Gap(40.0),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton:
          (_authController.isAdmin) &&
              subscription.status == BusSubscriptionStatus.pending
          ? ExpandableFab(
              key: _fabKey,
              type: ExpandableFabType.up,
              distance: 70.0,
              childrenAnimation: ExpandableFabAnimation.rotate,
              overlayStyle: ExpandableFabOverlayStyle(
                color: Colors.black.withValues(alpha: 0.5),
                blur: 5,
              ),
              openButtonBuilder: RotateFloatingActionButtonBuilder(
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMenu03,
                  color: lightColor,
                ),
                fabSize: ExpandableFabSize.regular,
                backgroundColor: themeController.isDark
                    ? seedPalette.shade800
                    : seedColor,
                foregroundColor: lightColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius * 2.25,
                ),
              ),
              closeButtonBuilder: DefaultFloatingActionButtonBuilder(
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: lightColor,
                ),
                fabSize: ExpandableFabSize.regular,
                backgroundColor: themeController.isDark
                    ? seedPalette.shade800
                    : seedColor,
                foregroundColor: lightColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius * 2.25,
                ),
              ),
              children: [
                // Approve action
                FloatingActionButton.extended(
                  heroTag: 'approve',
                  onPressed: () => _handleApprove(context),
                  backgroundColor: successColor,
                  foregroundColor: lightColor,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: lightColor,
                  ),
                  label: Text(
                    l10n.subscriptionDetailPage_adminAction_approve,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: lightColor,
                    ),
                  ),
                ),
                // Reject action
                FloatingActionButton.extended(
                  heroTag: 'reject',
                  onPressed: () => _handleReject(context),
                  backgroundColor: errorColor,
                  foregroundColor: lightColor,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancelCircle,
                    color: lightColor,
                  ),
                  label: Text(
                    l10n.subscriptionDetailPage_adminAction_reject,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: lightColor,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: themeController.isDark
          ? seedPalette.shade900
          : seedPalette.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedImageNotFound02,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const Gap(16.0),
            Text(
              l10n.subscriptionDetailPage_paymentProof_placeholder,
              style: AppTextStyles.body.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    BusSubscription subscription,
  ) {
    if (!subscription.hasProof) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(
              imageUrl: subscription.proofOfPaymentUrl!,
              heroTag: subscription.id,
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(BusSubscriptionStatus status) {
    switch (status) {
      case BusSubscriptionStatus.approved:
        return successColor;
      case BusSubscriptionStatus.pending:
        return infoColor;
      case BusSubscriptionStatus.rejected:
        return errorColor;
      case BusSubscriptionStatus.expired:
        return greyColor;
    }
  }

  String _getStatusLabel(BusSubscriptionStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case BusSubscriptionStatus.approved:
        return l10n.subscriptionDetailPage_statusLabel_approved;
      case BusSubscriptionStatus.pending:
        return l10n.subscriptionDetailPage_statusLabel_pending;
      case BusSubscriptionStatus.rejected:
        return l10n.subscriptionDetailPage_statusLabel_rejected;
      case BusSubscriptionStatus.expired:
        return l10n.subscriptionDetailPage_statusLabel_expired;
    }
  }

  String _formatDuration(Duration duration) {
    final l10n = AppLocalizations.of(context)!;
    if (duration.isNegative || duration == Duration.zero) {
      return l10n.subscriptionExpired;
    }
    final days = duration.inDays;
    if (days > 0)
      return '$days ${l10n.days.length > 1 ? l10n.days : l10n.days.substring(0, l10n.days.length - 1)}';
    final hours = duration.inHours;
    if (hours > 0) return '$hours hr${hours > 1 ? "s" : ""}';
    final minutes = duration.inMinutes;
    return '$minutes minute${minutes > 1 ? "s" : ""}';
  }
}

// Apple-style action button
class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;
  final Gradient? gradient;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: borderRadius * 2.0,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        decoration: BoxDecoration(
          borderRadius: borderRadius * 2.75,
          gradient:
              gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeController.isDark
                    ? [seedPalette.shade800, seedPalette.shade900]
                    : [seedPalette.shade800, seedPalette.shade900],
              ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              color:
                  foregroundColor ??
                  (themeController.isDark ? lightColor : seedPalette.shade50),
              strokeWidth: 1.8,
            ),
            const Gap(4.0),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    foregroundColor ??
                    (themeController.isDark ? lightColor : seedPalette.shade50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Section container with rounded corners
class _SectionContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const _SectionContainer({required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (themeController.isDark
                ? seedPalette.shade800
                : seedPalette.shade50),
        borderRadius: borderRadius * 2.0,
      ),
      child: child,
    );
  }
}

// Info row with icon, label and value
class _InfoRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            color: themeController.isDark ? lightColor : seedColor,
          ),
          const Gap(12.0),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Schedule row with day and times
class _ScheduleRow extends StatelessWidget {
  final BusSubscriptionSchedule schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdays = [
      l10n.weekday_monday,
      l10n.weekday_tuesday,
      l10n.weekday_wednesday,
      l10n.weekday_thursday,
      l10n.weekday_friday,
      l10n.weekday_saturday,
    ];
    final day = weekdays[schedule.weekday - 1];

    return Padding(
      padding: const EdgeInsets.all(16).copyWith(right: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: 120.0,
            height: 48.0,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: seedPalette.shade200.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              day,
              style: AppTextStyles.body.copyWith(
                fontVariations: [FontVariation('wght', 500)],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.morning, style: AppTextStyles.small),
              Text(schedule.morningTime, style: AppTextStyles.body),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.closing, style: AppTextStyles.small),
              Text(schedule.closingTime, style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }
}

// Metadata row with smaller text

// Divider within sections
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: themeController.isDark
            ? seedPalette.shade50.withValues(alpha: 0.1)
            : seedColor.withValues(alpha: 0.1),
      ),
    );
  }
}

// Bus stop section with map and image
class _BusStopSection extends StatefulWidget {
  final BusStop stop;

  const _BusStopSection({required this.stop});

  @override
  State<_BusStopSection> createState() => _BusStopSectionState();
}

class _BusStopSectionState extends State<_BusStopSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasMap = widget.stop.hasMapEmbed;
    final hasImage = widget.stop.hasImage;
    final hasVisualContent = hasMap || hasImage;

    if (!hasVisualContent) {
      // Just show the info row if no map or image
      return _SectionContainer(
        child: _InfoRow(
          icon: HugeIcons.strokeRoundedLocation01,
          label: l10n.subscriptionDetailPage_mapView_title,
          value: widget.stop.name,
        ),
      );
    }

    // Calculate number of pages
    final pages = <Widget>[];
    if (hasMap) {
      pages.add(_MapView(stop: widget.stop));
    }
    if (hasImage) {
      pages.add(_PickupImageView(imageUrl: widget.stop.pickupImageUrl!));
    }

    return _SectionContainer(
      child: Column(
        children: [
          _InfoRow(
            icon: HugeIcons.strokeRoundedLocation06,
            label: l10n.subscriptionDetailPage_mapView_title,
            value: widget.stop.name,
          ),
          const Gap(8.0),
          SizedBox(
            height: 260.0,
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: pages,
                ),
                // Page indicator
                if (pages.length > 1)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      spacing: 4.0,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: duration,
                          width: _currentPage == index ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: _currentPage == index
                                ? accentColor
                                : lightColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
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

// Map view with background image - simple and clean
class _MapView extends StatelessWidget {
  final BusStop stop;

  const _MapView({required this.stop});

  Future<void> _openInMaps(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (!stop.hasMapEmbed) return;

    try {
      final uri = Uri.parse(stop.mapEmbedUrl!);
      if (kDebugMode) {
        debugPrint('Opening map URL: ${stop.mapEmbedUrl}');
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: lightColor,
                ),
                label: Text(
                  l10n.subscriptionDetailPage_mapView_openMessageSuccess,
                ),
                backgroundColor: successColor,
              ),
            );
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error opening map URL: ${e.toString()}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: lightColor,
              ),
              label: Text(l10n.subscriptionDetailPage_mapView_openMessageError),
              backgroundColor: errorColor,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedPalette.shade800
            : seedPalette.shade100,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16.0),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background map image
          Image.asset(mapsBg, fit: BoxFit.cover),

          // Subtle gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  seedColor.withValues(alpha: 0.2),
                  seedColor.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),

          // Tap to open button (bottom left)
          Positioned(
            bottom: 16,
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openInMaps(context),
                borderRadius: borderRadius * 1.25,
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: themeController.isDark
                        ? accentColor
                        : accentPalette.shade300,
                    borderRadius: borderRadius * 1.25,
                    boxShadow: [
                      BoxShadow(
                        color: darkColor.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 18.0,
                        color: themeController.isDark ? lightColor : darkColor,
                      ),
                      const Gap(8),
                      Text(
                        l10n.subscriptionDetailPage_mapView_ctaLabel,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14.0,
                          color: themeController.isDark
                              ? lightColor
                              : darkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // "Open in Maps" button (top right)
          Positioned(
            top: 16,
            right: 16,
            child: IconButton.filledTonal(
              tooltip: l10n.subscriptionDetailPage_mapView_ctaTooltip,
              onPressed: () => _openInMaps(context),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowUpRight01,
                color: lightColor,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: seedColor.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pickup point image view
class _PickupImageView extends StatelessWidget {
  final String imageUrl;

  const _PickupImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.0)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: themeController.isDark
                  ? seedPalette.shade800
                  : seedPalette.shade100,
              child: Center(child: LoadingIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: themeController.isDark
                  ? seedPalette.shade800
                  : seedPalette.shade100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedImageNotFound02,
                      size: 48,
                      color: greyColor,
                    ),
                    const Gap(8.0),
                    Text(
                      l10n.subscriptionDetailPage_mapView_pickupImageUnavailable,
                      style: AppTextStyles.small.copyWith(color: greyColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // "Place preview" badge (bottom left)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: themeController.isDark
                    ? seedPalette.shade200
                    : seedColor,
                borderRadius: borderRadius * 1.25,
                boxShadow: [
                  BoxShadow(
                    color: darkColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedImage02,
                    size: 18,
                    color: themeController.isDark ? seedColor : lightColor,
                  ),
                  const Gap(8),
                  Text(
                    l10n.subscriptionDetailPage_mapView_pickupImagePreview,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14.0,
                      color: themeController.isDark ? seedColor : lightColor,
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

// Student info section (Admin only)
class _StudentInfoSection extends StatelessWidget {
  final String studentId;

  const _StudentInfoSection({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<BaseUser?>(
      future: authController.getUserById(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SectionContainer(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedUserCircle,
                        color: themeController.isDark ? lightColor : seedColor,
                      ),
                      const Gap(12.0),
                      Text(
                        l10n.subscriptionDetailPage_studentSection_title,
                        style: AppTextStyles.h3,
                      ),
                    ],
                  ),
                  const Gap(16.0),
                  // Shimmer loading effect
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child:
                          Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: themeController.isDark
                                      ? seedColor.withValues(alpha: 0.2)
                                      : seedPalette.shade50.withValues(
                                          alpha: 0.5,
                                        ),
                                  borderRadius: borderRadius * 1.5,
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: const Duration(milliseconds: 1500),
                                color: themeController.isDark
                                    ? lightColor.withValues(alpha: 0.2)
                                    : lightColor.withValues(alpha: 0.5),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _SectionContainer(
            backgroundColor: errorColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    color: errorColor,
                  ),
                  const Gap(12.0),
                  Expanded(
                    child: Text(
                      l10n.subscriptionDetailPage_studentSection_loadingError,
                      style: AppTextStyles.body.copyWith(color: errorColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final student = snapshot.data!;

        return _SectionContainer(
          backgroundColor: themeController.isDark
              ? seedPalette.shade700
              : seedPalette.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: themeController.isDark
                            ? lightColor.withValues(alpha: 0.1)
                            : seedPalette.shade700.withValues(alpha: 0.1),
                        borderRadius: borderRadius * 1.5,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedUserCircle,
                        color: themeController.isDark ? lightColor : seedColor,
                      ),
                    ),
                    const Gap(12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.subscriptionDetailPage_studentSection_title,
                            style: AppTextStyles.h3,
                          ),
                          Text(
                            l10n.subscriptionDetailPage_studentSection_subtitle,
                            style: AppTextStyles.small.copyWith(
                              color: themeController.isDark
                                  ? seedPalette.shade50.withValues(alpha: 0.7)
                                  : greyColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _Divider(),
              _InfoRow(
                icon: HugeIcons.strokeRoundedUser,
                label: l10n.subscriptionDetailPage_studentSection_name,
                value: student.name,
              ),
              _Divider(),
              _InfoRow(
                icon: HugeIcons.strokeRoundedMail02,
                label: l10n.subscriptionDetailPage_studentSection_email,
                value: student.email,
              ),
              _Divider(),
              _InfoRow(
                icon: HugeIcons.strokeRoundedCheckmarkBadge02,
                label: l10n.subscriptionDetailPage_studentSection_status,
                value: student.status.name.capitalize ?? student.status.name,
                valueColor: student.isVerified ? successColor : warningColor,
              ),
              if (student.phone != null && student.phone!.isNotEmpty) ...[
                _Divider(),
                _InfoRow(
                  icon: HugeIcons.strokeRoundedCall,
                  label: l10n.subscriptionDetailPage_studentSection_phone,
                  value: student.phone!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Full screen image viewer with pan and zoom
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageViewer({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.pop(),
      child: Scaffold(
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          Center(child: LoadingIndicator()),
                      errorWidget: (context, url, error) => Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedImageNotFound02,
                          color: lightColor,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        tooltip: l10n.close,
                        onPressed: () => context.pop(),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: lightColor,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: seedColor.withValues(alpha: 0.6),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: l10n.download,
                        onPressed: () {
                          // TODO: Download or share image
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCloudDownload,
                          color: lightColor,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: seedColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
