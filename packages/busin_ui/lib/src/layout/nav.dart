import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../painters/contour.dart';
import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import '../widgets/haptics.dart';
import 'nav_indicator.dart';

/// One place the navigation leads to.
class BusinDestination {
  const BusinDestination({required this.label, required this.icon, this.semanticLabel});

  /// Short, because it sits under an icon.
  final String label;
  final List<List<dynamic>> icon;

  /// The full name for screen readers, if the short label is abbreviated.
  final String? semanticLabel;
}

/// Shared by the bar and the rail: a highlight that slides between items with the elastic stretch.
class _SlidingHighlight extends StatefulWidget {
  const _SlidingHighlight({required this.axis, required this.count, required this.index, required this.itemExtent, required this.gap, required this.color, required this.crossExtent});

  final Axis axis;
  final int count;
  final int index;

  /// Size of one item along the axis, and the gap between items.
  final double itemExtent;
  final double gap;
  final Color color;

  /// The highlight's size across the axis.
  final double crossExtent;

  @override
  State<_SlidingHighlight> createState() => _SlidingHighlightState();
}

class _SlidingHighlightState extends State<_SlidingHighlight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: indicatorDuration);
  late (double, double) _from = _span(widget.index);
  late (double, double) _to = _span(widget.index);

  (double, double) _span(int i) {
    final start = i * (widget.itemExtent + widget.gap);
    return (start, start + widget.itemExtent);
  }

  @override
  void didUpdateWidget(_SlidingHighlight old) {
    super.didUpdateWidget(old);
    if (old.itemExtent != widget.itemExtent || old.gap != widget.gap) {
      // The window was resized or rotated: the items moved, so the highlight goes straight to its place.
      _from = _to = _span(widget.index);
      _controller.value = 1;
    } else if (old.index != widget.index) {
      // Start from wherever the highlight is now, so a quick second tap does not jump.
      _from = _current();
      _to = _span(widget.index);
      if (BusinMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  (double, double) _current() => _controller.isAnimating ? indicatorEdges(from: _from, to: _to, t: _controller.value) : _to;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final (start, end) = _controller.value == 0 && _from == _to || _controller.isCompleted ? _to : indicatorEdges(from: _from, to: _to, t: _controller.value);
        final box = DecoratedBox(
          decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(BusinRadius.sm)),
        );
        return widget.axis == Axis.horizontal
            ? Positioned(left: start, width: end - start, top: 0, height: widget.crossExtent, child: box)
            : Positioned(top: start, height: end - start, left: 0, width: widget.crossExtent, child: box);
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap, required this.labelSize});

  final BusinDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final color = selected ? p.fg : p.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.semanticLabel ?? destination.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(BusinRadius.sm),
        onTap: () {
          if (!selected) BusinHaptics.selection();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: destination.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: labelSize),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glass surface with the stitched thread, floating: the shared skin of the bar and the rail.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    const radius = BorderRadius.all(Radius.circular(BusinRadius.lg));
    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: BusinElevation.glassBlur, sigmaY: BusinElevation.glassBlur),
          child: Stack(
            children: [
              ColoredBox(color: p.surface.withValues(alpha: BusinElevation.glassOpacity), child: child),
              Positioned.fill(child: Contour(color: threadColor(text: p.fg, background: p.surface, mix: 0.16), style: ContourStyle.bar)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone's navigation: a floating glass bar with icon over label and a highlight that slides between items with
/// an elastic stretch (the portal's bar). Place it at the bottom of a `Stack`; [AdaptiveScaffold] does that, adds the
/// system safe area and hides it while the keyboard is open.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.destinations, required this.currentIndex, required this.onSelected});

  final List<BusinDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const double height = 68;
  static const double _pad = 8;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    return _GlassPanel(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(_pad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;
              return Stack(
                children: [
                  _SlidingHighlight(
                    axis: Axis.horizontal,
                    count: destinations.length,
                    index: currentIndex,
                    itemExtent: itemWidth,
                    gap: 0,
                    color: p.fg.withValues(alpha: 0.09),
                    crossExtent: constraints.maxHeight,
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        SizedBox(
                          width: itemWidth,
                          height: constraints.maxHeight,
                          child: _NavItem(destination: destinations[i], selected: i == currentIndex, onTap: () => onSelected(i), labelSize: 11),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The tablet's navigation: a slim floating glass rail down the left edge, brand mark on top, the same items and the
/// same elastic highlight running vertically.
class BusinNavRail extends StatelessWidget {
  const BusinNavRail({super.key, required this.destinations, required this.currentIndex, required this.onSelected, this.header});

  final List<BusinDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Shown above the items: the brand mark.
  final Widget? header;

  static const double width = 88;
  static const double _item = 64;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    return SizedBox(
      width: width,
      child: _GlassPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              if (header != null) ...[header!, const SizedBox(height: 20)],
              SizedBox(
                height: destinations.length * (_item + _gap) - _gap,
                child: Stack(
                  children: [
                    _SlidingHighlight(
                      axis: Axis.vertical,
                      count: destinations.length,
                      index: currentIndex,
                      itemExtent: _item,
                      gap: _gap,
                      color: p.fg.withValues(alpha: 0.09),
                      crossExtent: width - 16,
                    ),
                    Column(
                      children: [
                        for (var i = 0; i < destinations.length; i++) ...[
                          if (i > 0) const SizedBox(height: _gap),
                          SizedBox(
                            height: _item,
                            width: double.infinity,
                            child: _NavItem(destination: destinations[i], selected: i == currentIndex, onTap: () => onSelected(i), labelSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
