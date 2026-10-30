import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
    this.trend,
    this.onTap,
  });

  final String title;
  final String value;
  final List<List<dynamic>> icon;
  final String? subtitle;
  final Color? color;
  final String? trend; // e.g., "+12%", "-5%"
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius * 2.5,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: themeController.isDark
                ? seedColor.withValues(alpha: 0.3)
                : seedPalette.shade50.withValues(alpha: 0.5),
            borderRadius: borderRadius * 2.5,
            border: Border.all(
              color: cardColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: borderRadius * 1.5,
                    ),
                    child: HugeIcon(
                      icon: icon,
                      color: cardColor,
                      size: 24.0,
                    ),
                  ),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: trend!.startsWith('+')
                            ? successColor.withValues(alpha: 0.15)
                            : errorColor.withValues(alpha: 0.15),
                        borderRadius: borderRadius,
                      ),
                      child: Text(
                        trend!,
                        style: AppTextStyles.small.copyWith(
                          color: trend!.startsWith('+')
                              ? successColor
                              : errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                value,
                style: AppTextStyles.h1.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.7)
                      : darkColor.withValues(alpha: 0.7),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  subtitle!,
                  style: AppTextStyles.small.copyWith(
                    color: themeController.isDark
                        ? lightColor.withValues(alpha: 0.5)
                        : darkColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms);
  }
}

