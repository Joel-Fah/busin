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

/// The orange marker under a headline (the portal's `MarkedTitle`). Decoration only: the text is drawn on top,
/// undistorted, and the marker is hidden from screen readers. Needs no filter: the hand-drawn edge is a seeded path.
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
    final em = resolved.fontSize ?? 16;
    final mark = (color ?? BusinPalette.orange).withValues(alpha: opacity);

    return CustomPaint(
      painter: _MarkPainter(color: mark, em: em, seed: text.hashCode),
      child: Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color, required this.em, required this.seed});

  final Color color;
  final double em;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(markerPath(size, em: em, seed: seed), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.em != em || old.seed != seed;
}
