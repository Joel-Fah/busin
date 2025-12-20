import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../controllers/scanner_controller.dart';
import '../../../services/scanner_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  static const String routeName = '/scanner';

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ScannerController _scannerController = Get.put(ScannerController());
  late MobileScannerController _mobileScannerController;

  @override
  void initState() {
    super.initState();
    _mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    // Clear scan results when leaving the page to avoid showing old results on return
    _scannerController.clearScanResult();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Only process if scanner is active
    if (!_scannerController.isScannerActive.value) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final scannedCode = barcode.rawValue!;
        // Controller handles duplicate prevention and persistence
        _scannerController.processScan(scannedCode);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClipRSuperellipse(
            borderRadius: BorderRadius.vertical(
              bottom: borderRadius.topLeft * 5,
            ),
            child: SizedBox(
              height: mediaHeight(context) * 0.6,
              child: Stack(
                children: [
                  // Scanner View (full area)
                  Obx(
                    () => _scannerController.isScannerActive.value
                        ? MobileScanner(
                            controller: _mobileScannerController,
                            onDetect: _onDetect,
                          )
                        : Container(
                            color: seedColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedPause,
                                    color: seedPalette.shade50,
                                    size: 64.0,
                                  ),
                                  const Gap(16.0),
                                  Text(
                                    'Scanner Paused',
                                    style: AppTextStyles.h2.copyWith(
                                      color: seedPalette.shade50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  // Back Button at Top Left
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16,
                    left: 16.0,
                    child: _buildBackButton(),
                  ),

                  // Info Bubble at Top Center
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildInfoBubble()),
                  ),

                  // Scanner Controls
                  Positioned(
                    bottom: 16.0,
                    right: 16.0,
                    child: _buildScannerControls(),
                  ),
                ],
              ),
            ),
          ),

          // Result Section (2/5 of screen)
          Expanded(
            child: Container(
              width: mediaWidth(context),
              decoration: BoxDecoration(
                color: themeController.isDark ? seedColor : lightColor,
              ),
              child: Obx(() {
                final result = _scannerController.currentScanResult.value;
                final isProcessing = _scannerController.isProcessing.value;

                if (isProcessing) {
                  return _buildProcessingState();
                }

                if (result == null) {
                  return _buildIdleState();
                }

                return _buildResultState(result);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
          color: darkColor.withValues(alpha: 0.7),
          borderRadius: borderRadius * 2.0,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: borderRadius * 2.0,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: borderRadius * 2.0,
                border: Border.all(
                  color: lightColor.withValues(alpha: 0.3),
                ),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: lightColor,
                size: 20.0,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.5, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildInfoBubble() {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: infoColor.withValues(alpha: 0.9),
            borderRadius: borderRadius * 2.5,
            boxShadow: [
              BoxShadow(
                color: darkColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.0,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                color: lightColor,
                size: 20.0,
              ),
              Text(
                'Scan student QR codes',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14.0,
                  color: lightColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.5, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildScannerControls() {
    return Column(
      children: [
        _ScannerControlButton(
          icon: _mobileScannerController.torchEnabled
              ? HugeIcons.strokeRoundedFlashOff
              : HugeIcons.strokeRoundedFlash,
          onTap: () => _mobileScannerController.toggleTorch(),
          tooltip: 'Toggle Flash',
        ),
        const Gap(8.0),
        Obx(
          () => _ScannerControlButton(
            icon: _scannerController.isScannerActive.value
                ? HugeIcons.strokeRoundedPause
                : HugeIcons.strokeRoundedPlay,
            onTap: () => _scannerController.toggleScanner(),
            tooltip: _scannerController.isScannerActive.value
                ? 'Pause Scanner'
                : 'Resume Scanner',
          ),
        ),
        const Gap(8.0),
        _ScannerControlButton(
          icon: HugeIcons.strokeRoundedRefresh,
          onTap: () {
            _scannerController.resetScanner();
            _mobileScannerController.stop();
            _mobileScannerController.start();
          },
          tooltip: 'Reset Scanner',
        ),
      ],
    );
  }

  Widget _buildIdleState() {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ready to Scan',
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8.0),
                  Text(
                    'Point camera at QR code',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
              ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1500.ms),
          const Gap(24.0),
          Text(
            'Verifying...',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(8.0),
          Text(
            'Please wait',
            style: AppTextStyles.body.copyWith(
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.7)
                  : darkColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildResultState(ScanResult result) {
    final isGranted = result.isValid && result.hasActiveSubscription;
    final statusColor = isGranted ? successColor : errorColor;
    final statusIcon = isGranted
        ? HugeIcons.strokeRoundedCheckmarkCircle02
        : HugeIcons.strokeRoundedCancelCircle;
    final statusText = isGranted ? 'ACCESS GRANTED' : 'ACCESS DENIED';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        key: ValueKey(result.student?.id ?? result.hashCode),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Compact Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2.0),
                  ),
                  child: HugeIcon(
                    icon: statusIcon,
                    color: statusColor,
                    size: 24.0,
                  ),
                ),
                const Gap(12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: AppTextStyles.h3.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      if (result.student != null)
                        Text(
                          result.student!.name,
                          style: AppTextStyles.body.copyWith(
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.8)
                                : darkColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(12.0),
            Divider(
              color: themeController.isDark
                  ? lightColor.withValues(alpha: 0.1)
                  : darkColor.withValues(alpha: 0.1),
              height: 1,
            ),
            const Gap(12.0),

            // Details Section
            if (result.student != null) ...[
              _buildCompactInfo(result),
            ] else ...[
              _ErrorCard(message: result.errorMessage ?? 'Unknown error'),
            ],

            const Gap(12.0),

            // Compact Clear Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Controller handles clearing and resets lastScannedCode
                  _scannerController.clearScanResult();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: lightColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius * 1.5,
                  ),
                ),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh,
                  color: lightColor,
                  size: 18.0,
                ),
                label: const Text(
                  'Next Scan',
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(ScanResult result) {
    final subscription = result.subscription;
    final student = result.student!;

    return Column(
      children: [
        // Student Email
        _CompactInfoRow(
          icon: HugeIcons.strokeRoundedMail01,
          label: 'Email',
          value: student.email,
        ),

        if (subscription != null) ...[
          const Gap(10.0),
          _CompactInfoRow(
            icon: HugeIcons.strokeRoundedTicket01,
            label: 'Subscription',
            value: '${subscription.semester.label} ${subscription.year}',
            valueColor: accentColor,
          ),
          const Gap(10.0),
          _CompactInfoRow(
            icon: HugeIcons.strokeRoundedLocation01,
            label: 'Bus Stop',
            value: subscription.stop?.name ?? 'N/A',
            valueColor: accentColor,
          ),
          const Gap(10.0),
          _CompactInfoRow(
            icon: HugeIcons.strokeRoundedCalendar03,
            label: 'Valid Until',
            value: dateFormatter(subscription.endDate),
            valueColor: successColor,
          ),
        ] else ...[
          const Gap(10.0),
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.1),
              borderRadius: borderRadius * 1.5,
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  color: errorColor,
                  size: 18.0,
                ),
                const Gap(10.0),
                Expanded(
                  child: Text(
                    'No active subscription found',
                    style: AppTextStyles.body.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScannerControlButton extends StatelessWidget {
  const _ScannerControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: darkColor.withValues(alpha: 0.7),
        borderRadius: borderRadius * 2.0,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius * 2.0,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              borderRadius: borderRadius * 2.0,
              border: Border.all(color: lightColor.withValues(alpha: 0.3)),
            ),
            child: HugeIcon(icon: icon, color: lightColor, size: 20.0),
          ),
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: (valueColor ?? accentColor).withValues(alpha: 0.15),
            borderRadius: borderRadius,
          ),
          child: HugeIcon(
            icon: icon,
            color: valueColor ?? accentColor,
            size: 16.0,
          ),
        ),
        const Gap(10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: themeController.isDark
                      ? lightColor.withValues(alpha: 0.6)
                      : darkColor.withValues(alpha: 0.6),
                  fontSize: 11.0,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  fontSize: 13.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: borderRadius * 2.0,
        border: Border.all(
          color: errorColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: errorColor,
            size: 32.0,
          ),
          const Gap(12.0),
          Text(
            'Error',
            style: AppTextStyles.h3.copyWith(
              color: errorColor,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const Gap(6.0),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: errorColor,
              fontSize: 13.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

