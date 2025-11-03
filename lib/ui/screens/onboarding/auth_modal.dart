import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/ui/components/widgets/primary_button.dart';
import 'package:busin/ui/components/widgets/secondary_button.dart';
import 'package:busin/ui/screens/home/home.dart';
import 'package:busin/ui/screens/home/anonymous.dart';
import 'package:busin/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../models/actors/roles.dart';
import '../../../utils/constants.dart';

class AuthModalSheet extends StatefulWidget {
  const AuthModalSheet({super.key});

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  final PageController _pageController = PageController();
  UserRole? _selected;
  int _pageIndex = 0;

  bool _isLoading = false;
  String _error = '';

  AuthController get _authController =>
      Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController(), permanent: true);

  OnboardingController get _onboardingController =>
      Get.isRegistered<OnboardingController>()
          ? Get.find<OnboardingController>()
          : Get.put(OnboardingController(), permanent: true);

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final idx = (_pageController.page ?? _pageIndex.toDouble()).round();
      if (idx != _pageIndex) {
        setState(() => _pageIndex = idx);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
  }

  void _goBack() {
    _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // Apply onboarding choice: Student => verified; Staff => pending
      if (_selected == UserRole.student) {
        _authController.setFirstLoginProfile(UserRole.student, AccountStatus.verified);
      } else if (_selected == UserRole.staff) {
        _authController.setFirstLoginProfile(UserRole.staff, AccountStatus.pending);
      }

      await _authController.signInWithGoogle();
      _onboardingController.setOnboardingComplete(true);

      // Navigate to the main home after successful sign-in
      if (mounted) {
        context.goNamed(removeLeadingSlash(HomePage.routeName));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipOnboarding() {
    _onboardingController.setOnboardingComplete(true);
    context.goNamed(removeLeadingSlash(AnonymousHomePage.routeName));
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.isDark ? darkGradient : lightGradient;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _pageIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _pageIndex > 0) {
          _goBack();
        }
      },
      child: SafeArea(
        child: Animate(
          effects: [FadeEffect(), MoveEffect()],
          child: ListView(
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  width: 72.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: borderRadius * 2.0,
                  ),
                ),
              ),
              const Gap(20.0),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ).copyWith(bottom: MediaQuery.paddingOf(context).bottom),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius * 3.75,
                    gradient: gradient,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: _pageIndex == 0
                            ? mediaHeight(context) / 3
                            : mediaHeight(context) / 2,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildRoleSelectionPage(context),
                            _buildConfirmPage(context),
                          ],
                        ),
                      ),
                      const Gap(16),
                      if (_pageIndex == 1)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              overlayColor: accentPalette.shade200,
                            ),
                            onPressed: _isLoading ? null : _goBack,
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              size: 20.0,
                            ),
                            label: Text(
                              l10n.authModal_Step2_cta1Back,
                              style: AppTextStyles.body,
                            ),
                          ),
                        ),
                      if (_pageIndex == 1) const Gap(8),
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _error,
                            style: AppTextStyles.body.copyWith(
                              color: errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: _pageIndex == 0
                            ? Column(
                          spacing: 8.0,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton.label(
                                onPressed: (_selected == null || _isLoading)
                                    ? null
                                    : _goToNext,
                                label: l10n.authModal_Step1_cta1Proceed,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: SecondaryButton.icon(
                                onPressed:
                                _isLoading ? null : _skipOnboarding,
                                iconAlignment: IconAlignment.end,
                                icon: HugeIcon(
                                  icon: HugeIcons
                                      .strokeRoundedArrowUpRight01,
                                ),
                                label: Text(
                                  l10n.authModal_Step1_cta2Skip,
                                  style: AppTextStyles.body.copyWith(
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            : PrimaryButton.icon(
                          onPressed:
                          _isLoading ? null : _handleGoogleSignIn,
                          icon: SvgPicture.asset(googleIcon, width: 20.0),
                          label: _isLoading
                              ? Text(
                            'Signing in...',
                            style: AppTextStyles.body.copyWith(
                              color: lightColor,
                              fontVariations: [
                                FontVariation('wght', 500),
                              ],
                            ),
                          )
                              : RichText(
                            text: TextSpan(
                              text: l10n.authModal_Step2_cta2Login,
                              children: [
                                TextSpan(
                                  text: " (@ictuniversity.edu.cm)",
                                  style: AppTextStyles.body.copyWith(
                                    color: lightColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                              style: AppTextStyles.body.copyWith(
                                color: lightColor,
                                fontVariations: [
                                  FontVariation('wght', 500),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionPage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text(
          l10n.authModal_Step1_title,
          style: AppTextStyles.title.copyWith(
            fontVariations: [const FontVariation('wght', 400)],
          ),
        ),
        const Gap(8),
        Text(l10n.authModal_Step1_subtitle, style: AppTextStyles.body),
        const Gap(12),
        Row(
          spacing: 16.0,
          children: [
            Expanded(
              child: _RoleOption(
                title: l10n.authModal_Step1_option1,
                icon: HugeIcons.strokeRoundedUser,
                selected: _selected == UserRole.student,
                onTap: _isLoading
                    ? null
                    : () => setState(() => _selected = UserRole.student),
              ),
            ),
            Expanded(
              child: _RoleOption(
                title: l10n.authModal_Step1_option2,
                icon: HugeIcons.strokeRoundedSchoolTie,
                selected: _selected == UserRole.staff,
                onTap: _isLoading
                    ? null
                    : () => setState(() => _selected = UserRole.staff),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmPage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        themeController.isDark
            ? Image.asset(ictULogo, height: 100.0)
            : Image.asset(ictULogoHorizontal, width: 160.0),
        const Gap(16.0),
        Text(
          l10n.authModal_Step2_subtitle,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        Text(
          l10n.authModal_Step2_title,
          style: AppTextStyles.h2.copyWith(
            fontVariations: [FontVariation('wght', 500)],
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(16.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: themeController.isDark
                ? seedPalette.shade300.withValues(alpha: 0.1)
                : infoColor.withValues(alpha: 0.1),
            borderRadius: borderRadius * 2,
          ),
          child: Row(
            spacing: 16.0,
            children: [
              HugeIcon(
                icon: infoIcon,
                color: themeController.isDark
                    ? seedPalette.shade300
                    : infoColor,
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: l10n.authModal_Step2_instruction_slice1,
                    children: [
                      TextSpan(
                        text: " @ictuniversity.edu.cm ",
                        style: AppTextStyles.body.copyWith(
                          color: themeController.isDark
                              ? seedPalette.shade300
                              : infoColor,
                          fontVariations: [FontVariation('wght', 500)],
                        ),
                      ),
                      TextSpan(
                        text: l10n.authModal_Step2_instruction_slice2,
                      ),
                    ],
                  ),
                  style: AppTextStyles.body.copyWith(
                    color: themeController.isDark
                        ? seedPalette.shade300
                        : infoColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(16.0),
        Text(
          l10n.authModal_Step2_instruction_details,
          style: AppTextStyles.body.copyWith(
            color: themeController.isDark
                ? lightColor.withValues(alpha: 0.8)
                : greyColor,
            fontSize: 14.0,
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 16.0),
          child: Row(
            spacing: 8.0,
            children: [
              CircleAvatar(
                radius: 2.0,
                backgroundColor: themeController.isDark
                    ? lightColor.withValues(alpha: 0.8)
                    : greyColor,
              ),
              Expanded(
                child: Text(
                  l10n.authModal_Step2_instruction_detailsBullet1,
                  style: AppTextStyles.body.copyWith(
                    color: themeController.isDark
                        ? lightColor.withValues(alpha: 0.8)
                        : greyColor,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 16.0),
          child: Row(
            spacing: 8.0,
            children: [
              CircleAvatar(
                radius: 2.0,
                backgroundColor: themeController.isDark
                    ? lightColor.withValues(alpha: 0.75)
                    : greyColor,
              ),
              Expanded(
                child: Text(
                  l10n.authModal_Step2_instruction_detailsBullet2,
                  style: AppTextStyles.body.copyWith(
                    color: themeController.isDark
                        ? lightColor.withValues(alpha: 0.75)
                        : greyColor,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .move(begin: const Offset(0, 12), curve: Curves.easeOut);
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback? onTap;

  const _RoleOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius * 2;

    final Color borderCol = selected ? accentColor : Colors.transparent;
    final Color? bgCol = selected ? accentColor.withValues(alpha: 0.1) : null;

    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: 250.ms,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: radius,
              border: Border.all(color: borderCol, width: selected ? 1.5 : 1.0),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: 200.ms,
                      curve: Curves.easeOut,
                      scale: selected ? 1.05 : 1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: icon,
                            size: 28,
                            color: selected ? accentColor : greyColor,
                          ),
                          const Gap(8),
                          Text(
                            title,
                            style: AppTextStyles.h3.copyWith(
                              color: selected ? accentColor : greyColor,
                              fontVariations: [FontVariation('wght', 400)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!selected)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      radius: Radius.circular((radius.topLeft.x).toDouble()),
                      dashPattern: const [2, 4, 6, 8],
                      strokeWidth: 1.5,
                      strokeCap: StrokeCap.round,
                      color: greyColor,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}