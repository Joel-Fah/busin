import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/locale_controller.dart';
import 'package:busin/controllers/onboarding_controller.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/ui/components/widgets/buttons/primary_button.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class WelcomeModal extends StatelessWidget {
  const WelcomeModal({super.key});

  /// Show the welcome modal if user hasn't seen it
  static Future<void> showIfNeeded(BuildContext context) async {
    final OnboardingController onboardingController =
        Get.find<OnboardingController>();

    if (!onboardingController.hasSeenWelcomeModal && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => const WelcomeModal(),
      );
      onboardingController.markWelcomeModalAsSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final LocaleController localeController = Get.find<LocaleController>();
    final user = authController.currentUser.value;

    // Determine header image based on locale
    final headerImage = localeController.locale.languageCode == 'fr'
        ? welcomeHeaderFr
        : welcomeHeaderEn;

    // Get user-specific welcome message
    final welcomeData = _getWelcomeData(user?.role ?? UserRole.student);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        gradient: themeController.isDark ? darkGradient : lightGradient,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(16.0),
            // Header Image
            SvgPicture.asset(headerImage, width: mediaWidth(context))
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),

            // Welcome Title
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                        welcomeData['title']!,
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  const Gap(16.0),

                  // Welcome Message
                  Text(
                        welcomeData['message']!,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const Gap(32.0),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child:
                        PrimaryButton.label(
                              onPressed: () => context.pop(),
                              label: welcomeData['cta']!,
                            )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 600.ms)
                            .scale(
                              begin: Offset(0.8, 0.8),
                              end: Offset(1.0, 1.0),
                            ),
                  ),
                ],
              ),
            ),

            const Gap(8.0),
          ],
        ),
      ),
    );
  }

  /// Get welcome data based on user role
  Map<String, String> _getWelcomeData(UserRole role) {
    switch (role) {
      case UserRole.student:
        return {
          'title': 'Welcome to BusIn!',
          'message':
              'Hey there! We\'re excited to have you on board. Managing your bus subscriptions just got way easier. Ready to hop on?',
          'cta': 'Let\'s Explore!',
        };

      case UserRole.staff:
        return {
          'title': 'Welcome to BusIn',
          'message':
              'Thank you for joining the BusIn team. You now have access to scan student QR codes and verify bus access. Let\'s make transportation management seamless.',
          'cta': 'Get Started',
        };

      case UserRole.admin:
        return {
          'title': 'Welcome, Administrator',
          'message':
              'Welcome to the BusIn management dashboard. You have full access to manage subscriptions, bus stops, semesters, and oversee the entire transportation system. Let\'s streamline operations.',
          'cta': 'Access Dashboard',
        };
    }
  }
}
