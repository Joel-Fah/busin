import 'dart:async';

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';

/// The mark's width, the same as the native launch screen, so the hand-off from the system splash to the drawing is
/// invisible: the same size, in the same place.
const double splashMarkWidth = 144;

/// How long the loading screen stays silent before it admits it is taking a while.
const splashSlowAfter = Duration(seconds: 10);

/// The first thing on screen. On a cold start the logo draws itself once (a tap skips it); afterwards, and whenever the
/// session or the profile is still being read, the finished mark stays with a thin progress bar below it. If that lasts
/// more than ten seconds it says so and offers to try again, instead of waiting in silence.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  /// Starts counting when the drawing is over and something is still being read; stops when there is nothing to wait for.
  void _watch(bool waiting) {
    if (waiting && _slowTimer == null && !_slow) {
      _slowTimer = Timer(splashSlowAfter, () {
        if (mounted) setState(() => _slow = true);
      });
    } else if (!waiting && (_slowTimer != null || _slow)) {
      _slowTimer?.cancel();
      _slowTimer = null;
      if (_slow) {
        // After this frame: setting state while building is not allowed.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _slow = false);
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _slow = false;
      _slowTimer?.cancel();
      _slowTimer = null;
    });
    ref.invalidate(profileProvider);
    ref.invalidate(authUserIdProvider);
  }

  @override
  Widget build(BuildContext context) {
    final palette = BusinPalette.of(context);
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    final introDone = ref.watch(introDoneProvider);
    final waiting = introDone && ref.watch(accessProvider) is AccessLoading;
    _watch(waiting);
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
                    label: l10n.loadingLabel,
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
          if (introDone && _slow && waiting)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(BusinSpace.x6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Semantics(
                      liveRegion: true,
                      container: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.loadingSlowTitle, style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                          const SizedBox(height: BusinSpace.x2),
                          Text(l10n.loadingSlowBody, style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)), textAlign: TextAlign.center),
                          const SizedBox(height: BusinSpace.x4),
                          BusinButton(label: l10n.actionRetry, variant: BusinButtonVariant.secondary, onPressed: _retry),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
