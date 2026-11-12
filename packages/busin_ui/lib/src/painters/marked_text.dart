import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/palette.dart';

/// The outline of the rough marker stroke for a text box: a bar [em] tall times 0.4, running 0.15 em past each end,
/// with edges that wobble by hand-drawn amounts. [seed] makes the wobble the same every time for the same text.
Path markerPath(Size box, {required double em, int seed = 7}) {
  final random = math.Random(seed);
  final height = em * 0.4;
  final left = -em * 0.15;
  final right = box.width + em * 0.15;
  final bottom = box.height - em * 0.02;
  final top = bottom - height;
  double wobble() => (random.nextDouble() - 0.5) * em * 0.12;

  final steps = math.max(3, ((right - left) / (em * 1.4)).round());
  final path = Path()..moveTo(left, top + height * 0.5 + wobble());
  // Along the top, left to right.
  for (var i = 0; i <= steps; i++) {
    final x = left + (right - left) * i / steps;
    path.lineTo(x, top + wobble());
  }
  // Round the right end, then back along the bottom.
  path.lineTo(right + em * 0.04, top + height * 0.5 + wobble());
  for (var i = steps; i >= 0; i--) {
    final x = left + (right - left) * i / steps;
    path.lineTo(x, bottom + wobble());
  }
  path.close();
  return path;
}

/// Where the marker goes for [text] laid out in [maxWidth]: under the *last* line only, as wide as that line. A
/// one-line headline gets the whole line; a two-line one gets the second. Returns the line's left edge and width.
({double left, double width}) lastLineSpan(TextSpan text, {required double maxWidth, required TextDirection direction, TextAlign align = TextAlign.start, TextScaler scaler = TextScaler.noScaling, int? maxLines}) {
  final painter = TextPainter(text: text, textDirection: direction, textAlign: align, textScaler: scaler, maxLines: maxLines)..layout(maxWidth: maxWidth);
  final lines = painter.computeLineMetrics();
  painter.dispose();
  if (lines.isEmpty) return (left: 0, width: 0);
  final last = lines.last;
  return (left: last.left, width: last.width);
}

/// The orange marker under a headline (the portal's `MarkedTitle`). Decoration only: the text is drawn on top,
/// undistorted, and the marker is hidden from screen readers. With a headline that wraps, the marker sits under the last
/// line only. Needs no filter: the hand-drawn edge is a seeded path.
class MarkedText extends StatelessWidget {
  const MarkedText(this.text, {super.key, this.style, this.color, this.opacity = 0.55, this.textAlign, this.maxLines});

  final String text;
  final TextStyle? style;

  /// The marker colour; the brand orange by default.
  final Color? color;

  /// 0.55 in dialogs and 0.7 on the dark banner, as in the portal.
  final double opacity;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    return CustomPaint(
      painter: MarkerPainter(
        text: TextSpan(text: text, style: resolved),
        color: (color ?? BusinPalette.orange).withValues(alpha: opacity),
        em: resolved.fontSize ?? 16,
        seed: text.hashCode,
        direction: Directionality.of(context),
        align: textAlign ?? TextAlign.start,
        scaler: MediaQuery.textScalerOf(context),
        maxLines: maxLines,
      ),
      child: Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis),
    );
  }
}

class MarkerPainter extends CustomPainter {
  const MarkerPainter({required this.text, required this.color, required this.em, required this.seed, required this.direction, this.align = TextAlign.start, this.scaler = TextScaler.noScaling, this.maxLines});

  final TextSpan text;
  final Color color;
  final double em;
  final int seed;
  final TextDirection direction;
  final TextAlign align;
  final TextScaler scaler;
  final int? maxLines;

  /// The last line's left edge and width in a box [width] wide: the marker spans exactly this. The box is as wide as the
  /// widest line, so laying the text out in it breaks the lines where the real text broke them.
  ({double left, double width}) spanFor(double width) => lastLineSpan(text, maxWidth: width, direction: direction, align: align, scaler: scaler, maxLines: maxLines);

  @override
  void paint(Canvas canvas, Size size) {
    final span = spanFor(size.width);
    if (span.width <= 0) return;
    canvas.save();
    canvas.translate(span.left, 0);
    canvas.drawPath(markerPath(Size(span.width, size.height), em: em, seed: seed), Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MarkerPainter old) =>
      old.text != text || old.color != color || old.em != em || old.seed != seed || old.align != align || old.scaler != scaler || old.maxLines != maxLines;
}
