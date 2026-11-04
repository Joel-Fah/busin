import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// One number with its name, for the top of a screen: "12 Trips today". The value is read first by
/// screen readers, then the label.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$value $label',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(BusinRadius.lg)),
          child: Padding(
            padding: const EdgeInsets.all(BusinSpace.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  HugeIcon(icon: icon!, size: 22, color: p.muted),
                  const SizedBox(height: BusinSpace.x3),
                ],
                Text(value, style: text.headlineMedium),
                const SizedBox(height: BusinSpace.x1),
                Text(label, style: text.bodyMedium?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
