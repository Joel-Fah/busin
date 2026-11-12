import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../painters/contour.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// Where something stands in a short process, as a line of stages: done ones ticked, the current one ringed in the brand
/// orange (or in the danger colour with a cross when [failed]), the coming ones quiet. The stitched thread joins them.
/// It always says the same in words as it shows: each stage has its label, and a screen reader hears "Step 2 of 3".
class StepLine extends StatelessWidget {
  const StepLine({super.key, required this.labels, required this.current, this.failed = false, this.stepSemantics});

  final List<String> labels;

  /// Index of the stage the process is at. Stages before it are done; equal to the length means all done.
  final int current;

  /// The current stage ended badly (a rejection): it shows a cross and no later stage is reached.
  final bool failed;

  /// How to say a stage aloud: `(number, total, label)`.
  final String Function(int number, int total, String label)? stepSemantics;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: SizedBox(height: 2, child: CustomPaint(painter: _Thread(color: i <= current && !(failed && i == current) ? p.ok : p.line))),
              ),
            ),
          Semantics(
            container: true,
            label: (stepSemantics ?? (n, t, l) => '$n/$t $l')(i + 1, labels.length, labels[i]),
            child: ExcludeSemantics(
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    _Dot(state: _stateOf(i)),
                    const SizedBox(height: BusinSpace.x2),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: text.labelSmall?.copyWith(color: i <= current ? p.fg : p.muted, fontWeight: i == current ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  _StepState _stateOf(int i) {
    if (i < current) return _StepState.done;
    if (i == current) return failed ? _StepState.failed : (current >= labels.length ? _StepState.done : _StepState.current);
    return _StepState.todo;
  }
}

enum _StepState { done, current, failed, todo }

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final (Color fill, Color ink, List<List<dynamic>>? icon, Color ring) = switch (state) {
      _StepState.done => (p.okBg, p.ok, HugeIcons.strokeRoundedTick02, p.ok),
      _StepState.current => (p.warnBg, p.warn, HugeIcons.strokeRoundedClock01, BusinPalette.orange),
      _StepState.failed => (p.badBg, p.bad, HugeIcons.strokeRoundedCancel01, p.bad),
      _StepState.todo => (p.surface2, p.muted, null, p.line),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(BusinRadius.xs + 2), border: Border.all(color: ring, width: state == _StepState.current ? 2 : 1)),
      child: icon == null ? null : Center(child: HugeIcon(icon: icon, size: 18, color: ink)),
    );
  }
}

class _Thread extends CustomPainter {
  const _Thread({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in dashSegments(size.width, 4, 5)) {
      canvas.drawLine(Offset(from, size.height / 2), Offset(to, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_Thread old) => old.color != color;
}
