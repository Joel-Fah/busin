import 'dart:async';
import 'dart:ui';

import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/scanning_controller.dart';
import 'package:busin/controllers/subscriptions_controller.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/ui/components/widgets/custom_list_tile.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/screens/home/scannings_list.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/actors/roles.dart';
import '../../../utils/constants.dart';
import '../../components/widgets/home/appbar_list_tile.dart';
import '../../components/widgets/user_avatar.dart';
import '../profile/profile.dart';

class ScanningsTab extends StatefulWidget {
  const ScanningsTab({super.key});

  static const String routeName = '/scannings_tab';

  @override
  State<ScanningsTab> createState() => _ScanningsTabState();
}

class _ScanningsTabState extends State<ScanningsTab> {
  final AuthController authController = Get.find<AuthController>();
  final ScanningController scanningController = Get.find<ScanningController>();
  final BusSubscriptionsController subscriptionsController =
      Get.find<BusSubscriptionsController>();
  final _noScreenshot = NoScreenshot.instance;
  bool _isProtectionEnabled = false;
  StreamSubscription? _screenshotSubscription;

  @override
  void initState() {
    super.initState();
    _enableScreenshotProtection();
    // Request location permission for students
    if (authController.isStudent) {
      _requestLocationPermission();
    }
  }

  @override
  void dispose() {
    _disableScreenshotProtection();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      await scanningController.requestLocationPermission();
      if (kDebugMode) {
        debugPrint('[ScanningsTab] Location permission requested for student');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningsTab] Error requesting location permission: $e');
      }
    }
  }

  Future<void> _enableScreenshotProtection() async {
    try {
      // Listen for screenshot attempts BEFORE enabling protection
      _screenshotSubscription = _noScreenshot.screenshotStream.listen((event) {
        // Only show warning if protection was already enabled and widget is mounted
        if (mounted && _isProtectionEnabled) {
          _showScreenshotWarning();
        }
      });

      // Small delay to ensure listener is set up
      await Future.delayed(const Duration(milliseconds: 100));

      // Enable screenshot blocking
      await _noScreenshot.screenshotOff();
      _isProtectionEnabled = true;
    } catch (e) {
      // Silently fail if screenshot blocking is not supported
      debugPrint('Screenshot protection not available: $e');
    }
  }

  Future<void> _disableScreenshotProtection() async {
    try {
      _isProtectionEnabled = false;

      // Cancel the stream subscription
      await _screenshotSubscription?.cancel();
      _screenshotSubscription = null;

      // Re-enable screenshots
      await _noScreenshot.screenshotOn();
    } catch (e) {
      debugPrint('Error disabling screenshot protection: $e');
    }
  }

  void _showScreenshotWarning() {
    // Check if warning has already been shown
    if (scanningController.hasShownScreenshotWarning()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        buildSnackBar(
          prefixIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: seedColor,
          ),
          label: Text(l10n.scanningsTab_screenshotsWarning),
          backgroundColor: warningColor,
          foregroundColor: seedColor,
        ),
      );

    // Mark warning as shown
    scanningController.markScreenshotWarningShown();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: AppBarListTile(
          onTap: () => context.pushNamed(
            removeLeadingSlash(ProfilePage.routeName),
            pathParameters: {'tag': authController.userProfileImage},
          ),
          leading: UserAvatar(tag: authController.userProfileImage),
          title: authController.userDisplayName,
          subtitle: authController.isVerified
              ? AccountStatus.verified.label
              : AccountStatus.pending.label,
          subtitleColor: authController.isVerified ? successColor : infoColor,
        ),
      ),
      body: Obx(() {
        final user = authController.currentUser.value;
        final isSuspended = user?.status.isSuspended ?? false;

        // Check if user has an active (approved) subscription
        final hasActiveSubscription = subscriptionsController.busSubscriptions
            .any((sub) => sub.status.isApproved);

        // Determine if QR should be blocked
        final shouldBlockQR = isSuspended || !hasActiveSubscription;

        return Column(
          children: [
            // QR Code Section
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: ClipRSuperellipse(
                borderRadius: borderRadius * 8.0,
                child:
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: themeController.isDark
                                  ? [
                                      seedPalette.shade800.withValues(
                                        alpha: 0.8,
                                      ),
                                      seedPalette.shade900.withValues(
                                        alpha: 0.3,
                                      ),
                                    ]
                                  : [
                                      seedPalette.shade50.withValues(
                                        alpha: 0.8,
                                      ),
                                      seedPalette.shade100.withValues(
                                        alpha: 0.5,
                                      ),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
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
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // QR Code (conditionally blurred)
                              ClipRSuperellipse(
                                borderRadius: borderRadius * 6.0,
                                child: ImageFiltered(
                                  imageFilter: shouldBlockQR
                                      ? ImageFilter.blur(sigmaX: 8, sigmaY: 8)
                                      : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                  child: QrImageView(
                                    data: authController.currentUser.value!.id
                                        .toString(),
                                    backgroundColor: lightColor,
                                    padding: const EdgeInsets.all(20),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      color: seedColor,
                                      dataModuleShape: QrDataModuleShape.circle,
                                    ),
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.circle,
                                      color: seedColor,
                                    ),
                                    gapless: false,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),
                                ),
                              ),
                              // Blocked image (only shown when QR is blocked)
                              if (shouldBlockQR)
                                Image.asset(blocked)
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1, 1),
                                    ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        )
                        .scale(
                          begin: const Offset(0.98, 0.98),
                          end: const Offset(1, 1),
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
              ),
            ),

            // Header with View All Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child:
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.scannings,
                            style: AppTextStyles.title.copyWith(fontSize: 48.0),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.pushNamed(
                                removeLeadingSlash(ScanningsListPage.routeName),
                              );
                            },
                            style: TextButton.styleFrom(
                              overlayColor: accentColor.withValues(alpha: 0.1),
                            ),
                            iconAlignment: IconAlignment.end,
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowUpRight02,
                            ),
                            label: Text(
                              l10n.viewAll,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.06,
                        end: 0,
                        duration: 380.ms,
                        curve: Curves.easeOut,
                      ),
            ),
            const Gap(20.0),

            // Latest Activity Section
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300.0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32.0),
                  ),
                  color: themeController.isDark
                      ? seedPalette.shade900
                      : seedPalette.shade50,
                ),
                child: Obx(() {
                  final lastScan = scanningController.lastScan.value;

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                            l10n.homeTab_title,
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.normal,
                              fontVariations: const [
                                FontVariation('wght', 400),
                              ],
                              fontSize: 24.0,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 320.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeOut,
                          ),
                      const Gap(20.0),

                      // Display last scan or empty state
                      if (lastScan != null)
                        CustomListTile(
                              onTap: () {
                                // TODO: Navigate to scan details
                              },
                              primaryPillLabel: '#${scanningController.scannings.length}',
                              title: Text(
                                lastScan.hasLocation
                                    ? maskCoordinates(lastScan.locationString)
                                    : l10n.homeTab_scanningsTile_titleUnavailable,
                                style: Theme.of(context)
                                    .listTileTheme
                                    .titleTextStyle
                                    ?.copyWith(color: accentColor),
                              ),
                              subtitle: Text(
                                dateTimeFormatter(lastScan.scannedAt),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 450.ms,
                              curve: Curves.easeOut,
                            )
                      else
                        _buildEmptyState(),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedQrCode,
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.3)
                      : darkColor.withValues(alpha: 0.3),
                  size: 48.0,
                ),
                const Gap(12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeTab_emptyScanningsCard_title,
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.homeTab_emptyScanningsCard_message,
                        style: AppTextStyles.body.copyWith(
                          color: themeController.isDark
                              ? lightColor.withValues(alpha: 0.6)
                              : darkColor.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}
