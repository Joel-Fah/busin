import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

/// Shown while the session and the profile are being read: the wordmark on the brand teal, settling in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = BusinPalette.of(context);
    return Scaffold(
      backgroundColor: BusinRamps.seed,
      body: Stack(
        children: [
          const Positioned.fill(child: Grain(opacity: 1)),
          Center(
            child: Semantics(
              label: BusinL10n.of(context).loadingLabel,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: BusinMotion.of(context, BusinMotion.slow),
                    curve: BusinMotion.soft,
                    builder: (context, t, child) => Opacity(opacity: t, child: Transform.scale(scale: 0.92 + 0.08 * t, child: child)),
                    child: const BrandMark(color: Colors.white, height: 72),
                  ),
                  const SizedBox(height: BusinSpace.x8),
                  SizedBox(
                    width: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(BusinRadius.xs),
                      child: LinearProgressIndicator(minHeight: 4, color: palette.accent, backgroundColor: Colors.white24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
