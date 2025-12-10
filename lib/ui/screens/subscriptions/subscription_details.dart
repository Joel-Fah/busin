import 'package:flutter/material.dart';
import 'package:busin/utils/utils.dart';
import 'package:busin/utils/constants.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/subscriptions_controller.dart';
import '../../../models/subscription.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  static const String routeName = '/subscription-details';

  final String subscriptionId;

  const SubscriptionDetailsPage({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context) {
    final BusSubscriptionsController controller = Get.find<BusSubscriptionsController>();
    final subscription = controller.getSubscriptionById(subscriptionId);

    if (subscription == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscription Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: errorColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Subscription not found',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'This subscription may have been deleted',
                style: AppTextStyles.body.copyWith(color: greyColor),
              ),
            ],
          ),
        ),
      );
    }

    return _SubscriptionDetailsContent(subscription: subscription);
  }
}

class _SubscriptionDetailsContent extends StatelessWidget {
  final BusSubscription subscription;

  const _SubscriptionDetailsContent({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(subscription.status);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image with SliverAppBar - Dynamic title behavior
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final isExpanded = top > kToolbarHeight + 50;

                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExpanded ? 0.0 : 1.0,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 72, right: 16),
                      child: Text(
                        subscription.semesterYear,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, subscription),
                        child: Hero(
                          tag: 'subscription_${subscription.id}',
                          child: subscription.hasProof
                              ? Image.network(
                                  subscription.proofOfPaymentUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder(colorScheme);
                                  },
                                )
                              : _buildImagePlaceholder(colorScheme),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.5, 1.0],
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
                                Text(
                                  subscription.semesterYear,
                                  style: AppTextStyles.title.copyWith(
                                    color: lightColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    subscription.status.label,
                                    style: AppTextStyles.body.copyWith(
                                      color: lightColor,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                const SizedBox(height: 8),

                // Action buttons (Apple style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: HugeIcons.strokeRoundedEdit02,
                          label: 'Edit',
                          onTap: () {
                            // TODO: Navigate to edit page
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: subscription.isCurrentlyActive
                              ? HugeIcons.strokeRoundedPauseCircle
                              : HugeIcons.strokeRoundedPlayCircle,
                          label: subscription.isCurrentlyActive
                              ? 'Pause'
                              : 'Activate',
                          onTap: () {
                            // TODO: Handle activation
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: HugeIcons.strokeRoundedShare08,
                          label: 'Share',
                          onTap: () {
                            // TODO: Share subscription
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Status & Dates section
                _SectionContainer(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        label: 'Start date',
                        value: dateFormatter(subscription.startDate),
                        colorScheme: colorScheme,
                      ),
                      _Divider(colorScheme: colorScheme),
                      _InfoRow(
                        icon: HugeIcons.strokeRoundedCalendar04,
                        label: 'End date',
                        value: dateFormatter(subscription.endDate),
                        colorScheme: colorScheme,
                      ),
                      _Divider(colorScheme: colorScheme),
                      _InfoRow(
                        icon: HugeIcons.strokeRoundedClock01,
                        label: 'Time remaining',
                        value: _formatDuration(subscription.timeRemaining),
                        colorScheme: colorScheme,
                        valueColor: accentColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bus stop section
                if (subscription.hasStop)
                  _SectionContainer(
                    child: _InfoRow(
                      icon: HugeIcons.strokeRoundedLocation01,
                      label: 'Bus stop',
                      value: subscription.stop!.name,
                      colorScheme: colorScheme,
                    ),
                  ),

                const SizedBox(height: 16),

                // Weekly schedules
                if (subscription.schedules.isNotEmpty)
                  _SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendarCheckIn02,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Weekly schedule',
                                style: AppTextStyles.h4.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...subscription.schedules
                            .asMap()
                            .entries
                            .map((entry) {
                          return Column(
                            children: [
                              if (entry.key > 0)
                                _Divider(colorScheme: colorScheme),
                              _ScheduleRow(
                                schedule: entry.value,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Review info (if available)
                if (subscription.observation != null)
                  _SectionContainer(
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
                                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                                color: subscription.status.isRejected
                                    ? errorColor
                                    : successColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                subscription.status.isRejected
                                    ? 'Rejection reason'
                                    : 'Review observation',
                                style: AppTextStyles.h4.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (subscription.observation!.message != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              subscription.observation!.message!,
                              style: AppTextStyles.body,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Reviewed on ${dateFormatter(subscription.observation!.observedAt)}',
                            style: AppTextStyles.small.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Metadata
                _SectionContainer(
                  child: Column(
                    children: [
                      _MetadataRow(
                        icon: HugeIcons.strokeRoundedCalendarAdd02,
                        label: 'Created',
                        value: dateFormatter(subscription.createdAt),
                        colorScheme: colorScheme,
                      ),
                      _Divider(colorScheme: colorScheme),
                      _MetadataRow(
                        icon: HugeIcons.strokeRoundedEdit02,
                        label: 'Last updated',
                        value: dateFormatter(subscription.updatedAt),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: themeController.isDark ? seedPalette.shade900 : seedPalette.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedImageNotFound02,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No proof of payment',
              style: AppTextStyles.body.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, BusSubscription subscription) {
    if (!subscription.hasProof) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrl: subscription.proofOfPaymentUrl!,
          heroTag: 'subscription_${subscription.id}',
        ),
      ),
    );
  }

  Color _getStatusColor(BusSubscriptionStatus status) {
    switch (status) {
      case BusSubscriptionStatus.approved:
        return successColor;
      case BusSubscriptionStatus.pending:
        return warningColor;
      case BusSubscriptionStatus.rejected:
        return errorColor;
      case BusSubscriptionStatus.expired:
        return greyColor;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return 'Expired';
    }
    final days = duration.inDays;
    if (days > 0) return '$days day${days > 1 ? "s" : ""}';
    final hours = duration.inHours;
    if (hours > 0) return '$hours hour${hours > 1 ? "s" : ""}';
    final minutes = duration.inMinutes;
    return '$minutes minute${minutes > 1 ? "s" : ""}';
  }
}

// Apple-style action button
class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: themeController.isDark
              ? seedPalette.shade900
              : seedPalette.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              color: accentColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
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

  const _SectionContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedPalette.shade900
            : seedPalette.shade50,
        borderRadius: BorderRadius.circular(16),
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
  final ColorScheme colorScheme;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
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
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
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

  const _ScheduleRow({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final day = weekdays[schedule.weekday - 1];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                day,
                style: AppTextStyles.body.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSun03,
                      size: 16,
                      color: greyColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      schedule.morningTime,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedMoon02,
                      size: 16,
                      color: greyColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      schedule.closingTime,
                      style: AppTextStyles.small.copyWith(
                        color: greyColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Metadata row with smaller text
class _MetadataRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            color: greyColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.small.copyWith(color: greyColor),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.small.copyWith(color: greyColor),
          ),
        ],
      ),
    );
  }
}

// Divider within sections
class _Divider extends StatelessWidget {
  final ColorScheme colorScheme;

  const _Divider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

// Full screen image viewer with pan and zoom
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: accentColor,
                      ),
                    );
                  },
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: lightColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      // TODO: Download or share image
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedDownload01,
                      color: lightColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
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

