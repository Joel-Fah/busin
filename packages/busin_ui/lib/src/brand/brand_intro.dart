import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../tokens/shape.dart';
import 'brand_paths.dart';

/// Where the opening animation stands at time [t] (seconds), for [count] shapes: the portal's timeline. Each outline draws
/// itself over 1.5 s (cubic in and out), a tenth of a second after the one before; the fill starts 0.25 s before the last
/// outline ends and takes 0.7 s (quadratic out) while the outline fades over 0.4 s; then there is a short hold.
class IntroFrame {
  const IntroFrame({required this.stroke, required this.fill, required this.strokeOpacity});

  /// How much of each outline is drawn, 0 to 1, one per shape.
  final List<double> stroke;

  /// The opacity of the fill, 0 to 1.
  final double fill;

  /// The opacity of the outline, 1 down to 0 as the fill arrives.
  final double strokeOpacity;
}

class IntroTiming {
  const IntroTiming._();

  static const double draw = 1.5;
  static const double stagger = 0.12;
  static const double fillDuration = 0.7;
  static const double fadeDuration = 0.4;
  static const double overlap = 0.25;
  static const double hold = 0.35;

  /// When the last outline finishes drawing.
  static double drawEnd(int count) => draw + stagger * (count - 1);

  /// When the fill begins.
  static double fillStart(int count) => drawEnd(count) - overlap;

  /// The whole animation, seconds.
  static double total(int count) => fillStart(count) + fillDuration + hold;
}

double _unit(double v) => v.clamp(0.0, 1.0);

IntroFrame introFrame(double t, int count) => IntroFrame(
      stroke: [for (var i = 0; i < count; i++) Curves.easeInOutCubic.transform(_unit((t - IntroTiming.stagger * i) / IntroTiming.draw))],
      fill: Curves.easeOutQuad.transform(_unit((t - IntroTiming.fillStart(count)) / IntroTiming.fillDuration)),
      strokeOpacity: 1 - _unit((t - IntroTiming.fillStart(count)) / IntroTiming.fadeDuration),
    );

/// The finished picture: every shape filled, no outline. What the animation ends on, and what [BrandMark] shows.
final IntroFrame finishedBrandFrame = IntroFrame(stroke: List.filled(brandPaths.length, 1.0), fill: 1, strokeOpacity: 0);

/// The wordmark parsed once: each shape as a path, with its fill rule.
final List<({Path path, bool evenOdd})> _shapes = [
  for (final shape in brandPaths)
    (path: parseSvgPathData(shape.d)..fillType = shape.evenOdd ? PathFillType.evenOdd : PathFillType.nonZero, evenOdd: shape.evenOdd),
];

class BrandIntroPainter extends CustomPainter {
  const BrandIntroPainter({required this.frame, required this.color, this.strokeWidth = 1.4});

  final IntroFrame frame;
  final Color color;

  /// In the logo's own units (the portal uses 1.4).
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / brandWidth, size.height / brandHeight);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: color.a * frame.strokeOpacity);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: color.a * frame.fill);

    for (var i = 0; i < _shapes.length; i++) {
      final shape = _shapes[i];
      if (frame.fill > 0) canvas.drawPath(shape.path, fill);
      final progress = frame.stroke[i];
      if (progress > 0 && frame.strokeOpacity > 0) {
        for (final metric in shape.path.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * progress), outline);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandIntroPainter old) => old.frame != frame || old.color != color || old.strokeWidth != strokeWidth;
}

/// The opening animation: the wordmark draws its outline, then fills in. [width] is its width in logical pixels (the
/// height follows the logo's proportions). Tapping anywhere skips ahead quickly. Under reduced motion it shows the
/// finished mark for half a second and moves on. [onDone] is called once, when it ends or is skipped.
class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.color, required this.onDone, this.width = 144});

  final Color color;
  final VoidCallback onDone;
  final double width;

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _total = IntroTiming.total(brandPaths.length);
  Timer? _reducedTimer;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: (_total * 1000).round()))..addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (BusinMotion.reduced(context)) {
      // The finished mark, held briefly: no movement.
      _controller.value = (IntroTiming.fillStart(brandPaths.length) + IntroTiming.fillDuration) / _total;
      _reducedTimer = Timer(const Duration(milliseconds: 500), _finish);
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  void _skip() {
    if (_done || _reducedTimer != null) return;
    // Eight times faster, as in the portal: the rest plays out in a blink.
    final remaining = (1 - _controller.value) * _total / 8;
    _controller.animateTo(1, duration: Duration(milliseconds: (remaining * 1000).round().clamp(1, 600)), curve: Curves.linear);
  }

  @override
  void dispose() {
    _reducedTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * brandHeight / brandWidth;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _skip(),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size(widget.width, height),
            painter: BrandIntroPainter(frame: introFrame(_controller.value * _total, brandPaths.length), color: widget.color),
          ),
        ),
      ),
    );
  }
}
