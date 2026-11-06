import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import 'push_providers.dart';
import 'push_service.dart';

/// Offers to turn notifications on, at the moment the student has something to wait for (a request that is pending).
/// Shown once: "Turn on" asks the system, "Not now" hides it for good. If the system says no, it says how to change that.
class PushPromptCard extends ConsumerStatefulWidget {
  const PushPromptCard({super.key});

  @override
  ConsumerState<PushPromptCard> createState() => _PushPromptCardState();
}

class _PushPromptCardState extends ConsumerState<PushPromptCard> {
  bool _busy = false;
  bool _denied = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    final answer = await ref.read(pushRegistrarProvider).enable();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _denied = answer != PushPermission.granted;
    });
    if (answer == PushPermission.granted) {
      // The stored answer is stale now: read it again, then the offer goes away.
      ref.invalidate(pushPermissionProvider);
      ref.invalidate(showPushPromptProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showPushPromptProvider).value ?? false;
    if (!show) return const SizedBox.shrink();

    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: BusinSpace.x4),
      child: DecoratedBox(
        decoration: BoxDecoration(color: palette.infoBg, borderRadius: BorderRadius.circular(BusinRadius.lg)),
        child: Padding(
          padding: const EdgeInsets.all(BusinSpace.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedNotification01, color: palette.info),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(child: Text(l10n.pushPromptTitle, style: text.titleMedium)),
                ],
              ),
              const SizedBox(height: BusinSpace.x2),
              Text(_denied ? l10n.pushPromptDenied : l10n.pushPromptBody, style: text.bodyMedium),
              const SizedBox(height: BusinSpace.x4),
              if (!_denied)
                BusinButton(label: l10n.pushPromptEnable, onPressed: _busy ? null : _enable, loading: _busy, expand: true),
              BusinButton(
                label: l10n.pushPromptLater,
                variant: BusinButtonVariant.ghost,
                onPressed: _busy ? null : () => dismissPushPrompt(ref),
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
