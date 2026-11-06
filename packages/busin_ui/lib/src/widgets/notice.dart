import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'status_chip.dart';

/// A message with a tone, the portal's notice: a tinted panel with an icon and words, for things the person must read
/// (a rejection and its reason, a failed send). Errors are announced to screen readers. Never colour alone: the icon and
/// the words carry the meaning too.
class Notice extends StatelessWidget {
  const Notice({super.key, required this.child, this.tone = StatusTone.info, this.icon, this.title});

  final Widget child;
  final StatusTone tone;
  final List<List<dynamic>>? icon;

  /// A short bold line above the body.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final (Color fill, Color ink, List<List<dynamic>> defaultIcon) = switch (tone) {
      StatusTone.ok => (p.okBg, p.ok, HugeIcons.strokeRoundedCheckmarkCircle02),
      StatusTone.warn => (p.warnBg, p.warn, HugeIcons.strokeRoundedAlert02),
      StatusTone.bad => (p.badBg, p.bad, HugeIcons.strokeRoundedAlert02),
      StatusTone.info => (p.infoBg, p.info, HugeIcons.strokeRoundedInformationCircle),
      StatusTone.neutral => (p.surface2, p.muted, HugeIcons.strokeRoundedInformationCircle),
    };
    return Semantics(
      liveRegion: tone == StatusTone.bad,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(BusinRadius.md)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x3 + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: HugeIcon(icon: icon ?? defaultIcon, size: 20, color: ink)),
              const SizedBox(width: BusinSpace.x3),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: text.bodyMedium!.copyWith(color: ink),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) Text(title!, style: text.bodyMedium?.copyWith(color: ink, fontWeight: FontWeight.w700)),
                      child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
