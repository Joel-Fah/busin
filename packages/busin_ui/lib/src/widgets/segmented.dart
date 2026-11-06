import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'haptics.dart';

/// One choice in a [BusinSegmented].
class BusinSegment<T> {
  const BusinSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final List<List<dynamic>>? icon;
}

/// A short row of exclusive choices (theme: system, light, dark). The chosen one is a raised pill that slides in; each
/// choice has its words, and a screen reader hears a group with one choice selected. Every choice is a full-size tap
/// target.
class BusinSegmented<T> extends StatelessWidget {
  const BusinSegmented({super.key, required this.segments, required this.selected, required this.onChanged, required this.groupLabel});

  final List<BusinSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// What the group is, for screen readers ("Theme").
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final index = segments.indexWhere((s) => s.value == selected);
    final duration = BusinMotion.of(context, BusinMotion.normal);

    return Semantics(
      container: true,
      label: groupLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.md)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / segments.length;
              return Stack(
                children: [
                  // The pill under the chosen label.
                  if (index >= 0)
                    AnimatedPositioned(
                      duration: duration,
                      curve: BusinMotion.soft,
                      left: width * index,
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(BusinRadius.sm),
                          boxShadow: BusinElevation.soft(Theme.of(context).brightness),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      for (final segment in segments)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: segment.value == selected,
                            inMutuallyExclusiveGroup: true,
                            label: segment.label,
                            excludeSemantics: true,
                            onTap: () => onChanged(segment.value),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (segment.value == selected) return;
                                BusinHaptics.selection();
                                onChanged(segment.value);
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 44),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (segment.icon != null) ...[
                                        HugeIcon(icon: segment.icon!, size: 18, color: segment.value == selected ? p.fg : p.muted),
                                        const SizedBox(width: 6),
                                      ],
                                      Flexible(
                                        child: Text(
                                          segment.label,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: text.labelLarge?.copyWith(
                                            color: segment.value == selected ? p.fg : p.muted,
                                            fontWeight: segment.value == selected ? FontWeight.w800 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
