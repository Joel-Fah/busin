import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class ListSubHeading extends StatelessWidget {
  const ListSubHeading({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.body.copyWith(
        color: themeController.isDark
            ? lightColor.withValues(alpha: 0.5)
            : seedColor.withValues(alpha: 0.5),
      ),
    );
  }
}
