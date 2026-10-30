import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/constants.dart';

class BusLoadingOverlay extends StatelessWidget {
  const BusLoadingOverlay({
    super.key,
    required this.visible,
    this.title = 'Processing your request',
    this.message = 'Please stay with us for a few seconds...',
  });

  final bool visible;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ModalBarrier(
            dismissible: false,
          ),
          AnimatedSwitcher(
            duration: 350.ms,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            child: !visible
                ? const SizedBox.shrink()
                : Container(
              key: const ValueKey('bus-loading-overlay'),
              color: Colors.black.withValues(alpha: 0.5),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 32.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _BusLoadingCard(title: title, message: message),
                  ),
                ),
              ),
            )
                .animate()
                .fade(duration: 200.ms)
                .slideY(
              begin: 0.25,
              end: 0.0,
              duration: 350.ms,
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusLoadingCard extends StatelessWidget {
  const _BusLoadingCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: mediaWidth(context),
      padding: const EdgeInsets.all(24.0).copyWith(top: 0.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 28.0,
            offset: const Offset(0, 12.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(busLoader),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
