import 'package:busin/ui/components/onboarding/step_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

import '../../../models/onboard.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import '../widgets/locale_popup_button.dart';

class FirstOnboardPage extends StatelessWidget {
  const FirstOnboardPage({required this.onboardData, required this.index});

  final Onboard onboardData;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                themeController.isDark ? onboard1 : onboard1_light,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Bottom gradient overlay for readability
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              height: mediaHeight(context) * 0.45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    seedColor.withValues(alpha: 0),
                    seedColor,
                    Color(0xFF00161A),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 56.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(whiteLogo, height: 56.0)
                      .animate()
                      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.2, end: 0, duration: 500.ms),
                  LocalePopupButton().animate()
                      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.2, end: 0, duration: 500.ms),
                ],
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mediaWidth(context) * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          onboardData.title,
                          style: AppTextStyles.h2.copyWith(
                            color: lightColor,
                            fontVariations: [FontVariation('wght', 400)],
                          ),
                        )
                        .animate(target: index == 0 ? 1 : 0)
                        .fadeIn(duration: 450.ms)
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const Gap(10),
                    Text(
                          onboardData.subtitle,
                          style: AppTextStyles.body.copyWith(
                            color: lightColor.withValues(alpha: 0.75),
                          ),
                        )
                        .animate(target: index == 0 ? 1 : 0)
                        .fadeIn(duration: 550.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 550.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ),
              ),
              const Gap(16),
              StepProgressIndicator(current: 0, index: index),
            ],
          ),
        ),
      ],
    );
  }
}
