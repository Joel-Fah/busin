import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/constants.dart';

SnackBar buildSnackBar({
  required Widget prefixIcon,
  required Widget label,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.25),
    backgroundColor: backgroundColor ?? infoColor,
    showCloseIcon: true,
    closeIconColor: foregroundColor ?? null,
    padding: const EdgeInsets.all(10.0),
    content: Material(
      textStyle: AppTextStyles.body.copyWith(
        color: foregroundColor ?? lightColor,
      ),
      color: foregroundColor ?? lightColor,
      type: MaterialType.transparency,
      child: Animate(
        effects: [FadeEffect(), MoveEffect()],
        child: Row(
          spacing: 8.0,
          children: [
            Ink(
              decoration: BoxDecoration(
                borderRadius: borderRadius * 1.75,
                color:
                    foregroundColor?.withValues(alpha: 0.1) ??
                    lightColor.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(12.0),
              child: prefixIcon,
            ),
            Expanded(child: label),
          ],
        ),
      ),
    ),
  );
}
