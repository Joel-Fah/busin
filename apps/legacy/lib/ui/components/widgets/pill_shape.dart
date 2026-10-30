import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class PillShape extends StatelessWidget {
  const PillShape({
    super.key,
    this.bgColor,
    this.borderColor,
    required this.label,
  });

  final Color? bgColor, borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: borderRadius * 4.0,
        color:
            bgColor ??
            (themeController.isDark ? seedColor : seedPalette.shade100),
        border: Border.all(
          width: 3.0,
          color:
              borderColor ??
              (themeController.isDark
                  ? seedPalette.shade900
                  : seedPalette.shade50),
        ),
      ),
      child: Text(label, style: AppTextStyles.body),
    );
  }
}
