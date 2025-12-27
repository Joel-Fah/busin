import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/ui/components/widgets/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/value_objects/bus_stop_selection.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class BusStopCard extends StatelessWidget {
  final BusStop stop;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final int index;

  const BusStopCard({
    super.key,
    required this.stop,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image section (full height preview)
        Expanded(child: _buildImageSection()),

        // Info and actions section (no background)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta data
              Row(
                spacing: 8.0,
                children: [
                  _MetaData(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    label: 'Created on ${dateTimeFormatter(stop.createdAt)}',
                  ),
                  FutureBuilder(
                    future: authController.getUserById(stop.createdBy),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _MetaData(
                          icon: HugeIcons.strokeRoundedUser,
                          label: 'Loading...',
                        );
                      } else if (snapshot.hasError) {
                        return _MetaData(
                          icon: HugeIcons.strokeRoundedUser,
                          label: 'Unknown User',
                        );
                      } else {
                        final userName = snapshot.data?.name ?? 'Unknown User';
                        return _MetaData(
                          icon: HugeIcons.strokeRoundedUser,
                          label: 'By $userName',
                        );
                      }
                    },
                  ),
                ],
              ),

              // Stop name with location icon
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "#${index + 1}. ",
                      style: AppTextStyles.h2.copyWith(color: accentColor),
                    ),
                    TextSpan(text: stop.name),
                  ],
                ),
                style: AppTextStyles.h2,
              ),
              const Gap(12.0),

              // Features badges
              Row(
                spacing: 8.0,
                children: [
                  if (stop.hasImage)
                    _FeatureBadge(
                      icon: HugeIcons.strokeRoundedImage02,
                      label: 'Image',
                      color: successColor,
                    ),
                  if (stop.hasMapEmbed)
                    _FeatureBadge(
                      icon: HugeIcons.strokeRoundedMaps,
                      label: 'Map',
                      color: infoColor,
                    ),
                ],
              ),

              // Action buttons
              if (showActions && authController.isAdmin) ...[
                const Gap(16.0),
                Row(
                  spacing: 8.0,
                  children: [
                    Expanded(child: Divider()),
                    Row(
                      spacing: 8.0,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          icon: HugeIcons.strokeRoundedEdit02,
                          label: 'Edit',
                          onTap: onEdit,
                        ),
                        _ActionButton(
                          icon: HugeIcons.strokeRoundedDelete02,
                          label: 'Delete',
                          onTap: onDelete,
                          color: errorColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    if (stop.hasImage) {
      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: borderRadius * 2.75),
        constraints: BoxConstraints(minHeight: 300.0),
        child: CachedNetworkImage(
          imageUrl: stop.pickupImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: themeController.isDark
                ? seedPalette.shade900
                : seedPalette.shade100,
            child: Center(child: LoadingIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: themeController.isDark
                ? seedPalette.shade900
                : seedPalette.shade100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedImageNotFound02,
                    color: greyColor,
                    size: 48,
                  ),
                  const Gap(8.0),
                  Text(
                    'Image not available',
                    style: AppTextStyles.small.copyWith(color: greyColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (stop.hasMapEmbed) {
      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: borderRadius * 2.75,
          color: themeController.isDark
              ? seedPalette.shade900
              : seedPalette.shade100,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(mapsBg, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    seedColor.withValues(alpha: 0.1),
                    seedColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMaps,
                color: lightColor,
                size: 64,
              ),
            ),
          ],
        ),
      );
    }

    // Placeholder
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius * 2.75,
        color: themeController.isDark
            ? seedPalette.shade900
            : seedPalette.shade100,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              color: greyColor,
              size: 64,
            ),
            const Gap(12.0),
            Text(
              'No preview available',
              style: AppTextStyles.body.copyWith(color: greyColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        color ?? (themeController.isDark ? lightColor : seedColor);

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      overlayColor: WidgetStatePropertyAll(color?.withValues(alpha: 0.1)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: buttonColor, size: 24),
            const Gap(4.0),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: buttonColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaData extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;

  const _MetaData({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          spacing: 4.0,
          children: [
            HugeIcon(
              icon: icon,
              color: themeController.isDark ? seedPalette.shade50 : greyColor,
              size: 16.0,
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

class _FeatureBadge extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;

  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 16, color: color),
          const Gap(6.0),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
