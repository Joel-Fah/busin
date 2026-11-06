import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// The mark's width, the same as the native launch screen, so the hand-off from the system splash to the drawing is
/// invisible: the same size, in the same place.
const double splashMarkWidth = 144;

/// The first thing on screen. On a cold start the logo draws itself once (a tap skips it); afterwards, and whenever the
/// session or the profile is still being read, the finished mark stays with a thin progress bar below it.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = BusinPalette.of(context);
    final introDone = ref.watch(introDoneProvider);
    const markHeight = splashMarkWidth * 126 / 205;
    return Scaffold(
      backgroundColor: BusinRamps.seed,
      body: Stack(
        children: [
          const Positioned.fill(child: Grain(opacity: 1)),
          // The mark stays at the exact centre, as on the native splash; the bar hangs below it.
          Center(
            child: introDone
                ? Semantics(
                    label: BusinL10n.of(context).loadingLabel,
                    child: const BrandMark(color: Colors.white, height: markHeight),
                  )
                : BrandIntro(
                    color: Colors.white,
                    width: splashMarkWidth,
                    onDone: ref.read(introDoneProvider.notifier).finish,
                  ),
          ),
          if (introDone)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: markHeight + BusinSpace.x12 * 2),
                child: SizedBox(
                  width: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(BusinRadius.xs),
                    child: LinearProgressIndicator(minHeight: 4, color: palette.accent, backgroundColor: Colors.white24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
