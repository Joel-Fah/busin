import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../router.dart';
import 'area_providers.dart';

/// Offers My area to a student who never added it and was never asked (ADR 0023). Shown once: either answer hides it
/// for good, and My area stays in the profile.
class AreaPromptCard extends ConsumerWidget {
  const AreaPromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(showAreaPromptProvider).value ?? false;
    if (!show) return const SizedBox.shrink();

    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    // The same insight-card style as the notifications offer: pale teal and the brand's dark teal, in both themes.
    const ink = BusinRamps.seed;
    return Padding(
      padding: const EdgeInsets.only(top: BusinSpace.x4),
      child: BusinCard(
        color: BusinRamps.teal50,
        padding: const EdgeInsets.all(BusinSpace.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: BusinRamps.teal100, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                  child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedHome01, size: 22, color: ink)),
                ),
                const SizedBox(width: BusinSpace.x3),
                Expanded(child: Text(l10n.areaPromptTitle, style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: BusinSpace.x3),
            Text(l10n.areaPromptBody, style: text.bodyMedium?.copyWith(color: ink)),
            const SizedBox(height: BusinSpace.x4),
            BusinButton(
              label: l10n.areaPromptAdd,
              expand: true,
              onPressed: () {
                ref.read(markAreaOfferedProvider)();
                context.push(Routes.area);
              },
            ),
            // Ghost buttons take the page's text colour; on this pale card the label must be dark.
            Theme(
              data: Theme.of(context).copyWith(extensions: [BusinPalette.light]),
              child: BusinButton(label: l10n.areaIntroSkip, variant: BusinButtonVariant.ghost, expand: true, onPressed: () => ref.read(markAreaOfferedProvider)()),
            ),
          ],
        ),
      ),
    );
  }
}
