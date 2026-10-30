import 'dart:math';

import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/models/onboard.dart';
import 'package:busin/utils/constants.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/utils.dart';
import '../../components/onboarding/first_page.dart';
import '../../components/onboarding/step_progress_indicator.dart';
import 'auth_modal.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController(viewportFraction: 0.95);
  final GlobalKey<_SecondOnboardPageState> _secondKey =
      GlobalKey<_SecondOnboardPageState>();
  int _index = 0;
  bool _handlingCta = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) => setState(() => _index = i);

  Future<void> _handleCtaTap() async {
    if (_handlingCta) return;
    _handlingCta = true;
    try {
      if (_index != 1) {
        await _controller.animateToPage(
          1,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic,
        );
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!mounted) return;
      await _secondKey.currentState?.startCtaFlow();
    } finally {
      _handlingCta = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeController.isDark
          ? SystemUiOverlayStyle.light
          : _index == 0
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: PageView(
          padEnds: false,
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            FirstOnboardPage(
              onboardData: onboardData(context)[0],
              index: _index,
            ),
            SecondOnboardPage(
              key: _secondKey,
              onboardData: onboardData(context)[1],
              index: _index,
              onCtaPressed: _handleCtaTap,
            ),
          ],
        ),
      ),
    );
  }
}

class SecondOnboardPage extends StatefulWidget {
  const SecondOnboardPage({
    super.key,
    required this.onboardData,
    required this.index,
    this.onCtaPressed,
  });

  final Onboard onboardData;
  final int index;
  final Future<void> Function()? onCtaPressed;

  @override
  State<SecondOnboardPage> createState() => _SecondOnboardPageState();
}

class _SecondOnboardPageState extends State<SecondOnboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctaCtrl;
  late final Animation<Offset> _ctaOffset;
  bool _ctaBusy = false;

  @override
  void initState() {
    super.initState();
    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 420),
    );
    _ctaOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.25, 0),
    ).animate(CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _ctaCtrl.dispose();
    super.dispose();
  }

  Future<void> startCtaFlow() => _onCtaTap();

  Future<void> _onCtaTap() async {
    if (_ctaBusy) return;
    _ctaBusy = true;
    try {
      await _ctaCtrl.forward();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => const AuthModalSheet(),
      );
    } finally {
      if (mounted) {
        await _ctaCtrl.reverse();
      }
      _ctaBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.onboardData;
    final index = widget.index;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeController.isDark ? seedColor : seedPalette.shade50,
                themeController.isDark ? seedPalette.shade900 : lightColor,
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: OverflowBox(
            maxWidth: mediaWidth(context) * 1.5,
            child: Align(
              alignment: Alignment.bottomCenter,
              child:
                  SvgPicture.asset(onboard2, alignment: Alignment.bottomCenter)
                      .animate(target: index == 1 ? 1 : 0)
                      .fadeIn(duration: 500.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 56.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                    backgroundColor: themeController.isDark
                        ? seedPalette.shade50
                        : seedPalette.shade100,
                    radius: 24.0,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedDirectionRight02,
                      color: seedColor,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .slideY(begin: -0.2, end: 0, duration: 500.ms),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mediaWidth(context) * 0.85,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(4),
                    Text(
                          data.title,
                          style: AppTextStyles.h2.copyWith(
                            fontVariations: [FontVariation('wght', 400)],
                          ),
                        )
                        .animate(target: index == 1 ? 1 : 0)
                        .fadeIn(duration: 450.ms)
                        .slideY(
                          begin: -0.2,
                          end: 0,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const Gap(10),
                    Text(
                          data.subtitle,
                          style: AppTextStyles.body.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.75),
                          ),
                        )
                        .animate(target: index == 1 ? 1 : 0)
                        .fadeIn(duration: 550.ms)
                        .slideY(
                          begin: -0.15,
                          end: 0,
                          duration: 550.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ),
              ),
              const Gap(16),
              StepProgressIndicator(current: 1, index: index),
            ],
          ),
        ),
        Positioned(
          bottom: 56.0,
          left: 0.0,
          right: 0.0,
          child: SlideTransition(
            position: _ctaOffset,
            child: OverflowBox(
              maxWidth: mediaWidth(context) * 1.05,
              fit: OverflowBoxFit.deferToChild,
              child: Transform.rotate(
                angle: pi / 180 * -3,
                child: GestureDetector(
                  onTap: widget.onCtaPressed ?? _onCtaTap,
                  child:
                      Container(
                            height: 180.0,
                            padding: EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0),
                                  blurRadius: 17.0,
                                  offset: const Offset(0, 62),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 16.0,
                                  offset: const Offset(0, 40),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 13.0,
                                  offset: const Offset(0, 22),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 5.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DottedBorder(
                              options: RectDottedBorderOptions(
                                dashPattern: [4, 6, 8, 10],
                                strokeWidth: 2.5,
                                strokeCap: StrokeCap.round,
                                color: accentPalette.shade50,
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)!.onboarding_cta,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.h1.copyWith(
                                    color: lightColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate(
                            onInit: (controller) =>
                                controller.repeat(reverse: true),
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .shake(
                            duration: 1200.ms,
                            hz: 1,
                            rotation: 0.05,
                            delay: 3000.ms,
                            curve: Curves.easeInOut,
                          )
                          .shimmer(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
