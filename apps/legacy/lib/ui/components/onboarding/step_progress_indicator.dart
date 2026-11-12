import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../utils/constants.dart';

class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({required this.current, required this.index});

  final int current;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == current;
    final double totalWidth = 70;
    final double big = totalWidth * 0.78;
    final double small = totalWidth * 0.28;
    final bool firstIsBig = index == 0;

    return Row(
      children: [
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: firstIsBig ? big : small,
          height: 6.0,
          decoration: BoxDecoration(
            color: firstIsBig ? accentColor : accentPalette.shade50,
            borderRadius: borderRadius,
          ),
        ),
        const Gap(8),
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: firstIsBig ? small : big,
          height: 6.0,
          decoration: BoxDecoration(
            color: firstIsBig ? accentPalette.shade50 : accentColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    ).animate(target: isActive ? 1 : 0).fadeIn(duration: duration);
  }
}
