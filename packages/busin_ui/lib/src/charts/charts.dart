import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// One bar of a [BusinBarChart]: its label under the axis and its segments, stacked from the bottom in the order of the
/// chart's colours.
class ChartBar {
  const ChartBar({required this.label, required this.segments});

  final String label;
  final List<double> segments;

  double get total => segments.fold(0, (a, b) => a + b);
}

/// A named colour under a chart. State is never told by colour alone: every series has its label here.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<({Color color, String label})> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = BusinPalette.of(context);
    return Wrap(
      spacing: BusinSpace.x4,
      runSpacing: BusinSpace.x2,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3)),
                child: const SizedBox(width: 12, height: 12),
              ),
              const SizedBox(width: BusinSpace.x2),
              Text(item.label, style: text.bodySmall?.copyWith(color: p.muted)),
            ],
          ),
      ],
    );
  }
}

/// Stacked bars over time (for example trips on time and late, one bar per week). The whole chart is one image for a
/// screen reader, described by [semanticLabel]; the numbers it shows are also given in text on the page. Tapping a bar
/// (or sliding across the bars) picks it: the others dim and a line above the chart gives its label, its total and, with
/// [seriesLabels], each part ("On time 8, Late 2"). Tapping it again puts the chart back.
class BusinBarChart extends StatefulWidget {
  const BusinBarChart({super.key, required this.bars, required this.colors, required this.semanticLabel, this.seriesLabels, this.height = 168});

  final List<ChartBar> bars;
  final List<Color> colors;
  final String semanticLabel;

  /// The name of each segment, in the order of [colors] (the legend's words), for the picked bar's line.
  final List<String>? seriesLabels;
  final double height;

  @override
  State<BusinBarChart> createState() => _BusinBarChartState();
}

class _BusinBarChartState extends State<BusinBarChart> {
  int? _picked;

  @override
  void didUpdateWidget(BusinBarChart old) {
    super.didUpdateWidget(old);
    if (_picked != null && _picked! >= widget.bars.length) _picked = null;
  }

  /// The bar under [dx], given the chart's [width] (the same slots the painter uses).
  int? _barAt(double dx, double width) {
    final bars = widget.bars.length;
    if (bars == 0) return null;
    final slot = (width - _axisWidth) / bars;
    if (slot <= 0 || dx < _axisWidth) return null;
    return ((dx - _axisWidth) / slot).floor().clamp(0, bars - 1);
  }

  void _pick(int? index, {bool toggle = false}) {
    if (index == null) return;
    setState(() => _picked = toggle && _picked == index ? null : index);
  }

  /// "Week of 2 Nov: 12 (On time 8, Late 2, Field trips 1, Not run 1)". Parts at zero are left out.
  String _readout(ChartBar bar) {
    final names = widget.seriesLabels;
    final total = _plain(bar.total);
    if (names == null || bar.segments.length < 2) return '${bar.label}: $total';
    final parts = [
      for (var s = 0; s < bar.segments.length && s < names.length; s++)
        if (bar.segments[s] > 0) '${names[s]} ${_plain(bar.segments[s])}',
    ];
    return parts.isEmpty ? '${bar.label}: $total' : '${bar.label}: $total (${parts.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final style = text.labelSmall?.copyWith(color: p.muted) ?? TextStyle(color: p.muted, fontSize: 11);
    final picked = _picked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: BusinMotion.of(context, BusinMotion.fast),
          alignment: Alignment.topCenter,
          child: picked == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: BusinSpace.x2),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _readout(widget.bars[picked]),
                      key: const ValueKey('bar-readout'),
                      style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
        ),
        Semantics(
          label: widget.semanticLabel,
          image: true,
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _pick(_barAt(d.localPosition.dx, constraints.maxWidth), toggle: true),
              onHorizontalDragUpdate: (d) => _pick(_barAt(d.localPosition.dx, constraints.maxWidth)),
              child: _Grow(
                builder: (t) => CustomPaint(
                  size: Size(double.infinity, widget.height),
                  painter: _BarPainter(bars: widget.bars, colors: widget.colors, grid: p.line, label: style, progress: t, picked: picked),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A line over time with values that may be missing (a week without data leaves a gap rather than a fake zero). [min]
/// and [max] fix the scale; [format] writes the axis values (for example as percentages).
class BusinLineChart extends StatelessWidget {
  const BusinLineChart({
    super.key,
    required this.points,
    required this.labels,
    required this.color,
    required this.semanticLabel,
    required this.format,
    this.min = 0,
    this.max = 1,
    this.target,
    this.height = 168,
  });

  final List<double?> points;
  final List<String> labels;
  final Color color;
  final String semanticLabel;
  final String Function(double value) format;
  final double min;
  final double max;

  /// A dashed line at a goal (for example 90% on time).
  final double? target;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: p.muted) ?? TextStyle(color: p.muted, fontSize: 11);
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: _Grow(
        builder: (t) => CustomPaint(
          size: Size(double.infinity, height),
          painter: _LinePainter(
            points: points,
            labels: labels,
            color: color,
            grid: p.line,
            surface: p.surface,
            label: style,
            format: format,
            min: min,
            max: max,
            target: target,
            progress: t,
          ),
        ),
      ),
    );
  }
}

/// Grows the chart in once, unless the phone asks for less motion.
class _Grow extends StatelessWidget {
  const _Grow({required this.builder});

  final Widget Function(double t) builder;

  @override
  Widget build(BuildContext context) {
    if (BusinMotion.reduced(context)) return builder(1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: BusinMotion.slow,
      curve: BusinMotion.soft,
      builder: (_, t, _) => builder(t),
    );
  }
}

const _axisWidth = 30.0;
const _labelsHeight = 18.0;

/// Room for one label under the axis, centred on its bar or point ("24 Aug" fits).
const _labelWidth = 64.0;

/// Which labels to draw so they do not run into each other: every one when they fit, otherwise every second or third.
bool _showLabel(int index, int count, double width) {
  final step = math.max(1, (count * 44 / math.max(width, 1)).ceil());
  return (count - 1 - index) % step == 0;
}

void _text(Canvas canvas, String value, TextStyle style, Offset at, {TextAlign align = TextAlign.center, double width = 40}) {
  // One line; a label that is still too long ends in an ellipsis rather than losing a word.
  final painter = TextPainter(text: TextSpan(text: value, style: style), textDirection: TextDirection.ltr, textAlign: align, maxLines: 1, ellipsis: '…')
    ..layout(minWidth: width, maxWidth: width);
  painter.paint(canvas, at);
}

/// A rounded step up from [value] for the top of the scale (1, 2, 5, 10, 20, 50...).
double _niceMax(double value) {
  if (value <= 0) return 1;
  final magnitude = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  for (final m in [1, 2, 5, 10]) {
    if (value <= m * magnitude) return m * magnitude;
  }
  return 10 * magnitude;
}

String _plain(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _BarPainter extends CustomPainter {
  _BarPainter({required this.bars, required this.colors, required this.grid, required this.label, required this.progress, this.picked});

  final List<ChartBar> bars;
  final List<Color> colors;
  final Color grid;
  final TextStyle label;
  final double progress;

  /// The bar picked by a tap: the others are drawn faded.
  final int? picked;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(_axisWidth, 4, size.width - _axisWidth, size.height - _labelsHeight - 8);
    final top = _niceMax(bars.fold(0.0, (m, b) => math.max(m, b.total)));
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = chart.bottom - chart.height * f;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), line);
      _text(canvas, _plain(top * f), label, Offset(0, y - 7), align: TextAlign.right, width: _axisWidth - 6);
    }
    if (bars.isEmpty) return;
    final slot = chart.width / bars.length;
    final barWidth = math.min(28.0, slot * 0.62);
    for (var i = 0; i < bars.length; i++) {
      final x = chart.left + slot * i + (slot - barWidth) / 2;
      var y = chart.bottom;
      final bar = bars[i];
      for (var s = 0; s < bar.segments.length; s++) {
        final h = chart.height * (bar.segments[s] / top) * progress;
        if (h <= 0) continue;
        final rect = Rect.fromLTWH(x, y - h, barWidth, h);
        // Only the top of the stack is rounded.
        final isTop = bar.segments.skip(s + 1).every((v) => v <= 0);
        final r = isTop ? const Radius.circular(4) : Radius.zero;
        final colour = colors[s % colors.length];
        final faded = picked != null && picked != i;
        canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: r, topRight: r), Paint()..color = faded ? colour.withValues(alpha: colour.a * 0.3) : colour);
        y -= h;
      }
      if (_showLabel(i, bars.length, chart.width)) {
        _text(canvas, bar.label, label, Offset(chart.left + slot * i + slot / 2 - _labelWidth / 2, chart.bottom + 6), width: _labelWidth);
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.bars != bars || old.progress != progress || old.grid != grid || old.colors != colors || old.picked != picked;
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.labels,
    required this.color,
    required this.grid,
    required this.surface,
    required this.label,
    required this.format,
    required this.min,
    required this.max,
    required this.target,
    required this.progress,
  });

  final List<double?> points;
  final List<String> labels;
  final Color color;
  final Color grid;
  final Color surface;
  final TextStyle label;
  final String Function(double value) format;
  final double min;
  final double max;
  final double? target;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Wider than the bar chart's axis: it says "100%".
    const axis = _axisWidth + 12;
    final chart = Rect.fromLTWH(axis + 4, 8, size.width - axis - 12, size.height - _labelsHeight - 14);
    double yOf(double v) => chart.bottom - chart.height * ((v - min) / (max - min)).clamp(0, 1);
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final v = min + (max - min) * f;
      canvas.drawLine(Offset(chart.left, yOf(v)), Offset(chart.right, yOf(v)), line);
      _text(canvas, format(v), label, Offset(0, yOf(v) - 7), align: TextAlign.right, width: axis);
    }
    final goal = target;
    if (goal != null) {
      final y = yOf(goal);
      final dash = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 1.2;
      for (var x = chart.left; x < chart.right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, chart.right), y), dash);
      }
    }
    if (points.isEmpty) return;
    final step = points.length == 1 ? 0.0 : chart.width / (points.length - 1);
    double xOf(int i) => points.length == 1 ? chart.center.dx : chart.left + step * i;
    // The line is drawn up to [progress] of its length, in runs between missing values.
    final shown = (points.length * progress).ceil();
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    Path? run;
    Path? area;
    int? runStart;
    void close(int end) {
      if (run == null) return;
      canvas.drawPath(area!..lineTo(xOf(end), chart.bottom)..lineTo(xOf(runStart!), chart.bottom)..close(), fill);
      canvas.drawPath(run!, stroke);
      run = null;
      area = null;
    }

    for (var i = 0; i < shown; i++) {
      final v = points[i];
      if (v == null) {
        close(i - 1);
        continue;
      }
      final at = Offset(xOf(i), yOf(v));
      if (run == null) {
        run = Path()..moveTo(at.dx, at.dy);
        area = Path()..moveTo(at.dx, at.dy);
        runStart = i;
      } else {
        run!.lineTo(at.dx, at.dy);
        area!.lineTo(at.dx, at.dy);
      }
    }
    var last = shown - 1;
    while (last >= 0 && points[last] == null) {
      last--;
    }
    if (last >= 0) close(last);
    for (var i = 0; i < shown; i++) {
      final v = points[i];
      if (v == null) continue;
      final at = Offset(xOf(i), yOf(v));
      canvas.drawCircle(at, 4, Paint()..color = surface);
      canvas.drawCircle(at, 3, Paint()..color = color);
    }
    for (var i = 0; i < labels.length; i++) {
      if (_showLabel(i, labels.length, chart.width)) _text(canvas, labels[i], label, Offset(xOf(i) - _labelWidth / 2, chart.bottom + 6), width: _labelWidth);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points || old.progress != progress || old.color != color || old.grid != grid;
}
