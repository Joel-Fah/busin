import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// What a list shows when there is nothing in it, or when it could not load: an icon, a title, a
/// short explanation and an optional action (for example "Try again"). Every list has one.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.body, this.icon, this.action});

  final String title;
  final String? body;
  final List<List<dynamic>>? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BusinSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.lg)),
                child: Padding(
                  padding: const EdgeInsets.all(BusinSpace.x5),
                  child: HugeIcon(icon: icon!, size: 32, color: p.muted),
                ),
              ),
              const SizedBox(height: BusinSpace.x5),
            ],
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: BusinSpace.x2),
              Text(body!, style: text.bodyMedium?.copyWith(color: p.muted), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: BusinSpace.x5), action!],
          ],
        ),
      ),
    );
  }
}
