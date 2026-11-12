import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access.dart';
import '../providers.dart';

/// While the session and the profile load.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(color: p.fg, height: 48, semanticLabel: BusinL10n.of(context).opsAppName),
            const SizedBox(height: BusinSpace.x6),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// A signed-in person who may not use the ops app: a student, or a suspended account.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final access = ref.watch(accessProvider);
    final reason = access is OpsBlocked ? access.reason : OpsBlockReason.notStaff;
    final (title, body, art) = switch (reason) {
      OpsBlockReason.notStaff => (l10n.opsNotStaffTitle, l10n.opsNotStaffBody, BusinIllustration.staff),
      OpsBlockReason.pending => (l10n.opsPendingTitle, l10n.opsPendingBody, BusinIllustration.waiting),
      OpsBlockReason.suspended => (l10n.blockedSuspendedTitle, l10n.blockedSuspendedBody, BusinIllustration.blocked),
    };
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          illustration: art,
          title: title,
          body: body,
          action: BusinButton(label: l10n.actionSignOut, variant: BusinButtonVariant.secondary, onPressed: () => ref.read(signOutProvider)()),
        ),
      ),
    );
  }
}

/// The account could not be read: offline at first launch, or a server problem.
class ProblemScreen extends ConsumerWidget {
  const ProblemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          illustration: BusinIllustration.waiting,
          title: l10n.opsProblemTitle,
          body: l10n.opsProblemBody,
          action: Wrap(
            spacing: BusinSpace.x3,
            runSpacing: BusinSpace.x3,
            alignment: WrapAlignment.center,
            children: [
              BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(profileProvider)),
              BusinButton(label: l10n.actionSignOut, variant: BusinButtonVariant.secondary, onPressed: () => ref.read(signOutProvider)()),
            ],
          ),
        ),
      ),
    );
  }
}
