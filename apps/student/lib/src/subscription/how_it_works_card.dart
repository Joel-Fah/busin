import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

/// The four steps from subscribing to riding, shown beside the form on a wide screen where there is room for help.
class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final steps = [l10n.howStep1, l10n.howStep2, l10n.howStep3, l10n.howStep4];
    return BusinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.howTitle, style: text.titleLarge)),
              const Illustration(BusinIllustration.ticket, width: 64, height: 64),
            ],
          ),
          const SizedBox(height: BusinSpace.x4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BusinSpace.x4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.xs)),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(steps[i], style: text.bodyLarge))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
