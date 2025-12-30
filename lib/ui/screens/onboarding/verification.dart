import 'package:busin/ui/components/widgets/buttons/primary_button.dart';
import 'package:busin/ui/components/widgets/buttons/secondary_button.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/actors/roles.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  static const String routeName = '/verification';

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final AuthController _authController = Get.find<AuthController>();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Auto-check status on page load
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isChecking = true;
    });

    try {
      // Reload user data from Firestore
      await _authController.reloadCurrentUser();

      final status = _authController.currentUser.value?.status;

      // Check if status has changed to verified
      if (status == AccountStatus.verified) {
        // Staff is verified, redirect to home (keep as staff, don't upgrade to admin)
        await _handleVerified();
      } else if (status == AccountStatus.suspended) {
        // Staff was rejected, just update UI (setState will rebuild)
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                backgroundColor: errorColor,
                prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
                label: Text(l10n.verificationPage_rejectMessage),
              ),
            );
        }
      }
      // If still pending, just update the UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                '${l10n.verificationPage_checkStatusError} ${e.toString()}',
              ),
              backgroundColor: errorColor,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _handleVerified() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: successColor,
              prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
              label: Text(l10n.verificationPage_approvedMessage),
            ),
          );

        // Navigate to home (as verified staff, not admin)
        context.goNamed(removeLeadingSlash(HomePage.routeName));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                '${l10n.verificationPage_navigationError} ${e.toString()}',
              ),
              backgroundColor: errorColor,
            ),
          );
      }
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    await _authController.signOut().then((_) {
      snackBarKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            backgroundColor: successColor,
            prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
            label: Text(l10n.verificationPage_signOutMessage),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStatus = _authController.currentUser.value?.status;
    final isPending = userStatus == AccountStatus.pending;
    final isRejected = userStatus == AccountStatus.suspended;
    final isVerified = userStatus == AccountStatus.verified;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          children: [
            // Logo or Icon
            Image.asset(waiting, height: 160.0),

            const Gap(32.0),

            // Title
            Text(
                  isRejected
                      ? l10n.verificationPage_titleRejected
                      : isPending
                      ? l10n.verificationPage_titlePending
                      : l10n.verificationPage_titleComplete,
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32.0,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 100.ms),
            const Gap(16.0),

            // Description
            Text(
                  isRejected
                      ? l10n.verificationPage_descriptionRejected
                      : isPending
                      ? l10n.verificationPage_descriptionPending
                      : l10n.verificationPage_descriptionComplete,
                  style: AppTextStyles.body.copyWith(
                    color: themeController.isDark
                        ? lightColor.withValues(alpha: 0.7)
                        : darkColor.withValues(alpha: 0.7),
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 200.ms),
            const Gap(48.0),

            // Status Card
            Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color:
                        (isRejected
                                ? errorColor
                                : isVerified
                                ? successColor
                                : infoColor)
                            .withValues(alpha: 0.1),
                    borderRadius: borderRadius * 2.75,
                    border: Border.all(
                      color: isRejected
                          ? errorColor
                          : isVerified
                          ? successColor
                          : infoColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: isRejected
                                ? HugeIcons.strokeRoundedCancelCircle
                                : isVerified
                                ? HugeIcons.strokeRoundedCheckmarkCircle02
                                : HugeIcons.strokeRoundedClock01,
                            color: isRejected
                                ? errorColor
                                : isVerified
                                ? successColor
                                : infoColor,
                            size: 20.0,
                          ),
                          const Gap(8.0),
                          Text(
                            isRejected
                                ? l10n.statusRejected
                                : isVerified
                                ? l10n.statusApproved
                                : l10n.statusPending,
                            style: AppTextStyles.h3.copyWith(
                              color: isRejected
                                  ? errorColor
                                  : isVerified
                                  ? successColor
                                  : infoColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16.0),
                      Text(
                        isRejected
                            ? l10n.verificationPage_infoAlert_descriptionRejected
                            : isVerified
                            ? l10n.verificationPage_infoAlert_descriptionVerified
                            : l10n.verificationPage_infoAlert_descriptionPending,
                        style: AppTextStyles.body.copyWith(
                          color: isRejected
                              ? errorColor
                              : isVerified
                              ? successColor
                              : infoColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 300.ms),
            const Gap(32.0),

            // Action Button (Check Status or Continue)
            if (isVerified)
              PrimaryButton.icon(
                    onPressed: () =>
                        context.goNamed(removeLeadingSlash(HomePage.routeName)),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: lightColor,
                      size: 20.0,
                    ),
                    label: Text(
                      l10n.verificationPage_ctaVerified,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 400.ms)
            else
              PrimaryButton.icon(
                    onPressed: _isChecking ? null : _checkVerificationStatus,
                    icon: _isChecking
                        ? SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                lightColor,
                              ),
                            ),
                          )
                        : const HugeIcon(
                            icon: HugeIcons.strokeRoundedRefresh,
                            color: lightColor,
                            size: 20.0,
                          ),
                    label: Text(
                      _isChecking
                          ? l10n.verificationPage_ctaPendingLoading
                          : l10n.verificationPage_ctaPending,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 400.ms),
            const Gap(16.0),

            // Sign Out Button
            SecondaryButton.icon(
                  dottedColor: accentColor,
                  onPressed: _signOut,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout02,
                    size: 20.0,
                  ),
                  label: Text(
                    l10n.verificationPage_ctaSignOut,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 500.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 500.ms),
            const Gap(48.0),

            // Help Text
            Text(
              l10n.verificationPage_labelSupport,
              style: AppTextStyles.small.copyWith(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.5)
                    : greyColor.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
