import 'dart:math' as math;

import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import '../router.dart';
import 'splash_screen.dart';

/// The first thing a student sees: a full-bleed photo under a veil, the wordmark, a headline with the marker under it,
/// and a rotated orange call to action. Dark mode shows the night bus under a teal veil with white words; light mode the
/// bus stop seen from above under a light veil with teal words (the mark stays white, on a teal shade at the top). On a wide screen (a
/// tablet in landscape) the photo takes the left and the words and the button sit on the page colour at the right.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with SingleTickerProviderStateMixin {
  bool _busy = false;
  SignInFailure? _failure;

  // The hand-off from the opening animation: the mark starts where the splash left it (the centre, 144 wide) and
  // travels to the top left corner while the photo and the words fade in around it.
  late final AnimationController _hand = AnimationController(vsync: this);
  bool _handoff = false;

  @override
  void initState() {
    super.initState();
    _handoff = ref.read(logoHandoffProvider);
    if (_handoff) {
      // After this frame: a provider cannot be changed while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(logoHandoffProvider.notifier).consume();
        _hand.duration = BusinMotion.of(context, const Duration(milliseconds: 1100));
        _hand.forward().whenComplete(() {
          if (mounted) setState(() => _handoff = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _hand.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // On success the session changes and the router moves on; this screen is gone.
    } on SignInException catch (e) {
      if (mounted) setState(() => _failure = e.reason);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final wide = BusinLayout.of(context).isExpanded;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final message = switch (_failure) {
      SignInFailure.cancelled => l10n.signInCancelled,
      SignInFailure.notAllowed => l10n.signInNotAllowed,
      SignInFailure.failed => l10n.signInFailed,
      null => null,
    };

    final words = _Words(message: message, busy: _busy, onSignIn: _signIn);

    final content = wide
          ? Row(
              children: [
                Expanded(flex: 6, child: _Photo(fade: false, showMark: !_handoff)),
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: Grain(opacity: 1)),
                      SafeArea(child: Center(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Padding(padding: const EdgeInsets.all(BusinSpace.x8), child: words))))),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                const _Photo(fade: true),
                SafeArea(
                  // Scrolls only when the screen is too short or the text too big for everything to fit.
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(BusinSpace.x6, BusinSpace.x4, BusinSpace.x6, BusinSpace.x6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(alignment: Alignment.centerLeft, child: Opacity(opacity: _handoff ? 0 : 1, child: const BrandMark(color: Colors.white, height: 44))),
                              const Spacer(),
                              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: words)),
                              if (kDebugMode) const _StyleguideLink(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light icons in both themes: the top of the photo stays dark enough for the white mark.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // The splash's own colours, so the hand-off from it shows no jump.
        backgroundColor: dark ? BusinRamps.seed : BusinPalette.of(context).bg,
        body: _handoff ? _withHandoff(context, content, wide, dark) : content,
      ),
    );
  }

  /// The screen fading in while the mark travels from the centre to its corner. The corner is where the screen's own
  /// mark sits (hidden until the end), so the traveller lands exactly on it.
  Widget _withHandoff(BuildContext context, Widget content, bool wide, bool dark) {
    final size = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    const startWidth = splashMarkWidth;
    final startHeight = startWidth * 126 / 205;
    final start = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: startWidth, height: startHeight);
    final endHeight = wide ? 48.0 : 44.0;
    final endLeft = wide ? BusinSpace.x8 : BusinSpace.x6 + safe.left;
    final endTop = wide ? BusinSpace.x8 : safe.top + BusinSpace.x4;
    final end = Rect.fromLTWH(endLeft, endTop, endHeight * 205 / 126, endHeight);
    final travel = CurvedAnimation(parent: _hand, curve: Curves.easeInOutCubicEmphasized);
    final reveal = CurvedAnimation(parent: _hand, curve: const Interval(0.35, 1, curve: Curves.easeOut));

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(opacity: reveal, child: content),
        AnimatedBuilder(
          animation: travel,
          builder: (context, _) {
            final rect = Rect.lerp(start, end, travel.value)!;
            return Positioned.fromRect(
              rect: rect,
              // In light mode the splash's mark is teal: it turns white on the way, as the photo appears under it.
              child: IgnorePointer(
                key: const ValueKey('logo-handoff'),
                child: FittedBox(child: BrandMark(color: dark ? Colors.white : Color.lerp(BusinRamps.seed, Colors.white, travel.value)!, height: 100)),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The photo, decorative: the night bus in dark mode, the bus stop seen from above (Pexels 21576182) in light mode. With
/// [fade] a veil of the page colour lets the words sit on it; without, the photo is shown whole.
class _Photo extends StatelessWidget {
  const _Photo({required this.fade, this.showMark = true});

  final bool fade;

  /// The wide layout's mark. Hidden while the travelling mark of the opening hand-off is on its way to it.
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final veil = dark ? BusinRamps.seed : BusinPalette.of(context).bg;
    final (colors, stops) = switch ((dark, fade)) {
      (true, true) => ([veil.withValues(alpha: 0.25), veil.withValues(alpha: 0.45), veil.withValues(alpha: 0.96)], const [0.0, 0.4, 0.82]),
      (true, false) => ([veil.withValues(alpha: 0.12), veil.withValues(alpha: 0.25)], const [0.0, 1.0]),
      // Light: a teal shade at the top so the white mark reads, the photo clear in the middle, then the page colour under
      // the words.
      (false, true) => (
          [BusinRamps.seed.withValues(alpha: 0.5), BusinRamps.seed.withValues(alpha: 0), veil.withValues(alpha: 0), veil.withValues(alpha: 0.5), veil.withValues(alpha: 0.95), veil],
          const [0.0, 0.22, 0.3, 0.5, 0.7, 1.0],
        ),
      (false, false) => ([BusinRamps.seed.withValues(alpha: 0.5), BusinRamps.seed.withValues(alpha: 0)], const [0.0, 0.3]),
    };
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (dark)
            Image.asset('assets/photos/night-bus.webp', package: 'busin_ui', fit: BoxFit.cover, alignment: const Alignment(0.1, 0.35), filterQuality: FilterQuality.medium)
          else
            Image.asset('assets/photos/bus-stop.webp', package: 'busin_ui', fit: BoxFit.cover, alignment: const Alignment(-0.1, -0.2), filterQuality: FilterQuality.medium),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: stops),
            ),
          ),
          if (!fade) Align(alignment: Alignment.topLeft, child: Padding(padding: const EdgeInsets.all(BusinSpace.x8), child: Opacity(opacity: showMark ? 1 : 0, child: const BrandMark(color: Colors.white, height: 48)))),
        ],
      ),
    );
  }
}

class _Words extends StatelessWidget {
  const _Words({required this.message, required this.busy, required this.onSignIn});

  final String? message;
  final bool busy;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : BusinRamps.seed;
    final p = dark ? BusinPalette.dark : BusinPalette.light;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredIn(
          child: MarkedText(l10n.signInTitle, opacity: 0.7, style: text.displaySmall?.copyWith(color: ink, height: 1.1)),
        ),
        const SizedBox(height: BusinSpace.x4),
        StaggeredIn(index: 1, child: Text(l10n.signInSubtitle, style: text.bodyLarge?.copyWith(color: ink.withValues(alpha: 0.85), height: 1.45))),
        const SizedBox(height: BusinSpace.x8),
        if (message != null) ...[
          Semantics(
            liveRegion: true,
            child: DecoratedBox(
              decoration: BoxDecoration(color: p.badBg, borderRadius: BorderRadius.circular(BusinRadius.md)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x3),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 18, color: p.bad),
                    const SizedBox(width: BusinSpace.x3),
                    Expanded(child: Text(message!, style: text.bodyMedium?.copyWith(color: p.bad))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: BusinSpace.x4),
        ],
        StaggeredIn(index: 2, child: _GoogleBanner(label: l10n.signInWithGoogle, busy: busy, onPressed: busy ? null : onSignIn)),
      ],
    );
  }
}

/// The call to action: a wide orange band, tilted a little, with grain and the stitched thread. It squeezes when pressed.
class _GoogleBanner extends StatefulWidget {
  const _GoogleBanner({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_GoogleBanner> createState() => _GoogleBannerState();
}

class _GoogleBannerState extends State<_GoogleBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(BusinRadius.md));
    final ink = BusinPalette.light.onAccent;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: BusinMotion.of(context, BusinMotion.fast),
        curve: BusinMotion.soft,
        child: Transform.rotate(
          angle: -2 * math.pi / 180,
          child: DecoratedBox(
            decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
            child: Material(
              color: BusinPalette.orange,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(child: Grain(opacity: 0.5)),
                  InkWell(
                    onTap: widget.onPressed == null
                        ? null
                        : () {
                            BusinHaptics.medium();
                            widget.onPressed!();
                          },
                    onHighlightChanged: (down) => setState(() => _pressed = down),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x6, vertical: BusinSpace.x5),
                      child: Row(
                        children: [
                          // Google's own mark, as its brand rules ask for a sign-in with Google.
                          const GoogleMark(size: 26),
                          const SizedBox(width: BusinSpace.x3),
                          Expanded(child: Text(widget.label, style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800))),
                          if (widget.busy)
                            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: ink))
                          else
                            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight02, color: ink),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(child: Contour(color: threadColor(text: ink, background: BusinPalette.orange, mix: 0.38), style: const ContourStyle(radius: 20, inset: 6, dash: 5, gap: 5, live: true), active: _pressed)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Debug builds only: a way into the styleguide from the first screen.
class _StyleguideLink extends StatelessWidget {
  const _StyleguideLink();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: BusinSpace.x4),
        child: Center(
          child: TextButton(
            onPressed: () => context.go(Routes.styleguide),
            child: Text('Styleguide', style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : BusinRamps.seed).withValues(alpha: 0.7))),
          ),
        ),
      );
}
