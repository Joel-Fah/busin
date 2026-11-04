import 'package:flutter/material.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// How a status is toned. The label always comes with it, so colour is never the only signal.
enum StatusTone { neutral, ok, warn, bad, info }

/// A small status label (Approved, Running, Suspended) in its tone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final (Color fill, Color ink) = switch (tone) {
      StatusTone.ok => (p.okBg, p.ok),
      StatusTone.warn => (p.warnBg, p.warn),
      StatusTone.bad => (p.badBg, p.bad),
      StatusTone.info => (p.infoBg, p.info),
      StatusTone.neutral => (p.surface2, p.muted),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(BusinRadius.xs)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: BusinSpace.x1 + 1),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
