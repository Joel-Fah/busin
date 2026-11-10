import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'offline_providers.dart';

/// "6 Nov 2026, 14:05": when the saved copy was made, in the phone's own clock and language.
String savedWhen(BuildContext context, DateTime savedAt) {
  final material = MaterialLocalizations.of(context);
  final local = savedAt.toLocal();
  return '${material.formatMediumDate(local)}, ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
}

/// A slim notice at the top of the app while what is on screen comes from the copy saved on the phone. It says the pass still
/// works at the door and when the copy dates; it goes away by itself when the server answers again.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final since = ref.watch(offlineSinceProvider);
    final l10n = BusinL10n.of(context);
    return AnimatedSize(
      duration: BusinMotion.of(context, BusinMotion.normal),
      curve: BusinMotion.soft,
      alignment: Alignment.topCenter,
      child: since == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(BusinSpace.x4, BusinSpace.x2, BusinSpace.x4, 0),
              child: Notice(
                tone: StatusTone.warn,
                icon: HugeIcons.strokeRoundedWifiDisconnected01,
                title: l10n.offlineTitle,
                child: Text(l10n.offlineBody(savedWhen(context, since))),
              ),
            ),
    );
  }
}
