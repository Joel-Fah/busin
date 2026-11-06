import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../painters/contour.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'illustration.dart';

/// What to show when there is nothing to show: not a card, but a quiet framed space with a 3D illustration (or an
/// icon), a title, a short explanation and one clear next step. The frame is a stitched thread that slides once when
/// the space appears. Every empty list in the apps says what is missing and what to do about it.
class EmptyState extends StatefulWidget {
  const EmptyState({super.key, required this.title, this.body, this.icon, this.illustration, this.action});

  final String title;
  final String? body;

  /// Used when there is no [illustration].
  final List<List<dynamic>>? icon;
  final BusinIllustration? illustration;
  final Widget? action;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // Slide the thread once as the space arrives.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(BusinSpace.x4),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x6, vertical: BusinSpace.x10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.illustration != null)
                      Illustration(widget.illustration!, width: 128, height: 128)
                    else if (widget.icon != null)
                      DecoratedBox(
                        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.lg)),
                        child: Padding(padding: const EdgeInsets.all(BusinSpace.x5), child: HugeIcon(icon: widget.icon!, size: 32, color: p.muted)),
                      ),
                    if (widget.illustration != null || widget.icon != null) const SizedBox(height: BusinSpace.x4),
                    Text(widget.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    if (widget.body != null) ...[
                      const SizedBox(height: BusinSpace.x2),
                      Text(widget.body!, style: text.bodyMedium?.copyWith(color: p.muted), textAlign: TextAlign.center),
                    ],
                    if (widget.action != null) ...[const SizedBox(height: BusinSpace.x5), widget.action!],
                  ],
                ),
              ),
              Positioned.fill(child: Contour(color: threadColor(text: p.fg, background: p.bg, mix: 0.16), style: ContourStyle.emptyState, active: _shown)),
            ],
          ),
        ),
      ),
    );
  }
}
