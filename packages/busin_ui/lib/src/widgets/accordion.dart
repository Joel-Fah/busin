import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'busin_card.dart';
import 'haptics.dart';

/// A card that opens to show more: a title row that stays, and a body that slides open under it. The one that matters
/// now is given [initiallyOpen]; the others wait closed. A screen reader hears whether it is expanded, and the whole
/// header is the tap target.
class BusinAccordion extends StatefulWidget {
  const BusinAccordion({super.key, required this.title, required this.child, this.trailing, this.initiallyOpen = false, this.semanticLabel});

  /// The row that is always visible.
  final Widget title;

  /// Shown under the title (a status chip).
  final Widget? trailing;
  final Widget child;
  final bool initiallyOpen;

  /// What a screen reader says for the header, if the title's own text is not enough.
  final String? semanticLabel;

  @override
  State<BusinAccordion> createState() => _BusinAccordionState();
}

class _BusinAccordionState extends State<BusinAccordion> {
  late bool _open = widget.initiallyOpen;

  void _toggle() {
    BusinHaptics.selection();
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final duration = BusinMotion.of(context, BusinMotion.normal);
    return BusinCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label: widget.semanticLabel,
            onTap: _toggle,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(BusinRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5, vertical: BusinSpace.x4),
                child: Row(
                  children: [
                    // The title, and under it the status: stacked, so nothing is squeezed on a narrow screen at large text.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.title,
                          if (widget.trailing != null) ...[const SizedBox(height: BusinSpace.x2), widget.trailing!],
                        ],
                      ),
                    ),
                    const SizedBox(width: BusinSpace.x2),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: duration,
                      curve: BusinMotion.soft,
                      child: HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, size: 20, color: p.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: BusinMotion.soft,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(padding: const EdgeInsets.fromLTRB(BusinSpace.x5, 0, BusinSpace.x5, BusinSpace.x5), child: widget.child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
