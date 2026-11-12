import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_location.dart';

/// "About 400 m from your stop, about 5 min on foot".
String walkText(BusinL10n l10n, ({double metres, int minutes}) walk) {
  final rough = roughWalk(walk.metres);
  return rough.km
      ? l10n.busMeWalkKm(l10n.localeName.startsWith('fr') ? rough.value.replaceFirst('.', ',') : rough.value, '${walk.minutes}')
      : l10n.busMeWalkM(rough.value, '${walk.minutes}');
}

/// Show me: explains first, then asks the phone. Says what happened when the student does not end up on the map.
Future<void> turnOnShowMe(BuildContext context, WidgetRef ref) async {
  final l10n = BusinL10n.of(context);
  final go = await showBusinSheet<bool>(
    context,
    builder: (context) => _MeSheet(title: l10n.busMeWhyTitle, body: l10n.busMeWhyBody, primary: l10n.busMeContinue, secondary: l10n.busMeNotNow),
  );
  if (go != true || !context.mounted) return;
  final access = await ref.read(showMeProvider.notifier).turnOn();
  if (!context.mounted) return;
  switch (access) {
    case MeAccess.granted:
      break;
    case MeAccess.approximate:
      BusinToast.show(context, l10n.busMeApproximate);
    case MeAccess.denied:
      BusinToast.show(context, l10n.busMeDenied, tone: ToastTone.warning);
    case MeAccess.off:
      BusinToast.show(context, l10n.busMeOff, tone: ToastTone.warning);
    case MeAccess.deniedForever:
      final open = await showBusinSheet<bool>(
        context,
        builder: (context) => _MeSheet(title: l10n.busMeWhyTitle, body: l10n.busMeDeniedForever, primary: l10n.busMeSettings, secondary: l10n.busMeNotNow),
      );
      if (open == true) await ref.read(myLocationFeedProvider).openSettings();
  }
}

/// A short sheet with a title, a few words and two choices (true for the first).
class _MeSheet extends StatelessWidget {
  const _MeSheet({required this.title, required this.body, required this.primary, required this.secondary});

  final String title;
  final String body;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(BusinSpace.x5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x2),
          Text(body, style: text.bodyMedium),
          const SizedBox(height: BusinSpace.x5),
          BusinButton(label: primary, onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: BusinSpace.x2),
          BusinButton(label: secondary, variant: BusinButtonVariant.ghost, onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

