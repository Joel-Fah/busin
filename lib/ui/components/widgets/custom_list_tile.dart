import 'package:busin/ui/components/widgets/pill_shape.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    this.onTap,
    this.showBorder = false,
    this.topPillsBorderColor,
    required this.primaryPillLabel,
    this.backgroundColor,
    required this.title,
    required this.subtitle,
    this.secondaryPillLabel,
  });

  final void Function()? onTap;
  final bool? showBorder;
  final Color? topPillsBorderColor, backgroundColor;
  final String? primaryPillLabel, secondaryPillLabel;
  final Widget title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? (themeController.isDark
                  ? seedColor.withValues(alpha: 0.4)
                  : seedPalette.shade100.withValues(alpha: 0.4)),
              borderRadius: borderRadius * 2.0,
              border: showBorder!
                  ? Border.all(width: 2.0, color: successColor)
                  : null,
            ),
            child: ListTile(
              onTap: onTap,
              contentPadding: EdgeInsets.all(10.0),
              title: title,
              subtitle: subtitle,
              trailing: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: themeController.isDark ? lightColor : seedColor,
              ),
            ),
          ),
        ),
        Positioned(
          top: -12.0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              spacing: 6.0,
              children: [
                if (primaryPillLabel != null && primaryPillLabel!.isNotEmpty)
                  PillShape(
                    borderColor: topPillsBorderColor,
                    label: primaryPillLabel!,
                  ),
                if (secondaryPillLabel != null &&
                    secondaryPillLabel!.isNotEmpty)
                  PillShape(
                    borderColor: topPillsBorderColor,
                    label: secondaryPillLabel!,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
