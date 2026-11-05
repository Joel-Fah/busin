import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';

/// Tells a signed-in person why they cannot use the app, and lets them sign out to try another account.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final access = ref.watch(accessProvider);
    final reason = access is Blocked ? access.reason : BlockReason.notStudent;
    final (title, body) = switch (reason) {
      BlockReason.notStudent => (l10n.blockedStaffTitle, l10n.blockedStaffBody),
      BlockReason.pending => (l10n.blockedPendingTitle, l10n.blockedPendingBody),
      BlockReason.suspended => (l10n.blockedSuspendedTitle, l10n.blockedSuspendedBody),
    };

    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: HugeIcons.strokeRoundedShield01,
          title: title,
          body: body,
          action: BusinButton(
            label: l10n.actionSignOut,
            variant: BusinButtonVariant.secondary,
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ),
      ),
    );
  }
}
