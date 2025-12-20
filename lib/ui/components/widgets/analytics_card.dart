import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.subtitle,
  });

  final String title;
  final Widget child;
  final List<List<dynamic>>? icon;
  final Widget? action;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeController.isDark
            ? seedColor.withValues(alpha: 0.3)
            : seedPalette.shade50.withValues(alpha: 0.5),
        borderRadius: borderRadius * 2.5,
        border: Border.all(
          color: themeController.isDark
              ? lightColor.withValues(alpha: 0.1)
              : darkColor.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: HugeIcon(
                    icon: icon!,
                    color: accentColor,
                    size: 20.0,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.small.copyWith(
                          color: themeController.isDark
                              ? lightColor.withValues(alpha: 0.6)
                              : darkColor.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16.0),
          child,
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 200.ms);
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final List<List<dynamic>>? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: HugeIcon(
                icon: icon!,
                color: color ?? accentColor,
                size: 18.0,
              ),
            ),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.8)
                    : darkColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total) : 0.0;
    final barColor = color ?? accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.8)
                      : darkColor.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '$value / $total',
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
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8.0,
              backgroundColor: themeController.isDark
                  ? darkColor.withValues(alpha: 0.3)
                  : lightColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

