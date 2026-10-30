import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

/// Model for a metadata entry
class MetadataEntry {
  final List<List<dynamic>> icon;
  final String label;
  final DateTime dateTime;

  const MetadataEntry({
    required this.icon,
    required this.label,
    required this.dateTime,
  });
}

/// Displays a list of metadata entries in a styled container
class MetadataSection extends StatelessWidget {
  final List<MetadataEntry> entries;
  final Color? backgroundColor;
  final String? locale;

  const MetadataSection({
    super.key,
    required this.entries,
    this.backgroundColor,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionContainer(
      backgroundColor: backgroundColor ?? Colors.transparent,
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          return Column(
            children: [
              _MetadataRow(
                icon: entry.icon,
                label: entry.label,
                value: formatRelativeDateTime(entry.dateTime, locale: locale),
              ),
              if (index < entries.length - 1) const _Divider(),
            ],
          );
        }),
      ),
    );
  }
}

// Section container with rounded corners and adaptive background
class _SectionContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const _SectionContainer({required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
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

// Metadata row with icon, label and value
class _MetadataRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;

  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            color: themeController.isDark ? seedPalette.shade500 : greyColor,
            size: 18,
          ),
          const Gap(12.0),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: themeController.isDark ? seedPalette.shade500 : greyColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.small.copyWith(
              color: themeController.isDark ? seedPalette.shade500 : greyColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Divider between metadata rows
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
