import 'package:flutter/animation.dart';

/// The two edges of the sliding highlight while it moves from one item to another, as in the portal's elastic tabs:
/// the edge in the direction of travel (the leading one) runs ahead with a little overshoot (0.5 s, back-out), and the
/// other edge follows 90 ms later (0.45 s, cubic-out), so the highlight stretches and then settles.
///
/// Spans are `(start, end)` along the axis of travel. [t] is progress through the whole move, 0 to 1.
(double, double) indicatorEdges({required (double, double) from, required (double, double) to, required double t}) {
  const totalMs = 540.0;
  final elapsed = t.clamp(0.0, 1.0) * totalMs;
  final lead = Curves.easeOutBack.transform((elapsed / 500).clamp(0.0, 1.0));
  final trail = Curves.easeOutCubic.transform(((elapsed - 90) / 450).clamp(0.0, 1.0));

  final forward = to.$1 >= from.$1;
  final start = from.$1 + (to.$1 - from.$1) * (forward ? trail : lead);
  final end = from.$2 + (to.$2 - from.$2) * (forward ? lead : trail);
  // The overshoot must never fold the highlight over itself.
  return end > start ? (start, end) : (start, start + 1);
}

/// The total time a move takes.
const Duration indicatorDuration = Duration(milliseconds: 540);
