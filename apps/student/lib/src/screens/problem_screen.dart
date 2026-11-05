import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';

/// The profile could not be read (no network, or the server refused). Retry or sign out.
class ProblemScreen extends ConsumerWidget {
  const ProblemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: HugeIcons.strokeRoundedWifiDisconnected01,
          title: l10n.errorGeneric,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(profileProvider)),
              const SizedBox(height: BusinSpace.x2),
              BusinButton(
                label: l10n.actionSignOut,
                variant: BusinButtonVariant.ghost,
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
