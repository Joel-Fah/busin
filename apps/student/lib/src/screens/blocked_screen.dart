import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final (title, body, art) = switch (reason) {
      BlockReason.notStudent => (l10n.blockedStaffTitle, l10n.blockedStaffBody, BusinIllustration.staff),
      BlockReason.suspended => (l10n.blockedSuspendedTitle, l10n.blockedSuspendedBody, BusinIllustration.blocked),
    };

    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          illustration: art,
          title: title,
          body: body,
          action: BusinButton(
            label: l10n.actionSignOut,
            variant: BusinButtonVariant.secondary,
            onPressed: () => ref.read(signOutProvider)(),
          ),
        ),
      ),
    );
  }
}
