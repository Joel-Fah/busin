import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens/shape.dart';

/// Where the dashes of a thread of [length] start and end, for a pattern of [dash] then [gap], with the whole pattern
/// slid forward by [offset] (a negative offset slides it back). The offset wraps, so a thread can slide round and round.
/// Pure, so it is tested without drawing.
List<(double, double)> dashSegments(double length, double dash, double gap, {double offset = 0}) {
  if (length <= 0 || dash <= 0 || gap < 0) return const [];
  final period = dash + gap;
  // Start one period early so a dash that has slid in from before the start still shows.
  var start = (offset % period) - period;
  final segments = <(double, double)>[];
  for (; start < length; start += period) {
    final from = start.clamp(0.0, length);
    final to = (start + dash).clamp(0.0, length);
    if (to > from) segments.add((from, to));
  }
  return segments;
}

/// The colour a thread takes on a surface: the element's own text colour mixed into its own background, so the
/// thread is tonal and never changes on press (the portal's `--thread-color` rule).
Color threadColor({required Color text, required Color background, double mix = 0.26}) => Color.lerp(background, text, mix)!;

/// Draws the stitched thread: a dashed rounded rectangle [inset] logical pixels inside its box, with round caps. The
/// corner follows the nested-radius rule: [radius] is the container's, the thread's own corner is that minus the inset.
class ContourPainter extends CustomPainter {
  const ContourPainter({
    required this.color,
    this.radius = BusinRadius.lg,
    this.inset = 16,
    this.dash = 9,
    this.gap = 7,
    this.width = 1.5,
    this.slide = 0,
  });

  final Color color;

  /// The corner radius of the container the thread sits in.
  final double radius;

  /// Distance from the container's edge to the thread.
  final double inset;
  final double dash;
  final double gap;
  final double width;

  /// How far the pattern has slid forward, in multiples of one dash-and-gap period (the portal slides three).
  final double slide;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    if (box.width <= 0 || box.height <= 0) return;

    final corner = BusinRadius.innerRadius(radius, inset);
    final path = Path()..addRRect(RRect.fromRectAndRadius(box, Radius.circular(corner)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      for (final (from, to) in dashSegments(metric.length, dash, gap, offset: slide * (dash + gap))) {
        canvas.drawPath(metric.extractPath(from, to), paint);
      }
    }
  }

  @override
  bool shouldRepaint(ContourPainter old) =>
      old.color != color || old.radius != radius || old.inset != inset || old.dash != dash || old.gap != gap || old.width != width || old.slide != slide;
}

/// The portal's presets, so a card, a bar and a button stitch the same way everywhere.
class ContourStyle {
  const ContourStyle({required this.radius, required this.inset, required this.dash, required this.gap, this.live = false});

  final double radius;
  final double inset;
  final double dash;
  final double gap;

  /// Slides when pressed or focused (buttons, links, empty states). Cards and bars stay still.
  final bool live;

  static const card = ContourStyle(radius: 28, inset: 12, dash: 9, gap: 7);
  static const bar = ContourStyle(radius: 28, inset: 6, dash: 6, gap: 6);
  static const button = ContourStyle(radius: 16, inset: 4, dash: 4, gap: 5, live: true);
  static const insightCard = ContourStyle(radius: 20, inset: 8, dash: 5, gap: 5);
  static const sheet = ContourStyle(radius: 36, inset: 14, dash: 9, gap: 7);
  static const banner = ContourStyle(radius: 28, inset: 14, dash: 9, gap: 7);
  static const emptyState = ContourStyle(radius: 28, inset: 0, dash: 9, gap: 7, live: true);
}

/// A thread drawn over its parent: place it with `Positioned.fill` in a `Stack`. When [live] and [active] it slides
/// forward by three periods (and thickens a little) over 900 ms, and back when [active] goes false. The thread never
/// takes pointer events, and under reduced motion it does not move.
class Contour extends StatelessWidget {
  const Contour({super.key, required this.color, this.style = ContourStyle.card, this.active = false, this.width = 1.5});

  final Color color;
  final ContourStyle style;

  /// For a live thread: pressed or focused.
  final bool active;
  final double width;

  @override
  Widget build(BuildContext context) {
    CustomPaint paint(double slide, double lineWidth) => CustomPaint(
          painter: ContourPainter(
            color: color,
            radius: style.radius,
            inset: style.inset,
            dash: style.dash,
            gap: style.gap,
            width: lineWidth,
            slide: slide,
          ),
          size: Size.infinite,
        );

    if (!style.live || BusinMotion.reduced(context)) return IgnorePointer(child: paint(0, width));

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: active ? 1 : 0),
        duration: const Duration(milliseconds: 900),
        curve: BusinMotion.soft,
        builder: (context, t, _) => paint(3 * t, width + 0.5 * t),
      ),
    );
  }
}

/// A child with a thread drawn over it: [child] sizes the box, the thread follows. For quick use where a full
/// `Stack` is overkill.
class ContourBox extends StatelessWidget {
  const ContourBox({super.key, required this.color, required this.child, this.style = ContourStyle.card, this.active = false});

  final Color color;
  final ContourStyle style;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned.fill(child: Contour(color: color, style: style, active: active)),
        ],
      );
}

/// Used by tests and by code that wants the path the painter follows.
Path contourPath(Size size, {required double radius, required double inset}) {
  final box = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
  return Path()..addRRect(RRect.fromRectAndRadius(box, Radius.circular(BusinRadius.innerRadius(radius, inset))));
}

/// Total length of the path the thread follows, for tests.
double contourLength(Size size, {required double radius, required double inset}) =>
    contourPath(size, radius: radius, inset: inset).computeMetrics().fold<double>(0, (sum, ui.PathMetric m) => sum + m.length);
