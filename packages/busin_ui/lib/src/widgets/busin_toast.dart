import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../painters/contour.dart';
import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'haptics.dart';

/// What a toast is telling. Each state has its own icon, colour and how long it stays: good news leaves quickly, a
/// problem stays long enough to be read and acted on.
enum ToastTone { success, info, warning, error }

/// A short message that floats at the top of the screen and goes away by itself: the stitched thread, an icon for its
/// state, swipe up to dismiss. One at a time: a new toast replaces the one showing. It never takes the place of the words
/// a screen needs to keep (an error with a retry button stays on the screen); it is for confirmations and reminders.
class BusinToast {
  const BusinToast._();

  /// How long a toast of this [tone] stays, unless the caller says otherwise.
  static Duration durationFor(ToastTone tone) => switch (tone) {
        ToastTone.success => const Duration(milliseconds: 2800),
        ToastTone.info => const Duration(milliseconds: 4000),
        ToastTone.warning => const Duration(milliseconds: 5500),
        ToastTone.error => const Duration(milliseconds: 7000),
      };

  static _Showing? _current;

  /// Shows [message] (with an optional bold [title]) in [context]'s root overlay.
  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = ToastTone.info,
    String? title,
    Duration? duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    switch (tone) {
      case ToastTone.success:
        BusinHaptics.light();
      case ToastTone.warning:
      case ToastTone.error:
        BusinHaptics.medium();
      case ToastTone.info:
        break;
    }
    late final OverlayEntry entry;
    final showing = _Showing();
    entry = OverlayEntry(
      builder: (context) => _ToastView(
        key: showing.key,
        message: message,
        title: title,
        tone: tone,
        duration: duration ?? durationFor(tone),
        onGone: () {
          if (entry.mounted) entry.remove();
          if (identical(_current, showing)) _current = null;
        },
      ),
    );
    showing.entry = entry;
    _current = showing;
    overlay.insert(entry);
  }

  /// Takes the toast away now, if one is showing.
  static void dismiss() {
    final showing = _current;
    _current = null;
    if (showing == null) return;
    final entry = showing.entry;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _Showing {
  final key = GlobalKey<_ToastViewState>();
  OverlayEntry? entry;
}

class _ToastView extends StatefulWidget {
  const _ToastView({super.key, required this.message, required this.tone, required this.duration, required this.onGone, this.title});

  final String message;
  final String? title;
  final ToastTone tone;
  final Duration duration;
  final VoidCallback onGone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final AnimationController _life = AnimationController(vsync: this, duration: widget.duration);
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _leave);
    _life.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.duration == null) {
      // In a little slower than the usual 280 ms and out quicker, so it arrives gently and leaves without lingering.
      _controller.duration = BusinMotion.of(context, const Duration(milliseconds: 460));
      _controller.reverseDuration = BusinMotion.of(context, const Duration(milliseconds: 320));
      _controller.forward();
    }
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onGone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final (Color fill, Color ink, List<List<dynamic>> icon) = switch (widget.tone) {
      ToastTone.success => (p.okBg, p.ok, HugeIcons.strokeRoundedCheckmarkCircle02),
      ToastTone.info => (p.infoBg, p.info, HugeIcons.strokeRoundedInformationCircle),
      ToastTone.warning => (p.warnBg, p.warn, HugeIcons.strokeRoundedAlert02),
      ToastTone.error => (p.badBg, p.bad, HugeIcons.strokeRoundedCancelCircle),
    };
    const radius = BorderRadius.all(Radius.circular(BusinRadius.md));
    final curved = CurvedAnimation(parent: _controller, curve: const Cubic(0.16, 1, 0.3, 1), reverseCurve: const Cubic(0.4, 0, 0.7, 0.2));

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(BusinSpace.x4, BusinSpace.x3, BusinSpace.x4, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(curved),
                  child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                  child: Dismissible(
                    key: ValueKey(widget.message),
                    direction: DismissDirection.up,
                    onDismissed: (_) => widget.onGone(),
                    child: Semantics(
                      liveRegion: true,
                      container: true,
                      label: [if (widget.title != null) widget.title!, widget.message].join('. '),
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          onTap: _leave,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
                            child: Material(
                              color: Color.alphaBlend(fill, p.surface),
                              shape: const RoundedRectangleBorder(borderRadius: radius),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: Contour(color: ink.withValues(alpha: 0.35), style: const ContourStyle(radius: BusinRadius.md, inset: 4, dash: 5, gap: 5))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        HugeIcon(icon: icon, size: 24, color: ink),
                                        const SizedBox(width: BusinSpace.x3),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (widget.title != null) Text(widget.title!, style: text.labelLarge?.copyWith(color: p.fg, fontWeight: FontWeight.w800)),
                                              Text(widget.message, style: text.bodyMedium?.copyWith(color: p.fg)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: BusinSpace.x2),
                                        // The ring empties as the time runs out.
                                        SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Positioned.fill(
                                                child: AnimatedBuilder(
                                                  animation: _life,
                                                  builder: (context, _) => CircularProgressIndicator(
                                                    value: 1 - _life.value,
                                                    strokeWidth: 2,
                                                    strokeCap: StrokeCap.round,
                                                    color: ink,
                                                  ),
                                                ),
                                              ),
                                              HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 12, color: ink),
                                            ],
                                          ),
                                        ),
                                      ],
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
